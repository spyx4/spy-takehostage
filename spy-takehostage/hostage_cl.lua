-- hostage_cl.lua
local QBCore = exports['qb-core']:GetCoreObject()
local takingHostage = false
local hostagePed = nil

-- Function to check if the player has a melee weapon or gun
function HasWeapon()
    local playerPed = PlayerPedId()
    local weaponHash = GetSelectedPedWeapon(playerPed)
    local weaponCategory = GetWeapontypeGroup(weaponHash)
    
    if weaponCategory == 416676503 or weaponCategory == -728555052 then -- 416676503 = guns, -728555052 = melee
        return true
    else
        return false
    end
end

-- Function to take a ped as a hostage
function TakeHostage()
    if not HasWeapon() then
        QBCore.Functions.Notify("You need a melee weapon or gun to take a hostage", "error")
        return
    end

    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local closestPed, closestDistance = GetClosestPed(playerCoords, 5.0)

    if closestPed ~= nil and closestDistance <= 5.0 and not IsPedAPlayer(closestPed) then
        takingHostage = true
        hostagePed = closestPed
        TaskSetBlockingOfNonTemporaryEvents(hostagePed, true)
        SetEntityAsMissionEntity(hostagePed, true, true)
        RequestAnimDict("random@arrests@busted")

        while not HasAnimDictLoaded("random@arrests@busted") do
            Citizen.Wait(100)
        end

        TaskPlayAnim(hostagePed, "random@arrests@busted", "idle_c", 8.0, -8.0, -1, 1, 0, false, false, false)
        AttachEntityToEntity(hostagePed, playerPed, 0, 0.0, 1.0, 0.0, 0.0, 0.0, 180.0, false, false, false, false, 2, true)
        QBCore.Functions.Notify("You have taken a hostage!", "success")

        -- Prevent hostage from fleeing or fighting back
        SetPedCombatAttributes(hostagePed, 46, true)
        SetPedFleeAttributes(hostagePed, 0, 0)
        SetPedFleeAttributes(hostagePed, 512, true)
        SetBlockingOfNonTemporaryEvents(hostagePed, true)
    else
        QBCore.Functions.Notify("No NPC nearby to take as hostage", "error")
    end
end

-- Function to release the hostage
function ReleaseHostage()
    if takingHostage and hostagePed ~= nil then
        DetachEntity(hostagePed, true, true)
        ClearPedTasksImmediately(hostagePed)
        FreezeEntityPosition(hostagePed, true)
        TaskPlayAnim(hostagePed, "random@arrests@busted", "idle_a", 8.0, -8.0, -1, 1, 0, false, false, false)
        SetPedAsNoLongerNeeded(hostagePed)
        takingHostage = false
        hostagePed = nil
        QBCore.Functions.Notify("You have released the hostage", "success")
    end
end

-- Function to get the closest ped
function GetClosestPed(coords, radius)
    local peds = GetGamePool('CPed')
    local closestPed = nil
    local closestDistance = radius + 0.01

    for _, ped in ipairs(peds) do
        local pedCoords = GetEntityCoords(ped)
        local distance = #(coords - pedCoords)

        if distance < closestDistance and not IsPedDeadOrDying(ped, true) and not IsPedAPlayer(ped) then
            closestPed = ped
            closestDistance = distance
        end
    end

    return closestPed, closestDistance
end

-- Key mapping
RegisterCommand('takehostage', function()
    if not takingHostage then
        TakeHostage()
    else
        ReleaseHostage()
    end
end, false)

RegisterKeyMapping('takehostage', 'Take Hostage', 'keyboard', 'H')

-- Disable certain controls while taking a hostage
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if takingHostage then
            DisableControlAction(0, 24, true) 
            DisableControlAction(0, 25, true) 
            DisableControlAction(0, 22, true) 
            DisableControlAction(0, 44, true) 
            DisableControlAction(0, 37, true) 
            DisableControlAction(0, 288, true) 
            DisableControlAction(0, 289, true) 
            DisableControlAction(0, 170, true) 
            DisableControlAction(0, 167, true) 
        end
    end
end)
