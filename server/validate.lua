-- Configuration check: finds mistakes in config.lua before they turn into confusing in-game behaviour.
-- Runs once at start (Config.CheckConfigOnStart) and on demand with /yachtcheck. Model names are checked on the
-- client (client/validate.lua) because only a client knows which models are streamed.

local function isNum(v) return type(v) == "number" and v == v end
local function inRange(v, lo, hi) return isNum(v) and v >= lo and v <= hi end
local function isVec(v) return type(v) == "vector3" or type(v) == "vector4" or (type(v) == "table" and isNum(v.x) and isNum(v.y)) end

function ValidateYachtConfig()
    local out = {}
    local function bad(area, text, ...) out[#out + 1] = ("%s: %s"):format(area, select("#", ...) > 0 and text:format(...) or text) end

    -- general ---------------------------------------------------------------
    if not (Config.Framework == "esx" or Config.Framework == "qbcore" or Config.Framework == "standalone") then
        bad("General", "Config.Framework is '%s' (expected esx, qbcore or standalone)", tostring(Config.Framework))
    end
    if not Language or not Language[Config.Language] then
        bad("General", "Config.Language '%s' does not exist, English is used instead", tostring(Config.Language))
    end
    if type(Config.YachtSpawnLocations) ~= "table" or #Config.YachtSpawnLocations == 0 then
        bad("Spawns", "Config.YachtSpawnLocations is empty: nobody can buy a yacht")
    end
    local pay = Config.Payment or {}
    local defaultOk = false
    for _, m in ipairs(pay.methods or {}) do if m == pay.default then defaultOk = true end end
    if not defaultOk then bad("Payment", "default payment '%s' is not in Config.Payment.methods", tostring(pay.default)) end
    if not inRange((Config.YachtPriceSettings or {}).yachtprice, 1, math.huge) then bad("Prices", "Config.YachtPriceSettings.yachtprice must be a positive number") end

    -- storage ---------------------------------------------------------------
    local inventories = { oxinventory = true, qsinventory = true, qbcoreinventory = true, codeminventory = true, coreinventory = true, psinventory = true, chezza = true }
    if not inventories[tostring(Config.InventorySystem)] then
        bad("Storage", "Config.InventorySystem '%s' is not recognised (use oxinventory, qsinventory, qbcoreinventory, codeminventory, coreinventory, psinventory or chezza): the storage rooms will do nothing", tostring(Config.InventorySystem))
    elseif Config.InventorySystem == "oxinventory" and Config.OxInventory ~= true then
        bad("Storage", "Config.InventorySystem is \"oxinventory\" but Config.OxInventory is not true: the storage rooms will do nothing")
    end

    -- wardrobe --------------------------------------------------------------
    local wardrobe = ResolveWardrobeSystem(Config.WardrobeSystem)
    if not wardrobe then
        bad("Wardrobe", "Config.WardrobeSystem '%s' is not recognised (use illeniumappearance, fivemappearance, qbcore, rcore, esx, codem, qsappearance, auto or custom): the wardrobe will do nothing", tostring(Config.WardrobeSystem))
    elseif wardrobe == "custom" then
        if type(Config.CustomWardrobe) ~= "function" then bad("Wardrobe", "Config.WardrobeSystem is \"custom\" but Config.CustomWardrobe is not a function") end
    elseif wardrobe == "auto" then
        local found = false
        for _, res in pairs(WARDROBE_RESOURCES) do if GetResourceState(res) == "started" then found = true end end
        if not found then bad("Wardrobe", "\"auto\" found no supported clothing script (illenium-appearance, fivem-appearance, qb-clothing, rcore_clothes) started: use a named system or \"custom\"") end
    elseif WARDROBE_RESOURCES[wardrobe] and GetResourceState(WARDROBE_RESOURCES[wardrobe]) ~= "started" then
        bad("Wardrobe", "Config.WardrobeSystem is '%s' but the resource '%s' is not started (ignore this if you renamed it)", tostring(Config.WardrobeSystem), WARDROBE_RESOURCES[wardrobe])
    end

    -- fuel ------------------------------------------------------------------
    local fuel = Config.Fuel or {}
    if fuel.enabled then
        if not inRange(fuel.startFuel, 0, 100) then bad("Fuel", "startFuel must be 0-100") end
        if not inRange(fuel.usagePerKm, 0, math.huge) or not inRange(fuel.pricePerPercent, 0, math.huge) then bad("Fuel", "usagePerKm and pricePerPercent must be numbers >= 0") end
        for i, st in ipairs(fuel.stations or {}) do
            if not isVec(st.coords) or not inRange(st.radius, 1, math.huge) then bad("Fuel", "station #%d needs coords and a radius > 0", i) end
        end
        if fuel.requireStation and #(fuel.stations or {}) == 0 and not (Config.Marinas and Config.Marinas.enabled) then
            bad("Fuel", "requireStation is on but there is no fuel station or marina: nobody can refuel")
        end
    end

    -- upkeep ----------------------------------------------------------------
    local up = Config.Upkeep or {}
    if up.enabled then
        if not inRange(up.intervalDays, 0.01, 3650) then bad("Upkeep", "intervalDays must be between 0.01 and 3650") end
        if not inRange(up.baseCost, 0, math.huge) then bad("Upkeep", "baseCost must be a number >= 0") end
        if not inRange(up.furniturePercent, 0, 1000) then bad("Upkeep", "furniturePercent must be 0-1000") end
        if not inRange(up.marinaDiscount, 0, 100) then bad("Upkeep", "marinaDiscount must be 0-100") end
        if not inRange(up.graceDays, 0, 3650) then bad("Upkeep", "graceDays must be >= 0") end
        if up.onDefault ~= "lock" and up.onDefault ~= "repossess" then bad("Upkeep", "onDefault must be \"lock\" or \"repossess\" (is '%s')", tostring(up.onDefault)) end
        if up.onDefault == "repossess" and not inRange(up.repossessDays, 1, 3650) then
            bad("Upkeep", "onDefault is \"repossess\" but repossessDays is not set: yachts are never removed")
        end
        if up.account ~= nil and up.account ~= "bank" and up.account ~= "cash" then bad("Upkeep", "account must be \"bank\" or \"cash\"") end
    end

    -- marinas ---------------------------------------------------------------
    local mar = Config.Marinas or {}
    if mar.enabled then
        if type(mar.list) ~= "table" or #mar.list == 0 then bad("Marinas", "enabled but the list is empty") end
        local labels = {}
        for i, m in ipairs(mar.list or {}) do
            local tag = ("marina #%d (%s)"):format(i, tostring(m.label))
            if type(m.label) ~= "string" or m.label == "" then bad("Marinas", "marina #%d needs a label", i) end
            if labels[m.label or ""] then bad("Marinas", "%s: duplicate label", tag) end
            labels[m.label or ""] = true
            if not isVec(m.zone) then bad("Marinas", "%s: zone must be a vector3", tag)
            elseif not inRange(m.radius, 10, 5000) then bad("Marinas", "%s: radius should be 10-5000", tag) end
            if type(m.harbour) ~= "vector4" and not (type(m.harbour) == "table" and isNum(m.harbour.w)) then
                bad("Marinas", "%s: harbour must be a vector4 (x, y, z, heading)", tag)
            elseif isVec(m.zone) and inRange(m.radius, 10, 5000) then
                local dx, dy = m.harbour.x - m.zone.x, m.harbour.y - m.zone.y
                if math.sqrt(dx * dx + dy * dy) > m.radius * 2 then
                    bad("Marinas", "%s: the harbour master is far outside the marina zone, check the coordinates", tag)
                end
            end
            if not inRange(m.fee or 0, 0, math.huge) then bad("Marinas", "%s: fee must be >= 0", tag) end
        end
        for i = 1, #(mar.list or {}) do
            for j = i + 1, #mar.list do
                local a, b = mar.list[i], mar.list[j]
                if isVec(a.zone) and isVec(b.zone) and isNum(a.radius) and isNum(b.radius) then
                    local dx, dy = a.zone.x - b.zone.x, a.zone.y - b.zone.y
                    if math.sqrt(dx * dx + dy * dy) < math.max(a.radius, b.radius) then
                        bad("Marinas", "'%s' and '%s' overlap", tostring(a.label), tostring(b.label))
                    end
                end
            end
        end
    end
    local dock = Config.Docking or {}
    if dock.enabled then
        local fees = 0
        for _, z in ipairs(dock.zones or {}) do if (z.fee or 0) > 0 then fees = fees + 1 end end
        for _, m in ipairs((mar.enabled and mar.list) or {}) do if (m.fee or 0) > 0 then fees = fees + 1 end end
        if fees == 0 then bad("Docking", "enabled but no zone or marina has a fee") end
    end

    -- condition and sea state -----------------------------------------------
    local cond = Config.Condition or {}
    if cond.enabled then
        if not inRange(cond.minPower, 0.05, 1) then bad("Condition", "minPower must be 0.05-1") end
        if not inRange(cond.performanceStart, 1, 100) then bad("Condition", "performanceStart must be 1-100") end
        if not inRange(cond.noSailBelow, 0, 99) then bad("Condition", "noSailBelow must be 0-99") end
        if not inRange(cond.impactMinSpeed, 0.1, 200) then bad("Condition", "impactMinSpeed must be > 0") end
        for _, k in ipairs({ "wearPerKm", "impactDamagePerSpeed", "impactMaxDamage", "repairPricePerPercent", "fuelPenalty", "stormWearMultiplier" }) do
            if not inRange(cond[k], 0, math.huge) then bad("Condition", "%s must be a number >= 0", k) end
        end
        if not inRange(cond.insuredDiscount, 0, 100) or not inRange(cond.marinaDiscount, 0, 100) then bad("Condition", "discounts must be 0-100") end
    end
    local sea = Config.SeaState or {}
    if sea.enabled then
        if not inRange(sea.maxSlowdown, 0, 0.9) then bad("SeaState", "maxSlowdown must be 0-0.9 (a higher value would stop the engine)") end
        if not inRange(sea.stormThreshold, 0, 1) then bad("SeaState", "stormThreshold must be 0-1") end
        for name, v in pairs(sea.weather or {}) do
            if not inRange(v, 0, 1) then bad("SeaState", "weather %s must be 0-1", tostring(name)) end
        end
    end

    -- comfort: moods, lights, radio, tenders -------------------------------------
    local c = Config.Comfort or {}
    if c.enabled then
        local modes, stations, colors = {}, {}, (c.hullLights and c.hullLights.colors) or {}
        for _, m in ipairs(c.lightModes or {}) do modes[m.id] = true end
        for _, s in ipairs((c.ambience and c.ambience.stations) or {}) do stations[s.id] = true end
        local seen = {}
        for i, m in ipairs(c.moods or {}) do
            local tag = ("mood '%s'"):format(tostring(m.id))
            if type(m.id) ~= "string" or m.id == "" then bad("Moods", "mood #%d needs an id", i) end
            if seen[m.id or ""] then bad("Moods", "%s: duplicate id", tag) end
            seen[m.id or ""] = true
            if m.lightMode and not modes[m.lightMode] then bad("Moods", "%s: lightMode '%s' is not in Config.Comfort.lightModes", tag, tostring(m.lightMode)) end
            if m.hull and m.hull.color and not colors[m.hull.color] then bad("Moods", "%s: hull colour %s does not exist", tag, tostring(m.hull.color)) end
            if m.radio and not stations[m.radio] then bad("Moods", "%s: radio station '%s' is not in Config.Comfort.ambience.stations", tag, tostring(m.radio)) end
        end
        for i, s in ipairs(c.moodSchedule or {}) do
            if not inRange(s.from, 0, 23) or not inRange(s.to, 0, 23) then bad("Moods", "moodSchedule #%d: from/to must be hours 0-23", i) end
            if not colors[s.color] then bad("Moods", "moodSchedule #%d: hull colour %s does not exist", i, tostring(s.color)) end
        end
        if c.hullLights and c.hullLights.enabled and #(c.hullLights.points or {}) == 0 then bad("Hull lights", "enabled but there are no light points") end

        local t = c.tender
        if t and t.enabled then
            local ids = {}
            for _, o in ipairs(t.options or {}) do
                if ids[o.id] then bad("Tenders", "duplicate option id %s", tostring(o.id)) end
                ids[o.id] = true
                if type(o.model) ~= "string" or o.model == "" then bad("Tenders", "option %s has no model", tostring(o.id)) end
                if not inRange(o.price, 0, math.huge) then bad("Tenders", "option %s: price must be >= 0", tostring(o.id)) end
                if not (t.slots or {})[o.category or ""] or #t.slots[o.category] == 0 then
                    bad("Tenders", "'%s' (%s) has no parking spot: add one to Config.Comfort.tender.slots['%s']", tostring(o.label), tostring(o.category), tostring(o.category))
                end
            end
        end
    end

    -- furniture catalogue ---------------------------------------------------
    -- a model sold in several categories is fine as long as the price is the same (refunds and upkeep use one price per model)
    local prices, conflicts = {}, {}
    for ci, cat in ipairs(Config.Furnitures or {}) do
        if type(cat.categorylabel) ~= "string" or cat.categorylabel == "" then bad("Furniture", "category #%d has no label", ci) end
        for _, item in ipairs(cat.categoryobjects or {}) do
            local m = item.furnitureobject
            if type(m) ~= "string" or m == "" then
                bad("Furniture", "category '%s' has an item without a model", tostring(cat.categorylabel))
            elseif not inRange(item.furnitureprice, 0, math.huge) then
                bad("Furniture", "'%s' has an invalid price", m)
            else
                if prices[m] ~= nil and prices[m] ~= item.furnitureprice and not conflicts[m] then
                    conflicts[m] = true
                    bad("Furniture", "'%s' is sold at different prices in different categories", m)
                end
                prices[m] = prices[m] or item.furnitureprice
            end
        end
    end

    return out
end

function PrintYachtConfigProblems(problems)
    if #problems == 0 then
        print("^2[as-yacht]^7 config check: no problems found")
        return
    end
    print(("^3[as-yacht]^7 config check: %d problem(s) found"):format(#problems))
    for _, p in ipairs(problems) do print("^3  - ^7" .. p) end
end

CreateThread(function()
    if Config.CheckConfigOnStart == false then return end
    Wait(8000) -- after LoadYachts and the other modules
    PrintYachtConfigProblems(ValidateYachtConfig())
end)
