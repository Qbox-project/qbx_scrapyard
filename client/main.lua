local QBCore = exports['qbx-core']:GetCoreObject()
local emailSend = false
local isBusy = false

local function scrapVehicleAnim(time)
    time /= 1000
    lib.requestAnimDict("mp_car_bomb")
    TaskPlayAnim(cache.ped, "mp_car_bomb", "car_bomb_mechanic" ,3.0, 3.0, -1, 16, 0, false, false, false)
    local openingDoor = true
    CreateThread(function()
        while openingDoor do
            TaskPlayAnim(cache.ped, "mp_car_bomb", "car_bomb_mechanic", 3.0, 3.0, -1, 16, 0, false, false, false)
            Wait(2000)
            time -= 2
            if time <= 0 or not isBusy then
                openingDoor = false
                StopAnimTask(cache.ped, "mp_car_bomb", "car_bomb_mechanic", 1.0)
            end
        end
    end)
end

local function getVehicleKey(vehicleModel)
    if not Config.CurrentVehicles or table.type(Config.CurrentVehicles) == 'empty' then
        return 0
    end

    for k, v in pairs(Config.CurrentVehicles) do
        if joaat(v) == vehicleModel then
            return k
        end
    end

    return 0
end

local function isVehicleValid(vehicleModel)
    if not Config.CurrentVehicles or table.type(Config.CurrentVehicles) == 'empty' then
        return false
    end

    for _, v in pairs(Config.CurrentVehicles) do
        if joaat(v) == vehicleModel then
            return true
        end
    end

    return false
end

local function scrapVehicle()
    local vehicle = cache.vehicle
    if not vehicle or isBusy then return end

    if cache.seat == -1 then
        if isVehicleValid(GetEntityModel(vehicle)) then
            local vehiclePlate = QBCore.Functions.GetPlate(vehicle)
            local retval = lib.callback.await('qb-scrapyard:server:checkOwnerVehicle', false, vehiclePlate)
            if retval then
                isBusy = true
                local scrapTime = math.random(28000, 37000)
                scrapVehicleAnim(scrapTime)
                if lib.progressBar({
                    duration = scrapTime,
                    label = Lang:t('text.demolish_vehicle'),
                    useWhileDead = false,
                    canCancel = true,
                    disable = {
                        move = true,
                        car = true,
                        mouse = false,
                        combat = true
                    }
                }) then
                    TriggerServerEvent("qb-scrapyard:server:ScrapVehicle", getVehicleKey(GetEntityModel(vehicle)))
                    SetEntityAsMissionEntity(vehicle, true, true)
                    DeleteVehicle(vehicle)
                else
                    QBCore.Functions.Notify(Lang:t('error.canceled'), "error")
                end

                isBusy = false
            else
                QBCore.Functions.Notify(Lang:t('error.smash_own'), "error")
            end
        else
            QBCore.Functions.Notify(Lang:t('error.cannot_scrap'), "error")
        end
    else
        QBCore.Functions.Notify(Lang:t('error.not_driver'), "error")
    end
end

local function createListEmail()
    if not Config.CurrentVehicles or table.type(Config.CurrentVehicles) == 'empty' then
        QBCore.Functions.Notify(Lang:t('error.demolish_vehicle'), "error")
        return
    end

    emailSend = true
    local vehicleList = ""
    for _, v in pairs(Config.CurrentVehicles) do
        local vehicleInfo = QBCore.Shared.Vehicles[v]
        if vehicleInfo then
            vehicleList = vehicleList  .. vehicleInfo["brand"] .. " " .. vehicleInfo["name"] .. "<br />"
        end
    end
    SetTimeout(math.random(15000, 20000), function()
        emailSend = false
        TriggerServerEvent('qb-phone:server:sendNewMail', {
            sender = Lang:t('email.sender'),
            subject = Lang:t('email.subject'),
            message = Lang:t('email.message') .. vehicleList,
            button = {}
        })
    end)
end

local listen = false
local function keyListener(_type)
    CreateThread(function()
        listen = true
        while listen do
            if IsControlPressed(0, 38) then
                exports['qbx-core']:KeyPressed()
                if _type == 'deliver' then
                    scrapVehicle()
                else
                    if not IsPedInAnyVehicle(cache.ped, false) and not emailSend then
                        createListEmail()
                    end
                end
                break
            end
            Wait(0)
        end

        listen = false
    end)
end

RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
    TriggerServerEvent("qb-scrapyard:server:LoadVehicleList")
end)

RegisterNetEvent('qb-scapyard:client:setNewVehicles', function(vehicleList)
    Config.CurrentVehicles = vehicleList
end)

CreateThread(function()
    for _, v in pairs(Config.Locations) do
        local blip = AddBlipForCoord(v.main.x, v.main.y, v.main.z)
        SetBlipSprite(blip, 380)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.7)
        SetBlipAsShortRange(blip, true)
        SetBlipColour(blip, 9)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(Lang:t('text.scrapyard'))
        EndTextCommandSetBlipName(blip)
    end

    for i = 1, #Config.Locations, 1 do
        for k, v in pairs(Config.Locations[i]) do
            if k ~= 'main' then
                if Config.UseTarget then
                    if k == 'deliver' then
                        local inVehicle = IsPedInAnyVehicle(cache.ped, false)

                        local function onEnter()
                            if inVehicle and not isBusy then
                                if not isBusy then
                                    exports['qbx-core']:DrawText(Lang:t('text.disassemble_vehicle'),'left')
                                    keyListener(k)
                                end
                            end
                        end
    
                        local function onExit()
                            exports['qbx-core']:HideText()
                        end
    
                        lib.zones.box({
                            coords = vec3(v.coords.x, v.coords.y, v.coords.z),
                            size = vec3(4, 4, 4),
                            rotation = v.heading,
                            debug = Config.ZoneDebug,
                            onEnter = onEnter,
                            onExit = onExit
                        })
                    else
                        exports["qb-target"]:AddBoxZone("list"..i, v.coords, v.length, v.width, {
                            name = "list"..i,
                            heading = v.heading,
                            minZ = v.coords.z - 1,
                            maxZ = v.coords.z + 1,
                        }, {
                            options = {
                                {
                                    action = function()
                                        if not IsPedInAnyVehicle(cache.ped, false) and not emailSend then
                                            createListEmail()
                                        end
                                    end,
                                    icon = "fa fa-envelop",
                                    label = Lang:t('text.email_list_target'),
                                }
                            },
                            distance = 1.5
                        })
                    end
                else
                    local inVehicle = IsPedInAnyVehicle(cache.ped, false)

                    local function onEnter()
                        if inVehicle and not isBusy then
                            if not isBusy then
                                exports['qbx-core']:DrawText(Lang:t('text.disassemble_vehicle'),'left')
                                keyListener(k)
                            end
                        end
                    end

                    local function onExit()
                        exports['qbx-core']:HideText()
                    end

                    lib.zones.box({
                        coords = vec3(v.coords.x, v.coords.y, v.coords.z),
                        size = vec3(4, 4, 4),
                        rotation = v.heading,
                        debug = Config.ZoneDebug,
                        onEnter = onEnter,
                        onExit = onExit
                    })
                end
            end
        end
    end
end)
