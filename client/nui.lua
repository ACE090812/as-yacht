-- as-yacht client/nui.lua: Buy menu, permissions, transfer and upgrade NUI callbacks.
-- (Split from the former client/main.lua. File-level state is global so every client module shares it.)

RegisterNUICallback("buycamerachange", function(data, cb)
    if not isYachtBuyMenuOpen then cb("ok") return end
    if isCameraTransitioning then cb("ok") return end
    isCameraTransitioning = true

    local cameras = Config.YachtBuyLocation.yachtbuycameras
    if currentBuyCameraIndex == #cameras then
        currentBuyCameraIndex = 1
    else
        currentBuyCameraIndex = currentBuyCameraIndex + 1
    end

    local nextCamCfg  = cameras[currentBuyCameraIndex]
    local cameraspeed = nextCamCfg.cameraspeed or 5000
    StopCamPointing(buyCameraMain)
    StopCamPointing(buyCameraAlt)

    if activeCameraIndex == 1 then
        SetCamCoord(buyCameraAlt, nextCamCfg.coords)
        SetCamRot(buyCameraAlt, nextCamCfg.rotation)
        activeCameraIndex = 2
        SetCamActiveWithInterp(buyCameraAlt, buyCameraMain, cameraspeed, 1, 1)
    else
        SetCamCoord(buyCameraMain, nextCamCfg.coords)
        SetCamRot(buyCameraMain, nextCamCfg.rotation)
        activeCameraIndex = 1
        SetCamActiveWithInterp(buyCameraMain, buyCameraAlt, cameraspeed, 1, 1)
    end

    Citizen.Wait(cameraspeed)
    isCameraTransitioning = false
    cb("ok")
end)

buyTourActive = false

function ApplyBuyCameraPreset(index)
    if not isYachtBuyMenuOpen or isCameraTransitioning then return end
    local preset = Config.BuyCameraPresets[math.floor(tonumber(index) or 0)]
    local obj = yachtBuyState.yachtbuyobject
    if not preset or not obj or not DoesEntityExist(obj) then return end
    isCameraTransitioning = true

    local pos = GetOffsetFromEntityInWorldCoords(obj, preset.offset.x, preset.offset.y, preset.offset.z)
    local nextCam, prevCam
    if activeCameraIndex == 1 then
        nextCam, prevCam = buyCameraAlt, buyCameraMain
        activeCameraIndex = 2
    else
        nextCam, prevCam = buyCameraMain, buyCameraAlt
        activeCameraIndex = 1
    end
    StopCamPointing(nextCam)
    SetCamCoord(nextCam, pos.x, pos.y, pos.z)
    PointCamAtEntity(nextCam, obj, 0.0, 0.0, 8.0, true)
    SetCamActiveWithInterp(nextCam, prevCam, 1500, 1, 1)
    Citizen.Wait(1500)
    isCameraTransitioning = false
end

RegisterNUICallback("buycamerapreset", function(data, cb)
    cb("ok")
    buyTourActive = false
    ApplyBuyCameraPreset(data.index)
end)

-- Automatic tour: flies the preview camera through every preset.
RegisterNUICallback("buytour", function(data, cb)
    cb("ok")
    if buyTourActive then buyTourActive = false return end
    buyTourActive = true
    SendNUIMessage({message = "buytourstate", active = true})
    Citizen.CreateThread(function()
        local i = 0
        while buyTourActive and isYachtBuyMenuOpen do
            i = i % #Config.BuyCameraPresets + 1
            while isCameraTransitioning do Citizen.Wait(100) end
            ApplyBuyCameraPreset(i)
            local waited = 0
            while buyTourActive and isYachtBuyMenuOpen and waited < (Config.BuyTourSeconds or 4) * 1000 do
                Citizen.Wait(100) waited = waited + 100
            end
        end
        buyTourActive = false
        SendNUIMessage({message = "buytourstate", active = false})
    end)
end)

-- Shows the boats / jet skis / helicopters picked in the buy menu next to the preview yacht.
RegisterNUICallback("buypreviewtenders", function(data, cb)
    cb("ok")
    ClearPreviewTenders()
    local token = previewTenderToken
    local cfg = Config.Comfort and Config.Comfort.tender
    local yacht = yachtBuyState.yachtbuyobject
    if not isYachtBuyMenuOpen or not cfg or not cfg.enabled or not yacht or not DoesEntityExist(yacht) then return end
    local ids = type(data.ids) == "table" and data.ids or {}

    Citizen.CreateThread(function()
        local used = {}
        for _, id in ipairs(ids) do
            local opt
            for _, o in ipairs(cfg.options) do if o.id == tonumber(id) then opt = o end end
            local cat = opt and (opt.category or "Vehicles")
            local slots = cat and cfg.slots and cfg.slots[cat]
            used[cat or ""] = (used[cat or ""] or 0) + 1
            local off = slots and slots[used[cat]]
            if opt and off then
                local hash = GetHashKey(opt.model)
                if IsModelInCdimage(hash) then
                    RequestModel(hash)
                    local t = 0
                    while not HasModelLoaded(hash) and t < 5000 do Citizen.Wait(50) t = t + 50 end
                    if token ~= previewTenderToken or not isYachtBuyMenuOpen or not DoesEntityExist(yacht) then return end
                    if HasModelLoaded(hash) then
                        local p, heading = TenderSpawnCoords(yacht, off, hash, opt.air, cfg)
                        local veh = CreateVehicle(hash, p.x, p.y, p.z, heading, false, false)
                        SetModelAsNoLongerNeeded(hash)
                        if DoesEntityExist(veh) then
                            SetEntityCollision(veh, false, false)
                            FreezeEntityPosition(veh, true)
                            SetVehicleDoorsLocked(veh, 2)
                            previewTenders[#previewTenders + 1] = veh
                        end
                    end
                end
            end
        end
    end)
end)

RegisterNUICallback("buypreviewenv", function(data, cb)
    cb("ok")
    if not isYachtBuyMenuOpen then return end
    local hourIdx = tonumber(data.time)
    local weatherIdx = tonumber(data.weather)
    local t = hourIdx and Config.BuyPreview.times[hourIdx]
    local w = weatherIdx and Config.BuyPreview.weathers[weatherIdx]
    if hourIdx == 0 then -- "Auto" for time
        if previewEnv.hour then NetworkClearClockTimeOverride() end
        previewEnv.hour = nil
    elseif t then
        previewEnv.hour = t.hour
        previewEnvTouched = true
    end
    if weatherIdx == 0 then
        if previewEnv.weather then ClearOverrideWeather() end
        previewEnv.weather = nil
    elseif w then
        previewEnv.weather = w.type
        previewEnvTouched = true
    end
end)

RegisterNUICallback("buyyachtchangecolor", function(data, cb)
    if not isYachtBuyMenuOpen then cb("ok") return end
    local colorId = tonumber(data.yachtcolorddata)
    if not colorId or not Config.YachColors[colorId] then cb("ok") return end
    yachtBuyState.yachtcolor = colorId

    local colCfg = Config.YachColors[colorId]
    
    SetVehicleModColor_1(yachtBuyState.yachtbuyobject, 1, colCfg.primary, 0)
    SetVehicleModColor_2(yachtBuyState.yachtbuyobject, 1, colCfg.secondary)
    SetVehicleColours(yachtBuyState.yachtbuyobject, colCfg.primary, colCfg.secondary)
    SetVehicleDashboardColor(yachtBuyState.yachtbuyobject, colCfg.interior)
    SetObjectTextureVariant(yachtBuyState.yachtbuyobject, colCfg.overlay)
    SetVehicleInteriorColor(yachtBuyState.yachtbuyobject, colCfg.secondary)

    for _, objData in ipairs(yachtBuyState.mainobjects) do
        if DoesEntityExist(objData.handler) then
            SetObjectTextureVariant(objData.handler, colCfg.overlay)
            if objData.objectname == "as_apa_mp_apa_yacht_option3" then
                SetVehicleModColor_1(objData.handler, 1, colCfg.primary, 0)
                SetVehicleModColor_2(objData.handler, 1, colCfg.secondary)
                SetVehicleColours(objData.handler, colCfg.primary, colCfg.secondary)
                SetVehicleDashboardColor(objData.handler, colCfg.primary)
                if yachtBuyState.railing.railingid == 1 then
                    SetVehicleInteriorColor(objData.handler, 5)
                else
                    SetVehicleInteriorColor(objData.handler, 37)
                end
            end
        end
    end

    for _, door in ipairs(yachtBuyState.doors) do
        if DoesEntityExist(door.handler) then
            SetObjectTextureVariant(door.handler, colCfg.overlay)
        end
    end

    cb("ok")
end)

RegisterNUICallback("buyyachtchangeflag", function(data, cb)
    if not isYachtBuyMenuOpen then cb("ok") return end
    local flagId = tonumber(data.flagdata)
    if not flagId or not flagObjectsList[flagId] then cb("ok") return end
    yachtBuyState.flagdata.flagid = flagId
    SpawnFlagBuy(flagId)
    cb("ok")
end)

RegisterNUICallback("buyyachtchangelight", function(data, cb)
    if not isYachtBuyMenuOpen then cb("ok") return end
    local category = tonumber(data.ligthtcolorcategorydata) or 1
    local colorId  = tonumber(data.ligthtcolordata) or 1
    yachtBuyState.lighting.lightingcategory = category
    yachtBuyState.lighting.lightingid       = colorId
    SpawnLightBuy(category, colorId)
    cb("ok")
end)

RegisterNUICallback("buyyachtchangerailing", function(data, cb)
    if not isYachtBuyMenuOpen then cb("ok") return end
    local railingId   = math.floor(tonumber(data.railingdata) or 1)
    if not Config.RailingTypes[railingId] then railingId = 1 end
    yachtBuyState.railing.railingid = railingId

    SetVehicleInteriorColor(yachtBuyState.yachtbuyobject, GetRailingColour(railingId))

    for _, objData in ipairs(yachtBuyState.mainobjects) do
        if DoesEntityExist(objData.handler) and objData.objectname == "as_apa_mp_apa_yacht_option3" then
            SetVehicleInteriorColor(objData.handler, GetRailingColour(railingId))
        end
    end

    SpawnRailingBuy(railingId)
    cb("ok")
end)

RegisterNUICallback("buyyachtchangename", function(data, cb)
    if not isYachtBuyMenuOpen then cb("ok") return end
    yachtBuyState.textdata.uppertext  = tostring(data.uppertextdata  or "")
    yachtBuyState.textdata.bottomtext = tostring(data.bottomtextdata or "")
    cb("ok")
end)

RegisterNUICallback("buyyacht", function(data, cb)
    if not isYachtBuyMenuOpen or buyPending then cb("ok") return end
    buyPending = true

    local railingId = math.floor(tonumber(data.railingdata) or 1)
    if not Config.RailingTypes[railingId] then railingId = 1 end
    local colorId = tonumber(data.yachtcolorddata) or yachtBuyState.yachtcolor or 1
    local lightCat = tonumber(data.ligthtcolorcategorydata) or yachtBuyState.lighting.lightingcategory or 1
    local lightId = tonumber(data.ligthtcolordata) or yachtBuyState.lighting.lightingid or 1
    local upperText = tostring(data.uppertextdata or yachtBuyState.textdata.uppertext or "")
    local bottomText = tostring(data.bottomtextdata or yachtBuyState.textdata.bottomtext or "")
    local flagId = tonumber(data.flagdata) or yachtBuyState.flagdata.flagid or 1
    local equipmentId = tonumber(data.equipmentdata) or 1

    TriggerServerEvent(
        "asyacht:Global:BuyYacht",
        colorId,
        { category = lightCat, id = lightId },
        { uppertext = upperText, bottomtext = bottomText },
        railingId,
        flagId,
        equipmentId,
        tostring(data.paymentdata or Config.Payment.default),
        { engine = tonumber(data.engine) or 1, storage = tonumber(data.storage) or 1, tenders = type(data.tenders) == "table" and data.tenders or {} }
    )
    cb("ok")
end)

RegisterNUICallback("closebuymenu", function(data, cb)
    if not isYachtBuyMenuOpen then cb("ok") return end
    TriggerServerEvent("asyacht:Global:CloseYachtBuy")
    cb("ok")
end)

RegisterNUICallback("chooseownfurniture", function(data, cb)
    if not isManagementMenuOpen then cb("ok") return end
    if managementMenuYachtId ~= nil then
        SetNuiFocus(false, false)
        SendNUIMessage({message = "yachtmanagmenthide"})
        TriggerServerEvent("asyacht:Global:OpenFurnitureEdit", managementMenuYachtId)
        isManagementMenuOpen  = false
        managementMenuYachtId = nil
    end
    cb("ok")
end)

RegisterNUICallback("choosebuyfurniture", function(data, cb)
    if not isManagementMenuOpen then cb("ok") return end
    if managementMenuYachtId ~= nil then
        SetNuiFocus(false, false)
        SendNUIMessage({message = "yachtmanagmenthide"})
        TriggerServerEvent("asyacht:Global:OpenFurnitureShop", managementMenuYachtId)
        isManagementMenuOpen  = false
        managementMenuYachtId = nil
    end
    cb("ok")
end)

RegisterNUICallback("chooseaddpermissions", function(data, cb)
    if not isManagementMenuOpen then cb("ok") return end
    if managementMenuYachtId ~= nil then
        SendNUIMessage({
            message = "yachtmanagmentaddpermissionsshow"
        })
        local playerCoords = GetEntityCoords(PlayerPedId())
        local players = GetPlayersInArea(playerCoords, 10.0)
        TriggerServerEvent("asyacht:Global:OpenAddPermissionPlayer", managementMenuYachtId, players)
    end
    cb("ok")
end)

RegisterNUICallback("addplayerpermission", function(data, cb)
    if not isManagementMenuOpen then cb("ok") return end
    if managementMenuYachtId ~= nil then
        SendNUIMessage({
            message = "yachtmanagmentaddpermissionschangeshow"
        })
        TriggerServerEvent("asyacht:Global:AddPermissionPlayer",
            managementMenuYachtId,
            tonumber(data.playeriddata)  
        )
    end
    cb("ok")
end)

RegisterNUICallback("choosepermissions", function(data, cb)
    if not isManagementMenuOpen then cb("ok") return end
    if managementMenuYachtId ~= nil then
        SendNUIMessage({
            message = "yachtmanagmentaddpermissionschangeshow"
        })
        TriggerServerEvent("asyacht:Global:OpenPermissions", managementMenuYachtId)
    end
    cb("ok")
end)

RegisterNUICallback("choosetransferyacht", function(data, cb)
    if not isManagementMenuOpen then cb("ok") return end
    if managementMenuYachtId ~= nil then
        SendNUIMessage({
            message = "yachtmanagmenttransfershow"
        })
        local playerCoords = GetEntityCoords(PlayerPedId())
        local players = GetPlayersInArea(playerCoords, 10.0)
        TriggerServerEvent("asyacht:Global:OpenTransferYachtPlayer", managementMenuYachtId, players)
    end
    cb("ok")
end)

RegisterNUICallback("sellyacht", function(data, cb)
    if not isManagementMenuOpen then cb("ok") return end
    if managementMenuYachtId ~= nil then
        SetNuiFocus(false, false)
        SendNUIMessage({message = "yachtmanagmenthide"})
        TriggerServerEvent("asyacht:Global:SellPlayerYacht", managementMenuYachtId)
        isManagementMenuOpen  = false
        managementMenuYachtId = nil
    end
    cb("ok")
end)

RegisterNUICallback("transferplayeryacht", function(data, cb)
    if not isManagementMenuOpen then cb("ok") return end
    if managementMenuYachtId ~= nil then
        SetNuiFocus(false, false)
        SendNUIMessage({message = "yachtmanagmenthide"})
        TriggerServerEvent("asyacht:Global:TransferPlayerYacht",
            managementMenuYachtId,
            tonumber(data.playeriddata)
        )
        isManagementMenuOpen  = false
        managementMenuYachtId = nil
    end
    cb("ok")
end)

RegisterNUICallback("changepermissions", function(data, cb)
    if not isManagementMenuOpen then cb("ok") return end
    if managementMenuYachtId ~= nil then
        TriggerServerEvent("asyacht:Global:ChangePermissions",
            managementMenuYachtId,
            tostring(data.playeriddata),
            data.yachtcontroldata,
            data.dooraccessdata,
            data.furnituremanagmentdata,
            data.storageaccessdata,
            data.wardrobeaccessdata
        )
    end
    cb("ok")
end)

RegisterNUICallback("removepermission", function(data, cb)
    if not isManagementMenuOpen then cb("ok") return end
    if managementMenuYachtId ~= nil then
        TriggerServerEvent("asyacht:Global:DeletePermissions",
            managementMenuYachtId,
            tostring(data.playeriddata)
        )
    end
    cb("ok")
end)

RegisterNetEvent("asyacht:Global:UpgradesData")
AddEventHandler("asyacht:Global:UpgradesData", function(data)
    if not isManagementMenuOpen then return end
    data.message = "upgradesshow"
    SendNUIMessage(data)
end)

RegisterNUICallback("chooseupgrades", function(data, cb)
    cb("ok")
    if isManagementMenuOpen and managementMenuYachtId ~= nil then
        TriggerServerEvent("asyacht:Global:RequestUpgrades", managementMenuYachtId)
    end
end)

RegisterNUICallback("upgraderename", function(data, cb)
    cb("ok")
    if isManagementMenuOpen and managementMenuYachtId ~= nil then
        TriggerServerEvent("asyacht:Global:UpgradeRename", managementMenuYachtId, tostring(data.upper or ""), tostring(data.bottom or ""))
    end
end)

RegisterNUICallback("upgradeappearance", function(data, cb)
    cb("ok")
    if isManagementMenuOpen and managementMenuYachtId ~= nil then
        TriggerServerEvent("asyacht:Global:UpgradeAppearance", managementMenuYachtId,
            tonumber(data.color), tonumber(data.railing), tonumber(data.flag), tonumber(data.lightcat), tonumber(data.lightid))
    end
end)

RegisterNUICallback("upgraderefuel", function(data, cb)
    cb("ok")
    if isManagementMenuOpen and managementMenuYachtId ~= nil then
        TriggerServerEvent("asyacht:Global:RefuelYacht", managementMenuYachtId)
    end
end)

RegisterNUICallback("upgradeinsure", function(data, cb)
    cb("ok")
    if isManagementMenuOpen and managementMenuYachtId ~= nil then
        TriggerServerEvent("asyacht:Global:BuyInsurance", managementMenuYachtId)
    end
end)

RegisterNUICallback("upgraderental", function(data, cb)
    cb("ok")
    if isManagementMenuOpen and managementMenuYachtId ~= nil then
        TriggerServerEvent("asyacht:Global:OfferRental", managementMenuYachtId, tonumber(data.target), tonumber(data.minutes), tonumber(data.price))
    end
end)

RegisterNUICallback("upgradeengine", function(data, cb)
    cb("ok")
    if isManagementMenuOpen and managementMenuYachtId ~= nil then
        TriggerServerEvent("asyacht:Global:UpgradeEngine", managementMenuYachtId, tonumber(data.tier))
    end
end)

RegisterNUICallback("upgradestorage", function(data, cb)
    cb("ok")
    if isManagementMenuOpen and managementMenuYachtId ~= nil then
        TriggerServerEvent("asyacht:Global:UpgradeStorage", managementMenuYachtId, tonumber(data.tier))
    end
end)

RegisterNUICallback("closemanagment", function(data, cb)
    if not isManagementMenuOpen then cb("ok") return end
    if managementMenuYachtId == nil then cb("ok") return end
    SetNuiFocus(false, false)
    SendNUIMessage({message = "yachtmanagmenthide"})
    isManagementMenuOpen  = false
    managementMenuYachtId = nil
    cb("ok")
end)
