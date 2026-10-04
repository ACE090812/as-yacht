-- ─── Logging ────────────────────────────────────────────────────────────────
function LogYacht(title, message)
    local cfg = Config.Logging
    if not cfg or not cfg.enabled then return end

    if cfg.console then
        print(("[as-yacht] %s: %s"):format(title, message))
    end

    if cfg.webhook and cfg.webhook ~= "" then
        PerformHttpRequest(cfg.webhook, function() end, "POST", json.encode({
            username = cfg.botname or "AS Yacht",
            embeds = {{
                title = title,
                description = message,
                color = 3447003,
                footer = { text = os.date("%Y-%m-%d %H:%M:%S") },
            }},
        }), { ["Content-Type"] = "application/json" })
    end
end

-- ─── Helpers ────────────────────────────────────────────────────────────────
local function Reply(src, message)
    if src == 0 then
        print("[as-yacht] " .. message)
    else
        TriggerClientEvent("chat:addMessage", src, { args = { "Yacht", message } })
    end
end

local function IsYachtAdmin(src)
    if src == 0 then return true end
    if IsPlayerAceAllowed(src, "asyacht.admin") then return true end
    return CheckYachtGivePermission(src) == true
end

-- Validates the 8 yacht option args shared by both give commands.
-- args order: flag, lightCategory, lightId, upperText, bottomText, railing, color, equipment
local function ParseYachtOptions(a)
    local flag, lcat, lid = tonumber(a[1]), tonumber(a[2]), tonumber(a[3])
    local railing, color, equipment = tonumber(a[6]), tonumber(a[7]), tonumber(a[8])
    local L = YachtLimits
    if not (IsYachtInt(flag, L.flag) and IsYachtInt(lcat, L.lightCategory) and IsYachtInt(lid, L.lightId)
        and IsYachtInt(railing, L.railing) and IsYachtInt(color, L.color) and IsYachtInt(equipment, L.equipment)
        and a[4] and a[5]) then
        return nil
    end
    return {
        flagid = flag,
        lightdata = { category = lcat, id = lid },
        textdata = { uppertext = SanitizeYachtText(a[4]), bottomtext = SanitizeYachtText(a[5]) },
        railingid = railing,
        colorid = color,
        equipmentid = equipment,
    }
end

-- ─── Give commands (one implementation for both) ────────────────────────────
local function RegisterGiveCommand(name, byIdentifier)
    RegisterCommand(name, function(source, args)
        if not IsYachtAdmin(source) then return end

        if not args[1] then
            Reply(source, Language[Config.Language][byIdentifier and "identifierplayer" or "idplayer"])
            return
        end

        local options = ParseYachtOptions({ table.unpack(args, 2, 9) })
        if not options then
            Reply(source, Language[Config.Language]["definedata"])
            return
        end

        local targetSrc, identifier
        if byIdentifier then
            identifier = tostring(args[1])
        else
            targetSrc = tonumber(args[1])
            if not targetSrc or not GetPlayerName(targetSrc) then
                Reply(source, Language[Config.Language]["idplayer"])
                return
            end
        end

        local found, freeCoords, freeRotation = findFreeYachtSpawn(yachts)
        if not found then
            Reply(source, Language[Config.Language]["nospaceforyacht"])
            return
        end

        local yachtId
        if byIdentifier then
            yachtId = CreateYachtIdentifier(identifier, freeCoords, freeRotation, options.flagid, options.lightdata,
                options.textdata, options.railingid, options.colorid, options.equipmentid)
        else
            yachtId = CreateYachtCommand(targetSrc, freeCoords, freeRotation, options.flagid, options.lightdata,
                options.textdata, options.railingid, options.colorid, options.equipmentid)
        end

        if yachtId then
            local who = byIdentifier and identifier or GetPlayerNameYacht(targetSrc)
            Reply(source, LanguageFile("yachtgive", who))
            LogYacht("Yacht given", ("%s gave yacht #%s to %s"):format(source == 0 and "console" or GetPlayerIdentifierYacht(source), yachtId, who))
        end
    end, false)
end

RegisterGiveCommand(Config.GiveYachtCommand, false)
RegisterGiveCommand(Config.GiveYachtIdentifierCommand, true)

-- ─── Admin commands ─────────────────────────────────────────────────────────
local AdminCmd = Config.AdminCommands or {}

RegisterCommand(AdminCmd.list or "yachtlist", function(source)
    if not IsYachtAdmin(source) then return end
    local count = 0
    for _, y in pairs(yachts) do
        count = count + 1
        local c = y.yachtcurrentanchoreddata.coords
        Reply(source, ("#%s owner=%s at %.0f, %.0f%s"):format(y.yachtid, y.owner, c.x, c.y, y.driverid and " (sailing)" or ""))
    end
    Reply(source, ("%d yacht(s) total"):format(count))
end, false)

RegisterCommand(AdminCmd.teleport or "yachtgoto", function(source, args)
    if not IsYachtAdmin(source) or source == 0 then return end
    local yacht = yachts["yacht-" .. tostring(tonumber(args[1]))]
    if not yacht then
        Reply(source, Language[Config.Language]["yachtnotfound"])
        return
    end
    local c = GlobalState["asyacht-" .. yacht.yachtid .. "-coords"] or yacht.yachtcurrentanchoreddata.coords
    SetEntityCoords(GetPlayerPed(source), c.x, c.y, c.z + 15.0)
end, false)

RegisterCommand(AdminCmd.delete or "yachtdelete", function(source, args)
    if not IsYachtAdmin(source) then return end
    local yachtId = tonumber(args[1])
    if yachtId and RemoveYachtFully(yachtId) then
        Reply(source, LanguageFile("yachtdeleted", yachtId))
        LogYacht("Yacht deleted", ("%s deleted yacht #%s"):format(source == 0 and "console" or GetPlayerIdentifierYacht(source), yachtId))
    else
        Reply(source, Language[Config.Language]["yachtnotfound"])
    end
end, false)

-- ─── Exports (for other resources) ──────────────────────────────────────────
-- exports['as-yacht']:HasYacht(serverIdOrIdentifier)        -> boolean
-- exports['as-yacht']:GetPlayerYachts(serverIdOrIdentifier) -> { yachtId, ... }
-- exports['as-yacht']:GetYachtData(yachtId)                 -> table | nil
-- exports['as-yacht']:GetYachtOwner(yachtId)                -> identifier | nil
-- exports['as-yacht']:GiveYacht(identifier, options?)       -> yachtId | nil
-- exports['as-yacht']:RemoveYacht(yachtId)                  -> boolean
-- exports['as-yacht']:TransferYacht(yachtId, identifier)    -> boolean

local function ResolveIdentifier(v)
    if type(v) == "number" then return GetPlayerIdentifierYacht(v) end
    return v
end

local function GetPlayerYachtIds(who)
    local identifier = ResolveIdentifier(who)
    local list = {}
    for _, y in pairs(yachts) do
        if y.owner == identifier then list[#list + 1] = y.yachtid end
    end
    return list
end

exports("GetPlayerYachts", GetPlayerYachtIds)

exports("HasYacht", function(who)
    return #GetPlayerYachtIds(who) > 0
end)

exports("GetYachtOwner", function(yachtId)
    local y = yachts["yacht-" .. tostring(yachtId)]
    return y and y.owner or nil
end)

exports("GetYachtData", function(yachtId)
    local y = yachts["yacht-" .. tostring(yachtId)]
    if not y then return nil end
    return {
        yachtid = y.yachtid,
        owner = y.owner,
        coords = GlobalState["asyacht-" .. y.yachtid .. "-coords"] or y.yachtcurrentanchoreddata.coords,
        anchored = GlobalState["asyacht-" .. y.yachtid .. "-anchored"] == true,
        driver = y.driverid,
        flag = y.flagdata.flagid,
        color = y.yachtcolor,
        railing = y.railing.railingid,
        lighting = { category = y.lighting.lightingcategory, id = y.lighting.lightingid },
        text = { upper = y.textdata.uppertext, bottom = y.textdata.bottomtext },
        permissions = y.permissions,
        fuel = y.extras.fuel,
        insured = y.extras.insured == true,
        condition = GetYachtCondition and GetYachtCondition(y) or nil,
        upkeep = GetUpkeepInfo and GetUpkeepInfo(y) or nil,
    }
end)

exports("GiveYacht", function(identifier, o)
    o = o or {}
    local options = ParseYachtOptions({
        o.flag or 1, o.lightCategory or 1, o.lightId or 1,
        o.upperText or "", o.bottomText or "",
        o.railing or 1, o.color or 1, o.equipment or 1,
    })
    if not options or type(identifier) ~= "string" or identifier == "" then return nil end
    local found, coords, rotation = findFreeYachtSpawn(yachts)
    if not found then return nil end
    return CreateYachtIdentifier(identifier, coords, rotation, options.flagid, options.lightdata,
        options.textdata, options.railingid, options.colorid, options.equipmentid)
end)

exports("RemoveYacht", function(yachtId)
    return RemoveYachtFully(tonumber(yachtId))
end)

exports("TransferYacht", function(yachtId, identifier)
    return DoTransferYacht(tonumber(yachtId), identifier)
end)
