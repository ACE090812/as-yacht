-- Layout sharing: export a saved layout as a short code, import a code from another player,
-- and buy the pieces a layout needs. Nothing in a code is trusted: every piece is checked against the
-- furniture catalogue and the yacht limits before it is stored.

local function cfg() return (Config.Comfort or {}).layoutSharing or {} end
local function L(key, ...) return LanguageFile(key, ...) end
local PREFIX = "ASY1:"

-- ─── base64 ─────────────────────────────────────────────────────────────────
local B = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local enc, dec = {}, {}
for i = 1, #B do enc[i - 1] = B:sub(i, i); dec[B:byte(i)] = i - 1 end

local function b64encode(data)
    local out = {}
    for i = 1, #data, 3 do
        local a, b, c = data:byte(i, i + 2)
        local n = a * 65536 + (b or 0) * 256 + (c or 0)
        local c1, c2, c3, c4 = n >> 18 & 63, n >> 12 & 63, n >> 6 & 63, n & 63
        out[#out + 1] = enc[c1] .. enc[c2] .. (b and enc[c3] or "=") .. (c and enc[c4] or "=")
    end
    return table.concat(out)
end

local function b64decode(text)
    text = text:gsub("[%s]", "")
    if #text % 4 ~= 0 or text:find("[^%w%+/=]") then return nil end
    local out = {}
    for i = 1, #text, 4 do
        local a, b, c, d = text:byte(i, i + 3)
        local pc, pd = c == 61, d == 61 -- '='
        local va, vb, vc, vd = dec[a], dec[b], not pc and dec[c] or 0, not pd and dec[d] or 0
        if not va or not vb or not vc or not vd then return nil end
        local n = va * 262144 + vb * 4096 + vc * 64 + vd
        out[#out + 1] = string.char(n >> 16 & 255)
        if not pc then out[#out + 1] = string.char(n >> 8 & 255) end
        if not pd then out[#out + 1] = string.char(n & 255) end
    end
    return table.concat(out)
end

-- ─── helpers ────────────────────────────────────────────────────────────────
local catalogue -- model -> price (nil price = starter piece that is not sold)
local function models()
    if catalogue then return catalogue end
    catalogue = {}
    for _, cat in pairs(Config.Furnitures or {}) do
        for _, item in pairs(cat.categoryobjects or {}) do catalogue[item.furnitureobject] = item.furnitureprice or 0 end
    end
    return catalogue
end

local function starterModels()
    local set = {}
    for _, f in pairs(Config.BasicEquipment or {}) do set[f.furnituremodel] = true end
    return set
end

local function owned(src, yachtId)
    yachtId = NormYachtId(yachtId)
    local yacht = yachts["yacht-" .. yachtId]
    if not yacht or not IsPlayerYachtOwnerPermission(yachtId, src) or not YachtIsNearYacht(src, yachtId) then return nil end
    if YachtThrottled(src, "layouts", 400) then return nil end
    return yacht
end

local function r3(n) return math.floor(n * 1000 + 0.5) / 1000 end

local function validNumber(n, limit)
    return type(n) == "number" and n == n and math.abs(n) <= limit
end

local function validXYZ(t, limit)
    return type(t) == "table" and validNumber(t.x, limit) and validNumber(t.y, limit) and validNumber(t.z, limit)
end

-- How many pieces of the layout the yacht lacks, and what the buyable ones cost.
function LayoutMissing(yacht, layout)
    local have = {}
    for _, f in pairs(yacht.furnitures) do have[f.furnituremodel] = (have[f.furnituremodel] or 0) + 1 end
    local missing, cost = 0, 0
    local shop = models()
    for _, item in ipairs(layout.items or {}) do
        if (have[item.model] or 0) > 0 then
            have[item.model] = have[item.model] - 1
        else
            missing = missing + 1
            cost = cost + (shop[item.model] or 0)
        end
    end
    return missing, cost
end

-- ─── export ─────────────────────────────────────────────────────────────────
RegisterServerEvent("asyacht:Global:ExportLayout")
AddEventHandler("asyacht:Global:ExportLayout", function(yachtId, index)
    local src = source
    if not cfg().enabled then return end
    local yacht = owned(src, yachtId)
    index = tonumber(index)
    local layout = yacht and index and yacht.extras.layouts and yacht.extras.layouts[index]
    if not layout then return end

    local items = {}
    for _, it in ipairs(layout.items or {}) do
        local p, r = it.coords, it.rotation
        items[#items + 1] = { m = it.model, p = { r3(p.x), r3(p.y), r3(p.z) }, r = { r3(r.x), r3(r.y), r3(r.z) } }
    end
    local code = PREFIX .. b64encode(json.encode({ n = layout.name, i = items }))
    TriggerClientEvent("asyacht:Global:LayoutCode", src, layout.name, code)
end)

-- ─── import ─────────────────────────────────────────────────────────────────
RegisterServerEvent("asyacht:Global:ImportLayout")
AddEventHandler("asyacht:Global:ImportLayout", function(yachtId, code)
    local src = source
    local c = cfg()
    if not c.enabled then return end
    local yacht = owned(src, yachtId)
    if not yacht then return end

    local function bad() TriggerClientEvent("asyacht:Notify", src, L("layoutinvalid"), "error") end
    if type(code) ~= "string" or #code > (c.maxCodeLength or 16000) or code:sub(1, #PREFIX) ~= PREFIX then return bad() end

    local raw = b64decode(code:sub(#PREFIX + 1))
    if not raw then return bad() end
    local ok, data = pcall(json.decode, raw)
    if not ok or type(data) ~= "table" or type(data.i) ~= "table" then return bad() end

    local shop, starters = models(), starterModels()
    local limits = YachtLimits
    local items = {}
    for _, it in ipairs(data.i) do
        if #items >= limits.maxFurniturePerYacht then return bad() end
        if type(it) ~= "table" or type(it.m) ~= "string" or not (shop[it.m] ~= nil or starters[it.m]) then return bad() end
        local p, r = it.p, it.r
        if type(p) ~= "table" or type(r) ~= "table" then return bad() end
        local px, py, pz = p[1], p[2], p[3]
        local rx, ry, rz = r[1], r[2], r[3]
        if not (validNumber(px, limits.maxFurnitureOffset) and validNumber(py, limits.maxFurnitureOffset) and validNumber(pz, limits.maxFurnitureOffset)
            and validNumber(rx, 360.0) and validNumber(ry, 360.0) and validNumber(rz, 360.0)) then
            return bad()
        end
        items[#items + 1] = { model = it.m, coords = vector3(px, py, pz), rotation = vector3(rx, ry, rz) }
    end
    if #items == 0 then return bad() end

    local name = SanitizeYachtText(type(data.n) == "string" and data.n or "")
    if name == "" then name = "Shared layout" end

    local list = yacht.extras.layouts
    if type(list) ~= "table" then list = {}; yacht.extras.layouts = list end
    local entry = { name = name, items = items }
    local replaced = false
    for i, l in ipairs(list) do if l.name == name then list[i] = entry; replaced = true; break end end
    if not replaced then
        if #list >= ((Config.Comfort.layouts and Config.Comfort.layouts.max) or 3) then
            return TriggerClientEvent("asyacht:Notify", src, L("layoutfull"), "error")
        end
        list[#list + 1] = entry
    end
    TriggerClientEvent("asyacht:Notify", src, L("layoutimported", name, #items), "success")
    LogYacht("Layout imported", ("%s imported layout '%s' (%s pieces) on yacht #%s"):format(GetPlayerIdentifierYacht(src), name, #items, yacht.yachtid))
    SaveYachtExtras(yacht.yachtid)
    if SendYachtUpgrades then SendYachtUpgrades(src, yacht) end
end)

-- ─── buy the missing pieces and apply the layout ────────────────────────────
RegisterServerEvent("asyacht:Global:LayoutBuyMissing")
AddEventHandler("asyacht:Global:LayoutBuyMissing", function(yachtId, index)
    local src = source
    if not cfg().enabled then return end
    local yacht = owned(src, yachtId)
    index = tonumber(index)
    local layout = yacht and index and yacht.extras.layouts and yacht.extras.layouts[index]
    if not layout then return end
    if yacht.furniture.decorating == true then return TriggerClientEvent("asyacht:Notify", src, L("layoutbusy"), "error") end

    local shop = models()
    local have = {}
    for _, f in pairs(yacht.furnitures) do have[f.furnituremodel] = (have[f.furnituremodel] or 0) + 1 end
    local toBuy, total = {}, 0
    for _, item in ipairs(layout.items or {}) do
        if (have[item.model] or 0) > 0 then
            have[item.model] = have[item.model] - 1
        elseif shop[item.model] ~= nil then
            toBuy[#toBuy + 1] = item
            total = total + shop[item.model]
        end
    end
    if #toBuy == 0 then return TriggerClientEvent("asyacht:Notify", src, L("layoutnothingtobuy"), "info") end

    local count = 0
    for _ in pairs(yacht.furnitures) do count = count + 1 end
    if count + #toBuy > YachtLimits.maxFurniturePerYacht then
        return TriggerClientEvent("asyacht:Notify", src, L("layoutfurniturelimit", YachtLimits.maxFurniturePerYacht), "error")
    end
    if ChargeYachtPlayer(src, total) == nil then
        return TriggerClientEvent("asyacht:Notify", src, L("nomoneyenoughfurniture", total), "error")
    end

    for _, item in ipairs(toBuy) do
        local id = GetUniqueFurnitureId(yacht.yachtid)
        yacht.furnitures[id] = { furnituremodel = item.model, furniturecoords = item.coords, furniturerotation = item.rotation }
        TriggerClientEvent("asyacht:Global:FurnitureNew", -1, yacht.yachtid, id, item.model, item.coords, item.rotation)
    end
    updateYachtFurniture(yacht.yachtid, yacht.furnitures)
    local moved = ApplyYachtLayout(yacht, layout)
    TriggerClientEvent("asyacht:Notify", src, L("layoutbought", #toBuy, total), "success")
    LogYacht("Layout pieces bought", ("%s bought %s pieces for $%s to complete layout '%s' on yacht #%s"):format(
        GetPlayerIdentifierYacht(src), #toBuy, total, layout.name, yacht.yachtid))
    if SendYachtUpgrades then SendYachtUpgrades(src, yacht) end
end)
