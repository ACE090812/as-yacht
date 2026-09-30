Config = {}

-- ═══════════════════════════════════════════════════════════════════════════
--  1. FRAMEWORK & INTEGRATIONS
--  Which framework, inventory, target and wardrobe scripts to hook into.
-- ═══════════════════════════════════════════════════════════════════════════

-- Framework: "esx" | "qbcore" | "standalone"
Config.Framework = "qbcore"

Config.ESXFramework = {
	newversion = false,
	getsharedobject = "esx:getSharedObject",
	resourcename = "es_extended"
}

Config.PlayerLoadedEvent = {
	esx = "esx:onPlayerSpawn",
	qbcore = "QBCore:Client:OnPlayerLoaded",
	standalone = "playerLoaded",
}

Config.QBCoreFrameworkResourceName = "qb-core"

-- true = use ox_inventory stashes for storage rooms
Config.OxInventory = true

-- "oxinventory" | "qbinventory" | "qsinventory" | ...
Config.InventorySystem = "oxinventory"

-- Wardrobe script used by the wardrobes on board
Config.WardrobeSystem = "illeniumappearance"

-- true = use a target system instead of key prompts
Config.Target = false

Config.Targettype = "oxtarget" -- "qtarget" | "qbtarget" | "oxtarget" | "astarget" (as-interact)

Config.TargetSystemsNames = {qtarget = "qtarget", qbtarget = "qb-target", oxtarget = "ox_target", astarget = "as-interact"}

-- Language name from language/main.lua and language/translations.lua ("English", "Spanish", "French", "German")
Config.Language = "English"

-- Accent colour of the menus
Config.InterfaceColor = "#38bdf8"

-- How notifications are shown: "nui" (glass toast), "ox" (ox_lib) or "native" (GTA feed)
Config.NotifyStyle = "nui"


-- ═══════════════════════════════════════════════════════════════════════════
--  2. CONTROLS & INTERACTION
--  Keys and distances for everything you can do on the yacht.
-- ═══════════════════════════════════════════════════════════════════════════

-- 1 = 3D text + key press
Config.YachtInteractionSystem = 1

-- Key to enter / leave the yacht
Config.YachtEnterExitKey = "F"

-- Key to open and close doors
Config.YachtOpenCloseDoorKey = "E"

-- Key to open storage rooms
Config.YachtStorageKey = "E"

-- Key to open wardrobes
Config.YachtWardrobeKey = "E"

-- Key to open the management menu
Config.YachtManagmentKey = "E"

-- Key to start driving at the helm
Config.YachtDriveKey = "E"

-- Key to sit in the hot tub
Config.HotTubSitKey = "E"

-- How close you must be to a door to use it
Config.YachtDoorDistance = 2.5

-- How close you must be to a hot tub seat
Config.HottubSeatDistance = 2.5

Config.YachtServerInteractDistance = 250.0 -- max server-side distance from the yacht for drive/storage/wardrobe/hottub actions


-- ═══════════════════════════════════════════════════════════════════════════
--  3. FEATURE SWITCHES & RULES
--  Turn whole features on or off and set the basic rules.
-- ═══════════════════════════════════════════════════════════════════════════

-- true = nobody can buy a yacht
Config.DisableYachtBuy = false

-- true = yachts cannot be sailed
Config.DisableYachtDrive = false

-- true = yachts cannot be sold
Config.DisableYachtSell = false

-- true = yachts cannot be transferred to other players
Config.DisableYachtTransfer = false

-- true = furniture shop and decorating are turned off
Config.DisableYachtFurniture = false

Config.OneYachtPerPlayer = true -- block buying a second yacht

Config.TransferRequiresConsent = true -- receiving player must accept a yacht transfer

Config.FurnitureRefundPercentage = 50 -- % of purchased furniture value refunded when a yacht is sold (0 = off, free starter equipment is never refunded)

-- true = players on the yacht cannot ragdoll (stops falling over while it moves)
Config.YachtNoRagdoll = true

-- true = flatten the waves around yachts
Config.CalmWater = false

-- false = the driver sails the yacht client-side (smoother); true = server-owned entity
Config.ServerNetworkYacht = false

-- Distance (m) at which yachts stay visible
Config.YachtDisplayMaxDistance = 5000.0


-- ═══════════════════════════════════════════════════════════════════════════
--  4. COMMANDS, ADMIN & LOGGING
-- ═══════════════════════════════════════════════════════════════════════════

-- Admin command: give a yacht to a player id
Config.GiveYachtCommand = "giveyacht"

-- Admin command: give a yacht to an identifier (works for offline players)
Config.GiveYachtIdentifierCommand = "giveyachtidentifier"

Config.AdminCommands = { list = "yachtlist", teleport = "yachtgoto", delete = "yachtdelete" } -- admins only (group admin/god, ACE asyacht.admin, or console)

Config.Logging = {
	enabled = false,
	console = true, -- also print log lines to the server console
	webhook = "", -- Discord webhook URL
	botname = "AS Yacht",
}


-- ═══════════════════════════════════════════════════════════════════════════
--  5. YACHT STORE
--  The dealer, prices and everything shown in the buy menu.
-- ═══════════════════════════════════════════════════════════════════════════

Config.YachtBuyLocation = {
	coords = vector3(-816.31, -1345.09, 5.15),
	openkey = "E",
	distance = 2.0,
	yachtpreviewlocation = vector3(-2699.88, -1636.59, -4.0),
	npc = {
		enabled = true, -- yacht dealer ped stands at the buy location
		model = "a_m_m_business_01",
		heading = 90.0, -- which way the dealer faces
		scenario = "WORLD_HUMAN_STAND_IMPATIENT", -- "" for none
		streamdistance = 80.0,
	},
	blip = {
		enabled = true,
		blipiconid = 410,
		blipdisplay = 4,
		blipcolor = 3,
		blipshortrange = false,
		blipscale = 0.7,
		bliptext = "Yacht Store",
	},
	personalblip = {
		enabled = true,
		blipiconid = 455,
		blipdisplay = 4,
		blipcolor = 4,
		blipshortrange = true,
		blipscale = 0.7,
		bliptext = "My Yacht",
		showyachtname = true, -- append the yacht's name to the blip label ("My Yacht: ACE BOAT")
	},
	yachtbuycameras = {
		{coords = vector3(-2751.1105835367, -1549.4184204508, 23.771157836914), rotation = vector3(-8.6929132938385, 0.0, -156.09448814392), cameraspeed = 5000},
		{coords = vector3(-2610.9483413384, -1637.6996322944, 14.17112197876), rotation = vector3(-3.5275589823723, 0.0, -261.85826721787), cameraspeed = 10000},
		{coords = vector3(-2620.7402871326, -1671.9213583753, 4.8711012840271), rotation = vector3(1.5748032033443, 0.0, -297.95275524259), cameraspeed = 5000},
		{coords = vector3(-2649.9093502561, -1706.1173824827, 15.371125793457), rotation = vector3(-7.0551180243492, 0.0, -331.14960551262), cameraspeed = 5000},
		{coords = vector3(-2797.1578407018, -1636.6877647669, 15.371125793457), rotation = vector3(-1.7007873356342, 0.0, -79.811022341251), cameraspeed = 10000},
		{coords = vector3(-2784.8701561575, -1587.3008399362, 27.471171951294), rotation = vector3(-14.110236108303, 0.0, -119.6220458746), cameraspeed = 5000},
    },
}

Config.YachtPriceSettings = {
	yachtprice = 1500000,
	redemptionpercentage = 0,
	yachtlightingprice = {
		[1] = 25000,
		[2] = 15000,
	},
	yachtequipmentprice = {
		[1] = 0,
		[2] = 50000,
	},
}

-- ─── Buy menu ──────────────────────────────────────────────────────────────
Config.Payment = {
	methods = {"cash", "bank"}, -- accounts the buyer can choose between
	default = "cash",
}

Config.NameRules = {
	minLength = 1,
	maxLength = 24,
	unique = true, -- two yachts cannot share the same upper + bottom text
	blockedWords = {"admin", "staff", "police"}, -- case-insensitive, matched anywhere in the text
}

-- Railing colours. colour = GTA vehicle colour ID used to tint the railing,
-- swatch = colour(s) shown in the menu. Add/remove/reorder freely (IDs are the list positions, 1 = default).
-- Changing the order changes which railing existing yachts have, so only append to an in-use server.
Config.RailingTypes = {
	[1] = {label = "Silver", colour = 5,   price = 25000, swatch = {"#9fb3c4", "#e6eef5"}},
	[2] = {label = "Gold",   colour = 37,  price = 75000, swatch = {"#b98a2c", "#f3d27a"}},
	[3] = {label = "Black",  colour = 0,   price = 30000, swatch = {"#1a1d21", "#4a515a"}},
	[4] = {label = "Chrome", colour = 120, price = 45000, swatch = {"#c9d2da", "#ffffff"}},
	[5] = {label = "Red",    colour = 27,  price = 35000, swatch = {"#8f1420", "#e0354a"}},
	[6] = {label = "Blue",   colour = 64,  price = 35000, swatch = {"#14407a", "#3d8bf0"}},
}

Config.YachColors = {
    [1]  = {primary = 64,  secondary = 112, interior = 112, overlay = 0},
    [2]  = {primary = 64,  secondary = 64,  interior = 112, overlay = 2},
    [3]  = {primary = 51,  secondary = 112, interior = 112, overlay = 10},
    [4]  = {primary = 150, secondary = 112, interior = 112, overlay = 14},
    [5]  = {primary = 4,   secondary = 112, interior = 112, overlay = 13},
    [6]  = {primary = 64,  secondary = 64,  interior = 112, overlay = 1},
    [7]  = {primary = 0,   secondary = 0,   interior = 112, overlay = 6},
    [8]  = {primary = 150, secondary = 150, interior = 112, overlay = 11},
    [9]  = {primary = 99,  secondary = 112, interior = 111, overlay = 8},
    [10] = {primary = 112, secondary = 64,  interior = 112, overlay = 12},
    [11] = {primary = 112, secondary = 3,   interior = 112, overlay = 3},
    [12] = {primary = 89,  secondary = 112, interior = 112, overlay = 4},
    [13] = {primary = 135, secondary = 112, interior = 112, overlay = 9},
    [14] = {primary = 0,   secondary = 112, interior = 0,   overlay = 7},
    [15] = {primary = 30,  secondary = 66,  interior = 66,  overlay = 5},
    [16] = {primary = 66,  secondary = 37,  interior = 66,  overlay = 15},
}

-- Preview options shown in the buy menu (client-side only, does not change the world for others)
Config.BuyPreview = {
	times = { {label = "Dawn", hour = 6}, {label = "Day", hour = 12}, {label = "Dusk", hour = 19}, {label = "Night", hour = 23} },
	weathers = { {label = "Clear", type = "CLEAR"}, {label = "Overcast", type = "OVERCAST"}, {label = "Rain", type = "RAIN"}, {label = "Fog", type = "FOGGY"} },
	sounds = true, -- click / success / error sounds in the UI
}

-- Camera presets, offsets are relative to the preview yacht (x = right, y = forward, z = up)
Config.BuyCameraPresets = {
	{label = "Stern",     offset = vector3(0.0, -80.0, 20.0)},
	{label = "Bow",       offset = vector3(0.0, 80.0, 20.0)},
	{label = "Port",      offset = vector3(-75.0, 0.0, 14.0)},
	{label = "Starboard", offset = vector3(75.0, 0.0, 14.0)},
	{label = "Top",       offset = vector3(0.0, -12.0, 100.0)},
}

-- Buy menu "Tour" button: seconds spent on each camera preset
Config.BuyTourSeconds = 4


-- ═══════════════════════════════════════════════════════════════════════════
--  6. YACHT WORLD
--  Where yachts anchor and where things are placed on board.
-- ═══════════════════════════════════════════════════════════════════════════

Config.YachtSpawnLocations = {
    {coords = vector3(-2161.122314, -2153.391357, -4.0), rotation = vector3(-0.096552, 0.130122, 33.667583)},
    {coords = vector3(-1907.472168, -1893.615112, -4.0), rotation = vector3(-0.028517, 0.147471, 24.793594)},
    {coords = vector3(-2410.845947, -1708.264160, -4.0), rotation = vector3(-0.182983, 0.084275, 69.863152)},
    {coords = vector3(-2673.783936, -1829.221436, -4.0), rotation = vector3(-0.157319, -0.056657, 63.908047)},
    {coords = vector3(-2723.676514, -2265.419922, -4.0), rotation = vector3(0.041670, 0.018722, -173.124634)},
    {coords = vector3(-2715.398438, -1710.015869, -4.0), rotation = vector3(-0.026554, 0.101541, -26.140566)},
    {coords = vector3(-3547.398438, -1900.015869, -4.0), rotation = vector3(-0.026554, 0.101541, -26.140566)},
    {coords = vector3(-2907.864990, -1622.784058, -4.0), rotation = vector3(0.123583, 0.120111, 69.809982)},
    {coords = vector3(-2919.222, -858.98, 9.702), rotation = vector3(-14.110236108303, 0.0, -119.6220458746)},
	{coords = vector3(-3263.804, -434.078, 10.73), rotation = vector3(-14.110236108303, 0.0, -119.6220458746)},
	{coords = vector3(-3723.947, 317.865, 5.482), rotation = vector3(-14.110236108303, 0.0, -119.6220458746)},
	{coords = vector3(-3829.041, 870.294, 11.393), rotation = vector3(-14.110236108303, 0.0, -119.6220458746)},
	{coords = vector3(-3930.36, 1482.444, 15.656), rotation = vector3(-14.110236108303, 0.0, -119.6220458746)},
	{coords = vector3(-4000.319, 2325.388, 12.572), rotation = vector3(-14.110236108303, 0.0, -119.6220458746)},
	{coords = vector3(-2758.187, 6364.05, 8.044), rotation = vector3(-14.110236108303, 0.0, -119.6220458746)},
	{coords = vector3(-2127.426, 6839.618, 7.833), rotation = vector3(-14.110236108303, 0.0, -119.6220458746)},
	{coords = vector3(-1254.571, 7050.035, 8.864), rotation = vector3(-14.110236108303, 0.0, -119.6220458746)},
	{coords = vector3(869.532, 7160.36, 14.912), rotation = vector3(-14.110236108303, 0.0, -119.6220458746)},
	{coords = vector3(1285.401, 7021.067, 13.681), rotation = vector3(-14.110236108303, 0.0, -119.6220458746)},
	{coords = vector3(1953.159, 7077.557, 14.281), rotation = vector3(-14.110236108303, 0.0, -119.6220458746)},
	{coords = vector3(2901.002, 7039.069, 6.757), rotation = vector3(-14.110236108303, 0.0, -119.6220458746)},
	{coords = vector3(3935.237, 6111.267, 7.945), rotation = vector3(-14.110236108303, 0.0, -119.6220458746)},
	{coords = vector3(4701.55, 4458.369, 6.222), rotation = vector3(-14.110236108303, 0.0, -119.6220458746)},
	{coords = vector3(5225.802, 3126.488, 3.69), rotation = vector3(-14.110236108303, 0.0, -119.6220458746)},
	{coords = vector3(4821.342, 1723.76, 10.016), rotation = vector3(-14.110236108303, 0.0, -119.6220458746)}
}

-- Where a yacht may be anchored
Config.AnchorRules = {
	minDistance = 90.0, -- metres to the nearest other yacht (0 = off)
	blockedZones = {    -- e.g. {coords = vector3(x, y, z), radius = 150.0}
	},
}

-- ─── Stability ─────────────────────────────────────────────────────────────
-- While a yacht is sailing its position is saved regularly, so a crash or restart
-- puts it back near where it was instead of at its last anchor point.
Config.Autosave = {
	enabled = true,
	interval = 30, -- seconds between saves of sailing yachts
}

-- Number of doors on the yacht model (do not change)
Config.YachtDoorCount = 41

-- Number of hot tub seats on the yacht model (do not change)
Config.YachtHottubSeatCount = 11

Config.YachtStorageLocations = {
	[1] = {coords = vector3(3.592150, 7.750217, 6.35475), distance = 2.5},
	[2] = {coords = vector3(-0.720738, 12.267517, 6.354536), distance = 2.5},
}

Config.YachtWardrobeLocations = {
	[1] = {coords = vector3(3.054163, 22.447800, 6.354722), distance = 2.5},
	[2] = {coords = vector3(3.965877, 16.665924, 6.3545484), distance = 2.5},
}

Config.YachtDriveLocation = {coords = vector3(-0.126549, 14.307654, 13.206366), distance = 2.5}

Config.YachtManageLocation = {coords = vector3(5.955555, 13.520107, 6.354536), distance = 2.5}


-- ═══════════════════════════════════════════════════════════════════════════
--  7. UPGRADES & ECONOMY
--  Paid upgrades, fuel, marina fees, insurance and rentals (Manage menu > Upgrades).
-- ═══════════════════════════════════════════════════════════════════════════

-- ─── Paid upgrades (Manage menu > Upgrades) ─────────────────────────────────
Config.Upgrades = {
	enabled = true,
	renamePrice = 50000,      -- change the yacht's name
	appearancePrice = 75000,  -- one charge for changing hull colour, railing, flag or lights
	engine = {                -- power/torque are multipliers applied while driving
		[1] = {label = "Standard", price = 0,      power = 1.0, torque = 1.0, fuelUse = 1.0},
		[2] = {label = "Sport",    price = 250000, power = 1.4, torque = 1.4, fuelUse = 1.25},
		[3] = {label = "Luxury",   price = 600000, power = 1.8, torque = 1.8, fuelUse = 1.5},
	},
	storage = {               -- weight in grams (ox_inventory) / slots per storage room
		[1] = {label = "Standard", price = 0,      slots = 50,  weight = 100000},
		[2] = {label = "Large",    price = 150000, slots = 100, weight = 250000},
		[3] = {label = "Cargo",    price = 400000, slots = 150, weight = 500000},
	},
}

-- ─── Economy ───────────────────────────────────────────────────────────────
-- Fuel is used while sailing (distance based) and refilled from the Upgrades screen.
Config.Fuel = {
	enabled = true,
	startFuel = 100.0,       -- % in a new yacht's tank
	usagePerKm = 1.5,        -- % of the tank used per kilometre (multiplied by the engine tier's fuelUse)
	idleUsagePerMin = 0.1,   -- % per minute while the engine is running
	pricePerPercent = 400,   -- cost of refilling 1%
	lowFuelWarning = 15.0,   -- warn the driver below this %
	requireStation = false,  -- true = refuelling only works next to a station below
	stations = {             -- {coords = vector3(x, y, z), radius = 150.0}
	},
}

-- Fee for anchoring inside a marina (charged to whoever anchors; anchoring is refused if they cannot pay).
Config.Docking = {
	enabled = false,
	zones = {
		-- {label = "Vespucci Marina", coords = vector3(-860.0, -1420.0, 0.0), radius = 120.0, fee = 25000},
	},
}

-- Insurance and recovery: /yachtrecover moves a stuck or lost yacht to a free anchorage.
Config.Insurance = {
	enabled = true,
	price = 100000,            -- one-off cost of insuring a yacht
	recoveryFee = 150000,      -- recovery fee without insurance
	insuredRecoveryFee = 10000,-- recovery fee with insurance
	cooldownMinutes = 10,
	clearRadius = 70.0,        -- nobody may be within this distance of the yacht (they would be left behind)
	command = "yachtrecover",
}

-- Renting your yacht to another player for a limited time (Upgrades screen).
Config.Rental = {
	enabled = true,
	maxMinutes = 240,
	maxPrice = 500000,
	offerTimeout = 30,         -- seconds the other player has to answer
	grant = {                  -- access the renter gets
		yachtcontrol = true, dooraccess = true, furnituremanagment = false, storageaccess = false, wardrobeaccess = false,
	},
}


-- ═══════════════════════════════════════════════════════════════════════════
--  8. COMFORT & EXTRAS
--  Furniture layouts, light schedule, radio, hull lights and the boats / jet skis / helicopters.
-- ═══════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
--  Comfort & style extras (Upgrades menu)
-- ═══════════════════════════════════════════════════════════════════════════
Config.Comfort = {
	enabled = true,

	-- Saved furniture layouts: a snapshot of where every piece sits. Loading one moves the
	-- pieces the yacht already owns (matched by model); it never buys or refunds anything.
	layouts = { enabled = true, max = 3 },

	-- Day / night lighting: the light prop is shown always, only at night, or never.
	lightModes = {
		{ id = "on",   label = "Always on" },
		{ id = "auto", label = "Night only" },
		{ id = "off",  label = "Off" },
	},
	nightStart = 19, nightEnd = 6,      -- in-game hours

	-- Onboard radio. Played locally for players who are standing on the yacht (native radio stations).
	ambience = {
		enabled = true, price = 15000, radius = 50.0,
		stations = {
			{ id = "RADIO_02_POP",          label = "Los Santos Radio - Pop" },
			{ id = "RADIO_13_JAZZ",         label = "Jazz" },
			{ id = "RADIO_09_HIPHOP_OLD",   label = "Old school hip hop" },
			{ id = "RADIO_22_DLC_BATTLE_MIX1_RADIO", label = "Lounge mix" },
		},
	},

	-- Glowing hull lights. Drawn as dynamic lights, so keep the point list short.
	hullLights = {
		enabled = true, price = 40000,
		range = 14.0, intensity = 4.0, drawDistance = 160.0,
		-- offsets relative to the yacht origin. CHECK THESE IN GAME and adjust to your yacht model.
		points = {
			vector3( 9.0, -40.0, 1.5), vector3(-9.0, -40.0, 1.5),
			vector3( 9.0, -10.0, 1.5), vector3(-9.0, -10.0, 1.5),
			vector3( 9.0,  20.0, 1.5), vector3(-9.0,  20.0, 1.5),
		},
		colors = {
			{ id = 1, label = "Ice blue", rgb = {60, 160, 255} },
			{ id = 2, label = "Teal",     rgb = {20, 220, 190} },
			{ id = 3, label = "Purple",   rgb = {160, 70, 255} },
			{ id = 4, label = "Pink",     rgb = {255, 70, 170} },
			{ id = 5, label = "Amber",    rgb = {255, 170, 40} },
			{ id = 6, label = "White",    rgb = {255, 255, 255} },
		},
	},

	-- Tenders & toys: boats, jet skis and helicopters that appear next to the yacht when called.
	-- Each option can override spawnOffset (relative to the yacht origin) and heading. CHECK IN GAME.
	-- air = true spawns the vehicle in the air at heliOffset and puts you in the pilot seat.
	tender = {
		enabled = true, cooldown = 60,
		-- Parking spots on the yacht, measured with /yachtoffset. The number of spots per category is also the
		-- maximum a player can own of that category (1 boat, 2 jet skis, 1 helicopter).
		slots = {
			["Boats"]       = { vector3(-0.68, -58.18, 3.2) },
			["Jet skis"]    = { vector3(-6.54, -57.29, 1.2), vector3(6.49, -57.34, 1.2) },
			["Helicopters"] = { vector3(0.22, -29.98, 12.9) },
		},
		dockKey = 38,          -- key that docks a vehicle (38 = E) when you stand next to it or sit in it near the yacht
		slotPush = 1.0,        -- boats / jet skis are moved out over the water by this many half-lengths so they do not sit inside the hull (0 = off)
		slotHeading = 180.0,   -- added to the yacht heading for boats and jet skis (180 = facing out over the stern)
		options = {
			{ id = 1,  category = "Boats",       label = "Dinghy",             model = "dinghy",      price = 60000 },
			{ id = 2,  category = "Jet skis",    label = "Seashark",           model = "seashark",    price = 25000 },
			{ id = 3,  category = "Boats",       label = "Speeder",            model = "speeder",     price = 180000 },
			{ id = 4,  category = "Boats",       label = "Jetmax",             model = "jetmax",      price = 220000 },
			{ id = 5,  category = "Boats",       label = "Squalo",             model = "squalo",      price = 120000 },
			{ id = 6,  category = "Jet skis",    label = "Seashark Lifeguard", model = "seashark2",   price = 30000 },
			{ id = 7,  category = "Helicopters", label = "Swift",              model = "swift",       price = 900000, air = true },
			{ id = 8,  category = "Helicopters", label = "Maverick",           model = "maverick",    price = 650000, air = true },
			{ id = 9,  category = "Helicopters", label = "Frogger",            model = "frogger",     price = 700000, air = true },
			{ id = 10, category = "Helicopters", label = "Supervolito",        model = "supervolito", price = 850000, air = true },
		},
	},

}


-- ═══════════════════════════════════════════════════════════════════════════
--  9. SCRIPT HOOKS
--  Replace these with your own vehicle-key / text functions if you need to.
-- ═══════════════════════════════════════════════════════════════════════════

function DrawText3D(x, y, z, text)
	local onScreen,_x,_y=World3dToScreen2d(x,y,z)
	local px,py,pz=table.unpack(GetGameplayCamCoords())
	if onScreen then
		SetTextScale(0.35, 0.35)
		SetTextFont(4)
		SetTextProportional(1)
		SetTextColour(255, 255, 255, 255)
		SetTextEntry("STRING")
		SetTextCentre(1)
		AddTextComponentString(text)
        DrawText(_x,_y)
        local factor = (string.len(text)) / 240
		DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 255, 102, 255, 150)
	end
end

function AddYachtKey(vehicle, plate, model)

end

function RemoveYachtKey(vehicle, plate, model)

end


-- ═══════════════════════════════════════════════════════════════════════════
--  10. FURNITURE
--  Starter furniture (BasicEquipment) and the furniture shop catalogue. Long lists, rarely edited.
-- ═══════════════════════════════════════════════════════════════════════════

Config.BasicEquipment = {
	["153946714"] = {furnituremodel = "vw_prop_vw_wallart_73a", furniturecoords = vector3(3.277, -1.840, 6.936), furniturerotation = vector3(-0.000, -0.562, 180.000)},
	["284739561"] = {furnituremodel = "apa_mp_h_acc_dec_head_01", furniturecoords = vector3(-2.147, 5.471, 6.218), furniturerotation = vector3(0.000, -0.000, 27.039)},
	["739512846"] = {furnituremodel = "apa_mp_h_lit_lamptable_09", furniturecoords = vector3(-1.591, -1.588, 6.218), furniturerotation = vector3(-0.036, -0.181, 90.000)},
	["846275319"] = {furnituremodel = "apa_mp_h_lit_lamptable_09", furniturecoords = vector3(2.091, -1.583, 6.219), furniturerotation = vector3(0.000, -0.000, 90.000)},
	["512739684"] = {furnituremodel = "h4_mp_h_yacht_bed_01", furniturecoords = vector3(0.311, -1.838, 5.355), furniturerotation = vector3(0.000, -0.000, 180.000)},
	["394857216"] = {furnituremodel = "apa_mp_h_lit_lamptable_09", furniturecoords = vector3(6.307, 20.675, 6.230), furniturerotation = vector3(0.000, -0.000, 90.000)},
	["685394127"] = {furnituremodel = "apa_mp_h_lit_lamptable_09", furniturecoords = vector3(2.536, 20.644, 6.230), furniturerotation = vector3(0.000, -0.000, 90.000)},
	["127394856"] = {furnituremodel = "v_ret_gc_chair03", furniturecoords = vector3(6.547, 14.070, 6.042), furniturerotation = vector3(0.000, -0.000, -90.000)},
	["563829471"] = {furnituremodel = "prop_laptop_lester2", furniturecoords = vector3(5.202, 14.053, 6.228), furniturerotation = vector3(0.000, -0.000, 90.000)},
	["471829563"] = {furnituremodel = "v_res_mousemat", furniturecoords = vector3(5.352, 14.396, 6.229), furniturerotation = vector3(0.000, -0.000, 90.000)},
	["829563471"] = {furnituremodel = "h4_mp_h_yacht_bed_01", furniturecoords = vector3(4.410, 21.066, 5.355), furniturerotation = vector3(0.000, -0.000, 0.000)},
	["394856127"] = {furnituremodel = "apa_mp_h_lit_lamptable_09", furniturecoords = vector3(0.645, 28.188, 6.238), furniturerotation = vector3(0.000, -0.000, 90.000)},
	["127563841"] = {furnituremodel = "apa_mp_h_lit_lamptable_09", furniturecoords = vector3(3.911, 28.198, 6.238), furniturerotation = vector3(0.000, -0.000, 90.000)},
	["563849122"] = {furnituremodel = "h4_mp_h_yacht_bed_01", furniturecoords = vector3(2.272, 28.690, 5.389), furniturerotation = vector3(0.000, -0.000, 0.000)},
	["849127553"] = {furnituremodel = "ex_mp_h_din_table_05", furniturecoords = vector3(1.381, 25.829, 2.337), furniturerotation = vector3(0.000, -0.000, 180.000)},
	["127564849"] = {furnituremodel = "prop_laptop_01a", furniturecoords = vector3(1.525, 26.036, 3.135), furniturerotation = vector3(0.000, -0.000, 180.000)},
	["563849127"] = {furnituremodel = "xm_prop_x17_corp_offchair", furniturecoords = vector3(1.502, 27.489, 2.867), furniturerotation = vector3(0.000, -0.000, 0.000)},
	["842122263"] = {furnituremodel = "vw_prop_vw_wallart_65a", furniturecoords = vector3(2.612, 25.061, 4.113), furniturerotation = vector3(0.000, 0.000, 180.000)},
	["127560849"] = {furnituremodel = "vw_prop_vw_wallart_41a", furniturecoords = vector3(0.150, 25.100, 4.113), furniturerotation = vector3(0.000, 0.000, 180.000)},
	["563844127"] = {furnituremodel = "apa_mp_h_bed_with_table_02", furniturecoords = vector3(1.381, 33.065, 2.337), furniturerotation = vector3(0.000, -0.000, 0.000)},
	["849157563"] = {furnituremodel = "apa_mp_h_str_shelffloorm_02", furniturecoords = vector3(1.381, 24.658, 2.271), furniturerotation = vector3(0.000, -0.000, 0.000)},
	["127567849"] = {furnituremodel = "apa_mp_h_bed_with_table_02", furniturecoords = vector3(1.381, 18.308, 2.337), furniturerotation = vector3(0.000, -0.000, -180.000)},
	["563845127"] = {furnituremodel = "apa_mp_h_str_shelffloorm_02", furniturecoords = vector3(1.381, 17.932, 2.271), furniturerotation = vector3(0.000, -0.000, 0.000)},
	["849126563"] = {furnituremodel = "apa_mp_h_bed_with_table_02", furniturecoords = vector3(1.381, 11.596, 2.337), furniturerotation = vector3(0.000, -0.000, -180.000)},
	["127561849"] = {furnituremodel = "bkr_prop_biker_barstool_02", furniturecoords = vector3(-2.137, 22.400, 8.450), furniturerotation = vector3(0.000, -0.000, 143.988)},
	["563842127"] = {furnituremodel = "bkr_prop_biker_barstool_02", furniturecoords = vector3(-1.196, 21.869, 8.450), furniturerotation = vector3(0.000, -0.000, 157.106)},
	["129122563"] = {furnituremodel = "bkr_prop_biker_barstool_02", furniturecoords = vector3(-0.076, 21.627, 8.450), furniturerotation = vector3(0.000, -0.000, 180.420)},
	["127261449"] = {furnituremodel = "bkr_prop_biker_barstool_02", furniturecoords = vector3(1.118, 21.845, 8.450), furniturerotation = vector3(0.000, -0.000, 202.725)},
	["523442127"] = {furnituremodel = "bkr_prop_biker_barstool_02", furniturecoords = vector3(2.142, 22.445, 8.450), furniturerotation = vector3(0.000, -0.000, 222.015)},
	["449122563"] = {furnituremodel = "sum_mp_h_yacht_side_table_02", furniturecoords = vector3(-2.677, 17.467, 8.444), furniturerotation = vector3(0.000, -0.000, 90.000)},
	["127561449"] = {furnituremodel = "sum_mp_h_yacht_side_table_02", furniturecoords = vector3(2.580, 17.467, 8.444), furniturerotation = vector3(0.000, -0.000, 90.000)},
	["563244527"] = {furnituremodel = "prop_tv_flat_michael", furniturecoords = vector3(-0.041, 4.683, 9.979), furniturerotation = vector3(0.000, 0.000, 180.000)},
	["849124563"] = {furnituremodel = "apa_mp_h_yacht_sofa_01", furniturecoords = vector3(-0.043, 8.675, 8.444), furniturerotation = vector3(0.000, -0.000, 0.000)},
	["127761849"] = {furnituremodel = "sf_mp_h_yacht_coffee_table_02", furniturecoords = vector3(-0.043, 6.594, 8.444), furniturerotation = vector3(0.000, -0.000, 180.000)},
	["563242127"] = {furnituremodel = "apa_mp_h_acc_rugwoolm_02", furniturecoords = vector3(-0.063, -20.985, 8.425), furniturerotation = vector3(0.033, 0.077, 90.000)},
	["849125563"] = {furnituremodel = "ba_vip_table3", furniturecoords = vector3(-0.063, -20.985, 9.063), furniturerotation = vector3(0.033, 0.077, 155.000)},
	["121567849"] = {furnituremodel = "v_res_fh_sofa", furniturecoords = vector3(-2.685, -23.163, 8.428), furniturerotation = vector3(0.033, 0.077, 90.000)},
	["563244121"] = {furnituremodel = "apa_mp_h_stn_chairstrip_05", furniturecoords = vector3(2.504, -21.119, 8.424), furniturerotation = vector3(0.008, 0.051, -90.000)},
	["842124563"] = {furnituremodel = "prop_bar_beerfridge_01", furniturecoords = vector3(5.074, -20.416, 8.423), furniturerotation = vector3(0.008, 0.051, -90.000)},
	["122561849"] = {furnituremodel = "prop_bar_fridge_01", furniturecoords = vector3(5.070, -19.580, 8.432), furniturerotation = vector3(0.008, 0.051, -90.000)},
	["563244127"] = {furnituremodel = "prop_bar_ice_01", furniturecoords = vector3(4.856, -18.797, 8.421), furniturerotation = vector3(0.008, 0.051, -90.000)},
	["845124563"] = {furnituremodel = "hei_heist_str_avunitl_03", furniturecoords = vector3(-0.063, -17.032, 8.425), furniturerotation = vector3(0.008, 0.051, 0.000)},
	["127565849"] = {furnituremodel = "hei_heist_din_chair_05", furniturecoords = vector3(-2.600, 18.667, 8.444), furniturerotation = vector3(-0.010, 0.006, 0.000)},
	["563824127"] = {furnituremodel = "hei_heist_din_chair_05", furniturecoords = vector3(-3.877, 17.544, 8.444), furniturerotation = vector3(-0.010, 0.006, 90.000)},
	["849122563"] = {furnituremodel = "hei_heist_din_chair_05", furniturecoords = vector3(-2.754, 16.267, 8.444), furniturerotation = vector3(-0.010, 0.006, -180.000)},
	["127161849"] = {furnituremodel = "hei_heist_din_chair_05", furniturecoords = vector3(-1.477, 17.391, 8.444), furniturerotation = vector3(-0.010, 0.006, -90.000)},
	["563442127"] = {furnituremodel = "hei_heist_din_chair_05", furniturecoords = vector3(1.380, 17.544, 8.444), furniturerotation = vector3(-0.010, 0.006, 90.000)},
	["849624563"] = {furnituremodel = "hei_heist_din_chair_05", furniturecoords = vector3(2.631, 18.667, 8.444), furniturerotation = vector3(-0.010, 0.006, 0.000)},
	["127525849"] = {furnituremodel = "hei_heist_din_chair_05", furniturecoords = vector3(3.780, 17.391, 8.444), furniturerotation = vector3(-0.010, 0.006, -90.000)},
	["523845127"] = {furnituremodel = "hei_heist_din_chair_05", furniturecoords = vector3(2.618, 16.267, 8.444), furniturerotation = vector3(-0.010, 0.006, -180.000)},
	["844224463"] = {furnituremodel = "as_yacht_massage_lounger_1", furniturecoords = vector3(-3.208, 9.442, 2.337), furniturerotation = vector3(0.000, -0.000, -180.000)},
	["844124563"] = {furnituremodel = "as_yacht_massage_lounger_1", furniturecoords = vector3(1.093, 9.442, 2.337), furniturerotation = vector3(0.000, -0.000, -180.000)},
	["127461849"] = {furnituremodel = "m24_1_prop_m41_lounger_01a", furniturecoords = vector3(0.383, 1.526, 2.339), furniturerotation = vector3(0.000, -0.000, 180.000)},
	["563846127"] = {furnituremodel = "m24_1_prop_m41_coftableb_01a", furniturecoords = vector3(-0.477, 1.789, 2.337), furniturerotation = vector3(0.000, -0.000, 90.000)},
	["849522563"] = {furnituremodel = "m24_1_prop_m41_lounger_01a", furniturecoords = vector3(-1.390, 1.526, 2.339), furniturerotation = vector3(0.000, -0.000, 180.000)},
	["127563549"] = {furnituremodel = "m24_1_prop_m41_coftableb_01a", furniturecoords = vector3(-2.262, 1.789, 2.337), furniturerotation = vector3(0.000, -0.000, 90.000)},
	["563849627"] = {furnituremodel = "m24_1_prop_m41_lounger_01a", furniturecoords = vector3(-3.168, 1.526, 2.339), furniturerotation = vector3(0.000, -0.000, 180.000)},
	["849127263"] = {furnituremodel = "m24_1_prop_m41_coftableb_01a", furniturecoords = vector3(1.210, 1.789, 2.337), furniturerotation = vector3(0.000, -0.000, 90.000)},
	["127563649"] = {furnituremodel = "m24_1_prop_m41_lounger_01a", furniturecoords = vector3(2.018, 1.526, 2.339), furniturerotation = vector3(0.000, -0.000, 180.000)},
	["513242122"] = {furnituremodel = "ch_chint03_plan_lockers", furniturecoords = vector3(6.962, 4.503, 3.397), furniturerotation = vector3(-0.000, -0.000, 180.000)},
	["849128563"] = {furnituremodel = "as_yacht_paravan_1", furniturecoords = vector3(-0.988, 9.018, 3.330), furniturerotation = vector3(0.000, -0.000, 90.000)},
}

Config.Furnitures = {
    {
        categorylabel = "Bar",
        categoryobjects = {
            {furnitureprice = 100, furnitureobject ="prop_whiskey_glasses"},
            {furnitureprice = 100, furnitureobject ="prop_tequila_bottle"},
            {furnitureprice = 100, furnitureobject ="prop_irish_sign_01"},
            {furnitureprice = 100, furnitureobject ="prop_bar_pump_06"},
            {furnitureprice = 100, furnitureobject ="prop_pitcher_02"},
            {furnitureprice = 100, furnitureobject ="prop_pinacolada"},
            {furnitureprice = 100, furnitureobject ="prop_cockneon"},
            {furnitureprice = 100, furnitureobject ="prop_beer_amopen"},
            {furnitureprice = 100, furnitureobject ="prop_bikerset"},
            {furnitureprice = 100, furnitureobject ="prop_champ_jer_01b"},
            {furnitureprice = 100, furnitureobject ="prop_glass_stack_08"},
            {furnitureprice = 100, furnitureobject ="prop_drink_champ"},
            {furnitureprice = 100, furnitureobject ="vodkarow"},
            {furnitureprice = 100, furnitureobject ="prop_bottle_cognac"},
            {furnitureprice = 100, furnitureobject ="prop_bar_pump_08"},
            {furnitureprice = 100, furnitureobject ="prop_tall_glass"},
            {furnitureprice = 100, furnitureobject ="prop_bar_measrjug"},
            {furnitureprice = 100, furnitureobject ="prop_bar_fridge_02"},
            {furnitureprice = 100, furnitureobject ="prop_bar_cooler_03"},
            {furnitureprice = 100, furnitureobject ="prop_bar_drinkstraws"},
            {furnitureprice = 100, furnitureobject ="prop_bar_stool_01"},
            {furnitureprice = 100, furnitureobject ="prop_optic_vodka"},
            {furnitureprice = 100, furnitureobject ="prop_stripmenu"},
            {furnitureprice = 100, furnitureobject ="prop_ragganeon"},
            {furnitureprice = 100, furnitureobject ="beerrow_world"},
            {furnitureprice = 100, furnitureobject ="prop_bar_pump_01"},
            {furnitureprice = 100, furnitureobject ="prop_barrachneon"},
            {furnitureprice = 100, furnitureobject ="prop_bar_coasterdisp"},
            {furnitureprice = 100, furnitureobject ="prop_bar_shots"},
            {furnitureprice = 100, furnitureobject ="prop_bar_stirrers"},
            {furnitureprice = 100, furnitureobject ="prop_bar_napkindisp"},
            {furnitureprice = 100, furnitureobject ="prop_bar_lemons"},
            {furnitureprice = 100, furnitureobject ="prop_bar_beans"},
            {furnitureprice = 100, furnitureobject ="prop_bar_cockshaker"},
            {furnitureprice = 100, furnitureobject ="prop_irish_sign_02"},
            {furnitureprice = 100, furnitureobject ="prop_bar_caddy"},
            {furnitureprice = 100, furnitureobject ="prop_bar_limes"},
            {furnitureprice = 100, furnitureobject ="prop_beerneon"},
            {furnitureprice = 100, furnitureobject ="prop_champ_cool"},
            {furnitureprice = 100, furnitureobject ="prop_bar_pump_07"},
            {furnitureprice = 100, furnitureobject ="beerrow_local"},
            {furnitureprice = 100, furnitureobject ="prop_bahammenu"},
            {furnitureprice = 100, furnitureobject ="prop_patriotneon"},
            {furnitureprice = 100, furnitureobject ="prop_bar_ice_01"},
            {furnitureprice = 100, furnitureobject ="prop_beer_logopen"},
            {furnitureprice = 100, furnitureobject ="prop_bar_fruit"},
            {furnitureprice = 100, furnitureobject ="prop_bar_fridge_01"},
            {furnitureprice = 100, furnitureobject ="prop_bar_fridge_04"},
            {furnitureprice = 100, furnitureobject ="prop_bar_sink_01"},
            {furnitureprice = 100, furnitureobject ="prop_irish_sign_03"},
            {furnitureprice = 100, furnitureobject ="prop_glass_stack_10"},
            {furnitureprice = 100, furnitureobject ="prop_bar_beerfridge_01"},
            {furnitureprice = 100, furnitureobject ="prop_loggneon"},
            {furnitureprice = 100, furnitureobject ="spiritsrow"},
            {furnitureprice = 100, furnitureobject ="prop_bar_fridge_03"},
            {furnitureprice = 100, furnitureobject ="prop_drink_whisky"},
            {furnitureprice = 100, furnitureobject ="prop_glass_stack_05"},
            {furnitureprice = 100, furnitureobject ="winerow"},
            {furnitureprice = 100, furnitureobject ="prop_stripset"},
            {furnitureprice = 100, furnitureobject ="prop_bar_cooler_01"},
            {furnitureprice = 100, furnitureobject ="prop_drinkmenu"},
        }
    },
    {
        categorylabel = "Bathroom",
        categoryobjects = {
            {furnitureprice = 100, furnitureobject ="prop_towel_01"},
            {furnitureprice = 100, furnitureobject ="prop_toilet_soap_04"},
            {furnitureprice = 100, furnitureobject ="v_res_mbtaps"},
            {furnitureprice = 100, furnitureobject ="prop_toilet_roll_05"},
            {furnitureprice = 100, furnitureobject ="v_res_r_perfume"},
            {furnitureprice = 100, furnitureobject ="prop_toilet_soap_03"},
            {furnitureprice = 100, furnitureobject ="v_serv_bs_looroll"},
            {furnitureprice = 100, furnitureobject ="v_res_tt_looroll"},
            {furnitureprice = 100, furnitureobject ="v_res_mbtowelfld"},
            {furnitureprice = 100, furnitureobject ="prop_towel_rail_01"},
            {furnitureprice = 100, furnitureobject ="prop_toilet_shamp_01"},
            {furnitureprice = 100, furnitureobject ="prop_toilet_roll_02"},
            {furnitureprice = 100, furnitureobject ="prop_toothbrush_01"},
            {furnitureprice = 100, furnitureobject ="prop_toothpaste_01"},
            {furnitureprice = 100, furnitureobject ="prop_toilet_soap_02"},
            {furnitureprice = 100, furnitureobject ="v_res_mbath"},
            {furnitureprice = 100, furnitureobject ="prop_toilet_brush_01"},
            {furnitureprice = 100, furnitureobject ="prop_w_fountain_01"},
            {furnitureprice = 100, furnitureobject ="prop_shower_rack_01"},
            {furnitureprice = 100, furnitureobject ="prop_toilet_soap_01"},
            {furnitureprice = 100, furnitureobject ="prop_soap_disp_01"},
            {furnitureprice = 100, furnitureobject ="v_res_r_cottonbuds"},
            {furnitureprice = 100, furnitureobject ="prop_sink_04"},
            {furnitureprice = 100, furnitureobject ="prop_toilet_02"},
            {furnitureprice = 100, furnitureobject ="prop_sponge_01"},
            {furnitureprice = 100, furnitureobject ="prop_toilet_roll_01"},
            {furnitureprice = 100, furnitureobject ="prop_toilet_01"},
            {furnitureprice = 100, furnitureobject ="prop_sink_06"},
            {furnitureprice = 100, furnitureobject ="prop_toothb_cup_01"},
            {furnitureprice = 100, furnitureobject ="prop_toilet_shamp_02"},
            {furnitureprice = 100, furnitureobject ="v_res_mbathpot"},
            {furnitureprice = 100, furnitureobject ="prop_towel_rail_02"},
            {furnitureprice = 100, furnitureobject ="v_res_r_bublbath"},
            {furnitureprice = 100, furnitureobject ="v_res_r_lotion"},
            {furnitureprice = 100, furnitureobject ="v_res_mbaccessory"},
            {furnitureprice = 100, furnitureobject ="prop_sink_05"},
            {furnitureprice = 100, furnitureobject ="v_res_mbsink"},
            {furnitureprice = 100, furnitureobject ="prop_sink_02"},
            {furnitureprice = 100, furnitureobject ="v_res_mbtowel"},
            {furnitureprice = 100, furnitureobject ="prop_handdry_02"},
            {furnitureprice = 100, furnitureobject ="prop_handdry_01"},
        }
    },
    {
        categorylabel = "Bins",
        categoryobjects = {
            {furnitureprice = 100, furnitureobject ="prop_bin_07b"},
            {furnitureprice = 100, furnitureobject ="prop_bin_beach_01d"},
            {furnitureprice = 100, furnitureobject ="prop_bin_01a"},
            {furnitureprice = 100, furnitureobject ="prop_bin_beach_01a"},
            {furnitureprice = 100, furnitureobject ="prop_recyclebin_03_a"},
            {furnitureprice = 100, furnitureobject ="prop_bin_07c"},
            {furnitureprice = 100, furnitureobject ="prop_bin_07d"},
            {furnitureprice = 100, furnitureobject ="prop_bin_08a"},
            {furnitureprice = 100, furnitureobject ="prop_bin_08open"},
            {furnitureprice = 100, furnitureobject ="prop_bin_12a"},
            {furnitureprice = 100, furnitureobject ="prop_bin_05a"},
        }
    },
    {
        categorylabel = "Construction",
        categoryobjects = {
            {furnitureprice = 100, furnitureobject ="prop_tool_blowtorch"},
            {furnitureprice = 100, furnitureobject ="prop_worklight_04b"},
            {furnitureprice = 100, furnitureobject ="prop_paint_wpaper01"},
            {furnitureprice = 100, furnitureobject ="prop_worklight_04c_l1"},
            {furnitureprice = 100, furnitureobject ="prop_paints_can07"},
            {furnitureprice = 100, furnitureobject ="prop_paints_can03"},
            {furnitureprice = 100, furnitureobject ="prop_medstation_03"},
            {furnitureprice = 100, furnitureobject ="prop_worklight_03a"},
            {furnitureprice = 100, furnitureobject ="prop_worklight_01a"},
            {furnitureprice = 100, furnitureobject ="prop_paint_brush03"},
            {furnitureprice = 100, furnitureobject ="prop_tool_cable01"},
            {furnitureprice = 100, furnitureobject ="prop_tool_screwdvr03"},
            {furnitureprice = 100, furnitureobject ="prop_tool_fireaxe"},
            {furnitureprice = 100, furnitureobject ="prop_paint_brush02"},
            {furnitureprice = 100, furnitureobject ="prop_tool_bluepnt"},
            {furnitureprice = 100, furnitureobject ="prop_tool_pickaxe"},
            {furnitureprice = 100, furnitureobject ="prop_tool_jackham"},
            {furnitureprice = 100, furnitureobject ="prop_oiltub_04"},
            {furnitureprice = 100, furnitureobject ="prop_oiltub_06"},
            {furnitureprice = 100, furnitureobject ="prop_crosssaw_01"},
            {furnitureprice = 100, furnitureobject ="prop_tool_nailgun"},
            {furnitureprice = 100, furnitureobject ="prop_tool_shovel5"},
            {furnitureprice = 100, furnitureobject ="prop_paints_can01"},
            {furnitureprice = 100, furnitureobject ="prop_worklight_04d"},
            {furnitureprice = 100, furnitureobject ="prop_generator_03a"},
            {furnitureprice = 100, furnitureobject ="prop_tool_spanner02"},
            {furnitureprice = 100, furnitureobject ="prop_tool_torch"},
            {furnitureprice = 100, furnitureobject ="prop_oiltub_02"},
            {furnitureprice = 100, furnitureobject ="prop_tool_box_05"},
            {furnitureprice = 100, furnitureobject ="prop_tool_box_02"},
            {furnitureprice = 100, furnitureobject ="prop_tool_rake"},
            {furnitureprice = 100, furnitureobject ="prop_paint_brush05"},
            {furnitureprice = 100, furnitureobject ="prop_paints_pallete01"},
            {furnitureprice = 100, furnitureobject ="prop_tool_shovel3"},
            {furnitureprice = 100, furnitureobject ="prop_paint_stepl01"},
            {furnitureprice = 100, furnitureobject ="prop_etricmotor_01"},
            {furnitureprice = 100, furnitureobject ="prop_tool_shovel006"},
            {furnitureprice = 100, furnitureobject ="prop_cons_crate"},
            {furnitureprice = 100, furnitureobject ="prop_generator_01a"},
            {furnitureprice = 100, furnitureobject ="prop_worklight_04a"},
            {furnitureprice = 100, furnitureobject ="prop_tool_shovel"},
            {furnitureprice = 100, furnitureobject ="prop_wheelbarrow01a"},
            {furnitureprice = 100, furnitureobject ="prop_tool_drill"},
            {furnitureprice = 100, furnitureobject ="prop_tool_screwdvr02"},
            {furnitureprice = 100, furnitureobject ="prop_medstation_01"},
            {furnitureprice = 100, furnitureobject ="prop_tool_rake_l1"},
            {furnitureprice = 100, furnitureobject ="prop_paint_brush04"},
            {furnitureprice = 100, furnitureobject ="prop_bandsaw_01"},
            {furnitureprice = 100, furnitureobject ="prop_paint_tray"},
            {furnitureprice = 100, furnitureobject ="prop_tool_box_04"},
            {furnitureprice = 100, furnitureobject ="prop_tool_cable02"},
            {furnitureprice = 100, furnitureobject ="prop_vertdrill_01"},
            {furnitureprice = 100, furnitureobject ="prop_tool_consaw"},
            {furnitureprice = 100, furnitureobject ="prop_cementbags01"},
            {furnitureprice = 100, furnitureobject ="prop_tool_spanner01"},
            {furnitureprice = 100, furnitureobject ="prop_worklight_04b_l1"},
            {furnitureprice = 100, furnitureobject ="prop_paint_roller"},
            {furnitureprice = 100, furnitureobject ="prop_tool_hardhat"},
            {furnitureprice = 100, furnitureobject ="prop_tool_bench02_ld"},
            {furnitureprice = 100, furnitureobject ="prop_paints_can05"},
            {furnitureprice = 100, furnitureobject ="prop_paints_bench01"},
            {furnitureprice = 100, furnitureobject ="prop_tool_broom2"},
            {furnitureprice = 100, furnitureobject ="prop_paints_can04"},
            {furnitureprice = 100, furnitureobject ="prop_cementmixer_01a"},
            {furnitureprice = 100, furnitureobject ="prop_paints_can02"},
            {furnitureprice = 100, furnitureobject ="prop_tool_broom"},
            {furnitureprice = 100, furnitureobject ="prop_ducktape_01"},
            {furnitureprice = 100, furnitureobject ="prop_tool_box_07"},
            {furnitureprice = 100, furnitureobject ="prop_girder_01a"},
            {furnitureprice = 100, furnitureobject ="prop_workwall_02"},
            {furnitureprice = 100, furnitureobject ="prop_generator_02a"},
            {furnitureprice = 100, furnitureobject ="prop_tool_broom2_l1"},
            {furnitureprice = 100, furnitureobject ="prop_paint_spray01a"},
            {furnitureprice = 100, furnitureobject ="prop_tool_shovel2"},
            {furnitureprice = 100, furnitureobject ="prop_tool_mopbucket"},
            {furnitureprice = 100, furnitureobject ="prop_tool_hammer"},
            {furnitureprice = 100, furnitureobject ="prop_tablesaw_01"},
            {furnitureprice = 100, furnitureobject ="prop_oiltub_01"},
            {furnitureprice = 100, furnitureobject ="prop_worklight_02a"},
            {furnitureprice = 100, furnitureobject ="prop_oiltub_05"},
            {furnitureprice = 100, furnitureobject ="prop_tool_adjspanner"},
            {furnitureprice = 100, furnitureobject ="prop_tool_sledgeham"},
            {furnitureprice = 100, furnitureobject ="prop_tool_pliers"},
            {furnitureprice = 100, furnitureobject ="prop_generator_04"},
            {furnitureprice = 100, furnitureobject ="prop_tool_shovel4"},
            {furnitureprice = 100, furnitureobject ="prop_tool_box_01"},
            {furnitureprice = 100, furnitureobject ="prop_wheelbarrow02a"},
            {furnitureprice = 100, furnitureobject ="prop_medstation_02"},
            {furnitureprice = 100, furnitureobject ="prop_tool_box_03"},
            {furnitureprice = 100, furnitureobject ="prop_worklight_04c"},
            {furnitureprice = 100, furnitureobject ="prop_tool_bench02"},
            {furnitureprice = 100, furnitureobject ="prop_tool_spanner03"},
            {furnitureprice = 100, furnitureobject ="prop_worklight_03b"},
            {furnitureprice = 100, furnitureobject ="prop_paints_can06"},
            {furnitureprice = 100, furnitureobject ="prop_paint_brush01"},
            {furnitureprice = 100, furnitureobject ="prop_tool_wrench"},
            {furnitureprice = 100, furnitureobject ="prop_spraygun_01"},
            {furnitureprice = 100, furnitureobject ="prop_worklight_04d_l1"},
            {furnitureprice = 100, furnitureobject ="prop_oiltub_03"},
            {furnitureprice = 100, furnitureobject ="prop_paint_spray01b"},
            {furnitureprice = 100, furnitureobject ="prop_tool_mallet"},
            {furnitureprice = 100, furnitureobject ="prop_cementmixer_02a"},
            {furnitureprice = 100, furnitureobject ="prop_tool_screwdvr01"},
            {furnitureprice = 100, furnitureobject ="hei_prop_cash_crate_empty"},
            {furnitureprice = 100, furnitureobject ="hei_prop_cash_crate_half_full"},
            {furnitureprice = 100, furnitureobject ="p_blueprints_01_s"},
        }
    },
    {
        categorylabel = "Electrical",
        categoryobjects = {
            {furnitureprice = 100, furnitureobject ="prop_tv_flat_03b"},
            {furnitureprice = 100, furnitureobject ="v_res_monitorsquare"},
            {furnitureprice = 100, furnitureobject ="v_club_roc_mscreen"},
            {furnitureprice = 100, furnitureobject ="v_res_harddrive"},
            {furnitureprice = 100, furnitureobject ="prop_ghettoblast_02"},
            {furnitureprice = 100, furnitureobject ="prop_speaker_01"},
            {furnitureprice = 100, furnitureobject ="prop_cctv_cont_06"},
            {furnitureprice = 100, furnitureobject ="prop_tv_01"},
            {furnitureprice = 100, furnitureobject ="prop_laptop_01a"},
            {furnitureprice = 100, furnitureobject ="prop_tv_flat_michael"},
            {furnitureprice = 100, furnitureobject ="prop_laptop_lester2"},
            {furnitureprice = 100, furnitureobject ="prop_tv_flat_01"},
            {furnitureprice = 100, furnitureobject ="prop_monitor_w_large"},
            {furnitureprice = 100, furnitureobject ="prop_dj_deck_02"},
            {furnitureprice = 100, furnitureobject ="prop_speaker_07"},
            {furnitureprice = 100, furnitureobject ="prop_mouse_02"},
            {furnitureprice = 100, furnitureobject ="prop_cctv_01_sm_02"},
            {furnitureprice = 100, furnitureobject ="v_res_fa_radioalrm"},
            {furnitureprice = 100, furnitureobject ="prop_tv_flat_02b"},
            {furnitureprice = 100, furnitureobject ="v_club_roc_spot_b"},
            {furnitureprice = 100, furnitureobject ="prop_portable_hifi_01"},
            {furnitureprice = 100, furnitureobject ="prop_monitor_01d"},
            {furnitureprice = 100, furnitureobject ="prop_monitor_01c"},
            {furnitureprice = 100, furnitureobject ="v_res_mousemat"},
            {furnitureprice = 100, furnitureobject ="prop_el_tapeplayer_01"},
            {furnitureprice = 100, furnitureobject ="prop_dj_deck_01"},
            {furnitureprice = 100, furnitureobject ="apa_mp_h_acc_coffeemachine_01"},
            {furnitureprice = 100, furnitureobject ="des_tvsmash_start"},
            {furnitureprice = 100, furnitureobject ="prop_tv_03"},
            {furnitureprice = 100, furnitureobject ="xm_prop_x17_tv_ceiling_01"},
            {furnitureprice = 100, furnitureobject ="prop_monitor_02"},
            {furnitureprice = 100, furnitureobject ="prop_tv_cabinet_04"},
            {furnitureprice = 100, furnitureobject ="v_res_monitor"},
            {furnitureprice = 100, furnitureobject ="prop_cctv_cont_02"},
            {furnitureprice = 100, furnitureobject ="v_res_keyboard"},
            {furnitureprice = 100, furnitureobject ="prop_dyn_pc"},
            {furnitureprice = 100, furnitureobject ="v_res_monitorwidelarge"},
            {furnitureprice = 100, furnitureobject ="v_res_pcheadset"},
            {furnitureprice = 100, furnitureobject ="v_res_pctower"},
            {furnitureprice = 100, furnitureobject ="prop_speaker_02"},
            {furnitureprice = 100, furnitureobject ="prop_amp_01"},
            {furnitureprice = 100, furnitureobject ="prop_laptop_02_closed"},
            {furnitureprice = 100, furnitureobject ="prop_monitor_li"},
            {furnitureprice = 100, furnitureobject ="prop_laptop_lester"},
            {furnitureprice = 100, furnitureobject ="prop_monitor_03b"},
            {furnitureprice = 100, furnitureobject ="prop_mouse_01b"},
            {furnitureprice = 100, furnitureobject ="v_res_vhsplayer"},
            {furnitureprice = 100, furnitureobject ="v_club_vu_deckcase"},
            {furnitureprice = 100, furnitureobject ="v_club_roc_micstd"},
            {furnitureprice = 100, furnitureobject ="v_res_ipoddock"},
            {furnitureprice = 100, furnitureobject ="prop_cctv_unit_04"},
            {furnitureprice = 100, furnitureobject ="prop_cs_tv_stand"},
            {furnitureprice = 100, furnitureobject ="prop_till_01_dam"},
            {furnitureprice = 100, furnitureobject ="prop_till_01"},
            {furnitureprice = 100, furnitureobject ="prop_cs_keyboard_01"},
            {furnitureprice = 100, furnitureobject ="prop_keyboard_01a"},
            {furnitureprice = 100, furnitureobject ="prop_cs_dvd_player"},
            {furnitureprice = 100, furnitureobject ="v_res_vacuum"},
            {furnitureprice = 100, furnitureobject ="prop_keyboard_01b"},
            {furnitureprice = 100, furnitureobject ="v_res_tt_tvremote"},
            {furnitureprice = 100, furnitureobject ="v_club_roc_spot_w"},
            {furnitureprice = 100, furnitureobject ="prop_trev_tv_01"},
            {furnitureprice = 100, furnitureobject ="prop_tv_flat_03"},
            {furnitureprice = 100, furnitureobject ="v_res_mm_audio"},
        }
    },
    {
        categorylabel = "Equipment",
        categoryobjects = {
            {furnitureprice = 100, furnitureobject ="hei_p_attache_case_shut"},
            {furnitureprice = 100, furnitureobject ="p_cs_panties_03_s"},
            {furnitureprice = 100, furnitureobject ="p_cs_cuffs_02_s"},
            {furnitureprice = 100, furnitureobject ="p_cs_duffel_01_s"},
            {furnitureprice = 100, furnitureobject ="p_cs_police_torch_s"},
            {furnitureprice = 100, furnitureobject ="p_ld_heist_bag_s_1"},
            {furnitureprice = 100, furnitureobject ="p_ld_heist_bag_s_2"},
            {furnitureprice = 100, furnitureobject ="p_ld_heist_bag_s_pro"},
            {furnitureprice = 100, furnitureobject ="p_michael_backpack_s"},
            {furnitureprice = 100, furnitureobject ="p_s_scuba_tank_s"},
            {furnitureprice = 100, furnitureobject ="stt_prop_c4_stack"},
			{furnitureprice = 100, furnitureobject ="prop_pooltable_02"},
			{furnitureprice = 100, furnitureobject ="ch_prop_arcade_love_01a"},
			{furnitureprice = 100, furnitureobject ="prop_bball_arcade_01"},
			{furnitureprice = 100, furnitureobject ="sum_prop_arcade_str_bar_01a"},
			{furnitureprice = 100, furnitureobject ="ch_prop_arcade_claw_01a"},
			{furnitureprice = 100, furnitureobject ="ch_prop_arcade_fortune_01a"},
			{furnitureprice = 100, furnitureobject ="djn_table_football_1"},
        }
    },
    {
        categorylabel = "Garage",
        categoryobjects = {
            {furnitureprice = 100, furnitureobject ="prop_car_seat"},
            {furnitureprice = 100, furnitureobject ="prop_bumper_06"},
            {furnitureprice = 100, furnitureobject ="prop_wheel_rim_03"},
            {furnitureprice = 100, furnitureobject ="prop_compressor_02"},
            {furnitureprice = 100, furnitureobject ="prop_wheel_01"},
            {furnitureprice = 100, furnitureobject ="prop_wheel_hub_01"},
            {furnitureprice = 100, furnitureobject ="prop_engine_hoist"},
            {furnitureprice = 100, furnitureobject ="prop_toolchest_02"},
            {furnitureprice = 100, furnitureobject ="prop_carcreeper"},
            {furnitureprice = 100, furnitureobject ="prop_spray_jackleg"},
            {furnitureprice = 100, furnitureobject ="prop_compressor_01"},
            {furnitureprice = 100, furnitureobject ="prop_bumper_05"},
            {furnitureprice = 100, furnitureobject ="prop_car_bonnet_02"},
            {furnitureprice = 100, furnitureobject ="prop_toolchest_03"},
            {furnitureprice = 100, furnitureobject ="prop_car_bonnet_01"},
            {furnitureprice = 100, furnitureobject ="prop_toolchest_03_l2"},
            {furnitureprice = 100, furnitureobject ="prop_car_exhaust_01"},
            {furnitureprice = 100, furnitureobject ="prop_car_door_04"},
            {furnitureprice = 100, furnitureobject ="prop_car_battery_01"},
            {furnitureprice = 100, furnitureobject ="prop_toolchest_01"},
            {furnitureprice = 100, furnitureobject ="prop_car_door_02"},
            {furnitureprice = 100, furnitureobject ="prop_carjack_l2"},
            {furnitureprice = 100, furnitureobject ="prop_bumper_02"},
            {furnitureprice = 100, furnitureobject ="prop_wheel_06"},
            {furnitureprice = 100, furnitureobject ="prop_toolchest_05"},
            {furnitureprice = 100, furnitureobject ="prop_bumper_04"},
            {furnitureprice = 100, furnitureobject ="prop_wheel_03"},
            {furnitureprice = 100, furnitureobject ="prop_wheel_rim_05"},
            {furnitureprice = 100, furnitureobject ="prop_wheel_rim_02"},
            {furnitureprice = 100, furnitureobject ="prop_car_door_01"},
            {furnitureprice = 100, furnitureobject ="prop_wheel_rim_04"},
            {furnitureprice = 100, furnitureobject ="prop_car_door_03"},
            {furnitureprice = 100, furnitureobject ="prop_wheel_04"},
            {furnitureprice = 100, furnitureobject ="prop_wheel_02"},
            {furnitureprice = 100, furnitureobject ="prop_wheel_05"},
            {furnitureprice = 100, furnitureobject ="prop_carjack"},
            {furnitureprice = 100, furnitureobject ="prop_bumper_03"},
            {furnitureprice = 100, furnitureobject ="prop_car_engine_01"},
            {furnitureprice = 100, furnitureobject ="prop_toolchest_04"},
            {furnitureprice = 100, furnitureobject ="prop_bumper_01"},
            {furnitureprice = 100, furnitureobject ="prop_wheel_tyre"},
            {furnitureprice = 100, furnitureobject ="prop_wheel_rim_01"},
            {furnitureprice = 100, furnitureobject ="prop_compressor_03"},
            {furnitureprice = 100, furnitureobject ="prop_wheel_hub_02_lod_02"},
        }
    },
    {
        categorylabel = "Industrial",
        categoryobjects = {
            {furnitureprice = 100, furnitureobject ="prop_luggage_04a"},
            {furnitureprice = 100, furnitureobject ="prop_byard_lifering"},
            {furnitureprice = 100, furnitureobject ="prop_oil_guage_01"},
            {furnitureprice = 100, furnitureobject ="prop_mb_crate_01a"},
            {furnitureprice = 100, furnitureobject ="prop_rail_sign04"},
            {furnitureprice = 100, furnitureobject ="prop_ind_mech_03a"},
            {furnitureprice = 100, furnitureobject ="prop_rail_sigbox01"},
            {furnitureprice = 100, furnitureobject ="prop_air_trailer_2b"},
            {furnitureprice = 100, furnitureobject ="prop_mb_cargo_01a"},
            {furnitureprice = 100, furnitureobject ="prop_luggage_09a"},
            {furnitureprice = 100, furnitureobject ="prop_byard_chains01"},
            {furnitureprice = 100, furnitureobject ="prop_byard_phone"},
            {furnitureprice = 100, furnitureobject ="prop_luggage_03a"},
            {furnitureprice = 100, furnitureobject ="prop_byard_gastank02"},
            {furnitureprice = 100, furnitureobject ="prop_luggage_01a"},
            {furnitureprice = 100, furnitureobject ="prop_ind_mech_04a"},
            {furnitureprice = 100, furnitureobject ="prop_air_cargo_04a"},
            {furnitureprice = 100, furnitureobject ="prop_mb_crate_01b"},
            {furnitureprice = 100, furnitureobject ="prop_air_cargo_04c"},
            {furnitureprice = 100, furnitureobject ="prop_luggage_07a"},
            {furnitureprice = 100, furnitureobject ="prop_luggage_05a"},
            {furnitureprice = 100, furnitureobject ="prop_luggage_08a"},
            {furnitureprice = 100, furnitureobject ="prop_byard_motor_02"},
            {furnitureprice = 100, furnitureobject ="prop_mb_cargo_04a"},
            {furnitureprice = 100, furnitureobject ="prop_luggage_06a"},
            {furnitureprice = 100, furnitureobject ="prop_air_trailer_2a"},
            {furnitureprice = 100, furnitureobject ="prop_air_cargo_04b"},
            {furnitureprice = 100, furnitureobject ="hei_prop_carrier_liferafts"},
            {furnitureprice = 100, furnitureobject ="hei_prop_carrier_light_01"},
            {furnitureprice = 100, furnitureobject ="hei_prop_carrier_lightset_1"},
            {furnitureprice = 100, furnitureobject ="hei_prop_hei_warehousetrolly"},
            {furnitureprice = 100, furnitureobject ="hei_prop_hei_ammo_pile"},
        }
    },
    {
        categorylabel = "Interior",
        categoryobjects = {
            {furnitureprice = 100, furnitureobject ="apa_mp_h_acc_rugwooll_03"},
            {furnitureprice = 100, furnitureobject ="apa_mp_h_acc_rugwoolm_01"},
            {furnitureprice = 100, furnitureobject ="apa_mp_h_acc_rugwoolm_02"},
            {furnitureprice = 100, furnitureobject ="apa_mp_h_acc_rugwools_03"},
            {furnitureprice = 100, furnitureobject ="hei_heist_str_avunitl_03"},
            {furnitureprice = 100, furnitureobject ="hei_heist_stn_benchshort"},
            {furnitureprice = 100, furnitureobject ="hei_p_m_bag_var18_bus_s"},
            {furnitureprice = 100, furnitureobject ="hei_prop_bank_alarm_01"},
            {furnitureprice = 100, furnitureobject ="hei_prop_bank_cctv_01"},
            {furnitureprice = 100, furnitureobject ="hei_prop_bank_cctv_02"},
            {furnitureprice = 100, furnitureobject ="hei_prop_cc_metalcover_01"},
            {furnitureprice = 100, furnitureobject ="hei_prop_drug_statue_01"},
            {furnitureprice = 100, furnitureobject ="hei_prop_drug_statue_stack"},
            {furnitureprice = 100, furnitureobject ="hei_prop_hei_bank_mon"},
            {furnitureprice = 100, furnitureobject ="hei_prop_gold_trolly_half_full"},
            {furnitureprice = 100, furnitureobject ="hei_prop_hei_bank_phone_01"},
            {furnitureprice = 100, furnitureobject ="hei_prop_hei_bnk_lamp_01"},
            {furnitureprice = 100, furnitureobject ="hei_prop_hei_bnk_lamp_02"},
            {furnitureprice = 100, furnitureobject ="hei_prop_hei_bust_01"},
            {furnitureprice = 100, furnitureobject ="hei_prop_hei_carrier_disp_01"},
            {furnitureprice = 100, furnitureobject ="hei_prop_hei_cs_keyboard"},
            {furnitureprice = 100, furnitureobject ="hei_prop_hei_drug_case"},
            {furnitureprice = 100, furnitureobject ="hei_prop_hei_lflts_02"},
            {furnitureprice = 100, furnitureobject ="hei_prop_hei_med_benchset1"},
            {furnitureprice = 100, furnitureobject ="hei_prop_heist_apecrate"},
            {furnitureprice = 100, furnitureobject ="hei_prop_heist_drug_tub_01"},
            {furnitureprice = 100, furnitureobject ="hei_prop_heist_pc_01"},
            {furnitureprice = 100, furnitureobject ="hei_prop_heist_tub_truck"},
            {furnitureprice = 100, furnitureobject ="hei_prop_mini_sever_01"},
            {furnitureprice = 100, furnitureobject ="hei_prop_wall_light_10a_cr"},
            {furnitureprice = 100, furnitureobject ="ng_proc_coffee_01a"},
            {furnitureprice = 100, furnitureobject ="ng_proc_food_bag01a"},
            {furnitureprice = 100, furnitureobject ="ng_proc_oilcan01a"},
            {furnitureprice = 100, furnitureobject ="ng_proc_litter_plasbot1"},
            {furnitureprice = 100, furnitureobject ="p_amanda_note_01_s"},
            {furnitureprice = 100, furnitureobject ="p_cctv_s"},
            {furnitureprice = 100, furnitureobject ="p_controller_01_s"},
            {furnitureprice = 100, furnitureobject ="p_champ_flute_s"},
            {furnitureprice = 100, furnitureobject ="p_cs_newspaper_s"},
            {furnitureprice = 100, furnitureobject ="p_cs_scissors_s"},
            {furnitureprice = 100, furnitureobject ="p_cs_trolley_01_s"},
            {furnitureprice = 100, furnitureobject ="p_defilied_ragdoll_01_s"},
            {furnitureprice = 100, furnitureobject ="p_kitch_juicer_s"},
            {furnitureprice = 100, furnitureobject ="p_laptop_02_s"},
            {furnitureprice = 100, furnitureobject ="p_lestersbed_s"},
            {furnitureprice = 100, furnitureobject ="p_mbbed_s"},
            {furnitureprice = 100, furnitureobject ="apa_mp_h_bed_double_08"},
            {furnitureprice = 100, furnitureobject ="apa_mp_h_bed_double_09"},
            {furnitureprice = 100, furnitureobject ="gr_prop_bunker_bed_01"},
            {furnitureprice = 100, furnitureobject ="apa_mp_h_bed_wide_05"},
            {furnitureprice = 100, furnitureobject ="apa_mp_h_yacht_bed_02"},
            {furnitureprice = 100, furnitureobject ="p_sec_case_02_s"},
            {furnitureprice = 100, furnitureobject ="p_syringe_01_s"},
            {furnitureprice = 100, furnitureobject ="p_till_01_s"},
            {furnitureprice = 100, furnitureobject ="p_tourist_map_01_s"},
            {furnitureprice = 100, furnitureobject ="p_tv_cam_02_s"},
            {furnitureprice = 100, furnitureobject ="p_v_43_safe_s"},
            {furnitureprice = 100, furnitureobject ="p_v_res_tt_bed_s"},
            {furnitureprice = 100, furnitureobject ="p_w_grass_gls_s"},
            {furnitureprice = 100, furnitureobject ="prop_train_ticket_02_tu"},
            {furnitureprice = 100, furnitureobject ="prop_vend_snak_01_tu"},
            {furnitureprice = 100, furnitureobject ="prop_xmas_tree_int"},
            {furnitureprice = 100, furnitureobject ="prop_wheelchair_01_s"},
            {furnitureprice = 100, furnitureobject ="v_ilev_acet_projector"},
            {furnitureprice = 100, furnitureobject ="v_ilev_fh_dineeamesa"},
            {furnitureprice = 100, furnitureobject ="v_ilev_lest_bigscreen"},
            {furnitureprice = 100, furnitureobject ="v_ilev_liconftable_sml"},
            {furnitureprice = 100, furnitureobject ="v_ilev_mm_fridgeint"},
            {furnitureprice = 100, furnitureobject ="v_ilev_mm_screen"},
            {furnitureprice = 100, furnitureobject ="v_ilev_mr_rasberryclean"},
            {furnitureprice = 100, furnitureobject ="v_ilev_ra_doorsafe"},
            {furnitureprice = 100, furnitureobject ="v_ilev_ta_tatgun"},
            {furnitureprice = 100, furnitureobject ="v_ilev_tort_stool"},
            {furnitureprice = 100, furnitureobject ="v_ilev_trev_pictureframe"},
            {furnitureprice = 100, furnitureobject ="v_res_msonbed_s"},
            {furnitureprice = 100, furnitureobject ="w_am_baseball"},
            {furnitureprice = 100, furnitureobject ="w_am_case"},
            {furnitureprice = 100, furnitureobject ="w_am_brfcase"},
            {furnitureprice = 100, furnitureobject ="w_am_fire_exting"},
            {furnitureprice = 100, furnitureobject ="w_am_jerrycan"},
        }
    },
    {
        categorylabel = "Kitchen",
        categoryobjects = {
            {furnitureprice = 100, furnitureobject ="v_res_mkniferack"},
            {furnitureprice = 100, furnitureobject ="prop_pot_03"},
            {furnitureprice = 100, furnitureobject ="v_res_foodjara"},
            {furnitureprice = 100, furnitureobject ="v_ret_ta_paproll"},
            {furnitureprice = 100, furnitureobject ="prop_mug_02"},
            {furnitureprice = 100, furnitureobject ="prop_kitch_pot_fry"},
            {furnitureprice = 100, furnitureobject ="v_res_foodjarb"},
            {furnitureprice = 100, furnitureobject ="v_serv_bs_mug"},
            {furnitureprice = 100, furnitureobject ="prop_mug_03"},
            {furnitureprice = 100, furnitureobject ="prop_plate_02"},
            {furnitureprice = 100, furnitureobject ="prop_plate_01"},
            {furnitureprice = 100, furnitureobject ="v_ret_fh_plate1"},
            {furnitureprice = 100, furnitureobject ="v_res_tre_fridge"},
            {furnitureprice = 100, furnitureobject ="v_res_mknifeblock"},
            {furnitureprice = 100, furnitureobject ="v_res_mplatelrg"},
            {furnitureprice = 100, furnitureobject ="v_res_tt_bowlpile02"},
            {furnitureprice = 100, furnitureobject ="v_ret_fh_ironbrd"},
            {furnitureprice = 100, furnitureobject ="prop_cleaver"},
            {furnitureprice = 100, furnitureobject ="prop_kettle"},
            {furnitureprice = 100, furnitureobject ="prop_mug_04"},
            {furnitureprice = 100, furnitureobject ="prop_knife_stand"},
            {furnitureprice = 100, furnitureobject ="v_ret_gc_cup"},
            {furnitureprice = 100, furnitureobject ="prop_cooker_03"},
            {furnitureprice = 100, furnitureobject ="prop_kettle_01"},
            {furnitureprice = 100, furnitureobject ="prop_lime_jar"},
            {furnitureprice = 100, furnitureobject ="v_res_fa_pottea"},
            {furnitureprice = 100, furnitureobject ="v_ret_fh_dryer"},
            {furnitureprice = 100, furnitureobject ="v_res_fa_basket"},
            {furnitureprice = 100, furnitureobject ="v_res_mmug"},
            {furnitureprice = 100, furnitureobject ="v_res_mplatesml"},
            {furnitureprice = 100, furnitureobject ="prop_kitch_pot_lrg2"},
            {furnitureprice = 100, furnitureobject ="prop_pot_01"},
            {furnitureprice = 100, furnitureobject ="prop_toaster_02"},
            {furnitureprice = 100, furnitureobject ="v_res_tt_plate01"},
            {furnitureprice = 100, furnitureobject ="prop_pot_04"},
            {furnitureprice = 100, furnitureobject ="v_ret_ta_paproll2"},
            {furnitureprice = 100, furnitureobject ="v_res_pestle"},
            {furnitureprice = 100, furnitureobject ="prop_micro_04"},
            {furnitureprice = 100, furnitureobject ="prop_breadbin_01"},
            {furnitureprice = 100, furnitureobject ="v_res_cakedome"},
            {furnitureprice = 100, furnitureobject ="v_res_fa_grater"},
            {furnitureprice = 100, furnitureobject ="prop_wok"},
            {furnitureprice = 100, furnitureobject ="prop_pot_rack"},
            {furnitureprice = 100, furnitureobject ="prop_fridge_03"},
            {furnitureprice = 100, furnitureobject ="prop_washer_01"},
            {furnitureprice = 100, furnitureobject ="v_ret_fh_washmach"},
            {furnitureprice = 100, furnitureobject ="v_ret_fh_plate2"},
            {furnitureprice = 100, furnitureobject ="prop_foodprocess_01"},
            {furnitureprice = 100, furnitureobject ="prop_micro_01"},
            {furnitureprice = 100, furnitureobject ="prop_fridge_01"},
            {furnitureprice = 100, furnitureobject ="prop_whisk"},
            {furnitureprice = 100, furnitureobject ="v_res_mutensils"},
            {furnitureprice = 100, furnitureobject ="prop_kitch_juicer"},
            {furnitureprice = 100, furnitureobject ="prop_micro_02"},
            {furnitureprice = 100, furnitureobject ="prop_washer_03"},
            {furnitureprice = 100, furnitureobject ="v_res_fa_chopbrd"},
            {furnitureprice = 100, furnitureobject ="v_res_fridgemoda"},
        }
    },
    {
        categorylabel = "Misc",
        categoryobjects = {
            {furnitureprice = 100, furnitureobject ="prop_cs_ilev_blind_01"},
            {furnitureprice = 100, furnitureobject ="prop_amanda_note_01"},
            {furnitureprice = 100, furnitureobject ="prop_tennis_rack_01"},
            {furnitureprice = 100, furnitureobject ="prop_sandwich_01"},
            {furnitureprice = 100, furnitureobject ="prop_space_pistol"},
            {furnitureprice = 100, furnitureobject ="prop_cs_film_reel_01"},
            {furnitureprice = 100, furnitureobject ="prop_cs_duffel_01b"},
            {furnitureprice = 100, furnitureobject ="prop_cs_server_drive"},
            {furnitureprice = 100, furnitureobject ="prop_mem_candle_combo"},
            {furnitureprice = 100, furnitureobject ="prop_police_radio_main"},
            {furnitureprice = 100, furnitureobject ="prop_cash_case_02"},
            {furnitureprice = 100, furnitureobject ="prop_pineapple"},
            {furnitureprice = 100, furnitureobject ="prop_cs_amanda_shoe"},
            {furnitureprice = 100, furnitureobject ="prop_cliff_paper"},
            {furnitureprice = 100, furnitureobject ="prop_cs_phone_01"},
            {furnitureprice = 100, furnitureobject ="prop_broken_cboard_p1"},
            {furnitureprice = 100, furnitureobject ="prop_cd_folder_pile1"},
            {furnitureprice = 100, furnitureobject ="prop_controller_01"},
            {furnitureprice = 100, furnitureobject ="prop_gun_case_01"},
            {furnitureprice = 100, furnitureobject ="prop_ecg_01"},
            {furnitureprice = 100, furnitureobject ="p_cs_bottle_01"},
            {furnitureprice = 100, furnitureobject ="prop_cash_pile_01"},
            {furnitureprice = 100, furnitureobject ="prop_cs_plate_01"},
            {furnitureprice = 100, furnitureobject ="prop_ear_defenders_01"},
            {furnitureprice = 100, furnitureobject ="prop_ld_crocclips01"},
            {furnitureprice = 100, furnitureobject ="prop_cs_mini_tv"},
            {furnitureprice = 100, furnitureobject ="prop_nigel_bag_pickup"},
            {furnitureprice = 100, furnitureobject ="prop_boombox_01"},
            {furnitureprice = 100, furnitureobject ="prop_drug_package"},
            {furnitureprice = 100, furnitureobject ="prop_mil_crate_01"},
            {furnitureprice = 100, furnitureobject ="prop_weld_torch"},
            {furnitureprice = 100, furnitureobject ="prop_trevor_rope_01"},
            {furnitureprice = 100, furnitureobject ="prop_cs_gascutter_1"},
            {furnitureprice = 100, furnitureobject ="prop_cd_paper_pile3"},
            {furnitureprice = 100, furnitureobject ="prop_energy_drink"},
            {furnitureprice = 100, furnitureobject ="prop_megaphone_01"},
            {furnitureprice = 100, furnitureobject ="prop_cs_petrol_can"},
            {furnitureprice = 100, furnitureobject ="prop_ld_bomb_anim"},
            {furnitureprice = 100, furnitureobject ="prop_cs_bowl_01b"},
            {furnitureprice = 100, furnitureobject ="p_ing_microphonel_01"},
            {furnitureprice = 100, furnitureobject ="prop_devin_box_01"},
            {furnitureprice = 100, furnitureobject ="prop_hard_hat_01"},
            {furnitureprice = 100, furnitureobject ="prop_rope_family_3"},
            {furnitureprice = 100, furnitureobject ="prop_anim_cash_pile_01"},
            {furnitureprice = 100, furnitureobject ="prop_weed_pallet"},
            {furnitureprice = 100, furnitureobject ="prop_big_shit_02"},
            {furnitureprice = 100, furnitureobject ="prop_cs_milk_01"},
            {furnitureprice = 100, furnitureobject ="prop_cs_duffel_01"},
            {furnitureprice = 100, furnitureobject ="prop_iron_01"},
            {furnitureprice = 100, furnitureobject ="prop_gold_cont_01"},
            {furnitureprice = 100, furnitureobject ="prop_cs_photoframe_01"},
            {furnitureprice = 100, furnitureobject ="prop_table_mic_01"},
            {furnitureprice = 100, furnitureobject ="prop_cs_walkie_talkie"},
            {furnitureprice = 100, furnitureobject ="prop_tv_cam_02"},
            {furnitureprice = 100, furnitureobject ="prop_blox_spray"},
            {furnitureprice = 100, furnitureobject ="prop_idol_case_02"},
            {furnitureprice = 100, furnitureobject ="prop_cs_crisps_01"},
            {furnitureprice = 100, furnitureobject ="prop_ld_flow_bottle"},
            {furnitureprice = 100, furnitureobject ="prop_cash_pile_02"},
            {furnitureprice = 100, furnitureobject ="prop_cs_trowel"},
            {furnitureprice = 100, furnitureobject ="prop_flight_box_01"},
            {furnitureprice = 100, furnitureobject ="prop_cs_bs_cup"},
            {furnitureprice = 100, furnitureobject ="prop_mil_crate_02"},
            {furnitureprice = 100, furnitureobject ="prop_peanut_bowl_01"},
            {furnitureprice = 100, furnitureobject ="prop_drug_package_02"},
            {furnitureprice = 100, furnitureobject ="prop_cs_sink_filler"},
            {furnitureprice = 100, furnitureobject ="prop_ld_headset_01"},
            {furnitureprice = 100, furnitureobject ="prop_cs_leg_chain_01"},
            {furnitureprice = 100, furnitureobject ="prop_cash_depot_billbrd"},
            {furnitureprice = 100, furnitureobject ="prop_cs_mopbucket_01"},
            {furnitureprice = 100, furnitureobject ="prop_cs_cctv"},
            {furnitureprice = 100, furnitureobject ="prop_cs_kettle_01"},
            {furnitureprice = 100, furnitureobject ="prop_cs_hand_radio"},
            {furnitureprice = 100, furnitureobject ="prop_peyote_lowland_02"},
            {furnitureprice = 100, furnitureobject ="prop_cs_cashenvelope"},
            {furnitureprice = 100, furnitureobject ="p_rc_handset"},
            {furnitureprice = 100, furnitureobject ="prop_cs_ironing_board"},
            {furnitureprice = 100, furnitureobject ="prop_cash_case_01"},
            {furnitureprice = 100, furnitureobject ="prop_mp3_dock"},
            {furnitureprice = 100, furnitureobject ="prop_cs_beer_box"},
            {furnitureprice = 100, furnitureobject ="prop_ld_gold_chest"},
            {furnitureprice = 100, furnitureobject ="prop_cs_wrench"},
            {furnitureprice = 100, furnitureobject ="prop_cs_burger_01"},
            {furnitureprice = 100, furnitureobject ="prop_shower_towel"},
            {furnitureprice = 100, furnitureobject ="prop_cs_rub_box_01"},
            {furnitureprice = 100, furnitureobject ="prop_cs_hotdog_01"},
            {furnitureprice = 100, furnitureobject ="prop_cs_toaster"},
            {furnitureprice = 100, furnitureobject ="prop_ld_wallet_pickup"},
            {furnitureprice = 100, furnitureobject ="prop_coffin_02"},
            {furnitureprice = 100, furnitureobject ="prop_cs_dildo_01"},
            {furnitureprice = 100, furnitureobject ="prop_pliers_01"},
            {furnitureprice = 100, furnitureobject ="prop_sewing_machine"},
            {furnitureprice = 100, furnitureobject ="prop_cs_lester_crate"},
            {furnitureprice = 100, furnitureobject ="prop_headset_01"},
            {furnitureprice = 100, furnitureobject ="prop_beer_box_01"},
            {furnitureprice = 100, furnitureobject ="prop_makeup_brush"},
            {furnitureprice = 100, furnitureobject ="prop_anim_cash_pile_02"},
            {furnitureprice = 100, furnitureobject ="prop_cs_gascutter_2"},
            {furnitureprice = 100, furnitureobject ="prop_cash_crate_01"},
            {furnitureprice = 100, furnitureobject ="prop_rail_controller"},
            {furnitureprice = 100, furnitureobject ="prop_mp_drug_package"},
            {furnitureprice = 100, furnitureobject ="prop_ld_fireaxe"},
            {furnitureprice = 100, furnitureobject ="prop_proxy_hat_01"},
            {furnitureprice = 100, furnitureobject ="prop_tv_test"},
            {furnitureprice = 100, furnitureobject ="prop_cs_clothes_box"},
            {furnitureprice = 100, furnitureobject ="prop_binoc_01"},
            {furnitureprice = 100, furnitureobject ="prop_ld_shovel"},
            {furnitureprice = 100, furnitureobject ="prop_premier_fence_02"},
            {furnitureprice = 100, furnitureobject ="prop_cs_sink_filler_02"},
            {furnitureprice = 100, furnitureobject ="prop_hockey_bag_01"},
            {furnitureprice = 100, furnitureobject ="prop_fbi3_coffee_table"},
            {furnitureprice = 100, furnitureobject ="prop_ld_fags_01"},
            {furnitureprice = 100, furnitureobject ="prop_coke_block_01"},
            {furnitureprice = 100, furnitureobject ="prop_devin_rope_01"},
            {furnitureprice = 100, furnitureobject ="prop_bongos_01"},
            {furnitureprice = 100, furnitureobject ="prop_glass_suck_holder"},
            {furnitureprice = 100, furnitureobject ="prop_welding_mask_01"},
            {furnitureprice = 100, furnitureobject ="prop_cs_steak"},
            {furnitureprice = 100, furnitureobject ="prop_cs_street_binbag_01"},
            {furnitureprice = 100, furnitureobject ="prop_tea_trolly"},
            {furnitureprice = 100, furnitureobject ="prop_cs_trolley_01"},
            {furnitureprice = 100, furnitureobject ="prop_gold_cont_01b"},
            {furnitureprice = 100, furnitureobject ="prop_sh_mr_rasp_01"},
        }
    },
    {
        categorylabel = "Office",
        categoryobjects = {
            {furnitureprice = 100, furnitureobject ="prop_cleaning_trolly"},
            {furnitureprice = 100, furnitureobject ="prop_copier_01"},
            {furnitureprice = 100, furnitureobject ="v_res_printer"},
            {furnitureprice = 100, furnitureobject ="prop_folder_02"},
            {furnitureprice = 100, furnitureobject ="prop_water_bottle_dark"},
            {furnitureprice = 100, furnitureobject ="prop_paper_box_02"},
            {furnitureprice = 100, furnitureobject ="v_res_paperfolders"},
            {furnitureprice = 100, furnitureobject ="prop_coathook_01"},
            {furnitureprice = 100, furnitureobject ="prop_off_chair_01"},
            {furnitureprice = 100, furnitureobject ="v_ret_gc_chair03"},
            {furnitureprice = 100, furnitureobject ="prop_paper_box_05"},
            {furnitureprice = 100, furnitureobject ="v_ret_gc_fax"},
            {furnitureprice = 100, furnitureobject ="v_res_binder"},
            {furnitureprice = 100, furnitureobject ="prop_off_chair_04b"},
            {furnitureprice = 100, furnitureobject ="prop_off_chair_04"},
            {furnitureprice = 100, furnitureobject ="v_corp_cd_chair"},
            {furnitureprice = 100, furnitureobject ="v_serv_tc_bin2_"},
            {furnitureprice = 100, furnitureobject ="v_ret_gc_pen1"},
            {furnitureprice = 100, furnitureobject ="prop_inout_tray_02"},
            {furnitureprice = 100, furnitureobject ="v_res_cd"},
            {furnitureprice = 100, furnitureobject ="v_ret_gc_staple"},
            {furnitureprice = 100, furnitureobject ="prop_cabinet_01b"},
            {furnitureprice = 100, furnitureobject ="prop_paper_box_04"},
            {furnitureprice = 100, furnitureobject ="prop_cabinet_01"},
            {furnitureprice = 100, furnitureobject ="v_ret_gc_scissors"},
            {furnitureprice = 100, furnitureobject ="v_serv_tc_bin1_"},
            {furnitureprice = 100, furnitureobject ="v_corp_offchair"},
            {furnitureprice = 100, furnitureobject ="prop_fan_01"},
            {furnitureprice = 100, furnitureobject ="prop_paper_box_01"},
            {furnitureprice = 100, furnitureobject ="prop_wait_bench_01"},
            {furnitureprice = 100, furnitureobject ="prop_fax_01"},
            {furnitureprice = 100, furnitureobject ="v_ret_gc_shred"},
            {furnitureprice = 100, furnitureobject ="prop_folder_01"},
            {furnitureprice = 100, furnitureobject ="v_ret_gc_folder2"},
            {furnitureprice = 100, furnitureobject ="prop_printer_01"},
            {furnitureprice = 100, furnitureobject ="prop_office_phone_tnt"},
            {furnitureprice = 100, furnitureobject ="prop_off_chair_05"},
            {furnitureprice = 100, furnitureobject ="prop_office_desk_01"},
            {furnitureprice = 100, furnitureobject ="v_ret_gc_phone"},
            {furnitureprice = 100, furnitureobject ="v_ret_gc_print"},
            {furnitureprice = 100, furnitureobject ="v_res_officeboxfile01"},
            {furnitureprice = 100, furnitureobject ="prop_water_bottle"},
            {furnitureprice = 100, furnitureobject ="prop_off_chair_03"},
            {furnitureprice = 100, furnitureobject ="prop_fib_coffee"},
            {furnitureprice = 100, furnitureobject ="prop_watercooler"},
            {furnitureprice = 100, furnitureobject ="prop_office_alarm_01"},
            {furnitureprice = 100, furnitureobject ="prop_waiting_seat_01"},
            {furnitureprice = 100, furnitureobject ="prop_cabinet_02b"},
            {furnitureprice = 100, furnitureobject ="prop_shredder_01"},
            {furnitureprice = 100, furnitureobject ="prop_paper_box_03"},
            {furnitureprice = 100, furnitureobject ="v_club_officechair"},
            {furnitureprice = 100, furnitureobject ="v_corp_bk_chair3"},
            {furnitureprice = 100, furnitureobject ="prop_off_phone_01"},
            {furnitureprice = 100, furnitureobject ="prop_printer_02"},
            {furnitureprice = 100, furnitureobject ="prop_watercooler_dark"},
            {furnitureprice = 100, furnitureobject ="prop_inout_tray_01"},
            {furnitureprice = 100, furnitureobject ="watercooler_bottle001"},
            {furnitureprice = 100, furnitureobject ="prop_fib_clipboard"},
            {furnitureprice = 100, furnitureobject ="v_ret_gc_trays"},
            {furnitureprice = 100, furnitureobject ="v_res_cdstorage"},
            {furnitureprice = 100, furnitureobject ="prop_fib_ashtray_01"},
            {furnitureprice = 100, furnitureobject ="prop_sol_chair"},
            {furnitureprice = 100, furnitureobject ="v_ret_gc_folder1"},
            {furnitureprice = 100, furnitureobject ="v_res_desktidy"},
            {furnitureprice = 100, furnitureobject ="prop_tablesmall_01"},
            {furnitureprice = 100, furnitureobject ="v_ret_gc_pen2"},
        }
    },
    {
        categorylabel = "Outdoor",
        categoryobjects = {
            {furnitureprice = 100, furnitureobject ="hei_prop_heist_weed_pallet"},
            {furnitureprice = 100, furnitureobject ="hei_prop_heist_weed_pallet_02"},
            {furnitureprice = 100, furnitureobject ="hei_prop_heist_weed_block_01b"},
            {furnitureprice = 100, furnitureobject ="ind_prop_firework_01"},
            {furnitureprice = 100, furnitureobject ="ind_prop_firework_03"},
            {furnitureprice = 100, furnitureobject ="ind_prop_firework_02"},
            {furnitureprice = 100, furnitureobject ="ind_prop_firework_04"},
            {furnitureprice = 100, furnitureobject ="ng_proc_binbag_01a"},
            {furnitureprice = 100, furnitureobject ="ng_proc_box_02a"},
            {furnitureprice = 100, furnitureobject ="ng_proc_coffee_02a"},
            {furnitureprice = 100, furnitureobject ="ng_proc_litter_plasbot3"},
            {furnitureprice = 100, furnitureobject ="ng_proc_sodacan_02a"},
            {furnitureprice = 100, furnitureobject ="ng_proc_sodacan_02c"},
            {furnitureprice = 100, furnitureobject ="ng_proc_sodacan_03b"},
            {furnitureprice = 100, furnitureobject ="ng_proc_tyre_dam1"},
            {furnitureprice = 100, furnitureobject ="ng_proc_tyre_01"},
        }
    },
    {
        categorylabel = "Plants",
        categoryobjects = {
            {furnitureprice = 100, furnitureobject ="apa_mp_h_acc_vase_flowers_01"},
            {furnitureprice = 100, furnitureobject ="apa_mp_h_acc_vase_flowers_02"},
            {furnitureprice = 100, furnitureobject ="hei_heist_acc_flowers_01"},
            {furnitureprice = 100, furnitureobject ="prop_xmas_tree_int"},
            {furnitureprice = 100, furnitureobject ="prop_veg_crop_03_pump"},
            {furnitureprice = 100, furnitureobject ="prop_veg_crop_tr_01"},
            {furnitureprice = 100, furnitureobject ="prop_veg_crop_02"},
            {furnitureprice = 100, furnitureobject ="prop_plant_int_01b"},
            {furnitureprice = 100, furnitureobject ="prop_plant_int_03a"},
            {furnitureprice = 100, furnitureobject ="prop_pot_plant_01d"},
            {furnitureprice = 100, furnitureobject ="prop_pot_plant_01e"},
            {furnitureprice = 100, furnitureobject ="p_int_jewel_plant_01"},
            {furnitureprice = 100, furnitureobject ="p_int_jewel_plant_02"},
            {furnitureprice = 100, furnitureobject ="prop_fbibombplant"},
            {furnitureprice = 100, furnitureobject ="prop_bush_ornament_01"},
            {furnitureprice = 100, furnitureobject ="prop_bush_ornament_02"},
            {furnitureprice = 100, furnitureobject ="prop_bush_ornament_03"},
            {furnitureprice = 100, furnitureobject ="prop_plant_interior_05a"},
            {furnitureprice = 100, furnitureobject ="prop_pot_plant_05b"},
            {furnitureprice = 100, furnitureobject ="prop_plant_int_01b"},
            {furnitureprice = 100, furnitureobject ="prop_pot_plant_02c"},
            {furnitureprice = 100, furnitureobject ="prop_plant_int_05b"},
            {furnitureprice = 100, furnitureobject ="prop_pot_plant_05d"},
            {furnitureprice = 100, furnitureobject ="prop_pot_plant_03b"},
            {furnitureprice = 100, furnitureobject ="prop_plant_int_04a"},
            {furnitureprice = 100, furnitureobject ="prop_plant_int_06b"},
            {furnitureprice = 100, furnitureobject ="prop_plant_int_03a"},
            {furnitureprice = 100, furnitureobject ="prop_pot_plant_04b"},
            {furnitureprice = 100, furnitureobject ="prop_pot_plant_05c"},
            {furnitureprice = 100, furnitureobject ="prop_pot_plant_02b"},
            {furnitureprice = 100, furnitureobject ="prop_pot_plant_inter_03a"},
            {furnitureprice = 100, furnitureobject ="prop_pot_plant_04c"},
            {furnitureprice = 100, furnitureobject ="prop_plant_int_03c"},
            {furnitureprice = 100, furnitureobject ="prop_plant_int_05a"},
            {furnitureprice = 100, furnitureobject ="prop_pot_plant_01a"},
            {furnitureprice = 100, furnitureobject ="prop_plant_int_03b"},
            {furnitureprice = 100, furnitureobject ="prop_plant_int_02a"},
            {furnitureprice = 100, furnitureobject ="prop_plant_int_06a"},
            {furnitureprice = 100, furnitureobject ="prop_pot_plant_04a"},
            {furnitureprice = 100, furnitureobject ="prop_plant_int_01a"},
            {furnitureprice = 100, furnitureobject ="prop_pot_plant_02a"},
            {furnitureprice = 100, furnitureobject ="prop_plant_int_04c"},
            {furnitureprice = 100, furnitureobject ="prop_pot_plant_05a"},
            {furnitureprice = 100, furnitureobject ="prop_pot_plant_03c"},
            {furnitureprice = 100, furnitureobject ="prop_plant_int_02b"},
            {furnitureprice = 100, furnitureobject ="prop_pot_plant_6a"},
            {furnitureprice = 100, furnitureobject ="prop_pot_plant_03a"},
            {furnitureprice = 100, furnitureobject ="prop_plant_int_04b"},
            {furnitureprice = 100, furnitureobject ="prop_pot_plant_01e"},
            {furnitureprice = 100, furnitureobject ="prop_pot_plant_05d_l1"},
            {furnitureprice = 100, furnitureobject ="prop_pot_plant_01d"},
            {furnitureprice = 100, furnitureobject ="prop_pot_plant_02d"},
            {furnitureprice = 100, furnitureobject ="prop_pot_plant_01b"},
            {furnitureprice = 100, furnitureobject ="prop_pot_plant_bh1"},
            {furnitureprice = 100, furnitureobject ="prop_pot_plant_01c"},
        }
    },
    {
        categorylabel = "Recreational",
        categoryobjects = {
            {furnitureprice = 100, furnitureobject ="prop_beach_towel_02"},
            {furnitureprice = 100, furnitureobject ="prop_weight_15k"},
            {furnitureprice = 100, furnitureobject ="prop_boogieboard_10"},
            {furnitureprice = 100, furnitureobject ="prop_beach_towel_04"},
            {furnitureprice = 100, furnitureobject ="prop_porn_mag_02"},
            {furnitureprice = 100, furnitureobject ="prop_sglasses_stand_02b"},
            {furnitureprice = 100, furnitureobject ="prop_hat_box_06"},
            {furnitureprice = 100, furnitureobject ="prop_ftowel_07"},
            {furnitureprice = 100, furnitureobject ="prop_weight_5k"},
            {furnitureprice = 100, furnitureobject ="prop_bikini_disp_04"},
            {furnitureprice = 100, furnitureobject ="prop_venice_board_03"},
            {furnitureprice = 100, furnitureobject ="prop_barbell_100kg"},
            {furnitureprice = 100, furnitureobject ="prop_bleachers_04"},
            {furnitureprice = 100, furnitureobject ="prop_vend_snak_01"},
            {furnitureprice = 100, furnitureobject ="prop_sglasses_stand_01"},
            {furnitureprice = 100, furnitureobject ="prop_venice_sign_18"},
            {furnitureprice = 100, furnitureobject ="prop_buck_spade_06"},
            {furnitureprice = 100, furnitureobject ="prop_beach_lilo_01"},
            {furnitureprice = 100, furnitureobject ="prop_bikini_disp_05"},
            {furnitureprice = 100, furnitureobject ="prop_boxing_glove_01"},
            {furnitureprice = 100, furnitureobject ="prop_venice_counter_02"},
            {furnitureprice = 100, furnitureobject ="prop_studio_light_01"},
            {furnitureprice = 100, furnitureobject ="prop_bleachers_05"},
            {furnitureprice = 100, furnitureobject ="prop_muscle_bench_04"},
            {furnitureprice = 100, furnitureobject ="prop_suitcase_02"},
            {furnitureprice = 100, furnitureobject ="prop_dress_disp_04"},
            {furnitureprice = 100, furnitureobject ="prop_buck_spade_09"},
            {furnitureprice = 100, furnitureobject ="prop_drug_erlenmeyer"},
            {furnitureprice = 100, furnitureobject ="prop_beachflag_02"},
            {furnitureprice = 100, furnitureobject ="prop_bleachers_03"},
            {furnitureprice = 100, furnitureobject ="prop_pooltable_3b"},
            {furnitureprice = 100, furnitureobject ="prop_clothes_rail_01"},
            {furnitureprice = 100, furnitureobject ="prop_sglasss_1_lod"},
            {furnitureprice = 100, furnitureobject ="prop_front_seat_01"},
            {furnitureprice = 100, furnitureobject ="prop_scrim_02"},
            {furnitureprice = 100, furnitureobject ="prop_ice_box_01_l1"},
            {furnitureprice = 100, furnitureobject ="prop_hwbowl_seat_03b"},
            {furnitureprice = 100, furnitureobject ="prop_barbell_01"},
            {furnitureprice = 100, furnitureobject ="prop_slacks_02"},
            {furnitureprice = 100, furnitureobject ="prop_game_clock_02"},
            {furnitureprice = 100, furnitureobject ="prop_bleachers_02"},
            {furnitureprice = 100, furnitureobject ="prop_display_unit_02"},
            {furnitureprice = 100, furnitureobject ="prop_arm_wrestle_01"},
            {furnitureprice = 100, furnitureobject ="prop_beach_bag_01a"},
            {furnitureprice = 100, furnitureobject ="prop_front_seat_05"},
            {furnitureprice = 100, furnitureobject ="prop_tshirt_stand_01b"},
            {furnitureprice = 100, furnitureobject ="prop_coolbox_01"},
            {furnitureprice = 100, furnitureobject ="prop_tshirt_box_01"},
            {furnitureprice = 100, furnitureobject ="prop_suitcase_01c"},
            {furnitureprice = 100, furnitureobject ="prop_hwbowl_pseat_6x1"},
            {furnitureprice = 100, furnitureobject ="prop_barbell_02"},
            {furnitureprice = 100, furnitureobject ="prop_barbell_20kg"},
            {furnitureprice = 100, furnitureobject ="prop_table_tennis"},
            {furnitureprice = 100, furnitureobject ="prop_suitcase_01b"},
            {furnitureprice = 100, furnitureobject ="prop_game_clock_01"},
            {furnitureprice = 100, furnitureobject ="prop_front_seat_02"},
            {furnitureprice = 100, furnitureobject ="prop_vend_water_01"},
            {furnitureprice = 100, furnitureobject ="prop_gumball_01"},
            {furnitureprice = 100, furnitureobject ="prop_dart_1"},
            {furnitureprice = 100, furnitureobject ="prop_golf_bag_01c"},
            {furnitureprice = 100, furnitureobject ="prop_front_seat_06"},
            {furnitureprice = 100, furnitureobject ="prop_front_seat_07"},
            {furnitureprice = 100, furnitureobject ="prop_bikini_disp_06"},
            {furnitureprice = 100, furnitureobject ="prop_tshirt_stand_04"},
            {furnitureprice = 100, furnitureobject ="prop_dress_disp_01"},
            {furnitureprice = 100, furnitureobject ="prop_beach_lotion_02"},
            {furnitureprice = 100, furnitureobject ="prop_beachflag_le"},
            {furnitureprice = 100, furnitureobject ="prop_exer_bike_01"},
            {furnitureprice = 100, furnitureobject ="prop_ven_market_stool"},
            {furnitureprice = 100, furnitureobject ="prop_barbell_50kg"},
            {furnitureprice = 100, furnitureobject ="prop_pier_kiosk_01"},
            {furnitureprice = 100, furnitureobject ="prop_gumball_02"},
            {furnitureprice = 100, furnitureobject ="prop_dress_disp_02"},
            {furnitureprice = 100, furnitureobject ="prop_towel_shelf_01"},
            {furnitureprice = 100, furnitureobject ="prop_weight_1_5k"},
            {furnitureprice = 100, furnitureobject ="prop_cap_row_02"},
            {furnitureprice = 100, furnitureobject ="prop_dolly_02"},
            {furnitureprice = 100, furnitureobject ="prop_beach_punchbag"},
            {furnitureprice = 100, furnitureobject ="prop_punch_bag_l"},
            {furnitureprice = 100, furnitureobject ="prop_beach_dip_bars_02"},
            {furnitureprice = 100, furnitureobject ="prop_sglasses_stand_1b"},
            {furnitureprice = 100, furnitureobject ="prop_beach_sandcas_05"},
            {furnitureprice = 100, furnitureobject ="prop_dart_bd_01"},
            {furnitureprice = 100, furnitureobject ="prop_ftowel_10"},
            {furnitureprice = 100, furnitureobject ="prop_barbell_30kg"},
            {furnitureprice = 100, furnitureobject ="prop_speedball_01"},
            {furnitureprice = 100, furnitureobject ="prop_ftowel_01"},
            {furnitureprice = 100, furnitureobject ="prop_film_cam_01"},
            {furnitureprice = 100, furnitureobject ="prop_weight_2_5k"},
            {furnitureprice = 100, furnitureobject ="prop_jukebox_01"},
            {furnitureprice = 100, furnitureobject ="prop_drug_bottle"},
            {furnitureprice = 100, furnitureobject ="prop_porn_mag_03"},
            {furnitureprice = 100, furnitureobject ="prop_golf_bag_01"},
            {furnitureprice = 100, furnitureobject ="prop_weight_squat"},
            {furnitureprice = 100, furnitureobject ="prop_beachflag_01"},
            {furnitureprice = 100, furnitureobject ="prop_v_15_cars_clock"},
            {furnitureprice = 100, furnitureobject ="prop_sports_clock_01"},
            {furnitureprice = 100, furnitureobject ="prop_bikini_disp_01"},
            {furnitureprice = 100, furnitureobject ="prop_pris_bench_01"},
            {furnitureprice = 100, furnitureobject ="prop_sglasss_1b_lod"},
            {furnitureprice = 100, furnitureobject ="prop_kino_light_03"},
            {furnitureprice = 100, furnitureobject ="prop_basketball_net"},
            {furnitureprice = 100, furnitureobject ="prop_muscle_bench_03"},
            {furnitureprice = 100, furnitureobject ="prop_bleachers_01"},
            {furnitureprice = 100, furnitureobject ="prop_airhockey_01"},
            {furnitureprice = 100, furnitureobject ="prop_scrim_01"},
            {furnitureprice = 100, furnitureobject ="prop_beach_bars_01"},
            {furnitureprice = 100, furnitureobject ="prop_studio_light_03"},
            {furnitureprice = 100, furnitureobject ="prop_muscle_bench_05"},
            {furnitureprice = 100, furnitureobject ="prop_weight_rack_02"},
            {furnitureprice = 100, furnitureobject ="prop_bleachers_04_cr"},
            {furnitureprice = 100, furnitureobject ="prop_venice_counter_01"},
            {furnitureprice = 100, furnitureobject ="prop_barbell_10kg"},
            {furnitureprice = 100, furnitureobject ="prop_muscle_bench_01"},
            {furnitureprice = 100, furnitureobject ="prop_muscle_bench_02"},
            {furnitureprice = 100, furnitureobject ="prop_display_unit_01"},
            {furnitureprice = 100, furnitureobject ="prop_weight_20k"},
            {furnitureprice = 100, furnitureobject ="prop_barbell_40kg"},
            {furnitureprice = 100, furnitureobject ="prop_muscle_bench_06"},
            {furnitureprice = 100, furnitureobject ="prop_barbell_60kg"},
            {furnitureprice = 100, furnitureobject ="prop_arcade_02"},
            {furnitureprice = 100, furnitureobject ="prop_porn_mag_01"},
            {furnitureprice = 100, furnitureobject ="prop_weight_bench_02"},
            {furnitureprice = 100, furnitureobject ="prop_exer_bike_mg"},
            {furnitureprice = 100, furnitureobject ="prop_ven_market_table1"},
            {furnitureprice = 100, furnitureobject ="prop_beach_sandcas_03"},
            {furnitureprice = 100, furnitureobject ="prop_venice_counter_03"},
            {furnitureprice = 100, furnitureobject ="prop_pris_bars_01"},
            {furnitureprice = 100, furnitureobject ="prop_weight_10k"},
            {furnitureprice = 100, furnitureobject ="prop_pool_rack_02"},
            {furnitureprice = 100, furnitureobject ="prop_gumball_03"},
            {furnitureprice = 100, furnitureobject ="prop_freeweight_01"},
            {furnitureprice = 100, furnitureobject ="prop_bikini_disp_03"},
            {furnitureprice = 100, furnitureobject ="prop_dress_disp_03"},
            {furnitureprice = 100, furnitureobject ="prop_sglasses_stand_02"},
            {furnitureprice = 100, furnitureobject ="prop_barbell_80kg"},
            {furnitureprice = 100, furnitureobject ="prop_poolball_11"},
            {furnitureprice = 100, furnitureobject ="prop_a_base_bars_01"},
        }
    },
    {
        categorylabel = "Trash",
        categoryobjects = {
            {furnitureprice = 100, furnitureobject ="prop_rub_tyre_01"},
            {furnitureprice = 100, furnitureobject ="prop_rub_boxpile_02"},
            {furnitureprice = 100, furnitureobject ="prop_rub_table_02"},
            {furnitureprice = 100, furnitureobject ="prop_rub_matress_01"},
            {furnitureprice = 100, furnitureobject ="prop_rub_tyre_03"},
            {furnitureprice = 100, furnitureobject ="prop_skid_chair_01"},
            {furnitureprice = 100, furnitureobject ="prop_rub_monitor"},
            {furnitureprice = 100, furnitureobject ="prop_skid_chair_03"},
            {furnitureprice = 100, furnitureobject ="prop_rub_trainers_01"},
            {furnitureprice = 100, furnitureobject ="prop_pizza_box_03"},
            {furnitureprice = 100, furnitureobject ="prop_rub_pile_04"},
            {furnitureprice = 100, furnitureobject ="prop_rub_trolley02a"},
            {furnitureprice = 100, furnitureobject ="prop_rub_binbag_03b"},
            {furnitureprice = 100, furnitureobject ="prop_rub_cabinet03"},
            {furnitureprice = 100, furnitureobject ="prop_rub_cage01e"},
            {furnitureprice = 100, furnitureobject ="prop_rub_boxpile_04"},
            {furnitureprice = 100, furnitureobject ="prop_homeless_matress_01"},
            {furnitureprice = 100, furnitureobject ="prop_rub_boxpile_05"},
            {furnitureprice = 100, furnitureobject ="prop_rub_couch01"},
            {furnitureprice = 100, furnitureobject ="prop_rub_cabinet"},
            {furnitureprice = 100, furnitureobject ="prop_skid_chair_02"},
            {furnitureprice = 100, furnitureobject ="prop_rub_matress_02"},
            {furnitureprice = 100, furnitureobject ="prop_rub_carpart_05"},
            {furnitureprice = 100, furnitureobject ="prop_homeless_matress_02"},
            {furnitureprice = 100, furnitureobject ="prop_rub_pile_03"},
            {furnitureprice = 100, furnitureobject ="prop_rub_bike_02"},
            {furnitureprice = 100, furnitureobject ="prop_rub_litter_06"},
            {furnitureprice = 100, furnitureobject ="prop_rub_matress_04"},
            {furnitureprice = 100, furnitureobject ="prop_skid_trolley_2"},
            {furnitureprice = 100, furnitureobject ="prop_rub_cardpile_07"},
            {furnitureprice = 100, furnitureobject ="prop_rub_binbag_06"},
            {furnitureprice = 100, furnitureobject ="prop_rub_washer_01"},
            {furnitureprice = 100, furnitureobject ="prop_rub_cage01c"},
            {furnitureprice = 100, furnitureobject ="prop_rub_couch04"},
            {furnitureprice = 100, furnitureobject ="prop_rub_trolley03a"},
            {furnitureprice = 100, furnitureobject ="prop_rub_generator"},
            {furnitureprice = 100, furnitureobject ="prop_rub_bike_03"},
            {furnitureprice = 100, furnitureobject ="prop_rub_couch03"},
        }
    },
    {
        categorylabel = "Seating",
        categoryobjects = {
            {furnitureprice = 100, furnitureobject ="apa_mp_h_stn_sofa2seat_02"},
            {furnitureprice = 100, furnitureobject ="apa_mp_h_stn_sofacorn_01"},
            {furnitureprice = 100, furnitureobject ="apa_mp_h_stn_sofacorn_09"},
            {furnitureprice = 100, furnitureobject ="apa_mp_h_stn_sofacorn_10"},
            {furnitureprice = 100, furnitureobject ="apa_mp_h_yacht_sofa_02"},
            {furnitureprice = 100, furnitureobject ="v_ilev_m_sofa"},
            {furnitureprice = 100, furnitureobject ="v_res_tre_sofa"},
            {furnitureprice = 100, furnitureobject ="prop_couch_lg_08"},
            {furnitureprice = 100, furnitureobject ="apa_mp_h_stn_sofacorn_06"},
            {furnitureprice = 100, furnitureobject ="ex_mp_h_off_sofa_02"},
            {furnitureprice = 100, furnitureobject ="apa_mp_h_din_chair_04"},
            {furnitureprice = 100, furnitureobject ="apa_mp_h_din_chair_12"},
            {furnitureprice = 100, furnitureobject ="apa_mp_h_stn_chairarm_02"},
            {furnitureprice = 100, furnitureobject ="apa_mp_h_stn_chairarm_23"},
            {furnitureprice = 100, furnitureobject ="apa_mp_h_stn_chairstrip_05"},
            {furnitureprice = 100, furnitureobject ="bkr_prop_biker_boardchair01"},
            {furnitureprice = 100, furnitureobject ="hei_heist_din_chair_05"},
            {furnitureprice = 100, furnitureobject ="p_yacht_chair_01_s"},
            {furnitureprice = 100, furnitureobject ="v_res_m_l_chair1"},
            {furnitureprice = 100, furnitureobject ="v_res_tre_stool"},
            {furnitureprice = 100, furnitureobject ="prop_off_chair_04b"},
            {furnitureprice = 100, furnitureobject ="prop_table_03_chr"},
            {furnitureprice = 100, furnitureobject ="apa_mp_h_din_stool_04"},
            {furnitureprice = 100, furnitureobject ="prop_couch_lg_07"},
            {furnitureprice = 100, furnitureobject ="prop_yaught_sofa_01"},
            {furnitureprice = 100, furnitureobject ="prop_couch_sm2_07"},
            {furnitureprice = 100, furnitureobject ="prop_couch_lg_02"},
            {furnitureprice = 100, furnitureobject ="prop_couch_sm_05"},
            {furnitureprice = 100, furnitureobject ="prop_couch_lg_05"},
            {furnitureprice = 100, furnitureobject ="prop_yaught_chair_01"},
            {furnitureprice = 100, furnitureobject ="prop_couch_lg_06"},
            {furnitureprice = 100, furnitureobject ="prop_couch_lg_08"},
            {furnitureprice = 100, furnitureobject ="prop_couch_sm_06"},
            {furnitureprice = 100, furnitureobject ="prop_couch_01"},
            {furnitureprice = 100, furnitureobject ="prop_couch_03"},
            {furnitureprice = 100, furnitureobject ="prop_couch_04"},
            {furnitureprice = 100, furnitureobject ="prop_gc_chair02"},
            {furnitureprice = 100, furnitureobject ="prop_armchair_01"},
            {furnitureprice = 100, furnitureobject ="prop_couch_sm1_07"},
            {furnitureprice = 100, furnitureobject ="prop_couch_sm_07"},
            {furnitureprice = 100, furnitureobject ="prop_couch_sm_02"},
            {furnitureprice = 100, furnitureobject ="prop_table_07"},
            {furnitureprice = 100, furnitureobject ="prop_chair_01a"},
            {furnitureprice = 100, furnitureobject ="prop_bench_06"},
            {furnitureprice = 100, furnitureobject ="prop_table_04_chr"},
            {furnitureprice = 100, furnitureobject ="prop_table_08_side"},
            {furnitureprice = 100, furnitureobject ="prop_clown_chair"},
            {furnitureprice = 100, furnitureobject ="prop_proxy_chateau_table"},
            {furnitureprice = 100, furnitureobject ="prop_table_03"},
            {furnitureprice = 100, furnitureobject ="prop_table_04"},
            {furnitureprice = 100, furnitureobject ="prop_chair_02"},
            {furnitureprice = 100, furnitureobject ="prop_chateau_chair_01"},
            {furnitureprice = 100, furnitureobject ="prop_chair_05"},
            {furnitureprice = 100, furnitureobject ="prop_table_05"},
            {furnitureprice = 100, furnitureobject ="prop_table_06_chr"},
            {furnitureprice = 100, furnitureobject ="prop_chair_07"},
            {furnitureprice = 100, furnitureobject ="prop_chair_01b"},
            {furnitureprice = 100, furnitureobject ="prop_patio_lounger_3"},
            {furnitureprice = 100, furnitureobject ="prop_bench_01a"},
            {furnitureprice = 100, furnitureobject ="prop_patio_lounger1_table"},
            {furnitureprice = 100, furnitureobject ="prop_old_deck_chair"},
            {furnitureprice = 100, furnitureobject ="prop_table_03b_chr"},
            {furnitureprice = 100, furnitureobject ="prop_stool_01"},
            {furnitureprice = 100, furnitureobject ="prop_chair_04b"},
            {furnitureprice = 100, furnitureobject ="prop_bench_11"},
            {furnitureprice = 100, furnitureobject ="p_lev_sofa_s"},
            {furnitureprice = 100, furnitureobject ="v_ilev_fh_kitchenstool"},
            {furnitureprice = 100, furnitureobject ="v_ilev_hd_chair"},
            {furnitureprice = 100, furnitureobject ="v_ilev_leath_chr"},
            {furnitureprice = 100, furnitureobject ="p_v_med_p_sofa_s"},
            {furnitureprice = 100, furnitureobject ="v_ilev_m_dinechair"},
            {furnitureprice = 100, furnitureobject ="v_ilev_m_sofa"},
            {furnitureprice = 100, furnitureobject ="v_res_tre_sofa_s"},
            {furnitureprice = 100, furnitureobject ="hei_prop_hei_skid_chair"},
            {furnitureprice = 100, furnitureobject ="p_clb_officechair_s"},
            {furnitureprice = 100, furnitureobject ="p_armchair_01_s"},
            {furnitureprice = 100, furnitureobject ="p_res_sofa_l_s"},
            {furnitureprice = 100, furnitureobject ="p_soloffchair_s"},
            {furnitureprice = 100, furnitureobject ="v_ilev_p_easychair"},
            {furnitureprice = 100, furnitureobject ="p_dinechair_01_s"},
            {furnitureprice = 100, furnitureobject ="p_ilev_p_easychair_s"},
            {furnitureprice = 100, furnitureobject ="v_ilev_chair02_ped"},
            {furnitureprice = 100, furnitureobject ="prop_direct_chair_01"},
        }
    },
    {
        categorylabel = "Storage",
        categoryobjects = {
            {furnitureprice = 100, furnitureobject ="prop_crate_11c"},
            {furnitureprice = 100, furnitureobject ="prop_box_wood05a"},
            {furnitureprice = 100, furnitureobject ="prop_drop_crate_01"},
            {furnitureprice = 100, furnitureobject ="prop_sacktruck_02b"},
            {furnitureprice = 100, furnitureobject ="prop_flattruck_01c"},
            {furnitureprice = 100, furnitureobject ="v_ret_ta_box"},
            {furnitureprice = 100, furnitureobject ="v_ind_cf_chckbox2"},
            {furnitureprice = 100, furnitureobject ="prop_cardbordbox_03a"},
            {furnitureprice = 100, furnitureobject ="prop_barrel_02b"},
            {furnitureprice = 100, furnitureobject ="prop_boxpile_03a"},
            {furnitureprice = 100, furnitureobject ="prop_barrel_03a"},
            {furnitureprice = 100, furnitureobject ="prop_box_wood02a"},
            {furnitureprice = 100, furnitureobject ="prop_flattruck_01d"},
            {furnitureprice = 100, furnitureobject ="prop_crate_10a"},
            {furnitureprice = 100, furnitureobject ="prop_cardbordbox_04a"},
            {furnitureprice = 100, furnitureobject ="prop_boxpile_07d"},
            {furnitureprice = 100, furnitureobject ="prop_jerrycan_01a"},
            {furnitureprice = 100, furnitureobject ="prop_gascyl_01a"},
            {furnitureprice = 100, furnitureobject ="prop_box_ammo07b"},
            {furnitureprice = 100, furnitureobject ="prop_barrel_pile_03"},
            {furnitureprice = 100, furnitureobject ="prop_pallet_pile_01"},
            {furnitureprice = 100, furnitureobject ="prop_crate_02a"},
            {furnitureprice = 100, furnitureobject ="prop_pallet_03a"},
            {furnitureprice = 100, furnitureobject ="v_ind_cf_boxes"},
            {furnitureprice = 100, furnitureobject ="prop_barrel_pile_05"},
            {furnitureprice = 100, furnitureobject ="prop_boxpile_05a"},
            {furnitureprice = 100, furnitureobject ="prop_bucket_02a"},
            {furnitureprice = 100, furnitureobject ="v_res_filebox01"},
            {furnitureprice = 100, furnitureobject ="prop_gascyl_04a"},
            {furnitureprice = 100, furnitureobject ="prop_box_wood01a"},
            {furnitureprice = 100, furnitureobject ="prop_crate_09a"},
            {furnitureprice = 100, furnitureobject ="prop_oilcan_02a"},
            {furnitureprice = 100, furnitureobject ="v_ret_gc_box1"},
            {furnitureprice = 100, furnitureobject ="v_ind_cs_box01"},
            {furnitureprice = 100, furnitureobject ="prop_box_wood07a"},
            {furnitureprice = 100, furnitureobject ="prop_barrel_exp_01b"},
            {furnitureprice = 100, furnitureobject ="prop_bucket_01a"},
            {furnitureprice = 100, furnitureobject ="prop_box_guncase_02a"},
            {furnitureprice = 100, furnitureobject ="prop_drop_crate_01_set"},
            {furnitureprice = 100, furnitureobject ="prop_box_wood05b"},
            {furnitureprice = 100, furnitureobject ="prop_cardbordbox_02a"},
            {furnitureprice = 100, furnitureobject ="prop_box_tea01a"},
            {furnitureprice = 100, furnitureobject ="prop_box_guncase_01a"},
            {furnitureprice = 100, furnitureobject ="v_serv_plas_boxg4"},
            {furnitureprice = 100, furnitureobject ="prop_warehseshelf01"},
            {furnitureprice = 100, furnitureobject ="prop_warehseshelf03"},
            {furnitureprice = 100, furnitureobject ="prop_warehseshelf02"},
            {furnitureprice = 100, furnitureobject ="v_ind_cf_crate2"},
            {furnitureprice = 100, furnitureobject ="v_ind_cf_crate"},
            {furnitureprice = 100, furnitureobject ="prop_pallettruck_02"},
            {furnitureprice = 100, furnitureobject ="prop_barrel_01a"},
            {furnitureprice = 100, furnitureobject ="prop_boxpile_10b"},
            {furnitureprice = 100, furnitureobject ="prop_pallet_01a"},
            {furnitureprice = 100, furnitureobject ="prop_bucket_01b"},
            {furnitureprice = 100, furnitureobject ="v_serv_plastic_box"},
            {furnitureprice = 100, furnitureobject ="v_serv_abox_02"},
            {furnitureprice = 100, furnitureobject ="v_ind_cfbox"},
            {furnitureprice = 100, furnitureobject ="prop_boxpile_02c"},
            {furnitureprice = 100, furnitureobject ="v_serv_plas_boxgt2"},
            {furnitureprice = 100, furnitureobject ="prop_box_wood04a"},
            {furnitureprice = 100, furnitureobject ="prop_cratepile_02a"},
            {furnitureprice = 100, furnitureobject ="prop_boxpile_10a"},
            {furnitureprice = 100, furnitureobject ="prop_crate_11e"},
            {furnitureprice = 100, furnitureobject ="prop_barrel_pile_01"},
            {furnitureprice = 100, furnitureobject ="prop_barrel_pile_02"},
            {furnitureprice = 100, furnitureobject ="prop_crate_05a"},
            {furnitureprice = 100, furnitureobject ="prop_boxpile_01a"},
            {furnitureprice = 100, furnitureobject ="prop_box_wood08a"},
            {furnitureprice = 100, furnitureobject ="prop_cratepile_03a"},
            {furnitureprice = 100, furnitureobject ="prop_cratepile_01a"},
            {furnitureprice = 100, furnitureobject ="prop_pallet_pile_02"},
            {furnitureprice = 100, furnitureobject ="prop_sacktruck_01"},
            {furnitureprice = 100, furnitureobject ="prop_cratepile_07a"},
            {furnitureprice = 100, furnitureobject ="prop_boxpile_02b"},
            {furnitureprice = 100, furnitureobject ="prop_boxpile_06a"},
            {furnitureprice = 100, furnitureobject ="prop_shelves_02"},
            {furnitureprice = 100, furnitureobject ="prop_pallettruck_01"},
            {furnitureprice = 100, furnitureobject ="prop_boxpile_09a"},
            {furnitureprice = 100, furnitureobject ="prop_shelves_01"},
            {furnitureprice = 100, furnitureobject ="prop_flattruck_01a"},
            {furnitureprice = 100, furnitureobject ="prop_sacktruck_02a"},
            {furnitureprice = 100, furnitureobject ="v_ind_cf_crate1"},
            {furnitureprice = 100, furnitureobject ="prop_watercrate_01"},
            {furnitureprice = 100, furnitureobject ="prop_shelves_03"},
        }
    },
    {
        categorylabel = "Utility",
        categoryobjects = {
            {furnitureprice = 100, furnitureobject ="prop_tyre_rack_01"},
            {furnitureprice = 100, furnitureobject ="prop_fire_exting_3a"},
            {furnitureprice = 100, furnitureobject ="prop_fire_driser_3b"},
            {furnitureprice = 100, furnitureobject ="prop_fire_driser_1b"},
            {furnitureprice = 100, furnitureobject ="prop_fire_driser_4b"},
            {furnitureprice = 100, furnitureobject ="prop_cctv_cam_06a"},
            {furnitureprice = 100, furnitureobject ="prop_elecbox_18"},
            {furnitureprice = 100, furnitureobject ="prop_elecbox_10"},
            {furnitureprice = 100, furnitureobject ="prop_elecbox_21"},
            {furnitureprice = 100, furnitureobject ="prop_cctv_cam_04a"},
            {furnitureprice = 100, furnitureobject ="prop_telegwall_03b"},
            {furnitureprice = 100, furnitureobject ="prop_fire_exting_2a"},
            {furnitureprice = 100, furnitureobject ="prop_cctv_cam_05a"},
            {furnitureprice = 100, furnitureobject ="prop_elecbox_23"},
            {furnitureprice = 100, furnitureobject ="prop_cctv_cam_02a"},
            {furnitureprice = 100, furnitureobject ="prop_cctv_cam_01a"},
            {furnitureprice = 100, furnitureobject ="prop_elecbox_08b"},
            {furnitureprice = 100, furnitureobject ="prop_cctv_cam_07a"},
            {furnitureprice = 100, furnitureobject ="prop_fire_exting_1b"},
            {furnitureprice = 100, furnitureobject ="prop_elecbox_22"},
            {furnitureprice = 100, furnitureobject ="prop_cctv_cam_01b"},
            {furnitureprice = 100, furnitureobject ="prop_cctv_cam_04b"},
            {furnitureprice = 100, furnitureobject ="prop_cctv_cam_03a"},
            {furnitureprice = 100, furnitureobject ="prop_fire_hosereel"},
            {furnitureprice = 100, furnitureobject ="prop_fire_hosebox_01"},
            {furnitureprice = 100, furnitureobject ="prop_bikerack_2"},
            {furnitureprice = 100, furnitureobject ="prop_elecbox_20"},
            {furnitureprice = 100, furnitureobject ="prop_gas_rack01"},
            {furnitureprice = 100, furnitureobject ="prop_telegwall_01a"},
            {furnitureprice = 100, furnitureobject ="prop_fire_exting_1a"},
            {furnitureprice = 100, furnitureobject ="prop_fire_hosereel_l1"},
            {furnitureprice = 100, furnitureobject ="prop_cctv_cam_04c"},
        }
    },

    {
        categorylabel = "Tables",
        categoryobjects = {
            {furnitureprice = 100, furnitureobject ="apa_mp_h_tab_coffee_08"},
            {furnitureprice = 100, furnitureobject ="apa_mp_h_tab_coffee_07"},
            {furnitureprice = 100, furnitureobject ="ex_mp_h_tab_coffee_05"},
            {furnitureprice = 100, furnitureobject ="hei_heist_tab_coffee_06"},
            {furnitureprice = 100, furnitureobject ="apa_mp_h_din_table_06"},
            {furnitureprice = 100, furnitureobject ="ex_mp_h_din_table_05"},
            {furnitureprice = 100, furnitureobject ="ex_prop_ex_console_table_01"},
            {furnitureprice = 100, furnitureobject ="hei_prop_yah_table_03"},
            {furnitureprice = 100, furnitureobject ="hei_prop_yah_table_01"},
            {furnitureprice = 100, furnitureobject ="v_ret_fh_kitchtable"},
            {furnitureprice = 100, furnitureobject ="prop_table_02"},
            {furnitureprice = 100, furnitureobject ="prop_table_04"},
            {furnitureprice = 100, furnitureobject ="prop_table_05"},
            {furnitureprice = 100, furnitureobject ="apa_mp_h_din_table_01"},
            {furnitureprice = 100, furnitureobject ="apa_mp_h_tab_sidelrg_01"},
            {furnitureprice = 100, furnitureobject ="hei_heist_din_table_06"},
            {furnitureprice = 100, furnitureobject ="v_corp_officedesk_5"},
            {furnitureprice = 100, furnitureobject ="v_ind_dc_desk03"},
            {furnitureprice = 100, furnitureobject ="v_med_p_desk"},
            {furnitureprice = 100, furnitureobject ="v_res_d_smallsidetable"},
            {furnitureprice = 100, furnitureobject ="v_res_tre_bedsidetable"},
        }
    },
    {
        categorylabel = "Outdoor furniture",
        categoryobjects = {
            {furnitureprice = 100, furnitureobject ="prop_bbq_5"},
            {furnitureprice = 100, furnitureobject ="prop_ch2_wdfence_01"},
            {furnitureprice = 100, furnitureobject ="prop_hottub2"},
            {furnitureprice = 100, furnitureobject ="prop_fnclink_02a_sdt"},
            {furnitureprice = 100, furnitureobject ="prop_fnclink_01a"},
            {furnitureprice = 100, furnitureobject ="prop_fnclog_01b"},
            {furnitureprice = 100, furnitureobject ="prop_fncres_02c"},
            {furnitureprice = 100, furnitureobject ="prop_fncres_05b"},
        }
    },
    {
        categorylabel = "Lights",
        categoryobjects = {
            {furnitureprice = 100, furnitureobject ="apa_mp_h_floorlamp_a"},
            {furnitureprice = 100, furnitureobject ="apa_mp_h_floorlamp_c"},
            {furnitureprice = 100, furnitureobject ="apa_mp_h_lit_floorlamp_05"},
            {furnitureprice = 100, furnitureobject ="apa_mp_h_lit_floorlamp_10"},
            {furnitureprice = 100, furnitureobject ="apa_mp_h_lit_floorlamp_13"},
            {furnitureprice = 100, furnitureobject ="apa_mp_h_lit_lamptable_04"},
            {furnitureprice = 100, furnitureobject ="apa_mp_h_lit_lamptable_09"},
            {furnitureprice = 100, furnitureobject ="apa_mp_h_lit_lamptablenight_24"},
        }
    },
    {
        categorylabel = "Clutter",
        categoryobjects = {
            {furnitureprice = 100, furnitureobject ="prop_amb_beer_bottle"},
            {furnitureprice = 100, furnitureobject ="ng_proc_sodacup_01a"},
            {furnitureprice = 100, furnitureobject ="v_res_mcofcupdirt"},
            {furnitureprice = 100, furnitureobject ="ng_proc_pizza01a"},
            {furnitureprice = 100, furnitureobject ="v_res_tt_pizzaplate"},
            {furnitureprice = 100, furnitureobject ="v_ret_fh_plate1"},
            {furnitureprice = 100, furnitureobject ="v_ret_247_bread1"},
            {furnitureprice = 100, furnitureobject ="v_ret_fh_fry02"},
            {furnitureprice = 100, furnitureobject ="prop_cs_burger_01"},
            {furnitureprice = 100, furnitureobject ="prop_drink_whisky"},
            {furnitureprice = 100, furnitureobject ="p_whiskey_bottle_s"},
            {furnitureprice = 100, furnitureobject ="prop_knife"},
            {furnitureprice = 100, furnitureobject ="ng_proc_paper_news_globe"},
            {furnitureprice = 100, furnitureobject ="prop_champset"},
            {furnitureprice = 100, furnitureobject ="hei_prop_heist_box"},
            {furnitureprice = 100, furnitureobject ="apa_mp_h_acc_fruitbowl_02"},
            {furnitureprice = 100, furnitureobject ="apa_mp_h_acc_fruitbowl_01"},
            {furnitureprice = 100, furnitureobject ="bkr_prop_bkr_cashpile_01"},
            {furnitureprice = 100, furnitureobject ="bkr_prop_bkr_cashpile_06"},
            {furnitureprice = 100, furnitureobject ="bkr_prop_bkr_cash_roll_01"},
            {furnitureprice = 100, furnitureobject ="ex_mp_h_acc_candles_01"},
            {furnitureprice = 100, furnitureobject ="ex_mp_h_acc_candles_02"},
            {furnitureprice = 100, furnitureobject ="ex_prop_tv_settop_remote"},
            {furnitureprice = 100, furnitureobject ="v_res_fa_cereal01"},
            {furnitureprice = 100, furnitureobject ="v_res_mp_ashtrayb"},
            {furnitureprice = 100, furnitureobject ="v_res_tissues"},
        }
    },
}
