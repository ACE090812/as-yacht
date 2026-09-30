ESX = nil
QBCore = nil

local playersInBuyPreview = {}
yachts = {}
local yachtsLoaded = false

function LanguageFile2(key, ...)
    local lang = Language and (Language[Config.Language] or Language["English"])
    local text = lang and lang[key]
    if not text then return "" end
    return string.format(text, ...)
end

function LanguageFile(key, ...)
    local text = LanguageFile2(key, ...)
    return tostring(text:gsub("^%l", string.upper))
end

-- ─── Validation helpers ────────────────────────────────────────────────────
local Limits = {
    flag = {1, 46}, lightCategory = {1, 2}, lightId = {1, 8},
    railing = {1, #Config.RailingTypes}, color = {1, 16}, equipment = {1, 2},
    textMaxLength = 24,
    maxFurniturePerYacht = 300,
    maxFurnitureOffset = 60.0, -- metres from the yacht origin
}

YachtLimits = Limits
local function isInt(v, range)
    return type(v) == "number" and v == math.floor(v) and v >= range[1] and v <= range[2]
end

local function sanitizeText(t)
    if type(t) ~= "string" then return "" end
    t = t:gsub("[<>\"'`&]", ""):gsub("%c", "")
    return t:sub(1, Limits.textMaxLength)
end

SanitizeYachtText = sanitizeText
IsYachtInt = isInt

local function validOffset(v)
    if type(v) ~= "table" and type(v) ~= "vector3" then return false end
    if type(v.x) ~= "number" or type(v.y) ~= "number" or type(v.z) ~= "number" then return false end
    return math.abs(v.x) <= Limits.maxFurnitureOffset and math.abs(v.y) <= Limits.maxFurnitureOffset and math.abs(v.z) <= Limits.maxFurnitureOffset
end

local function isNum3(v, keys)
    if type(v) ~= "table" and type(v) ~= "vector3" then return false end
    return type(v.x) == "number" and type(v.y) == "number" and type(v.z or 0) == "number"
end

local function validRot(v)
    return isNum3(v) and math.abs(v.x) <= 360.0 and math.abs(v.y) <= 360.0 and math.abs(v.z) <= 360.0
end

local function isPlayerNear(src, coords, dist)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 or not coords then return false end
    return #(GetEntityCoords(ped) - vector3(coords.x, coords.y, coords.z)) <= dist
end

local function isPlayerNearYacht(src, yachtId)
    local c = GlobalState["asyacht-" .. yachtId .. "-coords"]
    return c ~= nil and isPlayerNear(src, c, Config.YachtServerInteractDistance or 250.0)
end

YachtIsNearYacht = isPlayerNearYacht

local function isValidOnlinePlayer(id)
    id = tonumber(id)
    return id ~= nil and GetPlayerName(id) ~= nil, id
end

local function getNearbyPlayers(src, dist)
    local list = {}
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return list end
    local me = GetEntityCoords(ped)
    for _, pid in ipairs(GetPlayers()) do
        pid = tonumber(pid)
        if pid ~= src then
            local tp = GetPlayerPed(pid)
            if tp and tp ~= 0 and #(GetEntityCoords(tp) - me) <= dist then
                list[#list + 1] = pid
            end
        end
    end
    return list
end

YachtGetNearbyPlayers = function(src, dist) return getNearbyPlayers(src, dist) end

local function playerOwnsYacht(identifier)
    for _, y in pairs(yachts) do
        if y.owner == identifier then return true end
    end
    return false
end

if Config.Framework == "esx" then
    if Config.ESXFramework.newversion == true then
        ESX = exports[Config.ESXFramework.resourcename]:getSharedObject()
    else
        TriggerEvent(Config.ESXFramework.getsharedobject, function(obj) 
            ESX = obj 
        end)
    end
elseif Config.Framework == "qbcore" then
    QBCore = exports[Config.QBCoreFrameworkResourceName]:GetCoreObject()
end

function generateRandomFurnitureId()
    return tostring(math.random(100000000, 999999999))
end

function GetUniqueFurnitureId(yachtId)
    local yacht = yachts["yacht-" .. yachtId]
    local furnitureId = generateRandomFurnitureId()
    while yacht and yacht.furnitures and yacht.furnitures[furnitureId] do
        Citizen.Wait(0)
        furnitureId = generateRandomFurnitureId()
    end
    return furnitureId
end

function SpawnYacht(yachtId, targetPed)
    local handlerKey = "asyacht-" .. yachtId .. "-vehhandler"
    local vehIdKey = "asyacht-" .. yachtId .. "-vehid"
    local coordsKey = "asyacht-" .. yachtId .. "-coords"

    if GlobalState[handlerKey] and DoesEntityExist(GlobalState[handlerKey]) then
        DeleteEntity(GlobalState[handlerKey])
    end

    GlobalState[handlerKey] = nil
    GlobalState[vehIdKey] = nil

    local spawnCoords = GlobalState[coordsKey]
    local veh = CreateVehicleServerSetter(
        GetHashKey("djn_yacht_veh"),
        "boat",
        spawnCoords.x,
        spawnCoords.y,
        -4.0,
        0.0
    )

    GlobalState[handlerKey] = veh

    while not DoesEntityExist(GlobalState[handlerKey]) do
        Citizen.Wait(0)
    end

    SetEntityCoords(GlobalState[handlerKey], spawnCoords.x, spawnCoords.y, -4.0)
    FreezeEntityPosition(GlobalState[handlerKey], true)
    
    local rotZ = 0.0
    if yachts["yacht-" .. yachtId] and yachts["yacht-" .. yachtId].yachtcurrentanchoreddata then
        rotZ = yachts["yacht-" .. yachtId].yachtcurrentanchoreddata.rotation.z
    end
    SetEntityRotation(GlobalState[handlerKey], 0.0, 0.0, rotZ)

    GlobalState[vehIdKey] = NetworkGetNetworkIdFromEntity(GlobalState[handlerKey])

    SetEntityCoords(GlobalState[handlerKey], spawnCoords.x, spawnCoords.y, -4.0)
    FreezeEntityPosition(GlobalState[handlerKey], true)
    SetEntityRotation(GlobalState[handlerKey], 0.0, 0.0, rotZ)
end

-- ─── Database / yacht state ────────────────────────────────────────────────
local DOOR_COUNT = Config.YachtDoorCount or 41
local HOTTUB_SEAT_COUNT = Config.YachtHottubSeatCount or 11

local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local out = {}
    for k, v in pairs(t) do out[k] = deepCopy(v) end
    return out
end

-- Per-yacht data that is stored as one JSON column (upgrades now, more later).
function DefaultYachtExtras()
    return {
        enginetier = 1, storagetier = 1,
        fuel = (Config.Fuel and Config.Fuel.startFuel) or 100.0,
        insured = false, lastrecovery = 0,
        layouts = {}, lightmode = "on", radio = false, radioowned = false,
        hullowned = false, hullon = false, hullcolor = 1, tenders = {},
    }
end

local function MergeExtras(raw)
    local out = DefaultYachtExtras()
    if type(raw) == "string" then raw = json.decode(raw) end
    if type(raw) == "table" then
        for k, v in pairs(raw) do out[k] = v end
    end
    return out
end

-- quiet = save only (no broadcast); used for frequent changes such as fuel.
function SaveYachtExtras(yachtId, quiet, sync)
    local yacht = yachts["yacht-" .. yachtId]
    if not yacht then return end
    yacht.extrasDirty = false
    if sync then
        MySQL.update.await("UPDATE yachts SET extras = ? WHERE yachtid = ?", { json.encode(yacht.extras), yachtId })
    else
        MySQL.update("UPDATE yachts SET extras = ? WHERE yachtid = ?", { json.encode(yacht.extras), yachtId })
    end
    if not quiet then
        TriggerClientEvent("asyacht:Global:YachtExtras", -1, yachtId, yacht.extras)
    end
end

function SaveDirtyYachtExtras(sync)
    for _, yacht in pairs(yachts) do
        if yacht.extrasDirty then SaveYachtExtras(yacht.yachtid, true, sync) end
    end
end

local function EnsureSchema()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `yachts` (
          `yachtid` int(11) NOT NULL AUTO_INCREMENT,
          `identifier` varchar(255) NOT NULL,
          `coords` longtext NOT NULL,
          `rotation` longtext NOT NULL,
          `flagid` int(11) NOT NULL DEFAULT 1,
          `lightid` int(11) NOT NULL DEFAULT 1,
          `lighcategoryid` int(11) NOT NULL DEFAULT 1,
          `uppertext` varchar(255) NOT NULL DEFAULT '',
          `bottomtext` varchar(255) NOT NULL DEFAULT '',
          `railingid` int(11) NOT NULL DEFAULT 1,
          `colorid` int(11) NOT NULL DEFAULT 1,
          `permissions` longtext NOT NULL,
          `furnitures` longtext NOT NULL,
          `extras` longtext NULL,
          PRIMARY KEY (`yachtid`),
          KEY `identifier` (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Upgrade older installs whose yachtid was not AUTO_INCREMENT (runs once).
    local extra = MySQL.scalar.await([[
        SELECT EXTRA FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'yachts' AND COLUMN_NAME = 'yachtid'
    ]])
    if extra and not tostring(extra):lower():find("auto_increment", 1, true) then
        MySQL.query.await("ALTER TABLE `yachts` MODIFY `yachtid` int(11) NOT NULL AUTO_INCREMENT")
        print("[as-yacht] Upgraded yachts.yachtid to AUTO_INCREMENT")
    end

    -- Upgrade installs created before paid upgrades existed (runs once).
    local hasExtras = MySQL.scalar.await([[
        SELECT COUNT(*) FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'yachts' AND COLUMN_NAME = 'extras'
    ]])
    if tonumber(hasExtras) == 0 then
        MySQL.query.await("ALTER TABLE `yachts` ADD COLUMN `extras` longtext NULL")
        print("[as-yacht] Added yachts.extras column")
    end
end

-- Builds the in-memory state for one yacht.
local function BuildYachtState(d)
    local doors = {}
    for i = 1, DOOR_COUNT do doors[i] = { opened = false } end
    local seats = {}
    for i = 1, HOTTUB_SEAT_COUNT do seats[i] = { taken = false, takenplayerid = nil } end

    return {
        yachtcurrentanchoreddata = { coords = d.coords, rotation = d.rotation, heading = 0.0 },
        owner = d.owner,
        driverid = nil,
        driverleave = false,
        furniture = { decorating = false, decoratingid = nil },
        yachtid = d.yachtid,
        removeinprogress = false,
        doors = doors,
        hottubseats = seats,
        flagdata = { flagid = d.flagid },
        lighting = { lightingcategory = d.lightcategory, lightingid = d.lightid },
        railing = { railingid = d.railingid },
        textdata = { uppertext = d.uppertext, bottomtext = d.bottomtext },
        yachtcolor = d.colorid,
        furnitures = d.furnitures or {},
        permissions = d.permissions or {},
        extras = MergeExtras(d.extras),
    }
end

-- Publishes a yacht's state to GlobalState and registers its storages.
local function RegisterYachtWorld(yachtId, coords, rotation)
    GlobalState["asyacht-" .. yachtId .. "-anchored"] = true
    GlobalState["asyacht-" .. yachtId .. "-vehhandler"] = nil
    GlobalState["asyacht-" .. yachtId .. "-vehid"] = nil
    GlobalState["asyacht-" .. yachtId .. "-coords"] = vector3(coords.x, coords.y, -4.0)
    GlobalState["asyacht-" .. yachtId .. "-rotation"] = vector3(0.0, 0.0, rotation.z)
    RegisterStorages(yachtId)
end

local function sendYachtToClients(target, yacht)
    TriggerClientEvent("asyacht:Global:CreateYacht", target, yacht.yachtid, yacht.flagdata.flagid, {
        category = yacht.lighting.lightingcategory,
        id = yacht.lighting.lightingid
    }, {
        uppertext = yacht.textdata.uppertext,
        bottomtext = yacht.textdata.bottomtext
    }, yacht.railing.railingid, yacht.yachtcolor, yacht.furnitures)
    TriggerClientEvent("asyacht:Global:YachtExtras", target, yacht.yachtid, yacht.extras)
end

function LoadYachts()
    EnsureSchema()
    local result = MySQL.query.await("SELECT * FROM yachts") or {}

    for _, row in ipairs(result) do
        local coordsData = json.decode(row.coords)
        local rotationData = json.decode(row.rotation)
        local c = coordsData.coords or coordsData
        local r = rotationData.rotation or rotationData

        local furnitures = {}
        for fId, fData in pairs(json.decode(row.furnitures) or {}) do
            furnitures[fId] = {
                furnituremodel = fData.furnituremodel,
                furniturecoords = vector3(fData.furniturecoords.x, fData.furniturecoords.y, fData.furniturecoords.z),
                furniturerotation = vector3(fData.furniturerotation.x, fData.furniturerotation.y, fData.furniturerotation.z),
                free = fData.free,
            }
        end

        local yacht = BuildYachtState({
            yachtid = row.yachtid, owner = row.identifier,
            coords = vector3(c.x, c.y, c.z), rotation = vector3(r.x, r.y, r.z),
            flagid = row.flagid, lightcategory = row.lighcategoryid, lightid = row.lightid,
            railingid = row.railingid, colorid = row.colorid,
            uppertext = row.uppertext, bottomtext = row.bottomtext,
            furnitures = furnitures, permissions = json.decode(row.permissions) or {},
            extras = row.extras,
        })
        yachts["yacht-" .. row.yachtid] = yacht
        RegisterYachtWorld(row.yachtid, yacht.yachtcurrentanchoreddata.coords, yacht.yachtcurrentanchoreddata.rotation)

        if Config.DisableYachtDrive == false and Config.ServerNetworkYacht == true then
            SpawnYacht(row.yachtid, nil)
        end
    end
    yachtsLoaded = true

    for _, playerId in ipairs(GetPlayers()) do
        local pSrc = tonumber(playerId)
        local identifier = GetPlayerIdentifierYacht(pSrc)
        for _, yacht in pairs(yachts) do
            sendYachtToClients(pSrc, yacht)
        end
        if identifier and identifier ~= "" then
            for _, yacht in pairs(yachts) do
                if yacht.owner == identifier then
                    TriggerClientEvent("asyacht:Global:CreateYachtBlip", pSrc, yacht.yachtid)
                end
            end
        end
    end
end

-- Single implementation behind CreateYacht / CreateYachtCommand / CreateYachtIdentifier.
-- o = { flagid, lightdata = {category,id}, textdata = {uppertext,bottomtext}, railingid, colorid, equipmentid }
-- Returns the new yachtId (or nil). Must run inside a thread/event handler (uses awaits).
function CreateYachtRecord(owner, coords, rotation, o)
    if not owner or owner == "" then return nil end

    local furnitures = {}
    if o.equipmentid == 2 then
        furnitures = deepCopy(Config.BasicEquipment or {}) -- copy: never share one table between yachts
        for _, f in pairs(furnitures) do f.free = true end  -- free items are not refunded on sell
    end

    local yachtId = MySQL.insert.await(
        "INSERT INTO yachts (identifier, coords, rotation, flagid, lightid, lighcategoryid, uppertext, bottomtext, railingid, colorid, permissions, furnitures) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)",
        {
            owner, json.encode({ coords = coords }), json.encode({ rotation = rotation }),
            o.flagid, o.lightdata.id, o.lightdata.category, o.textdata.uppertext, o.textdata.bottomtext,
            o.railingid, o.colorid, json.encode({}), json.encode(furnitures),
        }
    )
    if not yachtId then return nil end

    local yacht = BuildYachtState({
        yachtid = yachtId, owner = owner, coords = coords, rotation = rotation,
        flagid = o.flagid, lightcategory = o.lightdata.category, lightid = o.lightdata.id,
        railingid = o.railingid, colorid = o.colorid,
        uppertext = o.textdata.uppertext, bottomtext = o.textdata.bottomtext,
        furnitures = furnitures,
    })
    yachts["yacht-" .. yachtId] = yacht
    RegisterYachtWorld(yachtId, coords, rotation)
    sendYachtToClients(-1, yacht)
    return yachtId
end

function CreateYacht(playersource, coords, rotation, colorid, lightdata, textdata, railingid, flagid, equipmentid)
    local yachtId = CreateYachtRecord(GetPlayerIdentifierYacht(playersource), coords, rotation, {
        flagid = flagid, lightdata = lightdata, textdata = textdata,
        railingid = railingid, colorid = colorid, equipmentid = equipmentid,
    })
    if not yachtId then return nil end
    TriggerClientEvent("asyacht:Global:SpawnPlayerOnYacht", playersource, yachtId)
    TriggerClientEvent("asyacht:Notify", playersource, Language[Config.Language].yachtgot)
    TriggerClientEvent("asyacht:Global:YachtGotPlayer", playersource, yachtId)
    LogYacht("Yacht purchased", ("%s (%s) bought yacht #%s"):format(GetPlayerNameYacht(playersource), GetPlayerIdentifierYacht(playersource), yachtId))
    return yachtId
end

function CreateYachtCommand(playersource, coords, rotation, flagid, lightdata, textdata, railingid, colorid, equipmentid)
    local yachtId = CreateYachtRecord(GetPlayerIdentifierYacht(playersource), coords, rotation, {
        flagid = flagid, lightdata = lightdata, textdata = textdata,
        railingid = railingid, colorid = colorid, equipmentid = equipmentid,
    })
    if not yachtId then return nil end
    TriggerClientEvent("asyacht:Global:CreateYachtBlip", playersource, yachtId)
    TriggerClientEvent("asyacht:Notify", playersource, Language[Config.Language].yachtgot)
    return yachtId
end

function CreateYachtIdentifier(identifier, coords, rotation, flagid, lightdata, textdata, railingid, colorid, equipmentid)
    return CreateYachtRecord(identifier, coords, rotation, {
        flagid = flagid, lightdata = lightdata, textdata = textdata,
        railingid = railingid, colorid = colorid, equipmentid = equipmentid,
    })
end

-- Furniture saves are debounced: many moves in a row become one write.
local pendingFurnitureSave = {}

local function writeFurniture(yachtId)
    local yacht = yachts["yacht-" .. yachtId]
    if yacht then
        MySQL.update("UPDATE yachts SET furnitures = ? WHERE yachtid = ?", { json.encode(yacht.furnitures), yachtId })
    end
end

function updateYachtFurniture(yachtId, furnitures)
    if pendingFurnitureSave[yachtId] then return end
    pendingFurnitureSave[yachtId] = true
    SetTimeout(2000, function()
        pendingFurnitureSave[yachtId] = nil
        writeFurniture(yachtId)
    end)
end

function FlushFurnitureSaves()
    for yachtId in pairs(pendingFurnitureSave) do
        local yacht = yachts["yacht-" .. yachtId]
        if yacht then
            MySQL.update.await("UPDATE yachts SET furnitures = ? WHERE yachtid = ?", { json.encode(yacht.furnitures), yachtId })
        end
    end
    pendingFurnitureSave = {}
end

function updateYachtPermissions(yachtId, permissions)
    MySQL.update("UPDATE yachts SET permissions = ? WHERE yachtid = ?", { json.encode(permissions), yachtId })
end

function updateYachtOwner(yachtId, identifier)
    MySQL.update("UPDATE yachts SET identifier = ? WHERE yachtid = ?", { identifier, yachtId })
end

function RemoveYachtDatabase(yachtId)
    MySQL.update("DELETE FROM yachts WHERE yachtid = ?", { yachtId })
end

function updateYachtLocation(yachtId, coords, rotation)
    MySQL.update("UPDATE yachts SET coords = ?, rotation = ? WHERE yachtid = ?",
        { json.encode({ coords = coords }), json.encode({ rotation = rotation }), yachtId })
end

-- Finds the online player (server id) for an identifier, or nil.
function GetSourceByIdentifier(identifier)
    for _, pid in ipairs(GetPlayers()) do
        pid = tonumber(pid)
        if GetPlayerIdentifierYacht(pid) == identifier then return pid end
    end
    return nil
end

local furniturePriceByModel
local function getFurniturePrice(model)
    if not furniturePriceByModel then
        furniturePriceByModel = {}
        for _, cat in pairs(Config.Furnitures or {}) do
            for _, item in pairs(cat.categoryobjects or {}) do
                furniturePriceByModel[item.furnitureobject] = item.furnitureprice
            end
        end
    end
    return furniturePriceByModel[model] or 0
end

function GetFurnitureRefund(yacht)
    local pct = Config.FurnitureRefundPercentage or 0
    if pct <= 0 then return 0 end
    local total = 0
    for _, f in pairs(yacht.furnitures) do
        if not f.free then total = total + getFurniturePrice(f.furnituremodel) end
    end
    return math.floor(total * pct / 100)
end

-- Deletes a yacht everywhere (world, clients, database, memory). Used by sell, admin delete and exports.
function RemoveYachtFully(yachtId)
    local yacht = yachts["yacht-" .. yachtId]
    if not yacht or yacht.removeinprogress then return false end
    yacht.removeinprogress = true

    -- Move anyone still aboard back to shore so they don't fall into the sea.
    local c = GlobalState["asyacht-" .. yachtId .. "-coords"]
    for _, pid in ipairs(GetPlayers()) do
        pid = tonumber(pid)
        local ped = GetPlayerPed(pid)
        if c and ped and ped ~= 0 and #(GetEntityCoords(ped) - vector3(c.x, c.y, c.z)) <= 150.0 then
            SetEntityCoords(ped, Config.YachtBuyLocation.coords)
        end
    end

    TriggerClientEvent("asyacht:Global:RemoveYacht", -1, yachtId)
    local ownerSrc = GetSourceByIdentifier(yacht.owner)
    if ownerSrc then TriggerClientEvent("asyacht:Global:RemoveYachtBlip", ownerSrc, yachtId) end

    local handlerKey = "asyacht-" .. yachtId .. "-vehhandler"
    local vehicleHandler = GlobalState[handlerKey]
    if vehicleHandler and DoesEntityExist(vehicleHandler) then
        DeleteEntity(vehicleHandler)
    end
    for _, suffix in ipairs({ "anchored", "vehhandler", "vehid", "coords", "rotation" }) do
        GlobalState["asyacht-" .. yachtId .. "-" .. suffix] = nil
    end

    pendingFurnitureSave[yachtId] = nil
    RemoveYachtDatabase(yachtId)
    yachts["yacht-" .. yachtId] = nil
    return true
end

-- Changes a yacht's owner (no consent prompt - callers handle that).
function DoTransferYacht(yachtId, newIdentifier)
    local yacht = yachts["yacht-" .. yachtId]
    if not yacht or not newIdentifier or newIdentifier == "" then return false end
    local oldSrc = GetSourceByIdentifier(yacht.owner)
    local newSrc = GetSourceByIdentifier(newIdentifier)

    yacht.permissions[newIdentifier] = nil
    yacht.owner = newIdentifier
    updateYachtOwner(yachtId, newIdentifier)
    updateYachtPermissions(yachtId, yacht.permissions)
    if newSrc then TriggerClientEvent("asyacht:Global:CreateYachtBlip", newSrc, yachtId) end
    if oldSrc then TriggerClientEvent("asyacht:Global:RemoveYachtBlip", oldSrc, yachtId) end
    return true
end

function CalculateYachtPrice(lightingCategory, railingId, equipmentId)
    local totalPrice = Config.YachtPriceSettings.yachtprice
    if Config.YachtPriceSettings.yachtlightingprice[lightingCategory] then
        totalPrice = totalPrice + Config.YachtPriceSettings.yachtlightingprice[lightingCategory]
    end
    local railing = Config.RailingTypes[railingId]
    if railing then
        totalPrice = totalPrice + railing.price
    end
    if Config.YachtPriceSettings.yachtequipmentprice[equipmentId] then
        totalPrice = totalPrice + Config.YachtPriceSettings.yachtequipmentprice[equipmentId]
    end
    return totalPrice
end

function findFreeYachtSpawn(yachtsList)
    local found = false
    local freeCoords = nil
    local freeRotation = nil

    for _, spawnData in pairs(Config.YachtSpawnLocations) do
        local isFree = true
        for _, yachtData in pairs(yachtsList) do
            if yachtData.yachtcurrentanchoreddata and yachtData.yachtcurrentanchoreddata.coords then
                local dist = #(yachtData.yachtcurrentanchoreddata.coords - spawnData.coords)
                if dist < 200.0 then
                    isFree = false
                    break
                end
            end
        end
        if isFree then
            found = true
            freeCoords = spawnData.coords
            freeRotation = spawnData.rotation
            break
        end
    end

    return found, freeCoords, freeRotation
end

function IsPlayerYachtOwnerPermission(yachtId, playersource)
    local yacht = yachts["yacht-" .. yachtId]
    if yacht and yacht.owner == GetPlayerIdentifierYacht(playersource) then
        return true
    end
    return false
end

function HasPlayerDrivePermission(yachtId, playersource)
    local yacht = yachts["yacht-" .. yachtId]
    if yacht and yacht.permissions then
        local identifier = GetPlayerIdentifierYacht(playersource)
        if yacht.permissions[identifier] and yacht.permissions[identifier].yachtcontrol == true then
            return true
        end
    end
    return false
end

function HasPlayerDoorPermission(yachtId, playersource)
    local yacht = yachts["yacht-" .. yachtId]
    if yacht and yacht.permissions then
        local identifier = GetPlayerIdentifierYacht(playersource)
        if yacht.permissions[identifier] and yacht.permissions[identifier].dooraccess == true then
            return true
        end
    end
    return false
end

function HasPlayerFurniturePermission(yachtId, playersource)
    local yacht = yachts["yacht-" .. yachtId]
    if yacht and yacht.permissions then
        local identifier = GetPlayerIdentifierYacht(playersource)
        if yacht.permissions[identifier] and yacht.permissions[identifier].furnituremanagment == true then
            return true
        end
    end
    return false
end

function HasPlayerStoragePermission(yachtId, playersource)
    local yacht = yachts["yacht-" .. yachtId]
    if yacht and yacht.permissions then
        local identifier = GetPlayerIdentifierYacht(playersource)
        if yacht.permissions[identifier] and yacht.permissions[identifier].storageaccess == true then
            return true
        end
    end
    return false
end

function HasPlayerWardrobePermission(yachtId, playersource)
    local yacht = yachts["yacht-" .. yachtId]
    if yacht and yacht.permissions then
        local identifier = GetPlayerIdentifierYacht(playersource)
        if yacht.permissions[identifier] and yacht.permissions[identifier].wardrobeaccess == true then
            return true
        end
    end
    return false
end

if Config.DisableYachtDrive == false then
    function DriveYacht(yachtId, playersource)
        local yacht = yachts["yacht-" .. yachtId]
        if yacht then
            local hasPerm = HasPlayerDrivePermission(yachtId, playersource)
            local isOwner = IsPlayerYachtOwnerPermission(yachtId, playersource)
            if hasPerm or isOwner then
                if Config.Fuel and Config.Fuel.enabled and (yacht.extras.fuel or 0) <= 0 then
                    TriggerClientEvent("asyacht:Notify", playersource, Language[Config.Language].outoffuel, "error")
                    return
                end
                if GlobalState["asyacht-" .. yachtId .. "-anchored"] == true then
                    if yacht.driverid == nil then
                        yacht.driverid = playersource
                        if Config.ServerNetworkYacht == false then
                            TriggerClientEvent("asyacht:Global:YachtClientMethod", playersource, yachtId)
                        end
                        TriggerClientEvent("asyacht:Global:AttachPlayer", -1, yachtId)

                        if Config.ServerNetworkYacht == true then
                            TriggerClientEvent("asyacht:Global:DriveProtect", playersource, yachtId)
                            Citizen.Wait(500)
                            local playerPed = GetPlayerPed(playersource)
                            SpawnYacht(yachtId, playerPed)
                            FreezeEntityPosition(GlobalState["asyacht-" .. yachtId .. "-vehhandler"], true)
                            GlobalState["asyacht-" .. yachtId .. "-anchored"] = false
                            TriggerClientEvent("asyacht:Global:YachtMaximumSynchronize", -1, yachtId)
                            Citizen.Wait(2000)
                            TriggerClientEvent("asyacht:Global:ReattachYacht", -1, yachtId)
                            FreezeEntityPosition(GlobalState["asyacht-" .. yachtId .. "-vehhandler"], false)
                            SetEntityCoords(GlobalState["asyacht-" .. yachtId .. "-vehhandler"], GlobalState["asyacht-" .. yachtId .. "-coords"].x, GlobalState["asyacht-" .. yachtId .. "-coords"].y, -4.0)
                            SetEntityRotation(GlobalState["asyacht-" .. yachtId .. "-vehhandler"], 0.0, 0.0, GlobalState["asyacht-" .. yachtId .. "-rotation"].z)
                            Citizen.Wait(10)
                            SetEntityCoords(GlobalState["asyacht-" .. yachtId .. "-vehhandler"], GlobalState["asyacht-" .. yachtId .. "-coords"].x, GlobalState["asyacht-" .. yachtId .. "-coords"].y, -4.0)
                            SetEntityRotation(GlobalState["asyacht-" .. yachtId .. "-vehhandler"], 0.0, 0.0, GlobalState["asyacht-" .. yachtId .. "-rotation"].z)
                            TriggerClientEvent("asyacht:Global:DriveYacht", playersource, yachtId)

                            while yacht.driverleave == false do
                                Citizen.Wait(50)
                                if GetPedInVehicleSeat(GlobalState["asyacht-" .. yachtId .. "-vehhandler"], -1) ~= playerPed then
                                    TaskWarpPedIntoVehicle(playerPed, GlobalState["asyacht-" .. yachtId .. "-vehhandler"], -1)
                                end
                                GlobalState["asyacht-" .. yachtId .. "-coords"] = GetEntityCoords(GlobalState["asyacht-" .. yachtId .. "-vehhandler"])
                            end

                            TriggerClientEvent("asyacht:Global:AttachPlayer", -1, yachtId)
                            local finalCoords = GetEntityCoords(GlobalState["asyacht-" .. yachtId .. "-vehhandler"])
                            local finalRot = GetEntityRotation(GlobalState["asyacht-" .. yachtId .. "-vehhandler"])
                            local finalHeading = GetEntityHeading(GlobalState["asyacht-" .. yachtId .. "-vehhandler"])

                            SetEntityRotation(GlobalState["asyacht-" .. yachtId .. "-vehhandler"], 0.0, 0.0, finalRot.z)
                            SetEntityCoords(GlobalState["asyacht-" .. yachtId .. "-vehhandler"], finalCoords.x, finalCoords.y, -4.0)

                            GlobalState["asyacht-" .. yachtId .. "-coords"] = vector3(finalCoords.x, finalCoords.y, -4.0)
                            GlobalState["asyacht-" .. yachtId .. "-rotation"] = vector3(0.0, 0.0, finalRot.z)

                            yacht.yachtcurrentanchoreddata.coords = vector3(finalCoords.x, finalCoords.y, -4.0)
                            yacht.yachtcurrentanchoreddata.rotation = vector3(0.0, 0.0, finalRot.z)
                            yacht.yachtcurrentanchoreddata.heading = finalHeading

                            TaskLeaveVehicle(playerPed, GlobalState["asyacht-" .. yachtId .. "-vehhandler"], 1)
                            SetEntityCoords(playerPed, finalCoords.x, finalCoords.y, finalCoords.z)
                            Citizen.Wait(500)
                            TriggerClientEvent("asyacht:Global:YachtLeave", playersource, yachtId)

                            updateYachtLocation(yachtId, vector3(finalCoords.x, finalCoords.y, -4.0), vector3(0.0, 0.0, finalRot.z))

                            GlobalState["asyacht-" .. yachtId .. "-anchored"] = true
                            TriggerClientEvent("asyacht:Global:YachtMaximumSynchronizeAnchor", -1, yachtId)

                            yacht.driverid = nil
                            yacht.driverleave = false

                            SetEntityRotation(GlobalState["asyacht-" .. yachtId .. "-vehhandler"], 0.0, 0.0, finalRot.z)
                            SetEntityCoords(GlobalState["asyacht-" .. yachtId .. "-vehhandler"], finalCoords.x, finalCoords.y, -4.0)
                            FreezeEntityPosition(GlobalState["asyacht-" .. yachtId .. "-vehhandler"], true)

                            if DoesEntityExist(GlobalState["asyacht-" .. yachtId .. "-vehhandler"]) then
                                DeleteEntity(GlobalState["asyacht-" .. yachtId .. "-vehhandler"])
                            end
                            GlobalState["asyacht-" .. yachtId .. "-vehhandler"] = nil
                            GlobalState["asyacht-" .. yachtId .. "-vehid"] = nil

                            Citizen.Wait(4000)
                            TriggerClientEvent("asyacht:Global:DeattachPlayer", -1, yachtId)
                        else
                            while GlobalState["asyacht-" .. yachtId .. "-vehid"] == nil and yacht.driverleave == false do
                                Citizen.Wait(50)
                            end
                            GlobalState["asyacht-" .. yachtId .. "-anchored"] = false
                            TriggerClientEvent("asyacht:Global:YachtMaximumSynchronize", -1, yachtId)
                            Citizen.Wait(2500)
                            TriggerClientEvent("asyacht:Global:ReattachYacht", -1, yachtId)
                            TriggerClientEvent("asyacht:Global:DriveYachtUnfreeze", playersource, yachtId)
                            TriggerClientEvent("asyacht:Global:DeattachPlayer", -1, yachtId)

                            while yacht.driverleave == false do
                                Citizen.Wait(50)
                            end

                            TriggerClientEvent("asyacht:Global:YachtLeave", playersource, yachtId)
                            TriggerClientEvent("asyacht:Global:AttachPlayer", -1, yachtId)

                            updateYachtLocation(yachtId, vector3(GlobalState["asyacht-" .. yachtId .. "-coords"].x, GlobalState["asyacht-" .. yachtId .. "-coords"].y, -4.0), vector3(0.0, 0.0, GlobalState["asyacht-" .. yachtId .. "-rotation"].z))

                            GlobalState["asyacht-" .. yachtId .. "-anchored"] = true
                            TriggerClientEvent("asyacht:Global:YachtMaximumSynchronizeAnchor", -1, yachtId)

                            yacht.driverid = nil
                            yacht.driverleave = false
                            GlobalState["asyacht-" .. yachtId .. "-vehhandler"] = nil
                            GlobalState["asyacht-" .. yachtId .. "-vehid"] = nil

                            Citizen.Wait(4000)
                            TriggerClientEvent("asyacht:Global:DeattachPlayer", -1, yachtId)
                        end
                    end
                end
            end
        end
    end

    RegisterServerEvent("asyacht:Global:EnterYacht")
    AddEventHandler("asyacht:Global:EnterYacht", function(yachtId)
        local src = source
        if yachtId ~= nil and yachts["yacht-" .. yachtId] and isPlayerNearYacht(src, yachtId) then
            if GlobalState["asyacht-" .. yachtId .. "-anchored"] == true then
                if yachts["yacht-" .. yachtId].driverid == nil then
                    DriveYacht(yachtId, src)
                end
            end
        end
    end)

    if Config.ServerNetworkYacht == false then
        RegisterServerEvent("asyacht:Global:YachtClientMethodGet")
        AddEventHandler("asyacht:Global:YachtClientMethodGet", function(yachtId, netId)
            local src = source
            if yachtId ~= nil and yachts["yacht-" .. yachtId] then
                if yachts["yacht-" .. yachtId].driverid == src then
                    GlobalState["asyacht-" .. yachtId .. "-vehid"] = netId
                end
            end
        end)

        RegisterServerEvent("asyacht:Global:ExitYacht")
        AddEventHandler("asyacht:Global:ExitYacht", function(yachtId, finalCoords, finalRotation)
            local src = source
            if yachtId ~= nil and yachts["yacht-" .. yachtId] and isNum3(finalCoords) and isNum3(finalRotation) then
                if math.abs(finalCoords.x) > 8000.0 or math.abs(finalCoords.y) > 8000.0 then return end
                if not isPlayerNear(src, finalCoords, 400.0) then return end
                if GlobalState["asyacht-" .. yachtId .. "-anchored"] == false then
                    local yacht = yachts["yacht-" .. yachtId]
                    if yacht.driverid == src then
                        local blocked = GetAnchorBlockReason(yachtId, finalCoords)
                        if blocked and yacht.driverleave == false then
                            TriggerClientEvent("asyacht:Notify", src, blocked, "error")
                            TriggerClientEvent("asyacht:Global:ExitRejected", src, yachtId)
                            return
                        end
                        if yacht.driverleave == false and ChargeDockingFee and not ChargeDockingFee(src, finalCoords) then
                            TriggerClientEvent("asyacht:Global:ExitRejected", src, yachtId)
                            return
                        end
                        if yacht.driverleave == false then
                            GlobalState["asyacht-" .. yachtId .. "-coords"] = vector3(finalCoords.x, finalCoords.y, -4.0)
                            GlobalState["asyacht-" .. yachtId .. "-rotation"] = vector3(0.0, 0.0, finalRotation.z)
                            yacht.yachtcurrentanchoreddata.coords = vector3(finalCoords.x, finalCoords.y, -4.0)
                            yacht.yachtcurrentanchoreddata.rotation = vector3(0.0, 0.0, finalRotation.z)
                            yacht.driverleave = true
                        end
                    end
                end
            end
        end)
    else
        RegisterServerEvent("asyacht:Global:ExitYacht")
        AddEventHandler("asyacht:Global:ExitYacht", function(yachtId)
            local src = source
            if yachtId ~= nil and yachts["yacht-" .. yachtId] then
                if GlobalState["asyacht-" .. yachtId .. "-anchored"] == false then
                    local yacht = yachts["yacht-" .. yachtId]
                    if yacht.driverid == src then
                        local handler = GlobalState["asyacht-" .. yachtId .. "-vehhandler"]
                        if handler and DoesEntityExist(handler) and yacht.driverleave == false then
                            local blocked = GetAnchorBlockReason(yachtId, GetEntityCoords(handler))
                            if blocked then
                                TriggerClientEvent("asyacht:Notify", src, blocked, "error")
                                TriggerClientEvent("asyacht:Global:ExitRejected", src, yachtId)
                                return
                            end
                            if ChargeDockingFee and not ChargeDockingFee(src, GetEntityCoords(handler)) then
                                TriggerClientEvent("asyacht:Global:ExitRejected", src, yachtId)
                                return
                            end
                        end
                        if yacht.driverleave == false then
                            yacht.driverleave = true
                        end
                    end
                end
            end
        end)
    end
end

-- The driver's client reports the live position every few seconds (client-networked yachts),
-- used by the autosave and when the driver disconnects mid-sail.
RegisterServerEvent("asyacht:Global:DriveTick")
AddEventHandler("asyacht:Global:DriveTick", function(yachtId, coords, rot)
    local src = source
    local yacht = yachts["yacht-" .. tostring(yachtId)]
    if not yacht or yacht.driverid ~= src or GlobalState["asyacht-" .. yacht.yachtid .. "-anchored"] ~= false then return end
    if not isNum3(coords) or not isNum3(rot) then return end
    if math.abs(coords.x) > 8000.0 or math.abs(coords.y) > 8000.0 then return end
    if not isPlayerNear(src, coords, 400.0) then return end
    yacht.livepos = {
        coords = vector3(coords.x, coords.y, -4.0),
        rotation = vector3(0.0, 0.0, rot.z),
        at = GetGameTimer(),
    }
    if ConsumeFuel then ConsumeFuel(yacht, yacht.livepos.coords, src) end
end)

RegisterServerEvent("asyacht:Global:SynchronizeYacht")
AddEventHandler("asyacht:Global:SynchronizeYacht", function()
    local src = source

    while not yachtsLoaded do
        Citizen.Wait(100)
    end

    local identifier = GetPlayerIdentifierYacht(src)

    for _, yacht in pairs(yachts) do
        TriggerClientEvent("asyacht:Global:CreateYacht", src, yacht.yachtid, yacht.flagdata.flagid, {
            category = yacht.lighting.lightingcategory,
            id = yacht.lighting.lightingid
        }, {
            uppertext = yacht.textdata.uppertext,
            bottomtext = yacht.textdata.bottomtext
        }, yacht.railing.railingid, yacht.yachtcolor, yacht.furnitures)
    end

    Citizen.Wait(500)

    if identifier and identifier ~= "" then
        for _, yacht in pairs(yachts) do
            if yacht.owner == identifier then
                TriggerClientEvent("asyacht:Global:CreateYachtBlip", src, yacht.yachtid)
            end
        end
    end
end)

-- Returns ok, languageKey, ...args. excludeYachtId lets an owner keep/re-use their own name.
function ValidateYachtName(textData, excludeYachtId)
    local rules = Config.NameRules or {}
    local upper, bottom = textData.uppertext or "", textData.bottomtext or ""
    local minLen, maxLen = rules.minLength or 1, rules.maxLength or Limits.textMaxLength
    if #upper < minLen or #upper > maxLen or #bottom < minLen or #bottom > maxLen then
        return false, "namelength", minLen, maxLen
    end
    local combined = (upper .. " " .. bottom):lower()
    for _, word in ipairs(rules.blockedWords or {}) do
        if word ~= "" and combined:find(word:lower(), 1, true) then
            return false, "nameblocked"
        end
    end
    if rules.unique then
        local u, b = upper:lower(), bottom:lower()
        for _, y in pairs(yachts) do
            if y.yachtid ~= excludeYachtId and y.textdata
                and (y.textdata.uppertext or ""):lower() == u and (y.textdata.bottomtext or ""):lower() == b then
                return false, "nametaken"
            end
        end
    end
    return true
end

-- Returns a language string when the yacht may not be anchored at coords, otherwise nil.
function GetAnchorBlockReason(yachtId, coords)
    local rules = Config.AnchorRules or {}
    local flat = vector3(coords.x, coords.y, 0.0)
    local minD = rules.minDistance or 0
    if minD > 0 then
        for _, y in pairs(yachts) do
            if y.yachtid ~= yachtId and GlobalState["asyacht-" .. y.yachtid .. "-anchored"] == true then
                local c = GlobalState["asyacht-" .. y.yachtid .. "-coords"] or y.yachtcurrentanchoreddata.coords
                if c and #(flat - vector3(c.x, c.y, 0.0)) < minD then
                    return Language[Config.Language].anchortooclose
                end
            end
        end
    end
    for _, zone in ipairs(rules.blockedZones or {}) do
        if #(flat - vector3(zone.coords.x, zone.coords.y, 0.0)) < zone.radius then
            return Language[Config.Language].anchorblockedzone
        end
    end
    return nil
end

if Config.DisableYachtBuy == false then
    local function SendBuyBalances(src)
        TriggerClientEvent("asyacht:Global:BuyMenuBalances", src, GetMoneyYacht(src, "cash"), GetMoneyYacht(src, "bank"))
    end

    -- The menu stays open after a recoverable problem so the buyer can fix it.
    local function RejectBuy(src, message)
        playersInBuyPreview[src] = true
        TriggerClientEvent("asyacht:Notify", src, message, "error")
        TriggerClientEvent("asyacht:Global:BuyRejected", src)
        SendBuyBalances(src)
    end

    local function AbortBuy(src, message)
        playersInBuyPreview[src] = nil
        SetPlayerRoutingBucket(src, 0)
        if message then TriggerClientEvent("asyacht:Notify", src, message, "error") end
        TriggerClientEvent("asyacht:Global:CloseYachtBuyMenu", src)
    end

    RegisterServerEvent("asyacht:Global:BuyYacht")
    AddEventHandler("asyacht:Global:BuyYacht", function(colorId, lightData, textData, railingId, flagId, equipmentId, paymentMethod, upgrades)
        local src = source
        if playersInBuyPreview[src] == nil then return end -- also blocks double submits
        playersInBuyPreview[src] = nil

        local account = paymentMethod or (Config.Payment and Config.Payment.default) or "cash"
        local accountAllowed = false
        for _, m in ipairs((Config.Payment and Config.Payment.methods) or { "cash" }) do
            if m == account then accountAllowed = true end
        end

        local valid = type(lightData) == "table" and type(textData) == "table"
            and isInt(colorId, Limits.color) and isInt(flagId, Limits.flag)
            and isInt(railingId, Limits.railing) and isInt(equipmentId, Limits.equipment)
            and isInt(lightData.category, Limits.lightCategory) and isInt(lightData.id, Limits.lightId)
        if not valid then return AbortBuy(src) end
        if not accountAllowed then return RejectBuy(src, Language[Config.Language].invalidpayment) end

        textData = { uppertext = sanitizeText(textData.uppertext), bottomtext = sanitizeText(textData.bottomtext) }
        local identifier = GetPlayerIdentifierYacht(src)
        if Config.OneYachtPerPlayer ~= false and playerOwnsYacht(identifier) then
            return AbortBuy(src, Language[Config.Language].alreadyhasayacht)
        end

        local nameOk, nameKey, a1, a2 = ValidateYachtName(textData, nil)
        if not nameOk then
            return RejectBuy(src, LanguageFile(nameKey, a1, a2))
        end

        local found, freeCoords, freeRotation = findFreeYachtSpawn(yachts)
        if not found then
            return AbortBuy(src, Language[Config.Language].nospaceforyacht)
        end

        -- optional upgrades picked in the buy menu (tier 1 / style 1 are the free defaults)
        local U = Config.Upgrades or {}
        local picked = { engine = 1, storage = 1, tenders = {}, tenderCount = {} }
        local upgradePrice = 0
        if type(upgrades) == "table" and U.enabled then
            local e, st = tonumber(upgrades.engine) or 1, tonumber(upgrades.storage) or 1
            if not (U.engine and U.engine[e] and U.storage and U.storage[st]) then return AbortBuy(src) end
            picked.engine, picked.storage = e, st

            -- boats / jet skis / helicopters bought with the yacht
            local tcfg = Config.Comfort and Config.Comfort.tender
            if type(upgrades.tenders) == "table" and tcfg and tcfg.enabled then
                local seen = {}
                for _, tid in ipairs(upgrades.tenders) do
                    tid = tonumber(tid)
                    if tid and not seen[tid] then
                        seen[tid] = true
                        local found
                        for _, o in ipairs(tcfg.options) do if o.id == tid then found = o end end
                        if not found then return AbortBuy(src) end
                        local cat = found.category or "Vehicles"
                        picked.tenderCount[cat] = (picked.tenderCount[cat] or 0) + 1
                        if picked.tenderCount[cat] > (TenderLimit and TenderLimit(cat) or 0) then
                            return RejectBuy(src, LanguageFile("tenderlimit", TenderLimit and TenderLimit(cat) or 0, cat))
                        end
                        picked.tenders[#picked.tenders + 1] = tid
                        upgradePrice = upgradePrice + (found.price or 0)
                    end
                end
            end
            if e > 1 then upgradePrice = upgradePrice + (U.engine[e].price or 0) end
            if st > 1 then upgradePrice = upgradePrice + (U.storage[st].price or 0) end
        end

        local price = CalculateYachtPrice(lightData.category, railingId, equipmentId) + upgradePrice
        if price > GetMoneyYacht(src, account) then
            return RejectBuy(src, LanguageFile("nomoneyenoughaccount", account))
        end

        RemoveMoneyYacht(src, price, account)
        TriggerClientEvent("asyacht:Notify", src, LanguageFile("yachtbought", price), "success")
        SetPlayerRoutingBucket(src, 0)
        TriggerClientEvent("asyacht:Global:CloseYachtBuyMenu", src)
        local newId = CreateYacht(src, freeCoords, freeRotation, colorId, lightData, textData, railingId, flagId, equipmentId)
        local newYacht = newId and yachts["yacht-" .. newId]
        if newYacht and (picked.engine > 1 or picked.storage > 1 or #picked.tenders > 0) then
            newYacht.extras.enginetier, newYacht.extras.storagetier = picked.engine, picked.storage
            for _, tid in ipairs(picked.tenders) do newYacht.extras.tenders[tostring(tid)] = true end
            -- put the vehicles bought with the yacht in the water next to it
            local tcfg = Config.Comfort and Config.Comfort.tender
            for _, tid in ipairs(picked.tenders) do
                for _, opt in ipairs((tcfg and tcfg.options) or {}) do
                    if opt.id == tid then
                        TriggerClientEvent("asyacht:Global:TenderApproved", src, newId, opt.model, opt.id, true)
                    end
                end
            end
            SaveYachtExtras(newId)
            if picked.storage > 1 and ApplyYachtStorageTier then ApplyYachtStorageTier(newId) end
        end
        LogYacht("Yacht purchased", ("%s bought yacht #%s (%s %s) for $%s (%s)"):format(
            identifier, tostring(newId), textData.uppertext, textData.bottomtext, price, account))
    end)

    RegisterServerEvent("asyacht:Global:OpenYachtBuy")
    AddEventHandler("asyacht:Global:OpenYachtBuy", function()
        local src = source
        if not isPlayerNear(src, Config.YachtBuyLocation.coords, (Config.YachtBuyLocation.distance or 2.0) + 15.0) then return end
        playersInBuyPreview[src] = true
        SetPlayerRoutingBucket(src, 1000 + src) -- offset avoids colliding with buckets used by other resources
        TriggerClientEvent("asyacht:Global:OpenYachtBuyClient", src)
        SendBuyBalances(src)
    end)

    RegisterServerEvent("asyacht:Global:CloseYachtBuy")
    AddEventHandler("asyacht:Global:CloseYachtBuy", function()
        local src = source
        playersInBuyPreview[src] = nil
        SetPlayerRoutingBucket(src, 0)
        TriggerClientEvent("asyacht:Global:CloseYachtBuyMenu", src)
    end)
end

RegisterServerEvent("asyacht:Global:OpenCloseDoor")
AddEventHandler("asyacht:Global:OpenCloseDoor", function(yachtId, doorIndex)
    local src = source
    if yachtId ~= nil and yachts["yacht-" .. yachtId] then
        local yacht = yachts["yacht-" .. yachtId]
        local door = yacht.doors[doorIndex]
        if door then
            local hasPerm = HasPlayerDoorPermission(yachtId, src)
            local isOwner = IsPlayerYachtOwnerPermission(yachtId, src)
            if hasPerm or isOwner then
                if door.opened == false then
                    door.opened = true
                    TriggerClientEvent("asyacht:Global:CloseOpenHandler", -1, yachtId, doorIndex, true)
                else
                    door.opened = false
                    TriggerClientEvent("asyacht:Global:CloseOpenHandler", -1, yachtId, doorIndex, false)
                end
            end
        end
    end
end)

RegisterServerEvent("asyacht:Global:CloseFurniture")
AddEventHandler("asyacht:Global:CloseFurniture", function(yachtId)
    local src = source
    if yachtId ~= nil and yachts["yacht-" .. yachtId] then
        local yacht = yachts["yacht-" .. yachtId]
        if yacht.furniture.decorating == true and yacht.furniture.decoratingid == src then
            yacht.furniture.decorating = false
            yacht.furniture.decoratingid = nil
        end
    end
end)

if Config.DisableYachtFurniture == false then
    RegisterServerEvent("asyacht:Global:OpenFurnitureShop")
    AddEventHandler("asyacht:Global:OpenFurnitureShop", function(yachtId)
        local src = source
        if yachtId ~= nil and yachts["yacht-" .. yachtId] then
            local yacht = yachts["yacht-" .. yachtId]
            local hasPerm = HasPlayerFurniturePermission(yachtId, src)
            local isOwner = IsPlayerYachtOwnerPermission(yachtId, src)
            if hasPerm or isOwner then
                if yacht.furniture.decorating == false then
                    yacht.furniture.decorating = true
                    yacht.furniture.decoratingid = src
                    TriggerClientEvent("asyacht:Global:FurnitureShop", src, yachtId)
                end
            end
        end
    end)

    RegisterServerEvent("asyacht:Global:OpenFurnitureEdit")
    AddEventHandler("asyacht:Global:OpenFurnitureEdit", function(yachtId)
        local src = source
        if yachtId ~= nil and yachts["yacht-" .. yachtId] then
            local yacht = yachts["yacht-" .. yachtId]
            local hasPerm = HasPlayerFurniturePermission(yachtId, src)
            local isOwner = IsPlayerYachtOwnerPermission(yachtId, src)
            if hasPerm or isOwner then
                if yacht.furniture.decorating == false then
                    yacht.furniture.decorating = true
                    yacht.furniture.decoratingid = src
                    TriggerClientEvent("asyacht:Global:FurnitureEdit", src, yachtId)
                end
            end
        end
    end)
end

RegisterServerEvent("asyacht:Global:OpenAddPermissionPlayer")
AddEventHandler("asyacht:Global:OpenAddPermissionPlayer", function(yachtId, playersInArea)
    local src = source
    if yachtId ~= nil and yachts["yacht-" .. yachtId] then
        local isOwner = IsPlayerYachtOwnerPermission(yachtId, src)
        if isOwner then
            local playersList = {}
            for _, playerId in ipairs(getNearbyPlayers(src, 30.0)) do
                local pName = GetPlayerNameYacht(playerId)
                if pName then
                    playersList[#playersList + 1] = { playerid = playerId, playername = pName }
                end
            end
            TriggerClientEvent("asyacht:Global:OpenAddPermissionPlayerClient", src, yachtId, playersList)
        end
    end
end)

RegisterServerEvent("asyacht:Global:AddPermissionPlayer")
AddEventHandler("asyacht:Global:AddPermissionPlayer", function(yachtId, targetPlayerId)
    local src = source
    if yachtId ~= nil and yachts["yacht-" .. yachtId] then
        local isOwner = IsPlayerYachtOwnerPermission(yachtId, src)
        local okTarget, tId = isValidOnlinePlayer(targetPlayerId)
        if isOwner and okTarget and tId ~= src and isPlayerNear(tId, GetEntityCoords(GetPlayerPed(src)), 30.0) then
            targetPlayerId = tId
            local targetIdentifier = GetPlayerIdentifierYacht(targetPlayerId)
            local targetName = GetPlayerNameYacht(targetPlayerId)
            local yacht = yachts["yacht-" .. yachtId]

            if targetIdentifier and targetIdentifier ~= "" and yacht.permissions[tostring(targetIdentifier)] == nil then
                yacht.permissions[tostring(targetIdentifier)] = {
                    playername = targetName,
                    yachtcontrol = false,
                    dooraccess = false,
                    furnituremanagment = false,
                    storageaccess = false,
                    wardrobeaccess = false
                }
                updateYachtPermissions(yachtId, yacht.permissions)
                TriggerClientEvent("asyacht:Notify", src, LanguageFile("permissionsadded", targetName))
            end
        end
    end
end)

if Config.DisableYachtTransfer == false then
    RegisterServerEvent("asyacht:Global:OpenTransferYachtPlayer")
    AddEventHandler("asyacht:Global:OpenTransferYachtPlayer", function(yachtId, playersInArea)
        local src = source
        if yachtId ~= nil and yachts["yacht-" .. yachtId] then
            local isOwner = IsPlayerYachtOwnerPermission(yachtId, src)
            if isOwner then
                local playersList = {}
                for _, playerId in ipairs(getNearbyPlayers(src, 30.0)) do
                    local pName = GetPlayerNameYacht(playerId)
                    if pName then
                        playersList[#playersList + 1] = { playerid = playerId, playername = pName }
                    end
                end
                TriggerClientEvent("asyacht:Global:OpenTransferYachtPlayerClient", src, yachtId, playersList)
            end
        end
    end)

    local pendingTransfers = {}

    RegisterServerEvent("asyacht:Global:TransferPlayerYacht")
    AddEventHandler("asyacht:Global:TransferPlayerYacht", function(yachtId, targetPlayerId)
        local src = source
        if yachtId == nil or not yachts["yacht-" .. yachtId] then return end
        if not IsPlayerYachtOwnerPermission(yachtId, src) then return end

        local okTarget, tId = isValidOnlinePlayer(targetPlayerId)
        local targetIdentifier = okTarget and GetPlayerIdentifierYacht(tId) or nil
        if not okTarget or tId == src or not targetIdentifier or targetIdentifier == "" then return end
        if not isPlayerNear(tId, GetEntityCoords(GetPlayerPed(src)), 30.0) then return end

        if Config.TransferRequiresConsent == false then
            if DoTransferYacht(yachtId, targetIdentifier) then
                TriggerClientEvent("asyacht:Notify", src, LanguageFile("yachttransfered", GetPlayerNameYacht(tId)))
                LogYacht("Yacht transferred", ("Yacht #%s: %s -> %s"):format(yachtId, GetPlayerIdentifierYacht(src), targetIdentifier))
            end
            return
        end

        pendingTransfers[tId] = { yachtId = yachtId, from = src, fromIdentifier = GetPlayerIdentifierYacht(src), expires = GetGameTimer() + 30000 }
        TriggerClientEvent("asyacht:Notify", src, LanguageFile("transferoffersent", GetPlayerNameYacht(tId)))
        TriggerClientEvent("asyacht:Global:TransferOffer", tId, yachtId, GetPlayerNameYacht(src))
    end)

    RegisterServerEvent("asyacht:Global:TransferResponse")
    AddEventHandler("asyacht:Global:TransferResponse", function(accepted)
        local src = source
        local offer = pendingTransfers[src]
        pendingTransfers[src] = nil
        if not offer or GetGameTimer() > offer.expires then return end

        local yacht = yachts["yacht-" .. offer.yachtId]
        -- The offer is only valid if the same person still owns the yacht and is still online.
        if not yacht or yacht.owner ~= offer.fromIdentifier or GetPlayerIdentifierYacht(offer.from) ~= offer.fromIdentifier then return end

        if accepted ~= true then
            TriggerClientEvent("asyacht:Notify", offer.from, LanguageFile("transferdeclined", GetPlayerNameYacht(src)))
            return
        end

        local targetIdentifier = GetPlayerIdentifierYacht(src)
        if not targetIdentifier or targetIdentifier == "" then return end
        if Config.OneYachtPerPlayer ~= false and playerOwnsYacht(targetIdentifier) then
            TriggerClientEvent("asyacht:Notify", src, Language[Config.Language].alreadyhasayacht)
            TriggerClientEvent("asyacht:Notify", offer.from, LanguageFile("transfertargethasyacht", GetPlayerNameYacht(src)))
            return
        end
        if not isPlayerNear(src, GetEntityCoords(GetPlayerPed(offer.from)), 30.0) then return end

        if DoTransferYacht(offer.yachtId, targetIdentifier) then
            TriggerClientEvent("asyacht:Notify", offer.from, LanguageFile("yachttransfered", GetPlayerNameYacht(src)))
            LogYacht("Yacht transferred", ("Yacht #%s: %s -> %s"):format(offer.yachtId, offer.fromIdentifier, targetIdentifier))
        end
    end)
end

if Config.DisableYachtSell == false then
    RegisterServerEvent("asyacht:Global:SellPlayerYacht")
    AddEventHandler("asyacht:Global:SellPlayerYacht", function(yachtId)
        local src = source
        if yachtId == nil or not yachts["yacht-" .. yachtId] then return end
        if not IsPlayerYachtOwnerPermission(yachtId, src) then return end

        local yacht = yachts["yacht-" .. yachtId]
        if yacht.removeinprogress == false and yacht.driverid == nil then
            local sellPrice = math.floor(CalculateYachtPrice(yacht.lighting.lightingcategory, yacht.railing.railingid, 1) * (Config.YachtPriceSettings.redemptionpercentage / 100))
            local furnitureRefund = GetFurnitureRefund(yacht)

            if RemoveYachtFully(yachtId) then
                AddMoneyYacht(src, sellPrice + furnitureRefund)
                TriggerClientEvent("asyacht:Notify", src, LanguageFile("yachtsold", sellPrice))
                if furnitureRefund > 0 then
                    TriggerClientEvent("asyacht:Notify", src, LanguageFile("furniturerefunded", furnitureRefund))
                end
                LogYacht("Yacht sold", ("%s sold yacht #%s for $%s (+$%s furniture refund)"):format(GetPlayerIdentifierYacht(src), yachtId, sellPrice, furnitureRefund))
            end
        else
            TriggerClientEvent("asyacht:Notify", src, Language[Config.Language].yachtsoldnopossible)
        end
    end)
end

RegisterServerEvent("asyacht:Global:OpenManagment")
AddEventHandler("asyacht:Global:OpenManagment", function(yachtId)
    local src = source
    if yachtId ~= nil and yachts["yacht-" .. yachtId] then
        local isOwner = IsPlayerYachtOwnerPermission(yachtId, src)
        if isOwner then
            TriggerClientEvent("asyacht:Global:OpenManagmentClient", src, yachtId)
        else
            TriggerClientEvent("asyacht:Global:OpenManagmentClient2", src, yachtId)
        end
    end
end)

RegisterServerEvent("asyacht:Global:OpenPermissions")
AddEventHandler("asyacht:Global:OpenPermissions", function(yachtId)
    local src = source
    if yachtId ~= nil and yachts["yacht-" .. yachtId] then
        local isOwner = IsPlayerYachtOwnerPermission(yachtId, src)
        if isOwner then
            TriggerClientEvent("asyacht:Global:OpenPermissionsClient", src, yachtId, yachts["yacht-" .. yachtId].permissions)
        end
    end
end)

RegisterServerEvent("asyacht:Global:ChangePermissions")
AddEventHandler("asyacht:Global:ChangePermissions", function(yachtId, targetIdentifier, yachtcontrol, dooraccess, furnituremanagment, storageaccess, wardrobeaccess)
    local src = source
    if yachtId ~= nil and yachts["yacht-" .. yachtId] then
        local isOwner = IsPlayerYachtOwnerPermission(yachtId, src)
        if isOwner then
            local yacht = yachts["yacht-" .. yachtId]
            local targetPerm = yacht.permissions[tostring(targetIdentifier)]
            if targetPerm ~= nil then
                targetPerm.yachtcontrol = yachtcontrol
                targetPerm.dooraccess = dooraccess
                targetPerm.furnituremanagment = furnituremanagment
                targetPerm.storageaccess = storageaccess
                targetPerm.wardrobeaccess = wardrobeaccess
                TriggerClientEvent("asyacht:Notify", src, Language[Config.Language].permissionschanged)
                updateYachtPermissions(yachtId, yacht.permissions)
            end
        end
    end
end)

RegisterServerEvent("asyacht:Global:DeletePermissions")
AddEventHandler("asyacht:Global:DeletePermissions", function(yachtId, targetIdentifier)
    local src = source
    if yachtId ~= nil and yachts["yacht-" .. yachtId] then
        local isOwner = IsPlayerYachtOwnerPermission(yachtId, src)
        if isOwner then
            local yacht = yachts["yacht-" .. yachtId]
            local targetPerm = yacht.permissions[tostring(targetIdentifier)]
            if targetPerm ~= nil then
                local playerName = targetPerm.playername
                TriggerClientEvent("asyacht:Notify", src, LanguageFile("permissionsremoved", playerName))
                yacht.permissions[tostring(targetIdentifier)] = nil
                updateYachtPermissions(yachtId, yacht.permissions)
            end
        end
    end
end)

RegisterServerEvent("asyacht:Global:BuyFurniture")
AddEventHandler("asyacht:Global:BuyFurniture", function(yachtId, categoryId, furnitureId, relCoords, relRot)
    local src = source
    if yachtId ~= nil and yachts["yacht-" .. yachtId] then
        local yacht = yachts["yacht-" .. yachtId]
        if yacht.furniture.decorating == true and yacht.furniture.decoratingid == src then
            local hasPerm = HasPlayerFurniturePermission(yachtId, src)
            local isOwner = IsPlayerYachtOwnerPermission(yachtId, src)
            if hasPerm or isOwner then
                local category = Config.Furnitures[categoryId]
                local itemData = category and category.categoryobjects and category.categoryobjects[furnitureId]
                if not itemData or not validOffset(relCoords) or not validRot(relRot) then return end
                local count = 0
                for _ in pairs(yacht.furnitures) do count = count + 1 end
                if count >= Limits.maxFurniturePerYacht then return end
                local price = itemData.furnitureprice
                local playerMoney = GetMoneyYacht(src)

                if playerMoney >= price then
                    RemoveMoneyYacht(src, price)
                    TriggerClientEvent("asyacht:Notify", src, LanguageFile("furniturebought", price))
                    local uniqueFId = GetUniqueFurnitureId(yachtId)

                    yacht.furnitures[uniqueFId] = {
                        furnituremodel = itemData.furnitureobject,
                        furniturecoords = relCoords,
                        furniturerotation = relRot
                    }

                    updateYachtFurniture(yachtId, yacht.furnitures)
                    TriggerClientEvent("asyacht:Global:FurnitureNew", -1, yachtId, uniqueFId, itemData.furnitureobject, relCoords, relRot)
                else
                    TriggerClientEvent("asyacht:Notify", src, LanguageFile("nomoneyenoughfurniture", price))
                end
            end
        end
    end
end)

RegisterServerEvent("asyacht:Global:SaveFurniture")
AddEventHandler("asyacht:Global:SaveFurniture", function(yachtId, furnitureKey, relCoords, relRot)
    local src = source
    if yachtId ~= nil and yachts["yacht-" .. yachtId] then
        local yacht = yachts["yacht-" .. yachtId]
        if yacht.furniture.decorating == true and yacht.furniture.decoratingid == src then
            local hasPerm = HasPlayerFurniturePermission(yachtId, src)
            local isOwner = IsPlayerYachtOwnerPermission(yachtId, src)
            if hasPerm or isOwner then
                local fObj = yacht.furnitures[tostring(furnitureKey)]
                if fObj and validOffset(relCoords) and validRot(relRot) then
                    fObj.furniturecoords = relCoords
                    fObj.furniturerotation = relRot
                    TriggerClientEvent("asyacht:Global:UpdateFurniture", -1, yachtId, furnitureKey, relCoords, relRot)
                    updateYachtFurniture(yachtId, yacht.furnitures)
                end
            end
        end
    end
end)

RegisterServerEvent("asyacht:Global:RemoveFurniture")
AddEventHandler("asyacht:Global:RemoveFurniture", function(yachtId, furnitureKey)
    local src = source
    if yachtId ~= nil and yachts["yacht-" .. yachtId] then
        local yacht = yachts["yacht-" .. yachtId]
        if yacht.furniture.decorating == true and yacht.furniture.decoratingid == src then
            local hasPerm = HasPlayerFurniturePermission(yachtId, src)
            local isOwner = IsPlayerYachtOwnerPermission(yachtId, src)
            if hasPerm or isOwner then
                if yacht.furnitures[tostring(furnitureKey)] ~= nil then
                    yacht.furnitures[tostring(furnitureKey)] = nil
                    TriggerClientEvent("asyacht:Global:RemoveFurnitureObject", -1, yachtId, furnitureKey)
                    updateYachtFurniture(yachtId, yacht.furnitures)
                end
            end
        end
    end
end)

RegisterServerEvent("asyacht:Global:OpenStorage")
AddEventHandler("asyacht:Global:OpenStorage", function(yachtId, storageIndex)
    local src = source
    if yachtId ~= nil and yachts["yacht-" .. yachtId] then
        local hasPerm = HasPlayerStoragePermission(yachtId, src)
        local isOwner = IsPlayerYachtOwnerPermission(yachtId, src)
        if (hasPerm or isOwner) and isPlayerNearYacht(src, yachtId) then
            TriggerClientEvent("asyacht:Global:OpenStorageClient", src, yachtId, storageIndex)
        end
    end
end)

RegisterServerEvent("asyacht:Global:OpenWardrobe")
AddEventHandler("asyacht:Global:OpenWardrobe", function(yachtId, wardrobeIndex)
    local src = source
    if yachtId ~= nil and yachts["yacht-" .. yachtId] then
        local hasPerm = HasPlayerWardrobePermission(yachtId, src)
        local isOwner = IsPlayerYachtOwnerPermission(yachtId, src)
        if (hasPerm or isOwner) and isPlayerNearYacht(src, yachtId) then
            TriggerClientEvent("asyacht:Global:OpenWardrobeClient", src, yachtId, wardrobeIndex)
        end
    end
end)

RegisterServerEvent("asyacht:Global:UseHottub")
AddEventHandler("asyacht:Global:UseHottub", function(yachtId, seatIndex)
    local src = source
    if yachtId ~= nil and yachts["yacht-" .. yachtId] then
        local seat = yachts["yacht-" .. yachtId].hottubseats[seatIndex]
        if seat and seat.taken == false and seat.takenplayerid == nil and isPlayerNearYacht(src, yachtId) then
            seat.taken = true
            seat.takenplayerid = src
            TriggerClientEvent("asyacht:Global:SeatUseClient", -1, yachtId, seatIndex, true, src)
            TriggerClientEvent("asyacht:Global:HottubSit", src, yachtId, seatIndex)
        end
    end
end)

RegisterServerEvent("asyacht:Global:LeaveHottub")
AddEventHandler("asyacht:Global:LeaveHottub", function(yachtId, seatIndex)
    local src = source
    if yachtId ~= nil and yachts["yacht-" .. yachtId] then
        local seat = yachts["yacht-" .. yachtId].hottubseats[seatIndex]
        if seat and seat.taken == true and seat.takenplayerid == src then
            seat.taken = false
            seat.takenplayerid = nil
            TriggerClientEvent("asyacht:Global:SeatUseClient", -1, yachtId, seatIndex, false, src)
            TriggerClientEvent("asyacht:Global:HottubLeave", src)
        end
    end
end)

AddEventHandler("playerDropped", function()
    local src = source
    playersInBuyPreview[src] = nil
    for _, yacht in pairs(yachts) do
        if yacht.driverid == src then
            -- anchor where the driver last reported instead of snapping back to the old anchor point
            local lp = yacht.livepos
            if lp and GlobalState["asyacht-" .. yacht.yachtid .. "-anchored"] == false and (GetGameTimer() - lp.at) < 30000 then
                GlobalState["asyacht-" .. yacht.yachtid .. "-coords"] = lp.coords
                GlobalState["asyacht-" .. yacht.yachtid .. "-rotation"] = lp.rotation
                yacht.yachtcurrentanchoreddata.coords = lp.coords
                yacht.yachtcurrentanchoreddata.rotation = lp.rotation
            end
            yacht.driverleave = true -- lets the drive loop finish and anchor the yacht
        end
        if yacht.furniture.decoratingid == src then
            yacht.furniture.decorating = false
            yacht.furniture.decoratingid = nil
        end
        for idx, seat in pairs(yacht.hottubseats) do
            if seat.takenplayerid == src then
                seat.taken = false
                seat.takenplayerid = nil
                TriggerClientEvent("asyacht:Global:SeatUseClient", -1, yacht.yachtid, idx, false, src)
            end
        end
    end
end)

function authorized()
    print("[ACE Studios Yacht] Discord: https://discord.gg/DqrZ2YB4NF")
end

Citizen.CreateThread(function()
    authorized()
    LoadYachts()
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if SaveSailingYachts then SaveSailingYachts(true) end
    SaveDirtyYachtExtras(true)
    FlushFurnitureSaves()
    if Config.DisableYachtDrive == false and Config.ServerNetworkYacht == true then
        for _, yacht in pairs(yachts) do
            local handlerKey = "asyacht-" .. yacht.yachtid .. "-vehhandler"
            if GlobalState[handlerKey] and DoesEntityExist(GlobalState[handlerKey]) then
                DeleteEntity(GlobalState[handlerKey])
            end
        end
    end
end)