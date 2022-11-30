local QBCore = exports['qb-core']:GetCoreObject()
local emailSend = false
local isBusy = false
local CurrentVehicles = {}

RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
    TriggerServerEvent("qb-scrapyard:server:LoadVehicleList")
end)

CreateThread(function()
    for id in pairs(Config.Locations) do
        local blip = AddBlipForCoord(Config.Locations[id]["main"].x, Config.Locations[id]["main"].y, Config.Locations[id]["main"].z)

        SetBlipSprite(blip, 380)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.7)
        SetBlipAsShortRange(blip, true)
        SetBlipColour(blip, 9)

        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(Lang:t('text.scrapyard'))
        EndTextCommandSetBlipName(blip)
    end
end)

local listen = false

local function KeyListener(type)
    CreateThread(function()
        listen = true

        while listen do
            if IsControlPressed(0, 38) then
                if type == 'deliver' then
                    ScrapVehicle()
                else
                    if not IsPedInAnyVehicle(cache.ped) and not emailSend then
                        CreateListEmail()
                    end
                end
                break
            end

            Wait(0)
        end
    end)
end

CreateThread(function()
    local scrapPoly = {}

    for i = 1,#Config.Locations,1 do
        for k, v in pairs(Config.Locations[i]) do
            if k ~= 'main' then
                if Config.UseTarget then
                    if k == 'deliver' then
                        exports.ox_target:addBoxZone({
                            coords = v.coords,
                            size = vec3(2, 2, 2),
                            rotation = v.heading,
                            options = {
                                {
                                    name = 'qb-scrapyard:scrapVehicle',
                                    icon = "fa fa-wrench",
                                    label = Lang:t('text.disassemble_vehicle_target'),
                                    distance = 3,
                                    onSelect = function(_)
                                        ScrapVehicle()
                                    end
                                }
                            }
                        })
                    else
                        exports.ox_target:addBoxZone({
                            coords = v.coords,
                            size = vec3(2, 2, 2),
                            rotation = v.heading,
                            options = {
                                {
                                    name = 'qb-scrapyard:emailList',
                                    icon = "fa fa-envelop",
                                    label = Lang:t('text.email_list_target'),
                                    distance = 1.5,
                                    onSelect = function(_)
                                        if not IsPedInAnyVehicle(cache.ped) and not emailSend then
                                            CreateListEmail()
                                        end
                                    end
                                }
                            }
                        })
                    end
                else
                    scrapPoly[#scrapPoly + 1] = lib.zones.box({
                        coords = v.coords,
                        size = vec3(1, 1, 1),
                        rotation = 0.0,
                        onEnter = function(_)
                            if not isBusy then
                                if k == 'deliver' then
                                    lib.showTextUI(Lang:t('text.disassemble_vehicle'))
                                else
                                    lib.showTextUI(Lang:t('text.email_list'))
                                end

                                KeyListener(k)
                            end
                        end,
                        onExit = function(_)
                            listen = false

                            lib.hideTextUI()
                        end
                    })
                end
            end
        end
    end
end)

RegisterNetEvent('qb-scapyard:client:setNewVehicles', function(vehicleList)
    CurrentVehicles = vehicleList
end)

function CreateListEmail()
    if CurrentVehicles and next(CurrentVehicles) then
        emailSend = true

        local vehicleList = ""

        for k, v in pairs(CurrentVehicles) do
            if CurrentVehicles[k] then
                local vehicleInfo = QBCore.Shared.Vehicles[v]

                if vehicleInfo then
                    vehicleList = vehicleList  .. vehicleInfo.brand .. " " .. vehicleInfo.name .. "<br>"
                end
            end
        end

        SetTimeout(math.random(15000, 20000), function()
            emailSend = false

            TriggerServerEvent('qb-phone:server:sendNewMail', {
                sender = Lang:t('email.sender'),
                subject = Lang:t('email.subject'),
                message = Lang:t('email.message').. vehicleList,
                button = {}
            })
        end)
    else
        QBCore.Functions.Notify(Lang:t('error.demolish_vehicle'), "error")
    end
end

function ScrapVehicle()
    local vehicle = GetVehiclePedIsIn(cache.ped, true)

    if vehicle then
        if not isBusy then
            if GetPedInVehicleSeat(vehicle, -1) == cache.ped then
                if IsVehicleValid(GetEntityModel(vehicle)) then
                    local vehiclePlate = QBCore.Functions.GetPlate(vehicle)

                    QBCore.Functions.TriggerCallback('qb-scrapyard:checkOwnerVehicle', function(retval)
                        if retval then
                            isBusy = true

                            local scrapTime = math.random(28000, 37000)

                            ScrapVehicleAnim(scrapTime)

                            QBCore.Functions.Progressbar("scrap_vehicle", Lang:t('text.demolish_vehicle'), scrapTime, false, true, {
                                disableMovement = true,
                                disableCarMovement = true,
                                disableMouse = false,
                                disableCombat = true
                            }, {}, {}, {}, function() -- Done
                                TriggerServerEvent("qb-scrapyard:server:ScrapVehicle", GetVehicleKey(GetEntityModel(vehicle)))

                                SetEntityAsMissionEntity(vehicle, true, true)
                                DeleteVehicle(vehicle)

                                isBusy = false
                            end, function() -- Cancel
                                isBusy = false

                                QBCore.Functions.Notify(Lang:t('error.canceled'), "error")
                            end)
                        else
                            QBCore.Functions.Notify(Lang:t('error.smash_own'), "error")
                        end
                    end, vehiclePlate)
                else
                    QBCore.Functions.Notify(Lang:t('error.cannot_scrap'), "error")
                end
            else
                QBCore.Functions.Notify(Lang:t('error.not_driver'), "error")
            end
        end
    end
end

function IsVehicleValid(vehicleModel)
    local retval = false

    if CurrentVehicles and next(CurrentVehicles) then
        for k in pairs(CurrentVehicles) do
            if CurrentVehicles[k] and joaat(CurrentVehicles[k]) == vehicleModel then
                retval = true
            end
        end
    end

    return retval
end

function GetVehicleKey(vehicleModel)
    local retval = 0

    if CurrentVehicles and next(CurrentVehicles) then
        for k in pairs(CurrentVehicles) do
            if joaat(CurrentVehicles[k]) == vehicleModel then
                retval = k
            end
        end
    end

    return retval
end

function ScrapVehicleAnim(time)
    time = (time / 1000)

    lib.requestAnimDict("mp_car_bomb")

    TaskPlayAnim(cache.ped, "mp_car_bomb", "car_bomb_mechanic" ,3.0, 3.0, -1, 16, 0, false, false, false)

    local openingDoor = true

    CreateThread(function()
        while openingDoor do
            TaskPlayAnim(cache.ped, "mp_car_bomb", "car_bomb_mechanic", 3.0, 3.0, -1, 16, 0, 0, 0, 0)

            Wait(2000)

            time = time - 2

            if time <= 0 or not isBusy then
                openingDoor = false

                StopAnimTask(cache.ped, "mp_car_bomb", "car_bomb_mechanic", 1.0)
                RemoveAnimDict("mp_car_bomb")
            end
        end
    end)
end