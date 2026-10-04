-- as-yacht client/marina.lua: Marina blips, harbour master NPCs and the harbour menu (pay upkeep, refuel, repair).

local harbourPeds = {}   -- [marinaIndex] = ped
local MENU_ID = "asyacht_harbour"

local function money(n)
    local s = tostring(math.floor(tonumber(n) or 0))
    local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    return "$" .. out
end

local function duration(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    local d, h, m = seconds // 86400, seconds % 86400 // 3600, seconds % 3600 // 60
    if d > 0 then return ("%d d %d h"):format(d, h) end
    if h > 0 then return ("%d h %d min"):format(h, m) end
    return ("%d min"):format(math.max(1, m))
end

local function harbourPos(m) return vector3(m.harbour.x, m.harbour.y, m.harbour.z) end

-- Blips + NPC streaming ---------------------------------------------------------
CreateThread(function()
    local cfg = Config.Marinas
    if not cfg or not cfg.enabled then return end

    for _, m in ipairs(cfg.list or {}) do
        local blip = AddBlipForCoord(m.harbour.x, m.harbour.y, m.harbour.z)
        local b = cfg.blip or {}
        SetBlipSprite(blip, b.sprite or 410)
        SetBlipColour(blip, b.colour or 3)
        SetBlipScale(blip, b.scale or 0.8)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(m.label)
        EndTextCommandSetBlipName(blip)
    end

    local model = GetHashKey(cfg.pedModel or "s_m_y_dockwork_01")
    while true do
        local pcoords = GetEntityCoords(PlayerPedId())
        for i, m in ipairs(cfg.list or {}) do
            local dist = #(pcoords - harbourPos(m))
            local ped = harbourPeds[i]
            if dist < 80.0 and (not ped or not DoesEntityExist(ped)) then
                RequestModel(model)
                local waited = 0
                while not HasModelLoaded(model) and waited < 3000 do Wait(50) waited = waited + 50 end
                if HasModelLoaded(model) then
                    ped = CreatePed(4, model, m.harbour.x, m.harbour.y, m.harbour.z - 1.0, m.harbour.w, false, false)
                    SetEntityInvincible(ped, true)
                    SetBlockingOfNonTemporaryEvents(ped, true)
                    SetPedFleeAttributes(ped, 0, false)
                    FreezeEntityPosition(ped, true)
                    TaskStartScenarioInPlace(ped, "WORLD_HUMAN_CLIPBOARD", 0, true)
                    SetModelAsNoLongerNeeded(model)
                    harbourPeds[i] = ped
                end
            elseif dist >= 110.0 and ped then
                if DoesEntityExist(ped) then DeleteEntity(ped) end
                harbourPeds[i] = nil
            end
        end
        Wait(2000)
    end
end)

-- Interaction -------------------------------------------------------------------
CreateThread(function()
    local cfg = Config.Marinas
    if not cfg or not cfg.enabled then return end
    while true do
        local sleep = 1000
        if InSomeMenu() then -- (name is inverted: true = no menu is open)
            local pcoords = GetEntityCoords(PlayerPedId())
            for i, m in ipairs(cfg.list or {}) do
                local pos = harbourPos(m)
                if #(pcoords - pos) <= 3.0 then
                    sleep = 0
                    DrawText3D(pos.x, pos.y, pos.z + 1.0, (Lang.harbourprompt or "[E] Harbour master"):format(m.label))
                    if IsControlJustReleased(0, cfg.key or 38) then
                        TriggerServerEvent("asyacht:Global:HarbourOpen", i)
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

-- Menu --------------------------------------------------------------------------
local function act(index, yachtId, action)
    TriggerServerEvent("asyacht:Global:HarbourAction", index, yachtId, action)
end

RegisterNetEvent("asyacht:Global:HarbourData")
AddEventHandler("asyacht:Global:HarbourData", function(index, label, flags, list)
    if not (lib and lib.registerContext and lib.showContext) then
        Notify("ox_lib is required for the harbour menu.", "error")
        return
    end

    local options = {}
    if #list == 0 then
        options[1] = { title = Lang.harbournoyacht or "You do not own a yacht.", disabled = true, icon = "ship" }
    end

    for _, y in ipairs(list) do
        local subId = MENU_ID .. "_" .. y.id
        local title = (y.name ~= "" and y.name) or ("Yacht #" .. y.id)
        local bits = {}
        if y.fuel then bits[#bits + 1] = ("Fuel %d%%"):format(math.floor(y.fuel)) end
        if y.condition then bits[#bits + 1] = ("Hull %d%%"):format(math.floor(y.condition)) end
        bits[#bits + 1] = y.moored and (Lang.harbourmooredhere or "Moored here") or (Lang.harbournotmoored or "Not moored here")
        options[#options + 1] = { title = title, description = table.concat(bits, "  |  "), icon = "ship", menu = subId, arrow = true }

        local sub = {}
        if flags.upkeepEnabled and y.upkeep then
            local u = y.upkeep
            local state
            if u.status == "ok" then state = (Lang.upkeepcovered or "Covered for %s"):format(duration(u.seconds))
            elseif u.status == "due" then state = (Lang.upkeepdueshort or "Overdue - lock in %s"):format(duration((u.graceDays or 3) * 86400 - (u.seconds or 0)))
            else state = Lang.upkeeplockedshort or "Locked - unpaid" end
            sub[#sub + 1] = {
                title = (Lang.upkeepbutton or "Pay upkeep") .. " - " .. money(u.cost),
                description = state, icon = "receipt",
                onSelect = function() act(index, y.id, "upkeep") end,
            }
        end
        if flags.fuel and y.refuelprice ~= nil then
            sub[#sub + 1] = {
                title = (y.refuelprice > 0) and ((Lang.refuelbutton or "Refuel") .. " - " .. money(y.refuelprice)) or (Lang.tankfullshort or "Tank full"),
                description = y.moored and "" or (Lang.harbournotmoored or "Not moored here"),
                icon = "gas-pump", disabled = not y.moored or y.refuelprice <= 0,
                onSelect = function() act(index, y.id, "refuel") end,
            }
        end
        if flags.repair and flags.conditionEnabled and y.repairprice ~= nil then
            sub[#sub + 1] = {
                title = (y.repairprice > 0) and ((Lang.repairbutton or "Repair hull") .. " - " .. money(y.repairprice)) or (Lang.hullfineshort or "Hull in good shape"),
                description = y.moored and "" or (Lang.harbournotmoored or "Not moored here"),
                icon = "screwdriver-wrench", disabled = not y.moored or y.repairprice <= 0,
                onSelect = function() act(index, y.id, "repair") end,
            }
        end
        if #sub == 0 then sub[1] = { title = "-", disabled = true } end
        lib.registerContext({ id = subId, title = title, menu = MENU_ID, options = sub })
    end

    lib.registerContext({ id = MENU_ID, title = label, options = options })
    lib.showContext(MENU_ID)
end)

AddEventHandler("onClientResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    for _, ped in pairs(harbourPeds) do
        if ped and DoesEntityExist(ped) then DeleteEntity(ped) end
    end
end)
