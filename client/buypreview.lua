-- as-yacht client/buypreview.lua: Buy menu state and the preview session helpers.
-- (Split from the former client/main.lua. File-level state is global so every client module shares it.)

yachts = {}

yachtBuyState = {
    yachtbuyobject = nil,

    mainobjects = {
        {handler=nil, objectname="as_yacht_bar_details",              offsetcoords=vector3(-2.0496, 8.28e-4, 5.87994), offsetrotation=vector3(0,0,90)},
        {handler=nil, objectname="as_yacht_bridge_details",           offsetcoords=vector3(-2.0496, 8.28e-4, 5.87994), offsetrotation=vector3(0,0,90)},
        {handler=nil, objectname="as_yacht_engine_details_room_1",    offsetcoords=vector3(-2.0496, 8.28e-4, 5.87994), offsetrotation=vector3(0,0,90)},
        {handler=nil, objectname="as_yacht_engine_details_room_2",    offsetcoords=vector3(-2.0496, 8.28e-4, 5.87994), offsetrotation=vector3(0,0,90)},
        {handler=nil, objectname="as_yacht_engine_room_entry",        offsetcoords=vector3(-2.0496, 8.28e-4, 5.87994), offsetrotation=vector3(0,0,90)},
        {handler=nil, objectname="as_yacht_int_wellness_rooms_details",offsetcoords=vector3(-2.0496, 8.28e-4, 5.87994), offsetrotation=vector3(0,0,90)},
        {handler=nil, objectname="as_yacht_main_hall",                offsetcoords=vector3(-2.0496, 8.28e-4, 5.87994), offsetrotation=vector3(0,0,90)},
        {handler=nil, objectname="as_yacht_room1_details",            offsetcoords=vector3(-2.0496, 8.28e-4, 5.87994), offsetrotation=vector3(0,0,90)},
        {handler=nil, objectname="as_yacht_room2_details",            offsetcoords=vector3(-2.0496, 8.28e-4, 5.87994), offsetrotation=vector3(0,0,90)},
        {handler=nil, objectname="as_yacht_room3_details",            offsetcoords=vector3(-2.0496, 8.28e-4, 5.87994), offsetrotation=vector3(0,0,90)},
        {handler=nil, objectname="as_yachta_entry_room_details",      offsetcoords=vector3(-2.0496, 8.28e-4, 5.87994), offsetrotation=vector3(0,0,90)},
        
        {handler=nil, objectname="apa_prop_ap_stern_text",  offsetcoords=vector3(-2.0,  -0.65, 17.1), offsetrotation=vector3(10,0,90)},
        {handler=nil, objectname="apa_prop_ap_starb_text",  offsetcoords=vector3(-2.05,  0.0,   5.8), offsetrotation=vector3(0,0,90)},
        {handler=nil, objectname="apa_prop_ap_port_text",   offsetcoords=vector3(-2.05,  0.0,   5.8), offsetrotation=vector3(0,0,90)},
        
        {handler=nil, objectname="apa_mp_apa_yacht_win",    offsetcoords=vector3(-2.05,  0.0,   5.9), offsetrotation=vector3(0,0,90)},
        {handler=nil, objectname="as_apa_mp_apa_yacht_option3", offsetcoords=vector3(0,0,0),         offsetrotation=vector3(0,0,0)},
        
        {handler=nil, objectname="as_apa_mp_apa_yacht_jacuzzi_ripple1", offsetcoords=vector3(0,-51,6), offsetrotation=vector3(0,0,0)},
    },

    doors = {
        
        {handler=nil, objectname="apa_mp_apa_yacht_door",
         coords=vector3(-0.769,-36.827,6.536), rotation=vector3(0,0,0), rotationopened=vector3(0,0,90), opened=false},
        
        {handler=nil, objectname="sf_p_mp_yacht_door",
         coords=vector3(-4.803,-4.518,6.527), rotation=vector3(0,0,180), rotationopened=vector3(0,0,270), opened=false},
        
        {handler=nil, objectname="sf_p_mp_yacht_door",
         coords=vector3(-4.597,2.122,6.527), rotation=vector3(0,0,180), rotationopened=vector3(0,0,270), opened=false},
        
        {handler=nil, objectname="as_yacht_int_doors_1",
         coords=vector3(-3.343,14.919,6.47), rotation=vector3(0,0,-160), rotationopened=vector3(0,0,-70), opened=false},
        
        {handler=nil, objectname="as_yacht_int_doors_1",
         coords=vector3(-2.55,4.067,6.47), rotation=vector3(0,0,-160), rotationopened=vector3(0,0,-70), opened=false},
        
        {handler=nil, objectname="as_yacht_int_doors_1",
         coords=vector3(-3.343,17.287,6.47), rotation=vector3(0,0,-160), rotationopened=vector3(0,0,-70), opened=false},
        
        {handler=nil, objectname="as_yacht_int_doors_2",
         coords=vector3(0.224,18.263,6.262), rotation=vector3(0,0,135), rotationopened=vector3(0,0,225), opened=false},
        
        {handler=nil, objectname="as_yacht_int_doors_1",
         coords=vector3(-3.343,23.339,6.47), rotation=vector3(0,0,-160), rotationopened=vector3(0,0,-70), opened=false},
        
        {handler=nil, objectname="as_yacht_int_doors_2",
         coords=vector3(5.071,28.801,6.265), rotation=vector3(0,0,90), rotationopened=vector3(0,0,180), opened=false},
        
        {handler=nil, objectname="as_yacht_int_doors_1",
         coords=vector3(-5.038,32.619,6.449), rotation=vector3(0,0,-70), rotationopened=vector3(0,0,20), opened=false},
        
        {handler=nil, objectname="as_yacht_int_doors_1",
         coords=vector3(1.247,38.011,6.449), rotation=vector3(0,0,-160), rotationopened=vector3(0,0,-70), opened=false},
        
        {handler=nil, objectname="as_yacht_int_doors_1",
         coords=vector3(3.683,22.238,3.452), rotation=vector3(0,0,20), rotationopened=vector3(0,0,110), opened=false},
        
        {handler=nil, objectname="as_yacht_int_doors_1",
         coords=vector3(3.683,27.283,3.452), rotation=vector3(0,0,20), rotationopened=vector3(0,0,110), opened=false},
        
        {handler=nil, objectname="as_yacht_int_doors_1",
         coords=vector3(3.683,16.005,3.452), rotation=vector3(0,0,20), rotationopened=vector3(0,0,110), opened=false},
        
        {handler=nil, objectname="as_yacht_int_doors_1",
         coords=vector3(-1.019,15.56,3.452), rotation=vector3(0,0,20), rotationopened=vector3(0,0,-70), opened=false},
        
        {handler=nil, objectname="as_yacht_int_doors_1",
         coords=vector3(-1.019,21.732,3.452), rotation=vector3(0,0,20), rotationopened=vector3(0,0,-70), opened=false},
        
        {handler=nil, objectname="as_yacht_int_doors_1",
         coords=vector3(-1.235,18.328,3.452), rotation=vector3(0,0,110), rotationopened=vector3(0,0,200), opened=false},
        
        {handler=nil, objectname="as_yacht_int_doors_1",
         coords=vector3(-2.402,20.14,3.452), rotation=vector3(0,0,-70), rotationopened=vector3(0,0,20), opened=false},
        
        {handler=nil, objectname="as_yacht_int_doors_1",
         coords=vector3(-3.43,29.385,3.452), rotation=vector3(0,0,-70), rotationopened=vector3(0,0,-160), opened=false},
        
        {handler=nil, objectname="as_yacht_int_doors_1",
         coords=vector3(-6.51,29.385,3.452), rotation=vector3(0,0,-70), rotationopened=vector3(0,0,-160), opened=false},
        
        {handler=nil, objectname="as_yacht_int_doors_1",
         coords=vector3(-6.51,11.612,3.452), rotation=vector3(0,0,-70), rotationopened=vector3(0,0,20), opened=false},
        
        {handler=nil, objectname="as_apa_yacht_door_1",
         coords=vector3(-5.508,5.174,9.624), rotation=vector3(0,0,90), rotationopened=vector3(0,0,0), opened=false},
        
        {handler=nil, objectname="as_apa_yacht_door_1",
         coords=vector3(4.881,8.038,13.421), rotation=vector3(0,0,90), rotationopened=vector3(0,0,180), opened=false},
        
        {handler=nil, objectname="as_apa_yacht_door_1",
         coords=vector3(-4.974,8.038,13.421), rotation=vector3(0,0,90), rotationopened=vector3(0,0,0), opened=false},
        
        {handler=nil, objectname="as_apa_yacht_door_1",
         coords=vector3(5.427,5.174,9.624), rotation=vector3(0,0,90), rotationopened=vector3(0,0,180), opened=false},
        
        {handler=nil, objectname="as_yacht_int_doors_1",
         coords=vector3(-0.655,-18.873,6.459), rotation=vector3(0,0,-70), rotationopened=vector3(0,0,20), opened=false},
        
        {handler=nil, objectname="as_yacht_int_doors_2",
         coords=vector3(0.943,6.236,6.262), rotation=vector3(0,0,135), rotationopened=vector3(0,0,225), opened=false},
        
        {handler=nil, objectname="as_yacht_int_doors_3",
         coords=vector3(0.217,15.548,6.456), rotation=vector3(0,0,-70), rotationopened=vector3(0,0,20), opened=false},
        
        {handler=nil, objectname="as_yacht_int_door_l",
         coords=vector3(-1.013,-27.255,9.546), rotation=vector3(0,0,180), rotationopened=vector3(0,0,270), opened=false},
        
        {handler=nil, objectname="as_yacht_int_door_r",
         coords=vector3(0.893,-27.255,9.546), rotation=vector3(0,0,0), rotationopened=vector3(0,0,-90), opened=false},
        
        {handler=nil, objectname="as_yacht_int_door_s",
         coords=vector3(5.312,-16.599,9.547), rotation=vector3(0,0,90), rotationopened=vector3(0,0,0), opened=false},
        
        {handler=nil, objectname="as_yacht_int_gate_l",
         coords=vector3(-0.049,-51.949,2.058), rotation=vector3(0,0,90), rotationopened=vector3(0,0,55), opened=false, special=true, opencoords=vector3(-0.049,-53.949,2.058)},
        
        {handler=nil, objectname="as_yacht_int_gate_r",
         coords=vector3(-0.049,-51.949,2.058), rotation=vector3(0,0,90), rotationopened=vector3(0,0,125), opened=false, special=true, opencoords=vector3(-0.049,-53.949,2.058)},
        
        {handler=nil, objectname="as_apa_mp_apa_yacht_door_cap",
         coords=vector3(-1.19,0.081,12.56), rotation=vector3(0,0,-90), rotationopened=vector3(0,0,0), opened=false},
        
        {handler=nil, objectname="as_apa_mp_apa_yacht_door_cap",
         coords=vector3(1.138,0.081,12.56), rotation=vector3(0,0,90), rotationopened=vector3(0,0,0), opened=false},
        
        {handler=nil, objectname="as_apa_mp_apa_yacht_door_front",
         coords=vector3(0.943,42.884,7.758), rotation=vector3(0,0,90), rotationopened=vector3(0,0,0), opened=false},
        
        {handler=nil, objectname="as_apa_mp_apa_yacht_door_front",
         coords=vector3(-1.053,42.884,7.758), rotation=vector3(0,0,-90), rotationopened=vector3(0,0,0), opened=false},
        
        {handler=nil, objectname="as_yacht_int_door_saun",
         coords=vector3(-4.115,3.033,3.548), rotation=vector3(0,0,90), rotationopened=vector3(0,0,0), opened=false},
        
        {handler=nil, objectname="as_yacht_int_door_saun",
         coords=vector3(-5.047,3.966,3.548), rotation=vector3(0,0,-90), rotationopened=vector3(0,0,0), opened=false},
        
        {handler=nil, objectname="as_apa_mp_apa_yacht_door_engine",
         coords=vector3(4.696,0.734,3.831), rotation=vector3(0,0,90), rotationopened=vector3(0,0,180), opened=false},
        
        {handler=nil, objectname="as_apa_mp_apa_yacht_door_engine",
         coords=vector3(2.805,0.734,3.831), rotation=vector3(0,0,-90), rotationopened=vector3(0,0,-180), opened=false},
    },

    flagdata = {
        flagid  = 1,
        handler = nil,
        coords  = vector3(0.0, 56.55, 20.5),
        rotation = vector3(0.0, 130.0, 0.0),
    },

    lighting = {
        lightingcategory = 1,
        lightingid       = 1,
        handler          = nil,
        coords           = vector3(0, 0, 14.5),
        rotation         = vector3(0, 0, 0),
    },

    railing = {
        railingid = 1,
        handler   = nil,
        handler2  = nil,
        coords    = vector3(0, 0, 14.57),
        rotation  = vector3(0, 0, 0),
    },

    textdata = {
        uppertext  = "",
        bottomtext = "",
    },

    yachtcolor = 1,
}

function IsPreviewSessionActive(sessionId)
    return isYachtBuyMenuOpen and sessionId == previewSessionId
end

function WaitForPreviewModel(modelHash, modelName, sessionId)
    if not IsModelInCdimage(modelHash) or not IsModelValid(modelHash) then
        print(("^1AS Yacht^7: preview model is unavailable: %s. Ensure as_yachtobjects starts before as-yacht."):format(modelName))
        return false
    end

    local startedAt = GetGameTimer()
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        if not IsPreviewSessionActive(sessionId) then return false end
        if GetGameTimer() - startedAt >= 15000 then
            print(("^1AS Yacht^7: timed out loading preview model: %s"):format(modelName))
            print(("^1AS Yacht^7: debug %s -> inCdimage=%s valid=%s isVehicle=%s isBoat=%s"):format(modelName,
                tostring(IsModelInCdimage(modelHash)), tostring(IsModelValid(modelHash)),
                tostring(IsModelAVehicle(modelHash)), tostring(IsThisModelABoat(modelHash))))
            return false
        end
        RequestModel(modelHash)
        Citizen.Wait(0)
    end

    return true
end

-- Position for a boat / jet ski: the vehicle is pushed out along its own heading so its tail starts at the
-- parking spot instead of its centre (otherwise long boats end up half inside the yacht).
function TenderSpawnCoords(entity, off, hash, air, cfg)
    local p = GetOffsetFromEntityInWorldCoords(entity, off.x, off.y, off.z)
    local heading = GetEntityHeading(entity) + (air and 0.0 or (cfg.slotHeading or 0.0))
    if not air and (cfg.slotPush or 0.0) > 0.0 then
        local minD, maxD = GetModelDimensions(hash)
        local halfLen = (maxD.y - minD.y) / 2.0
        local rad = math.rad(heading)
        p = vector3(p.x - math.sin(rad) * halfLen * cfg.slotPush, p.y + math.cos(rad) * halfLen * cfg.slotPush, p.z)
    end
    return p, heading
end

previewTenders = {}   -- local, frozen copies of the vehicles picked in the buy menu
previewTenderToken = 0

function ClearPreviewTenders()
    previewTenderToken = previewTenderToken + 1
    for _, veh in ipairs(previewTenders) do
        if DoesEntityExist(veh) then DeleteEntity(veh) end
    end
    previewTenders = {}
end

function ClearYachtBuyPreview(sessionId)
    if sessionId ~= nil and sessionId ~= previewSessionId then return end
    ClearPreviewTenders()

    for _, door in ipairs(yachtBuyState.doors) do
        if DoesEntityExist(door.handler) then DeleteEntity(door.handler) end
        door.handler = nil
    end
    for _, obj in ipairs(yachtBuyState.mainobjects) do
        if DoesEntityExist(obj.handler) then DeleteEntity(obj.handler) end
        obj.handler = nil
    end

    if DoesEntityExist(yachtBuyState.flagdata.handler) then DeleteEntity(yachtBuyState.flagdata.handler) end
    if DoesEntityExist(yachtBuyState.lighting.handler) then DeleteEntity(yachtBuyState.lighting.handler) end
    if DoesEntityExist(yachtBuyState.railing.handler) then DeleteEntity(yachtBuyState.railing.handler) end
    if DoesEntityExist(yachtBuyState.railing.handler2) then DeleteEntity(yachtBuyState.railing.handler2) end
    if DoesEntityExist(yachtBuyState.yachtbuyobject) then DeleteEntity(yachtBuyState.yachtbuyobject) end

    yachtBuyState.flagdata.handler = nil
    yachtBuyState.lighting.handler = nil
    yachtBuyState.railing.handler = nil
    yachtBuyState.railing.handler2 = nil
    yachtBuyState.yachtbuyobject = nil
end
