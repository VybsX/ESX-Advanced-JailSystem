local jailLocations = {
    vector3(1685.6602, 2443.3972, 45.8381), -- Jail location 
    vector3(1686.6838, 2463.0725, 45.8452),
    vector3(1682.7974, 2462.5830, 50.4502),  
    vector3(1695.7217, 2443.2561, 50.4450),
    vector3(1761.3005, 2474.7510, 45.8137),
    vector3(1758.3046, 2473.3530, 50.4178),
    vector3(1745.4133, 2489.7188, 50.4219),
    vector3(1763.6559, 2499.9917, 45.8228) 
}
local releaseCoords = vector3(1792.5370, 2593.6958, 45.7559) -- Release location
local injail = false
local currentJailLocation = nil
local escapeRange = 250.0 -- Increased escape range 

-- Function to get a random jail location
local function getRandomJailLocation()
    return jailLocations[math.random(#jailLocations)]
end

-- Open jail menu
local function openJailMenu(targetPlayer)
    local input = lib.inputDialog("Send to Jail", {
        { type = "number", label = "Jail Time (minutes)", default = 5 },
        { type = "input", label = "Reason", placeholder = "Enter reason for jailing" }
    })

    if input and input[1] and input[2] then
        TriggerServerEvent("jail:sendPlayerToJail", targetPlayer, input[1], input[2], GetPlayerServerId(PlayerId()))
    end
end

-- Event to open the jail menu
RegisterNetEvent("jail:openJailMenu", function(targetPlayer)
    openJailMenu(targetPlayer)
end)

-- Event to start the jail timer
RegisterNetEvent("jail:startJailTimer", function(jailTime)
    injail = true
    currentJailLocation = getRandomJailLocation() -- Set a random jail location
    SetEntityCoords(PlayerPedId(), currentJailLocation.x, currentJailLocation.y, currentJailLocation.z)
    lib.notify({ title = "You are in Jail", description = "Remaining time: " .. jailTime .. " minutes.", type = "info" })

    -- Freeze hunger and thirst levels
    TriggerEvent('esx_status:setDisplay', 0.0) -- Hide the status HUD (optional)
    TriggerEvent('esx_status:add', 'hunger', 100) -- Set hunger to 100%
    TriggerEvent('esx_status:add', 'thirst', 100) -- Set thirst to 100%

    -- Start the timer and update every minute
    Citizen.CreateThread(function()
        while injail do
            Citizen.Wait(60000) -- Wait 1 minute
            jailTime = jailTime - 1
            if jailTime > 0 then
                lib.notify({ title = "Jail Time", description = "Remaining time: " .. jailTime .. " minutes.", type = "info" })
            else
                injail = false
                lib.notify({ title = "You are Free", description = "Your jail time has ended.", type = "success" })
                SetEntityCoords(PlayerPedId(), releaseCoords.x, releaseCoords.y, releaseCoords.z)
                TriggerServerEvent("jail:releasePlayer", GetPlayerServerId(PlayerId())) -- Notify server to release player
            end
        end
    end)
end)

-- Event to update remaining jail time
RegisterNetEvent("jail:updateRemainingTime", function(minutesLeft)
    lib.notify({ title = "Jail Time", description = "Remaining time: " .. math.ceil(minutesLeft) .. " minutes.", type = "info" })
end)

-- Event to release the player
RegisterNetEvent("jail:releasePlayer", function()
    injail = false
    SetEntityCoords(PlayerPedId(), releaseCoords.x, releaseCoords.y, releaseCoords.z)
    lib.notify({ title = "You are Free", description = "Your jail time has ended.", type = "success" })

    -- Restore hunger and thirst levels
    TriggerEvent('esx_status:setDisplay', 1.0) -- Show the status HUD (optional)
    TriggerEvent('esx_status:add', 'hunger', 100) -- Set hunger to 100%
    TriggerEvent('esx_status:add', 'thirst', 100) -- Set thirst to 100%
end)

-- Anti-escape system
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        while injail do 
            Citizen.Wait(0)
            -- Prevent escaping
            if GetDistanceBetweenCoords(currentJailLocation, GetEntityCoords(PlayerPedId())) > escapeRange then 
                SetEntityCoords(PlayerPedId(), currentJailLocation.x, currentJailLocation.y, currentJailLocation.z)
                lib.notify({ title = "Jail", description = "You cannot escape!", type = "error" })
            end

            -- Disable weapons
            DisableControlAction(0, 140, true) -- Disable melee attacks
            DisableControlAction(0, 141, true) -- Disable melee attacks
            DisableControlAction(0, 142, true) -- Disable melee attacks
            DisablePlayerFiring(PlayerPedId(), true) -- Disable shooting

            -- Disable vehicle entry
            DisableControlAction(0, 23, true) -- Disable entering vehicles

            -- Disable running
            DisableControlAction(0, 32, true) -- Disable W key (move forward)
            DisableControlAction(0, 33, true) -- Disable S key (move backward)
            DisableControlAction(0, 34, true) -- Disable A key (move left)
            DisableControlAction(0, 35, true) -- Disable D key (move right)
        end
    end
end)