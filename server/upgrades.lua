-- ─── Sailing autosave ───────────────────────────────────────────────────────
-- Saves the live position of yachts that are being sailed, so a crash or restart
-- does not put them back at their previous anchor point.
function SaveSailingYachts(sync)
    for _, yacht in pairs(yachts) do
        local id = yacht.yachtid
        if yacht.driverid ~= nil and GlobalState["asyacht-" .. id .. "-anchored"] == false then
            local coords, rotation

            local handler = GlobalState["asyacht-" .. id .. "-vehhandler"]
            if handler and DoesEntityExist(handler) then
                -- server-networked yacht: read the entity directly
                local c, r = GetEntityCoords(handler), GetEntityRotation(handler)
                coords, rotation = vector3(c.x, c.y, -4.0), vector3(0.0, 0.0, r.z)
                if ConsumeFuel then ConsumeFuel(yacht, coords, yacht.driverid) end
            elseif yacht.livepos then
                coords, rotation = yacht.livepos.coords, yacht.livepos.rotation
            end

            if coords and rotation then
                local args = { json.encode({ coords = coords }), json.encode({ rotation = rotation }), id }
                if sync then
                    MySQL.update.await("UPDATE yachts SET coords = ?, rotation = ? WHERE yachtid = ?", args)
                else
                    MySQL.update("UPDATE yachts SET coords = ?, rotation = ? WHERE yachtid = ?", args)
                end
            end
        end
    end
end

CreateThread(function()
    local cfg = Config.Autosave
    if not cfg or not cfg.enabled then return end
    local interval = math.max(10, tonumber(cfg.interval) or 30) * 1000
    while true do
        Wait(interval)
        SaveSailingYachts(false)
        SaveDirtyYachtExtras(false)
    end
end)

-- ─── Upgrades ───────────────────────────────────────────────────────────────
local function ownedYachtFor(src, yachtId)
    yachtId = tonumber(yachtId)
    local yacht = yachtId and yachts["yacht-" .. yachtId]
    if not yacht then return nil end
    if not IsPlayerYachtOwnerPermission(yachtId, src) then return nil end
    if not YachtIsNearYacht(src, yachtId) then return nil end
    if YachtThrottled(src, "upgrade", 250) then return nil end
    return yacht
end

-- Takes the price from the first account that can cover it. Returns the account name, or nil.
function ChargeYachtPlayer(src, price)
    if price <= 0 then return "cash" end
    local methods = (Config.Payment and Config.Payment.methods) or { "cash" }
    local ordered, default = {}, (Config.Payment and Config.Payment.default) or "cash"
    ordered[#ordered + 1] = default
    for _, m in ipairs(methods) do if m ~= default then ordered[#ordered + 1] = m end end
    for _, account in ipairs(ordered) do
        if GetMoneyYacht(src, account) >= price then
            RemoveMoneyYacht(src, price, account)
            return account
        end
    end
    return nil
end

local function BuildUpgradesPayload(src, yacht)
    local U = Config.Upgrades
    local railings = {}
    for id, r in ipairs(Config.RailingTypes) do
        railings[#railings + 1] = { id = id, label = r.label, price = r.price, swatch = r.swatch }
    end
    local engines, storages = {}, {}
    for id, e in ipairs(U.engine) do engines[#engines + 1] = { id = id, label = e.label, price = e.price, power = e.power } end
    for id, st in ipairs(U.storage) do storages[#storages + 1] = { id = id, label = st.label, price = st.price, slots = st.slots, weight = st.weight } end

    local nearby = {}
    for _, pid in ipairs(YachtGetNearbyPlayers(src, 30.0)) do
        nearby[#nearby + 1] = { id = pid, name = GetPlayerNameYacht(pid) }
    end

    return {
        yachtid = yacht.yachtid,
        upper = yacht.textdata.uppertext, bottom = yacht.textdata.bottomtext,
        color = yacht.yachtcolor, railing = yacht.railing.railingid, flag = yacht.flagdata.flagid,
        lightcat = yacht.lighting.lightingcategory, lightid = yacht.lighting.lightingid,
        enginetier = yacht.extras.enginetier, storagetier = yacht.extras.storagetier,
        engines = engines, storages = storages, railings = railings,
        renameprice = U.renamePrice, appearanceprice = U.appearancePrice,
        namerules = { minLength = Config.NameRules.minLength, maxLength = Config.NameRules.maxLength, blockedWords = Config.NameRules.blockedWords },
        cash = GetMoneyYacht(src, "cash"), bank = GetMoneyYacht(src, "bank"),
        fuel = Config.Fuel.enabled and (yacht.extras.fuel or 0) or nil,
        refuelprice = Config.Fuel.enabled and GetRefuelPrice(yacht) or nil,
        insurance = Config.Insurance.enabled and {
            insured = yacht.extras.insured == true,
            price = Config.Insurance.price,
            recoveryfee = GetRecoveryFee(yacht),
            command = Config.Insurance.command,
        } or nil,
        comfort = BuildComfortPayload and BuildComfortPayload(yacht) or nil,
        upkeep = GetUpkeepInfo and GetUpkeepInfo(yacht) or nil,
        condition = Config.Condition and Config.Condition.enabled and GetYachtCondition and {
            value = GetYachtCondition(yacht), repairprice = GetRepairPrice(yacht, 0),
            insureddiscount = yacht.extras.insured and Config.Condition.insuredDiscount or 0,
        } or nil,
        rental = Config.Rental.enabled and {
            maxminutes = Config.Rental.maxMinutes, maxprice = Config.Rental.maxPrice,
            nearby = nearby,
        } or nil,
    }
end

function SendYachtUpgrades(src, yacht)
    TriggerClientEvent("asyacht:Global:UpgradesData", src, BuildUpgradesPayload(src, yacht))
end
local SendUpgrades = SendYachtUpgrades

local function Fail(src, key, ...)
    TriggerClientEvent("asyacht:Notify", src, LanguageFile(key, ...), "error")
end

RegisterServerEvent("asyacht:Global:RequestUpgrades")
AddEventHandler("asyacht:Global:RequestUpgrades", function(yachtId)
    local src = source
    if not Config.Upgrades.enabled then return end
    local yacht = ownedYachtFor(src, yachtId)
    if yacht then SendUpgrades(src, yacht) end
end)

-- Name change ----------------------------------------------------------------
RegisterServerEvent("asyacht:Global:UpgradeRename")
AddEventHandler("asyacht:Global:UpgradeRename", function(yachtId, upper, bottom)
    local src = source
    if not Config.Upgrades.enabled then return end
    local yacht = ownedYachtFor(src, yachtId)
    if not yacht then return end

    local text = { uppertext = SanitizeYachtText(upper), bottomtext = SanitizeYachtText(bottom) }
    if text.uppertext == yacht.textdata.uppertext and text.bottomtext == yacht.textdata.bottomtext then
        return Fail(src, "nothingchanged")
    end
    local ok, key, a1, a2 = ValidateYachtName(text, yacht.yachtid)
    if not ok then return Fail(src, key, a1, a2) end

    local price = Config.Upgrades.renamePrice or 0
    local account = ChargeYachtPlayer(src, price)
    if not account then return Fail(src, "nomoneyupgrade") end

    yacht.textdata = { uppertext = text.uppertext, bottomtext = text.bottomtext }
    MySQL.update("UPDATE yachts SET uppertext = ?, bottomtext = ? WHERE yachtid = ?", { text.uppertext, text.bottomtext, yacht.yachtid })
    TriggerClientEvent("asyacht:Global:YachtTextUpdated", -1, yacht.yachtid, text.uppertext, text.bottomtext)
    TriggerClientEvent("asyacht:Notify", src, LanguageFile("yachtrenamed", price), "success")
    LogYacht("Yacht renamed", ("%s renamed yacht #%s to %s %s (paid $%s)"):format(
        GetPlayerIdentifierYacht(src), yacht.yachtid, text.uppertext, text.bottomtext, price))
    SendUpgrades(src, yacht)
end)

-- Appearance (hull colour, railing, flag, lights) ----------------------------
RegisterServerEvent("asyacht:Global:UpgradeAppearance")
AddEventHandler("asyacht:Global:UpgradeAppearance", function(yachtId, colorId, railingId, flagId, lightCat, lightId)
    local src = source
    if not Config.Upgrades.enabled then return end
    local yacht = ownedYachtFor(src, yachtId)
    if not yacht then return end

    local L = YachtLimits
    if not (IsYachtInt(colorId, L.color) and IsYachtInt(railingId, L.railing) and IsYachtInt(flagId, L.flag)
        and IsYachtInt(lightCat, L.lightCategory) and IsYachtInt(lightId, L.lightId)) then
        return
    end

    if colorId == yacht.yachtcolor and railingId == yacht.railing.railingid and flagId == yacht.flagdata.flagid
        and lightCat == yacht.lighting.lightingcategory and lightId == yacht.lighting.lightingid then
        return Fail(src, "nothingchanged")
    end

    local price = Config.Upgrades.appearancePrice or 0
    local account = ChargeYachtPlayer(src, price)
    if not account then return Fail(src, "nomoneyupgrade") end

    yacht.yachtcolor = colorId
    yacht.railing.railingid = railingId
    yacht.flagdata.flagid = flagId
    yacht.lighting.lightingcategory = lightCat
    yacht.lighting.lightingid = lightId
    MySQL.update("UPDATE yachts SET colorid = ?, railingid = ?, flagid = ?, lighcategoryid = ?, lightid = ? WHERE yachtid = ?",
        { colorId, railingId, flagId, lightCat, lightId, yacht.yachtid })
    TriggerClientEvent("asyacht:Global:YachtAppearanceUpdated", -1, yacht.yachtid, flagId, lightCat, lightId, railingId, colorId)
    TriggerClientEvent("asyacht:Notify", src, LanguageFile("appearanceupdated", price), "success")
    LogYacht("Yacht appearance changed", ("%s changed the look of yacht #%s (paid $%s)"):format(
        GetPlayerIdentifierYacht(src), yacht.yachtid, price))
    SendUpgrades(src, yacht)
end)

-- Engine / storage tiers -----------------------------------------------------
-- Resizes the stashes of a yacht after a storage upgrade (best effort, depends on the inventory).
function ApplyYachtStorageTier(yachtId)
    local yacht = yachts["yacht-" .. yachtId]
    if not yacht then return end
    local tier = Config.Upgrades.storage[yacht.extras.storagetier] or Config.Upgrades.storage[1]
    if Config.InventorySystem == "oxinventory" and Config.OxInventory == true then
        for i in pairs(Config.YachtStorageLocations) do
            local id = "yacht-" .. yachtId .. "-storage-" .. i
            pcall(function() exports.ox_inventory:RegisterStash(id, "Yacht Storage - " .. i, tier.slots, tier.weight, nil) end)
            pcall(function() exports.ox_inventory:SetSlotCount(id, tier.slots) end)
            pcall(function() exports.ox_inventory:SetMaxWeight(id, tier.weight) end)
        end
    end
end

local function BuyTier(src, yachtId, tierId, field, list, successKey, logTitle)
    if not Config.Upgrades.enabled then return end
    local yacht = ownedYachtFor(src, yachtId)
    if not yacht then return end
    if not IsYachtInt(tierId, { 1, #list }) then return end
    if tierId <= (yacht.extras[field] or 1) then return Fail(src, "alreadyhastier") end

    local tier = list[tierId]
    local account = ChargeYachtPlayer(src, tier.price)
    if not account then return Fail(src, "nomoneyupgrade") end

    yacht.extras[field] = tierId
    SaveYachtExtras(yacht.yachtid)
    TriggerClientEvent("asyacht:Notify", src, LanguageFile(successKey, tier.label, tier.price), "success")
    LogYacht(logTitle, ("%s bought %s tier %s (%s) for yacht #%s for $%s"):format(
        GetPlayerIdentifierYacht(src), field, tierId, tier.label, yacht.yachtid, tier.price))
    SendUpgrades(src, yacht)
    return yacht
end

RegisterServerEvent("asyacht:Global:UpgradeEngine")
AddEventHandler("asyacht:Global:UpgradeEngine", function(yachtId, tierId)
    BuyTier(source, yachtId, tierId, "enginetier", Config.Upgrades.engine, "engineupgraded", "Engine upgraded")
end)

RegisterServerEvent("asyacht:Global:UpgradeStorage")
AddEventHandler("asyacht:Global:UpgradeStorage", function(yachtId, tierId)
    local yacht = BuyTier(source, yachtId, tierId, "storagetier", Config.Upgrades.storage, "storageupgraded", "Storage upgraded")
    if yacht then ApplyYachtStorageTier(yacht.yachtid) end
end)
