


function AddMoneyYacht(playersource, moneydata)
	if Config.Framework == "esx" then
		local xPlayer = ESX.GetPlayerFromId(playersource)
		if xPlayer then
			xPlayer.addMoney(moneydata)
		end
	elseif Config.Framework == "qbcore" then
		local xPlayer = QBCore.Functions.GetPlayer(playersource)
		if xPlayer then	
			xPlayer.Functions.AddMoney('cash', moneydata)
		end
	elseif Config.Framework == "standalone" then
		
	end
end	

function RemoveMoneyYacht(playersource, moneydata, account)
	account = account or "cash"
	if Config.Framework == "esx" then
		local xPlayer = ESX.GetPlayerFromId(playersource)
		if xPlayer then
			if account == "bank" then
				xPlayer.removeAccountMoney('bank', moneydata)
			else
				xPlayer.removeMoney(moneydata)
			end
		end
	elseif Config.Framework == "qbcore" then
		local xPlayer = QBCore.Functions.GetPlayer(playersource)
		if xPlayer then	
			xPlayer.Functions.RemoveMoney(account, moneydata)	
		end
	elseif Config.Framework == "standalone" then
		
	end
end	

function GetMoneyYacht(playersource, account)
	account = account or "cash"
	local moneydata = 0
	if Config.Framework == "esx" then
		local xPlayer = ESX.GetPlayerFromId(playersource)
		if xPlayer then
			if account == "bank" then
				local acc = xPlayer.getAccount('bank')
				moneydata = acc and acc.money or 0
			else
				moneydata = xPlayer.getMoney()
			end
		end
	elseif Config.Framework == "qbcore" then
		local xPlayer = QBCore.Functions.GetPlayer(playersource)
		if xPlayer then	
			moneydata = xPlayer.Functions.GetMoney(account)
		end
	elseif Config.Framework == "standalone" then
		moneydata = 99999999999
		
	end
	return moneydata
end	

function GetPlayerIdentifierYacht(playersource)
	local playeridentifierdata = ""
	if Config.Framework == "esx" then
		local xPlayer = ESX.GetPlayerFromId(playersource)
		if xPlayer then
			playeridentifierdata = xPlayer.identifier
		else
			playeridentifierdata = GetPlayerIdentifiers(playersource)[1]	
		end
	elseif Config.Framework == "qbcore" then
		local xPlayer = QBCore.Functions.GetPlayer(playersource)
		if xPlayer then	
			playeridentifierdata = xPlayer.PlayerData.citizenid
		end
	elseif Config.Framework == "standalone" then
		playeridentifierdata = GetPlayerIdentifiers(playersource)[1]	
	end
	return playeridentifierdata
end

function GetPlayerNameYacht(playersource)
	return GetPlayerName(playersource)
end

function CheckYachtGivePermission(playersource)
	local permission = false
	if Config.Framework == "esx" then
		local xPlayer = ESX.GetPlayerFromId(playersource)
		local playergroup = xPlayer and xPlayer.getGroup() or nil
		if playergroup == "admin" or playergroup == "superadmin" then
			permission = true
		end
	elseif Config.Framework == "qbcore" then
		if QBCore.Functions.HasPermission(playersource, 'admin') or QBCore.Functions.HasPermission(playersource, 'god') then
			permission = true
		end
	elseif Config.Framework == "standalone" then
		
	end	
	return permission
end

local function WaitForResourceStarted(resourceName, timeoutMs)
	local waited = 0
	while GetResourceState(resourceName) ~= "started" and waited < timeoutMs do
		Citizen.Wait(500)
		waited = waited + 500
	end
	return GetResourceState(resourceName) == "started"
end

function RegisterStorages(yachtiddata)
	if Config.InventorySystem == "oxinventory" then
		if Config.OxInventory == true then
			if not WaitForResourceStarted("ox_inventory", 30000) then
				print("[as-yacht] WARNING: ox_inventory did not start within 30s -- yacht "..tostring(yachtiddata).."'s storage stashes were not registered. Restart as-yacht once ox_inventory is running.")
				return
			end
			for i, yachstoragehandler in pairs(Config.YachtStorageLocations) do	
				local y = yachts["yacht-" .. yachtiddata]
				local tier = Config.Upgrades and Config.Upgrades.storage and y and Config.Upgrades.storage[y.extras and y.extras.storagetier or 1]
				local stash = {
					id = 'yacht-'..yachtiddata..'-storage-'..i..'',
					label = 'Yacht Storage - '..i..'',
					slots = tier and tier.slots or 50,
					weight = tier and tier.weight or 100000,
					owner = nil, 
				}	
				exports.ox_inventory:RegisterStash(stash.id, stash.label, stash.slots, stash.weight, stash.owner)
			end	
		end
	elseif Config.InventorySystem == "qbcoreinventory" then		
		if not QBStorageEventRegistered then -- register once, not once per yacht
			QBStorageEventRegistered = true
			RegisterServerEvent("asyacht:Global:OpenStorageQB", function(storagenamedata)
				local playersource = source
				local data = { label = storagenamedata, maxweight = 400000, slots = 500 }
				local id = tonumber(tostring(storagenamedata):match("^yacht%-(%d+)%-"))
				local y = id and yachts["yacht-" .. id]
				local tier = y and Config.Upgrades and Config.Upgrades.storage and Config.Upgrades.storage[y.extras and y.extras.storagetier or 1]
				if tier then data.maxweight, data.slots = tier.weight * 4, tier.slots * 10 end
				exports['qb-inventory']:OpenInventory(playersource, storagenamedata, data)
			end)
		end
	end	
end
