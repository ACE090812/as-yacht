-- Hull condition: yacht.extras.condition runs 0-100. Collisions and sailing wear it down; repairs restore it.
-- Config.Condition controls the numbers. Clients only report events (impacts, weather); the server decides the damage.

local function cfg() return Config.Condition or {} end
local function enabled() return cfg().enabled == true end
local function L(key, ...) return LanguageFile(key, ...) end

function GetYachtCondition(yacht)
    local v = tonumber(yacht.extras.condition)
    if not v then return 100.0 end
    return math.max(0.0, math.min(100.0, v))
end

local function setCondition(yacht, value, reason, src, amount)
    local before = GetYachtCondition(yacht)
    local after = math.max(0.0, math.min(100.0, value))
    yacht.extras.condition = after
    yacht.extrasDirty = true
    -- the driver's client needs the live value for engine power and the HUD
    if yacht.driverid then
        TriggerClientEvent("asyacht:Global:ConditionUpdate", yacht.driverid, yacht.yachtid, after)
    end
    if after < before then
        YachtEmit("damaged", yacht.yachtid, after, amount or (before - after), reason)
        local target = src or yacht.driverid
        if target then
            if after <= 20 and before > 20 then
                TriggerClientEvent("asyacht:Notify", target, L("hullcritical", math.floor(after)), "error")
            elseif after <= 50 and before > 50 then
                TriggerClientEvent("asyacht:Notify", target, L("hullwarning", math.floor(after)), "warning")
            end
        end
    end
    return after
end

-- Slow wear while sailing; distKm / minutes come from the fuel tick, sea is the driver's reported roughness (0-1).
function ApplyHullWear(yacht, distKm)
    if not enabled() or distKm <= 0 then return end
    local sea = tonumber(yacht.seaRough) or 0.0
    local mult = 1.0 + sea * ((cfg().stormWearMultiplier or 3.0) - 1.0)
    local lost = distKm * (cfg().wearPerKm or 0.12) * mult
    if lost > 0 then setCondition(yacht, GetYachtCondition(yacht) - lost, "wear", yacht.driverid, lost) end
end

-- Extra fuel use as the hull gets worse (multiplier >= 1).
function GetConditionFuelMultiplier(yacht)
    if not enabled() then return 1.0 end
    return 1.0 + (1.0 - GetYachtCondition(yacht) / 100.0) * (cfg().fuelPenalty or 0.5)
end

-- Collisions reported by the driver's client. The server converts speed to damage and rate limits it.
RegisterServerEvent("asyacht:Global:HullImpact")
AddEventHandler("asyacht:Global:HullImpact", function(yachtId, speed)
    local src = source
    if not enabled() then return end
    yachtId = NormYachtId(yachtId)
    local yacht = yachts["yacht-" .. yachtId]
    if not yacht or yacht.driverid ~= src then return end
    if type(speed) ~= "number" or speed ~= speed or speed <= 0 or speed > 90 then return end
    local now = GetGameTimer()
    if yacht.lastImpact and now - yacht.lastImpact < (cfg().impactCooldown or 3) * 1000 then return end

    local over = speed - (cfg().impactMinSpeed or 5.0)
    if over <= 0 then return end
    yacht.lastImpact = now
    local dmg = math.min(cfg().impactMaxDamage or 18.0, over * (cfg().impactDamagePerSpeed or 1.4))
    setCondition(yacht, GetYachtCondition(yacht) - dmg, "impact", src, dmg)
end)

-- ─── Repairs ────────────────────────────────────────────────────────────────
-- discountPct is the extra discount of the place doing the repair (e.g. a marina); insurance stacks on top.
function GetRepairPrice(yacht, discountPct)
    if not enabled() then return 0 end
    local missing = 100.0 - GetYachtCondition(yacht)
    if missing < 0.5 then return 0 end
    local price = missing * (cfg().repairPricePerPercent or 0)
    if yacht.extras.insured then price = price * (100 - (cfg().insuredDiscount or 0)) / 100 end
    price = price * (100 - (discountPct or 0)) / 100
    return math.ceil(price)
end

function RepairYachtHull(src, yacht, discountPct)
    if not enabled() then return false end
    local price = GetRepairPrice(yacht, discountPct)
    if price <= 0 then
        TriggerClientEvent("asyacht:Notify", src, L("hullfine"), "info")
        return false
    end
    if yacht.driverid ~= nil then
        TriggerClientEvent("asyacht:Notify", src, L("hullrepairbusy"), "error")
        return false
    end
    if ChargeYachtPlayer(src, price) == nil then
        TriggerClientEvent("asyacht:Notify", src, L("nomoneyupgrade"), "error")
        return false
    end
    yacht.extras.condition = 100.0
    SaveYachtExtras(yacht.yachtid) -- broadcasts the new condition
    TriggerClientEvent("asyacht:Notify", src, L("hullrepaired", price), "success")
    LogYacht("Yacht repaired", ("%s repaired yacht #%s for $%s"):format(GetPlayerIdentifierYacht(src), yacht.yachtid, price))
    YachtEmit("repaired", yacht.yachtid, price)
    if SendYachtUpgrades then SendYachtUpgrades(src, yacht) end
    return true
end

RegisterServerEvent("asyacht:Global:RepairYacht")
AddEventHandler("asyacht:Global:RepairYacht", function(yachtId)
    local src = source
    yachtId = NormYachtId(yachtId)
    local yacht = yachts["yacht-" .. yachtId]
    if not yacht or not IsPlayerYachtOwnerPermission(yachtId, src) or not YachtIsNearYacht(src, yachtId) then return end
    if YachtThrottled(src, "repair", 800) then return end
    RepairYachtHull(src, yacht, 0)
end)

-- A wrecked yacht cannot sail.
YachtDriveChecks[#YachtDriveChecks + 1] = function(yacht)
    if not enabled() then return nil end
    if GetYachtCondition(yacht) <= (cfg().noSailBelow or 5) then return L("hulltoodamaged") end
    return nil
end

exports("GetYachtCondition", function(yachtId)
    local y = yachts["yacht-" .. tostring(yachtId)]
    return y and GetYachtCondition(y) or nil
end)
