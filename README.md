# Jail System for FiveM

This is a custom jail system for FiveM that allows admins or police to jail players for a specified amount of time. Players are restricted from using weapons, shooting, or escaping the jail zone while serving their sentence.

---

## Features

- **Jail Players**: Admins or police can jail players for a specified time with a reason.
- **Weapon Restriction**: Players cannot use weapons or shoot while in jail.
- **Anti-Escape System**: Players cannot escape the jail zone.
- **Automatic Release**: Players are automatically released after their jail time ends.
- **Discord Logs**: Logs all jail and unjail actions to a Discord webhook.

---

## Requirements

Before using this script, ensure you have the following dependencies installed and running on your FiveM server:

### 1. **ESX Framework**
   - This script is designed to work with the ESX framework. Make sure you have ESX installed and configured.
   - Download ESX from the official GitHub repository: [ESX Framework](https://github.com/esx-framework/esx_core).

### 2. **oxmysql**
   - This script uses **oxmysql** for database interactions. Ensure you have oxmysql installed and configured.
   - Download oxmysql from the official GitHub repository: [oxmysql](https://github.com/overextended/oxmysql).

### 3. **ox_lib**
   - This script uses **ox_lib** for input dialogs and notifications. Ensure you have ox_lib installed and configured.
   - Download ox_lib from the official GitHub repository: [ox_lib](https://github.com/overextended/ox_lib).

### 4. **Discord Webhook**
   - For logging jail and unjail actions, you need a Discord webhook URL.
   - Create a webhook in your Discord server by following these steps:
     1. Go to your Discord server settings.
     2. Navigate to **Integrations** > **Webhooks**.
     3. Create a new webhook and copy the URL.

### 5. **ox_inventory (Optional)**
   - If you're using **ox_inventory**, ensure it is installed and configured. This script does not remove inventory items, but it is compatible with ox_inventory if you decide to expand functionality.
   - Download ox_inventory from the official GitHub repository: [ox_inventory](https://github.com/overextended/ox_inventory).

---

## Installation

1. **Download the Script**:
   - Download the `client.lua` and `server.lua` files from this repository.

2. **Add to Your FiveM Server**:
   - Place the `client.lua` and `server.lua` files in a new folder (e.g., `jail-system`) within your `resources` directory.
   - Add the following line to your `server.cfg` file:
     ```plaintext
     ensure jail-system
     ```

3. **Set Up the Database**:
   - Run the following SQL query to create the `jailed_players` table:
     ```sql
     CREATE TABLE `jailed_players` (
         `license` VARCHAR(255) PRIMARY KEY,    -- Unique identifier for the player's license
         `playerName` VARCHAR(50) NOT NULL,     -- Name of the jailed player
         `timeRemaining` INT NOT NULL,          -- Time remaining in jail in seconds
         `reason` VARCHAR(255)                  -- Reason for jailing
     ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

     -- Optional: Add an index for faster lookups on the license
     CREATE INDEX `idx_license` ON `jailed_players` (`license`);
     ```

4. **Configure Discord Webhook**:
   - Replace the `discordWebhook` variable in `server.lua` with your Discord webhook URL.

---

## Usage

### Commands

- **Jail a Player**:
  ```plaintext
  /jail [playerID] [timeInMinutes] [reason]
  ```
  Example:
  ```plaintext
  /jail 1 10 "Breaking server rules"
  ```

- **Unjail a Player**:
  ```plaintext
  /unjail [playerID]
  ```
  Example:
  ```plaintext
  /unjail 1
  ```

---

## Configuration

### Jail Locations
You can customize the jail locations by editing the `jailLocations` table in `client.lua`. Add or remove coordinates as needed.

### Release Location
The release location is set in the `releaseCoords` variable in `client.lua`. Update this to your desired release point.

### Escape Range
The `escapeRange` variable in `client.lua` determines how far a player can go from their jail location before being teleported back. Adjust this value as needed.

---

## License

This script is licensed under the VYBSX License. Feel free to modify and distribute it as needed.

---

Enjoy using the jail system! 🚔
```
