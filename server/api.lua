-- Public API for other resources. Core exports (HasYacht, GiveYacht, ...) live in server/commands.lua,
-- upkeep / condition / marina exports in their own files. See README.md for the full list.

-- exports['as-yacht']:IsPlayerOnYacht(serverId)  -> yachtId | nil   (standing within the yacht's footprint)
exports("IsPlayerOnYacht", function(src)
    local ped = GetPlayerPed(tonumber(src) or -1)
    if not ped or ped == 0 then return nil end
    local p = GetEntityCoords(ped)
    for _, y in pairs(yachts) do
        local c = GlobalState["asyacht-" .. y.yachtid .. "-coords"] or y.yachtcurrentanchoreddata.coords
        if c then
            local dx, dy = p.x - c.x, p.y - c.y
            if math.sqrt(dx * dx + dy * dy) <= 45.0 then return y.yachtid end
        end
    end
    return nil
end)

-- exports['as-yacht']:GetYachtFuel(yachtId) -> percent | nil
exports("GetYachtFuel", function(yachtId)
    local y = yachts["yacht-" .. tostring(yachtId)]
    return y and (y.extras.fuel or 0) or nil
end)

-- exports['as-yacht']:GetAllYachts() -> { { yachtId, owner, anchored }, ... }
exports("GetAllYachts", function()
    local list = {}
    for _, y in pairs(yachts) do
        list[#list + 1] = { yachtId = y.yachtid, owner = y.owner, anchored = GlobalState["asyacht-" .. y.yachtid .. "-anchored"] == true }
    end
    return list
end)
