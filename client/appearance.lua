-- as-yacht client/appearance.lua: Yacht appearance data, name rendering and misc helpers.
-- (Split from the former client/main.lua. File-level state is global so every client module shares it.)

function GetLightColorObject(category, colorId)
    local defaultObject = "as_apa_mp_apa_y3_l2a"

    if category == 1 then
        local l2Options = {
            {lightobject = "as_apa_mp_apa_y3_l2a"},
            {lightobject = "as_apa_mp_apa_y3_l2b"},
            {lightobject = "as_apa_mp_apa_y3_l2c"},
            {lightobject = "as_apa_mp_apa_y3_l2d"},
            {lightobject = "as_apa_mp_apa_y3_l2p"},
            {lightobject = "as_apa_mp_apa_y3_l2r"},
            {lightobject = "as_apa_mp_apa_y3_l2o"},
            {lightobject = "as_apa_mp_apa_y3_l2w"},
        }
        local opt = l2Options[colorId]
        return opt and opt.lightobject or defaultObject
    elseif category == 2 then
        local l1Options = {
            {lightobject = "as_apa_mp_apa_y3_l1a"},
            {lightobject = "as_apa_mp_apa_y3_l1b"},
            {lightobject = "as_apa_mp_apa_y3_l1c"},
            {lightobject = "as_apa_mp_apa_y3_l1d"},
            {lightobject = "as_apa_mp_apa_y3_l1p"},
            {lightobject = "as_apa_mp_apa_y3_l1r"},
            {lightobject = "as_apa_mp_apa_y3_l1o"},
            {lightobject = "as_apa_mp_apa_y3_l1w"},
        }
        local opt = l1Options[colorId]
        return opt and opt.lightobject or defaultObject
    end

    return defaultObject
end

-- GTA colour ID used to tint the railing for a given railing type
function GetRailingColour(railingId)
    local r = Config.RailingTypes[railingId] or Config.RailingTypes[1]
    return r.colour
end

yachtNameRenderState = {
    renderdata = {-1, -1, -1},  
    moviedata  = -1,
    generated  = 0,             
    yachtid    = 1,
    upper      = nil,
    bottom     = nil,
}

-- Releases the render targets + movie so the next yacht/preview relinks cleanly
function ResetYachtName()
    local s = yachtNameRenderState
    if s.moviedata ~= -1 then
        SetScaleformMovieAsNoLongerNeeded(s.moviedata)
    end
    for _, name in ipairs({"stern_text", "starb_text", "port_text"}) do
        if IsNamedRendertargetRegistered(name) then ReleaseNamedRendertarget(name) end
    end
    s.renderdata = {-1, -1, -1}
    s.moviedata  = -1
    s.generated  = 0
    s.yachtid    = -1
    s.upper      = nil
    s.bottom     = nil
end

function PushYachtName(upperText, bottomText)
    local s = yachtNameRenderState
    SetupScaleform(s.moviedata, "SET_YACHT_NAME", {
        p0 = {type = "string", value = tostring(upperText or "")},
        p1 = {type = "int",    value = 1},
        p2 = {type = "string", value = tostring(bottomText or "")},
    })
    s.upper, s.bottom = upperText, bottomText
end

function DrawYachtName(upperText, bottomText, targetYachtId)
    if yachtNameRenderState.yachtid == targetYachtId then

        if yachtNameRenderState.generated == 0 then
            local rd = yachtNameRenderState.renderdata
            rd[1] = CreateNamedRenderTargetForModel("stern_text",  GetHashKey("apa_prop_ap_stern_text"))
            rd[2] = CreateNamedRenderTargetForModel("starb_text",  GetHashKey("apa_prop_ap_starb_text"))
            rd[3] = CreateNamedRenderTargetForModel("port_text",   GetHashKey("apa_prop_ap_port_text"))
            yachtNameRenderState.moviedata  = RequestScaleformMovie("YACHT_NAME")
            yachtNameRenderState.generated  = 1

        elseif yachtNameRenderState.generated == 1 then
            if HasScaleformMovieLoaded(yachtNameRenderState.moviedata) then
                PushYachtName(upperText, bottomText)
                yachtNameRenderState.generated = 2
            else
                
                yachtNameRenderState.moviedata = RequestScaleformMovie("YACHT_NAME")
            end

        elseif yachtNameRenderState.generated == 2 then
            -- text changed (typed in the buy menu, or yacht data updated) -> re-send it
            if yachtNameRenderState.upper ~= upperText or yachtNameRenderState.bottom ~= bottomText then
                PushYachtName(upperText, bottomText)
            end
            for _, renderId in ipairs(yachtNameRenderState.renderdata) do
                SetTextRenderId(renderId)
                SetUiLayer(4)
                N_0xc6372ecd45d73bcd(true)
                ScreenDrawPositionBegin(73, 73)
                DrawScaleformMovie(
                    yachtNameRenderState.moviedata,
                    0.38, 0.245, 1.0, 1.0,
                    255, 255, 255, 255, 0
                )
                SetTextRenderId(GetDefaultScriptRendertargetRenderId())
                ScreenDrawPositionEnd()
            end
        end
    else
        
        yachtNameRenderState.renderdata = {-1, -1, -1}
        yachtNameRenderState.moviedata  = -1
        yachtNameRenderState.generated  = 0
        yachtNameRenderState.yachtid    = targetYachtId
    end
end

function CreateNamedRenderTargetForModel(name, modelHash)
    local renderId = 0
    if not IsNamedRendertargetRegistered(name) then
        RegisterNamedRendertarget(name, false)
    end
    if not IsNamedRendertargetLinked(modelHash) then
        LinkNamedRendertarget(modelHash)
    end
    if IsNamedRendertargetRegistered(name) then
        renderId = GetNamedRendertargetRenderId(name)
    end
    return renderId
end

function SetupScaleform(movieHandle, methodName, params)
    BeginScaleformMovieMethod(movieHandle, methodName)
    if IsTable(params) then
        for i = 0, Tablelength(params) - 1 do
            local key   = "p" .. tostring(i)
            local entry = params[key]
            if     entry.type == "bool"       then PushScaleformMovieMethodParameterBool(entry.value)
            elseif entry.type == "int"        then PushScaleformMovieMethodParameterInt(entry.value)
            elseif entry.type == "float"      then PushScaleformMovieMethodParameterFloat(entry.value)
            elseif entry.type == "string"     then PushScaleformMovieMethodParameterString(entry.value)
            elseif entry.type == "buttonName" then PushScaleformMovieMethodParameterButtonName(entry.value)
            end
        end
    end
    EndScaleformMovieMethod()
    N_0x32f34ff7f617643b(movieHandle, 1)
end

function IsTable(value)
    return type(value) == "table"
end

function Tablelength(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

function CheckIfFurnitureIsInYachtNearby(yachtId, worldPos)
    local rawCoords = GlobalState["asyacht-" .. yachtId .. "-coords"]
    if not rawCoords then return false end
    local yachtCoords = vector3(rawCoords.x, rawCoords.y, rawCoords.z)
    local dist = #(worldPos - yachtCoords)
    return dist < 70.0
end

function GetRotationOffsetBetweenEntities(entity1, entity2)
    local rot1 = GetEntityRotation(entity1, 2)
    local rot2 = GetEntityRotation(entity2, 2)
    return vector3(
        rot2.x - rot1.x,
        rot2.y - rot1.y,
        rot2.z - rot1.z
    )
end


function ShowGtaClassicInteraction(text)
    AddTextEntry("gtavclassicinteractionasyacht", text)
    BeginTextCommandDisplayHelp("gtavclassicinteractionasyacht")
    EndTextCommandDisplayHelp(0, false, true, -1)
end
