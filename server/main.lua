local config = require 'config.server'
local currentVehicles = {}

local function isInList(name)
    local retval = false
    if currentVehicles ~= nil and next(currentVehicles) ~= nil then
        for k in pairs(currentVehicles) do
            if currentVehicles[k] == name then
                retval = true
            end
        end
    end
    return retval
end

local function generateVehicleList()
    currentVehicles = {}
    for i = 1, 40, 1 do
        local randVehicle = config.vehicles[math.random(1, #config.vehicles)]
        if not isInList(randVehicle) then
            currentVehicles[i] = randVehicle
        end
    end
    TriggerClientEvent("qbx_scrapyard:client:setNewVehicles", -1, currentVehicles)
end

lib.callback.register('qbx_scrapyard:server:checkVehicleOwner', function(_, plate)
    local vehicle = MySQL.scalar.await('SELECT `plate` FROM `player_vehicles` WHERE `plate` = ?', {plate})
    if not vehicle then
        return true
    else
        return false
    end
end)

RegisterNetEvent('qbx_scrapyard:server:loadVehicleList', function()
    TriggerClientEvent("qbx_scrapyard:client:setNewVehicles", source, currentVehicles)
end)

RegisterNetEvent('qbx_scrapyard:server:scrapVehicle', function(listKey)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player or not currentVehicles[listKey] then return end

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

    currentVehicles[listKey] = nil
    TriggerClientEvent("qbx_scrapyard:client:setNewVehicles", -1, currentVehicles)
end)

CreateThread(function()
    Wait(1000)
    while true do
        generateVehicleList()
        Wait(1000 * 60 * 60)
    end
end)
