-- Fuel, docking fees, insurance / recovery and rentals.

local function L(key, ...) return LanguageFile(key, ...) end

local function findOwnedYacht(src, yachtId)
    yachtId = tonumber(yachtId)
    local yacht = yachtId and yachts["yacht-" .. yachtId]
    if not yacht or not IsPlayerYachtOwnerPermission(yachtId, src) then return nil end
    return yacht
end

local function playerCoords(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    return GetEntityCoords(ped)
end

local function flatDistance(a, b)
    local dx, dy = a.x - b.x, a.y - b.y
    return math.sqrt(dx * dx + dy * dy)
end

local function findPlayerByIdentifier(identifier)
    for _, pid in ipairs(GetPlayers()) do
        pid = tonumber(pid)
        if GetPlayerIdentifierYacht(pid) == identifier then return pid end
    end
    return nil
end

-- ─── Fuel ───────────────────────────────────────────────────────────────────
-- Called with the yacht's position every few seconds while it is sailing.
function ConsumeFuel(yacht, coords, src)
    local cfg = Config.Fuel
    if not cfg or not cfg.enabled then return end

    local now = GetGameTimer()
    local last = yacht.fuelLast
    yacht.fuelLast = { x = coords.x, y = coords.y, at = now }
    if not last or (now - last.at) > 20000 then return end -- first tick of a trip

    local engine = Config.Upgrades.engine[yacht.extras.enginetier or 1]
    local mult = (engine and engine.fuelUse) or 1.0
    local distKm = flatDistance(coords, last) / 1000.0
    local minutes = (now - last.at) / 60000.0
    local used = (distKm * (cfg.usagePerKm or 1.5) + minutes * (cfg.idleUsagePerMin or 0.1)) * mult

    local before = yacht.extras.fuel or cfg.startFuel
    local fuel = math.max(0.0, before - used)
    yacht.extras.fuel = fuel
    yacht.extrasDirty = true

    if src then
        TriggerClientEvent("asyacht:Global:FuelUpdate", src, yacht.yachtid, fuel)
        local warn = cfg.lowFuelWarning or 15.0
        if fuel <= 0.0 and before > 0.0 then
            TriggerClientEvent("asyacht:Notify", src, L("outoffuel"), "error")
        elseif fuel <= warn and before > warn then
            TriggerClientEvent("asyacht:Notify", src, L("lowfuel", math.floor(fuel)), "warning")
        end
    end
end

local function refuelPrice(yacht)
    local cfg = Config.Fuel
    local missing = math.max(0.0, 100.0 - (yacht.extras.fuel or 0.0))
    return math.ceil(missing * (cfg.pricePerPercent or 0))
end
function GetRefuelPrice(yacht) return refuelPrice(yacht) end

RegisterServerEvent("asyacht:Global:RefuelYacht")
AddEventHandler("asyacht:Global:RefuelYacht", function(yachtId)
    local src = source
    local cfg = Config.Fuel
    if not cfg or not cfg.enabled then return end
    yachtId = tonumber(yachtId)
    local yacht = yachtId and yachts["yacht-" .. yachtId]
    if not yacht then return end
    if not (IsPlayerYachtOwnerPermission(yachtId, src) or HasPlayerDrivePermission(yachtId, src)) then return end
    if not YachtIsNearYacht(src, yachtId) then return end

    if cfg.requireStation and #(cfg.stations or {}) > 0 then
        local me, atStation = playerCoords(src), false
        for _, st in ipairs(cfg.stations) do
            if me and flatDistance(me, st.coords) <= st.radius then atStation = true end
        end
        if not atStation then
            return TriggerClientEvent("asyacht:Notify", src, L("needstation"), "error")
        end
    end

    local price = refuelPrice(yacht)
    if price <= 0 then
        return TriggerClientEvent("asyacht:Notify", src, L("tankfull"), "info")
    end
    if not ChargeYachtPlayer(src, price) then
        return TriggerClientEvent("asyacht:Notify", src, L("nomoneyupgrade"), "error")
    end

    yacht.extras.fuel = 100.0
    yacht.fuelLast = nil
    SaveYachtExtras(yacht.yachtid)
    if yacht.driverid then TriggerClientEvent("asyacht:Global:FuelUpdate", yacht.driverid, yacht.yachtid, 100.0) end
    TriggerClientEvent("asyacht:Notify", src, L("refueled", price), "success")
    LogYacht("Yacht refuelled", ("%s refuelled yacht #%s for $%s"):format(GetPlayerIdentifierYacht(src), yacht.yachtid, price))
    if SendYachtUpgrades then SendYachtUpgrades(src, yacht) end
end)

-- ─── Docking fees ───────────────────────────────────────────────────────────
-- Returns true when the yacht may anchor (fee paid or none due).
function ChargeDockingFee(src, coords)
    local cfg = Config.Docking
    if not cfg or not cfg.enabled then return true end
    for _, zone in ipairs(cfg.zones or {}) do
        if flatDistance(coords, zone.coords) <= zone.radius then
            local fee = zone.fee or 0
            if fee > 0 then
                if not ChargeYachtPlayer(src, fee) then
                    TriggerClientEvent("asyacht:Notify", src, L("dockingfeerequired", fee, zone.label or "Marina"), "error")
                    return false
                end
                TriggerClientEvent("asyacht:Notify", src, L("dockingfeepaid", fee, zone.label or "Marina"), "info")
                LogYacht("Docking fee", ("%s paid $%s at %s"):format(GetPlayerIdentifierYacht(src), fee, zone.label or "Marina"))
            end
            return true
        end
    end
    return true
end

-- ─── Insurance + recovery ───────────────────────────────────────────────────
RegisterServerEvent("asyacht:Global:BuyInsurance")
AddEventHandler("asyacht:Global:BuyInsurance", function(yachtId)
    local src = source
    local cfg = Config.Insurance
    if not cfg or not cfg.enabled then return end
    local yacht = findOwnedYacht(src, yachtId)
    if not yacht or not YachtIsNearYacht(src, yacht.yachtid) then return end
    if yacht.extras.insured then
        return TriggerClientEvent("asyacht:Notify", src, L("alreadyinsured"), "info")
    end
    if not ChargeYachtPlayer(src, cfg.price or 0) then
        return TriggerClientEvent("asyacht:Notify", src, L("nomoneyupgrade"), "error")
    end
    yacht.extras.insured = true
    SaveYachtExtras(yacht.yachtid)
    TriggerClientEvent("asyacht:Notify", src, L("insurancebought", cfg.price or 0), "success")
    LogYacht("Yacht insured", ("%s insured yacht #%s for $%s"):format(GetPlayerIdentifierYacht(src), yacht.yachtid, cfg.price or 0))
    if SendYachtUpgrades then SendYachtUpgrades(src, yacht) end
end)

function GetRecoveryFee(yacht)
    local cfg = Config.Insurance
    return yacht.extras.insured and (cfg.insuredRecoveryFee or 0) or (cfg.recoveryFee or 0)
end

-- Moves the owner's yacht to a free anchorage. Returns true on success.
function RecoverYacht(src, yachtId)
    local cfg = Config.Insurance
    if not cfg or not cfg.enabled then return false end
    local identifier = GetPlayerIdentifierYacht(src)

    local yacht
    if yachtId then
        yacht = findOwnedYacht(src, yachtId)
    else
        for _, y in pairs(yachts) do
            if y.owner == identifier then yacht = y break end
        end
    end
    if not yacht then
        TriggerClientEvent("asyacht:Notify", src, L("recovernoyacht"), "error")
        return false
    end
    if yacht.driverid ~= nil or GlobalState["asyacht-" .. yacht.yachtid .. "-anchored"] ~= true then
        TriggerClientEvent("asyacht:Notify", src, L("recoverbusy"), "error")
        return false
    end

    local waitMin = math.ceil(((yacht.extras.lastrecovery or 0) + (cfg.cooldownMinutes or 0) * 60 - os.time()) / 60)
    if waitMin > 0 then
        TriggerClientEvent("asyacht:Notify", src, L("recovercooldown", waitMin), "error")
        return false
    end

    local here = GlobalState["asyacht-" .. yacht.yachtid .. "-coords"] or yacht.yachtcurrentanchoreddata.coords
    for _, pid in ipairs(GetPlayers()) do
        local pc = playerCoords(tonumber(pid))
        if pc and flatDistance(pc, here) < (cfg.clearRadius or 70.0) then
            TriggerClientEvent("asyacht:Notify", src, L("recovernearby", math.floor(cfg.clearRadius or 70.0)), "error")
            return false
        end
    end

    local others = {}
    for k, y in pairs(yachts) do
        if y.yachtid ~= yacht.yachtid then others[k] = y end
    end
    local found, coords, rotation = findFreeYachtSpawn(others)
    if not found then
        TriggerClientEvent("asyacht:Notify", src, L("recovernospace"), "error")
        return false
    end

    local fee = GetRecoveryFee(yacht)
    if not ChargeYachtPlayer(src, fee) then
        TriggerClientEvent("asyacht:Notify", src, L("nomoneyupgrade"), "error")
        return false
    end

    local id = yacht.yachtid
    local c = vector3(coords.x, coords.y, -4.0)
    local r = vector3(0.0, 0.0, rotation.z)
    GlobalState["asyacht-" .. id .. "-coords"] = c
    GlobalState["asyacht-" .. id .. "-rotation"] = r
    yacht.yachtcurrentanchoreddata.coords = c
    yacht.yachtcurrentanchoreddata.rotation = r
    updateYachtLocation(id, c, r)

    local handler = GlobalState["asyacht-" .. id .. "-vehhandler"]
    if handler and DoesEntityExist(handler) then
        SetEntityCoords(handler, c.x, c.y, c.z)
        SetEntityRotation(handler, 0.0, 0.0, r.z)
    end
    TriggerClientEvent("asyacht:Global:YachtMaximumSynchronizeAnchor", -1, id)

    yacht.extras.lastrecovery = os.time()
    SaveYachtExtras(id)
    TriggerClientEvent("asyacht:Notify", src, L("recoverdone", fee), "success")
    LogYacht("Yacht recovered", ("%s recovered yacht #%s for $%s"):format(identifier, id, fee))
    return true
end

CreateThread(function()
    local cfg = Config.Insurance
    if cfg and cfg.enabled and cfg.command and cfg.command ~= "" then
        RegisterCommand(cfg.command, function(source)
            if source == 0 then return end
            RecoverYacht(source)
        end, false)
    end
end)

exports("RecoverYacht", function(src, yachtId) return RecoverYacht(src, yachtId) end)

-- ─── Rentals ────────────────────────────────────────────────────────────────
local pendingRentals = {} -- [renterSrc] = { yachtId, ownerSrc, minutes, price, expires }

RegisterServerEvent("asyacht:Global:OfferRental")
AddEventHandler("asyacht:Global:OfferRental", function(yachtId, targetId, minutes, price)
    local src = source
    local cfg = Config.Rental
    if not cfg or not cfg.enabled then return end
    local yacht = findOwnedYacht(src, yachtId)
    if not yacht or not YachtIsNearYacht(src, yacht.yachtid) then return end

    targetId = tonumber(targetId)
    minutes, price = tonumber(minutes), tonumber(price)
    local valid = targetId and targetId ~= src and GetPlayerName(targetId) ~= nil
        and minutes and minutes == math.floor(minutes) and minutes >= 5 and minutes <= (cfg.maxMinutes or 240)
        and price and price == math.floor(price) and price >= 0 and price <= (cfg.maxPrice or 500000)
    local me, them = playerCoords(src), valid and playerCoords(targetId)
    if not valid or not me or not them or flatDistance(me, them) > 30.0 then
        return TriggerClientEvent("asyacht:Notify", src, L("rentalinvalid"), "error")
    end
    if GetPlayerIdentifierYacht(targetId) == yacht.owner then
        return TriggerClientEvent("asyacht:Notify", src, L("rentalinvalid"), "error")
    end

    pendingRentals[targetId] = {
        yachtId = yacht.yachtid, ownerSrc = src, minutes = minutes, price = price,
        expires = GetGameTimer() + (cfg.offerTimeout or 30) * 1000,
    }
    local label = ((yacht.textdata.uppertext or "") .. " " .. (yacht.textdata.bottomtext or "")):gsub("%s+$", "")
    TriggerClientEvent("asyacht:Global:RentalOffer", targetId, GetPlayerNameYacht(src), label, minutes, price)
    TriggerClientEvent("asyacht:Notify", src, L("rentaloffersent"), "info")
end)

RegisterServerEvent("asyacht:Global:RentalResponse")
AddEventHandler("asyacht:Global:RentalResponse", function(accepted)
    local src = source
    local offer = pendingRentals[src]
    pendingRentals[src] = nil
    if not offer then return end
    if GetGameTimer() > offer.expires then
        return TriggerClientEvent("asyacht:Notify", src, L("rentalexpired"), "error")
    end
    if accepted ~= true then
        return TriggerClientEvent("asyacht:Notify", offer.ownerSrc, L("rentaldeclined"), "info")
    end

    local yacht = yachts["yacht-" .. offer.yachtId]
    if not yacht or GetPlayerName(offer.ownerSrc) == nil or GetPlayerIdentifierYacht(offer.ownerSrc) ~= yacht.owner then
        return TriggerClientEvent("asyacht:Notify", src, L("rentalinvalid"), "error")
    end
    local identifier = GetPlayerIdentifierYacht(src)
    local existing = yacht.permissions[tostring(identifier)]
    if existing and not existing.rentalexpires then -- don't overwrite access the owner granted by hand
        return TriggerClientEvent("asyacht:Notify", src, L("rentalinvalid"), "error")
    end
    if not ChargeYachtPlayer(src, offer.price) then
        return TriggerClientEvent("asyacht:Notify", src, L("nomoneyupgrade"), "error")
    end
    if offer.price > 0 then AddMoneyYacht(offer.ownerSrc, offer.price) end

    local perm = {}
    for k, v in pairs(Config.Rental.grant) do perm[k] = v end
    perm.playername = GetPlayerNameYacht(src)
    perm.rentalexpires = os.time() + offer.minutes * 60
    yacht.permissions[tostring(identifier)] = perm
    updateYachtPermissions(yacht.yachtid, yacht.permissions)

    TriggerClientEvent("asyacht:Notify", src, L("rentalstarted", offer.minutes), "success")
    TriggerClientEvent("asyacht:Notify", offer.ownerSrc, L("rentalstartedowner", perm.playername, offer.minutes, offer.price), "success")
    LogYacht("Yacht rented", ("%s rented yacht #%s to %s for %s min, $%s"):format(yacht.owner, yacht.yachtid, identifier, offer.minutes, offer.price))
end)

AddEventHandler("playerDropped", function()
    pendingRentals[source] = nil
end)

-- Removes expired rentals (runs even while the owner is offline).
function ExpireRentals()
    local now = os.time()
    for _, yacht in pairs(yachts) do
        local changed = false
        for identifier, perm in pairs(yacht.permissions) do
            if perm.rentalexpires and now >= perm.rentalexpires then
                yacht.permissions[identifier] = nil
                changed = true
                local renter = findPlayerByIdentifier(identifier)
                if renter then
                    TriggerClientEvent("asyacht:Notify", renter, L("rentalended"), "info")
                    if yacht.driverid == renter then yacht.driverleave = true end
                end
            end
        end
        if changed then updateYachtPermissions(yacht.yachtid, yacht.permissions) end
    end
end

CreateThread(function()
    while true do
        Wait(20000)
        ExpireRentals()
    end
end)
