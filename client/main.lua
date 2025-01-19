local config = require 'config.client'
local VEHICLES = exports.qbx_core:GetVehiclesByName()
local currentVehicles = {}
local emailSent = false
local isBusy = false
local isLoggedIn = LocalPlayer.state.isLoggedIn

local function setLocationsBlip()
    if not config.useBlips then return end
    for _, value in pairs(config.locations) do
        local blip = AddBlipForCoord(value.coords.x, value.coords.y, value.coords.z)
        SetBlipSprite(blip, value.blipIcon)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.8)
        SetBlipAsShortRange(blip, true)
        SetBlipColour(blip, 9)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(value.blipName)
        EndTextCommandSetBlipName(blip)
    end
end

local function scrapVehicleAnim(time)
    time /= 1000
    lib.playAnim(cache.ped, 'mp_car_bomb', 'car_bomb_mechanic', 3.0, 3.0, -1, 16, 0, false, false, false)
    local openingDoor = true
    CreateThread(function()
        while openingDoor do
            lib.playAnim(cache.ped, 'mp_car_bomb', 'car_bomb_mechanic', 3.0, 3.0, -1, 16, 0, false, false, false)
            Wait(2000)
            time -= 2
            if time <= 0 or not isBusy then
                openingDoor = false
                StopAnimTask(cache.ped, 'mp_car_bomb', 'car_bomb_mechanic', 1.0)
            end
        end
    end)
end

local function getVehicleKey(vehicleModel)
    if not currentVehicles or table.type(currentVehicles) == 'empty' then
        return 0
    end

    for k, v in pairs(currentVehicles) do
        if joaat(v) == vehicleModel then
            return k
        end
    end

    return 0
end

local function isVehicleValid(vehicleModel)
    if not currentVehicles or table.type(currentVehicles) == 'empty' then
        return false
    end

    for _, v in pairs(currentVehicles) do
        if joaat(v) == vehicleModel then
            return true
        end
    end

    return false
end

local function scrapVehicle()
    local vehicle = cache.vehicle
    if not vehicle or isBusy then return end

    if cache.seat ~= -1 then
        return exports.qbx_core:Notify(locale('error.not_driver'), 'error')
    end

    if not isVehicleValid(GetEntityModel(vehicle)) then
        return exports.qbx_core:Notify(locale('error.cannot_scrap'), 'error')
    end

    local vehiclePlate = qbx.getVehiclePlate(vehicle)

    local isOwned = lib.callback.await('qbx_scrapyard:server:checkVehicleOwner', false, vehiclePlate)
    if isOwned then
        return exports.qbx_core:Notify(locale('error.scrap_owned'), 'error')
    end

    isBusy = true
    local scrapTime = math.random(28000, 37000)
    scrapVehicleAnim(scrapTime)
    if lib.progressBar({
        duration = scrapTime,
        label = locale('text.scrap_vehicle'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            mouse = false,
            combat = true
        }
    }) then
        TriggerServerEvent('qbx_scrapyard:server:scrapVehicle', getVehicleKey(GetEntityModel(vehicle)), NetworkGetNetworkIdFromEntity(vehicle))
    end
    isBusy = false
end

local function createListEmail()
    if cache.vehicle then return end
    if not currentVehicles or table.type(currentVehicles) == 'empty' then
        exports.qbx_core:Notify(locale('error.scrap_vehicle'), 'error')
        return
    end

    emailSent = true
    local vehicleList = ''
    for _, v in pairs(currentVehicles) do
        local vehicleInfo = VEHICLES[v]
        if vehicleInfo then
            vehicleList = vehicleList .. vehicleInfo['brand'] .. ' ' .. vehicleInfo['name'] .. '<br />'
        end
    end
    exports.qbx_core:Notify(locale('text.email_sent'), 'success')
    SetTimeout(math.random(15000, 20000), function()
        emailSent = false
        TriggerServerEvent('qb-phone:server:sendNewMail', {
            sender = locale('email.sender'),
            subject = locale('email.subject'),
            message = locale('email.message') .. vehicleList,
            button = {}
        })
    end)
end

local function deliverZones()
    local function onEnter()
        if cache.vehicle and not isBusy then
            lib.showTextUI(locale('text.disassemble_vehicle'))
        end
    end

    local function onExit()
        lib.hideTextUI()
    end

    local function inside()
        if IsControlJustPressed(0, 38) and not isBusy then
            lib.hideTextUI()
            scrapVehicle()
            return
        end
    end

    lib.zones.box({
        coords = config.locations.deliver.coords,
        size = vec3(4, 4, 4),
        rotation = 77.63,
        debug = config.debugPoly,
        inside = inside,
        onEnter = onEnter,
        onExit = onExit
    })
end

local function listZone()
    if config.useTarget then
        local model = config.locations.main.pedModel
        local coords = config.locations.main.coords
        lib.requestModel(model, 5000)
        local pedList = CreatePed(4, model, coords.x, coords.y, coords.z - 1, coords.w, false, true)
        SetModelAsNoLongerNeeded(model)
        FreezeEntityPosition(pedList, true)
        exports.ox_target:addLocalEntity(pedList, {
            {
                name = 'scrapyard_list',
                label = locale('text.email_list_target'),
                icon = 'fas fa-list-ul',
                distance = 1.5,
                onSelect = createListEmail,
                canInteract = function()
                    return not emailSent
                end,
            }
        })
    else
        local function onEnter()
            if not cache.vehicle and not isBusy then
                lib.showTextUI(locale('text.email_list'))
            end
        end

        local function onExit()
            lib.hideTextUI()
        end

        local function inside()
            if IsControlJustPressed(0, 38) and not emailSent then
                lib.hideTextUI()
                createListEmail()
                return
            end
        end

        lib.zones.box({
            coords = config.locations.main.coords,
            size = vec3(2, 2, 2),
            rotation = 65,
            debug = config.debugPoly,
            inside = inside,
            onEnter = onEnter,
            onExit = onExit
        })
    end
end

local function init()
    setLocationsBlip()
    deliverZones()
    listZone()
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    isLoggedIn = true
    init()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    isLoggedIn = false
end)

RegisterNetEvent('qbx_scrapyard:client:setNewVehicles', function(vehicleList)
    currentVehicles = vehicleList
end)

CreateThread(function()
    if not isLoggedIn then return end
    init()
end)
