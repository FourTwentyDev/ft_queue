# FT Queue System

An advanced queue system for FiveM servers with ESX and QBCore support.

## Features

- ✅ **Real-Time Priority Handling**: Adjust player priority dynamically based on their role or status (e.g., staff, donator).
- ✅ **Fair and Transparent Queueing**: Ensures that players are handled efficiently and in a structured manner.
- ✅ **Performance Optimized**: Lightweight and efficient, minimizing server load while maximizing queue management.
- ✅ **Easy to Configure**: Simple setup with custom commands to fit your server's needs.
- ✅ **Auto-Kick for Inactivity**: Keeps the queue moving by automatically removing inactive players.
- ✅ **Framework Support**: Works with ESX, QBCore, or as a standalone resource.
- ✅ **Database Integration**: Uses oxmysql to store player priorities.

## Installation

1. Download the resource and place it in your server's resources directory.
2. Add `ensure ft_queue` to your server.cfg (make sure it starts before your framework resources).
3. Configure the `config.lua` file to your liking.
4. Ensure you have the oxmysql resource installed and running.
5. Restart your server.

## Configuration

The `config.lua` file contains all the configurable options for the queue system:

### General Settings

```lua
Config.ServerName = "Your Server Name" -- Name displayed in queue messages
Config.MaxPlayers = 64 -- Maximum players allowed on the server
Config.RefreshTime = 5000 -- How often to refresh queue status (in ms)
Config.AutoKickTime = 300 -- Time in seconds before kicking inactive players (5 minutes)
Config.SavePriority = true -- Whether to save priority in database
```

### Priority Levels

```lua
Config.PriorityLevels = {
    ["owner"] = 100,
    ["admin"] = 75,
    ["moderator"] = 50,
    ["donator"] = 25,
    ["regular"] = 10,
    ["default"] = 0
}
```

You can add, remove, or modify priority levels as needed. Higher values mean higher priority.

### Messages

```lua
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
```

### Commands

```lua
Config.Commands = {
    addPriority = "addpriority", -- Command to add priority to a player
    removePriority = "removepriority", -- Command to remove priority from a player
    checkPriority = "checkpriority", -- Command to check a player's priority
    refreshQueue = "refreshqueue" -- Command to manually refresh the queue
}
```

### Permissions

```lua
Config.Permissions = {
    managePriority = "queue.manage", -- Permission to manage priorities
    refreshQueue = "queue.refresh" -- Permission to refresh queue
}
```

### Framework Detection

```lua
Config.Framework = "auto" -- Options: "auto", "esx", "qbcore"
```

## Commands

The queue system provides several commands for managing player priorities:

- `/addpriority [id/identifier] [priority_level]` - Add priority to a player
- `/removepriority [id/identifier]` - Remove priority from a player
- `/checkpriority [id/identifier]` - Check a player's priority
- `/refreshqueue` - Manually refresh the queue

## Permissions

To use the commands, players need the following ace permissions:

- `queue.manage` - Permission to manage priorities (add, remove, check)
- `queue.refresh` - Permission to refresh the queue

Example of adding permissions in your server.cfg:

```
add_ace group.admin queue.manage allow
add_ace group.admin queue.refresh allow
add_ace group.moderator queue.refresh allow
```

## Exports

The queue system provides several exports for developers:

### GetQueueInfo

Returns information about the current queue state.

```lua
local queueInfo = exports['ft_queue']:GetQueueInfo()
-- Returns: { count = number, active = boolean, players = table }
```

### SetQueueActive

Enable or disable the queue system.

```lua
local isActive = exports['ft_queue']:SetQueueActive(true)
-- Returns: boolean (new state)
```

### AddPlayerPriority

Add priority to a player.

```lua
local success, message = exports['ft_queue']:AddPlayerPriority(identifier, priorityLevel, addedBy)
-- Returns: boolean (success), string (message)
```

### RemovePlayerPriority

Remove priority from a player.

```lua
local success, message = exports['ft_queue']:RemovePlayerPriority(identifier)
-- Returns: boolean (success), string (message)
```

## License

This resource is licensed under the MIT License.

## Support

For support, please open an issue on the GitHub repository or contact us on Discord.
