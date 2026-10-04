-- as-yacht client/sailing.lua: Sync, driving, anchoring, furniture sync and hot tub events.
-- (Split from the former client/main.lua. File-level state is global so every client module shares it.)

function SyncYachtSubObjects(yachtData, noCollisionTarget)
    local vehicle = yachtData.yachtmainobject
    if not DoesEntityExist(vehicle) then return end

    for _, objData in ipairs(yachtData.mainobjects) do
        if DoesEntityExist(objData.handler) then
            AttachEntityToEntity(objData.handler, vehicle, 0,
                objData.offsetcoords.x, objData.offsetcoords.y, objData.offsetcoords.z,
                objData.offsetrotation.x, objData.offsetrotation.y, objData.offsetrotation.z,
                false, false, true, false, 5, true)
            if noCollisionTarget then
                SetEntityNoCollisionEntity(objData.handler, noCollisionTarget, true)
            end
        end
    end

    if DoesEntityExist(yachtData.flagdata.handler) then
        AttachEntityToEntity(yachtData.flagdata.handler, vehicle, 0,
            -0.05, -56.55, 7.4, 230.0, -180.0, 0.0, false, false, true, false, 5, true)
        if noCollisionTarget then
            SetEntityNoCollisionEntity(yachtData.flagdata.handler, noCollisionTarget, true)
        end
    end

    if DoesEntityExist(yachtData.lighting.handler) then
        AttachEntityToEntity(yachtData.lighting.handler, vehicle, 0,
            yachtData.lighting.coords.x - 2.05, yachtData.lighting.coords.y, yachtData.lighting.coords.z + 5.8,
            yachtData.lighting.rotation.x, yachtData.lighting.rotation.y, yachtData.lighting.rotation.z + 90.0,
            false, false, true, false, 5, true)
        if noCollisionTarget then
            SetEntityNoCollisionEntity(yachtData.lighting.handler, noCollisionTarget, true)
        end
    end

    local rOffX = yachtData.railing.coords.x - 2.0
    local rOffY = yachtData.railing.coords.y
    local rOffZ = yachtData.railing.coords.z + 5.8
    local rRotX = yachtData.railing.rotation.x
    local rRotY = yachtData.railing.rotation.y
    local rRotZ = yachtData.railing.rotation.z + 90.0

    if DoesEntityExist(yachtData.railing.handler2) then
        AttachEntityToEntity(yachtData.railing.handler2, vehicle, 0, rOffX, rOffY, rOffZ, rRotX, rRotY, rRotZ, false, false, true, false, 5, true)
        if noCollisionTarget then
            SetEntityNoCollisionEntity(yachtData.railing.handler2, noCollisionTarget, true)
        end
    end
    if DoesEntityExist(yachtData.railing.handler3) then
        AttachEntityToEntity(yachtData.railing.handler3, vehicle, 0, rOffX, rOffY, rOffZ, rRotX, rRotY, rRotZ, false, false, true, false, 5, true)
        if noCollisionTarget then
            SetEntityNoCollisionEntity(yachtData.railing.handler3, noCollisionTarget, true)
        end
    end

    for _, door in ipairs(yachtData.doors) do
        if DoesEntityExist(door.handler) then
            local rot = door.opened and door.rotationopened or door.rotation
            AttachEntityToEntity(door.handler, vehicle, 0,
                door.coords.x, door.coords.y, door.coords.z,
                rot.x, rot.y, rot.z,
                false, false, true, false, 5, true)
            if noCollisionTarget then
                SetEntityNoCollisionEntity(door.handler, noCollisionTarget, true)
            end
        end
    end

    for _, furnitureEntry in pairs(yachtData.furnitureobjects) do
        if not furnitureEntry.removeinprogress and not furnitureEntry.editing and DoesEntityExist(furnitureEntry.handler) then
            AttachEntityToEntity(furnitureEntry.handler, vehicle, 0,
                furnitureEntry.furniturecoords.x, furnitureEntry.furniturecoords.y, furnitureEntry.furniturecoords.z,
                furnitureEntry.furniturerotation.x, furnitureEntry.furniturerotation.y, furnitureEntry.furniturerotation.z,
                false, false, false, false, 2, true)
            if noCollisionTarget then
                SetEntityNoCollisionEntity(furnitureEntry.handler, noCollisionTarget, true)
            end
        end
    end
end

function GetYachtDriveVehicle(yachtId)
    local vehNetId = GlobalState["asyacht-" .. yachtId .. "-vehid"]
    if not vehNetId or not NetworkDoesNetworkIdExist(vehNetId) then return nil end
    local driveVeh = NetToVeh(vehNetId)
    if not DoesEntityExist(driveVeh) then return nil end
    if GetEntityModel(driveVeh) ~= yachtModelHash then return nil end
    return driveVeh
end

RegisterNetEvent("asyacht:Global:YachtMaximumSynchronize")
AddEventHandler("asyacht:Global:YachtMaximumSynchronize", function(yachtId)
    local yachtData = yachts["yacht-" .. yachtId]
    if not yachtData then return end
    if yachtData.removeinprogress then return end

    Citizen.CreateThread(function()
        local vehNetId = GlobalState["asyacht-" .. yachtId .. "-vehid"]
        if vehNetId and NetworkDoesNetworkIdExist(vehNetId) then
            local driveVeh = NetToVeh(vehNetId)
            if DoesEntityExist(driveVeh) and GetEntityModel(driveVeh) == GetHashKey("as_yacht_veh") then
                if DoesEntityExist(yachtData.yachtmainobject) then
                    SetEntityNoCollisionEntity(yachtData.yachtmainobject, driveVeh, true)
                    AttachEntityToEntity(yachtData.yachtmainobject, driveVeh, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 5, true)
                    SetEntityVisible(yachtData.yachtmainobject, true)
                end
                SyncYachtSubObjects(yachtData, driveVeh)
            end
        end
    end)
end)

RegisterNetEvent("asyacht:Global:YachtMaximumSynchronizeAnchor")
AddEventHandler("asyacht:Global:YachtMaximumSynchronizeAnchor", function(yachtId)
    local yachtData = yachts["yacht-" .. yachtId]
    if not yachtData then return end
    if yachtData.removeinprogress then return end

    Citizen.CreateThread(function()
        local hasWater, waterZ = GetWaterHeightNoWaves(
            GlobalState["asyacht-" .. yachtId .. "-coords"].x,
            GlobalState["asyacht-" .. yachtId .. "-coords"].y, -4.0)
        local spawnZ = -4.0 + (hasWater and waterZ or 0)
        local spawnCoords = vector3(
            GlobalState["asyacht-" .. yachtId .. "-coords"].x,
            GlobalState["asyacht-" .. yachtId .. "-coords"].y, spawnZ)
        local spawnRot = GlobalState["asyacht-" .. yachtId .. "-rotation"].z

        local deadline = GetGameTimer() + 5000
        while true do
            Citizen.Wait(5)
            if DoesEntityExist(yachtData.yachtmainobject) then
                FreezeEntityPosition(yachtData.yachtmainobject, true)
                DetachEntity(yachtData.yachtmainobject)
                SetEntityVisible(yachtData.yachtmainobject, true)
                SetEntityCoords(yachtData.yachtmainobject,
                    spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, false, false)
                SetEntityRotation(yachtData.yachtmainobject, 0.0, 0.0, spawnRot)
            end
            if not IsEntityAttached(yachtData.yachtmainobject) then break end
            if GetGameTimer() > deadline then break end
        end

        Citizen.Wait(100)

        local colCfg = Config.YachColors[yachtData.yachtcolor]
        if DoesEntityExist(yachtData.yachtmainobject) then
            SetEntityCoords(yachtData.yachtmainobject,
                spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, false, false)
            SetEntityRotation(yachtData.yachtmainobject, 0.0, 0.0, spawnRot)
            FreezeEntityPosition(yachtData.yachtmainobject, true)
            SetEntityVisible(yachtData.yachtmainobject, true)
        else
            if not yachtData.hullspawning then
                yachtData.hullspawning = true
                RequestModel(yachtModelHash)
                while not HasModelLoaded(yachtModelHash) do
                    RequestModel(yachtModelHash)
                    Citizen.Wait(5)
                end
                local veh = CreateVehicle(yachtModelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, 0.0, false, true)
                yachtData.yachtmainobject = veh
                yachtData.hullspawning = false
                FreezeEntityPosition(veh, true)
                SetEntityRotation(veh, 0.0, 0.0, spawnRot)
                SetVehicleModColor_1(veh, 1, colCfg.primary, 0)
                SetVehicleModColor_2(veh, 1, colCfg.secondary)
                SetVehicleColours(veh, colCfg.primary, colCfg.secondary)
                SetVehicleDashboardColor(veh, colCfg.interior)
                SetVehicleInteriorColor(veh, GetRailingColour(yachtData.railing.railingid))
                SetObjectTextureVariant(veh, colCfg.overlay)
            end
        end

        local vehicle = yachtData.yachtmainobject
        if not DoesEntityExist(vehicle) then return end  

        for _, objData in ipairs(yachtData.mainobjects) do
            if DoesEntityExist(objData.handler) then
                AttachEntityToEntity(objData.handler, vehicle, 0,
                    objData.offsetcoords.x, objData.offsetcoords.y, objData.offsetcoords.z,
                    objData.offsetrotation.x, objData.offsetrotation.y, objData.offsetrotation.z,
                    false, false, true, false, 5, true)
            elseif not objData.spawning then
                objData.spawning = true
                local h = GetHashKey(objData.objectname)
                RequestModel(h)
                while not HasModelLoaded(h) do RequestModel(h) Citizen.Wait(5) end
                local obj = CreateObjectNoOffset(h, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, true, true)
                objData.handler = obj
                objData.spawning = false
                FreezeEntityPosition(obj, true)
                NetworkAllowLocalEntityAttachment(obj, true)
                SetObjectTextureVariant(obj, colCfg.overlay)
                SetEntityLodDist(obj, tonumber(Config.YachtDisplayMaxDistance) or 5000)
                AttachEntityToEntity(obj, vehicle, 0,
                    objData.offsetcoords.x, objData.offsetcoords.y, objData.offsetcoords.z,
                    objData.offsetrotation.x, objData.offsetrotation.y, objData.offsetrotation.z,
                    false, false, true, false, 5, true)
                DetachEntity(obj)
                FreezeEntityPosition(obj, true)
            end
        end

        if DoesEntityExist(yachtData.flagdata.handler) then
            AttachEntityToEntity(yachtData.flagdata.handler, vehicle, 0,
                -0.05, -56.55, 7.4, 230.0, -180.0, 0.0, false, false, true, false, 5, true)
        elseif not yachtData.flagdata.spawning then
            yachtData.flagdata.spawning = true
            local h = GetHashKey(flagObjectsList[yachtData.flagdata.flagid].flagobject)
            RequestModel(h)
            while not HasModelLoaded(h) do RequestModel(h) Citizen.Wait(5) end
            local obj = CreateObjectNoOffset(h, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, true, true)
            yachtData.flagdata.handler = obj
            yachtData.flagdata.spawning = false
            FreezeEntityPosition(obj, true)
            NetworkAllowLocalEntityAttachment(obj, true)
            SetObjectTextureVariant(obj, colCfg.overlay)
            SetEntityLodDist(obj, tonumber(Config.YachtDisplayMaxDistance) or 5000)
            AttachEntityToEntity(obj, vehicle, 0, -0.05, -56.55, 7.4, 230.0, -180.0, 0.0, false, false, true, false, 5, true)
            DetachEntity(obj)
            FreezeEntityPosition(obj, true)
        end

        if DoesEntityExist(yachtData.lighting.handler) then
            AttachEntityToEntity(yachtData.lighting.handler, vehicle, 0,
                yachtData.lighting.coords.x - 2.05, yachtData.lighting.coords.y, yachtData.lighting.coords.z + 5.8,
                yachtData.lighting.rotation.x, yachtData.lighting.rotation.y, yachtData.lighting.rotation.z + 90.0,
                false, false, true, false, 5, true)
        elseif not yachtData.lighting.spawning and YachtLightsWanted(yachtData.yachtiddata) then
            yachtData.lighting.spawning = true
            local h = GetHashKey(GetLightColorObject(yachtData.lighting.lightingcategory, yachtData.lighting.lightingid))
            RequestModel(h)
            while not HasModelLoaded(h) do RequestModel(h) Citizen.Wait(5) end
            local obj = CreateObjectNoOffset(h, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, true, true)
            yachtData.lighting.handler = obj
            yachtData.lighting.spawning = false
            FreezeEntityPosition(obj, true)
            NetworkAllowLocalEntityAttachment(obj, true)
            SetObjectTextureVariant(obj, colCfg.overlay)
            SetEntityLodDist(obj, tonumber(Config.YachtDisplayMaxDistance) or 5000)
            AttachEntityToEntity(obj, vehicle, 0,
                yachtData.lighting.coords.x - 2.05, yachtData.lighting.coords.y, yachtData.lighting.coords.z + 5.8,
                yachtData.lighting.rotation.x, yachtData.lighting.rotation.y, yachtData.lighting.rotation.z + 90.0,
                false, false, true, false, 5, true)
            DetachEntity(obj)
            FreezeEntityPosition(obj, true)
        end

        local rOffX = yachtData.railing.coords.x - 2.0
        local rOffY = yachtData.railing.coords.y
        local rOffZ = yachtData.railing.coords.z + 5.8
        local rRotZ = yachtData.railing.rotation.z + 90.0
        local rRotX = yachtData.railing.rotation.x
        local rRotY = yachtData.railing.rotation.y
        local railBase = anchorRailingTypesList[yachtData.railing.railingid].railingobject

        for _, suffix in ipairs({"", "_down"}) do
            local field = (suffix == "") and "handler2" or "handler3"
            if DoesEntityExist(yachtData.railing[field]) then
                AttachEntityToEntity(yachtData.railing[field], vehicle, 0,
                    rOffX, rOffY, rOffZ, rRotX, rRotY, rRotZ, false, false, false, false, 5, true)
                DetachEntity(yachtData.railing[field])
                FreezeEntityPosition(yachtData.railing[field], true)
            elseif not yachtData.railing["spawning_" .. field] then
                yachtData.railing["spawning_" .. field] = true
                local h = GetHashKey(railBase .. suffix)
                RequestModel(h)
                while not HasModelLoaded(h) do RequestModel(h) Citizen.Wait(5) end
                local obj = CreateObjectNoOffset(h, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, true, true)
                yachtData.railing[field] = obj
                yachtData.railing["spawning_" .. field] = false
                FreezeEntityPosition(obj, true)
                NetworkAllowLocalEntityAttachment(obj, true)
                SetObjectTextureVariant(obj, colCfg.overlay)
                SetEntityLodDist(obj, tonumber(Config.YachtDisplayMaxDistance) or 5000)
                SetEntityVisible(obj, false)
                AttachEntityToEntity(obj, vehicle, 0, rOffX, rOffY, rOffZ, rRotX, rRotY, rRotZ, false, false, false, false, 5, true)
                DetachEntity(obj)
                FreezeEntityPosition(obj, true)
            end
        end
        
        if DoesEntityExist(yachtData.railing.handler2) then SetEntityVisible(yachtData.railing.handler2, false) end
        if DoesEntityExist(yachtData.railing.handler3) then SetEntityVisible(yachtData.railing.handler3, true) end

        for _, door in ipairs(yachtData.doors) do
            if DoesEntityExist(door.handler) then
                local rot = door.opened and door.rotationopened or door.rotation
                AttachEntityToEntity(door.handler, vehicle, 0,
                    door.coords.x, door.coords.y, door.coords.z,
                    rot.x, rot.y, rot.z, false, false, true, false, 5, true)
            elseif not door.spawning then
                door.spawning = true
                local h = GetHashKey(door.objectname)
                RequestModel(h)
                while not HasModelLoaded(h) do RequestModel(h) Citizen.Wait(5) end
                local obj = CreateObjectNoOffset(h, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, true, true)
                door.handler = obj
                door.spawning = false
                FreezeEntityPosition(obj, true)
                NetworkAllowLocalEntityAttachment(obj, true)
                SetObjectTextureVariant(obj, colCfg.overlay)
                SetEntityLodDist(obj, tonumber(Config.YachtDisplayMaxDistance) or 5000)
                local rot = door.opened and door.rotationopened or door.rotation
                AttachEntityToEntity(obj, vehicle, 0,
                    door.coords.x, door.coords.y, door.coords.z,
                    rot.x, rot.y, rot.z, false, false, true, false, 5, true)
                DetachEntity(obj)
                FreezeEntityPosition(obj, true)
            end
        end

        for _, furnitureEntry in pairs(yachtData.furnitureobjects) do
            if not furnitureEntry.removeinprogress and not furnitureEntry.editing then
                if DoesEntityExist(furnitureEntry.handler) then
                    AttachEntityToEntity(furnitureEntry.handler, vehicle, 0,
                        furnitureEntry.furniturecoords.x, furnitureEntry.furniturecoords.y, furnitureEntry.furniturecoords.z,
                        furnitureEntry.furniturerotation.x, furnitureEntry.furniturerotation.y, furnitureEntry.furniturerotation.z,
                        false, false, true, false, 2, true)
                    DetachEntity(furnitureEntry.handler)
                    FreezeEntityPosition(furnitureEntry.handler, true)
                elseif not furnitureEntry.spawning then
                    furnitureEntry.spawning = true
                    local h = GetHashKey(furnitureEntry.furnituremodel)
                    RequestModel(h)
                    while not HasModelLoaded(h) do RequestModel(h) Citizen.Wait(5) end
                    local obj = CreateObjectNoOffset(h, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, true, true)
                    furnitureEntry.handler = obj
                    furnitureEntry.spawning = false
                    if furnitureEntry.removeinprogress then
                        DeleteEntity(obj)
                    else
                        FreezeEntityPosition(obj, true)
                        NetworkAllowLocalEntityAttachment(obj, true)
                        SetEntityRotation(obj, 0.0, 0.0, 0.0)
                        SetObjectTextureVariant(obj, colCfg.overlay)
                        SetEntityLodDist(obj, tonumber(Config.YachtDisplayMaxDistance) or 5000)
                        AttachEntityToEntity(obj, vehicle, 0,
                            furnitureEntry.furniturecoords.x, furnitureEntry.furniturecoords.y, furnitureEntry.furniturecoords.z,
                            furnitureEntry.furniturerotation.x, furnitureEntry.furniturerotation.y, furnitureEntry.furniturerotation.z,
                            false, false, true, false, 2, true)
                        DetachEntity(obj)
                        FreezeEntityPosition(obj, true)
                    end
                end
            end
        end
    end)
end)

RegisterNetEvent("asyacht:Global:CloseOpenHandler")
AddEventHandler("asyacht:Global:CloseOpenHandler", function(yachtId, doorId, open)
    if yachtId == nil or doorId == nil then return end

    local pairedDoors = {
        [32] = 33, [33] = 32,
        [34] = 35, [35] = 34,
        [36] = 37, [37] = 36,
        [30] = 31, [31] = 30,
        [38] = 39, [39] = 38,
        [40] = 41, [41] = 40,
    }

    if pairedDoors[doorId] then
        TriggerEvent("asyacht:Global:DoorSpecial", yachtId, doorId, open)
        TriggerEvent("asyacht:Global:DoorSpecial", yachtId, pairedDoors[doorId], open)
    else
        ToggleDoor(yachtId, doorId, open)
    end
end)

RegisterNetEvent("asyacht:Global:FurnitureNew")
AddEventHandler("asyacht:Global:FurnitureNew", function(yachtId, furnitureKey, furnitureModel, furnitureCoords, furnitureRot)
    local yachtData = yachts["yacht-" .. yachtId]
    if not yachtData then return end

    local modelStr = type(furnitureModel) == "table" and furnitureModel.furnituremodel or furnitureModel
    local c = type(furnitureCoords) == "table" and furnitureCoords or (type(furnitureModel) == "table" and furnitureModel.furniturecoords or vector3(0,0,0))
    local r = type(furnitureRot) == "table" and furnitureRot or (type(furnitureModel) == "table" and furnitureModel.furniturerotation or vector3(0,0,0))

    local purchase = pendingFurniturePurchase
    local needsPurchaseFinalization = purchase
        and purchase.yachtId == yachtId
        and purchase.model == modelStr
        and GetGameTimer() <= purchase.expiresAt
        and DoesEntityExist(yachtData.yachtmainobject)

    if needsPurchaseFinalization then
        c = GetOffsetFromEntityGivenWorldCoords(
            yachtData.yachtmainobject,
            purchase.worldCoords.x, purchase.worldCoords.y, purchase.worldCoords.z)
        local hullRot = GetEntityRotation(yachtData.yachtmainobject, 2)
        r = vector3(
            purchase.worldRotation.x - hullRot.x,
            purchase.worldRotation.y - hullRot.y,
            purchase.worldRotation.z - hullRot.z)
        pendingFurniturePurchase = nil
    elseif purchase and GetGameTimer() > purchase.expiresAt then
        pendingFurniturePurchase = nil
    end

    local entry = {
        handler           = nil,
        removeinprogress  = false,
        furnituremodel    = modelStr,
        furniturecoords   = vector3(c.x, c.y, c.z),
        furniturerotation = vector3(r.x, r.y, r.z),
    }
    yachtData.furnitureobjects[tostring(furnitureKey)] = entry

    if needsPurchaseFinalization then
        Citizen.CreateThread(function()
            Citizen.Wait(0)
            TriggerServerEvent("asyacht:Global:SaveFurniture", yachtId, furnitureKey,
                vector3(c.x, c.y, c.z), vector3(r.x, r.y, r.z))
        end)
    end
end)

RegisterNetEvent("asyacht:Global:UpdateFurniture")
AddEventHandler("asyacht:Global:UpdateFurniture", function(yachtId, furnitureKey, newCoords, newRot)
    local yachtData = yachts["yacht-" .. yachtId]
    if not yachtData then return end
    local furnitureEntry = yachtData.furnitureobjects[tostring(furnitureKey)]
    if not furnitureEntry then return end

    furnitureEntry.furniturecoords   = vector3(newCoords.x, newCoords.y, newCoords.z)
    furnitureEntry.furniturerotation = vector3(newRot.x, newRot.y, newRot.z)
    furnitureEntry.editing = false

    if DoesEntityExist(furnitureEntry.handler) and DoesEntityExist(yachtData.yachtmainobject) then
        AttachEntityToEntity(furnitureEntry.handler, yachtData.yachtmainobject, 0,
            furnitureEntry.furniturecoords.x, furnitureEntry.furniturecoords.y, furnitureEntry.furniturecoords.z,
            furnitureEntry.furniturerotation.x, furnitureEntry.furniturerotation.y, furnitureEntry.furniturerotation.z,
            false, false, true, false, 2, true)
    end
end)

RegisterNetEvent("asyacht:Global:RemoveFurnitureObject")
AddEventHandler("asyacht:Global:RemoveFurnitureObject", function(yachtId, furnitureKey)
    if yachtId == nil then return end
    local yachtData = yachts["yacht-" .. yachtId]
    if not yachtData then return end
    local furnitureEntry = yachtData.furnitureobjects[furnitureKey]
    if not furnitureEntry then return end

    furnitureEntry.removeinprogress = true

    if furnitureEntry.spawning then
        
        return
    end

    DetachEntity(furnitureEntry.handler, true, true)
    if DoesEntityExist(furnitureEntry.handler) then
        DeleteEntity(furnitureEntry.handler)
    end
    yachtData.furnitureobjects[furnitureKey] = nil

    SendNUIMessage({message = "removeobjectfromfurniturelist", furnitureid = furnitureKey})
end)

RegisterNetEvent("asyacht:Global:RemoveYacht")
AddEventHandler("asyacht:Global:RemoveYacht", function(yachtId)
    if yachtId == nil then return end
    local yachtKey  = "yacht-" .. yachtId
    local yachtData = yachts[yachtKey]
    if yachtData == nil then return end

    yachtData.removeinprogress = true

    local spawnWaitDeadline = GetGameTimer() + 10000
    local function anySpawning()
        if yachtData.hullspawning then return true end
        for _, obj in ipairs(yachtData.mainobjects) do
            if obj.spawning then return true end
        end
        for _, door in ipairs(yachtData.doors) do
            if door.spawning then return true end
        end
        if yachtData.flagdata.spawning then return true end
        if yachtData.lighting.spawning then return true end
        if yachtData.railing.spawning_handler2 or yachtData.railing.spawning_handler3 then return true end
        for _, furnitureEntry in pairs(yachtData.furnitureobjects) do
            if furnitureEntry.spawning then return true end
        end
        return false
    end
    while anySpawning() and GetGameTimer() < spawnWaitDeadline do
        Citizen.Wait(50)
    end

    for _, obj in ipairs(yachtData.mainobjects) do
        if DoesEntityExist(obj.handler) then
            DetachEntity(obj.handler, true, true)
            DeleteEntity(obj.handler)
        end
    end

    for _, furnitureEntry in pairs(yachtData.furnitureobjects) do
        if not furnitureEntry.removeinprogress and DoesEntityExist(furnitureEntry.handler) then
            DetachEntity(furnitureEntry.handler, true, true)
            DeleteEntity(furnitureEntry.handler)
        end
    end

    for _, door in ipairs(yachtData.doors) do
        if DoesEntityExist(door.handler) then
            DetachEntity(door.handler, true, true)
            DeleteEntity(door.handler)
        end
    end

    if DoesEntityExist(yachtData.flagdata.handler) then
        DetachEntity(yachtData.flagdata.handler, true, true)
        DeleteEntity(yachtData.flagdata.handler)
    end

    if DoesEntityExist(yachtData.lighting.handler) then
        DetachEntity(yachtData.lighting.handler, true, true)
        DeleteEntity(yachtData.lighting.handler)
    end

    for _, h in ipairs({"handler", "handler2", "handler3"}) do
        if DoesEntityExist(yachtData.railing[h]) then
            DetachEntity(yachtData.railing[h], true, true)
            DeleteEntity(yachtData.railing[h])
        end
    end

    if DoesEntityExist(yachtData.yachtmainobject) then
        DetachEntity(yachtData.yachtmainobject, true, true)
        DeleteEntity(yachtData.yachtmainobject)
    end

    Citizen.Wait(1000)
    yachts[yachtKey]            = nil
    yachtIntroPlayed[yachtId]   = nil
    RemovePersonalYachtBlip(yachtId)
end)

RegisterNetEvent("asyacht:Global:OpenStorageClient")
AddEventHandler("asyacht:Global:OpenStorageClient", function(yachtId, storageIndex)
    if yachtId == nil then return end
    if currentNearYachtId == nil then return end
    if yachts["yacht-" .. yachtId] == nil then return end
    OpenYachtStorage(yachtId, storageIndex)
end)

RegisterNetEvent("asyacht:Global:OpenWardrobeClient")
AddEventHandler("asyacht:Global:OpenWardrobeClient", function(yachtId, wardrobeIndex)
    if yachtId == nil then return end
    if currentNearYachtId == nil then return end
    if yachts["yacht-" .. yachtId] == nil then return end
    OpenYachtWardrobe(yachtId, wardrobeIndex)
end)

RegisterNetEvent("asyacht:Global:DriveProtect")
AddEventHandler("asyacht:Global:DriveProtect", function(yachtId)
    if yachtId == nil then return end
    DoScreenFadeOut(5)

    local yachtData = yachts["yacht-" .. yachtId]
    if not yachtData then return end
    if not DoesEntityExist(yachtData.yachtmainobject) then return end

    local playerPed = PlayerPedId()
    local yachtCoords = GetEntityCoords(yachtData.yachtmainobject)
    local yachtRot    = GetEntityRotation(yachtData.yachtmainobject, 2)

    local driveCfg = Config.YachtDriveLocation.coords
    local rad       = math.rad(yachtRot.z)
    local cosZ, sinZ = math.cos(rad), math.sin(rad)
    local relX = driveCfg.x * cosZ - driveCfg.y * sinZ + yachtCoords.x
    local relY = driveCfg.y * cosZ + driveCfg.x * sinZ + yachtCoords.y
    local relZ = (driveCfg.z - 0.25) + yachtCoords.z

    SetEntityCoordsNoOffset(playerPed, relX, relY, relZ)
    FreezeEntityPosition(playerPed, true)
    NetworkAllowLocalEntityAttachment(playerPed, true)
end)

RegisterNetEvent("asyacht:Global:YachtClientMethod")
AddEventHandler("asyacht:Global:YachtClientMethod", function(yachtId)
    local yachtData = yachts["yacht-" .. yachtId]
    if not yachtData then return end

    RequestModel(yachtModelHash)
    while not HasModelLoaded(yachtModelHash) do
        RequestModel(yachtModelHash)
        Citizen.Wait(5)
    end

    local playerPed = PlayerPedId()

    local rawCoords = GlobalState["asyacht-" .. yachtId .. "-coords"]
    local rawRot    = GlobalState["asyacht-" .. yachtId .. "-rotation"]
    while not rawCoords or not rawRot do
        Citizen.Wait(50)
        rawCoords = GlobalState["asyacht-" .. yachtId .. "-coords"]
        rawRot    = GlobalState["asyacht-" .. yachtId .. "-rotation"]
    end
    local gCoords = vector3(rawCoords.x, rawCoords.y, rawCoords.z)

    local hasWater, waterZ = GetWaterHeightNoWaves(gCoords.x, gCoords.y, -4.0)
    local spawnZ = -4.0 + (hasWater and waterZ or 0)

    local vehicle = CreateVehicle(yachtModelHash,
        gCoords.x, gCoords.y, spawnZ,
        0.0, true, true)

    drivingState.yachthandler = vehicle

    SetVehicleDoorsLocked(vehicle, 9)

    local colCfg = Config.YachColors[yachtData.yachtcolor]
    SetVehicleModColor_1(vehicle, 1, colCfg.primary, 0)
    SetVehicleModColor_2(vehicle, 1, colCfg.secondary)
    SetVehicleColours(vehicle, colCfg.primary, colCfg.secondary)
    SetVehicleDashboardColor(vehicle, colCfg.interior)
    SetVehicleInteriorColor(vehicle, GetRailingColour(yachtData.railing.railingid))

    SetEntityRotation(vehicle, 0.0, 0.0, rawRot.z)

    NetworkAllowLocalEntityAttachment(vehicle, true)
    FreezeEntityPosition(vehicle, true)
    SetEntityVisible(vehicle, false)
    SetEntityInvincible(vehicle, true)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetModelAsNoLongerNeeded(yachtModelHash)
    SetVehRadioStation(vehicle, "OFF")
    SetVehicleRadioEnabled(vehicle, false)

    TaskWarpPedIntoVehicle(playerPed, vehicle, -1)

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    TriggerServerEvent("asyacht:Global:YachtClientMethodGet", yachtId, netId)

    drivingState.driving   = true
    drivingState.drivingid = yachtId

    local plate = PlateReformat(GetVehicleNumberPlateText(vehicle))
    AddYachtKey(vehicle, GetEntityModel(vehicle), plate)

    DoScreenFadeIn(500)

    local nextTick = 0
    local lastFuelSent = nil
    while drivingState.driving do
        Citizen.Wait(0)
        if not DoesEntityExist(vehicle) then break end
        DisableControlAction(0, 75, true)  
        local engine = GetYachtEngineStats(yachtId)
        local outOfFuel = false
        if Config.Fuel and Config.Fuel.enabled then
            local fuel = yachtFuel[yachtId] or 100.0
            outOfFuel = fuel <= 0.0
            if fuel ~= lastFuelSent then
                lastFuelSent = fuel
                SendNUIMessage({ message = "fuelhud", show = true, value = fuel })
            end
        end
        if outOfFuel then
            SetVehicleEngineOn(vehicle, false, true, true)
            DisableControlAction(0, 71, true) -- accelerate
            DisableControlAction(0, 72, true) -- brake / reverse
        elseif engine then
            SetVehicleCheatPowerIncrease(vehicle, engine.power or 1.0)
            SetVehicleEngineTorqueMultiplier(vehicle, engine.torque or 1.0)
        end
        local now = GetGameTimer()
        if not Config.ServerNetworkYacht and now >= nextTick then
            nextTick = now + 5000
            local c, r = GetEntityCoords(vehicle), GetEntityRotation(vehicle)
            TriggerServerEvent("asyacht:Global:DriveTick", yachtId, {x=c.x, y=c.y, z=c.z}, {x=r.x, y=r.y, z=r.z})
        end
        local currentDriver = GetPedInVehicleSeat(vehicle, -1)
        if currentDriver ~= playerPed then
            TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
        end
    end

    drivingState.driving      = false
    drivingState.drivingid    = nil
    drivingState.yachthandler = nil
    SendNUIMessage({ message = "fuelhud", show = false })

    RemoveYachtKey(vehicle, plate, GetEntityModel(vehicle))
    TaskLeaveVehicle(playerPed, vehicle, 0)
    Citizen.Wait(500)
    if DoesEntityExist(vehicle) then
        DeleteEntity(vehicle)
    end
end)

RegisterNetEvent("asyacht:Global:DriveYachtUnfreeze")
AddEventHandler("asyacht:Global:DriveYachtUnfreeze", function(yachtId)
    if not drivingState.driving then return end

    NetworkRequestControlOfEntity(drivingState.yachthandler)
    while not NetworkHasControlOfEntity(drivingState.yachthandler) do
        if not DoesEntityExist(drivingState.yachthandler) then return end
        Citizen.Wait(5)
        NetworkRequestControlOfEntity(drivingState.yachthandler)
    end

    local hasWater, waterZ = GetWaterHeightNoWaves(
        GlobalState["asyacht-" .. yachtId .. "-coords"].x,
        GlobalState["asyacht-" .. yachtId .. "-coords"].y, -4.0)
    local spawnZ = -4.0 + (hasWater and waterZ or 0)

    FreezeEntityPosition(drivingState.yachthandler, false)
    SetEntityCoords(drivingState.yachthandler,
        GlobalState["asyacht-" .. yachtId .. "-coords"].x,
        GlobalState["asyacht-" .. yachtId .. "-coords"].y, spawnZ, false, false, false, false)
    SetEntityRotation(drivingState.yachthandler, 0.0, 0.0, GlobalState["asyacht-" .. yachtId .. "-rotation"].z)

    Citizen.Wait(10)
    SetEntityCoords(drivingState.yachthandler,
        GlobalState["asyacht-" .. yachtId .. "-coords"].x,
        GlobalState["asyacht-" .. yachtId .. "-coords"].y, spawnZ, false, false, false, false)
    SetEntityRotation(drivingState.yachthandler, 0.0, 0.0, GlobalState["asyacht-" .. yachtId .. "-rotation"].z)
end)

RegisterNetEvent("asyacht:Global:Anchor")
AddEventHandler("asyacht:Global:Anchor", function(yachtId, isAnchoring)
    local yachtData = yachts["yacht-" .. yachtId]
    if not yachtData then return end
    if not DoesEntityExist(yachtData.yachtmainobject) then return end

    if not DoesEntityExist(yachtData.railing.handler2) or not DoesEntityExist(yachtData.railing.handler3) then
        local vehicle = yachtData.yachtmainobject
        local vCoords = GetEntityCoords(vehicle)
        local railingBaseName = anchorRailingTypesList[yachtData.railing.railingid].railingobject
        local colCfg = Config.YachColors[yachtData.yachtcolor]
        local rOffX = yachtData.railing.coords.x - 2.0
        local rOffY = yachtData.railing.coords.y
        local rOffZ = yachtData.railing.coords.z + 5.8
        local rRotX = yachtData.railing.rotation.x
        local rRotY = yachtData.railing.rotation.y
        local rRotZ = yachtData.railing.rotation.z + 90.0

        if not DoesEntityExist(yachtData.railing.handler2) and not yachtData.railing.spawning_handler2 then
            yachtData.railing.spawning_handler2 = true
            local rHash2 = GetHashKey(railingBaseName)
            RequestModel(rHash2)
            while not HasModelLoaded(rHash2) do
                RequestModel(rHash2)
                Citizen.Wait(5)
            end
            local rObj2 = CreateObjectNoOffset(rHash2, vCoords.x, vCoords.y, vCoords.z, false, true, true)
            yachtData.railing.handler2 = rObj2
            yachtData.railing.spawning_handler2 = false
            SetObjectTextureVariant(rObj2, colCfg.overlay)
            SetEntityLodDist(rObj2, tonumber(Config.YachtDisplayMaxDistance) or 5000)
            AttachEntityToEntity(rObj2, vehicle, 0, rOffX, rOffY, rOffZ, rRotX, rRotY, rRotZ, false, false, true, false, 5, true)
        end

        if not DoesEntityExist(yachtData.railing.handler3) and not yachtData.railing.spawning_handler3 then
            yachtData.railing.spawning_handler3 = true
            local rHash3 = GetHashKey(railingBaseName .. "_down")
            RequestModel(rHash3)
            while not HasModelLoaded(rHash3) do
                RequestModel(rHash3)
                Citizen.Wait(5)
            end
            local rObj3 = CreateObjectNoOffset(rHash3, vCoords.x, vCoords.y, vCoords.z, false, true, true)
            yachtData.railing.handler3 = rObj3
            yachtData.railing.spawning_handler3 = false
            SetObjectTextureVariant(rObj3, colCfg.overlay)
            SetEntityLodDist(rObj3, tonumber(Config.YachtDisplayMaxDistance) or 5000)
            AttachEntityToEntity(rObj3, vehicle, 0, rOffX, rOffY, rOffZ, rRotX, rRotY, rRotZ, false, false, true, false, 5, true)
        end
    end

    if DoesEntityExist(yachtData.railing.handler2) then SetEntityVisible(yachtData.railing.handler2, not isAnchoring) end
    if DoesEntityExist(yachtData.railing.handler3) then SetEntityVisible(yachtData.railing.handler3, isAnchoring) end
end)

RegisterNetEvent("asyacht:Global:AttachPlayer")
AddEventHandler("asyacht:Global:AttachPlayer", function(yachtId)
    if currentNearYachtId ~= yachtId then return end
    if drivingState.driving then return end

    local yachtData = yachts["yacht-" .. yachtId]
    if not yachtData or not DoesEntityExist(yachtData.yachtmainobject) then return end

    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    local relOffset = GetOffsetFromEntityGivenWorldCoords(yachtData.yachtmainobject, pedCoords.x, pedCoords.y, pedCoords.z)

    if not IsEntityTouchingEntity(ped, yachtData.yachtmainobject) then return end

    FreezeEntityPosition(ped, true)
    AttachEntityToEntity(ped, yachtData.yachtmainobject, 0, relOffset.x, relOffset.y, relOffset.z, 0.0, 0.0, 0.0, false, false, false, false, 5, true)

    if not Config.ServerNetworkYacht then return end

    Citizen.CreateThread(function()
        local hasWater, waterZ = GetWaterHeightNoWaves(
            GlobalState["asyacht-" .. yachtId .. "-coords"].x,
            GlobalState["asyacht-" .. yachtId .. "-coords"].y, -4.0)
        local spawnZ = -4.0 + (hasWater and waterZ or 0)

        local waited = 0
        while GlobalState["asyacht-" .. yachtId .. "-vehid"] == nil and waited < 5000 do
            Citizen.Wait(5)
            waited = waited + 5
            SetEntityCoords(yachtData.yachtmainobject,
                GlobalState["asyacht-" .. yachtId .. "-coords"].x,
                GlobalState["asyacht-" .. yachtId .. "-coords"].y, spawnZ, false, false, false, false)
            SetEntityRotation(yachtData.yachtmainobject, 0.0, 0.0, GlobalState["asyacht-" .. yachtId .. "-rotation"].z)
        end

        for _ = 1, 9 do
            Citizen.Wait(500)
            AttachEntityToEntity(ped, yachtData.yachtmainobject, 0, relOffset.x, relOffset.y, relOffset.z, 0.0, 0.0, 0.0, false, false, false, false, 5, true)
            if Config.ServerNetworkYacht then
                SetEntityCoords(yachtData.yachtmainobject,
                    GlobalState["asyacht-" .. yachtId .. "-coords"].x,
                    GlobalState["asyacht-" .. yachtId .. "-coords"].y, spawnZ, false, false, false, false)
                SetEntityRotation(yachtData.yachtmainobject, 0.0, 0.0, GlobalState["asyacht-" .. yachtId .. "-rotation"].z)
            end
        end

        Citizen.Wait(2000)
        
        DetachEntity(ped, true, true)
        FreezeEntityPosition(ped, false)
    end)
end)

RegisterNetEvent("asyacht:Global:DeattachPlayer")
AddEventHandler("asyacht:Global:DeattachPlayer", function(yachtId)
    if currentNearYachtId ~= yachtId then return end
    if drivingState.driving then return end

    local playerPed = PlayerPedId()
    
    DetachEntity(playerPed, true, true)
    FreezeEntityPosition(playerPed, false)
    DoScreenFadeIn(0)
end)

RegisterNetEvent("asyacht:Global:ReattachYacht")
AddEventHandler("asyacht:Global:ReattachYacht", function(yachtId)
    local yachtData = yachts["yacht-" .. yachtId]
    if not yachtData then return end

    local vehicle = yachtData.yachtmainobject
    if not DoesEntityExist(vehicle) then return end

    local driveVeh = GetYachtDriveVehicle(yachtId)
    if driveVeh then
        SetEntityNoCollisionEntity(vehicle, driveVeh, true)
        AttachEntityToEntity(vehicle, driveVeh, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 5, true)
        SetEntityVisible(vehicle, true)
    end

    SyncYachtSubObjects(yachtData, driveVeh)
end)

RegisterNetEvent("asyacht:Global:HottubSit")
AddEventHandler("asyacht:Global:HottubSit", function(yachtId, seatIndex)
    if isPlayerSeated then return end
    SendNUIMessage({message = "hottubseatshow"})
    isPlayerSeated = true
    hottubSeatInfo.yachtid = yachtId
    hottubSeatInfo.seatid  = seatIndex
end)

RegisterNetEvent("asyacht:Global:SeatUseClient")
AddEventHandler("asyacht:Global:SeatUseClient", function(yachtId, seatIndex, taken, takenByServerId)
    local yachtData = yachts["yacht-" .. yachtId]
    if not yachtData then return end
    local seat = yachtData.hottubseats[seatIndex]
    if not seat then return end
    seat.taken = taken

    if not taken then
        seat.takenplayerid = nil
        if takenByServerId ~= nil then
            local plyIdx = GetPlayerFromServerId(takenByServerId)
            if plyIdx ~= -1 then
                local ped = GetPlayerPed(plyIdx)
                if DoesEntityExist(ped) then
                    DetachEntity(ped)
                    FreezeEntityPosition(ped, false)
                    ClearPedTasks(ped)
                end
            end
        end
    else
        seat.takenplayerid = takenByServerId
        local plyIdx = GetPlayerFromServerId(takenByServerId)
        if plyIdx ~= -1 then
            local ped = GetPlayerPed(plyIdx)
            if DoesEntityExist(ped) and DoesEntityExist(yachtData.yachtmainobject) then
                FreezeEntityPosition(ped, true)
                NetworkAllowLocalEntityAttachment(ped, true)
                AttachEntityToEntity(ped, yachtData.yachtmainobject, 0,
                    seat.offsets.coords.x, seat.offsets.coords.y, seat.offsets.coords.z,
                    seat.offsets.rotation.x, seat.offsets.rotation.y, seat.offsets.rotation.z,
                    false, false, false, false, 2, true)

                local animDict = "amb@prop_human_seat_chair_mp@female@proper@idle_a"
                RequestAnimDict(animDict)
                while not HasAnimDictLoaded(animDict) do
                    RequestAnimDict(animDict)
                    Citizen.Wait(5)
                end
                TaskPlayAnim(ped, animDict, "idle_b", 8.0, 8.0, -1, 1, 0, false, false, false)
            end
        end
    end
end)

RegisterNetEvent("asyacht:Global:HottubLeave")
AddEventHandler("asyacht:Global:HottubLeave", function()
    if not isPlayerSeated then return end
    local playerPed = PlayerPedId()
    local yachtData  = yachts["yacht-" .. tostring(hottubSeatInfo.yachtid)]

    if yachtData and DoesEntityExist(yachtData.yachtmainobject) then
        local seat = yachtData.hottubseats[hottubSeatInfo.seatid]
        if seat then
            local yCoords = GetEntityCoords(yachtData.yachtmainobject)
            local yRot    = GetEntityRotation(yachtData.yachtmainobject, 2)
            local rad        = math.rad(yRot.z)
            local cosZ, sinZ = math.cos(rad), math.sin(rad)
            local off = seat.offsets.coords

            local worldX = (off.x * cosZ) - (off.y * sinZ) + yCoords.x
            local worldY = (off.y * cosZ) + (off.x * sinZ) + yCoords.y
            local worldZ = off.z + yCoords.z

            DetachEntity(playerPed)
            FreezeEntityPosition(playerPed, false)
            ClearPedTasks(playerPed)
            SetEntityCoordsNoOffset(playerPed, worldX, worldY, worldZ + 0.5)
        end
    end

    SendNUIMessage({message = "hidehottubseat"})
    isPlayerSeated = false
    hottubSeatInfo.yachtid = nil
    hottubSeatInfo.seatid  = nil
end)

RegisterNetEvent("asyacht:Global:OpenYachtBuyMenuTarget")
AddEventHandler("asyacht:Global:OpenYachtBuyMenuTarget", function()
    if not isYachtBuyMenuOpen then
        TriggerServerEvent("asyacht:Global:SynchronizeYacht")
    end
end)
