-- as-yacht client/comfort.lua: Day/night lights, hull lights, tenders, layouts and radio.
-- (Split from the former client/main.lua. File-level state is global so every client module shares it.)

function IsNightTime()
    local c = Config.Comfort or {}
    local h = GetClockHours()
    return h >= (c.nightStart or 19) or h < (c.nightEnd or 6)
end

function YachtLightsWanted(yachtId)
    local ex = yachtExtras[yachtId]
    local mode = (ex and ex.lightmode) or "on"
    if mode == "off" then return false end
    if mode == "auto" then return IsNightTime() end
    return true
end

-- Removes the light prop when the schedule says it should be dark (the streaming loop only re-creates it when wanted).
CreateThread(function()
    while true do
        Wait(3000)
        for _, yd in pairs(yachts) do
            if yd.lighting and DoesEntityExist(yd.lighting.handler) and not YachtLightsWanted(yd.yachtiddata) then
                DeleteEntity(yd.lighting.handler)
                yd.lighting.handler = nil
            end
        end
    end
end)

-- Hull lights -------------------------------------------------------------------
-- Returns whether the hull lights are on and the colour id. The "auto" mood follows the time of day.
function EffectiveHull(ex)
    if ex.mood == "auto" and ex.hullowned then
        local h = GetClockHours()
        for _, s in ipairs((Config.Comfort or {}).moodSchedule or {}) do
            local inside
            if s.from <= s.to then inside = h >= s.from and h < s.to else inside = h >= s.from or h < s.to end
            if inside then return true, s.color end
        end
        return false, ex.hullcolor or 1
    end
    return ex.hullon == true, ex.hullcolor or 1
end

hullLit = {}
CreateThread(function()
    local cfg = Config.Comfort and Config.Comfort.hullLights
    if not cfg or not cfg.enabled then return end
    while true do
        -- pick the yachts that need drawing (cheap, once a second)
        hullLit = {}
        local pcoords = GetEntityCoords(PlayerPedId())
        for id, yd in pairs(yachts) do
            local ex = yachtExtras[yd.yachtiddata]
            local main = yd.yachtmainobject
            local on, colorId
            if ex then on, colorId = EffectiveHull(ex) end
            if on and main and DoesEntityExist(main) and #(pcoords - GetEntityCoords(main)) < (cfg.drawDistance or 160.0) then
                local col = cfg.colors[colorId or 1] or cfg.colors[1]
                hullLit[#hullLit + 1] = { entity = main, rgb = col.rgb }
            end
        end
        local frames = #hullLit > 0 and 60 or 0
        if frames == 0 then Wait(1000) end
        for _ = 1, frames do
            for _, h in ipairs(hullLit) do
                if DoesEntityExist(h.entity) then
                    for _, pt in ipairs(cfg.points) do
                        local p = GetOffsetFromEntityInWorldCoords(h.entity, pt.x, pt.y, pt.z)
                        DrawLightWithRange(p.x, p.y, p.z, h.rgb[1], h.rgb[2], h.rgb[3], cfg.range or 14.0, cfg.intensity or 4.0)
                    end
                end
            end
            Wait(0)
        end
    end
end)

-- Onboard radio -----------------------------------------------------------------
CreateThread(function()
    local cfg = Config.Comfort and Config.Comfort.ambience
    if not cfg or not cfg.enabled then return end
    local activeStation = nil
    while true do
        Wait(1500)
        local want = nil
        local ped = PlayerPedId()
        if not isYachtBuyMenuOpen and not IsPedInAnyVehicle(ped, false) then
            local pcoords = GetEntityCoords(ped)
            for _, yd in pairs(yachts) do
                local ex = yachtExtras[yd.yachtiddata]
                if ex and ex.radio and yd.yachtmainobject and DoesEntityExist(yd.yachtmainobject)
                    and #(pcoords - GetEntityCoords(yd.yachtmainobject)) < (cfg.radius or 50.0) then
                    want = ex.radio
                    break
                end
            end
        end
        if want ~= activeStation then
            if want then
                SetFrontendRadioActive(true)
                SetRadioToStationName(want)
            elseif activeStation then
                SetFrontendRadioActive(false)
            end
            activeStation = want
        end
    end
end)

-- Tender -------------------------------------------------------------------------
tenderVehicles = {}   -- [optionId] = { veh = entity, slot = n, air = bool }

function FreeTenderSlot(category, ignoreOptionId)
    local used = {}
    for id, t in pairs(tenderVehicles) do
        if id ~= ignoreOptionId and t.category == category and DoesEntityExist(t.veh) then used[t.slot] = true end
    end
    local slot = 1
    while used[slot] do slot = slot + 1 end
    return slot
end

RegisterNetEvent("asyacht:Global:TenderApproved")
AddEventHandler("asyacht:Global:TenderApproved", function(yachtId, modelName, optionId, fromPurchase)
    local cfg = Config.Comfort and Config.Comfort.tender
    print(("^3AS Yacht^7: vehicle request received (yacht %s, %s)"):format(tostring(yachtId), tostring(modelName)))
    if not cfg then return end

    -- right after buying, the yacht is still streaming in: wait for it
    local yd
    local waited = 0
    while waited < 30000 do
        yd = yachts["yacht-" .. yachtId]
        if yd and DoesEntityExist(yd.yachtmainobject) then break end
        Wait(250) waited = waited + 250
    end
    if not yd or not DoesEntityExist(yd.yachtmainobject) then
        print("^1AS Yacht^7: vehicle not spawned - the yacht was not loaded on your client")
        Notify("Could not place your vehicle: the yacht is not loaded yet. Call it from the Upgrades menu.", "error")
        return
    end

    local model = GetHashKey(modelName)
    if not IsModelInCdimage(model) then Notify("Tender model missing: " .. tostring(modelName), "error") return end
    RequestModel(model)
    local t = 0
    while not HasModelLoaded(model) and t < 5000 do Wait(50) t = t + 50 end
    if not HasModelLoaded(model) then
        print("^1AS Yacht^7: vehicle model failed to load: " .. tostring(modelName))
        Notify("Vehicle model failed to load: " .. tostring(modelName), "error")
        return
    end

    local main = yd.yachtmainobject
    local opt
    for _, o in ipairs(cfg.options) do if o.id == optionId then opt = o end end
    opt = opt or {}
    local air = opt.air == true
    local category = opt.category or "Vehicles"
    local slots = cfg.slots and cfg.slots[category] or {}

    local old = tenderVehicles[optionId]
    local slot = old and old.slot or FreeTenderSlot(category, optionId)
    if old and DoesEntityExist(old.veh) then DeleteEntity(old.veh) end
    local off = slots[slot]
    if not off then
        Notify("There is no free parking spot for that vehicle on your yacht.", "error")
        return
    end

    local pos, heading = TenderSpawnCoords(main, off, model, air, cfg)
    local veh = CreateVehicle(model, pos.x, pos.y, pos.z, heading, true, false)
    SetModelAsNoLongerNeeded(model)
    if not DoesEntityExist(veh) then
        print("^1AS Yacht^7: CreateVehicle failed for " .. tostring(modelName))
        Notify("The game refused to create " .. tostring(modelName), "error")
        return
    end
    print(("^2AS Yacht^7: spawned %s at %.1f %.1f %.1f (slot %d)"):format(tostring(modelName), pos.x, pos.y, pos.z, slot))

    tenderVehicles[optionId] = { veh = veh, slot = slot, category = category }
    SetEntityAsMissionEntity(veh, true, true)
    -- hold it in place until somebody climbs in (a helicopter would fall, a boat could slide off the platform)
    FreezeEntityPosition(veh, true)
    if air then
        SetHeliBladesFullSpeed(veh)
        SetVehicleEngineOn(veh, true, true, false)
        if not fromPurchase then TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1) end
    else
        SetVehicleEngineOn(veh, false, true, false)
    end
    CreateThread(function()
        while DoesEntityExist(veh) and not IsPedInVehicle(PlayerPedId(), veh, false) do Wait(300) end
        if DoesEntityExist(veh) then FreezeEntityPosition(veh, false) end
    end)
    Notify((opt.label or "Vehicle") .. " is waiting next to the yacht.", "success")
end)

-- Pressing F (enter vehicle) next to your yacht vehicles always enters the NEAREST one of them. Without this the
-- game picks whichever vehicle it likes, e.g. the boat instead of the helicopter parked beside you.
CreateThread(function()
    while true do
        local wait = 500
        local ped = PlayerPedId()
        if next(tenderVehicles) ~= nil and not IsPedInAnyVehicle(ped, false) then
            local pcoords = GetEntityCoords(ped)
            local best, bestDist
            for _, t in pairs(tenderVehicles) do
                if DoesEntityExist(t.veh) then
                    local d = #(pcoords - GetEntityCoords(t.veh))
                    if d < 9.0 and (not bestDist or d < bestDist) then best, bestDist = t.veh, d end
                end
            end
            if best then
                wait = 0
                DisableControlAction(0, 23, true)
                if IsDisabledControlJustPressed(0, 23) then
                    TaskEnterVehicle(ped, best, 10000, -1, 1.0, 1, 0)
                end
            end
        end
        Wait(wait)
    end
end)

-- Docking: stores a vehicle again (it can be called back from the Upgrades menu at any time).
function DockTender(optionId)
    local t = tenderVehicles[optionId]
    if not t or not DoesEntityExist(t.veh) then tenderVehicles[optionId] = nil return false end
    local ped = PlayerPedId()
    if IsPedInVehicle(ped, t.veh, false) then
        if GetEntityHeightAboveGround(t.veh) > 4.0 or GetEntitySpeed(t.veh) > 4.0 then
            Notify("Land or stop the vehicle before docking it.", "error")
            return false
        end
        TaskLeaveVehicle(ped, t.veh, 0)
        local waited = 0
        while IsPedInVehicle(ped, t.veh, false) and waited < 4000 do Wait(100) waited = waited + 100 end
    end
    if DoesEntityExist(t.veh) then DeleteEntity(t.veh) end
    tenderVehicles[optionId] = nil
    return true
end

RegisterNUICallback("comfortdock", function(data, cb)
    cb("ok")
    CreateThread(function()
        if DockTender(tonumber(data.id)) then Notify("Vehicle docked.", "success") end
    end)
end)

RegisterCommand("yachtdock", function()
    CreateThread(function()
        local any = false
        -- the vehicle you are in first, otherwise everything you have out
        for id, t in pairs(tenderVehicles) do
            if DoesEntityExist(t.veh) and IsPedInVehicle(PlayerPedId(), t.veh, false) then
                any = DockTender(id) or any
                if any then Notify("Vehicle docked.", "success") end
                return
            end
        end
        for id in pairs(tenderVehicles) do any = DockTender(id) or any end
        Notify(any and "Vehicles docked." or "You have no yacht vehicles out.", any and "success" or "error")
    end)
end, false)

-- Press E to dock: next to a parked yacht vehicle, or while sitting in one that has stopped near the yacht.
CreateThread(function()
    local cfg = Config.Comfort and Config.Comfort.tender
    local key = (cfg and cfg.dockKey) or 38
    local busy = false
    while true do
        local wait = 500
        if next(tenderVehicles) ~= nil and not busy then
            local ped = PlayerPedId()
            local pcoords = GetEntityCoords(ped)
            local target, inside
            for id, t in pairs(tenderVehicles) do
                if DoesEntityExist(t.veh) then
                    if IsPedInVehicle(ped, t.veh, false) then
                        if GetEntitySpeed(t.veh) < 4.0 and GetEntityHeightAboveGround(t.veh) < 4.0 then target, inside = id, true end
                        break
                    elseif not IsPedInAnyVehicle(ped, false) and #(pcoords - GetEntityCoords(t.veh)) < 4.0 then
                        target = id
                    end
                end
            end
            -- only offer it close to a yacht
            if target then
                local nearYacht = false
                for _, yd in pairs(yachts) do
                    if yd.yachtmainobject and DoesEntityExist(yd.yachtmainobject) and #(pcoords - GetEntityCoords(yd.yachtmainobject)) < 120.0 then nearYacht = true break end
                end
                if not nearYacht then target = nil end
            end
            if target then
                wait = 0
                BeginTextCommandDisplayHelp("STRING")
                AddTextComponentSubstringPlayerName("Press ~INPUT_PICKUP~ to dock this vehicle")
                EndTextCommandDisplayHelp(0, false, false, -1)
                if IsControlJustPressed(0, key) then
                    busy = true
                    local id = target
                    CreateThread(function()
                        if DockTender(id) then Notify("Vehicle docked.", "success") end
                        busy = false
                    end)
                end
            end
        end
        Wait(wait)
    end
end)

-- /yachtoffset: stand where a vehicle should appear (helipad, stern...) and run this.
-- It prints your position relative to the nearest yacht, ready to paste into Config.Comfort.tender.
RegisterCommand("yachtoffset", function()
    local ped = PlayerPedId()
    local pcoords = GetEntityCoords(ped)
    local best, bestDist
    for _, yd in pairs(yachts) do
        if yd.yachtmainobject and DoesEntityExist(yd.yachtmainobject) then
            local d = #(pcoords - GetEntityCoords(yd.yachtmainobject))
            if not bestDist or d < bestDist then best, bestDist = yd, d end
        end
    end
    if not best then Notify("No yacht nearby.", "error") return end
    local o = GetOffsetFromEntityGivenWorldCoords(best.yachtmainobject, pcoords.x, pcoords.y, pcoords.z)
    local text = ("vector3(%.2f, %.2f, %.2f)"):format(o.x, o.y, o.z)
    print("^2AS Yacht offset^7: " .. text)
    Notify("Offset from yacht: " .. text .. "  (also in the F8 console)", "info")
end, false)

-- NUI bridge for the comfort panel ---------------------------------------------------
function ComfortCallback(name, eventName, argsFn)
    RegisterNUICallback(name, function(data, cb)
        cb("ok")
        if isManagementMenuOpen and managementMenuYachtId ~= nil then
            TriggerServerEvent(eventName, managementMenuYachtId, argsFn(data))
        end
    end)
end

ComfortCallback("comfortlight",       "asyacht:Global:SetLightMode", function(d) return tostring(d.mode or "") end)
ComfortCallback("comfortradio",       "asyacht:Global:SetRadio",     function(d) return tostring(d.station or "") end)
ComfortCallback("comfortbuytender",   "asyacht:Global:BuyTender",    function(d) return tonumber(d.id) end)
ComfortCallback("comfortspawntender", "asyacht:Global:SpawnTender",  function(d) return tonumber(d.id) end)
ComfortCallback("comfortsavelayout",  "asyacht:Global:SaveLayout",   function(d) return tostring(d.name or "") end)
ComfortCallback("comfortloadlayout",  "asyacht:Global:LoadLayout",   function(d) return tonumber(d.index) end)
ComfortCallback("comfortdeletelayout","asyacht:Global:DeleteLayout", function(d) return tonumber(d.index) end)
ComfortCallback("comfortmood",         "asyacht:Global:SetMood",       function(d) return tostring(d.mood or "") end)
ComfortCallback("comfortexportlayout", "asyacht:Global:ExportLayout", function(d) return tonumber(d.index) end)
ComfortCallback("comfortimportlayout", "asyacht:Global:ImportLayout", function(d) return tostring(d.code or "") end)
ComfortCallback("comfortbuymissing",   "asyacht:Global:LayoutBuyMissing", function(d) return tonumber(d.index) end)
ComfortCallback("upgradeupkeep",       "asyacht:Global:PayUpkeep",    function() return nil end)
ComfortCallback("upgraderepair",       "asyacht:Global:RepairYacht",  function() return nil end)

-- The server sends the share code of a layout; the panel shows it in a box to copy.
RegisterNetEvent("asyacht:Global:LayoutCode")
AddEventHandler("asyacht:Global:LayoutCode", function(name, code)
    if not isManagementMenuOpen then return end
    SendNUIMessage({ message = "layoutcode", name = name, code = code })
end)

RegisterNUICallback("comfortHull", function(data, cb)
    cb("ok")
    if isManagementMenuOpen and managementMenuYachtId ~= nil then
        TriggerServerEvent("asyacht:Global:SetHullLights", managementMenuYachtId, tonumber(data.color), data.on == true)
    end
end)
