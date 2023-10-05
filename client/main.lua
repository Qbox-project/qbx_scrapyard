local VEHICLES = exports.qbx_core:GetVehiclesByName()
local emailSent = false
local isBusy = false

local function scrapVehicleAnim(time)
    time /= 1000
    lib.requestAnimDict("mp_car_bomb")
    TaskPlayAnim(cache.ped, "mp_car_bomb", "car_bomb_mechanic", 3.0, 3.0, -1, 16, 0, false, false, false)
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
            local vehiclePlate = GetPlate(vehicle)
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
                   exports.qbx_core:Notify(Lang:t('error.canceled'), 'error')
                end

                isBusy = false
            else
               exports.qbx_core:Notify(Lang:t('error.smash_own'), 'error')
            end
        else
           exports.qbx_core:Notify(Lang:t('error.cannot_scrap'), 'error')
        end
    else
       exports.qbx_core:Notify(Lang:t('error.not_driver'), 'error')
    end
end

local function createListEmail()
    if cache.vehicle then return end
    if not Config.CurrentVehicles or table.type(Config.CurrentVehicles) == 'empty' then
       exports.qbx_core:Notify(Lang:t('error.demolish_vehicle'), 'error')
        return
    end

    emailSent = true
    local vehicleList = ""
    for _, v in pairs(Config.CurrentVehicles) do
        local vehicleInfo = VEHICLES[v]
        if vehicleInfo then
            vehicleList = vehicleList  .. vehicleInfo["brand"] .. " " .. vehicleInfo["name"] .. "<br />"
        end
    end
   exports.qbx_core:Notify(Lang:t('text.email_sent'), 'success')
    SetTimeout(math.random(15000, 20000), function()
        emailSent = false
        TriggerServerEvent('qb-phone:server:sendNewMail', {
            sender = Lang:t('email.sender'),
            subject = Lang:t('email.subject'),
            message = Lang:t('email.message') .. vehicleList,
            button = {}
        })
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
                        local function onEnter()
                            if cache.vehicle and not isBusy then
                                lib.showTextUI(Lang:t('text.disassemble_vehicle'), {position = 'left-center'})
                            end
                        end

                        local function onExit()
                            lib.hideTextUI()
                        end

                        local function inside()
                            if IsControlPressed(0, 38) and not isBusy then
                                lib.hideTextUI()
                                scrapVehicle()
                                return
                            end
                        end

                        lib.zones.box({
                            coords = vec3(v?.coords.x, v?.coords.y, v?.coords.z),
                            size = vec3(4, 4, 4),
                            rotation = v?.heading,
                            debug = Config.DebugZone,
                            inside = inside,
                            onEnter = onEnter,
                            onExit = onExit
                        })
                    else
                        local model = v?.pedModel
                        lib.requestModel(model, 500)
                        local pedList = CreatePed(4, model, v?.coords.x, v?.coords.y, v?.coords.z - 1, v?.coords.w, true, true)
                        FreezeEntityPosition(pedList, true)
                        exports.ox_target:addLocalEntity(pedList, {
                            {
                                name = "scrapyard_list" .. i,
                                label = Lang:t("text.email_list_target"),
                                icon = "fas fa-list-ul",
                                distance = 1.5,
                                onSelect = createListEmail,
                                canInteract = function()
                                    return not emailSent
                                end,
                            }
                        })
                    end
                else
                    if k == 'deliver' then
                        local function onEnter()
                            if cache.vehicle and not isBusy then
                                lib.showTextUI(Lang:t('text.disassemble_vehicle'), {position = 'left-center'})
                            end
                        end

                        local function onExit()
                            lib.hideTextUI()
                        end

                        local function inside()
                            if IsControlPressed(0, 38) and not isBusy then
                                lib.hideTextUI()
                                scrapVehicle()
                                return
                            end
                        end

                        lib.zones.box({
                            coords = vec3(v.coords.x, v.coords.y, v.coords.z),
                            size = vec3(4, 4, 4),
                            rotation = v.heading,
                            debug = Config.DebugZone,
                            inside = inside,
                            onEnter = onEnter,
                            onExit = onExit
                        })
                    else
                        local function onEnter()
                            if not cache.vehicle and not isBusy then
                                lib.showTextUI(Lang:t('text.email_list_target'), {position = 'left-center'})
                            end
                        end

                        local function onExit()
                            lib.hideTextUI()
                        end

                        local function inside()
                            if IsControlPressed(0, 38) and not emailSent then
                                lib.hideTextUI()
                                createListEmail()
                                return
                            end
                        end

                        lib.zones.box({
                            coords = vec3(v.coords.x, v.coords.y, v.coords.z),
                            size = vec3(4, 4, 4),
                            rotation = v.heading,
                            debug = Config.DebugZone,
                            inside = inside,
                            onEnter = onEnter,
                            onExit = onExit
                        })
                    end
                end
            end
        end
    end
end)
