local QBCore = exports['qb-core']:GetCoreObject()
local strips = {}
local nextId = 1

local function isAuthorized(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false, 'Player not found.' end
    local job = Player.PlayerData.job
    if not job or not Config.AllowedJobs[job.name] then
        return false, 'You are not authorized to deploy spike strips.'
    end
    if Config.RequireOnDuty and not job.onduty then
        return false, 'You must be on duty.'
    end
    if Config.RequireItem then
        local item = Player.Functions.GetItemByName(Config.ItemName)
        if not item or (item.amount or 0) < 1 then
            return false, ('You need a %s.'):format(Config.ItemName)
        end
    end
    return true, nil, Player
end

local function ownerCount(src)
    local count = 0
    for _, strip in pairs(strips) do
        if strip.owner == src then count = count + 1 end
    end
    return count
end

RegisterNetEvent('agc-spikestrips:server:requestSync', function()
    TriggerClientEvent('agc-spikestrips:client:sync', source, strips)
end)

RegisterNetEvent('agc-spikestrips:server:place', function(coords, heading)
    local src = source
    local ok, reason, Player = isAuthorized(src)
    if not ok then
        TriggerClientEvent('QBCore:Notify', src, reason, 'error')
        return
    end
    if ownerCount(src) >= Config.MaxPerOfficer then
        TriggerClientEvent('QBCore:Notify', src, ('Maximum %d spike strips deployed.'):format(Config.MaxPerOfficer), 'error')
        return
    end
    if type(coords) ~= 'table' or not coords.x or not coords.y or not coords.z then return end

    if Config.RequireItem and Config.ConsumeItem then
        if not Player.Functions.RemoveItem(Config.ItemName, 1) then
            TriggerClientEvent('QBCore:Notify', src, 'Unable to remove spike strip item.', 'error')
            return
        end
    end

    local id = nextId
    nextId = nextId + 1
    strips[id] = {
        id = id,
        owner = src,
        coords = { x = coords.x + 0.0, y = coords.y + 0.0, z = coords.z + 0.0 },
        heading = (heading or 0.0) + 0.0,
    }
    TriggerClientEvent('agc-spikestrips:client:add', -1, strips[id])
    TriggerClientEvent('QBCore:Notify', src, 'Spike strip deployed.', 'success')
end)

RegisterNetEvent('agc-spikestrips:server:remove', function(id)
    local src = source
    local ok, reason, Player = isAuthorized(src)
    if not ok then
        TriggerClientEvent('QBCore:Notify', src, reason, 'error')
        return
    end
    id = tonumber(id)
    local strip = id and strips[id]
    if not strip then return end

    strips[id] = nil
    if Config.RequireItem and Config.ConsumeItem then
        Player.Functions.AddItem(Config.ItemName, 1)
    end
    TriggerClientEvent('agc-spikestrips:client:remove', -1, id)
    TriggerClientEvent('QBCore:Notify', src, 'Spike strip picked up.', 'success')
end)

RegisterNetEvent('agc-spikestrips:server:clearMine', function()
    local src = source
    local ok, reason, Player = isAuthorized(src)
    if not ok then
        TriggerClientEvent('QBCore:Notify', src, reason, 'error')
        return
    end
    local removed = 0
    for id, strip in pairs(strips) do
        if strip.owner == src then
            strips[id] = nil
            removed = removed + 1
            TriggerClientEvent('agc-spikestrips:client:remove', -1, id)
        end
    end
    if Config.RequireItem and Config.ConsumeItem and removed > 0 then
        Player.Functions.AddItem(Config.ItemName, removed)
    end
    TriggerClientEvent('QBCore:Notify', src, ('Removed %d spike strip(s).'):format(removed), 'success')
end)

AddEventHandler('playerDropped', function()
    local src = source
    for id, strip in pairs(strips) do
        if strip.owner == src then
            strips[id] = nil
            TriggerClientEvent('agc-spikestrips:client:remove', -1, id)
        end
    end
end)
