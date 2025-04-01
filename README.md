---

# FT Queue System for FiveM

A powerful, efficient, and fair queue system for FiveM servers with **ESX** and **QBCore** framework support.

## 🚀 Features

- **🔄 Real-Time Priority Handling**  
  Players are sorted by their priority level, which can be changed dynamically via commands or database.

- **📊 Transparent Queueing System**  
  Players see their **position**, **estimated wait time**, and **priority level** in real-time.

- **⚡ Performance Optimized**  
  Lightweight and efficient — minimal resource usage even on high-population servers.

- **⚙️ Easy Configuration**  
  All customizable settings are found in `config.lua`.

- **⏳ Auto-Kick for Inactivity**  
  Idle players in the queue are automatically removed after a configurable time.

- **📦 Framework Support**  
  Auto-detects ESX or QBCore. If none is found, runs in standalone mode.

- **🗃️ Persistent Database Integration**  
  Stores player priority in a database using **oxmysql**.

---

## 📁 Files Included

- `fxmanifest.lua` – Resource manifest and dependency declarations  
- `config.lua` – Queue system configuration  
- `server/database.lua` – Handles MySQL database interactions  
- `server/server.lua` – Core server-side logic  
- `README.md` – You're reading it 😉

---

## 🔧 Installation

1. **Place the resource** in your `resources` folder.
2. **Add the following line** to your `server.cfg`:
   ```cfg
   ensure ft-queue
   ```
3. **Configure settings** in `config.lua` as needed.
4. **Ensure oxmysql is properly installed** and configured.

---

## 💬 Commands

| Command | Description |
|--------|-------------|
| `/addpriority [id/identifier] [priority_level]` | Add or change a player's priority |
| `/removepriority [id/identifier]` | Remove a player's priority |
| `/checkpriority [id/identifier]` | Check a player's current priority |
| `/refreshqueue` | Manually refresh the queue |

---

## 📤 Exports for Developers

These can be used in other scripts or systems to interact with the queue.

```lua
GetQueueInfo()                      -- Returns current queue info
SetQueueActive(boolean)            -- Enables/disables the queue
AddPlayerPriority(identifier, level, addedBy) -- Adds priority to a player
RemovePlayerPriority(identifier)   -- Removes a player's priority
```

---

## ✅ Compatibility

- ESX  
- QBCore  
- Standalone (Fallback)

---

## 📌 Notes

- Make sure to set up your **oxmysql** connection properly.
- Player identifiers should be consistent (e.g., Steam or license-based).
- Inactivity timeout is configurable in `config.lua`.

---

## 📣 Credits

Developed by **FourTwenty Development**  
For support, suggestions, or issues, feel free to reach out via Discord or GitHub.

---
