-- as-yacht client/buymenu.lua: Appearance refresh, buy menu events and specs.
-- (Split from the former client/main.lua. File-level state is global so every client module shares it.)

function GetYachtEngineStats(yachtId)
    local extras = yachtExtras[yachtId]
    local tiers = Config.Upgrades and Config.Upgrades.engine
    return tiers and tiers[(extras and extras.enginetier) or 1] or nil
end

-- Repaints an existing yacht and re-creates its flag / lights / railing props from the current data.
function RefreshYachtAppearance(yachtId)
    local yd = yachts["yacht-" .. yachtId]
    if not yd then return end
    local colCfg = Config.YachColors[yd.yachtcolor]
    if not colCfg then return end
    local railingColour = GetRailingColour(yd.railing.railingid)

    local function paintVehicle(veh, dashboardColour)
        SetVehicleModColor_1(veh, 1, colCfg.primary, 0)
        SetVehicleModColor_2(veh, 1, colCfg.secondary)
        SetVehicleColours(veh, colCfg.primary, colCfg.secondary)
        SetVehicleDashboardColor(veh, dashboardColour)
        SetVehicleInteriorColor(veh, railingColour)
        SetObjectTextureVariant(veh, colCfg.overlay)
    end

    if DoesEntityExist(yd.yachtmainobject) then paintVehicle(yd.yachtmainobject, colCfg.interior) end
    for _, objData in ipairs(yd.mainobjects) do
        if DoesEntityExist(objData.handler) then
            if objData.objectname == "as_apa_mp_apa_yacht_option3" then
                paintVehicle(objData.handler, colCfg.primary)
            else
                SetObjectTextureVariant(objData.handler, colCfg.overlay)
            end
        end
    end
    for _, door in ipairs(yd.doors) do
        if DoesEntityExist(door.handler) then SetObjectTextureVariant(door.handler, colCfg.overlay) end
    end

    -- Props that depend on the chosen flag / lights / railing are deleted; the streaming loop re-creates them.
    for _, holder in ipairs({ yd.flagdata, yd.lighting }) do
        if DoesEntityExist(holder.handler) then DeleteEntity(holder.handler) end
        holder.handler = nil
    end
    for _, field in ipairs({ "handler2", "handler3" }) do
        if DoesEntityExist(yd.railing[field]) then DeleteEntity(yd.railing[field]) end
        yd.railing[field] = nil
    end
end

RegisterNetEvent("asyacht:Global:YachtAppearanceUpdated")
AddEventHandler("asyacht:Global:YachtAppearanceUpdated", function(yachtId, flagId, lightCat, lightId, railingId, colorId)
    local yd = yachts["yacht-" .. yachtId]
    if not yd then return end
    yd.flagdata.flagid = flagId
    yd.lighting.lightingcategory = lightCat
    yd.lighting.lightingid = lightId
    yd.railing.railingid = railingId
    yd.yachtcolor = colorId
    RefreshYachtAppearance(yachtId)
end)

RegisterNetEvent("asyacht:Global:YachtTextUpdated")
AddEventHandler("asyacht:Global:YachtTextUpdated", function(yachtId, upper, bottom)
    local yd = yachts["yacht-" .. yachtId]
    if not yd then return end
    yd.textdata.uppertext = upper
    yd.textdata.bottomtext = bottom
    RefreshYachtBlipName(yachtId) -- the name plate redraws itself when the text changes
end)

RegisterNetEvent("asyacht:Global:ExitRejected")
AddEventHandler("asyacht:Global:ExitRejected", function()
    if drivingState.driving and DoesEntityExist(drivingState.yachthandler) then
        FreezeEntityPosition(drivingState.yachthandler, false)
    end
end)

RegisterNetEvent("asyacht:Notify")
AddEventHandler("asyacht:Notify", function(message, ntype)
    Notify(message, ntype)
end)

function BuildYachtSpecs()
    return {
        { icon = "fa-hot-tub-person", label = "Hot tub seats", value = tostring(Config.YachtHottubSeatCount) },
        { icon = "fa-door-open",      label = "Doors",          value = tostring(Config.YachtDoorCount) },
        { icon = "fa-box-open",       label = "Storage rooms",  value = tostring(#Config.YachtStorageLocations) },
        { icon = "fa-shirt",          label = "Wardrobes",      value = tostring(#Config.YachtWardrobeLocations) },
    }
end

RegisterNetEvent("asyacht:Global:BuyMenuBalances")
AddEventHandler("asyacht:Global:BuyMenuBalances", function(cash, bank)
    SendNUIMessage({ message = "buybalances", cash = cash or 0, bank = bank or 0 })
end)

RegisterNetEvent("asyacht:Global:BuyRejected")
AddEventHandler("asyacht:Global:BuyRejected", function()
    buyPending = false
    SendNUIMessage({ message = "buyrejected" })
end)

function BuildBuyUpgradeList()
    local U = Config.Upgrades
    if not U or not U.enabled then return nil end
    local out = { engines = {}, storages = {} }
    for id, e in ipairs(U.engine) do out.engines[id] = { id = id, label = e.label, price = id > 1 and e.price or 0, detail = "x" .. tostring(e.power) .. " power" } end
    out.tenders = {}
    out.tenderlimits = {}
    local tcfg = Config.Comfort and Config.Comfort.tender
    if tcfg and tcfg.enabled then
        for cat, slots in pairs(tcfg.slots or {}) do out.tenderlimits[cat] = #slots end
        for _, o in ipairs(tcfg.options) do out.tenders[#out.tenders + 1] = { id = o.id, label = o.label, category = o.category or "Vehicles", price = o.price } end
    end
    for id, e in ipairs(U.storage) do out.storages[id] = { id = id, label = e.label, price = id > 1 and e.price or 0, detail = tostring(e.slots) .. " slots" } end
    return out
end

RegisterNetEvent("asyacht:Global:OpenYachtBuyClient")
AddEventHandler("asyacht:Global:OpenYachtBuyClient", function()
    if isYachtBuyMenuOpen then return end

    ClearYachtBuyPreview()
    previewSessionId = previewSessionId + 1
    previewLightRequestId = previewLightRequestId + 1
    local sessionId = previewSessionId
    isYachtBuyMenuOpen = true
    if Config.HideHudInBuyMenu and not buyHudHidden then
        buyHudHidden = true
        pcall(SetYachtHudVisible, false)
    end

    yachtBuyState.flagdata   = {flagid=1, handler=nil, coords=vector3(-56.55, -2.0, 1.5), rotation=vector3(0.0, 130.0, 0.0)}
    yachtBuyState.lighting   = {lightingcategory=1, lightingid=1, handler=nil, coords=vector3(0.0, 0.0, 14.5), rotation=vector3(0.0, 0.0, 0.0)}
    yachtBuyState.railing    = {railingid=1, handler=nil, coords=vector3(0.0, 0.0, 14.57), rotation=vector3(0.0, 0.0, 0.0)}
    yachtBuyState.textdata   = {uppertext="", bottomtext=""}
    yachtBuyState.yachtcolor = 1
    activeCameraIndex        = 1
    currentYachtColorIndex   = 1
    currentBuyCameraIndex    = 1
    isCameraTransitioning    = false

    if DoesCamExist(buyCameraMain) then DestroyCam(buyCameraMain, false) end
    buyCameraMain = CreateCam("DEFAULT_SCRIPTED_CAMERA", 1)
    SetCamCoord(buyCameraMain, Config.YachtBuyLocation.yachtbuycameras[1].coords)
    SetCamRot(buyCameraMain, Config.YachtBuyLocation.yachtbuycameras[1].rotation)

    if DoesCamExist(buyCameraAlt) then DestroyCam(buyCameraAlt, false) end
    buyCameraAlt = CreateCam("DEFAULT_SCRIPTED_CAMERA", 1)
    SetCamCoord(buyCameraAlt, Config.YachtBuyLocation.yachtbuycameras[2].coords)
    SetCamRot(buyCameraAlt, Config.YachtBuyLocation.yachtbuycameras[2].rotation)

    SetCamActive(buyCameraMain, true)
    RenderScriptCams(true, 100, 100, true, false)
    SetNuiFocus(true, true)

    local ps = Config.YachtPriceSettings
    local railingList = {}
    for id, r in ipairs(Config.RailingTypes) do
        railingList[#railingList + 1] = { id = id, label = r.label, price = r.price, swatch = r.swatch }
    end
    buyPending = false
    ClearPreviewEnv()
    local camLabels = {}
    for i, c in ipairs(Config.BuyCameraPresets or {}) do camLabels[i] = c.label end
    local timeList, weatherList = {}, {}
    for i, t in ipairs(Config.BuyPreview.times) do timeList[i] = t.label end
    for i, w in ipairs(Config.BuyPreview.weathers) do weatherList[i] = w.label end
    SendNUIMessage({
        message              = "yachtbuyshow",
        payment              = Config.Payment,
        namerules            = { minLength = Config.NameRules.minLength, maxLength = Config.NameRules.maxLength, blockedWords = Config.NameRules.blockedWords },
        camlabels            = camLabels,
        timelist             = timeList,
        weatherlist          = weatherList,
        sounds               = Config.BuyPreview.sounds,
        specs                = BuildYachtSpecs(),
        yachtprice           = ps.yachtprice,
        yachtlightingprice1  = ps.yachtlightingprice[1],
        yachtlightingprice2  = ps.yachtlightingprice[2],
        railings             = railingList,
        buyupgrades          = BuildBuyUpgradeList(),
        yachtequipmentprice1 = ps.yachtequipmentprice[1],
        yachtequipmentprice2 = ps.yachtequipmentprice[2],
    })

    Citizen.CreateThread(function()
        YachtSpawnBuy(sessionId)
    end)
end)

RegisterNetEvent("asyacht:Global:CloseYachtBuyMenu")
AddEventHandler("asyacht:Global:CloseYachtBuyMenu", function()
    isYachtBuyMenuOpen = false
    buyPending = false
    ClearPreviewEnv()
    if buyHudHidden then
        buyHudHidden = false
        pcall(SetYachtHudVisible, true)
    end
    ClearPreviewTenders()
    previewLightRequestId = previewLightRequestId + 1

    if DoesCamExist(buyCameraMain) then DestroyCam(buyCameraMain, false) end
    if DoesCamExist(buyCameraAlt)  then DestroyCam(buyCameraAlt,  false) end
    RenderScriptCams(false, 0, 0, true, false)

    SendNUIMessage({message = "hidebuymenu"})
    SetNuiFocus(false, false)
end)

RegisterNetEvent("asyacht:Global:SpawnPlayerOnYacht")
AddEventHandler("asyacht:Global:SpawnPlayerOnYacht", function(yachtId)
    Citizen.CreateThread(function()
        local yachtData = yachts["yacht-" .. yachtId]
        while not yachtData or not DoesEntityExist(yachtData.yachtmainobject) do
            Citizen.Wait(5)
            yachtData = yachts["yacht-" .. yachtId]
        end

        yachtIntroPlayed[yachtId] = true
        CreatePersonalYachtBlip(yachtId)

        local yachtCoords = GetEntityCoords(yachtData.yachtmainobject)
        local yachtRot    = GetEntityRotation(yachtData.yachtmainobject, 2)
        local spawnOffset = vector3(0.113886, -22.089855, 12.356288)
        local rad         = math.rad(yachtRot.z)
        local cosZ, sinZ  = math.cos(rad), math.sin(rad)

        local spawnPos = vector3(
            spawnOffset.x * cosZ - spawnOffset.y * sinZ + yachtCoords.x,
            spawnOffset.y * cosZ + spawnOffset.x * sinZ + yachtCoords.y,
            spawnOffset.z + yachtCoords.z + 0.5)

        local playerPed = PlayerPedId()
        FreezeEntityPosition(playerPed, true)
        SetEntityCoordsNoOffset(playerPed, spawnPos.x, spawnPos.y, spawnPos.z)
        Citizen.Wait(100)
        FreezeEntityPosition(playerPed, false)

        yachtRot    = GetEntityRotation(yachtData.yachtmainobject, 2)
        yachtCoords = GetEntityCoords(yachtData.yachtmainobject)
        local camPos1 = GetOffsetFromEntityInWorldCoords(yachtData.yachtmainobject, 45.0, 70.0, 17.8)
        local camPos2 = GetOffsetFromEntityInWorldCoords(yachtData.yachtmainobject, 20.0, -80.0, 17.8)

        local cam1 = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA",
            camPos1.x, camPos1.y, camPos1.z, yachtRot.x, yachtRot.y, yachtRot.z + 150.0, 70.0, true, 2)
        local cam2 = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA",
            camPos2.x, camPos2.y, camPos2.z, yachtRot.x, yachtRot.y, yachtRot.z - 300.0, 70.0, true, 2)

        SetCamActive(cam1, true)
        RenderScriptCams(true, 100, 100, true, false)
        SetCamActiveWithInterp(cam2, cam1, 8000, 1, 1)
        Citizen.Wait(8500)
        RenderScriptCams(false, 1500, 1500, true, false)

        if DoesCamExist(cam1) then DestroyCam(cam1, false) end
        if DoesCamExist(cam2) then DestroyCam(cam2, false) end
    end)
end)

RegisterNetEvent("asyacht:Global:YachtGotPlayer")
AddEventHandler("asyacht:Global:YachtGotPlayer", function(yachtId)
    Citizen.CreateThread(function()
        yachtIntroPlayed[yachtId] = true
        local yachtData = yachts["yacht-" .. yachtId]
        while not yachtData or not DoesEntityExist(yachtData.yachtmainobject) do
            Citizen.Wait(5)
            yachtData = yachts["yacht-" .. yachtId]
        end
        CreatePersonalYachtBlip(yachtId)
    end)
end)
