-- as-yacht client/events.lua: Server -> client events for yacht lifecycle, fuel and extras.
-- (Split from the former client/main.lua. File-level state is global so every client module shares it.)

RegisterNetEvent("asyacht:Global:CreateYachtBlip")
AddEventHandler("asyacht:Global:CreateYachtBlip", function(yachtId)
    Citizen.CreateThread(function()
        yachtIntroPlayed[yachtId] = true
        local timeout = GetGameTimer() + 30000
        while yachts["yacht-" .. yachtId] == nil and GetGameTimer() < timeout do
            Citizen.Wait(100)
        end
        if yachts["yacht-" .. yachtId] ~= nil then
            while not DoesEntityExist(yachts["yacht-" .. yachtId].yachtmainobject) and GetGameTimer() < timeout do
                Citizen.Wait(100)
            end
            if DoesEntityExist(yachts["yacht-" .. yachtId].yachtmainobject) then
                CreatePersonalYachtBlip(yachtId)
            end
        end
    end)
end)

RegisterNetEvent("asyacht:Global:RemoveYachtBlip")
AddEventHandler("asyacht:Global:RemoveYachtBlip", function(yachtId)
    yachtIntroPlayed[yachtId] = nil
    RemovePersonalYachtBlip(yachtId)
end)

RegisterNetEvent("asyacht:Global:DoorSpecial")
AddEventHandler("asyacht:Global:DoorSpecial", function(yachtId, doorIndex, open)
    if yachts["yacht-" .. yachtId] == nil then return end
    ToggleDoor(yachtId, doorIndex, open)
end)

RegisterNetEvent("asyacht:Global:DriveYacht")
AddEventHandler("asyacht:Global:DriveYacht", function(yachtId)
    drivingState.drivingid = yachtId
    
end)

RegisterNetEvent("asyacht:Global:YachtLeave")
AddEventHandler("asyacht:Global:YachtLeave", function(yachtId)
    if not drivingState.driving then return end

    yachtId = yachtId or drivingState.drivingid

    DoScreenFadeOut(5)
    local playerPed = PlayerPedId()

    if DoesEntityExist(drivingState.yachthandler) then
        TaskLeaveVehicle(playerPed, drivingState.yachthandler, 0)
        DeleteEntity(drivingState.yachthandler)
    end

    local disembarkOffset = vector3(0.0, 14.0, 13.15)
    DetachEntity(playerPed)
    FreezeEntityPosition(playerPed, true)
    NetworkAllowLocalEntityAttachment(playerPed, true)

    local yachtData = yachtId and yachts["yacht-" .. yachtId] or nil
    if yachtData then
        
        local startTime = GetGameTimer()
        while true do
            local elapsed = GetGameTimer() - startTime
            if elapsed >= 5000 then
                if not IsEntityAttached(yachtData.yachtmainobject) then
                    break
                end
            end
            Citizen.Wait(5)
            FreezeEntityPosition(playerPed, true)
            AttachEntityToEntity(playerPed, yachtData.yachtmainobject, 0,
                disembarkOffset.x, disembarkOffset.y, disembarkOffset.z,
                0.0, 0.0, 0.0, false, false, false, false, 2, true)
        end
    end

    DetachEntity(playerPed)
    FreezeEntityPosition(playerPed, false)
    drivingState.driving     = false
    drivingState.drivingid   = nil
    drivingState.yachthandler = nil

    Citizen.Wait(5000)
    DoScreenFadeIn(0)
end)

RegisterNetEvent("asyacht:Global:CreateYacht")
AddEventHandler("asyacht:Global:CreateYacht", function(
    yachtId, flagId, lightData, textData, railingId, colorId, furnitures)

    local yachtKey = "yacht-" .. yachtId
    if yachts[yachtKey] ~= nil then return end  

    local furnitureObjects = {}
    if furnitures then
        for key, entry in pairs(furnitures) do
            furnitureObjects[key] = {
                handler          = nil,
                removeinprogress = false,
                furnituremodel   = entry.furnituremodel,
                furniturecoords  = vector3(entry.furniturecoords.x, entry.furniturecoords.y, entry.furniturecoords.z),
                furniturerotation = vector3(entry.furniturerotation.x, entry.furniturerotation.y, entry.furniturerotation.z),
            }
        end
    end

    local entry = {
        yachtiddata      = yachtId,
        yachtmainobject  = nil,
        hullspawning     = false,
        lastAnchorTick   = 0,
        removeinprogress = false,
        yachtcolor       = colorId or 1,
        furnitureobjects = furnitureObjects,

        railing = {
            railingid = railingId or 1,
            handler   = nil,
            handler2  = nil,
            handler3  = nil,
            coords    = vector3(0.0, 0.0, 14.57),
            rotation  = vector3(0.0, 0.0, 0.0),
        },

        flagdata = {
            flagid   = flagId or 1,
            handler  = nil,
            coords   = vector3(0.0, 0.0, 0.0),
            rotation = vector3(0.0, 0.0, 0.0),
        },

        lighting = {
            lightingcategory = (lightData and lightData.category) or 1,
            lightingid       = (lightData and lightData.id) or 1,
            handler          = nil,
            coords           = vector3(0.0, 0.0, 14.5),
            rotation         = vector3(0.0, 0.0, 0.0),
        },

        textdata = {
            uppertext  = (textData and textData.uppertext) or "",
            bottomtext = (textData and textData.bottomtext) or "",
        },

        mainobjects = {
            {handler=nil, objectname="as_yacht_bar_details",               offsetcoords=vector3(-2.0496, 8.28e-4, 5.87994), offsetrotation=vector3(0,0,90)},
            {handler=nil, objectname="as_yacht_bridge_details",            offsetcoords=vector3(-2.0496, 8.28e-4, 5.87994), offsetrotation=vector3(0,0,90)},
            {handler=nil, objectname="as_yacht_engine_details_room_1",     offsetcoords=vector3(-2.0496, 8.28e-4, 5.87994), offsetrotation=vector3(0,0,90)},
            {handler=nil, objectname="as_yacht_engine_details_room_2",     offsetcoords=vector3(-2.0496, 8.28e-4, 5.87994), offsetrotation=vector3(0,0,90)},
            {handler=nil, objectname="as_yacht_engine_room_entry",         offsetcoords=vector3(-2.0496, 8.28e-4, 5.87994), offsetrotation=vector3(0,0,90)},
            {handler=nil, objectname="as_yacht_int_wellness_rooms_details",offsetcoords=vector3(-2.0496, 8.28e-4, 5.87994), offsetrotation=vector3(0,0,90)},
            {handler=nil, objectname="as_yacht_main_hall",                 offsetcoords=vector3(-2.0496, 8.28e-4, 5.87994), offsetrotation=vector3(0,0,90)},
            {handler=nil, objectname="as_yacht_room1_details",             offsetcoords=vector3(-2.0496, 8.28e-4, 5.87994), offsetrotation=vector3(0,0,90)},
            {handler=nil, objectname="as_yacht_room2_details",             offsetcoords=vector3(-2.0496, 8.28e-4, 5.87994), offsetrotation=vector3(0,0,90)},
            {handler=nil, objectname="as_yacht_room3_details",             offsetcoords=vector3(-2.0496, 8.28e-4, 5.87994), offsetrotation=vector3(0,0,90)},
            {handler=nil, objectname="as_yachta_entry_room_details",       offsetcoords=vector3(-2.0496, 8.28e-4, 5.87994), offsetrotation=vector3(0,0,90)},
            {handler=nil, objectname="apa_prop_ap_stern_text",  offsetcoords=vector3(-2.0, -0.65, 17.1), offsetrotation=vector3(10,0,90)},
            {handler=nil, objectname="apa_prop_ap_starb_text",  offsetcoords=vector3(-2.05, 0.0, 5.8),   offsetrotation=vector3(0,0,90)},
            {handler=nil, objectname="apa_prop_ap_port_text",   offsetcoords=vector3(-2.05, 0.0, 5.8),   offsetrotation=vector3(0,0,90)},
            {handler=nil, objectname="apa_mp_apa_yacht_win",    offsetcoords=vector3(-2.05, 0.0, 5.9),   offsetrotation=vector3(0,0,90)},
            {handler=nil, objectname="as_apa_mp_apa_yacht_option3", offsetcoords=vector3(0,0,0), offsetrotation=vector3(0,0,0)},
            {handler=nil, objectname="as_apa_mp_apa_yacht_jacuzzi_ripple1", offsetcoords=vector3(0,-51,6), offsetrotation=vector3(0,0,0)},
        },

        doors = {
            {handler=nil, objectname="apa_mp_apa_yacht_door",          coords=vector3(-0.769,-36.827,6.536), rotation=vector3(0,0,0),   rotationopened=vector3(0,0,90),   opened=false},
            {handler=nil, objectname="sf_p_mp_yacht_door",             coords=vector3(-4.803,-4.518,6.527),  rotation=vector3(0,0,180), rotationopened=vector3(0,0,270),  opened=false},
            {handler=nil, objectname="sf_p_mp_yacht_door",             coords=vector3(-4.597,2.122,6.527),   rotation=vector3(0,0,180), rotationopened=vector3(0,0,270),  opened=false},
            {handler=nil, objectname="as_yacht_int_doors_1",      coords=vector3(-3.343,14.919,6.47),   rotation=vector3(0,0,-160),rotationopened=vector3(0,0,-70),  opened=false},
            {handler=nil, objectname="as_yacht_int_doors_1",      coords=vector3(-2.55,4.067,6.47),     rotation=vector3(0,0,-160),rotationopened=vector3(0,0,-70),  opened=false},
            {handler=nil, objectname="as_yacht_int_doors_1",      coords=vector3(-3.343,17.287,6.47),   rotation=vector3(0,0,-160),rotationopened=vector3(0,0,-70),  opened=false},
            {handler=nil, objectname="as_yacht_int_doors_2",      coords=vector3(0.224,18.263,6.262),   rotation=vector3(0,0,135), rotationopened=vector3(0,0,225),  opened=false},
            {handler=nil, objectname="as_yacht_int_doors_1",      coords=vector3(-3.343,23.339,6.47),   rotation=vector3(0,0,-160),rotationopened=vector3(0,0,-70),  opened=false},
            {handler=nil, objectname="as_yacht_int_doors_2",      coords=vector3(5.071,28.801,6.265),   rotation=vector3(0,0,90),  rotationopened=vector3(0,0,180),  opened=false},
            {handler=nil, objectname="as_yacht_int_doors_1",      coords=vector3(-5.038,32.619,6.449),  rotation=vector3(0,0,-70), rotationopened=vector3(0,0,20),   opened=false},
            {handler=nil, objectname="as_yacht_int_doors_1",      coords=vector3(1.247,38.011,6.449),   rotation=vector3(0,0,-160),rotationopened=vector3(0,0,-70),  opened=false},
            {handler=nil, objectname="as_yacht_int_doors_1",      coords=vector3(3.683,22.238,3.452),   rotation=vector3(0,0,20),  rotationopened=vector3(0,0,110),  opened=false},
            {handler=nil, objectname="as_yacht_int_doors_1",      coords=vector3(3.683,27.283,3.452),   rotation=vector3(0,0,20),  rotationopened=vector3(0,0,110),  opened=false},
            {handler=nil, objectname="as_yacht_int_doors_1",      coords=vector3(3.683,16.005,3.452),   rotation=vector3(0,0,20),  rotationopened=vector3(0,0,110),  opened=false},
            {handler=nil, objectname="as_yacht_int_doors_1",      coords=vector3(-1.019,15.56,3.452),   rotation=vector3(0,0,20),  rotationopened=vector3(0,0,-70),  opened=false},
            {handler=nil, objectname="as_yacht_int_doors_1",      coords=vector3(-1.019,21.732,3.452),  rotation=vector3(0,0,20),  rotationopened=vector3(0,0,-70),  opened=false},
            {handler=nil, objectname="as_yacht_int_doors_1",      coords=vector3(-1.235,18.328,3.452),  rotation=vector3(0,0,110), rotationopened=vector3(0,0,200),  opened=false},
            {handler=nil, objectname="as_yacht_int_doors_1",      coords=vector3(-2.402,20.14,3.452),   rotation=vector3(0,0,-70), rotationopened=vector3(0,0,20),   opened=false},
            {handler=nil, objectname="as_yacht_int_doors_1",      coords=vector3(-3.43,29.385,3.452),   rotation=vector3(0,0,-70), rotationopened=vector3(0,0,-160), opened=false},
            {handler=nil, objectname="as_yacht_int_doors_1",      coords=vector3(-6.51,29.385,3.452),   rotation=vector3(0,0,-70), rotationopened=vector3(0,0,-160), opened=false},
            {handler=nil, objectname="as_yacht_int_doors_1",      coords=vector3(-6.51,11.612,3.452),   rotation=vector3(0,0,-70), rotationopened=vector3(0,0,20),   opened=false},
            {handler=nil, objectname="as_apa_yacht_door_1",       coords=vector3(-5.508,5.174,9.624),   rotation=vector3(0,0,90),  rotationopened=vector3(0,0,0),    opened=false},
            {handler=nil, objectname="as_apa_yacht_door_1",       coords=vector3(4.881,8.038,13.421),   rotation=vector3(0,0,90),  rotationopened=vector3(0,0,180),  opened=false},
            {handler=nil, objectname="as_apa_yacht_door_1",       coords=vector3(-4.974,8.038,13.421),  rotation=vector3(0,0,90),  rotationopened=vector3(0,0,0),    opened=false},
            {handler=nil, objectname="as_apa_yacht_door_1",       coords=vector3(5.427,5.174,9.624),    rotation=vector3(0,0,90),  rotationopened=vector3(0,0,180),  opened=false},
            {handler=nil, objectname="as_yacht_int_doors_1",      coords=vector3(-0.655,-18.873,6.459), rotation=vector3(0,0,-70), rotationopened=vector3(0,0,20),   opened=false},
            {handler=nil, objectname="as_yacht_int_doors_2",      coords=vector3(0.943,6.236,6.262),    rotation=vector3(0,0,135), rotationopened=vector3(0,0,225),  opened=false},
            {handler=nil, objectname="as_yacht_int_doors_3",      coords=vector3(0.217,15.548,6.456),   rotation=vector3(0,0,-70), rotationopened=vector3(0,0,20),   opened=false},
            {handler=nil, objectname="as_yacht_int_door_l",       coords=vector3(-1.013,-27.255,9.546), rotation=vector3(0,0,180), rotationopened=vector3(0,0,270),  opened=false},
            {handler=nil, objectname="as_yacht_int_door_r",       coords=vector3(0.893,-27.255,9.546),  rotation=vector3(0,0,0),   rotationopened=vector3(0,0,-90),  opened=false},
            {handler=nil, objectname="as_yacht_int_door_s",       coords=vector3(5.312,-16.599,9.547),  rotation=vector3(0,0,90),  rotationopened=vector3(0,0,0),    opened=false},
            {handler=nil, objectname="as_yacht_int_gate_l",       coords=vector3(-0.049,-51.949,2.058), rotation=vector3(0,0,90),  rotationopened=vector3(0,0,55),   opened=false, special=true, opencoords=vector3(-0.049,-53.949,2.058)},
            {handler=nil, objectname="as_yacht_int_gate_r",       coords=vector3(-0.049,-51.949,2.058), rotation=vector3(0,0,90),  rotationopened=vector3(0,0,125),  opened=false, special=true, opencoords=vector3(-0.049,-53.949,2.058)},
            {handler=nil, objectname="as_apa_mp_apa_yacht_door_cap",  coords=vector3(-1.19,0.081,12.56),    rotation=vector3(0,0,-90), rotationopened=vector3(0,0,0),    opened=false},
            {handler=nil, objectname="as_apa_mp_apa_yacht_door_cap",  coords=vector3(1.138,0.081,12.56),    rotation=vector3(0,0,90),  rotationopened=vector3(0,0,0),    opened=false},
            {handler=nil, objectname="as_apa_mp_apa_yacht_door_front",coords=vector3(0.943,42.884,7.758),   rotation=vector3(0,0,90),  rotationopened=vector3(0,0,0),    opened=false},
            {handler=nil, objectname="as_apa_mp_apa_yacht_door_front",coords=vector3(-1.053,42.884,7.758),  rotation=vector3(0,0,-90), rotationopened=vector3(0,0,0),    opened=false},
            {handler=nil, objectname="as_yacht_int_door_saun",    coords=vector3(-4.115,3.033,3.548),   rotation=vector3(0,0,90),  rotationopened=vector3(0,0,0),    opened=false},
            {handler=nil, objectname="as_yacht_int_door_saun",    coords=vector3(-5.047,3.966,3.548),   rotation=vector3(0,0,-90), rotationopened=vector3(0,0,0),    opened=false},
            {handler=nil, objectname="as_apa_mp_apa_yacht_door_engine",coords=vector3(4.696,0.734,3.831),   rotation=vector3(0,0,90),  rotationopened=vector3(0,0,180),  opened=false},
            {handler=nil, objectname="as_apa_mp_apa_yacht_door_engine",coords=vector3(2.805,0.734,3.831),   rotation=vector3(0,0,-90), rotationopened=vector3(0,0,-180), opened=false},
        },

        hottubseats = {
            {taken=false, takenplayerid=nil, offsets={coords=vector3(2.283, -51.146, 5.674),     rotation=vector3(0,0,87.650002)}},
            {taken=false, takenplayerid=nil, offsets={coords=vector3(2.039, -51.880001, 5.674),  rotation=vector3(0,0,62.549999)}},
            {taken=false, takenplayerid=nil, offsets={coords=vector3(1.757, -52.313999, 5.674),  rotation=vector3(0,0,53.450001)}},
            {taken=false, takenplayerid=nil, offsets={coords=vector3(1.295, -52.740002, 5.674),  rotation=vector3(0,0,36.950001)}},
            {taken=false, takenplayerid=nil, offsets={coords=vector3(0.799, -53.023998, 5.674),  rotation=vector3(0,0,20.15)}},
            {taken=false, takenplayerid=nil, offsets={coords=vector3(0.047, -53.161999, 5.674),  rotation=vector3(0,0,-1.55)}},
            {taken=false, takenplayerid=nil, offsets={coords=vector3(-0.657, -53.096001, 5.674), rotation=vector3(0,0,-13.85)}},
            {taken=false, takenplayerid=nil, offsets={coords=vector3(-1.319, -52.858002, 5.674), rotation=vector3(0,0,-21.35)}},
            {taken=false, takenplayerid=nil, offsets={coords=vector3(-1.781, -52.470001, 5.674), rotation=vector3(0,0,-47.349998)}},
            {taken=false, takenplayerid=nil, offsets={coords=vector3(-2.231, -51.866001, 5.674), rotation=vector3(0,0,-63.450001)}},
            {taken=false, takenplayerid=nil, offsets={coords=vector3(-2.427, -51.158001, 5.674), rotation=vector3(0,0,-86.849998)}},
        },
    }

    yachts[yachtKey] = entry
end)

RegisterNetEvent("asyacht:Global:YachtExtras")
AddEventHandler("asyacht:Global:YachtExtras", function(yachtId, extras)
    yachtExtras[yachtId] = extras
    yachtFuel[yachtId] = extras.fuel
end)

RegisterNetEvent("asyacht:Global:ConditionUpdate")
AddEventHandler("asyacht:Global:ConditionUpdate", function(yachtId, condition)
    yachtExtras[yachtId] = yachtExtras[yachtId] or {}
    yachtExtras[yachtId].condition = condition
end)

RegisterNetEvent("asyacht:Global:FuelUpdate")
AddEventHandler("asyacht:Global:FuelUpdate", function(yachtId, fuel)
    yachtFuel[yachtId] = fuel
end)
