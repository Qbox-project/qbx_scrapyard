local config = require 'config.server'
local currentVehicles = {}

local function isInList(name)
    if next(currentVehicles) then
        for i = 1, #currentVehicles do
            if currentVehicles[i] == name then
                return true
            end
        end
    end
    return false
end

local function generateVehicleList()
    table.wipe(currentVehicles)
    while #currentVehicles < 40 do
        local randVehicle = config.vehicles[math.random(1, #config.vehicles)]
        if not isInList(randVehicle) then
            currentVehicles[#currentVehicles + 1] = randVehicle
        end
    end

    TriggerClientEvent('qbx_scrapyard:client:setNewVehicles', -1, currentVehicles)
end

lib.callback.register('qbx_scrapyard:server:checkVehicleOwner', function(_, plate)
    local vehicle = MySQL.single.await('SELECT * FROM player_vehicles WHERE plate = ?', {plate})
    return vehicle and true or false
end)

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    TriggerClientEvent('qbx_scrapyard:client:setNewVehicles', source, currentVehicles)
end)

RegisterNetEvent('qbx_scrapyard:server:scrapVehicle', function(listKey, netId)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if not player or not currentVehicles[listKey] or not DoesEntityExist(entity) then return end

    DeleteEntity(entity)
    
    for _ = 1, math.random(2, 4), 1 do
        local item = config.items[math.random(1, #config.items)]
        exports.ox_inventory:AddItem(src, item, math.random(25, 45))
        Wait(500)
    end

    local luck = math.random(1, 8)
    local odd = math.random(1, 8)
    if luck == odd then
        local random = math.random(10, 20)
        exports.ox_inventory:AddItem(src, 'rubber', random)
    end

    table.remove(currentVehicles, listKey)
    TriggerClientEvent('qbx_scrapyard:client:setNewVehicles', -1, currentVehicles)
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    SetTimeout(2000, generateVehicleList)
end)

SetInterval(generateVehicleList, 60 * 60000)
