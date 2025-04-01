Config = {}

-- General Settings
Config.ServerName = "Your Server Name" -- Name displayed in queue messages
Config.MaxPlayers = 0 -- Maximum players allowed on the server (should match your server config)
Config.RefreshTime = 5000 -- How often to refresh queue status (in ms)
Config.AutoKickTime = 300 -- Time in seconds before kicking inactive players from queue (5 minutes)
Config.SavePriority = true -- Whether to save priority in database

-- Priority Settings
Config.PriorityLevels = {
    ["owner"] = 100,
    ["admin"] = 75,
    ["moderator"] = 50,
    ["donator"] = 25,
    ["regular"] = 10,
    ["default"] = 0
}

-- Queue Messages
Config.Messages = {
    connecting = "Connecting to %s",
    position = "You are in position %d of %d in queue",
    estimatedTime = "Estimated time: %s",
    joining = "You are being connected to the server...",
    connected = "Connected to server!",
    error = "Error: %s",
    kicked = "You were kicked from the queue due to inactivity",
    priority = "Priority: %s"
}

-- Commands
Config.Commands = {
    addPriority = "addpriority", -- Command to add priority to a player
    removePriority = "removepriority", -- Command to remove priority from a player
    checkPriority = "checkpriority", -- Command to check a player's priority
    refreshQueue = "refreshqueue" -- Command to manually refresh the queue
}

-- Permission levels required for commands (ace permissions)
Config.Permissions = {
    managePriority = "queue.manage", -- Permission to manage priorities
    refreshQueue = "queue.refresh" -- Permission to refresh queue
}

-- Framework detection (auto-detects, but you can force it)
Config.Framework = "auto" -- Options: "auto", "esx", "qbcore"
