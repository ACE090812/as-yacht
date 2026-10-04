-- as-yacht client/blips.lua: Map blips.
-- (Split from the former client/main.lua. File-level state is global so every client module shares it.)

function CreateYachtBuyBlip()
    if hasBuyBlipCreated then return end
    hasBuyBlipCreated = true

    local blipCfg = Config.YachtBuyLocation
    local blip = AddBlipForCoord(blipCfg.coords.x, blipCfg.coords.y, blipCfg.coords.z)
    yachtBuyBlip = blip
    SetBlipSprite(blip, blipCfg.blip.blipiconid)
    SetBlipDisplay(blip, blipCfg.blip.blipdisplay)
    SetBlipScale(blip, blipCfg.blip.blipscale)
    SetBlipColour(blip, blipCfg.blip.blipcolor)
    SetBlipAsShortRange(blip, blipCfg.blip.blipshortrange)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(blipCfg.blip.bliptext)
    EndTextCommandSetBlipName(blip)
end

function YachtBlipLabel(yachtId)
    local cfg = Config.YachtBuyLocation.personalblip
    local y = yachts["yacht-" .. yachtId]
    if cfg.showyachtname and y and y.textdata and (y.textdata.uppertext or "") ~= "" then
        local name = ((y.textdata.uppertext or "") .. " " .. (y.textdata.bottomtext or "")):gsub("%s+$", "")
        return cfg.bliptext .. ": " .. name
    end
    return cfg.bliptext
end

function RefreshYachtBlipName(yachtId)
    local blip = yachtBlips[yachtId]
    if blip and DoesBlipExist(blip) then
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(YachtBlipLabel(yachtId))
        EndTextCommandSetBlipName(blip)
    end
end

function CreatePersonalYachtBlip(yachtId)
    local personalBlipCfg = Config.YachtBuyLocation.personalblip
    local key = "yacht-" .. yachtId

    if yachtBlips[yachtId] ~= nil then
        if not DoesBlipExist(yachtBlips[yachtId]) then
            local blip = AddBlipForEntity(yachts[key].yachtmainobject)
            yachtBlips[yachtId] = blip
            SetBlipSprite(blip, personalBlipCfg.blipiconid)
            SetBlipDisplay(blip, personalBlipCfg.blipdisplay)
            SetBlipScale(blip, personalBlipCfg.blipscale)
            SetBlipColour(blip, personalBlipCfg.blipcolor)
            SetBlipAsShortRange(blip, personalBlipCfg.blipshortrange)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName(YachtBlipLabel(yachtId))
            EndTextCommandSetBlipName(blip)
        end
    end

    if yachtBlips[yachtId] == nil then
        local blip = AddBlipForEntity(yachts[key].yachtmainobject)
        yachtBlips[yachtId] = blip
        SetBlipSprite(blip, personalBlipCfg.blipiconid)
        SetBlipDisplay(blip, personalBlipCfg.blipdisplay)
        SetBlipScale(blip, personalBlipCfg.blipscale)
        SetBlipColour(blip, personalBlipCfg.blipcolor)
        SetBlipAsShortRange(blip, personalBlipCfg.blipshortrange)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(YachtBlipLabel(yachtId))
        EndTextCommandSetBlipName(blip)
    end
end

function RemovePersonalYachtBlip(yachtId)
    if yachtBlips[yachtId] ~= nil then
        RemoveBlip(yachtBlips[yachtId])
        yachtBlips[yachtId] = nil
    end
end
