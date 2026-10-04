-- as-yacht client/furniture.lua: Furniture editor, gizmo and noclip camera.
-- (Split from the former client/main.lua. File-level state is global so every client module shares it.)

RegisterNUICallback("furniturebuyobject", function(data, cb)
    if not isFurniturePlacing then cb(1) return end
    if not isFurnitureMenuOpen then cb(1) return end
    if isFurniturePlacementActive then cb(1) return end  
    if furnitureMenuYachtId == nil then cb(1) return end
    if not furniturePlacementCategoryId or not furniturePlacementItemId then cb(1) return end
    if not DoesEntityExist(furniturePlacementEntity) then cb(1) return end

    local yachtData = yachts["yacht-" .. furnitureMenuYachtId]
    if not yachtData or not DoesEntityExist(yachtData.yachtmainobject) then cb(1) return end

    SendNUIMessage({message = "hideobjecteditor"})
    SendNUIMessage({action  = "setGizmoEntity", data = {}})

    local storedPos = furniturePlacementCoords or GetEntityCoords(furniturePlacementEntity)
    local relCoords = GetOffsetFromEntityGivenWorldCoords(
        yachtData.yachtmainobject, storedPos.x, storedPos.y, storedPos.z)
    local relRot = GetRotationOffsetBetweenEntities(yachtData.yachtmainobject, furniturePlacementEntity)

    local renderedPos = GetEntityCoords(furniturePlacementEntity)
    local renderedRot = GetEntityRotation(furniturePlacementEntity, 2)
    local selectedItem = Config.Furnitures[furniturePlacementCategoryId]
        and Config.Furnitures[furniturePlacementCategoryId].categoryobjects[furniturePlacementItemId]
    pendingFurniturePurchase = {
        yachtId = furnitureMenuYachtId,
        model = selectedItem and selectedItem.furnitureobject or nil,
        worldCoords = vector3(renderedPos.x, renderedPos.y, renderedPos.z),
        worldRotation = vector3(renderedRot.x, renderedRot.y, renderedRot.z),
        expiresAt = GetGameTimer() + 15000,
    }

    TriggerServerEvent("asyacht:Global:BuyFurniture",
        furnitureMenuYachtId,
        furniturePlacementCategoryId,
        furniturePlacementItemId,
        vector3(relCoords.x, relCoords.y, relCoords.z),
        vector3(relRot.x,    relRot.y,    relRot.z)
    )

    if DoesEntityExist(furniturePlacementEntity) then
        DeleteEntity(furniturePlacementEntity)
    end

    furniturePlacementCategoryId = nil
    furniturePlacementItemId     = nil
    furniturePlacementEntity     = nil
    furniturePlacementCoords     = nil
    furniturePlacementRotation   = nil
    isFurniturePlacing           = false
    cb(1)
end)

RegisterNUICallback("furnituresaveobject", function(data, cb)
    if not isFurniturePlacing then cb(1) return end
    if not isFurnitureMenuOpen then cb(1) return end
    if furnitureMenuYachtId == nil then cb(1) return end
    if not furniturePlacementKey then cb(1) return end
    if not DoesEntityExist(furniturePlacementEntity) then cb(1) return end

    SendNUIMessage({message = "hideobjecteditor"})
    SendNUIMessage({action  = "setGizmoEntity", data = {}})
    GizmoEnd()

    isFurniturePlacing = false

    local yachtData = yachts["yacht-" .. furnitureMenuYachtId]
    if not yachtData or not DoesEntityExist(yachtData.yachtmainobject) then cb(1) return end

    local worldPos  = furniturePlacementCoords or GetEntityCoords(furniturePlacementEntity)
    local relCoords = GetOffsetFromEntityGivenWorldCoords(
        yachtData.yachtmainobject, worldPos.x, worldPos.y, worldPos.z)
    local relRot    = GetRotationOffsetBetweenEntities(yachtData.yachtmainobject, furniturePlacementEntity)

    TriggerServerEvent("asyacht:Global:SaveFurniture",
        furnitureMenuYachtId,
        furniturePlacementKey,
        vector3(relCoords.x, relCoords.y, relCoords.z),
        vector3(relRot.x,    relRot.y,    relRot.z)
    )

    local fe = yachtData.furnitureobjects[furniturePlacementKey]
    if fe then
        fe.furniturecoords   = vector3(relCoords.x, relCoords.y, relCoords.z)
        fe.furniturerotation = vector3(relRot.x,    relRot.y,    relRot.z)
        fe.editing = false
        if DoesEntityExist(fe.handler) then
            AttachEntityToEntity(fe.handler, yachtData.yachtmainobject, 0,
                fe.furniturecoords.x, fe.furniturecoords.y, fe.furniturecoords.z,
                fe.furniturerotation.x, fe.furniturerotation.y, fe.furniturerotation.z,
                false, false, true, false, 2, true)
        end
    end

    furniturePlacementEntity = nil
    furniturePlacementKey    = nil
    furniturePlacementCoords = nil
    furniturePlacementRotation = nil
    cb(1)
end)

RegisterNUICallback("furnitureremoveobject", function(data, cb)
    if not isFurniturePlacing then cb(1) return end
    if not isFurnitureMenuOpen then cb(1) return end
    if furnitureMenuYachtId == nil then cb(1) return end
    if not furniturePlacementKey then cb(1) return end

    SendNUIMessage({message = "hideobjecteditor"})
    SendNUIMessage({action  = "setGizmoEntity", data = {}})
    GizmoEnd()

    isFurniturePlacing = false

    TriggerServerEvent("asyacht:Global:RemoveFurniture",
        furnitureMenuYachtId,
        furniturePlacementKey
    )

    local yachtData = yachts["yacht-" .. furnitureMenuYachtId]
    if yachtData and DoesEntityExist(yachtData.yachtmainobject) then
        local fe = yachtData.furnitureobjects[furniturePlacementKey]
        if fe and DoesEntityExist(fe.handler) then
            fe.editing = false
            AttachEntityToEntity(fe.handler, yachtData.yachtmainobject, 0,
                fe.furniturecoords.x, fe.furniturecoords.y, fe.furniturecoords.z,
                fe.furniturerotation.x, fe.furniturerotation.y, fe.furniturerotation.z,
                false, false, true, false, 2, true)
        end
    end

    SendNUIMessage({message = "removeobjectfromfurniturelist", furnitureid = furniturePlacementKey})

    furniturePlacementEntity = nil
    furniturePlacementKey    = nil
    cb(1)
end)

RegisterNUICallback("yachtfurnitureclose", function(data, cb)
    if not isFurnitureMenuOpen then cb(1) return end
    if isFurniturePlacementActive then cb(1) return end  
    if furnitureMenuYachtId == nil then cb(1) return end

    local closingYachtId = furnitureMenuYachtId

    furniturePlacementCategoryId = nil
    furniturePlacementItemId     = nil
    furniturePlacementCoords     = nil
    furniturePlacementRotation   = nil

    TriggerServerEvent("asyacht:Global:CloseFurniture", closingYachtId)

    isGizmoActive              = false
    isFurniturePlacing         = false
    isFurnitureMenuOpen        = false
    isFurniturePlacementActive = false
    furnitureMenuYachtId       = nil

    SendNUIMessage({message = "hidefurnitureshop"})
    SendNUIMessage({action  = "setGizmoEntity", data = {}})
    
    if DoesEntityExist(furniturePlacementEntity) then
        DeleteEntity(furniturePlacementEntity)
        furniturePlacementEntity = nil
    end
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    ToggleNoClipFurniture(false)

    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
    if playerPositionBeforeFurniture then
        SetEntityCoordsNoOffset(ped, playerPositionBeforeFurniture)
    end
    Citizen.Wait(100)
    FreezeEntityPosition(ped, false)
    SetFocusEntity(ped)

    cb(1)
end)

RegisterNUICallback("yachtfurnitureeditclose", function(data, cb)
    if not isFurnitureMenuOpen then cb(1) return end
    if furnitureMenuYachtId == nil then cb(1) return end

    local closingYachtId = furnitureMenuYachtId
    local activeYachtData = yachts["yacht-" .. closingYachtId]
    local activeEntry = activeYachtData and furniturePlacementKey
        and activeYachtData.furnitureobjects[furniturePlacementKey]

    if activeEntry then
        activeEntry.editing = false
        if DoesEntityExist(activeEntry.handler) and DoesEntityExist(activeYachtData.yachtmainobject) then
            AttachEntityToEntity(activeEntry.handler, activeYachtData.yachtmainobject, 0,
                activeEntry.furniturecoords.x, activeEntry.furniturecoords.y, activeEntry.furniturecoords.z,
                activeEntry.furniturerotation.x, activeEntry.furniturerotation.y, activeEntry.furniturerotation.z,
                false, false, true, false, 2, true)
        end
    end

    furniturePlacementCategoryId = nil
    furniturePlacementItemId     = nil
    furniturePlacementCoords     = nil
    furniturePlacementRotation   = nil

    TriggerServerEvent("asyacht:Global:CloseFurniture", closingYachtId)

    isGizmoActive              = false
    isFurniturePlacing         = false
    isFurnitureMenuOpen        = false
    isFurniturePlacementActive = false
    furnitureMenuYachtId       = nil

    SendNUIMessage({message = "hidefurnitureown"})
    SendNUIMessage({action  = "setGizmoEntity", data = {}})
    furniturePlacementEntity = nil   
    furniturePlacementKey    = nil
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    ToggleNoClipFurniture(false)

    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
    if playerPositionBeforeFurniture then
        SetEntityCoordsNoOffset(ped, playerPositionBeforeFurniture)
    end
    Citizen.Wait(100)
    FreezeEntityPosition(ped, false)
    SetFocusEntity(ped)

    cb(1)
end)

RegisterNUICallback("objecteditorcreatorchangemode", function(data, cb)
    if not isFurnitureMenuOpen or furnitureMenuYachtId == nil then cb(1) return end
    local modeType = tostring(data.modetype)
    if modeType == "translate" then
        SendNUIMessage({action="SetGizmoTransformMode", data={transformhandler=false}})
    elseif modeType == "rotate" then
        SendNUIMessage({action="SetGizmoTransformMode", data={transformhandler=true}})
    end
    cb(1)
end)

RegisterNUICallback("objecteditorcreatorchangespace", function(data, cb)
    if not isFurnitureMenuOpen or furnitureMenuYachtId == nil then cb(1) return end
    local spaceType = tostring(data.spacetype)
    if spaceType == "world" then
        SendNUIMessage({action="SetSpaceMode", data={spacehandler=false}})
    elseif spaceType == "local" then
        SendNUIMessage({action="SetSpaceMode", data={spacehandler=true}})
    end
    cb(1)
end)

RegisterNUICallback("objecteditorcreatorsnapchange", function(data, cb)
    if not isFurnitureMenuOpen or furnitureMenuYachtId == nil then cb(1) return end
    local snapType = tostring(data.snaptype)
    local snapVal  = tonumber(data.snapdata)
    if snapType == "translate" and snapVal then
        furnitureTranslateSnapIndex = snapVal
        local snapData = furnitureTranslateSnaps[furnitureTranslateSnapIndex]
        if snapData then
            SendNUIMessage({action="SetTranslateSnap", data={translatesnapdata=snapData.snapdata}})
        end
    elseif snapType == "rotate" and snapVal then
        furnitureRotateSnapIndex = snapVal
        local snapData = furnitureRotateSnaps[furnitureRotateSnapIndex]
        if snapData then
            SendNUIMessage({action="SetRotationSnap", data={rotationsnapdata=snapData.snapdata}})
        end
    end
    cb(1)
end)

RegisterNUICallback("objecteditorcreatorspeedchange", function(data, cb)
    if isFurnitureMenuOpen and furnitureMenuYachtId ~= nil then
        local speedType = tostring(data.speedtype)
        local speedVal = tonumber(data.speeddata)
        if speedType == "camera" and speedVal then
            furnitureSpeedIndex = speedVal
        elseif speedType == "lookx" and speedVal then
            furnitureLookXIndex = speedVal
        elseif speedType == "looky" and speedVal then
            furnitureLookYIndex = speedVal
        end
    end
    cb(1)
end)

function RoundNumber(num, numDecimalPlaces)
    local power = 10 ^ (numDecimalPlaces or 0)
    return math.floor(num * power + 0.5) / power
end

RegisterNUICallback("gizmo:ChangePosition", function(data, cb)
    if data.handle and data.position and data.rotation then
        if isGizmoActive then
            if furnitureMenuYachtId ~= nil then
                if DoesEntityExist(furniturePlacementEntity) then
                    local yachtData = yachts["yacht-" .. furnitureMenuYachtId]
                    if yachtData then
                        local furnitureEntry = yachtData.furnitureobjects[tostring(furniturePlacementKey)]
                        if furnitureEntry then
                            local x, y, z
                            
                            local xInt, xFrac = math.modf(data.position.x)
                            if xFrac == 0 then
                                x = tonumber(string.format("%.1f", data.position.x))
                            else
                                x = RoundNumber(data.position.x, 3)
                            end

                            local yInt, yFrac = math.modf(data.position.y)
                            if yFrac == 0 then
                                y = tonumber(string.format("%.1f", data.position.y))
                            else
                                y = RoundNumber(data.position.y, 3)
                            end

                            local zInt, zFrac = math.modf(data.position.z)
                            if zFrac == 0 then
                                z = tonumber(string.format("%.1f", data.position.z))
                            else
                                z = RoundNumber(data.position.z, 3)
                            end

                            local rx
                            local rxInt, rxFrac = math.modf(data.rotation.x)
                            if rxFrac == 0 then
                                rx = tonumber(string.format("%.1f", data.rotation.x))
                            else
                                rx = data.rotation.x
                            end

                            local ry
                            local ryInt, ryFrac = math.modf(data.rotation.y)
                            if ryFrac == 0 then
                                ry = tonumber(string.format("%.1f", data.rotation.y))
                            else
                                ry = data.rotation.y
                            end

                            local rz
                            local rzInt, rzFrac = math.modf(data.rotation.z)
                            if rzFrac == 0 then
                                rz = tonumber(string.format("%.1f", data.rotation.z))
                            else
                                rz = data.rotation.z
                            end

                            local pos = vector3(x, y, z)
                            local rot = vector3(rx, ry, rz)

                            furnitureEntry.furniturecoords = pos
                            furnitureEntry.furniturerotation = rot

                            if CheckIfFurnitureIsInYachtNearby(furnitureMenuYachtId, pos) then
                                SetEntityCoords(furniturePlacementEntity, x, y, z)
                                SetEntityRotation(furniturePlacementEntity, rx, ry, rz)
                            else
                                GizmoStart(furniturePlacementEntity)
                            end
                        end
                    end
                end
            end
        elseif isFurniturePlacing then
            if furnitureMenuYachtId ~= nil then
                if DoesEntityExist(furniturePlacementEntity) then
                    local x, y, z
                    
                    local xInt, xFrac = math.modf(data.position.x)
                    if xFrac == 0 then
                        x = tonumber(string.format("%.1f", data.position.x))
                    else
                        x = RoundNumber(data.position.x, 3)
                    end

                    local yInt, yFrac = math.modf(data.position.y)
                    if yFrac == 0 then
                        y = tonumber(string.format("%.1f", data.position.y))
                    else
                        y = RoundNumber(data.position.y, 3)
                    end

                    local zInt, zFrac = math.modf(data.position.z)
                    if zFrac == 0 then
                        z = tonumber(string.format("%.1f", data.position.z))
                    else
                        z = RoundNumber(data.position.z, 3)
                    end

                    local rx
                    local rxInt, rxFrac = math.modf(data.rotation.x)
                    if rxFrac == 0 then
                        rx = tonumber(string.format("%.1f", data.rotation.x))
                    else
                        rx = data.rotation.x
                    end

                    local ry
                    local ryInt, ryFrac = math.modf(data.rotation.y)
                    if ryFrac == 0 then
                        ry = tonumber(string.format("%.1f", data.rotation.y))
                    else
                        ry = data.rotation.y
                    end

                    local rz
                    local rzInt, rzFrac = math.modf(data.rotation.z)
                    if rzFrac == 0 then
                        rz = tonumber(string.format("%.1f", data.rotation.z))
                    else
                        rz = data.rotation.z
                    end

                    local pos = vector3(x, y, z)
                    local rot = vector3(rx, ry, rz)

                    furniturePlacementCoords = pos
                    furniturePlacementRotation = rot

                    if CheckIfFurnitureIsInYachtNearby(furnitureMenuYachtId, pos) then
                        SetEntityCoords(furniturePlacementEntity, x, y, z)
                        SetEntityRotation(furniturePlacementEntity, rx, ry, rz)
                    else
                        GizmoStart(furniturePlacementEntity)
                    end
                end
            end
        end
    end
    cb(1)
end)

function GizmoEnd()
    
end

function GizmoStart(entity)
    furniturePlacementEntity = entity
    SendNUIMessage({
        action = "setGizmoEntity",
        data = {
            handle = entity,
            position = GetEntityCoords(entity),
            rotation = GetEntityRotation(entity)
        }
    })
end


function DisableControlsFurniture()
    DisableIdleCamera(true)
    HudWeaponWheelIgnoreSelection()
    local controls = {0, 1, 2, 16, 17, 22, 23, 24, 25, 26, 36, 37, 44, 47, 55, 69, 81, 82, 91, 92, 99, 106, 114, 115, 121, 122, 135, 140, 142, 199, 200, 245, 257, 30, 31}
    for _, control in ipairs(controls) do
        DisableControlAction(0, control, true)
    end
end

function IsControlAlwaysPressed(group, control)
    return IsControlPressed(group, control) or IsDisabledControlPressed(group, control)
end

function SetupCamFurniture()
    local ped = noClipPed or PlayerPedId()
    local rot = GetEntityRotation(ped)
    local coords = GetEntityCoords(ped)
    local fov = GetFinalRenderedCamFov()
    
    furnitureCamera = CreateCameraWithParams("DEFAULT_SCRIPTED_CAMERA", coords, vector3(0.0, 0.0, rot.z), fov, true, 2)
    SetCamActive(furnitureCamera, true)
    RenderScriptCams(true, true, 1000, false, false)
    AttachCamToEntity(furnitureCamera, ped, 0.0, 0.0, 1.0, true)
end

function DestroyCamera()
    SetGameplayCamRelativeHeading(0)
    RenderScriptCams(false, true, 1000, true, true)
    DetachEntity(noClipPed or PlayerPedId(), true, true)
    if furnitureCamera then
        SetCamActive(furnitureCamera, false)
        DestroyCam(furnitureCamera, true)
        furnitureCamera = nil
    end
end



function CheckInputRotationFurniture()
    if not furnitureCamera then return end
    local x = GetControlNormal(0, 220)
    local y = GetControlNormal(0, 221)
    local rot = GetCamRot(furnitureCamera, 2)
    
    local speedLookX = furnitureSpeedsLookX[furnitureLookXIndex].speeddata
    local speedLookY = furnitureSpeedsLookY[furnitureLookYIndex].speeddata
    
    local pitch = rot.x + (y * -5 * speedLookY)
    local yaw = rot.z + (x * -10 * speedLookX)
    
    if pitch > -89.0 and pitch < 89.0 then
        SetCamRot(furnitureCamera, vector3(pitch, rot.y, yaw), 2)
    end
    SetEntityHeading(noClipPed or PlayerPedId(), math.max(0.0, yaw % 360.0))
end

function GetInView(cx, cy, cz, rx, ry, rz)
    local heading = rz
    local pitch = rx
    
    local radPitch = math.rad(pitch)
    local radYaw = math.rad(heading)
    
    local dx = -math.sin(radYaw) * math.abs(math.cos(radPitch))
    local dy = math.cos(radYaw) * math.abs(math.cos(radPitch))
    local dz = math.sin(radPitch)
    
    local destX = cx + dx * 10000.0
    local destY = cy + dy * 10000.0
    local destZ = cz + dz * 10000.0
    
    local ray = StartShapeTestRay(cx, cy, cz, destX, destY, destZ, -1, -1, 1)
    local retval, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(ray)
    
    if entityHit > 0 and GetEntityType(entityHit) ~= 0 then
        local dist = #(vector3(cx, cy, cz) - GetEntityCoords(entityHit))
        if dist >= 100.0 then
            return endCoords, nil, dist
        end
        return endCoords, entityHit, dist
    end
    return endCoords, nil, 0.0
end



function CheckYachtFurnitureNearby(yachtId, coords)
    local found = false
    local closestKey = ""
    local minDistance = -1.0
    local yachtData = yachts["yacht-" .. yachtId]
    if yachtData and yachtData.furnitureobjects then
        for key, entry in pairs(yachtData.furnitureobjects) do
            local entity = entry.handler
            if DoesEntityExist(entity) then
                local entCoords = GetEntityCoords(entity)
                local dist = #(coords - entCoords)
                if dist < 5.0 and (minDistance == -1.0 or minDistance > dist) then
                    minDistance = dist
                    found = true
                    closestKey = key
                end
            end
        end
    end
    return found, closestKey
end

function RunNoClipThreadFurniture()
    CreateThread(function()
        noClipPed = PlayerPedId()
        while noClipActive do
            Wait(0)
            
            if not noClipActive then break end
            DisableControlsFurniture()
            
            if IsDisabledControlPressed(0, 25) then
                CheckInputRotationFurniture()
                if IsDisabledControlPressed(0, 348) then
                    local cx, cy, cz = table.unpack(GetCamCoord(furnitureCamera))
                    local rx, ry, rz = table.unpack(GetCamRot(furnitureCamera, 2))
                    local endCoords, hitEntity, dist = GetInView(cx, cy, cz, rx, ry, rz)
                    
                    local isNear, closestKey = CheckYachtFurnitureNearby(furnitureMenuYachtId, endCoords)
                    if isNear then
                        TriggerEvent("asyacht:Global:YachFurnitureEditClick", closestKey)
                        Wait(1000)
                    end
                end
            end
            
            local currentSpeed = furnitureSpeedsCamera[furnitureSpeedIndex].speeddata
            
            if IsControlAlwaysPressed(0, 32) then
                local offset
                local camRot = GetCamRot(furnitureCamera, 0)
                if camRot.x >= 0 then
                    offset = GetOffsetFromEntityInWorldCoords(noClipPed, 0.0, currentSpeed, (camRot.x * (currentSpeed / 2)) / 89.0)
                else
                    offset = GetOffsetFromEntityInWorldCoords(noClipPed, 0.0, currentSpeed, -1.0 * (math.abs(camRot.x) * (currentSpeed / 2)) / 89.0)
                end
                SetEntityCoordsNoOffset(noClipPed, offset)
            elseif IsControlAlwaysPressed(0, 33) then
                local offset
                local camRot = GetCamRot(furnitureCamera, 2)
                if camRot.x >= 0 then
                    offset = GetOffsetFromEntityInWorldCoords(noClipPed, 0.0, -currentSpeed, -(camRot.x * (currentSpeed / 2)) / 89.0)
                else
                    offset = GetOffsetFromEntityInWorldCoords(noClipPed, 0.0, -currentSpeed, (math.abs(camRot.x) * (currentSpeed / 2)) / 89.0)
                end
                SetEntityCoordsNoOffset(noClipPed, offset)
            end
            
            if IsControlAlwaysPressed(0, 34) then
                SetEntityCoordsNoOffset(noClipPed, GetOffsetFromEntityInWorldCoords(noClipPed, -currentSpeed, 0.0, 0.0))
            elseif IsControlAlwaysPressed(0, 35) then
                SetEntityCoordsNoOffset(noClipPed, GetOffsetFromEntityInWorldCoords(noClipPed, currentSpeed, 0.0, 0.0))
            end
            
            if IsControlAlwaysPressed(0, 22) then
                SetEntityCoordsNoOffset(noClipPed, GetOffsetFromEntityInWorldCoords(noClipPed, 0.0, 0.0, currentSpeed))
            elseif IsControlAlwaysPressed(0, 21) then
                SetEntityCoordsNoOffset(noClipPed, GetOffsetFromEntityInWorldCoords(noClipPed, 0.0, 0.0, -currentSpeed))
            end
            
            local currentCoords = GetEntityCoords(noClipPed)
            RequestCollisionAtCoord(currentCoords.x, currentCoords.y, currentCoords.z)
            FreezeEntityPosition(noClipPed, true)
            SetEntityCollision(noClipPed, false, false)
            SetEntityVisible(noClipPed, false, false)
            SetEntityInvincible(noClipPed, true)
            SetLocalPlayerVisibleLocally(true)
            SetEntityAlpha(noClipPed, 0, false)
            SetEveryoneIgnorePlayer(noClipPed, true)
            SetPoliceIgnorePlayer(noClipPed, true)
            SetFocusArea(currentCoords.x, currentCoords.y, currentCoords.z, 0.0, 0.0, 0.0)
            
            local yachtCoords = GlobalState["asyacht-" .. furnitureMenuYachtId .. "-coords"]
            if yachtCoords then
                local dist = #(currentCoords - yachtCoords)
                if dist >= 100.0 then
                    SetEntityCoords(noClipPed, playerPositionBeforeFurniture)
                end
            end
        end
        StopNoClipFurniture()
    end)
end

function StopNoClipFurniture()
    local ped = noClipPed or PlayerPedId()
    FreezeEntityPosition(ped, false)
    SetEntityCollision(ped, true, true)
    SetEntityVisible(ped, true, false)
    SetLocalPlayerVisibleLocally(true)
    ResetEntityAlpha(ped)
    ResetEntityAlpha(noClipPed)
    SetEveryoneIgnorePlayer(noClipPed, false)
    SetPoliceIgnorePlayer(noClipPed, false)
    ResetEntityAlpha(ped)
    SetPoliceIgnorePlayer(noClipPed, true)
    
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then
        while not IsVehicleOnAllWheels(ped) and not noClipActive do
            Wait(0)
        end
        while not noClipActive do
            Wait(0)
            if IsVehicleOnAllWheels(ped) then
                SetEntityInvincible(ped, false)
                break
            end
        end
    else
        if IsPedFalling(ped) then
            if math.abs(1.0 - GetEntityHeightAboveGround(ped)) > 1.0 then
                while not IsPedStopped(ped) and not IsPedFalling(ped) and not noClipActive do
                    Wait(0)
                end
            end
        end
        while not noClipActive do
            Wait(0)
            if not IsPedFalling(ped) and not IsPedRagdoll(ped) then
                SetEntityInvincible(ped, false)
                break
            end
        end
    end
end

function ToggleNoClipFurnitureDefault(enable)
    noClipActive = enable
    noClipPed = PlayerPedId()
    
    if enable then
        playerPositionBeforeFurniture = GetEntityCoords(noClipPed)
        FreezeEntityPosition(noClipPed, true)
        SetupCamFurniture()
        PlaySoundFromEntity(-1, "SELECT", noClipPed, "HUD_LIQUOR_STORE_SOUNDSET", 0, 0)
        ClearPedTasksImmediately(noClipPed)
        Wait(1000)
    else
        SetEntityCoords(noClipPed, playerPositionBeforeFurniture)
        Wait(50)
        DestroyCamera()
        PlaySoundFromEntity(-1, "CANCEL", noClipPed, "HUD_LIQUOR_STORE_SOUNDSET", 0, 0)
    end
    
    SetUserRadioControlEnabled(not enable)
    if enable then
        RunNoClipThreadFurniture()
    end
end

AddEventHandler("onClientResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    if DoesEntityExist(yachtBuyState.yachtbuyobject) then
        DeleteEntity(yachtBuyState.yachtbuyobject)
    end
    for _, obj in ipairs(yachtBuyState.mainobjects or {}) do
        if DoesEntityExist(obj.handler) then
            DeleteEntity(obj.handler)
        end
    end
    if DoesEntityExist(yachtBuyState.flagdata.handler) then
        DeleteEntity(yachtBuyState.flagdata.handler)
    end
    if DoesEntityExist(yachtBuyState.lighting.handler) then
        DeleteEntity(yachtBuyState.lighting.handler)
    end
    for _, h in ipairs({"handler", "handler2", "handler3"}) do
        if yachtBuyState.railing and DoesEntityExist(yachtBuyState.railing[h]) then
            DeleteEntity(yachtBuyState.railing[h])
        end
    end

    if DoesEntityExist(drivingState.yachthandler) then
        DeleteEntity(drivingState.yachthandler)
    end

    for yachtKey, yachtData in pairs(yachts) do
        if yachtData.mainobjects then
            for _, obj in ipairs(yachtData.mainobjects) do
                if DoesEntityExist(obj.handler) then
                    DetachEntity(obj.handler, true, true)
                    DeleteEntity(obj.handler)
                end
            end
        end
        if yachtData.furnitureobjects then
            for _, furnitureEntry in pairs(yachtData.furnitureobjects) do
                if DoesEntityExist(furnitureEntry.handler) then
                    DetachEntity(furnitureEntry.handler, true, true)
                    DeleteEntity(furnitureEntry.handler)
                end
            end
        end
        if yachtData.doors then
            for _, door in ipairs(yachtData.doors) do
                if DoesEntityExist(door.handler) then
                    DetachEntity(door.handler, true, true)
                    DeleteEntity(door.handler)
                end
            end
        end
        if yachtData.flagdata and DoesEntityExist(yachtData.flagdata.handler) then
            DetachEntity(yachtData.flagdata.handler, true, true)
            DeleteEntity(yachtData.flagdata.handler)
        end
        if yachtData.lighting and DoesEntityExist(yachtData.lighting.handler) then
            DetachEntity(yachtData.lighting.handler, true, true)
            DeleteEntity(yachtData.lighting.handler)
        end
        if yachtData.railing then
            for _, h in ipairs({"handler", "handler2", "handler3"}) do
                if DoesEntityExist(yachtData.railing[h]) then
                    DetachEntity(yachtData.railing[h], true, true)
                    DeleteEntity(yachtData.railing[h])
                end
            end
        end
        if DoesEntityExist(yachtData.yachtmainobject) then
            DetachEntity(yachtData.yachtmainobject, true, true)
            DeleteEntity(yachtData.yachtmainobject)
        end
        if yachtData.yachtiddata then
            RemovePersonalYachtBlip(yachtData.yachtiddata)
        end
    end

    if hasBuyBlipCreated and yachtBuyBlip and DoesBlipExist(yachtBuyBlip) then
        RemoveBlip(yachtBuyBlip)
    end
end)



-- ═══════════════════════════════════════════════════════════════════════════
--  Comfort & style extras: light schedule, hull lights, radio, tender
-- ═══════════════════════════════════════════════════════════════════════════


-- The server confirms a purchase so the shop can show an accurate "bought this visit" total and recent list.
RegisterNetEvent("asyacht:Global:FurniturePurchased")
AddEventHandler("asyacht:Global:FurniturePurchased", function(model, price)
    SendNUIMessage({ message = "furniturepurchased", name = model, price = price })
end)
