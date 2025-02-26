local discordWebhook = "" -- Replace with your Discord webhook URL

-- Function to send Discord logs
local function sendDiscordLog(embed)
    PerformHttpRequest(discordWebhook, function(err, text, headers) end, "POST", json.encode({ embeds = { embed } }), { ["Content-Type"] = "application/json" })
end

-- Function to check if a player is an admin
local function IsPlayerAdmin(source)
    local xPlayer = exports['es_extended']:getSharedObject().GetPlayerFromId(source)
    return xPlayer and xPlayer.getGroup() == "admin" -- Adjust this based on your admin system
end

-- Command to jail a player
RegisterCommand("jail", function(source, args)
    local src = source
    if src == 0 then
        print("[DEBUG] The server console cannot use this command.")
        return
    end

    local playerId = tonumber(args[1])
    if not playerId or not GetPlayerName(playerId) then
        TriggerClientEvent("chat:addMessage", src, { args = { "System", "Invalid player ID." } })
        return
    end

    local xPlayer = exports['es_extended']:getSharedObject().GetPlayerFromId(src)
    if not xPlayer or (xPlayer.job.name ~= "police" and not IsPlayerAdmin(src)) then
        TriggerClientEvent("chat:addMessage", src, { args = { "System", "You do not have permission to use this command." } })
        return
    end

    TriggerClientEvent("jail:openJailMenu", src, playerId)
end, false)

-- Command to unjail a player (for admins)
RegisterCommand("unjail", function(source, args)
    local src = source
    if src == 0 then
        print("[DEBUG] The server console cannot use this command.")
        return
    end

    local playerId = tonumber(args[1])
    if not playerId or not GetPlayerName(playerId) then
        TriggerClientEvent("chat:addMessage", src, { args = { "System", "Invalid player ID." } })
        return
    end

    -- Check if the source is an admin
    if not IsPlayerAdmin(src) then
        TriggerClientEvent("chat:addMessage", src, { args = { "System", "You do not have permission to use this command." } })
        return
    end

    -- Release the player
    local playerLicense = GetPlayerIdentifier(playerId, 0)
    if not playerLicense then
        TriggerClientEvent("chat:addMessage", src, { args = { "System", "Player not found." } })
        return
    end

    exports.oxmysql:execute("SELECT * FROM jailed_players WHERE license = @license", { ['@license'] = playerLicense }, function(result)
        if result and result[1] then
            -- Delete the player from the jailed_players table
            exports.oxmysql:execute("DELETE FROM jailed_players WHERE license = @license", { ['@license'] = playerLicense })

            -- Notify the player
            TriggerClientEvent("jail:releasePlayer", playerId)

            -- Log to Discord
            local embed = {
                title = "Player Unjailed",
                color = 3066993, -- Green color
                fields = {
                    { name = "Unjailed Player", value = GetPlayerName(playerId) .. " (License: " .. playerLicense .. ")", inline = true },
                    { name = "Admin", value = GetPlayerName(src) .. " (ID: " .. src .. ")", inline = true }
                }
            }
            sendDiscordLog(embed)

            -- Notify the admin
            TriggerClientEvent("chat:addMessage", src, { args = { "System", "Player " .. GetPlayerName(playerId) .. " has been unjailed." } })
        else
            TriggerClientEvent("chat:addMessage", src, { args = { "System", "This player is not in jail." } })
        end
    end)
end, false)

-- Event to send a player to jail
RegisterNetEvent("jail:sendPlayerToJail", function(playerId, jailTime, reason, jailerId)
    local playerLicense = GetPlayerIdentifier(playerId, 0)
    if not playerLicense then return end

    exports.oxmysql:execute("SELECT * FROM jailed_players WHERE license = @license", { ['@license'] = playerLicense }, function(result)
        if result and result[1] then
            TriggerClientEvent("chat:addMessage", jailerId, { args = { "System", "This player is already in jail." } })
            return
        else
            -- Save the player's jail data (without inventory)
            exports.oxmysql:execute("INSERT INTO jailed_players (license, playerName, timeRemaining, reason) VALUES (@license, @playerName, @timeRemaining, @reason)", {
                ['@license'] = playerLicense,
                ['@playerName'] = GetPlayerName(playerId),
                ['@timeRemaining'] = jailTime * 60,
                ['@reason'] = reason
            })

            -- Log to Discord
            local embed = {
                title = "Player Jailed",
                color = 15158332, -- Red color
                fields = {
                    { name = "Jailed Player", value = GetPlayerName(playerId) .. " (License: " .. playerLicense .. ")", inline = true },
                    { name = "Jailer", value = GetPlayerName(jailerId) .. " (ID: " .. jailerId .. ")", inline = true },
                    { name = "Jail Time", value = jailTime .. " minutes", inline = true },
                    { name = "Reason", value = reason, inline = true }
                }
            }
            sendDiscordLog(embed)

            -- Start the jail timer
            TriggerClientEvent("jail:startJailTimer", playerId, jailTime)
        end
    end)
end)

-- Event to release a player
RegisterNetEvent("jail:releasePlayer", function(playerId)
    local playerLicense = GetPlayerIdentifier(playerId, 0)
    if not playerLicense then return end

    exports.oxmysql:execute("SELECT * FROM jailed_players WHERE license = @license", { ['@license'] = playerLicense }, function(result)
        if result and result[1] then
            -- Delete the player from the jailed_players table
            exports.oxmysql:execute("DELETE FROM jailed_players WHERE license = @license", { ['@license'] = playerLicense })

            -- Notify the player
            TriggerClientEvent("jail:releasePlayer", playerId)
        end
    end)
end)

-- Thread to update jail time
CreateThread(function()
    while true do
        exports.oxmysql:execute("SELECT * FROM jailed_players", {}, function(result)
            for _, data in ipairs(result) do
                if data.timeRemaining > 0 then
                    exports.oxmysql:execute("UPDATE jailed_players SET timeRemaining = timeRemaining - 60 WHERE license = @license", { ['@license'] = data.license })
                    
                    local playerId = GetPlayerFromIdentifier(data.license)
                    if playerId then
                        TriggerClientEvent("jail:updateRemainingTime", playerId, data.timeRemaining / 60)
                    end
                else
                    releasePlayer(data.license)
                end
            end
        end)
        Wait(60000)
    end
end)

-- Function to get player ID from license
function GetPlayerFromIdentifier(identifier)
    for _, playerId in ipairs(GetPlayers()) do
        for i = 0, GetNumPlayerIdentifiers(playerId) - 1 do
            if GetPlayerIdentifier(playerId, i) == identifier then
                return playerId
            end
        end
    end
    return nil
end