-- as-yacht client/actions.lua: Furniture NUI entry points, keybinds and drive enter/exit.
-- (Split from the former client/main.lua. File-level state is global so every client module shares it.)

RegisterNUICallback("editfurniture", function(data, cb)
    if not isFurnitureMenuOpen then cb(1) return end
    if furnitureMenuYachtId == nil then cb(1) return end

    local yachtData = yachts["yacht-" .. furnitureMenuYachtId]
    if not yachtData then cb(1) return end
    local furnitureEntry = yachtData.furnitureobjects[tostring(data.furnitureid)]
    if not furnitureEntry then cb(1) return end

    if not isFurniturePlacing then
        
        isGizmoActive    = false
        isFurniturePlacing = true

        furniturePlacementKey = tostring(data.furnitureid)

        local worldPos = GetOffsetFromEntityInWorldCoords(
            yachtData.yachtmainobject,
            furnitureEntry.furniturecoords.x,
            furnitureEntry.furniturecoords.y,
            furnitureEntry.furniturecoords.z
        )
        local worldRot = GetWorldRotationFromEntityAndOffset(
            yachtData.yachtmainobject,
            furnitureEntry.furniturerotation.x,
            furnitureEntry.furniturerotation.y,
            furnitureEntry.furniturerotation.z
        )

        DetachEntity(furnitureEntry.handler, true, true)
        FreezeEntityPosition(furnitureEntry.handler, true)
        furnitureEntry.editing = true

        furniturePlacementEntity = furnitureEntry.handler
        furniturePlacementCoords = worldPos
        furniturePlacementRotation = worldRot

        SendNUIMessage({action="SetTranslateSnap",  data={translatesnapdata = furnitureTranslateSnaps[furnitureTranslateSnapIndex].snapdata}})
        SendNUIMessage({action="SetRotationSnap",   data={rotationsnapdata  = furnitureRotateSnaps[furnitureRotateSnapIndex].snapdata}})
        SendNUIMessage({action="SetGizmoTransformMode", data={transformhandler=false}})
        SendNUIMessage({action="SetSpaceMode",          data={spacehandler=false}})
        SendNUIMessage({message = "objecteditorownposshow"})

        if DoesEntityExist(furniturePlacementEntity) then
            GizmoStart(furniturePlacementEntity)
        end
    else
        
        local prevKey = furniturePlacementKey

        isGizmoActive    = false
        isFurniturePlacing = true

        local worldPos = GetOffsetFromEntityInWorldCoords(
            yachtData.yachtmainobject,
            furnitureEntry.furniturecoords.x,
            furnitureEntry.furniturecoords.y,
            furnitureEntry.furniturecoords.z
        )
        local worldRot = GetWorldRotationFromEntityAndOffset(
            yachtData.yachtmainobject,
            furnitureEntry.furniturerotation.x,
            furnitureEntry.furniturerotation.y,
            furnitureEntry.furniturerotation.z
        )

        DetachEntity(furnitureEntry.handler, true, true)
        FreezeEntityPosition(furnitureEntry.handler, true)
        furnitureEntry.editing = true

        furniturePlacementKey      = tostring(data.furnitureid)
        furniturePlacementEntity   = furnitureEntry.handler
        furniturePlacementCoords   = worldPos
        furniturePlacementRotation = worldRot

        if prevKey then
            local prevEntry = yachtData.furnitureobjects[prevKey]
            if prevEntry and DoesEntityExist(prevEntry.handler) then
                prevEntry.editing = false
                AttachEntityToEntity(prevEntry.handler, yachtData.yachtmainobject, 0,
                    prevEntry.furniturecoords.x, prevEntry.furniturecoords.y, prevEntry.furniturecoords.z,
                    prevEntry.furniturerotation.x, prevEntry.furniturerotation.y, prevEntry.furniturerotation.z,
                    false, false, true, false, 2, true)
            end
        end

        GizmoStart(furniturePlacementEntity)
    end

    cb(1)
end)

RegisterNUICallback("addnewfurnituretohouse", function(data, cb)
    if not isFurnitureMenuOpen then cb(1) return end
    if furnitureMenuYachtId == nil then cb(1) return end

    local keepPreviewTransform = isFurniturePlacing
        and not isFurniturePlacementActive
        and furniturePlacementKey == nil
        and furniturePlacementCoords ~= nil
    local previousPos = keepPreviewTransform and vector3(
        furniturePlacementCoords.x, furniturePlacementCoords.y, furniturePlacementCoords.z) or nil
    local previousRot = keepPreviewTransform and furniturePlacementRotation and vector3(
        furniturePlacementRotation.x, furniturePlacementRotation.y, furniturePlacementRotation.z) or nil

    isGizmoActive      = false
    isFurniturePlacing = true

    if DoesEntityExist(furniturePlacementEntity) then
        DeleteEntity(furniturePlacementEntity)
        furniturePlacementEntity = nil
    end

    local categoryId  = tonumber(data.furniturecategoryid)
    local furnitureId = tonumber(data.furnitureid)

    if not categoryId or not furnitureId then cb(1) return end
    local catCfg = Config.Furnitures[categoryId]
    if not catCfg then cb(1) return end
    local furnitureObj = catCfg.categoryobjects[furnitureId]
    if not furnitureObj then cb(1) return end

    furniturePlacementCategoryId = categoryId
    furniturePlacementItemId     = furnitureId
    furniturePlacementKey        = nil

    local modelHash = GetHashKey(furnitureObj.furnitureobject)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        RequestModel(modelHash)
        Citizen.Wait(5)
    end

    local spawnPos, spawnRot
    if previousPos then
        spawnPos = previousPos
        spawnRot = previousRot or vector3(0.0, 0.0, GetEntityHeading(PlayerPedId()))
    elseif furnitureCamera then
        local camCoords = GetCamCoord(furnitureCamera)
        local camRot    = GetCamRot(furnitureCamera, 2)
        local hitPos, hitEntity = GetInView(
            camCoords.x, camCoords.y, camCoords.z,
            camRot.x, camRot.y, camRot.z
        )
        local hitDistance = hitPos and #(hitPos - camCoords) or math.huge

        if hitEntity and hitDistance <= 20.0
            and CheckIfFurnitureIsInYachtNearby(furnitureMenuYachtId, hitPos) then
            spawnPos = hitPos
        else
            
            local placementPed = noClipPed or PlayerPedId()
            spawnPos = GetOffsetFromEntityInWorldCoords(placementPed, 0.0, 2.0, 0.0)
        end
        spawnRot = vector3(0.0, 0.0, camRot.z)
    else
        spawnPos = GetEntityCoords(PlayerPedId())
        spawnRot = vector3(0.0, 0.0, GetEntityHeading(PlayerPedId()))
    end

    local obj = CreateObjectNoOffset(modelHash, spawnPos.x, spawnPos.y, spawnPos.z, false, true, true)
    SetEntityRotation(obj, 0.0, 0.0, spawnRot.z)
    FreezeEntityPosition(obj, true)
    furniturePlacementEntity  = obj
    furniturePlacementCoords  = spawnPos
    furniturePlacementRotation = spawnRot

    SendNUIMessage({action="SetTranslateSnap",      data={translatesnapdata = furnitureTranslateSnaps[furnitureTranslateSnapIndex].snapdata}})
    SendNUIMessage({action="SetRotationSnap",        data={rotationsnapdata  = furnitureRotateSnaps[furnitureRotateSnapIndex].snapdata}})
    SendNUIMessage({action="SetGizmoTransformMode",  data={transformhandler=false}})
    SendNUIMessage({action="SetSpaceMode",           data={spacehandler=false}})
    SendNUIMessage({message = "objecteditorposshow"})

    GizmoStart(obj)
    SetModelAsNoLongerNeeded(modelHash)
    cb(1)
end)

if not Config.DisableYachtBuy and not Config.Target then
    RegisterCommand("openyachtbuymenu", function()
        if isPlayerNearBuyLocation and not isYachtBuyMenuOpen then
            TriggerServerEvent("asyacht:Global:OpenYachtBuy")
        end
    end, false)

    RegisterKeyMapping("openyachtbuymenu",
        Lang.yachtbuymenu,
        "keyboard",
        Config.YachtBuyLocation.openkey
    )
end

RegisterCommand("yachtopenclosedoor", function()
    if currentNearYachtId == nil then return end
    if currentNearDoorIndex == nil then return end
    TriggerServerEvent("asyacht:Global:OpenCloseDoor",
        currentNearYachtId, currentNearDoorIndex)
end, false)

RegisterKeyMapping("yachtopenclosedoor",
    Lang.yachtdoor,
    "keyboard",
    Config.YachtOpenCloseDoorKey
)

RegisterCommand("yachtopenstorage", function()
    if currentNearYachtId == nil then return end
    if currentNearStorageIndex == nil then return end
    TriggerServerEvent("asyacht:Global:OpenStorage",
        currentNearYachtId, currentNearStorageIndex)
end, false)

RegisterKeyMapping("yachtopenstorage",
    Lang.yachtstorage,
    "keyboard",
    Config.YachtStorageKey
)

RegisterCommand("yachtopenwardrobe", function()
    if currentNearYachtId == nil then return end
    if currentNearWardrobeIndex == nil then return end
    TriggerServerEvent("asyacht:Global:OpenWardrobe",
        currentNearYachtId, currentNearWardrobeIndex)
end, false)

RegisterKeyMapping("yachtopenwardrobe",
    Lang.yachtwardrobe,
    "keyboard",
    Config.YachtWardrobeKey
)

RegisterCommand("yachtopenmanagment", function()
    if currentNearYachtId == nil then return end
    if currentNearManageZoneId == nil then return end
    if isManagementMenuOpen then return end
    TriggerServerEvent("asyacht:Global:OpenManagment", currentNearYachtId)
end, false)

RegisterKeyMapping("yachtopenmanagment",
    Lang.yachtmanagment,
    "keyboard",
    Config.YachtManagmentKey
)

RegisterCommand("yachthottubuse", function()
    if isPlayerSeated then
        
        if hottubSeatInfo.yachtid ~= nil and hottubSeatInfo.seatid ~= nil then
            TriggerServerEvent("asyacht:Global:LeaveHottub",
                hottubSeatInfo.yachtid, hottubSeatInfo.seatid)
        end
    else
        if currentNearYachtId == nil then return end
        if currentNearHottubIndex == nil then return end
        TriggerServerEvent("asyacht:Global:UseHottub",
            currentNearYachtId, currentNearHottubIndex)
    end
end, false)

RegisterKeyMapping("yachthottubuse",
    Lang.hottubseat,
    "keyboard",
    Config.HotTubSitKey
)

function ToggleYachtDriveEnterExit()
    
    if currentNearYachtId ~= nil then
        if currentNearDriveZoneId ~= nil then
            if not drivingState.driving then
                TriggerServerEvent("asyacht:Global:EnterYacht", currentNearDriveZoneId)
            end
        end
    end

    if drivingState.drivingid ~= nil then
        if not Config.ServerNetworkYacht then
            local coords = GetEntityCoords(drivingState.yachthandler)
            local rot    = GetEntityRotation(drivingState.yachthandler)
            TriggerServerEvent("asyacht:Global:ExitYacht", drivingState.drivingid,
                {x=coords.x, y=coords.y, z=coords.z}, {x=rot.x, y=rot.y, z=rot.z})
            if DoesEntityExist(drivingState.yachthandler) then
                FreezeEntityPosition(drivingState.yachthandler, true)
            end
        else
            TriggerServerEvent("asyacht:Global:ExitYacht", drivingState.drivingid)
        end
    end
end

if not Config.DisableYachtDrive then
    RegisterCommand("yachtdrive", function()
        ToggleYachtDriveEnterExit()
    end, false)

    RegisterKeyMapping("yachtdrive",
        Lang.yachtdrive,
        "keyboard",
        Config.YachtDriveKey
    )

    RegisterCommand("yachtenterexit", function()
        ToggleYachtDriveEnterExit()
    end, false)

    RegisterKeyMapping("yachtenterexit",
        Lang.yachtdrive,
        "keyboard",
        Config.YachtEnterExitKey
    )
end

if Config.CalmWater then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(1000)
            WaterOverrideSetStrength(1.0)
            SetDeepOceanScaler(0.0)
        end
    end)
end
