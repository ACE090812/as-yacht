-- as-yacht client/seastate.lua: Sea state (weather roughness) and engine performance from weather + hull condition.

local roughness = 0.0
local weatherByHash = nil
local nextStormWarning = 0

-- 0.0 (flat) - 1.0 (storm). Always 0 when sea state is off or CalmWater is on.
function GetSeaRoughness()
    local cfg = Config.SeaState
    if not cfg or not cfg.enabled or Config.CalmWater then return 0.0 end
    return roughness
end

-- Engine power multiplier from the hull: full power above performanceStart, down to minPower at 0%.
function YachtConditionFactor(yachtId)
    local cfg = Config.Condition
    if not cfg or not cfg.enabled then return 1.0 end
    local ex = yachtExtras[yachtId]
    local cond = tonumber(ex and ex.condition) or 100.0
    local start = cfg.performanceStart or 60
    if cond >= start then return 1.0 end
    local minPower = cfg.minPower or 0.55
    return minPower + (1.0 - minPower) * math.max(0.0, cond) / start
end

-- Combined multiplier applied to the engine while sailing.
function YachtPerformanceFactor(yachtId)
    local cfg = Config.SeaState or {}
    return YachtConditionFactor(yachtId) * (1.0 - GetSeaRoughness() * (cfg.maxSlowdown or 0.3))
end

CreateThread(function()
    while true do
        local cfg = Config.SeaState
        if cfg and cfg.enabled and not Config.CalmWater then
            if not weatherByHash then
                weatherByHash = {}
                for name, value in pairs(cfg.weather or {}) do weatherByHash[GetHashKey(name)] = value end
            end
            roughness = weatherByHash[GetPrevWeatherTypeHashName()] or 0.0

            if drivingState.driving and roughness >= (cfg.stormThreshold or 0.7) and GetGameTimer() >= nextStormWarning then
                nextStormWarning = GetGameTimer() + (cfg.warnCooldown or 180) * 1000
                Notify(Lang.stormwarning or "Storm warning: rough seas slow the yacht and wear the hull.", "warning")
            end
            Wait(2000)
        else
            roughness = 0.0
            Wait(5000)
        end
    end
end)
