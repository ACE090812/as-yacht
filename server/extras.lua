-- Comfort & style extras: furniture layouts, light mode, onboard radio, hull lights,
-- tender boat and nameplate style. Everything is stored in yacht.extras.

local C = function() return Config.Comfort or {} end

local function owned(src, yachtId)
    yachtId = tonumber(yachtId)
    local yacht = yachtId and yachts["yacht-" .. yachtId]
    if not yacht then return nil end
    if not IsPlayerYachtOwnerPermission(yachtId, src) then return nil end
    if not YachtIsNearYacht(src, yachtId) then return nil end
    return yacht
end

local function Notice(src, key, ntype, ...)
    TriggerClientEvent("asyacht:Notify", src, LanguageFile(key, ...), ntype or "error")
end

local function Enabled() return C().enabled == true end

local function Finish(src, yacht)
    SaveYachtExtras(yacht.yachtid)
    if SendYachtUpgrades then SendYachtUpgrades(src, yacht) end
end

local function Pay(src, price)
    if (price or 0) <= 0 then return true end
    if ChargeYachtPlayer(src, price) then return true end
    Notice(src, "nomoneyupgrade")
    return false
end

function TenderLimits()
    local out = {}
    for cat, slots in pairs((C().tender and C().tender.slots) or {}) do out[cat] = #slots end
    return out
end

function BuildComfortPayload(yacht)
    local c = C()
    if not c.enabled then return nil end
    local ex = yacht.extras
    local layouts = {}
    for i, l in ipairs(ex.layouts or {}) do
        local n = 0
        for _ in pairs(l.items or {}) do n = n + 1 end
        layouts[i] = { name = l.name, count = n }
    end
    local tenders = {}
    for _, t in ipairs((c.tender and c.tender.options) or {}) do
        tenders[#tenders + 1] = { id = t.id, label = t.label, category = t.category or "Vehicles", price = t.price, owned = (ex.tenders or {})[tostring(t.id)] == true }
    end
    local stations = {}
    for _, st in ipairs((c.ambience and c.ambience.stations) or {}) do stations[#stations + 1] = { id = st.id, label = st.label } end
    local colors = {}
    for _, col in ipairs((c.hullLights and c.hullLights.colors) or {}) do colors[#colors + 1] = { id = col.id, label = col.label, rgb = col.rgb } end

    return {
        layoutsEnabled = c.layouts and c.layouts.enabled == true, layoutsMax = c.layouts and c.layouts.max or 3, layouts = layouts,
        lightmodes = c.lightModes, lightmode = ex.lightmode or "on",
        ambience = c.ambience and c.ambience.enabled and {
            price = c.ambience.price, owned = ex.radioowned == true, current = ex.radio or false, stations = stations,
        } or nil,
        hull = c.hullLights and c.hullLights.enabled and {
            price = c.hullLights.price, owned = ex.hullowned == true, on = ex.hullon == true, color = ex.hullcolor or 1, colors = colors,
        } or nil,
        tender = c.tender and c.tender.enabled and { options = tenders, limits = TenderLimits() } or nil,
    }
end

-- Layouts ---------------------------------------------------------------------
RegisterServerEvent("asyacht:Global:SaveLayout")
AddEventHandler("asyacht:Global:SaveLayout", function(yachtId, name)
    local src = source
    if not Enabled() or not (C().layouts and C().layouts.enabled) then return end
    local yacht = owned(src, yachtId)
    if not yacht then return end
    name = SanitizeYachtText and SanitizeYachtText(name) or tostring(name or "")
    if name == "" then name = "Layout" end
    local list = yacht.extras.layouts
    if type(list) ~= "table" then list = {}; yacht.extras.layouts = list end

    local items = {}
    for key, f in pairs(yacht.furnitures) do
        items[#items + 1] = { model = f.furnituremodel, coords = f.furniturecoords, rotation = f.furniturerotation }
    end
    local entry = { name = name, items = items }
    local replaced = false
    for i, l in ipairs(list) do if l.name == name then list[i] = entry; replaced = true; break end end
    if not replaced then
        if #list >= (C().layouts.max or 3) then return Notice(src, "layoutfull") end
        list[#list + 1] = entry
    end
    Notice(src, "layoutsaved", "success", name)
    Finish(src, yacht)
end)

RegisterServerEvent("asyacht:Global:DeleteLayout")
AddEventHandler("asyacht:Global:DeleteLayout", function(yachtId, index)
    local src = source
    if not Enabled() then return end
    local yacht = owned(src, yachtId)
    index = tonumber(index)
    if not yacht or not index or not yacht.extras.layouts or not yacht.extras.layouts[index] then return end
    table.remove(yacht.extras.layouts, index)
    Finish(src, yacht)
end)

RegisterServerEvent("asyacht:Global:LoadLayout")
AddEventHandler("asyacht:Global:LoadLayout", function(yachtId, index)
    local src = source
    if not Enabled() then return end
    local yacht = owned(src, yachtId)
    index = tonumber(index)
    local layout = yacht and yacht.extras.layouts and yacht.extras.layouts[index]
    if not layout then return end
    if yacht.furniture.decorating == true then return Notice(src, "layoutbusy") end

    -- pieces already placed on the yacht, grouped by model
    local pool = {}
    for key, f in pairs(yacht.furnitures) do
        pool[f.furnituremodel] = pool[f.furnituremodel] or {}
        table.insert(pool[f.furnituremodel], key)
    end

    local moved, missing = 0, 0
    for _, item in ipairs(layout.items or {}) do
        local keys = pool[item.model]
        if keys and #keys > 0 then
            local key = table.remove(keys, 1)
            local f = yacht.furnitures[key]
            f.furniturecoords, f.furniturerotation = item.coords, item.rotation
            TriggerClientEvent("asyacht:Global:UpdateFurniture", -1, yacht.yachtid, key, item.coords, item.rotation)
            moved = moved + 1
        else
            missing = missing + 1
        end
    end
    updateYachtFurniture(yacht.yachtid, yacht.furnitures)
    Notice(src, "layoutloaded", "success", layout.name, moved, missing)
    LogYacht("Furniture layout loaded", ("%s loaded layout '%s' on yacht #%s (%s moved, %s missing)"):format(
        GetPlayerIdentifierYacht(src), layout.name, yacht.yachtid, moved, missing))
end)

-- Light mode (free) -----------------------------------------------------------
RegisterServerEvent("asyacht:Global:SetLightMode")
AddEventHandler("asyacht:Global:SetLightMode", function(yachtId, mode)
    local src = source
    if not Enabled() then return end
    local yacht = owned(src, yachtId)
    if not yacht then return end
    local ok = false
    for _, m in ipairs(C().lightModes or {}) do if m.id == mode then ok = true end end
    if not ok then return end
    yacht.extras.lightmode = mode
    Finish(src, yacht)
end)

-- Radio -----------------------------------------------------------------------
RegisterServerEvent("asyacht:Global:SetRadio")
AddEventHandler("asyacht:Global:SetRadio", function(yachtId, stationId)
    local src = source
    local cfg = C().ambience
    if not Enabled() or not cfg or not cfg.enabled then return end
    local yacht = owned(src, yachtId)
    if not yacht then return end

    if stationId ~= "" and stationId ~= false then
        local valid = false
        for _, st in ipairs(cfg.stations) do if st.id == stationId then valid = true end end
        if not valid then return end
    end
    if not yacht.extras.radioowned then
        if not Pay(src, cfg.price) then return end
        yacht.extras.radioowned = true
    end
    yacht.extras.radio = (stationId ~= "" and stationId) or false
    Finish(src, yacht)
end)

-- Hull lights -----------------------------------------------------------------
RegisterServerEvent("asyacht:Global:SetHullLights")
AddEventHandler("asyacht:Global:SetHullLights", function(yachtId, colorId, on)
    local src = source
    local cfg = C().hullLights
    if not Enabled() or not cfg or not cfg.enabled then return end
    local yacht = owned(src, yachtId)
    colorId = tonumber(colorId)
    if not yacht or not colorId or not cfg.colors[colorId] then return end
    if not yacht.extras.hullowned then
        if not Pay(src, cfg.price) then return end
        yacht.extras.hullowned = true
    end
    yacht.extras.hullcolor = colorId
    yacht.extras.hullon = on == true
    Finish(src, yacht)
end)

-- Tender ----------------------------------------------------------------------
local lastTender = {}

-- how many vehicles of each category the yacht has spots for
function TenderLimit(category)
    local slots = C().tender and C().tender.slots and C().tender.slots[category]
    return slots and #slots or 0
end
local tenderLimit = TenderLimit

local function findTender(id)
    for _, t in ipairs((C().tender and C().tender.options) or {}) do if t.id == id then return t end end
end

RegisterServerEvent("asyacht:Global:BuyTender")
AddEventHandler("asyacht:Global:BuyTender", function(yachtId, optionId)
    local src = source
    if not Enabled() or not (C().tender and C().tender.enabled) then return end
    local yacht = owned(src, yachtId)
    optionId = tonumber(optionId)
    local opt = optionId and findTender(optionId)
    if not yacht or not opt then return end
    yacht.extras.tenders = type(yacht.extras.tenders) == "table" and yacht.extras.tenders or {}
    if yacht.extras.tenders[tostring(optionId)] then return end
    local category = opt.category or "Vehicles"
    local owned = 0
    for _, other in ipairs(C().tender.options) do
        if (other.category or "Vehicles") == category and yacht.extras.tenders[tostring(other.id)] then owned = owned + 1 end
    end
    if owned >= tenderLimit(category) then return Notice(src, "tenderlimit", "error", tenderLimit(category), category) end
    if not Pay(src, opt.price) then return end
    yacht.extras.tenders[tostring(optionId)] = true
    Notice(src, "tenderbought", "success", opt.label)
    Finish(src, yacht)
end)

RegisterServerEvent("asyacht:Global:SpawnTender")
AddEventHandler("asyacht:Global:SpawnTender", function(yachtId, optionId)
    local src = source
    local cfg = C().tender
    if not Enabled() or not cfg or not cfg.enabled then return end
    local yacht = owned(src, yachtId)
    optionId = tonumber(optionId)
    local opt = optionId and findTender(optionId)
    if not yacht or not opt then return end
    if not (yacht.extras.tenders or {})[tostring(optionId)] then return end
    if GlobalState["asyacht-" .. yacht.yachtid .. "-anchored"] ~= true then return Notice(src, "tenderanchor") end
    local now = os.time()
    local key = src .. ":" .. optionId
    if lastTender[key] and now - lastTender[key] < (cfg.cooldown or 60) then
        return Notice(src, "tendercooldown", "error", (cfg.cooldown or 60) - (now - lastTender[key]))
    end
    lastTender[key] = now
    TriggerClientEvent("asyacht:Global:TenderApproved", src, yacht.yachtid, opt.model, opt.id)
end)

AddEventHandler("playerDropped", function()
    local prefix = source .. ":"
    for k in pairs(lastTender) do if k:sub(1, #prefix) == prefix then lastTender[k] = nil end end
end)
