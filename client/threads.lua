-- as-yacht client/threads.lua: Main loops (interaction, prompts, drive and buy flow).
-- (Split from the former client/main.lua. File-level state is global so every client module shares it.)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        local playerPed    = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local maxDist      = tonumber(Config.YachtDisplayMaxDistance) or 5000
        local closestDist  = -1
        local nearestId    = nil

        for _, yachtData in pairs(yachts) do
            local ok, syncErr = pcall(function()
            local stateCoords = GlobalState["asyacht-" .. yachtData.yachtiddata .. "-coords"]
            if stateCoords ~= nil then
                local dist = #(playerCoords - vector3(stateCoords.x, stateCoords.y, stateCoords.z))
                if dist < maxDist and not yachtData.removeinprogress then
                    
                    if dist < 500.0 and (closestDist == -1 or dist < closestDist) then
                        closestDist = dist
                        nearestId   = yachtData.yachtiddata
                    end

                    local colCfg   = Config.YachColors[yachtData.yachtcolor]
                    local anchored = GlobalState["asyacht-" .. yachtData.yachtiddata .. "-anchored"]

                    if anchored then
                        
                        local now = GetGameTimer()
                        if (now - (yachtData.lastAnchorTick or 0)) >= 1000 then
                        yachtData.lastAnchorTick = now

                        local hasWater, waterZ = GetWaterHeightNoWaves(stateCoords.x, stateCoords.y, -4.0)
                        local spawnZ  = -4.0 + (hasWater and waterZ or 0)
                        local sCoords = vector3(stateCoords.x, stateCoords.y, spawnZ)
                        local sRotZ   = GlobalState["asyacht-" .. yachtData.yachtiddata .. "-rotation"].z

                        if DoesEntityExist(yachtData.yachtmainobject) then
                            if yachtIntroPlayed[yachtData.yachtiddata] then
                                CreatePersonalYachtBlip(yachtData.yachtiddata)
                            end
                            DetachEntity(yachtData.yachtmainobject)
                            SetEntityCoords(yachtData.yachtmainobject, sCoords.x, sCoords.y, sCoords.z, false, false, false, false)
                            SetEntityRotation(yachtData.yachtmainobject, 0.0, 0.0, sRotZ)
                            FreezeEntityPosition(yachtData.yachtmainobject, true)
                            SetEntityVisible(yachtData.yachtmainobject, true)
                            SetVehicleEngineOn(yachtData.yachtmainobject, false, true, true)
                            SetVehicleUndriveable(yachtData.yachtmainobject, true)
                        else
                            if not yachtData.hullspawning then
                                yachtData.hullspawning = true
                                RequestModel(yachtModelHash)
                                while not HasModelLoaded(yachtModelHash) do
                                    RequestModel(yachtModelHash)
                                    Citizen.Wait(5)
                                end
                                local veh = CreateVehicle(yachtModelHash, sCoords.x, sCoords.y, sCoords.z, 0.0, false, true)
                                yachtData.yachtmainobject = veh
                                yachtData.hullspawning = false
                                SetVehicleDoorsLocked(veh, 9)
                                FreezeEntityPosition(veh, true)
                                SetEntityRotation(veh, 0.0, 0.0, sRotZ)
                                SetVehicleModColor_1(veh, 1, colCfg.primary, 0)
                                SetVehicleModColor_2(veh, 1, colCfg.secondary)
                                SetVehicleColours(veh, colCfg.primary, colCfg.secondary)
                                SetVehicleDashboardColor(veh, colCfg.interior)
                                SetVehicleInteriorColor(veh, GetRailingColour(yachtData.railing.railingid))
                                SetVehicleEngineOn(veh, false, true, true)
                                SetVehicleUndriveable(veh, true)
                                SetObjectTextureVariant(veh, colCfg.overlay)
                                SetEntityAsMissionEntity(veh, true, true)
                                NetworkAllowLocalEntityAttachment(veh, true)
                                SetEntityLodDist(veh, 1000)
                                SetEntityVisible(veh, true)
                            end
                        end

                        local vehicle = yachtData.yachtmainobject
                        if DoesEntityExist(vehicle) then

                        for _, objData in ipairs(yachtData.mainobjects) do
                            if DoesEntityExist(objData.handler) then
                                AttachEntityToEntity(objData.handler, vehicle, 0,
                                    objData.offsetcoords.x, objData.offsetcoords.y, objData.offsetcoords.z,
                                    objData.offsetrotation.x, objData.offsetrotation.y, objData.offsetrotation.z,
                                    false, false, true, false, 5, true)
                                DetachEntity(objData.handler)
                                FreezeEntityPosition(objData.handler, true)
                            elseif not objData.spawning then
                                objData.spawning = true
                                local h = GetHashKey(objData.objectname)
                                RequestModel(h)
                                while not HasModelLoaded(h) do RequestModel(h) Citizen.Wait(5) end
                                local obj
                                if objData.objectname == "as_apa_mp_apa_yacht_option3" then
                                    obj = CreateVehicle(h, sCoords.x, sCoords.y, sCoords.z, 0.0, false, true)
                                    SetVehicleDoorsLocked(obj, 9)
                                    FreezeEntityPosition(obj, true)
                                    SetEntityRotation(obj, 0.0, 0.0, 0.0)
                                    SetVehicleModColor_1(obj, 1, colCfg.primary, 0)
                                    SetVehicleModColor_2(obj, 1, colCfg.secondary)
                                    SetVehicleColours(obj, colCfg.primary, colCfg.secondary)
                                    SetVehicleDashboardColor(obj, colCfg.primary)
                                    SetVehicleEngineOn(obj, false, true, true)
                                    SetVehicleUndriveable(obj, true)
                                    SetVehicleInteriorColor(obj, GetRailingColour(yachtData.railing.railingid))
                                else
                                    obj = CreateObjectNoOffset(h, sCoords.x, sCoords.y, sCoords.z, false, true, true)
                                    FreezeEntityPosition(obj, true)
                                    SetEntityRotation(obj, 0.0, 0.0, 0.0)
                                end
                                objData.handler = obj
                                objData.spawning = false
                                FreezeEntityPosition(obj, true)
                                NetworkAllowLocalEntityAttachment(obj, true)
                                SetEntityRotation(obj, 0.0, 0.0, 0.0)
                                SetObjectTextureVariant(obj, colCfg.overlay)
                                SetEntityLodDist(obj, 1000)
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
                            DetachEntity(yachtData.flagdata.handler)
                            FreezeEntityPosition(yachtData.flagdata.handler, true)
                        elseif not yachtData.flagdata.spawning then
                            yachtData.flagdata.spawning = true
                            local h = GetHashKey(flagObjectsList[yachtData.flagdata.flagid].flagobject)
                            RequestModel(h)
                            while not HasModelLoaded(h) do RequestModel(h) Citizen.Wait(5) end
                            local obj = CreateObjectNoOffset(h, sCoords.x, sCoords.y, sCoords.z, false, true, true)
                            yachtData.flagdata.handler = obj
                            yachtData.flagdata.spawning = false
                            FreezeEntityPosition(obj, true)
                            NetworkAllowLocalEntityAttachment(obj, true)
                            SetEntityRotation(obj, 0.0, 0.0, 0.0)
                            SetObjectTextureVariant(obj, colCfg.overlay)
                            SetEntityLodDist(obj, 1000)
                            AttachEntityToEntity(obj, vehicle, 0, -0.05, -56.55, 7.4, 230.0, -180.0, 0.0, false, false, true, false, 5, true)
                            DetachEntity(obj)
                            FreezeEntityPosition(obj, true)
                        end

                        if DoesEntityExist(yachtData.lighting.handler) then
                            AttachEntityToEntity(yachtData.lighting.handler, vehicle, 0,
                                yachtData.lighting.coords.x - 2.05, yachtData.lighting.coords.y, yachtData.lighting.coords.z + 5.8,
                                yachtData.lighting.rotation.x, yachtData.lighting.rotation.y, yachtData.lighting.rotation.z + 90.0,
                                false, false, false, false, 5, true)
                            DetachEntity(yachtData.lighting.handler)
                            FreezeEntityPosition(yachtData.lighting.handler, true)
                        elseif not yachtData.lighting.spawning and YachtLightsWanted(yachtData.yachtiddata) then
                            yachtData.lighting.spawning = true
                            local h = GetHashKey(GetLightColorObject(yachtData.lighting.lightingcategory, yachtData.lighting.lightingid))
                            RequestModel(h)
                            while not HasModelLoaded(h) do RequestModel(h) Citizen.Wait(5) end
                            local obj = CreateObjectNoOffset(h, sCoords.x, sCoords.y, sCoords.z, false, true, true)
                            yachtData.lighting.handler = obj
                            yachtData.lighting.spawning = false
                            FreezeEntityPosition(obj, true)
                            NetworkAllowLocalEntityAttachment(obj, true)
                            SetEntityRotation(obj, 0.0, 0.0, 0.0)
                            SetObjectTextureVariant(obj, colCfg.overlay)
                            SetEntityLodDist(obj, 1000)
                            AttachEntityToEntity(obj, vehicle, 0,
                                yachtData.lighting.coords.x - 2.05, yachtData.lighting.coords.y, yachtData.lighting.coords.z + 5.8,
                                yachtData.lighting.rotation.x, yachtData.lighting.rotation.y, yachtData.lighting.rotation.z + 90.0,
                                false, false, false, false, 5, true)
                            DetachEntity(obj)
                            FreezeEntityPosition(obj, true)
                        end

                        local rBase = anchorRailingTypesList[yachtData.railing.railingid].railingobject
                        local rOffX = yachtData.railing.coords.x - 2.0
                        local rOffY = yachtData.railing.coords.y
                        local rOffZ = yachtData.railing.coords.z + 5.8
                        local rRotX = yachtData.railing.rotation.x
                        local rRotY = yachtData.railing.rotation.y
                        local rRotZ = yachtData.railing.rotation.z + 90.0

                        for _, tbl in ipairs({{field="handler2", suffix=""}, {field="handler3", suffix="_down"}}) do
                            local fld = tbl.field
                            if DoesEntityExist(yachtData.railing[fld]) then
                                AttachEntityToEntity(yachtData.railing[fld], vehicle, 0,
                                    rOffX, rOffY, rOffZ, rRotX, rRotY, rRotZ, false, false, false, false, 5, true)
                                DetachEntity(yachtData.railing[fld])
                                FreezeEntityPosition(yachtData.railing[fld], true)
                            elseif not yachtData.railing["spawning_" .. fld] then
                                yachtData.railing["spawning_" .. fld] = true
                                local h = GetHashKey(rBase .. tbl.suffix)
                                RequestModel(h)
                                while not HasModelLoaded(h) do RequestModel(h) Citizen.Wait(5) end
                                local obj = CreateObjectNoOffset(h, sCoords.x, sCoords.y, sCoords.z, false, true, true)
                                yachtData.railing[fld] = obj
                                yachtData.railing["spawning_" .. fld] = false
                                FreezeEntityPosition(obj, true)
                                NetworkAllowLocalEntityAttachment(obj, true)
                                SetEntityRotation(obj, 0.0, 0.0, 0.0)
                                SetObjectTextureVariant(obj, colCfg.overlay)
                                SetEntityLodDist(obj, 1000)
                                SetEntityVisible(obj, false)
                                AttachEntityToEntity(obj, vehicle, 0,
                                    rOffX, rOffY, rOffZ, rRotX, rRotY, rRotZ, false, false, false, false, 5, true)
                                DetachEntity(obj)
                                FreezeEntityPosition(obj, true)
                            end
                        end
                        if DoesEntityExist(yachtData.railing.handler2) then SetEntityVisible(yachtData.railing.handler2, false) end
                        if DoesEntityExist(yachtData.railing.handler3) then SetEntityVisible(yachtData.railing.handler3, true) end

                        for _, door in ipairs(yachtData.doors) do
                            local rot = door.opened and door.rotationopened or door.rotation
                            if DoesEntityExist(door.handler) then
                                AttachEntityToEntity(door.handler, vehicle, 0,
                                    door.coords.x, door.coords.y, door.coords.z,
                                    rot.x, rot.y, rot.z, false, false, true, false, 5, true)
                            elseif not door.spawning then
                                door.spawning = true
                                local h = GetHashKey(door.objectname)
                                RequestModel(h)
                                while not HasModelLoaded(h) do RequestModel(h) Citizen.Wait(5) end
                                local obj = CreateObjectNoOffset(h, sCoords.x, sCoords.y, sCoords.z, false, true, true)
                                door.handler = obj
                                door.spawning = false
                                FreezeEntityPosition(obj, true)
                                NetworkAllowLocalEntityAttachment(obj, true)
                                SetEntityRotation(obj, 0.0, 0.0, 0.0)
                                SetObjectTextureVariant(obj, colCfg.overlay)
                                SetEntityLodDist(obj, 1000)
                                AttachEntityToEntity(obj, vehicle, 0,
                                    door.coords.x, door.coords.y, door.coords.z,
                                    rot.x, rot.y, rot.z, false, false, true, false, 5, true)
                            end
                            if DoesEntityExist(door.handler) then
                                DetachEntity(door.handler)
                                FreezeEntityPosition(door.handler, true)
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
                                    local retries = 0
                                    RequestModel(h)
                                    while not HasModelLoaded(h) and retries < 100 do
                                        RequestModel(h)
                                        Citizen.Wait(5)
                                        retries = retries + 1
                                    end
                                    if retries >= 99 then
                                        print("AS Yacht - Load Failed - " .. furnitureEntry.furnituremodel)
                                        furnitureEntry.spawning = false
                                    else
                                        local obj = CreateObjectNoOffset(h, sCoords.x, sCoords.y, sCoords.z, false, true, true)
                                        furnitureEntry.handler = obj
                                        furnitureEntry.spawning = false
                                        if furnitureEntry.removeinprogress then
                                            DeleteEntity(obj)
                                        else
                                            FreezeEntityPosition(obj, true)
                                            NetworkAllowLocalEntityAttachment(obj, true)
                                            SetEntityRotation(obj, 0.0, 0.0, 0.0)
                                            SetEntityAlwaysPrerender(obj, true)
                                            SetEntityMotionBlur(obj, false)
                                            SetObjectTextureVariant(obj, colCfg.overlay)
                                            SetEntityLodDist(obj, 1000)
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
                        end

                        end 

                        end 

                    else
                        
                        local vehNetId = GlobalState["asyacht-" .. yachtData.yachtiddata .. "-vehid"]
                        if vehNetId and NetworkDoesNetworkIdExist(vehNetId) then
                            local driveVeh = NetToVeh(vehNetId)
                            if DoesEntityExist(driveVeh) and GetEntityModel(driveVeh) == yachtModelHash then
                                
                                SetVehicleModColor_1(driveVeh, 1, colCfg.primary, 0)
                                SetVehicleModColor_2(driveVeh, 1, colCfg.secondary)
                                SetVehicleColours(driveVeh, colCfg.primary, colCfg.secondary)
                                SetVehicleDashboardColor(driveVeh, colCfg.interior)
                                SetVehicleInteriorColor(driveVeh, GetRailingColour(yachtData.railing.railingid))

                                if not DoesEntityExist(yachtData.yachtmainobject) and not yachtData.hullspawning then
                                    yachtData.hullspawning = true
                                    RequestModel(yachtModelHash)
                                    while not HasModelLoaded(yachtModelHash) do RequestModel(yachtModelHash) Citizen.Wait(5) end
                                    local hasWater, waterZ = GetWaterHeightNoWaves(stateCoords.x, stateCoords.y, -4.0)
                                    local spawnZ = -4.0 + (hasWater and waterZ or 0)
                                    local veh = CreateVehicle(yachtModelHash, stateCoords.x, stateCoords.y, spawnZ, 0.0, false, true)
                                    yachtData.yachtmainobject = veh
                                    yachtData.hullspawning = false
                                    SetVehicleDoorsLocked(veh, 9)
                                    SetEntityRotation(veh, 0.0, 0.0, GlobalState["asyacht-" .. yachtData.yachtiddata .. "-rotation"].z)
                                    SetVehicleModColor_1(veh, 1, colCfg.primary, 0)
                                    SetVehicleModColor_2(veh, 1, colCfg.secondary)
                                    SetVehicleColours(veh, colCfg.primary, colCfg.secondary)
                                    SetVehicleDashboardColor(veh, colCfg.interior)
                                    SetVehicleInteriorColor(veh, GetRailingColour(yachtData.railing.railingid))
                                    SetObjectTextureVariant(veh, colCfg.overlay)
                                    SetEntityAsMissionEntity(veh, true, true)
                                    FreezeEntityPosition(veh, true)
                                    NetworkAllowLocalEntityAttachment(veh, true)
                                    SetEntityLodDist(veh, 1000)
                                end
                                if DoesEntityExist(yachtData.yachtmainobject) then
                                if yachtIntroPlayed[yachtData.yachtiddata] then
                                    CreatePersonalYachtBlip(yachtData.yachtiddata)
                                end
                                SetEntityNoCollisionEntity(yachtData.yachtmainobject, driveVeh, true)
                                AttachEntityToEntity(yachtData.yachtmainobject, driveVeh, 0,
                                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 5, true)
                                SetEntityVisible(yachtData.yachtmainobject, true)
                                local vehicle = yachtData.yachtmainobject

                                for _, objData in ipairs(yachtData.mainobjects) do
                                    if DoesEntityExist(objData.handler) then
                                        AttachEntityToEntity(objData.handler, vehicle, 0,
                                            objData.offsetcoords.x, objData.offsetcoords.y, objData.offsetcoords.z,
                                            objData.offsetrotation.x, objData.offsetrotation.y, objData.offsetrotation.z,
                                            false, false, false, false, 5, true)
                                    elseif not objData.spawning then
                                        objData.spawning = true
                                        local h = GetHashKey(objData.objectname)
                                        RequestModel(h)
                                        while not HasModelLoaded(h) do RequestModel(h) Citizen.Wait(5) end
                                        local obj
                                        if objData.objectname == "as_apa_mp_apa_yacht_option3" then
                                            local sc = vector3(stateCoords.x, stateCoords.y, stateCoords.z)
                                            obj = CreateVehicle(h, sc.x, sc.y, sc.z, 0.0, false, true)
                                            SetVehicleDoorsLocked(obj, 9)
                                            FreezeEntityPosition(obj, true)
                                            SetEntityRotation(obj, 0.0, 0.0, 0.0)
                                            SetVehicleModColor_1(obj, 1, colCfg.primary, 0)
                                            SetVehicleModColor_2(obj, 1, colCfg.secondary)
                                            SetVehicleColours(obj, colCfg.primary, colCfg.secondary)
                                            SetVehicleDashboardColor(obj, colCfg.primary)
                                            SetVehicleInteriorColor(obj, GetRailingColour(yachtData.railing.railingid))
                                        else
                                            obj = CreateObjectNoOffset(h, stateCoords.x, stateCoords.y, stateCoords.z, false, true, true)
                                            FreezeEntityPosition(obj, true)
                                            SetEntityRotation(obj, 0.0, 0.0, 0.0)
                                        end
                                        objData.handler = obj
                                        objData.spawning = false
                                        FreezeEntityPosition(obj, true)
                                        NetworkAllowLocalEntityAttachment(obj, true)
                                        SetEntityRotation(obj, 0.0, 0.0, 0.0)
                                        SetObjectTextureVariant(obj, colCfg.overlay)
                                        SetEntityLodDist(obj, 1000)
                                        AttachEntityToEntity(obj, vehicle, 0,
                                            objData.offsetcoords.x, objData.offsetcoords.y, objData.offsetcoords.z,
                                            objData.offsetrotation.x, objData.offsetrotation.y, objData.offsetrotation.z,
                                            false, false, false, false, 5, true)
                                    end
                                    if DoesEntityExist(objData.handler) then
                                        SetEntityNoCollisionEntity(objData.handler, driveVeh, true)
                                    end
                                end

                                if DoesEntityExist(yachtData.flagdata.handler) then
                                    AttachEntityToEntity(yachtData.flagdata.handler, vehicle, 0,
                                        -0.05, -56.55, 7.4, 230.0, -180.0, 0.0, false, false, false, false, 5, true)
                                elseif not yachtData.flagdata.spawning then
                                    yachtData.flagdata.spawning = true
                                    local h = GetHashKey(flagObjectsList[yachtData.flagdata.flagid].flagobject)
                                    RequestModel(h)
                                    while not HasModelLoaded(h) do RequestModel(h) Citizen.Wait(5) end
                                    local obj = CreateObjectNoOffset(h, stateCoords.x, stateCoords.y, stateCoords.z, false, true, true)
                                    yachtData.flagdata.handler = obj
                                    yachtData.flagdata.spawning = false
                                    FreezeEntityPosition(obj, true)
                                    NetworkAllowLocalEntityAttachment(obj, true)
                                    SetEntityRotation(obj, 0.0, 0.0, 0.0)
                                    SetObjectTextureVariant(obj, colCfg.overlay)
                                    SetEntityLodDist(obj, 1000)
                                    AttachEntityToEntity(obj, vehicle, 0, -0.05, -56.55, 7.4, 230.0, -180.0, 0.0, false, false, false, false, 5, true)
                                end
                                if DoesEntityExist(yachtData.flagdata.handler) then
                                    SetEntityNoCollisionEntity(yachtData.flagdata.handler, driveVeh, true)
                                end

                                if DoesEntityExist(yachtData.lighting.handler) then
                                    AttachEntityToEntity(yachtData.lighting.handler, vehicle, 0,
                                        yachtData.lighting.coords.x - 2.05, yachtData.lighting.coords.y, yachtData.lighting.coords.z + 5.8,
                                        yachtData.lighting.rotation.x, yachtData.lighting.rotation.y, yachtData.lighting.rotation.z + 90.0,
                                        false, false, false, false, 5, true)
                                elseif not yachtData.lighting.spawning and YachtLightsWanted(yachtData.yachtiddata) then
                                    yachtData.lighting.spawning = true
                                    local h = GetHashKey(GetLightColorObject(yachtData.lighting.lightingcategory, yachtData.lighting.lightingid))
                                    RequestModel(h)
                                    while not HasModelLoaded(h) do RequestModel(h) Citizen.Wait(5) end
                                    local obj = CreateObjectNoOffset(h, stateCoords.x, stateCoords.y, stateCoords.z, false, true, true)
                                    yachtData.lighting.handler = obj
                                    yachtData.lighting.spawning = false
                                    FreezeEntityPosition(obj, true)
                                    NetworkAllowLocalEntityAttachment(obj, true)
                                    SetEntityRotation(obj, 0.0, 0.0, 0.0)
                                    SetObjectTextureVariant(obj, colCfg.overlay)
                                    SetEntityLodDist(obj, 1000)
                                    AttachEntityToEntity(obj, vehicle, 0,
                                        yachtData.lighting.coords.x - 2.05, yachtData.lighting.coords.y, yachtData.lighting.coords.z + 5.8,
                                        yachtData.lighting.rotation.x, yachtData.lighting.rotation.y, yachtData.lighting.rotation.z + 90.0,
                                        false, false, false, false, 5, true)
                                end
                                if DoesEntityExist(yachtData.lighting.handler) then
                                    SetEntityNoCollisionEntity(yachtData.lighting.handler, driveVeh, true)
                                end

                                local rBase = anchorRailingTypesList[yachtData.railing.railingid].railingobject
                                local rOffX = yachtData.railing.coords.x - 2.0
                                local rOffY = yachtData.railing.coords.y
                                local rOffZ = yachtData.railing.coords.z + 5.8
                                local rRotX = yachtData.railing.rotation.x
                                local rRotY = yachtData.railing.rotation.y
                                local rRotZ = yachtData.railing.rotation.z + 90.0

                                for _, tbl in ipairs({{field="handler2", suffix=""}, {field="handler3", suffix="_down"}}) do
                                    local fld = tbl.field
                                    if DoesEntityExist(yachtData.railing[fld]) then
                                        AttachEntityToEntity(yachtData.railing[fld], vehicle, 0,
                                            rOffX, rOffY, rOffZ, rRotX, rRotY, rRotZ, false, false, false, false, 5, true)
                                    elseif not yachtData.railing["spawning_" .. fld] then
                                        yachtData.railing["spawning_" .. fld] = true
                                        local h = GetHashKey(rBase .. tbl.suffix)
                                        RequestModel(h)
                                        while not HasModelLoaded(h) do RequestModel(h) Citizen.Wait(5) end
                                        local obj = CreateObjectNoOffset(h, stateCoords.x, stateCoords.y, stateCoords.z, false, true, true)
                                        yachtData.railing[fld] = obj
                                        yachtData.railing["spawning_" .. fld] = false
                                        FreezeEntityPosition(obj, true)
                                        NetworkAllowLocalEntityAttachment(obj, true)
                                        SetEntityRotation(obj, 0.0, 0.0, 0.0)
                                        SetObjectTextureVariant(obj, colCfg.overlay)
                                        SetEntityLodDist(obj, 1000)
                                        SetEntityVisible(obj, false)
                                        AttachEntityToEntity(obj, vehicle, 0,
                                            rOffX, rOffY, rOffZ, rRotX, rRotY, rRotZ, false, false, false, false, 5, true)
                                    end
                                    if DoesEntityExist(yachtData.railing[fld]) then
                                        SetEntityNoCollisionEntity(yachtData.railing[fld], driveVeh, true)
                                    end
                                end
                                if DoesEntityExist(yachtData.railing.handler2) then SetEntityVisible(yachtData.railing.handler2, true) end
                                if DoesEntityExist(yachtData.railing.handler3) then SetEntityVisible(yachtData.railing.handler3, false) end

                                for _, door in ipairs(yachtData.doors) do
                                    local rot = door.opened and door.rotationopened or door.rotation
                                    if DoesEntityExist(door.handler) then
                                        AttachEntityToEntity(door.handler, vehicle, 0,
                                            door.coords.x, door.coords.y, door.coords.z,
                                            rot.x, rot.y, rot.z, false, false, false, false, 5, true)
                                    elseif not door.spawning then
                                        door.spawning = true
                                        local h = GetHashKey(door.objectname)
                                        RequestModel(h)
                                        while not HasModelLoaded(h) do RequestModel(h) Citizen.Wait(5) end
                                        local obj = CreateObjectNoOffset(h, stateCoords.x, stateCoords.y, stateCoords.z, false, true, true)
                                        door.handler = obj
                                        door.spawning = false
                                        FreezeEntityPosition(obj, true)
                                        NetworkAllowLocalEntityAttachment(obj, true)
                                        SetEntityRotation(obj, 0.0, 0.0, 0.0)
                                        SetObjectTextureVariant(obj, colCfg.overlay)
                                        SetEntityLodDist(obj, 1000)
                                        AttachEntityToEntity(obj, vehicle, 0,
                                            door.coords.x, door.coords.y, door.coords.z,
                                            rot.x, rot.y, rot.z, false, false, false, false, 5, true)
                                    end
                                    if DoesEntityExist(door.handler) then
                                        SetEntityNoCollisionEntity(door.handler, driveVeh, true)
                                    end
                                end

                                for _, furnitureEntry in pairs(yachtData.furnitureobjects) do
                                    if not furnitureEntry.removeinprogress and not furnitureEntry.editing then
                                        if DoesEntityExist(furnitureEntry.handler) then
                                            AttachEntityToEntity(furnitureEntry.handler, vehicle, 0,
                                                furnitureEntry.furniturecoords.x, furnitureEntry.furniturecoords.y, furnitureEntry.furniturecoords.z,
                                                furnitureEntry.furniturerotation.x, furnitureEntry.furniturerotation.y, furnitureEntry.furniturerotation.z,
                                                false, false, false, false, 2, true)
                                        elseif not furnitureEntry.spawning then
                                            furnitureEntry.spawning = true
                                            local h = GetHashKey(furnitureEntry.furnituremodel)
                                            local retries = 0
                                            RequestModel(h)
                                            while not HasModelLoaded(h) and retries < 100 do
                                                RequestModel(h)
                                                Citizen.Wait(5)
                                                retries = retries + 1
                                            end
                                            if retries >= 99 then
                                                print("AS Yacht - Load Failed - " .. furnitureEntry.furnituremodel)
                                                furnitureEntry.spawning = false
                                            else
                                                local obj = CreateObjectNoOffset(h, stateCoords.x, stateCoords.y, stateCoords.z, false, true, true)
                                                furnitureEntry.handler = obj
                                                furnitureEntry.spawning = false
                                                if furnitureEntry.removeinprogress then
                                                    DeleteEntity(obj)
                                                else
                                                    FreezeEntityPosition(obj, true)
                                                    NetworkAllowLocalEntityAttachment(obj, true)
                                                    SetEntityRotation(obj, 0.0, 0.0, 0.0)
                                                    SetObjectTextureVariant(obj, colCfg.overlay)
                                                    SetEntityLodDist(obj, 1000)
                                                    AttachEntityToEntity(obj, vehicle, 0,
                                                        furnitureEntry.furniturecoords.x, furnitureEntry.furniturecoords.y, furnitureEntry.furniturecoords.z,
                                                        furnitureEntry.furniturerotation.x, furnitureEntry.furniturerotation.y, furnitureEntry.furniturerotation.z,
                                                        false, false, false, false, 2, true)
                                                end
                                            end
                                        end
                                        if DoesEntityExist(furnitureEntry.handler) then
                                            SetEntityNoCollisionEntity(furnitureEntry.handler, driveVeh, true)
                                        end
                                    end
                                end

                                end 
                            end
                        end
                    end
                end
            end
            end)
            if not ok then
                print(("^1AS Yacht^7: per-yacht sync error (yacht %s): %s"):format(tostring(yachtData and yachtData.yachtiddata), tostring(syncErr)))
            end
        end

        if nearestId then
            currentNearYachtId = nearestId
            if Config.YachtNoRagdoll then SetPedCanRagdoll(playerPed, false) end
        else
            if currentNearYachtId ~= nil and Config.YachtNoRagdoll then
                SetPedCanRagdoll(playerPed, true)
            end
            currentNearYachtId = nil
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        local closestDist    = -1
        local foundDoor      = false
        local nearestDoorIdx = nil
        local nearestDoorPos = vector3(0, 0, 0)
        local showFadeOut    = false

        local playerPed    = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        if currentNearYachtId ~= nil then
            local yachtData = yachts["yacht-" .. currentNearYachtId]
            if yachtData and not yachtData.removeinprogress and not drivingState.driving
            and DoesEntityExist(yachtData.yachtmainobject) then
                if InSomeMenu() then
                    local yachtCoords = GetEntityCoords(yachtData.yachtmainobject)
                    local yachtRot    = GetEntityRotation(yachtData.yachtmainobject, 2)

                    for i, door in ipairs(yachtData.doors) do
                        
                        local localCoords = (door.special and door.opencoords) or door.coords
                        local rad         = math.rad(yachtRot.z)
                        local cosZ, sinZ  = math.cos(rad), math.sin(rad)
                        local wx = localCoords.x * cosZ - localCoords.y * sinZ + yachtCoords.x
                        local wy = localCoords.y * cosZ + localCoords.x * sinZ + yachtCoords.y
                        local wz = localCoords.z + yachtCoords.z
                        local doorWorldPos = vector3(wx, wy, wz)
                        local dist = #(playerCoords - doorWorldPos)

                        if dist < Config.YachtDoorDistance and (closestDist == -1 or dist < closestDist) then
                            closestDist    = dist
                            foundDoor      = true
                            nearestDoorIdx = i
                            nearestDoorPos = doorWorldPos
                        end
                    end
                end
            end
        end

        if foundDoor and currentNearYachtId ~= nil then
            currentNearDoorIndex = nearestDoorIdx
            local nearYachtData  = yachts["yacht-" .. currentNearYachtId]
            local yachtDoors     = nearYachtData and nearYachtData.doors or nil
            local door           = yachtDoors and yachtDoors[nearestDoorIdx] or nil
            if door then
                local lang           = Lang
                local interactSystem = Config.YachtInteractionSystem

                if not door.opened then
                    if interactSystem == 1 then
                        SendNUIMessage({message="infonotifyshow", infonotifytext=lang.pressforopenyachtinteract})
                    elseif interactSystem == 2 then
                        DrawText3D(nearestDoorPos.x, nearestDoorPos.y, nearestDoorPos.z, lang.pressforopenyacht)
                    elseif interactSystem == 3 then
                        ShowGtaClassicInteraction(lang.pressforopenyachtinteractclassic)
                    end
                else
                    if interactSystem == 1 then
                        SendNUIMessage({message="infonotifyshow", infonotifytext=lang.pressforcloseyachtinteract})
                    elseif interactSystem == 2 then
                        DrawText3D(nearestDoorPos.x, nearestDoorPos.y, nearestDoorPos.z, lang.pressforcloseyacht)
                    elseif interactSystem == 3 then
                        ShowGtaClassicInteraction(lang.pressforcloseyachtinteractclassic)
                    end
                end

                if showFadeOut then
                    Citizen.Wait(1000)
                end
            end
        else
            if currentNearYachtId ~= nil and currentNearDoorIndex ~= nil then
                if Config.YachtInteractionSystem == 1 then
                    SendNUIMessage({message="hide"})
                end
            end
            currentNearDoorIndex = nil
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        local playerPed    = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local found        = false
        local foundIdx     = nil
        local foundPos     = nil

        if currentNearYachtId ~= nil and not drivingState.driving then
            local yachtData = yachts["yacht-" .. currentNearYachtId]
            if yachtData and not yachtData.removeinprogress and DoesEntityExist(yachtData.yachtmainobject) then
                if InSomeMenu() then
                    local yachtCoords = GetEntityCoords(yachtData.yachtmainobject)
                    local yachtRot    = GetEntityRotation(yachtData.yachtmainobject, 2)

                    for i, storageCfg in ipairs(Config.YachtStorageLocations) do
                        local rad         = math.rad(yachtRot.z)
                        local cosZ, sinZ  = math.cos(rad), math.sin(rad)
                        local wx = storageCfg.coords.x * cosZ - storageCfg.coords.y * sinZ + yachtCoords.x
                        local wy = storageCfg.coords.y * cosZ + storageCfg.coords.x * sinZ + yachtCoords.y
                        local wz = storageCfg.coords.z + yachtCoords.z
                        local dist = #(playerCoords - vector3(wx, wy, wz))

                        if dist < storageCfg.distance then
                            found    = true
                            foundIdx = i
                            foundPos = vector3(wx, wy, wz)
                            break
                        end
                    end
                end
            end
        end

        if found then
            currentNearStorageIndex = foundIdx
            local lang = Lang
            if Config.YachtInteractionSystem == 1 then
                SendNUIMessage({message="infonotifyshow", infonotifytext=lang.pressforstorageyachtinteract})
            elseif Config.YachtInteractionSystem == 2 then
                DrawText3D(foundPos.x, foundPos.y, foundPos.z, lang.pressforstorage)
            elseif Config.YachtInteractionSystem == 3 then
                ShowGtaClassicInteraction(lang.pressforstorageyachtinteractclassic)
            end
        else
            if currentNearYachtId ~= nil and currentNearStorageIndex ~= nil then
                if Config.YachtInteractionSystem == 1 then
                    SendNUIMessage({message="hide"})
                end
            end
            currentNearStorageIndex = nil
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        local playerPed    = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local found        = false
        local foundIdx     = nil
        local foundPos     = nil

        if currentNearYachtId ~= nil and not drivingState.driving then
            local yachtData = yachts["yacht-" .. currentNearYachtId]
            if yachtData and not yachtData.removeinprogress and DoesEntityExist(yachtData.yachtmainobject) then
                if InSomeMenu() then
                    local yachtCoords = GetEntityCoords(yachtData.yachtmainobject)
                    local yachtRot    = GetEntityRotation(yachtData.yachtmainobject, 2)

                    for i, wardrobeCfg in ipairs(Config.YachtWardrobeLocations) do
                        local rad         = math.rad(yachtRot.z)
                        local cosZ, sinZ  = math.cos(rad), math.sin(rad)
                        local wx = wardrobeCfg.coords.x * cosZ - wardrobeCfg.coords.y * sinZ + yachtCoords.x
                        local wy = wardrobeCfg.coords.y * cosZ + wardrobeCfg.coords.x * sinZ + yachtCoords.y
                        local wz = wardrobeCfg.coords.z + yachtCoords.z
                        local dist = #(playerCoords - vector3(wx, wy, wz))

                        if dist < wardrobeCfg.distance then
                            found    = true
                            foundIdx = i
                            foundPos = vector3(wx, wy, wz)
                            break
                        end
                    end
                end
            end
        end

        if found then
            currentNearWardrobeIndex = foundIdx
            local lang = Lang
            if Config.YachtInteractionSystem == 1 then
                SendNUIMessage({message="infonotifyshow", infonotifytext=lang.pressforwardrobeyachtinteract})
            elseif Config.YachtInteractionSystem == 2 then
                DrawText3D(foundPos.x, foundPos.y, foundPos.z, lang.pressforwardrobe)
            elseif Config.YachtInteractionSystem == 3 then
                ShowGtaClassicInteraction(lang.pressforwardrobeyachtinteractclassic)
            end
        else
            if currentNearYachtId ~= nil and currentNearWardrobeIndex ~= nil then
                if Config.YachtInteractionSystem == 1 then
                    SendNUIMessage({message="hide"})
                end
            end
            currentNearWardrobeIndex = nil
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        local playerPed    = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local found        = false
        local foundPos     = nil

        if currentNearYachtId ~= nil and not drivingState.driving then
            local yachtData = yachts["yacht-" .. currentNearYachtId]
            if yachtData and not yachtData.removeinprogress and DoesEntityExist(yachtData.yachtmainobject) then
                if InSomeMenu() then
                    local yachtCoords = GetEntityCoords(yachtData.yachtmainobject)
                    local yachtRot    = GetEntityRotation(yachtData.yachtmainobject, 2)
                    local manageCfg   = Config.YachtManageLocation

                    local rad         = math.rad(yachtRot.z)
                    local cosZ, sinZ  = math.cos(rad), math.sin(rad)
                    local wx = manageCfg.coords.x * cosZ - manageCfg.coords.y * sinZ + yachtCoords.x
                    local wy = manageCfg.coords.y * cosZ + manageCfg.coords.x * sinZ + yachtCoords.y
                    local wz = manageCfg.coords.z + yachtCoords.z
                    local dist = #(playerCoords - vector3(wx, wy, wz))

                    if dist < manageCfg.distance then
                        found    = true
                        foundPos = vector3(wx, wy, wz)
                        currentNearManageZoneId = currentNearYachtId
                    end
                end
            end
        end

        if found then
            local lang = Lang
            if Config.YachtInteractionSystem == 1 then
                SendNUIMessage({message="infonotifyshow", infonotifytext=lang.pressformanagmentyachtinteract})
            elseif Config.YachtInteractionSystem == 2 then
                DrawText3D(foundPos.x, foundPos.y, foundPos.z, lang.pressformanagment)
            elseif Config.YachtInteractionSystem == 3 then
                ShowGtaClassicInteraction(lang.pressformanagmentyachtinteractclassic)
            end
        else
            if currentNearYachtId ~= nil and currentNearManageZoneId ~= nil then
                if Config.YachtInteractionSystem == 1 then
                    SendNUIMessage({message="hide"})
                end
            end
            currentNearManageZoneId = nil
        end
    end
end)

if not Config.DisableYachtDrive then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)

            local playerPed    = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local found        = false
            local foundPos     = nil

            if currentNearYachtId ~= nil and not drivingState.driving then
                local yachtData = yachts["yacht-" .. currentNearYachtId]
                if yachtData and not yachtData.removeinprogress and DoesEntityExist(yachtData.yachtmainobject) then
                    
                    if GlobalState["asyacht-" .. currentNearYachtId .. "-anchored"] == true then
                        if InSomeMenu() then
                            local yachtCoords = GetEntityCoords(yachtData.yachtmainobject)
                            local yachtRot    = GetEntityRotation(yachtData.yachtmainobject, 2)
                            local driveCfg    = Config.YachtDriveLocation

                            local rad         = math.rad(yachtRot.z)
                            local cosZ, sinZ  = math.cos(rad), math.sin(rad)
                            local wx = driveCfg.coords.x * cosZ - driveCfg.coords.y * sinZ + yachtCoords.x
                            local wy = driveCfg.coords.y * cosZ + driveCfg.coords.x * sinZ + yachtCoords.y
                            local wz = driveCfg.coords.z + yachtCoords.z
                            local dist = #(playerCoords - vector3(wx, wy, wz))

                            if dist < driveCfg.distance then
                                found    = true
                                foundPos = vector3(wx, wy, wz)
                                currentNearDriveZoneId = currentNearYachtId
                            end
                        end
                    end
                end
            end

            if found then
                local lang = Lang
                if Config.YachtInteractionSystem == 1 then
                    SendNUIMessage({message="infonotifyshow", infonotifytext=lang.pressfordriveyachtinteract})
                elseif Config.YachtInteractionSystem == 2 then
                    DrawText3D(foundPos.x, foundPos.y, foundPos.z, lang.pressfordrive)
                elseif Config.YachtInteractionSystem == 3 then
                    ShowGtaClassicInteraction(lang.pressfordriveyachtinteractclassic)
                end
            else
                if currentNearYachtId ~= nil and currentNearDriveZoneId ~= nil then
                    if Config.YachtInteractionSystem == 1 then
                        SendNUIMessage({message="hide"})
                    end
                end
                currentNearDriveZoneId = nil
            end
        end
    end)
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if currentNearYachtId ~= nil then
            local yachtData = yachts["yacht-" .. currentNearYachtId]
            if yachtData then
                DrawYachtName(yachtData.textdata.uppertext, yachtData.textdata.bottomtext, currentNearYachtId)
            end
        else
            Citizen.Wait(1000)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        local playerPed    = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local found        = false
        local foundIdx     = nil
        local foundPos     = nil
        local closestDist  = -1

        if currentNearYachtId ~= nil and not drivingState.driving and not isPlayerSeated then
            local yachtData = yachts["yacht-" .. currentNearYachtId]
            if yachtData and not yachtData.removeinprogress and DoesEntityExist(yachtData.yachtmainobject) then
                if InSomeMenu() then
                    local yachtCoords = GetEntityCoords(yachtData.yachtmainobject)
                    local yachtRot    = GetEntityRotation(yachtData.yachtmainobject, 2)

                    local rad        = math.rad(yachtRot.z)
                    local cosZ, sinZ = math.cos(rad), math.sin(rad)

                    for seatId, seat in pairs(yachtData.hottubseats) do
                        local off = seat.offsets.coords
                        local worldX = (off.x * cosZ) - (off.y * sinZ) + yachtCoords.x
                        local worldY = (off.y * cosZ) + (off.x * sinZ) + yachtCoords.y
                        local worldZ = off.z + yachtCoords.z
                        local worldPos = vector3(worldX, worldY, worldZ)
                        local dist = #(playerCoords - worldPos)

                        if dist < Config.HottubSeatDistance and (closestDist == -1 or closestDist > dist) then
                            closestDist = dist
                            found       = true
                            foundIdx    = seatId
                            foundPos    = worldPos
                        end
                    end
                end
            end
        end

        if found then
            currentNearHottubIndex = foundIdx
            local lang = Lang
            if Config.YachtInteractionSystem == 1 then
                SendNUIMessage({message="infonotifyshow", infonotifytext=lang.pressforhottubseatinteract})
            elseif Config.YachtInteractionSystem == 2 then
                DrawText3D(foundPos.x, foundPos.y, foundPos.z, lang.pressforhottubseat)
            elseif Config.YachtInteractionSystem == 3 then
                ShowGtaClassicInteraction(lang.pressforhottubseatinteractclassic)
            end
        else
            if currentNearHottubIndex ~= nil then
                if Config.YachtInteractionSystem == 1 then
                    SendNUIMessage({message="hide"})
                end
            end
            currentNearHottubIndex = nil
        end
    end
end)

if not Config.DisableYachtBuy then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)

            local playerPed    = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local buyCfg       = Config.YachtBuyLocation
            local dist         = #(playerCoords - buyCfg.coords)
            local drawNeeded   = true

            if dist < buyCfg.distance then
                isPlayerNearBuyLocation = true
            else
                isPlayerNearBuyLocation = false
            end

            if dist < 25.0 then
                drawNeeded = false
            end

            if not Config.Target then
                if isPlayerNearBuyLocation and not isYachtBuyMenuOpen then
                    local lang = Lang
                    if Config.YachtInteractionSystem == 1 then
                        SendNUIMessage({message="infonotifyshow", infonotifytext=lang.pressforbuyyachtinteract})
                    elseif Config.YachtInteractionSystem == 2 then
                        DrawText3D(buyCfg.coords.x, buyCfg.coords.y, buyCfg.coords.z, lang.pressforbuyyacht)
                    elseif Config.YachtInteractionSystem == 3 then
                        ShowGtaClassicInteraction(lang.pressforbuyyachtinteractclassic)
                    end
                elseif not isPlayerNearBuyLocation then
                    if Config.YachtInteractionSystem == 1 and not isYachtBuyMenuOpen then
                        SendNUIMessage({message="hide"})
                    end
                end
            end

            if drawNeeded then
                Citizen.Wait(500)
            end
        end
    end)
end

furniturePlacementEntity    = nil

isFurniturePlacing           = false

furniturePlacementKey        = nil

furniturePlacementCategoryId = nil
furniturePlacementItemId     = nil
furniturePlacementCoords     = nil
furniturePlacementRotation   = nil

Citizen.CreateThread(function()
    while true do
        Wait(0)
        if DoesEntityExist(furniturePlacementEntity) then
            if (isGizmoActive or isFurniturePlacing) and furnitureMenuYachtId ~= nil then
                local camPos = GetFinalRenderedCamCoord()
                local camRot = GetFinalRenderedCamRot()
                SendNUIMessage({action="setCameraPosition", data={position=camPos, rotation=camRot}})
            end
        else
            Wait(1000)
        end
    end
end)
