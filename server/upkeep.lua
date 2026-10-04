-- Upkeep: a recurring berth / crew fee per yacht. Stored in yacht.extras.upkeep = { paidUntil = os.time(), state = "ok" }.
-- Runs on real time, so it also counts while the owner is offline. Config.Upkeep controls everything.

local DAY = 86400

local function cfg() return Config.Upkeep or {} end
local function enabled() return cfg().enabled == true end
local function interval() return math.max(1, tonumber(cfg().intervalDays) or 7) * DAY end

local function L(key, ...) return LanguageFile(key, ...) end

-- "3 d 4 h", "5 h 10 min", "12 min"
function FormatDuration(seconds)
    seconds = math.max(0, math.floor(seconds or 0))
    local d, h, m = math.floor(seconds / DAY), math.floor(seconds % DAY / 3600), math.floor(seconds % 3600 / 60)
    if d > 0 then return ("%d d %d h"):format(d, h) end
    if h > 0 then return ("%d h %d min"):format(h, m) end
    return ("%d min"):format(math.max(1, m))
end

local function ensure(yacht)
    local ex = yacht.extras
    if type(ex.upkeep) ~= "table" or type(ex.upkeep.paidUntil) ~= "number" then
        -- new yachts and yachts that existed before upkeep: the first period is free
        ex.upkeep = { paidUntil = os.time() + interval(), state = "ok" }
        yacht.extrasDirty = true
    end
    return ex.upkeep
end

-- Cost of one period, and the marina index when the discount applies.
function GetUpkeepCost(yacht)
    local c = cfg()
    local cost = (c.baseCost or 0) + math.floor(GetFurnitureValue(yacht) * (c.furniturePercent or 0) / 100)
    local marina = GetYachtMarina and GetYachtMarina(yacht)
    if marina and (c.marinaDiscount or 0) > 0 then
        cost = math.floor(cost * (100 - c.marinaDiscount) / 100)
    end
    return cost, marina
end

-- Returns status ("ok" | "due" | "locked" | "repossess") and the seconds until the next change
-- (time left while ok, time overdue otherwise).
function GetUpkeepStatus(yacht)
    if not enabled() then return "ok", nil end
    local u = ensure(yacht)
    local now = os.time()
    local over = now - u.paidUntil
    if over < 0 then return "ok", -over end
    local c = cfg()
    if over <= (c.graceDays or 3) * DAY then return "due", over end
    if c.onDefault == "repossess" and (c.repossessDays or 0) > 0 and over > c.repossessDays * DAY then
        return "repossess", over
    end
    return "locked", over
end

-- Summary for the UI / exports.
function GetUpkeepInfo(yacht)
    if not enabled() then return nil end
    local status, secs = GetUpkeepStatus(yacht)
    local cost, marina = GetUpkeepCost(yacht)
    local u = ensure(yacht)
    return {
        status = status, seconds = secs, cost = cost, paidUntil = u.paidUntil,
        discount = marina and cfg().marinaDiscount or 0,
        intervalDays = cfg().intervalDays or 7, graceDays = cfg().graceDays or 3,
        action = cfg().onDefault or "lock",
    }
end

-- Charges the preferred account first, then the other ones. Returns true when paid.
local function charge(src, price)
    if price <= 0 then return true end
    local first = cfg().account
    if first and GetMoneyYacht(src, first) >= price then
        RemoveMoneyYacht(src, price, first)
        return true
    end
    return ChargeYachtPlayer(src, price) ~= nil
end

local function notifyOwner(yacht, key, ntype, ...)
    local src = GetSourceByIdentifier(yacht.owner)
    if src then TriggerClientEvent("asyacht:Notify", src, L(key, ...), ntype or "info") end
end

-- Pays one period for the yacht. src is the paying owner (online). Returns true on success.
function PayYachtUpkeep(src, yacht)
    if not enabled() then return false end
    local u = ensure(yacht)
    local now = os.time()
    -- one period may be paid ahead, never more (stops hoarding years of cover)
    if u.paidUntil - now >= interval() then
        TriggerClientEvent("asyacht:Notify", src, L("upkeepalreadypaid"), "info")
        return false
    end
    local cost = GetUpkeepCost(yacht)
    if not charge(src, cost) then
        TriggerClientEvent("asyacht:Notify", src, L("nomoneyupgrade"), "error")
        return false
    end
    u.paidUntil = math.max(u.paidUntil, now) + interval()
    u.state = "ok"
    yacht.extrasDirty = true
    SaveYachtExtras(yacht.yachtid)
    TriggerClientEvent("asyacht:Notify", src, L("upkeeppaid", cost, FormatDuration(u.paidUntil - now)), "success")
    LogYacht("Yacht upkeep", ("%s paid $%s upkeep for yacht #%s"):format(yacht.owner, cost, yacht.yachtid))
    YachtEmit("upkeepPaid", yacht.yachtid, yacht.owner, cost)
    if SendYachtUpgrades then SendYachtUpgrades(src, yacht) end
    return true
end

RegisterServerEvent("asyacht:Global:PayUpkeep")
AddEventHandler("asyacht:Global:PayUpkeep", function(yachtId)
    local src = source
    yachtId = NormYachtId(yachtId)
    local yacht = yachts["yacht-" .. yachtId]
    if not yacht or not IsPlayerYachtOwnerPermission(yachtId, src) or not YachtIsNearYacht(src, yachtId) then return end
    if YachtThrottled(src, "upkeep", 800) then return end
    PayYachtUpkeep(src, yacht)
end)

-- A yacht with overdue upkeep cannot sail.
YachtDriveChecks[#YachtDriveChecks + 1] = function(yacht)
    if not enabled() then return nil end
    local status = GetUpkeepStatus(yacht)
    if status == "locked" or status == "repossess" then return L("upkeepblocked") end
    return nil
end

local function repossess(yacht)
    if yacht.driverid ~= nil or yacht.removeinprogress then return end
    local owner, id = yacht.owner, yacht.yachtid
    notifyOwner(yacht, "upkeeprepossessed", "error")
    LogYacht("Yacht repossessed", ("Yacht #%s of %s was repossessed (upkeep unpaid)"):format(id, owner))
    if RemoveYachtFully(id) then YachtEmit("repossessed", id, owner) end
end

-- One sweep over every yacht.
local function sweep()
    if not enabled() then return end
    local c = cfg()
    local now = os.time()
    for _, yacht in pairs(yachts) do
        local u = ensure(yacht)
        local status, secs = GetUpkeepStatus(yacht)

        if status ~= "ok" and c.autoPay ~= false then
            local owner = GetSourceByIdentifier(yacht.owner)
            if owner then
                local cost = GetUpkeepCost(yacht)
                if charge(owner, cost) then
                    u.paidUntil = math.max(u.paidUntil, now) + interval()
                    u.state = "ok"
                    yacht.extrasDirty = true
                    SaveYachtExtras(yacht.yachtid)
                    TriggerClientEvent("asyacht:Notify", owner, L("upkeepautopaid", cost), "success")
                    LogYacht("Yacht upkeep", ("%s upkeep of $%s for yacht #%s was paid automatically"):format(yacht.owner, cost, yacht.yachtid))
                    YachtEmit("upkeepPaid", yacht.yachtid, yacht.owner, cost)
                    status = "ok"
                end
            end
        end

        if status == "repossess" then
            repossess(yacht)
        else
            local state = status
            if status == "ok" and secs and secs <= (c.warnHours or 24) * 3600 then state = "soon" end
            if state ~= u.state then
                u.state = state
                yacht.extrasDirty = true
                if state == "soon" then
                    notifyOwner(yacht, "upkeepsoon", "warning", GetUpkeepCost(yacht), FormatDuration(secs))
                elseif state == "due" then
                    notifyOwner(yacht, "upkeepdue", "warning", FormatDuration((c.graceDays or 3) * DAY - secs))
                elseif state == "locked" then
                    notifyOwner(yacht, "upkeeplocked", "error")
                    YachtEmit("upkeepLocked", yacht.yachtid, yacht.owner)
                end
            end
        end
    end
end

CreateThread(function()
    Wait(15000) -- let LoadYachts finish
    while true do
        local ok, err = pcall(sweep)
        if not ok then print("^1[as-yacht]^7 upkeep sweep failed: " .. tostring(err)) end
        Wait(60000)
    end
end)

-- Tell an owner about a due / locked yacht right after they join.
AddEventHandler("asyacht:Global:SynchronizeYacht", function()
    local src = source
    if not enabled() then return end
    local identifier = GetPlayerIdentifierYacht(src)
    if not identifier or identifier == "" then return end
    Wait(4000)
    for _, yacht in pairs(yachts) do
        if yacht.owner == identifier then
            local status, secs = GetUpkeepStatus(yacht)
            if status == "due" then
                TriggerClientEvent("asyacht:Notify", src, L("upkeepdue", FormatDuration((cfg().graceDays or 3) * DAY - secs)), "warning")
            elseif status == "locked" then
                TriggerClientEvent("asyacht:Notify", src, L("upkeeplocked"), "error")
            end
        end
    end
end)

-- Exports
exports("GetYachtUpkeep", function(yachtId)
    local y = yachts["yacht-" .. tostring(yachtId)]
    return y and GetUpkeepInfo(y) or nil
end)
