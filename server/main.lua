local config = require 'config.server'
local clientConfig = require 'config.client'
local scrapyardCoords = clientConfig.locations.deliver.coords
local maxScrapDistance = 15.0
local currentVehicles = {}
local scrapping = {}

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

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    TriggerClientEvent('qbx_scrapyard:client:setNewVehicles', source, currentVehicles)
end)

RegisterNetEvent('qbx_scrapyard:server:scrapVehicle', function(listKey, netId)
    local src = source
    if scrapping[src] then return end

    local player = exports.qbx_core:GetPlayer(src)
    local expectedModel = currentVehicles[listKey]
    if not player or not expectedModel then return end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(entity) or GetEntityModel(entity) ~= joaat(expectedModel) then return end

    if GetPedInVehicleSeat(entity, -1) ~= GetPlayerPed(src) then return end

    if #(GetEntityCoords(entity) - scrapyardCoords) > maxScrapDistance then return end

    scrapping[src] = true

    local owned = MySQL.scalar.await('SELECT 1 FROM player_vehicles WHERE plate = ?', {qbx.getVehiclePlate(entity)})
    if owned then
        scrapping[src] = nil
        exports.qbx_core:Notify(src, locale('error.scrap_owned'), 'error')
        return
    end

    table.remove(currentVehicles, listKey)
    TriggerClientEvent('qbx_scrapyard:client:setNewVehicles', -1, currentVehicles)

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

    scrapping[src] = nil
end)

AddEventHandler('playerDropped', function()
    scrapping[source] = nil
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    SetTimeout(2000, generateVehicleList)
end)

SetInterval(generateVehicleList, 60 * 60000)
