-- ft_queue/server/database.lua
-- Database operations for the queue system

QueueDB = {}

-- Initialize the database tables
function QueueDB.Init()
    -- Create the priority table if it doesn't exist
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `ft_queue_priority` (
            `identifier` VARCHAR(60) NOT NULL,
            `priority_level` VARCHAR(50) NOT NULL,
            `added_by` VARCHAR(60) NOT NULL,
            `added_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`identifier`)
        )
    ]])
    
    print("^2[ft_queue] ^7Database tables initialized")
end

-- Get a player's priority level from the database
function QueueDB.GetPlayerPriority(identifier)
    if not Config.SavePriority then return nil end
    
    local result = MySQL.query.await("SELECT priority_level FROM ft_queue_priority WHERE identifier = ?", {
        identifier
    })
    
    if result and #result > 0 then
        return result[1].priority_level
    end
    
    return nil
end

-- Set a player's priority level in the database
function QueueDB.SetPlayerPriority(identifier, priorityLevel, addedBy)
    if not Config.SavePriority then return end
    
    MySQL.query("INSERT INTO ft_queue_priority (identifier, priority_level, added_by) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE priority_level = ?, added_by = ?, added_at = CURRENT_TIMESTAMP", {
        identifier, priorityLevel, addedBy, priorityLevel, addedBy
    })
end

-- Remove a player's priority from the database
function QueueDB.RemovePlayerPriority(identifier)
    if not Config.SavePriority then return end
    
    MySQL.query("DELETE FROM ft_queue_priority WHERE identifier = ?", {
        identifier
    })
end

-- Get all players with priority
function QueueDB.GetAllPriorities()
    if not Config.SavePriority then return {} end
    
    local result = MySQL.query.await("SELECT identifier, priority_level, added_by, added_at FROM ft_queue_priority")
    
    if result and #result > 0 then
        return result
    end
    
    return {}
end

-- No return statement needed as QueueDB is now global
