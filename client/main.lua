if IsDuplicityVersion() then
    GetPlayerPositionInRealTime104()
end

ESX = nil
QBCore = nil

local Lang = (Language and (Language[Config.Language] or Language["English"])) or {}

local drivingState = {
    driving    = false,
    drivingid  = nil,
    yachthandler = nil,
}

local isYachtBuyMenuOpen = false
local buyPending = false
local yachtExtras = {}   -- [yachtId] = { enginetier, storagetier, ... } from the server
local yachtFuel = {}     -- [yachtId] = live fuel % (sent to the driver while sailing)
local previewEnv = {}     -- { hour = n, weather = "TYPE" } chosen in the buy menu

local buyHudHidden = false -- true while we have the HUD hidden for the buy menu
local previewEnvTouched = false -- set once we override time/weather, so we always undo it

local function ClearPreviewEnv()
    if previewEnv.weather or previewEnvTouched then ClearOverrideWeather() end
    if previewEnv.hour or previewEnvTouched then NetworkClearClockTimeOverride() end
    previewEnv = {}
    previewEnvTouched = false
end

-- never leave a time/weather override behind if the resource restarts mid-preview
AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if previewEnvTouched then
        ClearOverrideWeather()
        NetworkClearClockTimeOverride()
    end
    if buyHudHidden then
        buyHudHidden = false
        pcall(SetYachtHudVisible, true)
    end
end)


local previewSessionId = 0
local previewLightRequestId = 0

local buyCameraMain = nil
local buyCameraAlt  = nil

local activeCameraIndex = 1

local currentYachtColorIndex = 1

local currentBuyCameraIndex  = 1

local isCameraTransitioning = false

local hasBuyBlipCreated = false
local yachtBuyBlip = nil

local yachtBlips = {}
local yachtIntroPlayed = {}

local currentNearYachtId = nil

local currentNearDoorIndex = nil

local currentNearStorageIndex   = nil
local currentNearWardrobeIndex  = nil
local currentNearManageZoneId   = nil
local currentNearDriveZoneId    = nil
local currentNearHottubIndex    = nil

local isManagementMenuOpen   = false
local managementMenuYachtId  = nil


local isFurnitureMenuOpen       = false
local isFurniturePlacementActive = false
local furnitureMenuYachtId       = nil
local isGizmoActive             = false

local pendingFurniturePurchase   = nil

local noClipActive = false
local furnitureCamera = nil
local noClipPed = nil
local playerPositionBeforeFurniture = nil

local furnitureSpeedsLookX = {
    {speeddata = 0.0}, {speeddata = 0.1}, {speeddata = 0.2}, {speeddata = 0.3}, {speeddata = 0.4},
    {speeddata = 0.5}, {speeddata = 0.6}, {speeddata = 0.7}, {speeddata = 0.8}, {speeddata = 0.9},
    {speeddata = 1.0}, {speeddata = 1.1}, {speeddata = 1.2}, {speeddata = 1.3}, {speeddata = 1.4},
    {speeddata = 1.5}, {speeddata = 1.6}, {speeddata = 1.7}, {speeddata = 1.8}, {speeddata = 1.9}
}

local furnitureSpeedsLookY = {
    {speeddata = 0.0}, {speeddata = 0.02}, {speeddata = 0.04}, {speeddata = 0.06}, {speeddata = 0.08},
    {speeddata = 0.1},  {speeddata = 0.2},  {speeddata = 0.3},  {speeddata = 0.4},  {speeddata = 0.5},
    {speeddata = 0.6},  {speeddata = 0.7},  {speeddata = 0.8},  {speeddata = 0.9},  {speeddata = 1.0},
    {speeddata = 1.1},  {speeddata = 1.2},  {speeddata = 1.3},  {speeddata = 1.4},  {speeddata = 1.5}
}

local furnitureSpeedsCamera = {
    {speeddata = 0.0}, {speeddata = 0.1}, {speeddata = 0.2}, {speeddata = 0.3}, {speeddata = 0.4},
    {speeddata = 0.5}, {speeddata = 0.6}, {speeddata = 0.7}, {speeddata = 0.8}, {speeddata = 0.9},
    {speeddata = 1.0}, {speeddata = 1.1}, {speeddata = 1.2}, {speeddata = 1.3}, {speeddata = 1.4},
    {speeddata = 1.5}, {speeddata = 1.6}, {speeddata = 1.7}, {speeddata = 1.8}, {speeddata = 1.9}
}

local furnitureTranslateSnaps = {
    {snapdata = 0.1}, {snapdata = 0.2}, {snapdata = 0.3}, {snapdata = 0.4}, {snapdata = 0.5},
    {snapdata = 0.6}, {snapdata = 0.7}, {snapdata = 0.8}, {snapdata = 0.9}, {snapdata = 1.0}
}

local furnitureRotateSnaps = {
    {snapdata = 0.1}, {snapdata = 0.2}, {snapdata = 0.3}, {snapdata = 0.4}, {snapdata = 0.5},
    {snapdata = 0.6}, {snapdata = 0.7}, {snapdata = 0.8}, {snapdata = 0.9}, {snapdata = 1.0}
}

local furnitureLookXIndex = 10
local furnitureLookYIndex = 10
local furnitureSpeedIndex = 10
local furnitureTranslateSnapIndex = 1
local furnitureRotateSnapIndex = 1

local hottubSeatInfo = {
    yachtid = yachtiddata,  
    seatid  = seatiddata,
}
local isPlayerSeated          = false

function InSomeMenu()
    return not (
        isYachtBuyMenuOpen
        or isManagementMenuOpen
        or isFurnitureMenuOpen
        or isFurniturePlacementActive
        or isGizmoActive
        or isPlayerSeated
        or (LocalPlayer.state.invOpen == true)
    )
end



ESX = nil

local hasInitialized     = false
local isTargetSystemReady = false

local isPlayerNearBuyLocation = false


local yachtModelHash = GetHashKey("as_yacht_veh")


local flagObjectsList = {
    [1]  = {flagobject = "apa_prop_flag_belgium"},
    [2]  = {flagobject = "apa_prop_flag_palestine"},
    [3]  = {flagobject = "apa_prop_flag_jamaica"},
    [4]  = {flagobject = "apa_prop_flag_newzealand"},
    [5]  = {flagobject = "apa_prop_flag_southafrica"},
    [6]  = {flagobject = "apa_prop_flag_netherlands"},
    [7]  = {flagobject = "apa_prop_flag_australia"},
    [8]  = {flagobject = "apa_prop_flag_lstein"},
    [9]  = {flagobject = "apa_prop_flag_denmark"},
    [10] = {flagobject = "apa_prop_flag_hungary"},
    [11] = {flagobject = "apa_prop_flag_eu_yt"},
    [12] = {flagobject = "apa_prop_flag_sweden"},
    [13] = {flagobject = "apa_prop_flag_german_yt"},
    [14] = {flagobject = "apa_prop_flag_us_yt"},
    [15] = {flagobject = "apa_prop_flag_norway"},
    [16] = {flagobject = "apa_prop_flag_china"},
    [17] = {flagobject = "apa_prop_flag_uk_yt"},
    [18] = {flagobject = "apa_prop_flag_switzerland"},
    [19] = {flagobject = "apa_prop_flag_puertorico"},
    [20] = {flagobject = "apa_prop_flag_russia_yt"},
    [21] = {flagobject = "apa_prop_flag_slovenia"},
    [22] = {flagobject = "apa_prop_flag_portugal"},
    [23] = {flagobject = "apa_prop_flag_slovakia"},
    [24] = {flagobject = "apa_prop_flag_turkey"},
    [25] = {flagobject = "apa_prop_flag_nigeria"},
    [26] = {flagobject = "apa_prop_flag_colombia"},
    [27] = {flagobject = "apa_prop_flag_austria"},
    [28] = {flagobject = "apa_prop_flag_croatia"},
    [29] = {flagobject = "apa_prop_flag_finland"},
    [30] = {flagobject = "apa_prop_flag_brazil"},
    [31] = {flagobject = "apa_prop_flag_france"},
    [32] = {flagobject = "apa_prop_flag_czechrep"},
    [33] = {flagobject = "apa_prop_flag_italy"},
    [34] = {flagobject = "apa_prop_flag_spain"},
    [35] = {flagobject = "apa_prop_flag_israel"},
    [36] = {flagobject = "apa_prop_flag_malta"},
    [37] = {flagobject = "apa_prop_flag_poland"},
    [38] = {flagobject = "apa_prop_flag_ireland"},
    [39] = {flagobject = "apa_prop_flag_england"},
    [40] = {flagobject = "apa_prop_flag_argentina"},
    [41] = {flagobject = "apa_prop_flag_scotland_yt"},
    [42] = {flagobject = "apa_prop_flag_mexico_yt"},
    [43] = {flagobject = "apa_prop_flag_canada_yt"},
    [44] = {flagobject = "apa_prop_flag_wales"},
    [45] = {flagobject = "apa_prop_flag_southkorea"},
    [46] = {flagobject = "apa_prop_flag_japan_yt"},
}


local anchorRailingTypesList = {
    [1] = {railingobject = "apa_mp_apa_yacht_o3_rail_a_anchor"},
    [2] = {railingobject = "apa_mp_apa_yacht_o3_rail_b_anchor"},
}
-- Extra railing colours (ids 3+) reuse the silver model; the colour itself comes from GetRailingColour.
setmetatable(anchorRailingTypesList, { __index = function(t, k) return rawget(t, 1) end })

function GetLightColorObject(category, colorId)
    local defaultObject = "rtx_apa_mp_apa_y3_l2a"

    if category == 1 then
        local l2Options = {
            {lightobject = "rtx_apa_mp_apa_y3_l2a"},
            {lightobject = "rtx_apa_mp_apa_y3_l2b"},
            {lightobject = "rtx_apa_mp_apa_y3_l2c"},
            {lightobject = "rtx_apa_mp_apa_y3_l2d"},
            {lightobject = "rtx_apa_mp_apa_y3_l2p"},
            {lightobject = "rtx_apa_mp_apa_y3_l2r"},
            {lightobject = "rtx_apa_mp_apa_y3_l2o"},
            {lightobject = "rtx_apa_mp_apa_y3_l2w"},
        }
        local opt = l2Options[colorId]
        return opt and opt.lightobject or defaultObject
    elseif category == 2 then
        local l1Options = {
            {lightobject = "rtx_apa_mp_apa_y3_l1a"},
            {lightobject = "rtx_apa_mp_apa_y3_l1b"},
            {lightobject = "rtx_apa_mp_apa_y3_l1c"},
            {lightobject = "rtx_apa_mp_apa_y3_l1d"},
            {lightobject = "rtx_apa_mp_apa_y3_l1p"},
            {lightobject = "rtx_apa_mp_apa_y3_l1r"},
            {lightobject = "rtx_apa_mp_apa_y3_l1o"},
            {lightobject = "rtx_apa_mp_apa_y3_l1w"},
        }
        local opt = l1Options[colorId]
        return opt and opt.lightobject or defaultObject
    end

    return defaultObject
end

-- GTA colour ID used to tint the railing for a given railing type
function GetRailingColour(railingId)
    local r = Config.RailingTypes[railingId] or Config.RailingTypes[1]
    return r.colour
end

local yachtNameRenderState = {
    renderdata = {-1, -1, -1},  
    moviedata  = -1,
    generated  = 0,             
    yachtid    = 1,
    upper      = nil,
    bottom     = nil,
}

-- Releases the render targets + movie so the next yacht/preview relinks cleanly
function ResetYachtName()
    local s = yachtNameRenderState
    if s.moviedata ~= -1 then
        SetScaleformMovieAsNoLongerNeeded(s.moviedata)
    end
    for _, name in ipairs({"stern_text", "starb_text", "port_text"}) do
        if IsNamedRendertargetRegistered(name) then ReleaseNamedRendertarget(name) end
    end
    s.renderdata = {-1, -1, -1}
    s.moviedata  = -1
    s.generated  = 0
    s.yachtid    = -1
    s.upper      = nil
    s.bottom     = nil
end

local function PushYachtName(upperText, bottomText)
    local s = yachtNameRenderState
    SetupScaleform(s.moviedata, "SET_YACHT_NAME", {
        p0 = {type = "string", value = tostring(upperText or "")},
        p1 = {type = "int",    value = 1},
        p2 = {type = "string", value = tostring(bottomText or "")},
    })
    s.upper, s.bottom = upperText, bottomText
end

function DrawYachtName(upperText, bottomText, targetYachtId)
    if yachtNameRenderState.yachtid == targetYachtId then

        if yachtNameRenderState.generated == 0 then
            local rd = yachtNameRenderState.renderdata
            rd[1] = CreateNamedRenderTargetForModel("stern_text",  GetHashKey("apa_prop_ap_stern_text"))
            rd[2] = CreateNamedRenderTargetForModel("starb_text",  GetHashKey("apa_prop_ap_starb_text"))
            rd[3] = CreateNamedRenderTargetForModel("port_text",   GetHashKey("apa_prop_ap_port_text"))
            yachtNameRenderState.moviedata  = RequestScaleformMovie("YACHT_NAME")
            yachtNameRenderState.generated  = 1

        elseif yachtNameRenderState.generated == 1 then
            if HasScaleformMovieLoaded(yachtNameRenderState.moviedata) then
                PushYachtName(upperText, bottomText)
                yachtNameRenderState.generated = 2
            else
                
                yachtNameRenderState.moviedata = RequestScaleformMovie("YACHT_NAME")
            end

        elseif yachtNameRenderState.generated == 2 then
            -- text changed (typed in the buy menu, or yacht data updated) -> re-send it
            if yachtNameRenderState.upper ~= upperText or yachtNameRenderState.bottom ~= bottomText then
                PushYachtName(upperText, bottomText)
            end
            for _, renderId in ipairs(yachtNameRenderState.renderdata) do
                SetTextRenderId(renderId)
                SetUiLayer(4)
                N_0xc6372ecd45d73bcd(true)
                ScreenDrawPositionBegin(73, 73)
                DrawScaleformMovie(
                    yachtNameRenderState.moviedata,
                    0.38, 0.245, 1.0, 1.0,
                    255, 255, 255, 255, 0
                )
                SetTextRenderId(GetDefaultScriptRendertargetRenderId())
                ScreenDrawPositionEnd()
            end
        end
    else
        
        yachtNameRenderState.renderdata = {-1, -1, -1}
        yachtNameRenderState.moviedata  = -1
        yachtNameRenderState.generated  = 0
        yachtNameRenderState.yachtid    = targetYachtId
    end
end

function CreateNamedRenderTargetForModel(name, modelHash)
    local renderId = 0
    if not IsNamedRendertargetRegistered(name) then
        RegisterNamedRendertarget(name, false)
    end
    if not IsNamedRendertargetLinked(modelHash) then
        LinkNamedRendertarget(modelHash)
    end
    if IsNamedRendertargetRegistered(name) then
        renderId = GetNamedRendertargetRenderId(name)
    end
    return renderId
end

function SetupScaleform(movieHandle, methodName, params)
    BeginScaleformMovieMethod(movieHandle, methodName)
    if IsTable(params) then
        for i = 0, Tablelength(params) - 1 do
            local key   = "p" .. tostring(i)
            local entry = params[key]
            if     entry.type == "bool"       then PushScaleformMovieMethodParameterBool(entry.value)
            elseif entry.type == "int"        then PushScaleformMovieMethodParameterInt(entry.value)
            elseif entry.type == "float"      then PushScaleformMovieMethodParameterFloat(entry.value)
            elseif entry.type == "string"     then PushScaleformMovieMethodParameterString(entry.value)
            elseif entry.type == "buttonName" then PushScaleformMovieMethodParameterButtonName(entry.value)
            end
        end
    end
    EndScaleformMovieMethod()
    N_0x32f34ff7f617643b(movieHandle, 1)
end

function IsTable(value)
    return type(value) == "table"
end

function Tablelength(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

function CheckIfFurnitureIsInYachtNearby(yachtId, worldPos)
    local rawCoords = GlobalState["asyacht-" .. yachtId .. "-coords"]
    if not rawCoords then return false end
    local yachtCoords = vector3(rawCoords.x, rawCoords.y, rawCoords.z)
    local dist = #(worldPos - yachtCoords)
    return dist < 70.0
end

function GetRotationOffsetBetweenEntities(entity1, entity2)
    local rot1 = GetEntityRotation(entity1, 2)
    local rot2 = GetEntityRotation(entity2, 2)
    return vector3(
        rot2.x - rot1.x,
        rot2.y - rot1.y,
        rot2.z - rot1.z
    )
end


function ShowGtaClassicInteraction(text)
    AddTextEntry("gtavclassicinteractionasyacht", text)
    BeginTextCommandDisplayHelp("gtavclassicinteractionasyacht")
    EndTextCommandDisplayHelp(0, false, true, -1)
end

yachts = {}

local yachtBuyState = {
    yachtbuyobject = nil,

    mainobjects = {
        {handler=nil, objectname="djn_yacht_bar_details",              offsetcoords=vector3(-2.0496, 8.28e-4, 5.87994), offsetrotation=vector3(0,0,90)},
        {handler=nil, objectname="djn_yacht_bridge_details",           offsetcoords=vector3(-2.0496, 8.28e-4, 5.87994), offsetrotation=vector3(0,0,90)},
        {handler=nil, objectname="djn_yacht_engine_details_room_1",    offsetcoords=vector3(-2.0496, 8.28e-4, 5.87994), offsetrotation=vector3(0,0,90)},
        {handler=nil, objectname="djn_yacht_engine_details_room_2",    offsetcoords=vector3(-2.0496, 8.28e-4, 5.87994), offsetrotation=vector3(0,0,90)},
        {handler=nil, objectname="djn_yacht_engine_room_entry",        offsetcoords=vector3(-2.0496, 8.28e-4, 5.87994), offsetrotation=vector3(0,0,90)},
        {handler=nil, objectname="djn_yacht_int_wellness_rooms_details",offsetcoords=vector3(-2.0496, 8.28e-4, 5.87994), offsetrotation=vector3(0,0,90)},
        {handler=nil, objectname="djn_yacht_main_hall",                offsetcoords=vector3(-2.0496, 8.28e-4, 5.87994), offsetrotation=vector3(0,0,90)},
        {handler=nil, objectname="djn_yacht_room1_details",            offsetcoords=vector3(-2.0496, 8.28e-4, 5.87994), offsetrotation=vector3(0,0,90)},
        {handler=nil, objectname="djn_yacht_room2_details",            offsetcoords=vector3(-2.0496, 8.28e-4, 5.87994), offsetrotation=vector3(0,0,90)},
        {handler=nil, objectname="djn_yacht_room3_details",            offsetcoords=vector3(-2.0496, 8.28e-4, 5.87994), offsetrotation=vector3(0,0,90)},
        {handler=nil, objectname="djn_yachta_entry_room_details",      offsetcoords=vector3(-2.0496, 8.28e-4, 5.87994), offsetrotation=vector3(0,0,90)},
        
        {handler=nil, objectname="apa_prop_ap_stern_text",  offsetcoords=vector3(-2.0,  -0.65, 17.1), offsetrotation=vector3(10,0,90)},
        {handler=nil, objectname="apa_prop_ap_starb_text",  offsetcoords=vector3(-2.05,  0.0,   5.8), offsetrotation=vector3(0,0,90)},
        {handler=nil, objectname="apa_prop_ap_port_text",   offsetcoords=vector3(-2.05,  0.0,   5.8), offsetrotation=vector3(0,0,90)},
        
        {handler=nil, objectname="apa_mp_apa_yacht_win",    offsetcoords=vector3(-2.05,  0.0,   5.9), offsetrotation=vector3(0,0,90)},
        {handler=nil, objectname="djn_apa_mp_apa_yacht_option3", offsetcoords=vector3(0,0,0),         offsetrotation=vector3(0,0,0)},
        
        {handler=nil, objectname="rtx_apa_mp_apa_yacht_jacuzzi_ripple1", offsetcoords=vector3(0,-51,6), offsetrotation=vector3(0,0,0)},
    },

    doors = {
        
        {handler=nil, objectname="apa_mp_apa_yacht_door",
         coords=vector3(-0.769,-36.827,6.536), rotation=vector3(0,0,0), rotationopened=vector3(0,0,90), opened=false},
        
        {handler=nil, objectname="sf_p_mp_yacht_door",
         coords=vector3(-4.803,-4.518,6.527), rotation=vector3(0,0,180), rotationopened=vector3(0,0,270), opened=false},
        
        {handler=nil, objectname="sf_p_mp_yacht_door",
         coords=vector3(-4.597,2.122,6.527), rotation=vector3(0,0,180), rotationopened=vector3(0,0,270), opened=false},
        
        {handler=nil, objectname="rtx_djn_yacht_int_doors_1",
         coords=vector3(-3.343,14.919,6.47), rotation=vector3(0,0,-160), rotationopened=vector3(0,0,-70), opened=false},
        
        {handler=nil, objectname="rtx_djn_yacht_int_doors_1",
         coords=vector3(-2.55,4.067,6.47), rotation=vector3(0,0,-160), rotationopened=vector3(0,0,-70), opened=false},
        
        {handler=nil, objectname="rtx_djn_yacht_int_doors_1",
         coords=vector3(-3.343,17.287,6.47), rotation=vector3(0,0,-160), rotationopened=vector3(0,0,-70), opened=false},
        
        {handler=nil, objectname="rtx_djn_yacht_int_doors_2",
         coords=vector3(0.224,18.263,6.262), rotation=vector3(0,0,135), rotationopened=vector3(0,0,225), opened=false},
        
        {handler=nil, objectname="rtx_djn_yacht_int_doors_1",
         coords=vector3(-3.343,23.339,6.47), rotation=vector3(0,0,-160), rotationopened=vector3(0,0,-70), opened=false},
        
        {handler=nil, objectname="rtx_djn_yacht_int_doors_2",
         coords=vector3(5.071,28.801,6.265), rotation=vector3(0,0,90), rotationopened=vector3(0,0,180), opened=false},
        
        {handler=nil, objectname="rtx_djn_yacht_int_doors_1",
         coords=vector3(-5.038,32.619,6.449), rotation=vector3(0,0,-70), rotationopened=vector3(0,0,20), opened=false},
        
        {handler=nil, objectname="rtx_djn_yacht_int_doors_1",
         coords=vector3(1.247,38.011,6.449), rotation=vector3(0,0,-160), rotationopened=vector3(0,0,-70), opened=false},
        
        {handler=nil, objectname="rtx_djn_yacht_int_doors_1",
         coords=vector3(3.683,22.238,3.452), rotation=vector3(0,0,20), rotationopened=vector3(0,0,110), opened=false},
        
        {handler=nil, objectname="rtx_djn_yacht_int_doors_1",
         coords=vector3(3.683,27.283,3.452), rotation=vector3(0,0,20), rotationopened=vector3(0,0,110), opened=false},
        
        {handler=nil, objectname="rtx_djn_yacht_int_doors_1",
         coords=vector3(3.683,16.005,3.452), rotation=vector3(0,0,20), rotationopened=vector3(0,0,110), opened=false},
        
        {handler=nil, objectname="rtx_djn_yacht_int_doors_1",
         coords=vector3(-1.019,15.56,3.452), rotation=vector3(0,0,20), rotationopened=vector3(0,0,-70), opened=false},
        
        {handler=nil, objectname="rtx_djn_yacht_int_doors_1",
         coords=vector3(-1.019,21.732,3.452), rotation=vector3(0,0,20), rotationopened=vector3(0,0,-70), opened=false},
        
        {handler=nil, objectname="rtx_djn_yacht_int_doors_1",
         coords=vector3(-1.235,18.328,3.452), rotation=vector3(0,0,110), rotationopened=vector3(0,0,200), opened=false},
        
        {handler=nil, objectname="rtx_djn_yacht_int_doors_1",
         coords=vector3(-2.402,20.14,3.452), rotation=vector3(0,0,-70), rotationopened=vector3(0,0,20), opened=false},
        
        {handler=nil, objectname="rtx_djn_yacht_int_doors_1",
         coords=vector3(-3.43,29.385,3.452), rotation=vector3(0,0,-70), rotationopened=vector3(0,0,-160), opened=false},
        
        {handler=nil, objectname="rtx_djn_yacht_int_doors_1",
         coords=vector3(-6.51,29.385,3.452), rotation=vector3(0,0,-70), rotationopened=vector3(0,0,-160), opened=false},
        
        {handler=nil, objectname="rtx_djn_yacht_int_doors_1",
         coords=vector3(-6.51,11.612,3.452), rotation=vector3(0,0,-70), rotationopened=vector3(0,0,20), opened=false},
        
        {handler=nil, objectname="rtx_djn_apa_yacht_door_1",
         coords=vector3(-5.508,5.174,9.624), rotation=vector3(0,0,90), rotationopened=vector3(0,0,0), opened=false},
        
        {handler=nil, objectname="rtx_djn_apa_yacht_door_1",
         coords=vector3(4.881,8.038,13.421), rotation=vector3(0,0,90), rotationopened=vector3(0,0,180), opened=false},
        
        {handler=nil, objectname="rtx_djn_apa_yacht_door_1",
         coords=vector3(-4.974,8.038,13.421), rotation=vector3(0,0,90), rotationopened=vector3(0,0,0), opened=false},
        
        {handler=nil, objectname="rtx_djn_apa_yacht_door_1",
         coords=vector3(5.427,5.174,9.624), rotation=vector3(0,0,90), rotationopened=vector3(0,0,180), opened=false},
        
        {handler=nil, objectname="rtx_djn_yacht_int_doors_1",
         coords=vector3(-0.655,-18.873,6.459), rotation=vector3(0,0,-70), rotationopened=vector3(0,0,20), opened=false},
        
        {handler=nil, objectname="rtx_djn_yacht_int_doors_2",
         coords=vector3(0.943,6.236,6.262), rotation=vector3(0,0,135), rotationopened=vector3(0,0,225), opened=false},
        
        {handler=nil, objectname="rtx_djn_yacht_int_doors_3",
         coords=vector3(0.217,15.548,6.456), rotation=vector3(0,0,-70), rotationopened=vector3(0,0,20), opened=false},
        
        {handler=nil, objectname="rtx_djn_yacht_int_door_l",
         coords=vector3(-1.013,-27.255,9.546), rotation=vector3(0,0,180), rotationopened=vector3(0,0,270), opened=false},
        
        {handler=nil, objectname="rtx_djn_yacht_int_door_r",
         coords=vector3(0.893,-27.255,9.546), rotation=vector3(0,0,0), rotationopened=vector3(0,0,-90), opened=false},
        
        {handler=nil, objectname="rtx_djn_yacht_int_door_s",
         coords=vector3(5.312,-16.599,9.547), rotation=vector3(0,0,90), rotationopened=vector3(0,0,0), opened=false},
        
        {handler=nil, objectname="rtx_djn_yacht_int_gate_l",
         coords=vector3(-0.049,-51.949,2.058), rotation=vector3(0,0,90), rotationopened=vector3(0,0,55), opened=false, special=true, opencoords=vector3(-0.049,-53.949,2.058)},
        
        {handler=nil, objectname="rtx_djn_yacht_int_gate_r",
         coords=vector3(-0.049,-51.949,2.058), rotation=vector3(0,0,90), rotationopened=vector3(0,0,125), opened=false, special=true, opencoords=vector3(-0.049,-53.949,2.058)},
        
        {handler=nil, objectname="rtx_apa_mp_apa_yacht_door_cap",
         coords=vector3(-1.19,0.081,12.56), rotation=vector3(0,0,-90), rotationopened=vector3(0,0,0), opened=false},
        
        {handler=nil, objectname="rtx_apa_mp_apa_yacht_door_cap",
         coords=vector3(1.138,0.081,12.56), rotation=vector3(0,0,90), rotationopened=vector3(0,0,0), opened=false},
        
        {handler=nil, objectname="rtx_apa_mp_apa_yacht_door_front",
         coords=vector3(0.943,42.884,7.758), rotation=vector3(0,0,90), rotationopened=vector3(0,0,0), opened=false},
        
        {handler=nil, objectname="rtx_apa_mp_apa_yacht_door_front",
         coords=vector3(-1.053,42.884,7.758), rotation=vector3(0,0,-90), rotationopened=vector3(0,0,0), opened=false},
        
        {handler=nil, objectname="rtx_djn_yacht_int_door_saun",
         coords=vector3(-4.115,3.033,3.548), rotation=vector3(0,0,90), rotationopened=vector3(0,0,0), opened=false},
        
        {handler=nil, objectname="rtx_djn_yacht_int_door_saun",
         coords=vector3(-5.047,3.966,3.548), rotation=vector3(0,0,-90), rotationopened=vector3(0,0,0), opened=false},
        
        {handler=nil, objectname="rtx_apa_mp_apa_yacht_door_engine",
         coords=vector3(4.696,0.734,3.831), rotation=vector3(0,0,90), rotationopened=vector3(0,0,180), opened=false},
        
        {handler=nil, objectname="rtx_apa_mp_apa_yacht_door_engine",
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

local function IsPreviewSessionActive(sessionId)
    return isYachtBuyMenuOpen and sessionId == previewSessionId
end

local function WaitForPreviewModel(modelHash, modelName, sessionId)
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
local function TenderSpawnCoords(entity, off, hash, air, cfg)
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

local previewTenders = {}   -- local, frozen copies of the vehicles picked in the buy menu
local previewTenderToken = 0

local function ClearPreviewTenders()
    previewTenderToken = previewTenderToken + 1
    for _, veh in ipairs(previewTenders) do
        if DoesEntityExist(veh) then DeleteEntity(veh) end
    end
    previewTenders = {}
end

local function ClearYachtBuyPreview(sessionId)
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

function CreateYachtBuyBlip()
    if hasBuyBlipCreated then return end
    hasBuyBlipCreated = true

    local blipCfg = Config.YachtBuyLocation
    local blip = AddBlipForCoord(blipCfg.coords.x, blipCfg.coords.y, blipCfg.coords.z)
    yachtBuyBlip = blip
    SetBlipSprite(blip, blipCfg.blip.blipiconid)
    SetBlipDisplay(blip, blipCfg.blip.blipdisplay)
    SetBlipScale(blip, blipCfg.blip.blipscale)
    SetBlipColour(blip, blipCfg.blip.blipcolor)
    SetBlipAsShortRange(blip, blipCfg.blip.blipshortrange)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(blipCfg.blip.bliptext)
    EndTextCommandSetBlipName(blip)
end

function YachtBlipLabel(yachtId)
    local cfg = Config.YachtBuyLocation.personalblip
    local y = yachts["yacht-" .. yachtId]
    if cfg.showyachtname and y and y.textdata and (y.textdata.uppertext or "") ~= "" then
        local name = ((y.textdata.uppertext or "") .. " " .. (y.textdata.bottomtext or "")):gsub("%s+$", "")
        return cfg.bliptext .. ": " .. name
    end
    return cfg.bliptext
end

function RefreshYachtBlipName(yachtId)
    local blip = yachtBlips[yachtId]
    if blip and DoesBlipExist(blip) then
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(YachtBlipLabel(yachtId))
        EndTextCommandSetBlipName(blip)
    end
end

function CreatePersonalYachtBlip(yachtId)
    local personalBlipCfg = Config.YachtBuyLocation.personalblip
    local key = "yacht-" .. yachtId

    if yachtBlips[yachtId] ~= nil then
        if not DoesBlipExist(yachtBlips[yachtId]) then
            local blip = AddBlipForEntity(yachts[key].yachtmainobject)
            yachtBlips[yachtId] = blip
            SetBlipSprite(blip, personalBlipCfg.blipiconid)
            SetBlipDisplay(blip, personalBlipCfg.blipdisplay)
            SetBlipScale(blip, personalBlipCfg.blipscale)
            SetBlipColour(blip, personalBlipCfg.blipcolor)
            SetBlipAsShortRange(blip, personalBlipCfg.blipshortrange)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName(YachtBlipLabel(yachtId))
            EndTextCommandSetBlipName(blip)
        end
    end

    if yachtBlips[yachtId] == nil then
        local blip = AddBlipForEntity(yachts[key].yachtmainobject)
        yachtBlips[yachtId] = blip
        SetBlipSprite(blip, personalBlipCfg.blipiconid)
        SetBlipDisplay(blip, personalBlipCfg.blipdisplay)
        SetBlipScale(blip, personalBlipCfg.blipscale)
        SetBlipColour(blip, personalBlipCfg.blipcolor)
        SetBlipAsShortRange(blip, personalBlipCfg.blipshortrange)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(YachtBlipLabel(yachtId))
        EndTextCommandSetBlipName(blip)
    end
end

function RemovePersonalYachtBlip(yachtId)
    if yachtBlips[yachtId] ~= nil then
        RemoveBlip(yachtBlips[yachtId])
        yachtBlips[yachtId] = nil
    end
end

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
        if objData.objectname == "djn_apa_mp_apa_yacht_option3" then
            
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
            {handler=nil, objectname="djn_yacht_bar_details",               offsetcoords=vector3(-2.0496, 8.28e-4, 5.87994), offsetrotation=vector3(0,0,90)},
            {handler=nil, objectname="djn_yacht_bridge_details",            offsetcoords=vector3(-2.0496, 8.28e-4, 5.87994), offsetrotation=vector3(0,0,90)},
            {handler=nil, objectname="djn_yacht_engine_details_room_1",     offsetcoords=vector3(-2.0496, 8.28e-4, 5.87994), offsetrotation=vector3(0,0,90)},
            {handler=nil, objectname="djn_yacht_engine_details_room_2",     offsetcoords=vector3(-2.0496, 8.28e-4, 5.87994), offsetrotation=vector3(0,0,90)},
            {handler=nil, objectname="djn_yacht_engine_room_entry",         offsetcoords=vector3(-2.0496, 8.28e-4, 5.87994), offsetrotation=vector3(0,0,90)},
            {handler=nil, objectname="djn_yacht_int_wellness_rooms_details",offsetcoords=vector3(-2.0496, 8.28e-4, 5.87994), offsetrotation=vector3(0,0,90)},
            {handler=nil, objectname="djn_yacht_main_hall",                 offsetcoords=vector3(-2.0496, 8.28e-4, 5.87994), offsetrotation=vector3(0,0,90)},
            {handler=nil, objectname="djn_yacht_room1_details",             offsetcoords=vector3(-2.0496, 8.28e-4, 5.87994), offsetrotation=vector3(0,0,90)},
            {handler=nil, objectname="djn_yacht_room2_details",             offsetcoords=vector3(-2.0496, 8.28e-4, 5.87994), offsetrotation=vector3(0,0,90)},
            {handler=nil, objectname="djn_yacht_room3_details",             offsetcoords=vector3(-2.0496, 8.28e-4, 5.87994), offsetrotation=vector3(0,0,90)},
            {handler=nil, objectname="djn_yachta_entry_room_details",       offsetcoords=vector3(-2.0496, 8.28e-4, 5.87994), offsetrotation=vector3(0,0,90)},
            {handler=nil, objectname="apa_prop_ap_stern_text",  offsetcoords=vector3(-2.0, -0.65, 17.1), offsetrotation=vector3(10,0,90)},
            {handler=nil, objectname="apa_prop_ap_starb_text",  offsetcoords=vector3(-2.05, 0.0, 5.8),   offsetrotation=vector3(0,0,90)},
            {handler=nil, objectname="apa_prop_ap_port_text",   offsetcoords=vector3(-2.05, 0.0, 5.8),   offsetrotation=vector3(0,0,90)},
            {handler=nil, objectname="apa_mp_apa_yacht_win",    offsetcoords=vector3(-2.05, 0.0, 5.9),   offsetrotation=vector3(0,0,90)},
            {handler=nil, objectname="djn_apa_mp_apa_yacht_option3", offsetcoords=vector3(0,0,0), offsetrotation=vector3(0,0,0)},
            {handler=nil, objectname="rtx_apa_mp_apa_yacht_jacuzzi_ripple1", offsetcoords=vector3(0,-51,6), offsetrotation=vector3(0,0,0)},
        },

        doors = {
            {handler=nil, objectname="apa_mp_apa_yacht_door",          coords=vector3(-0.769,-36.827,6.536), rotation=vector3(0,0,0),   rotationopened=vector3(0,0,90),   opened=false},
            {handler=nil, objectname="sf_p_mp_yacht_door",             coords=vector3(-4.803,-4.518,6.527),  rotation=vector3(0,0,180), rotationopened=vector3(0,0,270),  opened=false},
            {handler=nil, objectname="sf_p_mp_yacht_door",             coords=vector3(-4.597,2.122,6.527),   rotation=vector3(0,0,180), rotationopened=vector3(0,0,270),  opened=false},
            {handler=nil, objectname="rtx_djn_yacht_int_doors_1",      coords=vector3(-3.343,14.919,6.47),   rotation=vector3(0,0,-160),rotationopened=vector3(0,0,-70),  opened=false},
            {handler=nil, objectname="rtx_djn_yacht_int_doors_1",      coords=vector3(-2.55,4.067,6.47),     rotation=vector3(0,0,-160),rotationopened=vector3(0,0,-70),  opened=false},
            {handler=nil, objectname="rtx_djn_yacht_int_doors_1",      coords=vector3(-3.343,17.287,6.47),   rotation=vector3(0,0,-160),rotationopened=vector3(0,0,-70),  opened=false},
            {handler=nil, objectname="rtx_djn_yacht_int_doors_2",      coords=vector3(0.224,18.263,6.262),   rotation=vector3(0,0,135), rotationopened=vector3(0,0,225),  opened=false},
            {handler=nil, objectname="rtx_djn_yacht_int_doors_1",      coords=vector3(-3.343,23.339,6.47),   rotation=vector3(0,0,-160),rotationopened=vector3(0,0,-70),  opened=false},
            {handler=nil, objectname="rtx_djn_yacht_int_doors_2",      coords=vector3(5.071,28.801,6.265),   rotation=vector3(0,0,90),  rotationopened=vector3(0,0,180),  opened=false},
            {handler=nil, objectname="rtx_djn_yacht_int_doors_1",      coords=vector3(-5.038,32.619,6.449),  rotation=vector3(0,0,-70), rotationopened=vector3(0,0,20),   opened=false},
            {handler=nil, objectname="rtx_djn_yacht_int_doors_1",      coords=vector3(1.247,38.011,6.449),   rotation=vector3(0,0,-160),rotationopened=vector3(0,0,-70),  opened=false},
            {handler=nil, objectname="rtx_djn_yacht_int_doors_1",      coords=vector3(3.683,22.238,3.452),   rotation=vector3(0,0,20),  rotationopened=vector3(0,0,110),  opened=false},
            {handler=nil, objectname="rtx_djn_yacht_int_doors_1",      coords=vector3(3.683,27.283,3.452),   rotation=vector3(0,0,20),  rotationopened=vector3(0,0,110),  opened=false},
            {handler=nil, objectname="rtx_djn_yacht_int_doors_1",      coords=vector3(3.683,16.005,3.452),   rotation=vector3(0,0,20),  rotationopened=vector3(0,0,110),  opened=false},
            {handler=nil, objectname="rtx_djn_yacht_int_doors_1",      coords=vector3(-1.019,15.56,3.452),   rotation=vector3(0,0,20),  rotationopened=vector3(0,0,-70),  opened=false},
            {handler=nil, objectname="rtx_djn_yacht_int_doors_1",      coords=vector3(-1.019,21.732,3.452),  rotation=vector3(0,0,20),  rotationopened=vector3(0,0,-70),  opened=false},
            {handler=nil, objectname="rtx_djn_yacht_int_doors_1",      coords=vector3(-1.235,18.328,3.452),  rotation=vector3(0,0,110), rotationopened=vector3(0,0,200),  opened=false},
            {handler=nil, objectname="rtx_djn_yacht_int_doors_1",      coords=vector3(-2.402,20.14,3.452),   rotation=vector3(0,0,-70), rotationopened=vector3(0,0,20),   opened=false},
            {handler=nil, objectname="rtx_djn_yacht_int_doors_1",      coords=vector3(-3.43,29.385,3.452),   rotation=vector3(0,0,-70), rotationopened=vector3(0,0,-160), opened=false},
            {handler=nil, objectname="rtx_djn_yacht_int_doors_1",      coords=vector3(-6.51,29.385,3.452),   rotation=vector3(0,0,-70), rotationopened=vector3(0,0,-160), opened=false},
            {handler=nil, objectname="rtx_djn_yacht_int_doors_1",      coords=vector3(-6.51,11.612,3.452),   rotation=vector3(0,0,-70), rotationopened=vector3(0,0,20),   opened=false},
            {handler=nil, objectname="rtx_djn_apa_yacht_door_1",       coords=vector3(-5.508,5.174,9.624),   rotation=vector3(0,0,90),  rotationopened=vector3(0,0,0),    opened=false},
            {handler=nil, objectname="rtx_djn_apa_yacht_door_1",       coords=vector3(4.881,8.038,13.421),   rotation=vector3(0,0,90),  rotationopened=vector3(0,0,180),  opened=false},
            {handler=nil, objectname="rtx_djn_apa_yacht_door_1",       coords=vector3(-4.974,8.038,13.421),  rotation=vector3(0,0,90),  rotationopened=vector3(0,0,0),    opened=false},
            {handler=nil, objectname="rtx_djn_apa_yacht_door_1",       coords=vector3(5.427,5.174,9.624),    rotation=vector3(0,0,90),  rotationopened=vector3(0,0,180),  opened=false},
            {handler=nil, objectname="rtx_djn_yacht_int_doors_1",      coords=vector3(-0.655,-18.873,6.459), rotation=vector3(0,0,-70), rotationopened=vector3(0,0,20),   opened=false},
            {handler=nil, objectname="rtx_djn_yacht_int_doors_2",      coords=vector3(0.943,6.236,6.262),    rotation=vector3(0,0,135), rotationopened=vector3(0,0,225),  opened=false},
            {handler=nil, objectname="rtx_djn_yacht_int_doors_3",      coords=vector3(0.217,15.548,6.456),   rotation=vector3(0,0,-70), rotationopened=vector3(0,0,20),   opened=false},
            {handler=nil, objectname="rtx_djn_yacht_int_door_l",       coords=vector3(-1.013,-27.255,9.546), rotation=vector3(0,0,180), rotationopened=vector3(0,0,270),  opened=false},
            {handler=nil, objectname="rtx_djn_yacht_int_door_r",       coords=vector3(0.893,-27.255,9.546),  rotation=vector3(0,0,0),   rotationopened=vector3(0,0,-90),  opened=false},
            {handler=nil, objectname="rtx_djn_yacht_int_door_s",       coords=vector3(5.312,-16.599,9.547),  rotation=vector3(0,0,90),  rotationopened=vector3(0,0,0),    opened=false},
            {handler=nil, objectname="rtx_djn_yacht_int_gate_l",       coords=vector3(-0.049,-51.949,2.058), rotation=vector3(0,0,90),  rotationopened=vector3(0,0,55),   opened=false, special=true, opencoords=vector3(-0.049,-53.949,2.058)},
            {handler=nil, objectname="rtx_djn_yacht_int_gate_r",       coords=vector3(-0.049,-51.949,2.058), rotation=vector3(0,0,90),  rotationopened=vector3(0,0,125),  opened=false, special=true, opencoords=vector3(-0.049,-53.949,2.058)},
            {handler=nil, objectname="rtx_apa_mp_apa_yacht_door_cap",  coords=vector3(-1.19,0.081,12.56),    rotation=vector3(0,0,-90), rotationopened=vector3(0,0,0),    opened=false},
            {handler=nil, objectname="rtx_apa_mp_apa_yacht_door_cap",  coords=vector3(1.138,0.081,12.56),    rotation=vector3(0,0,90),  rotationopened=vector3(0,0,0),    opened=false},
            {handler=nil, objectname="rtx_apa_mp_apa_yacht_door_front",coords=vector3(0.943,42.884,7.758),   rotation=vector3(0,0,90),  rotationopened=vector3(0,0,0),    opened=false},
            {handler=nil, objectname="rtx_apa_mp_apa_yacht_door_front",coords=vector3(-1.053,42.884,7.758),  rotation=vector3(0,0,-90), rotationopened=vector3(0,0,0),    opened=false},
            {handler=nil, objectname="rtx_djn_yacht_int_door_saun",    coords=vector3(-4.115,3.033,3.548),   rotation=vector3(0,0,90),  rotationopened=vector3(0,0,0),    opened=false},
            {handler=nil, objectname="rtx_djn_yacht_int_door_saun",    coords=vector3(-5.047,3.966,3.548),   rotation=vector3(0,0,-90), rotationopened=vector3(0,0,0),    opened=false},
            {handler=nil, objectname="rtx_apa_mp_apa_yacht_door_engine",coords=vector3(4.696,0.734,3.831),   rotation=vector3(0,0,90),  rotationopened=vector3(0,0,180),  opened=false},
            {handler=nil, objectname="rtx_apa_mp_apa_yacht_door_engine",coords=vector3(2.805,0.734,3.831),   rotation=vector3(0,0,-90), rotationopened=vector3(0,0,-180), opened=false},
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

RegisterNetEvent("asyacht:Global:FuelUpdate")
AddEventHandler("asyacht:Global:FuelUpdate", function(yachtId, fuel)
    yachtFuel[yachtId] = fuel
end)

local function GetYachtEngineStats(yachtId)
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
            if objData.objectname == "djn_apa_mp_apa_yacht_option3" then
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

local function BuildYachtSpecs()
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
                                if objData.objectname == "djn_apa_mp_apa_yacht_option3" then
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
                                        if objData.objectname == "djn_apa_mp_apa_yacht_option3" then
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

local furniturePlacementEntity    = nil

local isFurniturePlacing           = false

local furniturePlacementKey        = nil

local furniturePlacementCategoryId = nil
local furniturePlacementItemId     = nil
local furniturePlacementCoords     = nil
local furniturePlacementRotation   = nil

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

local buyTourActive = false

local function ApplyBuyCameraPreset(index)
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
            if objData.objectname == "djn_apa_mp_apa_yacht_option3" then
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
        if DoesEntityExist(objData.handler) and objData.objectname == "djn_apa_mp_apa_yacht_option3" then
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

local function ToggleYachtDriveEnterExit()
    
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
        SendNUIMessage({message = "objecteditorownposshow"})

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
local function IsNightTime()
    local c = Config.Comfort or {}
    local h = GetClockHours()
    return h >= (c.nightStart or 19) or h < (c.nightEnd or 6)
end

function YachtLightsWanted(yachtId)
    local ex = yachtExtras[yachtId]
    local mode = (ex and ex.lightmode) or "on"
    if mode == "off" then return false end
    if mode == "auto" then return IsNightTime() end
    return true
end

-- Removes the light prop when the schedule says it should be dark (the streaming loop only re-creates it when wanted).
CreateThread(function()
    while true do
        Wait(3000)
        for _, yd in pairs(yachts) do
            if yd.lighting and DoesEntityExist(yd.lighting.handler) and not YachtLightsWanted(yd.yachtiddata) then
                DeleteEntity(yd.lighting.handler)
                yd.lighting.handler = nil
            end
        end
    end
end)

-- Hull lights -------------------------------------------------------------------
local hullLit = {}
CreateThread(function()
    local cfg = Config.Comfort and Config.Comfort.hullLights
    if not cfg or not cfg.enabled then return end
    while true do
        -- pick the yachts that need drawing (cheap, once a second)
        hullLit = {}
        local pcoords = GetEntityCoords(PlayerPedId())
        for id, yd in pairs(yachts) do
            local ex = yachtExtras[yd.yachtiddata]
            local main = yd.yachtmainobject
            if ex and ex.hullon and main and DoesEntityExist(main) and #(pcoords - GetEntityCoords(main)) < (cfg.drawDistance or 160.0) then
                local col = cfg.colors[ex.hullcolor or 1] or cfg.colors[1]
                hullLit[#hullLit + 1] = { entity = main, rgb = col.rgb }
            end
        end
        local frames = #hullLit > 0 and 60 or 0
        if frames == 0 then Wait(1000) end
        for _ = 1, frames do
            for _, h in ipairs(hullLit) do
                if DoesEntityExist(h.entity) then
                    for _, pt in ipairs(cfg.points) do
                        local p = GetOffsetFromEntityInWorldCoords(h.entity, pt.x, pt.y, pt.z)
                        DrawLightWithRange(p.x, p.y, p.z, h.rgb[1], h.rgb[2], h.rgb[3], cfg.range or 14.0, cfg.intensity or 4.0)
                    end
                end
            end
            Wait(0)
        end
    end
end)

-- Onboard radio -----------------------------------------------------------------
CreateThread(function()
    local cfg = Config.Comfort and Config.Comfort.ambience
    if not cfg or not cfg.enabled then return end
    local activeStation = nil
    while true do
        Wait(1500)
        local want = nil
        local ped = PlayerPedId()
        if not isYachtBuyMenuOpen and not IsPedInAnyVehicle(ped, false) then
            local pcoords = GetEntityCoords(ped)
            for _, yd in pairs(yachts) do
                local ex = yachtExtras[yd.yachtiddata]
                if ex and ex.radio and yd.yachtmainobject and DoesEntityExist(yd.yachtmainobject)
                    and #(pcoords - GetEntityCoords(yd.yachtmainobject)) < (cfg.radius or 50.0) then
                    want = ex.radio
                    break
                end
            end
        end
        if want ~= activeStation then
            if want then
                SetFrontendRadioActive(true)
                SetRadioToStationName(want)
            elseif activeStation then
                SetFrontendRadioActive(false)
            end
            activeStation = want
        end
    end
end)

-- Tender -------------------------------------------------------------------------
local tenderVehicles = {}   -- [optionId] = { veh = entity, slot = n, air = bool }

local function FreeTenderSlot(category, ignoreOptionId)
    local used = {}
    for id, t in pairs(tenderVehicles) do
        if id ~= ignoreOptionId and t.category == category and DoesEntityExist(t.veh) then used[t.slot] = true end
    end
    local slot = 1
    while used[slot] do slot = slot + 1 end
    return slot
end

RegisterNetEvent("asyacht:Global:TenderApproved")
AddEventHandler("asyacht:Global:TenderApproved", function(yachtId, modelName, optionId, fromPurchase)
    local cfg = Config.Comfort and Config.Comfort.tender
    print(("^3AS Yacht^7: vehicle request received (yacht %s, %s)"):format(tostring(yachtId), tostring(modelName)))
    if not cfg then return end

    -- right after buying, the yacht is still streaming in: wait for it
    local yd
    local waited = 0
    while waited < 30000 do
        yd = yachts["yacht-" .. yachtId]
        if yd and DoesEntityExist(yd.yachtmainobject) then break end
        Wait(250) waited = waited + 250
    end
    if not yd or not DoesEntityExist(yd.yachtmainobject) then
        print("^1AS Yacht^7: vehicle not spawned - the yacht was not loaded on your client")
        Notify("Could not place your vehicle: the yacht is not loaded yet. Call it from the Upgrades menu.", "error")
        return
    end

    local model = GetHashKey(modelName)
    if not IsModelInCdimage(model) then Notify("Tender model missing: " .. tostring(modelName), "error") return end
    RequestModel(model)
    local t = 0
    while not HasModelLoaded(model) and t < 5000 do Wait(50) t = t + 50 end
    if not HasModelLoaded(model) then
        print("^1AS Yacht^7: vehicle model failed to load: " .. tostring(modelName))
        Notify("Vehicle model failed to load: " .. tostring(modelName), "error")
        return
    end

    local main = yd.yachtmainobject
    local opt
    for _, o in ipairs(cfg.options) do if o.id == optionId then opt = o end end
    opt = opt or {}
    local air = opt.air == true
    local category = opt.category or "Vehicles"
    local slots = cfg.slots and cfg.slots[category] or {}

    local old = tenderVehicles[optionId]
    local slot = old and old.slot or FreeTenderSlot(category, optionId)
    if old and DoesEntityExist(old.veh) then DeleteEntity(old.veh) end
    local off = slots[slot]
    if not off then
        Notify("There is no free parking spot for that vehicle on your yacht.", "error")
        return
    end

    local pos, heading = TenderSpawnCoords(main, off, model, air, cfg)
    local veh = CreateVehicle(model, pos.x, pos.y, pos.z, heading, true, false)
    SetModelAsNoLongerNeeded(model)
    if not DoesEntityExist(veh) then
        print("^1AS Yacht^7: CreateVehicle failed for " .. tostring(modelName))
        Notify("The game refused to create " .. tostring(modelName), "error")
        return
    end
    print(("^2AS Yacht^7: spawned %s at %.1f %.1f %.1f (slot %d)"):format(tostring(modelName), pos.x, pos.y, pos.z, slot))

    tenderVehicles[optionId] = { veh = veh, slot = slot, category = category }
    SetEntityAsMissionEntity(veh, true, true)
    -- hold it in place until somebody climbs in (a helicopter would fall, a boat could slide off the platform)
    FreezeEntityPosition(veh, true)
    if air then
        SetHeliBladesFullSpeed(veh)
        SetVehicleEngineOn(veh, true, true, false)
        if not fromPurchase then TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1) end
    else
        SetVehicleEngineOn(veh, false, true, false)
    end
    CreateThread(function()
        while DoesEntityExist(veh) and not IsPedInVehicle(PlayerPedId(), veh, false) do Wait(300) end
        if DoesEntityExist(veh) then FreezeEntityPosition(veh, false) end
    end)
    Notify((opt.label or "Vehicle") .. " is waiting next to the yacht.", "success")
end)

-- Pressing F (enter vehicle) next to your yacht vehicles always enters the NEAREST one of them. Without this the
-- game picks whichever vehicle it likes, e.g. the boat instead of the helicopter parked beside you.
CreateThread(function()
    while true do
        local wait = 500
        local ped = PlayerPedId()
        if next(tenderVehicles) ~= nil and not IsPedInAnyVehicle(ped, false) then
            local pcoords = GetEntityCoords(ped)
            local best, bestDist
            for _, t in pairs(tenderVehicles) do
                if DoesEntityExist(t.veh) then
                    local d = #(pcoords - GetEntityCoords(t.veh))
                    if d < 9.0 and (not bestDist or d < bestDist) then best, bestDist = t.veh, d end
                end
            end
            if best then
                wait = 0
                DisableControlAction(0, 23, true)
                if IsDisabledControlJustPressed(0, 23) then
                    TaskEnterVehicle(ped, best, 10000, -1, 1.0, 1, 0)
                end
            end
        end
        Wait(wait)
    end
end)

-- Docking: stores a vehicle again (it can be called back from the Upgrades menu at any time).
local function DockTender(optionId)
    local t = tenderVehicles[optionId]
    if not t or not DoesEntityExist(t.veh) then tenderVehicles[optionId] = nil return false end
    local ped = PlayerPedId()
    if IsPedInVehicle(ped, t.veh, false) then
        if GetEntityHeightAboveGround(t.veh) > 4.0 or GetEntitySpeed(t.veh) > 4.0 then
            Notify("Land or stop the vehicle before docking it.", "error")
            return false
        end
        TaskLeaveVehicle(ped, t.veh, 0)
        local waited = 0
        while IsPedInVehicle(ped, t.veh, false) and waited < 4000 do Wait(100) waited = waited + 100 end
    end
    if DoesEntityExist(t.veh) then DeleteEntity(t.veh) end
    tenderVehicles[optionId] = nil
    return true
end

RegisterNUICallback("comfortdock", function(data, cb)
    cb("ok")
    CreateThread(function()
        if DockTender(tonumber(data.id)) then Notify("Vehicle docked.", "success") end
    end)
end)

RegisterCommand("yachtdock", function()
    CreateThread(function()
        local any = false
        -- the vehicle you are in first, otherwise everything you have out
        for id, t in pairs(tenderVehicles) do
            if DoesEntityExist(t.veh) and IsPedInVehicle(PlayerPedId(), t.veh, false) then
                any = DockTender(id) or any
                if any then Notify("Vehicle docked.", "success") end
                return
            end
        end
        for id in pairs(tenderVehicles) do any = DockTender(id) or any end
        Notify(any and "Vehicles docked." or "You have no yacht vehicles out.", any and "success" or "error")
    end)
end, false)

-- Press E to dock: next to a parked yacht vehicle, or while sitting in one that has stopped near the yacht.
CreateThread(function()
    local cfg = Config.Comfort and Config.Comfort.tender
    local key = (cfg and cfg.dockKey) or 38
    local busy = false
    while true do
        local wait = 500
        if next(tenderVehicles) ~= nil and not busy then
            local ped = PlayerPedId()
            local pcoords = GetEntityCoords(ped)
            local target, inside
            for id, t in pairs(tenderVehicles) do
                if DoesEntityExist(t.veh) then
                    if IsPedInVehicle(ped, t.veh, false) then
                        if GetEntitySpeed(t.veh) < 4.0 and GetEntityHeightAboveGround(t.veh) < 4.0 then target, inside = id, true end
                        break
                    elseif not IsPedInAnyVehicle(ped, false) and #(pcoords - GetEntityCoords(t.veh)) < 4.0 then
                        target = id
                    end
                end
            end
            -- only offer it close to a yacht
            if target then
                local nearYacht = false
                for _, yd in pairs(yachts) do
                    if yd.yachtmainobject and DoesEntityExist(yd.yachtmainobject) and #(pcoords - GetEntityCoords(yd.yachtmainobject)) < 120.0 then nearYacht = true break end
                end
                if not nearYacht then target = nil end
            end
            if target then
                wait = 0
                BeginTextCommandDisplayHelp("STRING")
                AddTextComponentSubstringPlayerName("Press ~INPUT_PICKUP~ to dock this vehicle")
                EndTextCommandDisplayHelp(0, false, false, -1)
                if IsControlJustPressed(0, key) then
                    busy = true
                    local id = target
                    CreateThread(function()
                        if DockTender(id) then Notify("Vehicle docked.", "success") end
                        busy = false
                    end)
                end
            end
        end
        Wait(wait)
    end
end)

-- /yachtoffset: stand where a vehicle should appear (helipad, stern...) and run this.
-- It prints your position relative to the nearest yacht, ready to paste into Config.Comfort.tender.
RegisterCommand("yachtoffset", function()
    local ped = PlayerPedId()
    local pcoords = GetEntityCoords(ped)
    local best, bestDist
    for _, yd in pairs(yachts) do
        if yd.yachtmainobject and DoesEntityExist(yd.yachtmainobject) then
            local d = #(pcoords - GetEntityCoords(yd.yachtmainobject))
            if not bestDist or d < bestDist then best, bestDist = yd, d end
        end
    end
    if not best then Notify("No yacht nearby.", "error") return end
    local o = GetOffsetFromEntityGivenWorldCoords(best.yachtmainobject, pcoords.x, pcoords.y, pcoords.z)
    local text = ("vector3(%.2f, %.2f, %.2f)"):format(o.x, o.y, o.z)
    print("^2AS Yacht offset^7: " .. text)
    Notify("Offset from yacht: " .. text .. "  (also in the F8 console)", "info")
end, false)

-- NUI bridge for the comfort panel ---------------------------------------------------
local function ComfortCallback(name, eventName, argsFn)
    RegisterNUICallback(name, function(data, cb)
        cb("ok")
        if isManagementMenuOpen and managementMenuYachtId ~= nil then
            TriggerServerEvent(eventName, managementMenuYachtId, argsFn(data))
        end
    end)
end

ComfortCallback("comfortlight",       "asyacht:Global:SetLightMode", function(d) return tostring(d.mode or "") end)
ComfortCallback("comfortradio",       "asyacht:Global:SetRadio",     function(d) return tostring(d.station or "") end)
ComfortCallback("comfortbuytender",   "asyacht:Global:BuyTender",    function(d) return tonumber(d.id) end)
ComfortCallback("comfortspawntender", "asyacht:Global:SpawnTender",  function(d) return tonumber(d.id) end)
ComfortCallback("comfortsavelayout",  "asyacht:Global:SaveLayout",   function(d) return tostring(d.name or "") end)
ComfortCallback("comfortloadlayout",  "asyacht:Global:LoadLayout",   function(d) return tonumber(d.index) end)
ComfortCallback("comfortdeletelayout","asyacht:Global:DeleteLayout", function(d) return tonumber(d.index) end)

RegisterNUICallback("comfortHull", function(data, cb)
    cb("ok")
    if isManagementMenuOpen and managementMenuYachtId ~= nil then
        TriggerServerEvent("asyacht:Global:SetHullLights", managementMenuYachtId, tonumber(data.color), data.on == true)
    end
end)