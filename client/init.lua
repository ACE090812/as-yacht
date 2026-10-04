-- as-yacht client/init.lua: Framework hooks, yacht spawning, doors and target setup.
-- (Split from the former client/main.lua. File-level state is global so every client module shares it.)

function InitializeYacht()
    if hasInitialized then return end
    hasInitialized = true

    if Config.Framework == "esx" then
        if Config.ESXFramework.newversion then
            ESX = exports[Config.ESXFramework.resourcename]:getSharedObject()
        else
            TriggerEvent(Config.ESXFramework.getsharedobject, function(sharedObj)
                ESX = sharedObj
            end)
        end
    elseif Config.Framework == "qbcore" then
        if not QBCore then
            pcall(function()
                QBCore = exports[Config.QBCoreFrameworkResourceName]:GetCoreObject()
            end)
        end
    end

    if not Config.DisableYachtBuy then
        if Config.YachtBuyLocation.blip.enabled then
            CreateYachtBuyBlip()
        end
        if not isTargetSystemReady and Config.Target then
            CreateTargets()
        end
    end

    SendNUIMessage({
        message               = "updateinterfacedata",
        interfacecolordata    = Config.InterfaceColor,
        yachtresourcenamedata = tostring(GetCurrentResourceName()),
    })

    TriggerServerEvent("asyacht:Global:SynchronizeYacht")
end

if Config.Framework == "esx" then
    RegisterNetEvent(Config.PlayerLoadedEvent.esx)
    AddEventHandler(Config.PlayerLoadedEvent.esx, function()
        Citizen.CreateThread(function()
            Citizen.Wait(2000)
            InitializeYacht()
            TriggerServerEvent("asyacht:Global:SynchronizeYacht")
            
        end)
    end)

elseif Config.Framework == "qbcore" then
    RegisterNetEvent(Config.PlayerLoadedEvent.qbcore)
    AddEventHandler(Config.PlayerLoadedEvent.qbcore, function()
        Citizen.CreateThread(function()
            Citizen.Wait(2000)
            InitializeYacht()
            TriggerServerEvent("asyacht:Global:SynchronizeYacht")
            
        end)
    end)

elseif Config.Framework == "standalone" then
    RegisterNetEvent(Config.PlayerLoadedEvent.standalone)
    AddEventHandler(Config.PlayerLoadedEvent.standalone, function()
        Citizen.CreateThread(function()
            Citizen.Wait(2000)
            InitializeYacht()
            TriggerServerEvent("asyacht:Global:SynchronizeYacht")
            
        end)
    end)
end

AddEventHandler("onClientResourceStart", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    Citizen.CreateThread(function()
        while true do
            if NetworkIsPlayerActive(PlayerId()) and DoesEntityExist(PlayerPedId()) then
                break
            end
            Citizen.Wait(500)
        end
        Citizen.Wait(1000)
        InitializeYacht()
    end)
end)

function SpawnFlagBuy(flagId, sessionId)
    sessionId = sessionId or previewSessionId
    if not IsPreviewSessionActive(sessionId) then return end

    if DoesEntityExist(yachtBuyState.flagdata.handler) then
        DeleteEntity(yachtBuyState.flagdata.handler)
        yachtBuyState.flagdata.handler = nil
    end

    local flagEntry = flagObjectsList[flagId]
    if not flagEntry then return end
    local modelHash = GetHashKey(flagEntry.flagobject)
    if not WaitForPreviewModel(modelHash, flagEntry.flagobject, sessionId) then return end
    if not IsPreviewSessionActive(sessionId) then return end

    local previewCoords = Config.YachtBuyLocation.yachtpreviewlocation
    local entity = CreateObjectNoOffset(modelHash,
        previewCoords.x, previewCoords.y, previewCoords.z,
        false, true, true)
    if not DoesEntityExist(entity) then
        print(("^1AS Yacht^7: failed to create preview flag: %s"):format(flagEntry.flagobject))
        return
    end
    if not IsPreviewSessionActive(sessionId) then
        DeleteEntity(entity)
        return
    end
    yachtBuyState.flagdata.handler = entity

    FreezeEntityPosition(entity, true)
    SetEntityRotation(entity, 0.0, 0.0, 0.0)
    SetCanAutoVaultOnEntity(entity, true)
    SetCanClimbOnEntity(entity, true)
    SetEntityHasGravity(entity, true)
    SetEntityAlwaysPrerender(entity, true)
    SetEntityMotionBlur(entity, false)
    SetEntityRenderScorched(entity, true)
    SetEntityLoadCollisionFlag(entity, true)
    SetEntityLodDist(entity, 1000)

    if DoesEntityExist(yachtBuyState.yachtbuyobject) then
        AttachEntityToEntity(
            entity, yachtBuyState.yachtbuyobject,
            0, -0.05, -56.55, 7.4, 230.0, -180.0, 0.0,
            false, false, true, false, 5, true
        )
        
        DetachEntity(entity)
    end
    FreezeEntityPosition(entity, true)
    SetModelAsNoLongerNeeded(modelHash)
end

function SpawnLightBuy(lightCategory, lightColorId, sessionId)
    sessionId = sessionId or previewSessionId
    previewLightRequestId = previewLightRequestId + 1
    local requestId = previewLightRequestId
    local objectName = GetLightColorObject(lightCategory, lightColorId)
    local modelHash  = GetHashKey(objectName)
    if not WaitForPreviewModel(modelHash, objectName, sessionId) then return end
    if not IsPreviewSessionActive(sessionId) or requestId ~= previewLightRequestId then return end

    if DoesEntityExist(yachtBuyState.lighting.handler) then
        DeleteEntity(yachtBuyState.lighting.handler)
        yachtBuyState.lighting.handler = nil
    end

    local previewCoords = Config.YachtBuyLocation.yachtpreviewlocation
    local entity = CreateObjectNoOffset(modelHash,
        previewCoords.x, previewCoords.y, previewCoords.z,
        false, true, true)
    if not DoesEntityExist(entity) then
        print(("^1AS Yacht^7: failed to create preview neon: %s"):format(objectName))
        return
    end
    if not IsPreviewSessionActive(sessionId) or requestId ~= previewLightRequestId then
        DeleteEntity(entity)
        return
    end
    yachtBuyState.lighting.handler = entity

    FreezeEntityPosition(entity, true)
    SetEntityRotation(entity, 0.0, 0.0, 0.0)
    SetCanAutoVaultOnEntity(entity, true)
    SetCanClimbOnEntity(entity, true)
    SetEntityHasGravity(entity, true)
    SetEntityAlwaysPrerender(entity, true)
    SetEntityMotionBlur(entity, false)
    SetEntityRenderScorched(entity, true)
    SetEntityLoadCollisionFlag(entity, true)
    SetEntityLodDist(entity, 1000)

    if DoesEntityExist(yachtBuyState.yachtbuyobject) then
        AttachEntityToEntity(
            entity, yachtBuyState.yachtbuyobject,
            0,
            yachtBuyState.lighting.coords.x - 2.05,
            yachtBuyState.lighting.coords.y,
            yachtBuyState.lighting.coords.z + 5.8,
            yachtBuyState.lighting.rotation.x,
            yachtBuyState.lighting.rotation.y,
            yachtBuyState.lighting.rotation.z + 90.0,
            false, false, true, false, 5, true
        )
        
        DetachEntity(entity)
    end
    FreezeEntityPosition(entity, true)
    SetModelAsNoLongerNeeded(modelHash)
end

function SpawnRailingBuy(railingId, sessionId)
    sessionId = sessionId or previewSessionId
    if not IsPreviewSessionActive(sessionId) then return end

    if DoesEntityExist(yachtBuyState.railing.handler2) then
        DeleteEntity(yachtBuyState.railing.handler2)
        yachtBuyState.railing.handler2 = nil
    end

    local railingEntry = anchorRailingTypesList[railingId] or anchorRailingTypesList[1]
    local modelHash = GetHashKey(railingEntry.railingobject)
    if not WaitForPreviewModel(modelHash, railingEntry.railingobject, sessionId) then return end
    if not IsPreviewSessionActive(sessionId) then return end

    local previewCoords = Config.YachtBuyLocation.yachtpreviewlocation
    local entity = CreateObjectNoOffset(modelHash,
        previewCoords.x, previewCoords.y, previewCoords.z,
        false, true, true)
    if not DoesEntityExist(entity) then
        print(("^1AS Yacht^7: failed to create preview railing: %s"):format(railingEntry.railingobject))
        return
    end
    if not IsPreviewSessionActive(sessionId) then
        DeleteEntity(entity)
        return
    end
    yachtBuyState.railing.handler2 = entity

    FreezeEntityPosition(entity, true)
    SetEntityRotation(entity, 0.0, 0.0, 0.0)
    SetCanAutoVaultOnEntity(entity, true)
    SetCanClimbOnEntity(entity, true)
    SetEntityHasGravity(entity, true)
    SetEntityAlwaysPrerender(entity, true)
    SetEntityMotionBlur(entity, false)
    SetEntityRenderScorched(entity, true)
    SetEntityLoadCollisionFlag(entity, true)
    SetEntityLodDist(entity, 1000)
    SetObjectTextureVariant(entity, Config.YachColors[yachtBuyState.yachtcolor].overlay)

    if DoesEntityExist(yachtBuyState.yachtbuyobject) then
        AttachEntityToEntity(
            entity, yachtBuyState.yachtbuyobject,
            0,
            yachtBuyState.railing.coords.x - 2.0,
            yachtBuyState.railing.coords.y,
            yachtBuyState.railing.coords.z + 5.8,
            yachtBuyState.railing.rotation.x,
            yachtBuyState.railing.rotation.y,
            yachtBuyState.railing.rotation.z + 90.0,
            false, false, true, false, 5, true
        )
        
        DetachEntity(entity)
    end
    FreezeEntityPosition(entity, true)
    SetModelAsNoLongerNeeded(modelHash)
end

function YachtSpawnBuy(sessionId)
    sessionId = sessionId or previewSessionId
    if not WaitForPreviewModel(yachtModelHash, "as_yacht_veh", sessionId) then
        ClearYachtBuyPreview(sessionId)
        return
    end

    local previewCoords = Config.YachtBuyLocation.yachtpreviewlocation
    
    local vehicle = CreateVehicle(yachtModelHash,
        previewCoords.x, previewCoords.y, previewCoords.z,
        0.0, false, true)

    if not DoesEntityExist(vehicle) then
        print("^1AS Yacht^7: failed to create the preview yacht vehicle")
        ClearYachtBuyPreview(sessionId)
        return
    end
    if not IsPreviewSessionActive(sessionId) then
        DeleteEntity(vehicle)
        ClearYachtBuyPreview(sessionId)
        return
    end

    yachtBuyState.yachtbuyobject = vehicle

    local colCfg = Config.YachColors[yachtBuyState.yachtcolor]
    SetVehicleModColor_1(vehicle, 1, colCfg.primary, 0)
    SetVehicleModColor_2(vehicle, 1, colCfg.secondary)
    SetVehicleColours(vehicle, colCfg.primary, colCfg.secondary)
    SetVehicleDashboardColor(vehicle, colCfg.interior)
    SetVehicleInteriorColor(vehicle, GetRailingColour(yachtBuyState.railing.railingid))
    SetObjectTextureVariant(vehicle, colCfg.overlay)  

    SetVehicleDoorsLocked(vehicle, 9)
    
    SetEntityRotation(vehicle, 0.0, -0.0, 80.282)
    NetworkAllowLocalEntityAttachment(vehicle, true)
    FreezeEntityPosition(vehicle, true)
    SetEntityAlwaysPrerender(vehicle, true)
    SetEntityMotionBlur(vehicle, false)
    SetEntityLodDist(vehicle, 1000)
    SetVehRadioStation(vehicle, "OFF")
    SetVehicleRadioEnabled(vehicle, false)
    SetModelAsNoLongerNeeded(yachtModelHash)

    for _, objData in ipairs(yachtBuyState.mainobjects) do
        local objHash = GetHashKey(objData.objectname)
        local objLoaded = WaitForPreviewModel(objHash, objData.objectname, sessionId)
        if not objLoaded and not IsPreviewSessionActive(sessionId) then
            ClearYachtBuyPreview(sessionId)
            return
        end
        -- a part that fails to load is skipped (already logged) instead of wiping the whole preview
        if objLoaded then
        local obj
        if objData.objectname == "as_apa_mp_apa_yacht_option3" then
            
            obj = CreateVehicle(objHash,
                previewCoords.x, previewCoords.y, previewCoords.z,
                0.0, false, true)
            SetVehicleDoorsLocked(obj, 9)
            FreezeEntityPosition(obj, true)
            SetEntityRotation(obj, 0.0, 0.0, 0.0)
            local c2 = Config.YachColors[yachtBuyState.yachtcolor]
            SetVehicleModColor_1(obj, 1, c2.primary, 0)
            SetVehicleModColor_2(obj, 1, c2.secondary)
            SetVehicleColours(obj, c2.primary, c2.secondary)
            SetVehicleDashboardColor(obj, c2.primary)
            SetVehicleInteriorColor(obj, GetRailingColour(yachtBuyState.railing.railingid))
        else
            obj = CreateObjectNoOffset(objHash,
                previewCoords.x, previewCoords.y, previewCoords.z,
                false, true, true)
            FreezeEntityPosition(obj, true)
            SetEntityRotation(obj, 0.0, 0.0, 0.0)
        end
        if not DoesEntityExist(obj) then
            print(("^1AS Yacht^7: failed to create preview object: %s"):format(objData.objectname))
            ClearYachtBuyPreview(sessionId)
            return
        end
        objData.handler = obj

        SetObjectTextureVariant(obj, Config.YachColors[yachtBuyState.yachtcolor].overlay)
        SetCanClimbOnEntity(obj, true)
        SetEntityLoadCollisionFlag(obj, true)
        SetEntityLodDist(obj, 1000)

        AttachEntityToEntity(
            obj, vehicle, 0,
            objData.offsetcoords.x, objData.offsetcoords.y, objData.offsetcoords.z,
            objData.offsetrotation.x, objData.offsetrotation.y, objData.offsetrotation.z,
            false, false, true, false, 5, true
        )
        DetachEntity(obj)
        FreezeEntityPosition(obj, true)
        SetModelAsNoLongerNeeded(objHash)
        end
    end

    for _, door in ipairs(yachtBuyState.doors) do
        local dHash = GetHashKey(door.objectname)
        if not WaitForPreviewModel(dHash, door.objectname, sessionId) then
            ClearYachtBuyPreview(sessionId)
            return
        end
        local dObj = CreateObjectNoOffset(dHash,
            previewCoords.x, previewCoords.y, previewCoords.z,
            false, true, true)
        if not DoesEntityExist(dObj) then
            print(("^1AS Yacht^7: failed to create preview door: %s"):format(door.objectname))
            ClearYachtBuyPreview(sessionId)
            return
        end
        door.handler = dObj
        FreezeEntityPosition(dObj, true)
        SetEntityRotation(dObj, 0.0, 0.0, 0.0)
        SetCanAutoVaultOnEntity(dObj, true)
        SetCanClimbOnEntity(dObj, true)
        SetEntityHasGravity(dObj, true)
        SetEntityAlwaysPrerender(dObj, true)
        SetEntityMotionBlur(dObj, false)
        SetEntityRenderScorched(dObj, true)
        SetEntityLoadCollisionFlag(dObj, true)
        SetEntityLodDist(dObj, 1000)
        AttachEntityToEntity(dObj, vehicle, 0,
            door.coords.x, door.coords.y, door.coords.z,
            door.rotation.x, door.rotation.y, door.rotation.z,
            false, false, true, false, 5, true)
        DetachEntity(dObj)
        FreezeEntityPosition(dObj, true)
        SetModelAsNoLongerNeeded(dHash)
    end

    SpawnFlagBuy(yachtBuyState.flagdata.flagid, sessionId)
    SpawnLightBuy(yachtBuyState.lighting.lightingcategory, yachtBuyState.lighting.lightingid, sessionId)
    SpawnRailingBuy(yachtBuyState.railing.railingid, sessionId)

    ResetYachtName()
    while IsPreviewSessionActive(sessionId) do
        Wait(0)
        HideHudAndRadarThisFrame()
        DisableRadarThisFrame()
        for _, comp in ipairs({1,2,3,4,6,7,8,9,13,17,20}) do
            HideHudComponentThisFrame(comp)
        end
        WaterOverrideSetStrength(0.6)
        if previewEnv.hour then NetworkOverrideClockTime(previewEnv.hour, 0, 0) end
        if previewEnv.weather then SetOverrideWeather(previewEnv.weather) end
        DrawYachtName(yachtBuyState.textdata.uppertext, yachtBuyState.textdata.bottomtext, 1)
    end

    ResetYachtName()
    ClearYachtBuyPreview(sessionId)
end

function GetWorldRotationFromEntityAndOffset(entity, offsetX, offsetY, offsetZ)
    local rot = GetEntityRotation(entity, 2)
    return vector3(
        rot.x + offsetX,
        rot.y + offsetY,
        rot.z + offsetZ
    )
end

function ToggleDoor(yachtId, doorIndex, forceOpen)
    local yachtData = yachts["yacht-" .. yachtId]
    if not yachtData then return end
    local door = yachtData.doors[doorIndex]
    if not door then return end

    if forceOpen and door.opened then return end
    if forceOpen == false and not door.opened then return end

    local targetOpen = not door.opened

    door.animGen = (door.animGen or 0) + 1
    local myGen = door.animGen

    local destRot    = door.opened and door.rotation or door.rotationopened
    local currentRot = door.opened and (door.rotationopened or door.rotation) or door.rotation

    local step      = 0.5
    local direction = (destRot.z > currentRot.z) and "plus" or "minus"

    Citizen.CreateThread(function()
        while true do
            if door.animGen ~= myGen then return end  

            if direction == "plus"  and currentRot.z >= destRot.z then break end
            if direction == "minus" and currentRot.z <= destRot.z then break end

            Citizen.Wait(5)

            if door.animGen ~= myGen then return end  

            if direction == "plus" then
                currentRot = vector3(currentRot.x, currentRot.y, currentRot.z + step)
            else
                currentRot = vector3(currentRot.x, currentRot.y, currentRot.z - step)
            end

            local liveData = yachts["yacht-" .. yachtId]
            if not liveData or liveData.removeinprogress then return end

            if DoesEntityExist(door.handler) and DoesEntityExist(liveData.yachtmainobject) then
                SetEntityRotation(door.handler, currentRot.x, currentRot.y, currentRot.z, 2, true)
                
                AttachEntityToEntity(
                    door.handler,
                    liveData.yachtmainobject,
                    0,
                    door.coords.x, door.coords.y, door.coords.z,
                    currentRot.x, currentRot.y, currentRot.z,
                    false, false, true, false, 5, true
                )
                DetachEntity(door.handler)
                FreezeEntityPosition(door.handler, true)
            end
        end
        if door.animGen == myGen then
            door.opened = targetOpen
        end
    end)
end

function GetPlayers()
    local result = {}
    for _, playerId in ipairs(GetActivePlayers()) do
        if DoesEntityExist(GetPlayerPed(playerId)) then
            table.insert(result, playerId)
        end
    end
    return result
end

function GetPlayersInArea(center, radius)
    local result = {}
    for _, playerId in ipairs(GetPlayers()) do
        local ped = GetPlayerPed(playerId)
        local pedPos = GetEntityCoords(ped)
        if #(pedPos - center) <= radius then
            if playerId ~= PlayerId() and playerId ~= -1 then
                local playerServerId = tonumber(GetPlayerServerId(playerId))
                table.insert(result, {
                    playerid = playerServerId,
                    playername = ""
                })
            end
        end
        if #result >= 5 then
            break
        end
    end
    return result
end

function PlateReformat(plateText)
    if not plateText then return "" end
    return string.gsub(plateText, "^%s*(.-)%s*$", "%1")
end

function CreateTargets()
    isTargetSystemReady = true
    local targetResource = Config.TargetSystemsNames[Config.Targettype]
    
end
