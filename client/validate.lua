-- as-yacht client/validate.lua: model check for /yachtcheck (admins). Models can only be verified on a client,
-- because only a client knows which models are streamed. Results go to the F8 console and a notification.

local function collect()
    local list = {}
    local function add(model, where) if type(model) == "string" and model ~= "" then list[#list + 1] = { model = model, where = where } end end

    add("as_yacht_veh", "yacht model (as-yachtmodels)")
    if Config.Marinas and Config.Marinas.enabled then add(Config.Marinas.pedModel, "marina ped") end
    local tender = Config.Comfort and Config.Comfort.tender
    for _, o in ipairs((tender and tender.enabled and tender.options) or {}) do add(o.model, "tender '" .. tostring(o.label) .. "'") end
    for _, f in pairs(Config.BasicEquipment or {}) do add(f.furnituremodel, "starter furniture") end
    for _, cat in ipairs(Config.Furnitures or {}) do
        for _, item in ipairs(cat.categoryobjects or {}) do add(item.furnitureobject, "shop: " .. tostring(cat.categorylabel)) end
    end
    return list
end

RegisterNetEvent("asyacht:Global:CheckModels")
AddEventHandler("asyacht:Global:CheckModels", function()
    local list, missing, seen = collect(), {}, {}
    for i, entry in ipairs(list) do
        if not seen[entry.model] then
            seen[entry.model] = true
            if not IsModelInCdimage(GetHashKey(entry.model)) then missing[#missing + 1] = entry end
        end
        if i % 200 == 0 then Wait(0) end -- do not hitch the game on a large catalogue
    end

    if #missing == 0 then
        print(("^2[as-yacht]^7 model check: all %d models exist"):format(#list))
        Notify(("Model check: all %d models exist."):format(#list), "success")
        return
    end
    print(("^3[as-yacht]^7 model check: %d model(s) are missing or not streamed:"):format(#missing))
    for _, m in ipairs(missing) do print(("^3  - ^7%s  (%s)"):format(m.model, m.where)) end
    Notify(("Model check: %d missing model(s), see the F8 console."):format(#missing), "error")
end)
