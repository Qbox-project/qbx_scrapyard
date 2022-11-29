local QBCore = exports['qb-core']:GetCoreObject()
local CurrentVehicles = {}

CreateThread(function()
    while true do
        Wait(1000)

        GenerateVehicleList()

        Wait((1000 * 60) * 60)
    end
end)

RegisterNetEvent('qb-scrapyard:server:LoadVehicleList', function()
    local src = source

    TriggerClientEvent("qb-scapyard:client:setNewVehicles", src, CurrentVehicles)
end)

QBCore.Functions.CreateCallback('qb-scrapyard:checkOwnerVehicle', function(_, cb, plate)
    local result = MySQL.scalar.await("SELECT `plate` FROM `player_vehicles` WHERE `plate` = ?", {
        plate
    })

    if result then
        cb(false)
    else
        cb(true)
    end
end)

RegisterNetEvent('qb-scrapyard:server:ScrapVehicle', function(listKey)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if CurrentVehicles[listKey] then
        for _ = 1, math.random(2, 4), 1 do
            local item = Config.Items[math.random(1, #Config.Items)]

            Player.Functions.AddItem(item, math.random(25, 45))

            Wait(500)
        end

        local Luck = math.random(1, 8)
        local Odd = math.random(1, 8)

        if Luck == Odd then
            local random = math.random(10, 20)

            Player.Functions.AddItem("rubber", random)
        end

        CurrentVehicles[listKey] = nil

        TriggerClientEvent("qb-scapyard:client:setNewVehicles", -1, CurrentVehicles)
    end
end)

function GenerateVehicleList()
    CurrentVehicles = {}

    for i = 1, Config.AmountOfVehicles, 1 do
        local randVehicle = Config.Vehicles[math.random(1, #Config.Vehicles)]

        if not IsInList(randVehicle) then
            CurrentVehicles[i] = randVehicle
        end
    end

    TriggerClientEvent("qb-scapyard:client:setNewVehicles", -1, CurrentVehicles)
end

function IsInList(name)
    local retval = false

    if CurrentVehicles and next(CurrentVehicles) then
        for k in pairs(CurrentVehicles) do
            if CurrentVehicles[k] == name then
                retval = true
            end
        end
    end

    return retval
end