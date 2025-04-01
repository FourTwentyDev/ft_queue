-- ft_queue/server/server.lua
-- Main server-side logic for the queue system

-- QueueDB is now a global variable defined in database.lua
local Queue = {}
local ConnectingPlayers = {}
local PlayerActivity = {}
local Framework = nil

-- Queue structure
Queue.List = {}
Queue.Active = true
Queue.Count = 0

-- Initialize the queue system
local function InitializeQueue()
    -- Initialize database
    QueueDB.Init()
    
    -- Print initialization message
    print("^2[ft_queue] ^7Queue system initialized")
    print("^2[ft_queue] ^7Server name: " .. Config.ServerName)
    print("^2[ft_queue] ^7Max players: " .. Config.MaxPlayers)
    
    -- Detect framework
    if Config.Framework == "auto" then
        if GetResourceState('es_extended') == 'started' then
            Framework = 'esx'
            print("^2[ft_queue] ^7Framework detected: ESX")
        elseif GetResourceState('qb-core') == 'started' then
            Framework = 'qbcore'
            print("^2[ft_queue] ^7Framework detected: QBCore")
        else
            Framework = 'none'
            print("^3[ft_queue] ^7No framework detected, running in standalone mode")
        end
    else
        Framework = Config.Framework
        print("^2[ft_queue] ^7Using configured framework: " .. Framework)
    end
end

-- Get player identifier
local function GetPlayerIdentifier(source)
    local identifiers = GetPlayerIdentifiers(source)
    local license = nil
    
    for _, v in pairs(identifiers) do
        if string.find(v, "license:") then
            license = v
            break
        end
    end
    
    return license
end

-- Get player priority level
local function GetPlayerPriority(source, identifier)
    local priority = "default"
    local priorityValue = Config.PriorityLevels["default"]
    
    -- Check if player has a saved priority
    if identifier then
        local dbPriority = QueueDB.GetPlayerPriority(identifier)
        if dbPriority and Config.PriorityLevels[dbPriority] then
            priority = dbPriority
            priorityValue = Config.PriorityLevels[dbPriority]
        end
    end
    
    -- Check if player has admin permissions
    if IsPlayerAceAllowed(source, Config.Permissions.managePriority) then
        priority = "admin"
        priorityValue = Config.PriorityLevels["admin"]
    end
    
    return priority, priorityValue
end

-- Add player to queue
local function AddPlayerToQueue(source, deferrals)
    local identifier = GetPlayerIdentifier(source)
    local priorityName, priorityValue = GetPlayerPriority(source, identifier)
    local name = GetPlayerName(source) or "Unknown"
    
    -- Create player entry
    local player = {
        source = source,
        name = name,
        identifier = identifier,
        priority = priorityValue,
        priorityName = priorityName,
        joinTime = os.time(),
        deferrals = deferrals
    }
    
    -- Add to queue
    table.insert(Queue.List, player)
    Queue.Count = Queue.Count + 1
    
    -- Sort queue by priority (higher priority first) and then by join time
    table.sort(Queue.List, function(a, b)
        if a.priority == b.priority then
            return a.joinTime < b.joinTime
        end
        return a.priority > b.priority
    end)
    
    -- Set player activity
    PlayerActivity[source] = os.time()
    
    -- Return player's position in queue
    for i, p in ipairs(Queue.List) do
        if p.source == source then
            return i
        end
    end
    
    return #Queue.List
end

-- Remove player from queue
local function RemovePlayerFromQueue(source)
    for i, player in ipairs(Queue.List) do
        if player.source == source then
            table.remove(Queue.List, i)
            Queue.Count = Queue.Count - 1
            PlayerActivity[source] = nil
            return true
        end
    end
    return false
end

-- Get player's position in queue
local function GetPlayerQueuePosition(source)
    for i, player in ipairs(Queue.List) do
        if player.source == source then
            return i
        end
    end
    return -1
end

-- Calculate estimated wait time
local function CalculateWaitTime(position)
    -- Simple estimation: 10 seconds per position
    local waitTime = position * 10
    
    -- Format time
    if waitTime < 60 then
        return waitTime .. " seconds"
    elseif waitTime < 3600 then
        return math.floor(waitTime / 60) .. " minutes"
    else
        return math.floor(waitTime / 3600) .. " hours, " .. math.floor((waitTime % 3600) / 60) .. " minutes"
    end
end

-- Process the queue
local function ProcessQueue()
    -- Check if there are players in queue
    if #Queue.List == 0 then return end
    
    -- Get current player count
    local playerCount = #GetPlayers()
    
    -- Check if server has space
    if playerCount >= Config.MaxPlayers then return end
    
    -- Calculate how many players can connect
    local freeSlots = Config.MaxPlayers - playerCount - #ConnectingPlayers
    
    -- Process players in queue
    for i = 1, math.min(freeSlots, #Queue.List) do
        local player = Queue.List[1]
        
        if player and player.deferrals then
            -- Add to connecting players
            ConnectingPlayers[player.source] = true
            
            -- Update player status
            player.deferrals.update(Config.Messages.joining)
            
            -- Allow connection after a short delay
            Citizen.SetTimeout(500, function()
                player.deferrals.done()
                
                -- Remove from queue
                RemovePlayerFromQueue(player.source)
                
                -- Remove from connecting after a delay
                Citizen.SetTimeout(5000, function()
                    ConnectingPlayers[player.source] = nil
                end)
            end)
        else
            -- Invalid player, remove from queue
            RemovePlayerFromQueue(player.source)
        end
    end
end

-- Update queue status for all players
local function UpdateQueueStatus()
    for i, player in ipairs(Queue.List) do
        if player.deferrals then
            local message = string.format(
                "\n" ..
                Config.Messages.connecting .. "\n" .. 
                Config.Messages.position .. "\n" .. 
                Config.Messages.estimatedTime .. "\n" .. 
                Config.Messages.priority,
                Config.ServerName,
                i, #Queue.List,
                CalculateWaitTime(i),
                player.priorityName
            )
            
            player.deferrals.update(message)
            
            -- Update activity timestamp
            PlayerActivity[player.source] = os.time()
        end
    end
end

-- Check for inactive players
local function CheckInactivePlayers()
    local currentTime = os.time()
    
    for source, lastActivity in pairs(PlayerActivity) do
        if (currentTime - lastActivity) > Config.AutoKickTime then
            -- Find player in queue
            for i, player in ipairs(Queue.List) do
                if player.source == source then
                    -- Kick player for inactivity
                    if player.deferrals then
                        player.deferrals.update(Config.Messages.kicked)
                        Citizen.SetTimeout(500, function()
                            player.deferrals.done(Config.Messages.kicked)
                        end)
                    end
                    
                    -- Remove from queue
                    RemovePlayerFromQueue(source)
                    break
                end
            end
        end
    end
end

-- Register commands
local function RegisterCommands()
    -- Add priority command
    RegisterCommand(Config.Commands.addPriority, function(source, args, rawCommand)
        -- Check permissions
        if source > 0 and not IsPlayerAceAllowed(source, Config.Permissions.managePriority) then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {"Queue System", "You don't have permission to use this command."}
            })
            return
        end
        
        -- Check arguments
        if #args < 2 then
            local message = "Usage: /" .. Config.Commands.addPriority .. " [id/identifier] [priority_level]"
            if source > 0 then
                TriggerClientEvent('chat:addMessage', source, {
                    color = {255, 255, 0},
                    multiline = true,
                    args = {"Queue System", message}
                })
            else
                print("^3[ft_queue] ^7" .. message)
            end
            return
        end
        
        local targetIdentifier = args[1]
        local priorityLevel = args[2]
        
        -- Check if priority level exists
        if not Config.PriorityLevels[priorityLevel] then
            local message = "Invalid priority level. Available levels: "
            local levels = ""
            
            for level, _ in pairs(Config.PriorityLevels) do
                levels = levels .. level .. ", "
            end
            
            levels = string.sub(levels, 1, -3) -- Remove last comma and space
            
            if source > 0 then
                TriggerClientEvent('chat:addMessage', source, {
                    color = {255, 0, 0},
                    multiline = true,
                    args = {"Queue System", message .. levels}
                })
            else
                print("^3[ft_queue] ^7" .. message .. levels)
            end
            return
        end
        
        -- Check if target is a player ID
        if tonumber(targetIdentifier) then
            local targetSource = tonumber(targetIdentifier)
            local targetPlayer = GetPlayerIdentifier(targetSource)
            
            if not targetPlayer then
                local message = "Player not found."
                if source > 0 then
                    TriggerClientEvent('chat:addMessage', source, {
                        color = {255, 0, 0},
                        multiline = true,
                        args = {"Queue System", message}
                    })
                else
                    print("^3[ft_queue] ^7" .. message)
                end
                return
            end
            
            targetIdentifier = targetPlayer
        end
        
        -- Add priority to database
        local adminIdentifier = "console"
        if source > 0 then
            adminIdentifier = GetPlayerIdentifier(source)
        end
        
        QueueDB.SetPlayerPriority(targetIdentifier, priorityLevel, adminIdentifier)
        
        -- Notify success
        local message = "Priority level '" .. priorityLevel .. "' set for " .. targetIdentifier
        if source > 0 then
            TriggerClientEvent('chat:addMessage', source, {
                color = {0, 255, 0},
                multiline = true,
                args = {"Queue System", message}
            })
        else
            print("^2[ft_queue] ^7" .. message)
        end
    end, true)
    
    -- Remove priority command
    RegisterCommand(Config.Commands.removePriority, function(source, args, rawCommand)
        -- Check permissions
        if source > 0 and not IsPlayerAceAllowed(source, Config.Permissions.managePriority) then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {"Queue System", "You don't have permission to use this command."}
            })
            return
        end
        
        -- Check arguments
        if #args < 1 then
            local message = "Usage: /" .. Config.Commands.removePriority .. " [id/identifier]"
            if source > 0 then
                TriggerClientEvent('chat:addMessage', source, {
                    color = {255, 255, 0},
                    multiline = true,
                    args = {"Queue System", message}
                })
            else
                print("^3[ft_queue] ^7" .. message)
            end
            return
        end
        
        local targetIdentifier = args[1]
        
        -- Check if target is a player ID
        if tonumber(targetIdentifier) then
            local targetSource = tonumber(targetIdentifier)
            local targetPlayer = GetPlayerIdentifier(targetSource)
            
            if not targetPlayer then
                local message = "Player not found."
                if source > 0 then
                    TriggerClientEvent('chat:addMessage', source, {
                        color = {255, 0, 0},
                        multiline = true,
                        args = {"Queue System", message}
                    })
                else
                    print("^3[ft_queue] ^7" .. message)
                end
                return
            end
            
            targetIdentifier = targetPlayer
        end
        
        -- Remove priority from database
        QueueDB.RemovePlayerPriority(targetIdentifier)
        
        -- Notify success
        local message = "Priority removed for " .. targetIdentifier
        if source > 0 then
            TriggerClientEvent('chat:addMessage', source, {
                color = {0, 255, 0},
                multiline = true,
                args = {"Queue System", message}
            })
        else
            print("^2[ft_queue] ^7" .. message)
        end
    end, true)
    
    -- Check priority command
    RegisterCommand(Config.Commands.checkPriority, function(source, args, rawCommand)
        -- Check permissions
        if source > 0 and not IsPlayerAceAllowed(source, Config.Permissions.managePriority) then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {"Queue System", "You don't have permission to use this command."}
            })
            return
        end
        
        -- Check arguments
        if #args < 1 then
            local message = "Usage: /" .. Config.Commands.checkPriority .. " [id/identifier]"
            if source > 0 then
                TriggerClientEvent('chat:addMessage', source, {
                    color = {255, 255, 0},
                    multiline = true,
                    args = {"Queue System", message}
                })
            else
                print("^3[ft_queue] ^7" .. message)
            end
            return
        end
        
        local targetIdentifier = args[1]
        
        -- Check if target is a player ID
        if tonumber(targetIdentifier) then
            local targetSource = tonumber(targetIdentifier)
            local targetPlayer = GetPlayerIdentifier(targetSource)
            
            if not targetPlayer then
                local message = "Player not found."
                if source > 0 then
                    TriggerClientEvent('chat:addMessage', source, {
                        color = {255, 0, 0},
                        multiline = true,
                        args = {"Queue System", message}
                    })
                else
                    print("^3[ft_queue] ^7" .. message)
                end
                return
            end
            
            targetIdentifier = targetPlayer
        end
        
        -- Get priority from database
        local priorityLevel = QueueDB.GetPlayerPriority(targetIdentifier) or "default"
        
        -- Notify
        local message = "Priority for " .. targetIdentifier .. " is: " .. priorityLevel
        if source > 0 then
            TriggerClientEvent('chat:addMessage', source, {
                color = {0, 255, 255},
                multiline = true,
                args = {"Queue System", message}
            })
        else
            print("^2[ft_queue] ^7" .. message)
        end
    end, true)
    
    -- Refresh queue command
    RegisterCommand(Config.Commands.refreshQueue, function(source, args, rawCommand)
        -- Check permissions
        if source > 0 and not IsPlayerAceAllowed(source, Config.Permissions.refreshQueue) then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {"Queue System", "You don't have permission to use this command."}
            })
            return
        end
        
        -- Process queue
        ProcessQueue()
        
        -- Notify
        local message = "Queue refreshed. " .. #Queue.List .. " players in queue."
        if source > 0 then
            TriggerClientEvent('chat:addMessage', source, {
                color = {0, 255, 0},
                multiline = true,
                args = {"Queue System", message}
            })
        else
            print("^2[ft_queue] ^7" .. message)
        end
    end, true)
end

-- Handle player connecting
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local source = source
    
    -- Defer the connection
    deferrals.defer()
    
    -- Update the status message
    deferrals.update(string.format(Config.Messages.connecting, Config.ServerName))
    
    -- Short delay to ensure all data is loaded
    Citizen.Wait(100)
    
    -- Check if queue is active
    if not Queue.Active then
        deferrals.done()
        return
    end
    
    -- Get current player count
    local playerCount = #GetPlayers()
    
    -- Check if server has space and no queue
    if playerCount < Config.MaxPlayers and #Queue.List == 0 and #ConnectingPlayers == 0 then
        deferrals.done()
        return
    end
    
    -- Add player to queue
    local position = AddPlayerToQueue(source, deferrals)
    
    -- Update queue status
    UpdateQueueStatus()
    
    -- Process queue
    ProcessQueue()
end)

-- Handle player disconnecting
AddEventHandler('playerDropped', function(reason)
    local source = source
    
    -- Remove from queue if in queue
    RemovePlayerFromQueue(source)
    
    -- Remove from connecting players if connecting
    if ConnectingPlayers[source] then
        ConnectingPlayers[source] = nil
    end
    
    -- Process queue after player leaves
    ProcessQueue()
end)

-- Initialize the queue system
Citizen.CreateThread(function()
    -- Initialize queue
    InitializeQueue()
    
    -- Register commands
    RegisterCommands()
    
    -- Main queue loop
    while true do
        -- Process queue
        ProcessQueue()
        
        -- Update queue status
        UpdateQueueStatus()
        
        -- Check for inactive players
        CheckInactivePlayers()
        
        -- Wait before next cycle
        Citizen.Wait(Config.RefreshTime)
    end
end)

-- Exports
exports('GetQueueInfo', function()
    return {
        count = #Queue.List,
        active = Queue.Active,
        players = Queue.List
    }
end)

exports('SetQueueActive', function(active)
    Queue.Active = active
    return Queue.Active
end)

exports('AddPlayerPriority', function(identifier, priorityLevel, addedBy)
    if not Config.PriorityLevels[priorityLevel] then
        return false, "Invalid priority level"
    end
    
    QueueDB.SetPlayerPriority(identifier, priorityLevel, addedBy or "API")
    return true, "Priority set successfully"
end)

exports('RemovePlayerPriority', function(identifier)
    QueueDB.RemovePlayerPriority(identifier)
    return true, "Priority removed successfully"
end)

-- Print startup message
print("^2[ft_queue] ^7Queue system loaded")
