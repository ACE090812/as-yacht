-- as-yacht client/core.lua: Shared state, notifications and helpers.
-- (Split from the former client/main.lua. File-level state is global so every client module shares it.)

if IsDuplicityVersion() then
    GetPlayerPositionInRealTime104()
end

ESX = nil
QBCore = nil

Lang = (Language and (Language[Config.Language] or Language["English"])) or {}

drivingState = {
    driving    = false,
    drivingid  = nil,
    yachthandler = nil,
}

isYachtBuyMenuOpen = false
buyPending = false
yachtExtras = {}   -- [yachtId] = { enginetier, storagetier, ... } from the server
yachtFuel = {}     -- [yachtId] = live fuel % (sent to the driver while sailing)
previewEnv = {}     -- { hour = n, weather = "TYPE" } chosen in the buy menu

buyHudHidden = false -- true while we have the HUD hidden for the buy menu
previewEnvTouched = false -- set once we override time/weather, so we always undo it

function ClearPreviewEnv()
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


previewSessionId = 0
previewLightRequestId = 0

buyCameraMain = nil
buyCameraAlt  = nil

activeCameraIndex = 1

currentYachtColorIndex = 1

currentBuyCameraIndex  = 1

isCameraTransitioning = false

hasBuyBlipCreated = false
yachtBuyBlip = nil

yachtBlips = {}
yachtIntroPlayed = {}

currentNearYachtId = nil

currentNearDoorIndex = nil

currentNearStorageIndex   = nil
currentNearWardrobeIndex  = nil
currentNearManageZoneId   = nil
currentNearDriveZoneId    = nil
currentNearHottubIndex    = nil

isManagementMenuOpen   = false
managementMenuYachtId  = nil


isFurnitureMenuOpen       = false
isFurniturePlacementActive = false
furnitureMenuYachtId       = nil
isGizmoActive             = false

pendingFurniturePurchase   = nil

noClipActive = false
furnitureCamera = nil
noClipPed = nil
playerPositionBeforeFurniture = nil

furnitureSpeedsLookX = {
    {speeddata = 0.0}, {speeddata = 0.1}, {speeddata = 0.2}, {speeddata = 0.3}, {speeddata = 0.4},
    {speeddata = 0.5}, {speeddata = 0.6}, {speeddata = 0.7}, {speeddata = 0.8}, {speeddata = 0.9},
    {speeddata = 1.0}, {speeddata = 1.1}, {speeddata = 1.2}, {speeddata = 1.3}, {speeddata = 1.4},
    {speeddata = 1.5}, {speeddata = 1.6}, {speeddata = 1.7}, {speeddata = 1.8}, {speeddata = 1.9}
}

furnitureSpeedsLookY = {
    {speeddata = 0.0}, {speeddata = 0.02}, {speeddata = 0.04}, {speeddata = 0.06}, {speeddata = 0.08},
    {speeddata = 0.1},  {speeddata = 0.2},  {speeddata = 0.3},  {speeddata = 0.4},  {speeddata = 0.5},
    {speeddata = 0.6},  {speeddata = 0.7},  {speeddata = 0.8},  {speeddata = 0.9},  {speeddata = 1.0},
    {speeddata = 1.1},  {speeddata = 1.2},  {speeddata = 1.3},  {speeddata = 1.4},  {speeddata = 1.5}
}

furnitureSpeedsCamera = {
    {speeddata = 0.0}, {speeddata = 0.1}, {speeddata = 0.2}, {speeddata = 0.3}, {speeddata = 0.4},
    {speeddata = 0.5}, {speeddata = 0.6}, {speeddata = 0.7}, {speeddata = 0.8}, {speeddata = 0.9},
    {speeddata = 1.0}, {speeddata = 1.1}, {speeddata = 1.2}, {speeddata = 1.3}, {speeddata = 1.4},
    {speeddata = 1.5}, {speeddata = 1.6}, {speeddata = 1.7}, {speeddata = 1.8}, {speeddata = 1.9}
}

-- Move steps in metres. The fine end (5 mm - 5 cm) is for seating a monitor flush on a table or a vase on a shelf.
furnitureTranslateSnaps = {
    {snapdata = 0.005}, {snapdata = 0.01}, {snapdata = 0.02}, {snapdata = 0.03}, {snapdata = 0.05},
    {snapdata = 0.1},   {snapdata = 0.2},  {snapdata = 0.25}, {snapdata = 0.5},  {snapdata = 1.0}
}

-- The step sizes in order, so the editor can label its slider with the real value.
function FurnitureSnapSteps()
    local steps = {}
    for i, snap in ipairs(furnitureTranslateSnaps) do steps[i] = snap.snapdata end
    return steps
end

furnitureRotateSnaps = {
    {snapdata = 0.1}, {snapdata = 0.2}, {snapdata = 0.3}, {snapdata = 0.4}, {snapdata = 0.5},
    {snapdata = 0.6}, {snapdata = 0.7}, {snapdata = 0.8}, {snapdata = 0.9}, {snapdata = 1.0}
}

furnitureLookXIndex = 10
furnitureLookYIndex = 10
furnitureSpeedIndex = 10
furnitureTranslateSnapIndex = 6 -- 0.1 m, the same default step as before
furnitureRotateSnapIndex = 1

hottubSeatInfo = {
    yachtid = yachtiddata,  
    seatid  = seatiddata,
}
isPlayerSeated          = false

-- Teleports the player onto the yacht and keeps them frozen until the collision under them has loaded. A player
-- released too early falls through the deck into the sea. A short background check then puts them back if they
-- still ended up below the deck (retries up to 3 times).
function PlacePedSafely(pos)
    local ped = PlayerPedId()
    local function put()
        FreezeEntityPosition(ped, true)
        SetEntityCoordsNoOffset(ped, pos.x, pos.y, pos.z, false, false, false)
        local waited = 0
        RequestCollisionAtCoord(pos.x, pos.y, pos.z)
        while not HasCollisionLoadedAroundEntity(ped) and waited < 3000 do
            RequestCollisionAtCoord(pos.x, pos.y, pos.z)
            Wait(50)
            waited = waited + 50
        end
        Wait(100)
        FreezeEntityPosition(ped, false)
    end
    put()
    CreateThread(function()
        for _ = 1, 3 do
            Wait(800)
            if not DoesEntityExist(ped) then return end
            if GetEntityCoords(ped).z > pos.z - 4.0 then return end -- still on the deck
            put()
        end
    end)
end

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

hasInitialized     = false
isTargetSystemReady = false

isPlayerNearBuyLocation = false


yachtModelHash = GetHashKey("as_yacht_veh")


flagObjectsList = {
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


anchorRailingTypesList = {
    [1] = {railingobject = "apa_mp_apa_yacht_o3_rail_a_anchor"},
    [2] = {railingobject = "apa_mp_apa_yacht_o3_rail_b_anchor"},
}
-- Extra railing colours (ids 3+) reuse the silver model; the colour itself comes from GetRailingColour.
setmetatable(anchorRailingTypesList, { __index = function(t, k) return rawget(t, 1) end })
