-- Marinas: moorings and the harbour master (pay upkeep, refuel, repair).
-- Fees and fuel stations for marinas are applied in server/economy.lua.

local function cfg() return Config.Marinas or {} end

local function flat(a, b)
    local dx, dy = a.x - b.x, a.y - b.y
    return math.sqrt(dx * dx + dy * dy)
end

-- Returns index, marina for the marina containing coords (or nil).
function GetMarinaAt(coords)
    if not cfg().enabled or not coords then return nil end
    for i, m in ipairs(cfg().list or {}) do
        if flat(coords, m.zone) <= m.radius then return i, m end
    end
    return nil
end

-- Index of the marina a yacht is anchored in (or nil while sailing / outside every marina).
function GetYachtMarina(yacht)
    if GlobalState["asyacht-" .. yacht.yachtid .. "-anchored"] ~= true then return nil end
    local c = GlobalState["asyacht-" .. yacht.yachtid .. "-coords"] or yacht.yachtcurrentanchoreddata.coords
    return (GetMarinaAt(c))
end

local function marinaByIndex(i)
    i = tonumber(i)
    if not i or i ~= math.floor(i) then return nil, nil end
    return (cfg().list or {})[i], i
end

local function nearHarbour(src, m)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    return #(GetEntityCoords(ped) - vector3(m.harbour.x, m.harbour.y, m.harbour.z)) <= 8.0
end

local function yachtLabel(y)
    return ((y.textdata.uppertext or "") .. " " .. (y.textdata.bottomtext or "")):gsub("^%s+", ""):gsub("%s+$", "")
end

local function buildList(src, index, m)
    local identifier = GetPlayerIdentifierYacht(src)
    local list = {}
    for _, y in pairs(yachts) do
        if y.owner == identifier then
            list[#list + 1] = {
                id = y.yachtid,
                name = yachtLabel(y),
                moored = GetYachtMarina(y) == index,
                fuel = Config.Fuel and Config.Fuel.enabled and (y.extras.fuel or 0) or nil,
                refuelprice = Config.Fuel and Config.Fuel.enabled and GetRefuelPrice(y) or nil,
                condition = GetYachtCondition and GetYachtCondition(y) or nil,
                repairprice = GetRepairPrice and GetRepairPrice(y, (Config.Condition or {}).marinaDiscount or 0) or nil,
                upkeep = GetUpkeepInfo and GetUpkeepInfo(y) or nil,
            }
        end
    end
    table.sort(list, function(a, b) return a.id < b.id end)
    return list
end

local function send(src, index, m)
    TriggerClientEvent("asyacht:Global:HarbourData", src, index, m.label, {
        fuel = m.fuel == true, repair = m.repair == true,
        conditionEnabled = (Config.Condition or {}).enabled == true,
        upkeepEnabled = (Config.Upkeep or {}).enabled == true,
    }, buildList(src, index, m))
end

RegisterServerEvent("asyacht:Global:HarbourOpen")
AddEventHandler("asyacht:Global:HarbourOpen", function(index)
    local src = source
    local m, i = marinaByIndex(index)
    if not cfg().enabled or not m or not nearHarbour(src, m) or YachtThrottled(src, "harbour", 500) then return end
    send(src, i, m)
end)

RegisterServerEvent("asyacht:Global:HarbourAction")
AddEventHandler("asyacht:Global:HarbourAction", function(index, yachtId, action)
    local src = source
    local m, i = marinaByIndex(index)
    yachtId = NormYachtId(yachtId)
    local yacht = yachts["yacht-" .. yachtId]
    if not cfg().enabled or not m or not yacht or type(action) ~= "string" then return end
    if not nearHarbour(src, m) or yacht.owner ~= GetPlayerIdentifierYacht(src) then return end
    if YachtThrottled(src, "harbouraction", 800) then return end

    local moored = GetYachtMarina(yacht) == i
    if action == "refuel" then
        if not m.fuel then return end
        if not moored then return TriggerClientEvent("asyacht:Notify", src, LanguageFile("harbourmoored", m.label), "error") end
        DoRefuelYacht(src, yacht)
    elseif action == "repair" then
        if not m.repair or not RepairYachtHull then return end
        if not moored then return TriggerClientEvent("asyacht:Notify", src, LanguageFile("harbourmoored", m.label), "error") end
        RepairYachtHull(src, yacht, (Config.Condition or {}).marinaDiscount or 0)
    elseif action == "upkeep" then
        if not PayYachtUpkeep then return end
        PayYachtUpkeep(src, yacht)
    else
        return
    end
    send(src, i, m)
end)

-- Exports
exports("GetYachtMarina", function(yachtId)
    local y = yachts["yacht-" .. tostring(yachtId)]
    if not y then return nil end
    local i = GetYachtMarina(y)
    return i and (cfg().list or {})[i] and (cfg().list[i].label) or nil
end)
