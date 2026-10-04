-- as-yacht client/manage.lua: Management / furniture / permission menu events.
-- (Split from the former client/main.lua. File-level state is global so every client module shares it.)

RegisterNetEvent("asyacht:Global:FurnitureShop")
AddEventHandler("asyacht:Global:FurnitureShop", function(yachtId)
    if isFurnitureMenuOpen or isFurniturePlacementActive then
        TriggerServerEvent("asyacht:Global:CloseFurniture", yachtId)
        return
    end
    if currentNearYachtId == nil then
        TriggerServerEvent("asyacht:Global:CloseFurniture", yachtId)
        return
    end

    isFurnitureMenuOpen        = true
    isFurniturePlacementActive = false    
    furnitureMenuYachtId       = yachtId

    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
    ToggleNoClipFurniture(true)

    SendNUIMessage({message = "yachtfurnitureshow"})

    for catId, category in ipairs(Config.Furnitures) do
        SendNUIMessage({
            message       = "addfurniturecategory",
            categoryid    = catId,
            categorylabel = category.categorylabel,
        })
        for objId, obj in ipairs(category.categoryobjects) do
            SendNUIMessage({
                message          = "addfurniture",
                categoryid       = catId,
                furnitureid      = objId,
                furniturelabel   = obj.furnitureobject,
                furnitureprice   = obj.furnitureprice,
            })
        end
    end
end)

RegisterNetEvent("asyacht:Global:FurnitureEdit")
AddEventHandler("asyacht:Global:FurnitureEdit", function(yachtId)
    if isFurnitureMenuOpen or isFurniturePlacementActive then
        TriggerServerEvent("asyacht:Global:CloseFurniture", yachtId)
        return
    end
    if currentNearYachtId == nil then
        TriggerServerEvent("asyacht:Global:CloseFurniture", yachtId)
        return
    end

    local yachtData = yachts["yacht-" .. yachtId]
    if not yachtData then
        TriggerServerEvent("asyacht:Global:CloseFurniture", yachtId)
        return
    end

    local playerCoords = GetEntityCoords(PlayerPedId())

    isFurnitureMenuOpen        = true
    isFurniturePlacementActive = true
    furnitureMenuYachtId       = yachtId

    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
    ToggleNoClipFurniture(true)

    SendNUIMessage({message = "yachtfurnitureownshow"})

    for key, entry in pairs(yachtData.furnitureobjects) do
        SendNUIMessage({
            message              = "addfurnitureown",
            furnitureid          = key,
            furnitureimage       = "img/objects/" .. entry.furnituremodel .. ".webp",
            furnitureobjectname  = entry.furnituremodel,
            furnitureobjecttextname = entry.furnituremodel,
        })
    end
end)

RegisterNetEvent("asyacht:Global:OpenManagmentClient")
AddEventHandler("asyacht:Global:OpenManagmentClient", function(yachtId)
    if isManagementMenuOpen then return end
    if currentNearYachtId == nil then return end

    isManagementMenuOpen  = true
    managementMenuYachtId = yachtId

    SetNuiFocus(true, true)
    SendNUIMessage({message = "yachtmanagmentshow"})
end)

RegisterNetEvent("asyacht:Global:OpenManagmentClient2")
AddEventHandler("asyacht:Global:OpenManagmentClient2", function(yachtId)
    if isManagementMenuOpen then return end
    if currentNearYachtId == nil then return end

    isManagementMenuOpen  = true
    managementMenuYachtId = yachtId

    SetNuiFocus(true, true)
    
    SendNUIMessage({message = "yachtmanagment2show"})
end)

RegisterNetEvent("asyacht:Global:OpenAddPermissionPlayerClient")
AddEventHandler("asyacht:Global:OpenAddPermissionPlayerClient", function(yachtId, playerList)
    if not isManagementMenuOpen then return end
    
    SendNUIMessage({message = "yachtmanagmentaddpermissionsshow"})
    
    for _, player in ipairs(playerList) do
        SendNUIMessage({
            message      = "yachtmanagmentaddplayer",
            playername   = player.playername,
            playeriddata = player.playerid,  
        })
    end
end)

RegisterNetEvent("asyacht:Global:OpenPermissionsClient")
AddEventHandler("asyacht:Global:OpenPermissionsClient", function(yachtId, permList)
    if not isManagementMenuOpen then return end
    
    SendNUIMessage({message = "yachtmanagmentaddpermissionschangeshow"})
    
    for _, perm in ipairs(permList) do
        SendNUIMessage({
            message              = "yachtmanagmentaddplayerchange",
            playerid             = perm.identifierdata,   
            playername           = perm.playername,
            yachtcontrol         = perm.yachtcontrol == 1,
            dooraccess           = perm.dooraccess == 1,
            furnituremanagment   = perm.furnituremanagment == 1,
            storageaccess        = perm.storageaccess == 1,
            wardrobeaccess       = perm.wardrobeaccess == 1,
        })
    end
end)

RegisterNetEvent("asyacht:Global:OpenTransferYachtPlayerClient")
AddEventHandler("asyacht:Global:OpenTransferYachtPlayerClient", function(yachtId, playerList)
    if not isManagementMenuOpen then return end
    
    SendNUIMessage({message = "yachtmanagmenttransfershow"})
    
    for _, player in ipairs(playerList) do
        SendNUIMessage({
            message      = "yachtmanagmenttransferaddplayer",
            playername   = player.playername,
            playeriddata = player.playerid,  
        })
    end
end)

RegisterNetEvent("asyacht:Global:YachFurnitureEditClick")
AddEventHandler("asyacht:Global:YachFurnitureEditClick", function(furnitureKey)
    if not isFurnitureMenuOpen or not isFurniturePlacementActive then return end
    if furnitureMenuYachtId == nil then return end

    local yachtData = yachts["yacht-" .. furnitureMenuYachtId]
    if not yachtData then return end

    if not isFurniturePlacing then
        
        local furnitureEntry = yachtData.furnitureobjects[tostring(furnitureKey)]
        if not furnitureEntry then return end

        isGizmoActive      = false
        isFurniturePlacing = true

        local worldPos = GetOffsetFromEntityInWorldCoords(
            yachtData.yachtmainobject,
            furnitureEntry.furniturecoords.x,
            furnitureEntry.furniturecoords.y,
            furnitureEntry.furniturecoords.z)
        local worldRot = GetWorldRotationFromEntityAndOffset(
            yachtData.yachtmainobject,
            furnitureEntry.furniturerotation.x,
            furnitureEntry.furniturerotation.y,
            furnitureEntry.furniturerotation.z)

        DetachEntity(furnitureEntry.handler, true, true)
        FreezeEntityPosition(furnitureEntry.handler, true)
        furnitureEntry.editing = true

        furniturePlacementKey      = tostring(furnitureKey)
        furniturePlacementEntity   = furnitureEntry.handler
        furniturePlacementCoords   = worldPos
        furniturePlacementRotation = worldRot

        SendNUIMessage({action="SetTranslateSnap",      data={translatesnapdata = furnitureTranslateSnaps[furnitureTranslateSnapIndex].snapdata}})
        SendNUIMessage({action="SetRotationSnap",        data={rotationsnapdata  = furnitureRotateSnaps[furnitureRotateSnapIndex].snapdata}})
        SendNUIMessage({action="SetGizmoTransformMode",  data={transformhandler=false}})
        SendNUIMessage({action="SetSpaceMode",           data={spacehandler=false}})
        SendNUIMessage({message = "objecteditorownposshow", translatesnap = furnitureTranslateSnapIndex, translatesteps = FurnitureSnapSteps(), rotatesnap = furnitureRotateSnapIndex})

        GizmoStart(furnitureEntry.handler)
    else
        
        local prevKey = furniturePlacementKey
        local newEntry = yachtData.furnitureobjects[tostring(furnitureKey)]
        if not newEntry then return end

        isGizmoActive      = false
        isFurniturePlacing = true

        local newWorldPos = GetOffsetFromEntityInWorldCoords(
            yachtData.yachtmainobject,
            newEntry.furniturecoords.x,
            newEntry.furniturecoords.y,
            newEntry.furniturecoords.z)
        local newWorldRot = GetWorldRotationFromEntityAndOffset(
            yachtData.yachtmainobject,
            newEntry.furniturerotation.x,
            newEntry.furniturerotation.y,
            newEntry.furniturerotation.z)

        DetachEntity(newEntry.handler, true, true)
        FreezeEntityPosition(newEntry.handler, true)
        newEntry.editing = true

        local newKey = tostring(furnitureKey)
        furniturePlacementKey      = newKey
        furniturePlacementEntity   = newEntry.handler
        furniturePlacementCoords   = newWorldPos
        furniturePlacementRotation = newWorldRot

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

        GizmoStart(newEntry.handler)
    end
end)
