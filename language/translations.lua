-- Extra languages. Any key missing here falls back to English automatically.
-- To use one, set Config.Language = "Spanish" (or "French", "German") in config.lua.
-- To add your own: copy a block below, rename it and translate the values.

local English = Language and Language["English"] or {}

local function extend(name, strings)
    Language[name] = setmetatable(strings, { __index = English })
end

extend("Spanish", {
    ["nomoneyenough"] = "No tienes suficiente dinero para comprar un yate",
    ["yachtbought"] = "Compraste un yate nuevo por $%s",
    ["alreadyhasayacht"] = "Ya tienes un yate.",
    ["nomoneyupgrade"] = "No tienes dinero suficiente para esta mejora.",
    ["nothingchanged"] = "No has cambiado nada.",
    ["yachtrenamed"] = "Yate renombrado por $%s.",
    ["appearanceupdated"] = "Aspecto actualizado por $%s.",
    ["engineupgraded"] = "Motor mejorado: %s ($%s).",
    ["storageupgraded"] = "Almacenamiento mejorado: %s ($%s).",
    ["outoffuel"] = "Te has quedado sin combustible.",
    ["lowfuel"] = "Combustible bajo.",
    ["refueled"] = "Yate repostado por $%s.",
    ["insurancebought"] = "Seguro contratado.",
    ["anchortooclose"] = "Estas demasiado cerca de otro yate.",
    ["layoutsaved"] = "Diseno '%s' guardado.",
    ["layoutloaded"] = "Diseno '%s' cargado: %s movidos, %s faltan.",
    ["tenderanchor"] = "Echa el ancla antes de llamar a tu lancha.",
})

extend("French", {
    ["nomoneyenough"] = "Vous n'avez pas assez d'argent pour acheter un yacht",
    ["yachtbought"] = "Vous avez achete un nouveau yacht pour %s $",
    ["alreadyhasayacht"] = "Vous possedez deja un yacht.",
    ["nomoneyupgrade"] = "Pas assez d'argent pour cette amelioration.",
    ["nothingchanged"] = "Rien n'a ete modifie.",
    ["yachtrenamed"] = "Yacht renomme pour %s $.",
    ["appearanceupdated"] = "Apparence mise a jour pour %s $.",
    ["engineupgraded"] = "Moteur ameliore : %s (%s $).",
    ["storageupgraded"] = "Stockage ameliore : %s (%s $).",
    ["outoffuel"] = "Vous etes en panne de carburant.",
    ["lowfuel"] = "Carburant faible.",
    ["refueled"] = "Yacht ravitaille pour %s $.",
    ["insurancebought"] = "Assurance souscrite.",
    ["anchortooclose"] = "Vous etes trop pres d'un autre yacht.",
    ["layoutsaved"] = "Agencement '%s' enregistre.",
    ["layoutloaded"] = "Agencement '%s' charge : %s deplaces, %s manquants.",
    ["tenderanchor"] = "Jetez l'ancre avant d'appeler votre annexe.",
})

extend("German", {
    ["nomoneyenough"] = "Du hast nicht genug Geld, um eine Yacht zu kaufen",
    ["yachtbought"] = "Du hast eine neue Yacht fuer $%s gekauft",
    ["alreadyhasayacht"] = "Du besitzt bereits eine Yacht.",
    ["nomoneyupgrade"] = "Nicht genug Geld fuer dieses Upgrade.",
    ["nothingchanged"] = "Nichts wurde geaendert.",
    ["yachtrenamed"] = "Yacht umbenannt fuer $%s.",
    ["appearanceupdated"] = "Aussehen aktualisiert fuer $%s.",
    ["engineupgraded"] = "Motor verbessert: %s ($%s).",
    ["storageupgraded"] = "Lager verbessert: %s ($%s).",
    ["outoffuel"] = "Dir ist der Treibstoff ausgegangen.",
    ["lowfuel"] = "Treibstoff niedrig.",
    ["refueled"] = "Yacht aufgetankt fuer $%s.",
    ["insurancebought"] = "Versicherung abgeschlossen.",
    ["anchortooclose"] = "Du bist zu nah an einer anderen Yacht.",
    ["layoutsaved"] = "Layout '%s' gespeichert.",
    ["layoutloaded"] = "Layout '%s' geladen: %s verschoben, %s fehlen.",
    ["tenderanchor"] = "Wirf den Anker, bevor du dein Beiboot rufst.",
})
