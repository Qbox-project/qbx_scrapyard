local config = require 'config.server'
local sharedConfig = require 'config.shared'
local ITEMS = exports.ox_inventory:Items()

local function isInList(name)
    local retval = false
    if sharedConfig.currentVehicles ~= nil and next(sharedConfig.currentVehicles) ~= nil then
        for k in pairs(sharedConfig.currentVehicles) do
            if sharedConfig.currentVehicles[k] == name then
                retval = true
            end
        end
    end
    return retval
end

local function generateVehicleList()
    sharedConfig.currentVehicles = {}
    for i = 1, 40, 1 do
        local randVehicle = config.vehicles[math.random(1, #config.vehicles)]
        if not isInList(randVehicle) then
            sharedConfig.currentVehicles[i] = randVehicle
        end
    end
    TriggerClientEvent("qb-scapyard:client:setNewVehicles", -1, sharedConfig.currentVehicles)
end

lib.callback.register('qb-scrapyard:server:checkOwnerVehicle', function(_, plate)
    local vehicle = MySQL.scalar.await("SELECT `plate` FROM `player_vehicles` WHERE `plate` = ?", {plate})
    if not vehicle then
        return true
    else
        return false
    end
end)

RegisterNetEvent('qb-scrapyard:server:LoadVehicleList', function()
    TriggerClientEvent("qb-scapyard:client:setNewVehicles", source, sharedConfig.currentVehicles)
end)

RegisterNetEvent('qb-scrapyard:server:ScrapVehicle', function(listKey)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player or not sharedConfig.currentVehicles[listKey] then return end

    for _ = 1, math.random(2, 4), 1 do
        local item = config.items[math.random(1, #config.items)]
        Player.Functions.AddItem(item, math.random(25, 45))
        TriggerClientEvent('inventory:client:ItemBox', src, ITEMS[item], 'add')
        Wait(500)
    end

    local luck = math.random(1, 8)
    local odd = math.random(1, 8)
    if luck == odd then
        local random = math.random(10, 20)
        Player.Functions.AddItem("rubber", random)
        TriggerClientEvent('inventory:client:ItemBox', src, ITEMS["rubber"], 'add')
    end

    sharedConfig.currentVehicles[listKey] = nil
    TriggerClientEvent("qb-scapyard:client:setNewVehicles", -1, sharedConfig.currentVehicles)
end)

CreateThread(function()
    Wait(1000)
    while true do
        generateVehicleList()
        Wait(1000 * 60 * 60)
    end
end)
