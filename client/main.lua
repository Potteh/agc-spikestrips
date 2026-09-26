local QBCore = exports['qb-core']:GetCoreObject()
local objects = {}
local stripData = {}
local placing = false

local function notify(msg, typ)
    QBCore.Functions.Notify(msg, typ or 'primary')
end

local function loadModel(model)
    if not IsModelInCdimage(model) then return false end
    RequestModel(model)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(model) and GetGameTimer() < timeout do Wait(0) end
    return HasModelLoaded(model)
end

local function deleteLocal(id)
    local obj = objects[id]
    if obj and DoesEntityExist(obj) then DeleteEntity(obj) end
    objects[id] = nil
    stripData[id] = nil
end

local function createLocal(strip)
    if not strip or not strip.id or objects[strip.id] then return end
    if not loadModel(Config.SpikeModel) then return end
    local c = strip.coords
    local obj = CreateObjectNoOffset(Config.SpikeModel, c.x, c.y, c.z + Config.GroundOffset, false, false, false)
    SetEntityHeading(obj, strip.heading or 0.0)
    PlaceObjectOnGroundProperly(obj)
    FreezeEntityPosition(obj, true)
    SetEntityCollision(obj, true, true)
    SetEntityAsMissionEntity(obj, true, true)
    objects[strip.id] = obj
    stripData[strip.id] = strip
    SetModelAsNoLongerNeeded(Config.SpikeModel)
end

RegisterNetEvent('agc-spikestrips:client:sync', function(serverStrips)
    for id in pairs(objects) do deleteLocal(id) end
    for _, strip in pairs(serverStrips or {}) do createLocal(strip) end
end)

RegisterNetEvent('agc-spikestrips:client:add', createLocal)
RegisterNetEvent('agc-spikestrips:client:remove', deleteLocal)

local function drawHelp(text)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

local function startPlacement()
    if placing then return end
    local pdata = QBCore.Functions.GetPlayerData()
    local job = pdata.job
    if not job or not Config.AllowedJobs[job.name] then return notify('Police only.', 'error') end
    if Config.RequireOnDuty and not job.onduty then return notify('You must be on duty.', 'error') end
    if IsPedInAnyVehicle(PlayerPedId(), false) then return notify('Exit the vehicle first.', 'error') end
    if not loadModel(Config.SpikeModel) then return notify('Spike strip model could not be loaded.', 'error') end

    placing = true
    local ped = PlayerPedId()
    local heading = GetEntityHeading(ped)
    local preview = CreateObjectNoOffset(Config.SpikeModel, 0.0, 0.0, 0.0, false, false, false)
    SetEntityAlpha(preview, 170, false)
    SetEntityCollision(preview, false, false)
    FreezeEntityPosition(preview, true)

    CreateThread(function()
        while placing do
            ped = PlayerPedId()
            local p = GetEntityCoords(ped)
            local rad = math.rad(GetEntityHeading(ped))
            local x = p.x + (-math.sin(rad) * Config.PlaceDistance)
            local y = p.y + ( math.cos(rad) * Config.PlaceDistance)
            local found, groundZ = GetGroundZFor_3dCoord(x, y, p.z + 2.0, false)
            local z = found and groundZ or p.z
            SetEntityCoordsNoOffset(preview, x, y, z + Config.GroundOffset, false, false, false)
            SetEntityHeading(preview, heading)
            drawHelp('~INPUT_CONTEXT~ Place  |  ~INPUT_CELLPHONE_LEFT~/~INPUT_CELLPHONE_RIGHT~ Rotate  |  ~INPUT_FRONTEND_RRIGHT~ Cancel')

            if IsControlPressed(0, 174) then heading = heading + 1.5 end
            if IsControlPressed(0, 175) then heading = heading - 1.5 end
            if IsControlJustPressed(0, 38) then
                local c = GetEntityCoords(preview)
                DeleteEntity(preview)
                placing = false
                TriggerServerEvent('agc-spikestrips:server:place', {x=c.x,y=c.y,z=c.z}, heading)
                break
            elseif IsControlJustPressed(0, 177) then
                DeleteEntity(preview)
                placing = false
                break
            end
            Wait(0)
        end
    end)
end

local function nearestStrip(maxDistance)
    local p = GetEntityCoords(PlayerPedId())
    local nearest, dist
    for id, obj in pairs(objects) do
        if DoesEntityExist(obj) then
            local d = #(p - GetEntityCoords(obj))
            if d <= maxDistance and (not dist or d < dist) then nearest, dist = id, d end
        end
    end
    return nearest
end

local function playPickup()
    local a = Config.PickupAnimation
    RequestAnimDict(a.dict)
    local timeout = GetGameTimer() + 3000
    while not HasAnimDictLoaded(a.dict) and GetGameTimer() < timeout do Wait(0) end
    if HasAnimDictLoaded(a.dict) then
        TaskPlayAnim(PlayerPedId(), a.dict, a.name, 8.0, -8.0, a.duration, 0, 0.0, false, false, false)
        Wait(a.duration)
    end
end

RegisterCommand(Config.PlaceCommand, startPlacement, false)
RegisterCommand(Config.RemoveCommand, function()
    local id = nearestStrip(Config.RemoveDistance)
    if not id then return notify('No spike strip nearby.', 'error') end
    playPickup()
    TriggerServerEvent('agc-spikestrips:server:remove', id)
end, false)
RegisterCommand(Config.ClearCommand, function()
    TriggerServerEvent('agc-spikestrips:server:clearMine')
end, false)

CreateThread(function()
    while true do
        local sleep = 500
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped, false)
            local vc = GetEntityCoords(veh)
            for _, obj in pairs(objects) do
                if DoesEntityExist(obj) and #(vc - GetEntityCoords(obj)) < 8.0 then
                    sleep = Config.CheckInterval
                    for _, tire in ipairs(Config.Tires) do
                        local bone = GetEntityBoneIndexByName(veh, tire.bone)
                        if bone ~= -1 then
                            local wheel = GetWorldPositionOfEntityBone(veh, bone)
                            local localPos = GetOffsetFromEntityGivenWorldCoords(obj, wheel.x, wheel.y, wheel.z)
                            -- p_ld_stinger_s runs mostly along its local X axis.
                            if math.abs(localPos.y) <= Config.PunctureDistance and math.abs(localPos.x) <= 2.4 and math.abs(localPos.z) <= 0.75 then
                                if not IsVehicleTyreBurst(veh, tire.index, false) then
                                    SetVehicleTyreBurst(veh, tire.index, false, 1000.0)
                                end
                            end
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

CreateThread(function()
    Wait(1500)
    TriggerServerEvent('agc-spikestrips:server:requestSync')
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(1000)
    TriggerServerEvent('agc-spikestrips:server:requestSync')
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for id in pairs(objects) do deleteLocal(id) end
end)
