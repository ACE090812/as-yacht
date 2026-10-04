-- Admin tools for the upkeep, hull and fuel systems. Names come from Config.AdminCommands.
-- Allowed for: group admin/god (framework), ACE "asyacht.admin", or the server console.

local AdminCmd = Config.AdminCommands or {}

local function reply(src, message) YachtReply(src, message) end

local function who(src)
    return src == 0 and "console" or GetPlayerIdentifierYacht(src)
end

-- Runs fn(yacht) for an admin and a valid yacht id argument.
local function withYacht(name, handler)
    RegisterCommand(name, function(source, args)
        if not YachtIsAdmin(source) then return end
        local id = tonumber(args[1])
        local yacht = id and yachts["yacht-" .. NormYachtId(id)]
        if not yacht then
            return reply(source, Language[Config.Language]["yachtnotfound"])
        end
        handler(source, yacht, args)
    end, false)
end

local function day(seconds)
    return ("%.1f"):format(seconds / 86400)
end

-- /yachtinfo <id> ---------------------------------------------------------------
withYacht(AdminCmd.info or "yachtinfo", function(src, y)
    local c = GlobalState["asyacht-" .. y.yachtid .. "-coords"] or y.yachtcurrentanchoreddata.coords
    local marina = GetYachtMarina and GetYachtMarina(y)
    local marinaLabel = marina and Config.Marinas.list[marina] and Config.Marinas.list[marina].label or "none"
    local furniture, layouts = 0, #(y.extras.layouts or {})
    for _ in pairs(y.furnitures) do furniture = furniture + 1 end

    reply(src, ("#%s %s %s | owner %s"):format(y.yachtid, y.textdata.uppertext or "", y.textdata.bottomtext or "", y.owner))
    reply(src, ("at %.0f, %.0f | %s | driver %s | marina %s"):format(c.x, c.y,
        GlobalState["asyacht-" .. y.yachtid .. "-anchored"] == true and "anchored" or "sailing", tostring(y.driverid), marinaLabel))
    reply(src, ("fuel %.0f%% | hull %.0f%% | insured %s | engine %s | storage %s"):format(y.extras.fuel or 0,
        GetYachtCondition and GetYachtCondition(y) or 100, tostring(y.extras.insured == true), tostring(y.extras.enginetier), tostring(y.extras.storagetier)))
    local up = GetUpkeepInfo and GetUpkeepInfo(y)
    if up then
        reply(src, ("upkeep %s | %s | cost $%s | paid until %s"):format(up.status,
            up.status == "ok" and (day(up.seconds) .. " d left") or (day(up.seconds) .. " d overdue"), up.cost, os.date("%Y-%m-%d %H:%M", up.paidUntil)))
    end
    reply(src, ("furniture %d | layouts %d | mood %s | permissions %d"):format(furniture, layouts, tostring(y.extras.mood),
        (function() local n = 0 for _ in pairs(y.permissions) do n = n + 1 end return n end)()))
end)

-- /yachtupkeep <id> [forgive | days <n>] ----------------------------------------
withYacht(AdminCmd.upkeep or "yachtupkeep", function(src, y, args)
    if not Config.Upkeep or not Config.Upkeep.enabled then return reply(src, "Upkeep is disabled in config.lua.") end
    local mode = args[2] and args[2]:lower()
    local u = y.extras.upkeep
    if not u then GetUpkeepInfo(y); u = y.extras.upkeep end
    local now = os.time()

    if mode == "forgive" then
        u.paidUntil = now + math.max(1, tonumber(Config.Upkeep.intervalDays) or 7) * 86400
    elseif mode == "days" then
        local n = tonumber(args[3])
        if not n or math.abs(n) > 3650 then return reply(src, "Usage: /" .. (AdminCmd.upkeep or "yachtupkeep") .. " <id> days <-3650..3650>") end
        u.paidUntil = now + math.floor(n * 86400)
    elseif mode ~= nil then
        return reply(src, "Usage: /" .. (AdminCmd.upkeep or "yachtupkeep") .. " <id> [forgive | days <n>]")
    end

    if mode then
        u.state = nil -- lets the sweep notify the owner about the new state
        y.extrasDirty = true
        SaveYachtExtras(y.yachtid)
        LogYacht("Yacht upkeep (admin)", ("%s set upkeep of yacht #%s: %s"):format(who(src), y.yachtid, table.concat(args, " ", 2)))
    end
    local info = GetUpkeepInfo(y)
    reply(src, ("yacht #%s upkeep: %s, %s d %s, next fee $%s"):format(y.yachtid, info.status, day(info.seconds or 0),
        info.status == "ok" and "left" or "overdue", info.cost))
end)

-- /yachtrepair <id> ------------------------------------------------------------
withYacht(AdminCmd.repair or "yachtrepair", function(src, y)
    y.extras.condition = 100.0
    SaveYachtExtras(y.yachtid)
    if y.driverid then TriggerClientEvent("asyacht:Global:ConditionUpdate", y.driverid, y.yachtid, 100.0) end
    LogYacht("Yacht repaired (admin)", ("%s repaired yacht #%s for free"):format(who(src), y.yachtid))
    reply(src, ("yacht #%s hull restored to 100%%"):format(y.yachtid))
end)

-- /yachtfuel <id> [percent] ----------------------------------------------------
withYacht(AdminCmd.fuel or "yachtfuel", function(src, y, args)
    local pct = args[2] and tonumber(args[2]) or 100.0
    if not pct or pct < 0 or pct > 100 then return reply(src, "Usage: /" .. (AdminCmd.fuel or "yachtfuel") .. " <id> [0-100]") end
    y.extras.fuel = pct + 0.0
    y.fuelLast = nil
    SaveYachtExtras(y.yachtid)
    if y.driverid then TriggerClientEvent("asyacht:Global:FuelUpdate", y.driverid, y.yachtid, y.extras.fuel) end
    LogYacht("Yacht fuel (admin)", ("%s set fuel of yacht #%s to %s%%"):format(who(src), y.yachtid, pct))
    reply(src, ("yacht #%s fuel set to %.0f%%"):format(y.yachtid, pct))
end)

-- /yachtcheck ------------------------------------------------------------------
RegisterCommand(AdminCmd.check or "yachtcheck", function(source)
    if not YachtIsAdmin(source) then return end
    local problems = ValidateYachtConfig()
    if #problems == 0 then
        reply(source, "Config check: no problems found.")
    else
        reply(source, ("Config check: %d problem(s), see the server console."):format(#problems))
    end
    PrintYachtConfigProblems(problems)
    -- the models can only be checked on a client
    if source ~= 0 then TriggerClientEvent("asyacht:Global:CheckModels", source) end
end, false)
