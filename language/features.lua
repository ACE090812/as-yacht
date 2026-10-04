-- Strings for the upkeep, marina, sea state, damage, mood and layout-sharing features.
-- Other languages fall back to English for any key missing in language/translations.lua.
local E = Language["English"]

-- sharing a yacht
E["permissionlimit"] = "You can share a yacht with at most %s people."

-- upkeep
E["upkeeppaid"] = "Upkeep paid: $%s. Covered for another %s."
E["upkeepalreadypaid"] = "Upkeep is already paid for the next period."
E["upkeepautopaid"] = "Upkeep of $%s was paid automatically."
E["upkeepsoon"] = "Upkeep of $%s is due in %s."
E["upkeepdue"] = "Your yacht's upkeep is overdue. Pay it within %s or the yacht will be locked."
E["upkeeplocked"] = "Your yacht is locked until you pay the overdue upkeep."
E["upkeepblocked"] = "This yacht cannot sail: the upkeep is overdue."
E["upkeeprepossessed"] = "Your yacht was repossessed because the upkeep was not paid."
E["upkeepcovered"] = "Covered for %s"
E["upkeepdueshort"] = "Overdue - locks in %s"
E["upkeeplockedshort"] = "Locked - unpaid"
E["upkeepbutton"] = "Pay upkeep"

-- hull condition
E["hullwarning"] = "Hull condition is down to %s%%. Repair it soon."
E["hullcritical"] = "Hull condition is critical (%s%%)!"
E["hulltoodamaged"] = "The hull is too damaged to sail. Repair it first."
E["hullfine"] = "The hull is in good shape."
E["hullrepairbusy"] = "The yacht cannot be repaired while it is being sailed."
E["hullrepaired"] = "Hull repaired for $%s."
E["hullfineshort"] = "Hull in good shape"
E["repairbutton"] = "Repair hull"
E["stormwarning"] = "Storm warning: rough seas slow the yacht and wear the hull. Consider anchoring."

-- marina / harbour master
E["harbourprompt"] = "[E] Harbour master"
E["harbournoyacht"] = "You do not own a yacht."
E["harbourmoored"] = "Your yacht must be moored in %s for this."
E["harbourmooredhere"] = "Moored here"
E["harbournotmoored"] = "Not moored here"
E["refuelbutton"] = "Refuel"
E["tankfullshort"] = "Tank full"

-- moods and layouts
E["moodset"] = "Mood set: %s."
E["layoutinvalid"] = "That layout code is not valid."
E["layoutimported"] = "Layout '%s' imported (%s pieces). Load it from the layout list."
E["layoutnothingtobuy"] = "You already own every piece this layout needs."
E["layoutfurniturelimit"] = "Your yacht can hold at most %s pieces of furniture."
E["layoutbought"] = "Bought %s pieces for $%s and placed the layout."
