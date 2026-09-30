


function Notify(message, ntype)
    ntype = ntype or "info"
    local style = Config.NotifyStyle or "nui"
    if style == "nui" then
        SendNUIMessage({ message = "toast", text = tostring(message), type = ntype })
    elseif style == "ox" and lib and lib.notify then
        lib.notify({ title = "AS Yacht", description = tostring(message), type = (ntype == "info") and "inform" or ntype })
    else
        SetNotificationTextEntry("STRING")
        AddTextComponentSubstringPlayerName(tostring(message))
        DrawNotification(false, false)
    end
end

function DrawText3D(x, y, z, text)
    local onScreen, sx, sy = World3dToScreen2d(x, y, z)
    if not onScreen then return end
    local factor = #text / 370.0
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    DrawText(sx, sy)
    DrawRect(sx, sy + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 68)
end

local _noClipEnabled = false

function ToggleNoClipFurniture(enable)
    _noClipEnabled = enable
    if enable then
        DisplayHud(false)
        DisplayRadar(false)
    else
        DisplayHud(true)
        DisplayRadar(true)
    end
    ToggleNoClipFurnitureDefault(enable)
end

function RegisterStorages(yachtiddata)
	if Config.InventorySystem == "qsinventory" then		
		for i, yachstoragehandler in pairs(Config.YachtStorageLocations) do	
			local stashID = "yacht-"..yachtiddata.."-storage-"..i..""
			local stashSlots = 50           
			local stashWeight = 1000        

			exports['qs-inventory']:RegisterStash(stashID, stashSlots, stashWeight)
		end
	end
end

function OpenYachtStorage(yachtiddata, storageiddata)
	if Config.InventorySystem == "oxinventory" then
		if Config.OxInventory == true then
			
			exports.ox_inventory:openInventory('stash', {id='yacht-'..yachtiddata..'-storage-'..storageiddata..''})
		end
	elseif Config.InventorySystem == "qsinventory" then		
		local stashID = "yacht-"..yachtiddata.."-storage-"..storageiddata..""
		local stashdata = {
			maxweight = 1000000,
			slots = 10,
		} 
		TriggerServerEvent('inventory:server:OpenInventory', 'stash', stashID, stashdata)
		TriggerEvent('inventory:client:SetCurrentStash', stashID)		
	elseif Config.InventorySystem == "qbcoreinventory" then		
		TriggerServerEvent("asyacht:Global:OpenStorageQB", "yacht-"..yachtiddata.."-storage-"..storageiddata.."")
	elseif Config.InventorySystem == "codeminventory" then		
		local name = "yacht-"..yachtiddata.."-storage-"..storageiddata..""
		local maxweight = 10000
		local slot = 50
		exports['codem-inventory']:OpenStash(name, maxweight, slot)
	elseif Config.InventorySystem == "coreinventory" then		
		local name = "yacht-"..yachtiddata.."-storage-"..storageiddata..""
		TriggerServerEvent('core_inventory:server:openInventory', name, 'stash', nil, nil)
	elseif Config.InventorySystem == "psinventory" then		
		local name = "yacht-"..yachtiddata.."-storage-"..storageiddata..""
		local stashdata = {
			maxweight = 1000000,
			slots = 30,		
		}
		TriggerServerEvent('ps-inventory:server:OpenInventory', 'stash', name, stashdata)
		TriggerEvent('ps-inventory:client:SetCurrentStash', name)
	elseif Config.InventorySystem == "chezza" then		
		local name = "yacht-"..yachtiddata.."-storage-"..storageiddata..""
		TriggerEvent('inventory:openInventory', { type = 'stash', id = name, title = 'Stash_' .. name, weight = 1000000, delay = 100, save = true })
	end
end	

function OpenYachtWardrobe(yachtiddata, wardrobeiddata)
	if Config.WardrobeSystem == "default" then
	elseif Config.WardrobeSystem == "esx" then
		  ESX.TriggerServerCallback('esx_property:getPlayerDressing', function(dressing)
			local elements = {{unselectable = true, icon = "fas fa-tshirt", title = "Wardrobe"}, {unselectable = false, icon = "", title = "Outfit 1"}, {unselectable = false, icon = "", title = "Outfit 2"}}

			for i=1, #dressing, 1 do
				elements[#elements + 1] = {
					title = dressing[i],
					value = i
				}
			end
			
			ESX.OpenContext("right", elements, function(menu, element)
				TriggerEvent('skinchanger:getSkin', function(skin)
					ESX.TriggerServerCallback('esx_property:getPlayerOutfit', function(clothes)
						TriggerEvent('skinchanger:loadClothes', skin, clothes)
						TriggerEvent('esx_skin:setLastSkin', skin)

						TriggerEvent('skinchanger:getSkin', function(skin)
							TriggerServerEvent('esx_skin:save', skin)
						end)
					end, element.value)
				end)
			end)
		end)
	elseif Config.WardrobeSystem == "qbcore" then
		TriggerEvent('qb-clothing:client:openOutfitMenu')
	elseif Config.WardrobeSystem == "codem" then
		TriggerEvent('codem-apperance:OpenWardrobe')
	elseif Config.WardrobeSystem == "fivemappearance" then
		exports['fivem-appearance']:openWardrobe()
	elseif Config.WardrobeSystem == "illeniumappearance" then
		 TriggerEvent('illenium-appearance:client:openOutfitMenu')
	 elseif Config.WardrobeSystem == "rcore" then
		 TriggerEvent('rcore_clothes:openOutfits')
	 elseif Config.WardrobeSystem == "qsappearance" then
		 TriggerEvent('clothing:openOutfitMenu')
	end
end	

TriggerEvent('chat:addSuggestion', "/"..Config.GiveYachtCommand, 'Yacht Player Give', {
    { name="Player ID", help="player id" },
    { name="Flag (1-46)", help="flag type" },
	{ name="Light Category (1-2)", help="light category" },
    { name="Light Color (1-8)", help="lig color" },
	{ name="Upper Text", help="yacht text" },
    { name="Bottom Text", help="yacht text" },
	{ name="Railing Type (1-2)", help="railing type" },
    { name="Yacht Color (1-16)", help="yacht color" },
	{ name="Equipment (1 - No, 2 - Yes)", help="equipment" }
})

TriggerEvent('chat:addSuggestion', "/"..Config.GiveYachtIdentifierCommand, 'Yacht Player Give', {
    { name="Player identifier", help="player identifier" },
    { name="Flag (1-46)", help="flag type" },
	{ name="Light Category (1-2)", help="light category" },
    { name="Light Color (1-8)", help="lig color" },
	{ name="Upper Text", help="yacht text" },
    { name="Bottom Text", help="yacht text" },
	{ name="Railing Type (1-2)", help="railing type" },
    { name="Yacht Color (1-16)", help="yacht color" },
	{ name="Equipment (1 - No, 2 - Yes)", help="equipment" }
})


RegisterNetEvent("asyacht:Global:TransferOffer")
AddEventHandler("asyacht:Global:TransferOffer", function(yachtId, fromName)
    local result = lib.alertDialog({
        header = "Yacht transfer",
        content = ("%s wants to transfer their yacht to you. Do you accept?"):format(tostring(fromName)),
        centered = true,
        cancel = true,
    })
    TriggerServerEvent("asyacht:Global:TransferResponse", result == "confirm")
end)


RegisterNetEvent("asyacht:Global:RentalOffer")
AddEventHandler("asyacht:Global:RentalOffer", function(ownerName, label, minutes, price)
    local result = lib.alertDialog({
        header = "Yacht rental",
        content = ("%s offers to rent you their yacht %s for %d minute(s) for $%s. Do you accept?"):format(
            tostring(ownerName), tostring(label), tonumber(minutes) or 0, tostring(price)),
        centered = true,
        cancel = true,
    })
    TriggerServerEvent("asyacht:Global:RentalResponse", result == "confirm")
end)

-- ─── Yacht dealer NPC (replaces the floor marker) ───────────────────────────
local dealerPed = nil

local function RemoveDealer()
    if dealerPed and DoesEntityExist(dealerPed) then
        DeleteEntity(dealerPed)
    end
    dealerPed = nil
end

local function SpawnDealer()
    local buyCfg = Config.YachtBuyLocation
    local cfg = buyCfg.npc
    local model = GetHashKey(cfg.model)

    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 5000 do
        Wait(50)
        timeout = timeout + 50
    end
    if not HasModelLoaded(model) then
        print(("^1AS Yacht^7: dealer model failed to load: %s"):format(tostring(cfg.model)))
        return
    end

    local c = buyCfg.coords
    local ped = CreatePed(4, model, c.x, c.y, c.z - 1.0, cfg.heading or 0.0, false, false)
    SetModelAsNoLongerNeeded(model)
    if not ped or ped == 0 then return end

    SetEntityAsMissionEntity(ped, true, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCanRagdoll(ped, false)
    SetPedDiesWhenInjured(ped, false)
    FreezeEntityPosition(ped, true)
    if cfg.scenario and cfg.scenario ~= "" then
        TaskStartScenarioInPlace(ped, cfg.scenario, 0, true)
    end
    dealerPed = ped
end

CreateThread(function()
    local cfg = Config.YachtBuyLocation and Config.YachtBuyLocation.npc
    if not cfg or not cfg.enabled or Config.DisableYachtBuy then return end

    while true do
        local dist = #(GetEntityCoords(PlayerPedId()) - Config.YachtBuyLocation.coords)
        local near = dist < (cfg.streamdistance or 80.0)
        if near and not (dealerPed and DoesEntityExist(dealerPed)) then
            SpawnDealer()
        elseif not near and dealerPed then
            RemoveDealer()
        end
        Wait(1500)
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then RemoveDealer() end
end)
