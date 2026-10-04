var yachtresourcename = (typeof GetParentResourceName === "function") ? GetParentResourceName() : "as-yacht";

// ── UI helpers ──────────────────────────────────────────────
function sliderFill(v) {
    const c = getComputedStyle(document.documentElement).getPropertyValue('--color').trim() || '#38bdf8';
    return 'linear-gradient(to right, ' + c + ' 0%, ' + c + ' ' + v + '%, rgba(255,255,255,0.18) ' + v + '%, rgba(255,255,255,0.18) 100%)';
}

function hexToRgb(hex) {
    hex = String(hex || '').replace('#', '');
    if (hex.length === 3) hex = hex.split('').map(function (c) { return c + c; }).join('');
    const n = parseInt(hex, 16);
    if (hex.length !== 6 || isNaN(n)) return null;
    return [(n >> 16) & 255, (n >> 8) & 255, n & 255].join(', ');
}

function formatMoney(n) {
    return '$' + Number(n || 0).toLocaleString();
}

function formatExtra(n) {
    return n > 0 ? '+' + formatMoney(n) : 'Included';
}

function updatePreview() {
    $('#previewUpper').text(upperText || 'Your yacht');
    $('#previewBottom').text(bottomText || 'Harbour');
}

function updatePriceLabels() {
    $('#lightprice-1').text(formatExtra(lightingPrices[1]));
    $('#lightprice-2').text(formatExtra(lightingPrices[2]));
    $('#equipprice-1').text(formatExtra(equipmentPrices[1]));
    $('#equipprice-2').text(formatExtra(equipmentPrices[2]));
}

let yachtColor = 1;
let lightType = 1;
let lightColor = 1;
let railingColor = 1;
let flag = 1;
let upperText = "";
let bottomText = "";
let equipment = 1; 

let infurnituremenu = 0;

let infurnitureownmenu = 0;

let yachtPrice = 0;

let lightingPrices = {
    1: 1000, 
    2: 500,
};
let railingPrices = {};

function buildRailingPicker(list) {
    const $p = $(".railing-picker").empty();
    (list || []).forEach(function(r) {
        railingPrices[r.id] = r.price;
        const sw = r.swatch || ["#9fb3c4", "#e6eef5"];
        const $d = $('<div></div>').attr("data-railing", r.id);
        $('<span class="metal"></span>').css("background",
            "linear-gradient(90deg," + sw[0] + "," + sw[1] + "," + sw[0] + ")").appendTo($d);
        $('<b></b>').text(r.label).appendTo($d);
        $('<small></small>').text(formatExtra(r.price)).appendTo($d);
        $d.appendTo($p);
    });
}

let buyUp = { engine: 1, storage: 1, tenders: [] };
let buyTenderPrices = {};
let buyTenderCat = {};
let buyTenderLimits = {};
let buyUpPrices = { engine: {}, storage: {} };
function upgradesPrice() {
    return (buyUpPrices.engine[buyUp.engine] || 0) + (buyUpPrices.storage[buyUp.storage] || 0) + buyUp.tenders.reduce(function (a, id) { return a + (buyTenderPrices[id] || 0); }, 0);
}
function buildBuyUpgrades(list) {
    $("#buy-upgrades-field").toggle(!!list);
    buyUp = { engine: 1, storage: 1, tenders: [] };
    const $tw = $("#bu-tenders").empty();
    buyTenderPrices = {}; buyTenderCat = {}; buyTenderLimits = (list && list.tenderlimits) || {};
    $("#bu-tenders-wrap").toggle(!!(list && list.tenders && list.tenders.length));
    if (list && list.tenders) {
        const cats = [];
        list.tenders.forEach(function (t) { if (cats.indexOf(t.category) < 0) cats.push(t.category); });
        cats.forEach(function (cat) {
            $('<div class="tender-cat"></div>').text(cat + (buyTenderLimits[cat] ? " (room for " + buyTenderLimits[cat] + ")" : "")).appendTo($tw);
            const $row = $('<div class="chips"></div>').appendTo($tw);
            list.tenders.filter(function (t) { return t.category === cat; }).forEach(function (t) {
                buyTenderPrices[t.id] = t.price; buyTenderCat[t.id] = t.category;
                $('<div class="chip tender-chip"></div>').attr("data-tender", t.id).text(t.label + " · +" + formatMoney(t.price)).appendTo($row);
            });
        });
    }
    if (!list) return;
    [["engine", "#bu-engines", list.engines], ["storage", "#bu-storages", list.storages]].forEach(function (g) {
        const key = g[0], $c = $(g[1]).empty();
        buyUpPrices[key] = {};
        (g[2] || []).forEach(function (t) {
            buyUpPrices[key][t.id] = t.price;
            const label = t.label + (t.detail ? " · " + t.detail : "") + " · " + (t.price > 0 ? "+" + formatMoney(t.price) : "Included");
            const $chip = $('<div class="chip"></div>');
            if (t.rgb) $('<span class="dot"></span>').css("background-color", "rgb(" + t.rgb.join(",") + ")").appendTo($chip);
            $chip.append(document.createTextNode(label)).attr("data-key", key).attr("data-id", t.id).toggleClass("selected", t.id === 1).appendTo($c);
        });
    });
}
$(document).on("click", "#bu-tenders .tender-chip", function () {
    const id = parseInt($(this).attr("data-tender"), 10);
    const i = buyUp.tenders.indexOf(id);
    if (i < 0) {
        const cat = buyTenderCat[id];
        const count = buyUp.tenders.filter(function (x) { return buyTenderCat[x] === cat; }).length;
        if (buyTenderLimits[cat] !== undefined && count >= buyTenderLimits[cat]) {
            toast("Your yacht only has room for " + buyTenderLimits[cat] + " in " + cat + ".", "error");
            return;
        }
    }
    if (i >= 0) buyUp.tenders.splice(i, 1); else buyUp.tenders.push(id);
    $(this).toggleClass("selected", i < 0);
    updateSelection();
    $.post('https://' + yachtresourcename + '/buypreviewtenders', JSON.stringify({ ids: buyUp.tenders }));
});
$(document).on("click", "#buy-upgrades-field .chip:not(.tender-chip)", function () {
    const key = $(this).attr("data-key");
    buyUp[key] = parseInt($(this).attr("data-id"), 10);
    $(this).siblings().removeClass("selected"); $(this).addClass("selected");
    updateSelection();
});

let equipmentPrices = {
    1: 0, 
    2: 25000, 
};

const furnitureNames = {}
const furnitureData = {};




function closeMain() {
    $("body").css("display", "none");
}

function openMain() {
    $("body").css("display", "block");
}

function objecteditorcreatorPrepareInterface() {
  let reformated1 = document.getElementById("cameraspeeddata");
  var value = (reformated1.value-reformated1.min)/(reformated1.max-reformated1.min)*100
  reformated1.style.background = sliderFill(value)  
  let reformated2 = document.getElementById("lookspeedxdata");
  var value = (reformated2.value-reformated2.min)/(reformated2.max-reformated2.min)*100
  reformated2.style.background = sliderFill(value)  
  let reformated3 = document.getElementById("lookspeedydata");
  var value = (reformated3.value-reformated3.min)/(reformated3.max-reformated3.min)*100
  reformated3.style.background = sliderFill(value)  
  let reformated4 = document.getElementById("translatesnapdata");
  var value = (reformated4.value-reformated4.min)/(reformated4.max-reformated4.min)*100
  reformated4.style.background = sliderFill(value)  
  let reformated5 = document.getElementById("rotationsnapdata");
  var value = (reformated5.value-reformated5.min)/(reformated5.max-reformated5.min)*100
  reformated5.style.background = sliderFill(value)  
}

objecteditorcreatorPrepareInterface();

document.getElementById("cameraspeeddata").oninput = function() {
  var value = (this.value-this.min)/(this.max-this.min)*100
  this.style.background = sliderFill(value)
};

document.getElementById("lookspeedxdata").oninput = function() {
  var value = (this.value-this.min)/(this.max-this.min)*100
  this.style.background = sliderFill(value)
};

document.getElementById("lookspeedydata").oninput = function() {
  var value = (this.value-this.min)/(this.max-this.min)*100
  this.style.background = sliderFill(value)
};

document.getElementById("translatesnapdata").oninput = function() {
  var value = (this.value-this.min)/(this.max-this.min)*100
  this.style.background = sliderFill(value)
};

document.getElementById("rotationsnapdata").oninput = function() {
  var value = (this.value-this.min)/(this.max-this.min)*100
  this.style.background = sliderFill(value)
};

function calculateFinalPrice() {
    const lightingPrice = lightingPrices[lightType] || 0;

    const railingPrice = railingPrices[railingColor] || 0;

    const equipmentPrice = equipmentPrices[equipment] || 0;

    const finalPrice = yachtPrice + lightingPrice + railingPrice + equipmentPrice + upgradesPrice();
    $("#pr-upg").text(formatMoney(upgradesPrice()));

    $("#pr-base").text(formatMoney(yachtPrice));
    $("#pr-light").text(formatMoney(lightingPrice));
    $("#pr-rail").text(formatMoney(railingPrice));
    $("#pr-equip").text(formatMoney(equipmentPrice));
    $("#pr-total").text(formatMoney(finalPrice));
    updatePriceLabels();
}

const resetSelection = () => {
    yachtColor = 1;
    lightType = 1;
    lightColor = 1;
    railingColor = 1;
    flag = 1;
    upperText = "";
    bottomText = "";
    equipment = 1;
    buyUp = { engine: 1, storage: 1, tenders: [] };
    $("#bu-tenders .chip").removeClass("selected");
    $.post('https://' + yachtresourcename + '/buypreviewtenders', JSON.stringify({ ids: [] }));
    $("#buy-upgrades-field .chip").removeClass("selected").filter('[data-id="1"]').addClass("selected");

    $(".color-picker div, .light-type-picker div, .light-color-picker div, .railing-picker div, .equipment-picker div").removeClass("selected");
    $("#flag-select").prop("selectedIndex", 0);
    $("#upper-text, #bottom-text").val("");

	$(".color-picker div[data-color='1'], .light-type-picker div[data-light-type='1'], .light-color-picker div[data-light-color='1'], .railing-picker div[data-railing='1'], .equipment-picker div[data-equipment='1']").addClass("selected");
	updatePreview();
	calculateFinalPrice();
	if (typeof renderFlagList === "function") { $("#flag-search").val(""); renderFlagList(); updateNameHint(); }
};

// ── Toasts ──────────────────────────────────────────────────
function toast(message, type) {
    type = type || "info";
    let box = document.getElementById("toasts");
    if (!box) {
        box = document.createElement("div");
        box.id = "toasts";
        document.documentElement.appendChild(box); // outside <body> so it shows even when menus are closed
    }
    const icons = { success: "fa-circle-check", error: "fa-circle-xmark", warning: "fa-triangle-exclamation", info: "fa-circle-info" };
    const el = $("<div>").addClass("toast-item " + type);
    el.append($("<i>").addClass("fas " + (icons[type] || icons.info)));
    el.append($("<span>").text(message));
    $(box).append(el);
    playSound(type === "error" || type === "warning" ? "error" : (type === "success" ? "success" : "click"));
    setTimeout(function () { el.addClass("out"); setTimeout(function () { el.remove(); }, 320); }, 4000);
}

const showNotification = (message, type = "warning") => toast(message, type);

// ── Sounds (tiny synthesised UI sounds) ─────────────────────
let soundsEnabled = true;
let audioCtx = null;
function playSound(kind) {
    if (!soundsEnabled) return;
    try {
        audioCtx = audioCtx || new (window.AudioContext || window.webkitAudioContext)();
        const notes = {
            click:   [[660, 0.05]],
            success: [[523, 0.09], [659, 0.09], [784, 0.16]],
            error:   [[220, 0.12], [180, 0.16]],
        }[kind] || [[660, 0.05]];
        let t = audioCtx.currentTime;
        notes.forEach(function (n) {
            const o = audioCtx.createOscillator();
            const g = audioCtx.createGain();
            o.type = "sine";
            o.frequency.value = n[0];
            g.gain.setValueAtTime(0.0001, t);
            g.gain.exponentialRampToValueAtTime(0.06, t + 0.01);
            g.gain.exponentialRampToValueAtTime(0.0001, t + n[1]);
            o.connect(g); g.connect(audioCtx.destination);
            o.start(t); o.stop(t + n[1] + 0.02);
            t += n[1];
        });
    } catch (e) { /* audio not available */ }
}

const validateSelection = () => {
    let isValid = true;

    if (yachtColor === null) {
        showNotification("Please select a yacht color.", "warning");
        isValid = false;
    }
    if (lightType === null) {
        showNotification("Please select a light type.", "warning");
        isValid = false;
    }
    if (lightColor === null) {
        showNotification("Please select a light color.", "warning");
        isValid = false;
    }
    if (railingColor === null) {
        showNotification("Please select a railing color.", "warning");
        isValid = false;
    }
    if (flag === null) {
        showNotification("Please select a flag.", "warning");
        isValid = false;
    }
    if (upperText.trim() === "") {
        showNotification("Please enter the upper text for the yacht name.", "warning");
        isValid = false;
    }
    if (bottomText.trim() === "") {
        showNotification("Please enter the bottom text for the yacht name.", "warning");
        isValid = false;
    }
    if (equipment === null) {
        showNotification("Please select an equipment option.", "warning");
        isValid = false;
    }

    return isValid;
};

// ── Furniture shop ─────────────────────────────────────────
// State: shopCategory is null (category list), a category id, "__fav" or "__recent". A search query overrides it
// and looks through every category. Favourites and recently bought pieces are remembered in localStorage.
const furnitureOrder = [];
const FAV_KEY = "asyacht_fav_furniture", RECENT_KEY = "asyacht_recent_furniture";
let shopCategory = null, shopQuery = "", shopSort = "default", shopFavOnly = false, shopRenderTimer = null;
let shopSession = { count: 0, total: 0 };

function shopLoad(key) {
    try { const v = JSON.parse(localStorage.getItem(key) || "[]"); return Array.isArray(v) ? v : []; } catch (e) { return []; }
}
function shopSave(key, value) { try { localStorage.setItem(key, JSON.stringify(value)); } catch (e) { /* storage unavailable */ } }
let shopFavs = shopLoad(FAV_KEY), shopRecent = shopLoad(RECENT_KEY);

function escapeHtml(t) { return String(t).replace(/[&<>"']/g, function (c) { return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]; }); }

function allShopItems() {
    const out = [];
    furnitureOrder.forEach(function (cat) { (furnitureData[cat] || []).forEach(function (it) { out.push(it); }); });
    return out;
}

function scheduleShopRender() {
    clearTimeout(shopRenderTimer);
    shopRenderTimer = setTimeout(renderShop, 30);
}

function addFurnitureCategory(categoryId, categoryLabel) {
    furnitureData[categoryId] = [];
    furnitureNames[categoryId] = categoryLabel;
    if (furnitureOrder.indexOf(categoryId) < 0) furnitureOrder.push(categoryId);
    scheduleShopRender();
}

function addFurniture(categoryId, furnitureId, furnitureLabel, furniturePrice) {
    if (!furnitureData[categoryId]) {
        return;
    }
    furnitureData[categoryId].push({
        id: furnitureId,
        category: categoryId,
        name: furnitureLabel,
        price: furniturePrice,
        image: 'img/objects/' + furnitureLabel + '.webp',
    });
    scheduleShopRender();
}

function shopCategoryButton(label, count, onClick, extraClass) {
    return $("<button>").addClass("category-button " + (extraClass || ""))
        .html(escapeHtml(label) + ' <small class="cat-count">' + count + '</small>')
        .click(onClick);
}

function shopItemCard(item) {
    const fav = shopFavs.indexOf(item.name) >= 0;
    const $card = $("<button>").addClass("furniture-item").attr("data-name", item.name)
        .html('<span class="fav-star' + (fav ? ' on' : '') + '" title="Favourite"><i class="fas fa-star"></i></span>' +
            '<img src="' + escapeHtml(item.image) + '" alt="' + escapeHtml(item.name) + '" onerror="this.src=\'img/default.webp\'">' +
            '<div class="furniture-name">' + escapeHtml(item.name) + '</div>' +
            '<div class="furniture-price">$' + escapeHtml(item.price) + '</div>');
    $card.find(".fav-star").on("click", function (e) {
        e.stopPropagation();
        const i = shopFavs.indexOf(item.name);
        if (i >= 0) shopFavs.splice(i, 1); else shopFavs.push(item.name);
        shopSave(FAV_KEY, shopFavs);
        $(this).toggleClass("on", i < 0);
        playSound("click");
        if (shopFavOnly || shopCategory === "__fav") renderShop();
    });
    $card.on("click", function () {
        $(".buyobjecttextname").text(item.name);
        $(".buyobjecttextprice").text('$' + item.price);
        $.post('https://' + yachtresourcename + '/addnewfurnituretohouse', JSON.stringify({
            furniturecategoryid: item.category,
            furnitureid: item.id,
        }));
    });
    return $card;
}

function sortShopItems(items) {
    const list = items.slice();
    if (shopSort === "price-asc") list.sort(function (a, b) { return a.price - b.price || a.name.localeCompare(b.name); });
    else if (shopSort === "price-desc") list.sort(function (a, b) { return b.price - a.price || a.name.localeCompare(b.name); });
    else if (shopSort === "name") list.sort(function (a, b) { return a.name.localeCompare(b.name); });
    return list;
}

function renderShop() {
    const q = shopQuery.trim().toLowerCase();
    const all = allShopItems();
    let items = null, title = "";

    if (q) {
        title = 'Results for "' + shopQuery.trim() + '"';
        items = all.filter(function (it) {
            return it.name.toLowerCase().indexOf(q) >= 0 || String(furnitureNames[it.category] || "").toLowerCase().indexOf(q) >= 0;
        });
    } else if (shopCategory === "__fav") {
        title = "Favourites";
        items = all.filter(function (it) { return shopFavs.indexOf(it.name) >= 0; });
    } else if (shopCategory === "__recent") {
        title = "Recently bought";
        items = shopRecent.map(function (n) { return all.find(function (it) { return it.name === n; }); }).filter(Boolean);
    } else if (shopCategory !== null && furnitureData[shopCategory]) {
        title = furnitureNames[shopCategory];
        items = furnitureData[shopCategory].slice();
    }

    $("#shopToolbar").toggle(items !== null);
    $("#shopSession").text(shopSession.count > 0 ? "Bought this visit: " + shopSession.count + " · $" + shopSession.total : "");

    if (items === null) {
        const $c = $("#furnitureCategories").empty().show();
        $("#furnitureList").hide();
        shopCategoryButton("Favourites", shopFavs.length, function () { shopCategory = "__fav"; renderShop(); }, "special").prepend('<i class="fas fa-star"></i> ').appendTo($c);
        shopCategoryButton("Recently bought", shopRecent.length, function () { shopCategory = "__recent"; renderShop(); }, "special").prepend('<i class="fas fa-clock-rotate-left"></i> ').appendTo($c);
        furnitureOrder.forEach(function (cat) {
            shopCategoryButton(furnitureNames[cat], (furnitureData[cat] || []).length, function () { showFurnitureList(cat); }).attr("data-category", cat).appendTo($c);
        });
        return;
    }

    if (shopFavOnly) items = items.filter(function (it) { return shopFavs.indexOf(it.name) >= 0; });
    items = sortShopItems(items);

    $("#furnitureCategories").hide();
    $("#furnitureList").show();
    $("#categoryName").text(title + " (" + items.length + ")");
    const $grid = $("#furnitureItems").empty();
    if (!items.length) {
        $('<div class="shop-empty"></div>').text(shopCategory === "__fav" ? "Tap the star on a piece to add it here." : (shopCategory === "__recent" ? "Nothing bought yet." : "No pieces found.")).appendTo($grid);
        return;
    }
    items.forEach(function (it) { $grid.append(shopItemCard(it)); });
}

function removeFurnitureItemById(furnitureId) {
    const itemToRemove = $("#furnitureownItems").find(`.furnitureown-item[data-id="${furnitureId}"]`);
    
    if (itemToRemove.length > 0) {
        itemToRemove.remove();
    } else {
    }
}

function addPlayerPermissions(playerId, playerName, permissions) {
    const playersList = $(".playerspermissions-list");

    const playerManagementDiv = $("<div>")
        .addClass("playermanagment")
        .attr("data-player-id", playerId);

    const playerNameSpan = $("<span>").addClass("player-name").text(playerName);

    const permissionsDiv = $("<div>").addClass("permissions");

    const permissionLabels = [
        { name: "yacht_control", text: "Yacht Control", checked: permissions.yacht_control },
        { name: "door_access", text: "Door Access", checked: permissions.door_access },
        { name: "furniture_management", text: "Furniture Management", checked: permissions.furniture_management },
        { name: "storage_access", text: "Storage Access", checked: permissions.storage_access },
        { name: "wardrobe_access", text: "Wardrobe Access", checked: permissions.wardrobe_access },
    ];

    permissionLabels.forEach(permission => {
        const permissionLabel = $("<label>").addClass("switch");
        const permissionCheckbox = $("<input>")
            .attr("type", "checkbox")
            .addClass("permission")
            .attr("data-permission", permission.name)
            .prop("checked", permission.checked)
            .on("change", function () {
                permissions[permission.name] = $(this).prop("checked");
            });
        const permissionSlider = $("<span>").addClass("slider");
        const permissionText = $("<span>").addClass("permission-text").text(permission.text);

        permissionLabel.append(permissionCheckbox, permissionSlider, permissionText);
        permissionsDiv.append(permissionLabel);
    });

    const savePermissionsButton = $("<button>")
        .addClass("save-permissions-button")
        .html('<i class="fas fa-save"></i> Save Permissions')
        .click(() => {
			let yachtControl = permissions.yacht_control || false;
			let doorAccess = permissions.door_access || false;
			let furnitureManagement = permissions.furniture_management || false;
			let storageAccess = permissions.storage_access || false;
			let wardrobeAccess = permissions.wardrobe_access || false;
            $.post(`https://${yachtresourcename}/changepermissions`, JSON.stringify({
                playeriddata: playerId,
				yachtcontroldata: yachtControl,
				dooraccessdata: doorAccess,
				furnituremanagmentdata: furnitureManagement,
				storageaccessdata: storageAccess,
				wardrobeaccessdata: wardrobeAccess,
            }));
        });		

    const deletePlayerButton = $("<button>")
        .addClass("delete-player-button")
        .html('<i class="fas fa-trash"></i> Delete Player')
        .click(() => {
            $.post(`https://${yachtresourcename}/removepermission`, JSON.stringify({
                playeriddata: playerId,
            }));
            playerManagementDiv.remove(); 
        });

    playerManagementDiv.append(playerNameSpan, permissionsDiv, savePermissionsButton, deletePlayerButton);

    playersList.append(playerManagementDiv);
}


window.addEventListener('message', function (event) {

	var item = event.data;
	
	if (item.message == "infonotifyshow") {
		document.getElementsByClassName("infonotifytext")[0].innerHTML = item.infonotifytext;
		openMain();
		$("#infonotifyshow").show();	
	}	
	
	if (item.message == "yachtbuyshow") {
		nameRules = item.namerules || nameRules;
		$("#upper-text, #bottom-text").attr("maxlength", nameRules.maxLength);
		paymentMethods = (item.payment && item.payment.methods) || paymentMethods;
		payment = (item.payment && item.payment.default) || paymentMethods[0];
		soundsEnabled = item.sounds !== false;
		previewTime = 0; previewWeather = 0; purchaseBusy = false;
		$("#confirm-modal").removeClass("open");
		buildPreviewControls(item);
		buildSpecs(item.specs);
		buildRailingPicker(item.railings);
		buildBuyUpgrades(item.buyupgrades);
		openMain();
		resetSelection();
		yachtPrice = item.yachtprice;
		lightingPrices[1] = item.yachtlightingprice1;
		lightingPrices[2] = item.yachtlightingprice2;
		equipmentPrices[1] = item.yachtequipmentprice1;
		equipmentPrices[2] = item.yachtequipmentprice2;
		calculateFinalPrice();
		buildPayPicker();
		$("#yachtbuyshow").show();
	}
	
	if (item.message == "yachtfurnitureshow") {
		shopCategory = null; shopQuery = ""; shopFavOnly = false; shopSession = { count: 0, total: 0 };
		furnitureOrder.length = 0;
		Object.keys(furnitureData).forEach(function (k) { delete furnitureData[k]; delete furnitureNames[k]; });
		$("#searchInput").val(""); $("#shopFavOnly").removeClass("selected");
		infurnituremenu = 1;
		$("#furnitureCategories").empty();
		$("#furnitureItems").empty();
		renderShop();
		openMain();
		$("#furnitureMenu").show();
	}

	if (item.message == "furniturepurchased") {
		shopSession.count += 1;
		shopSession.total += Number(item.price) || 0;
		shopRecent = [item.name].concat(shopRecent.filter(function (n) { return n !== item.name; })).slice(0, 12);
		shopSave(RECENT_KEY, shopRecent);
		$("#shopSession").text("Bought this visit: " + shopSession.count + " · $" + shopSession.total);
	}		

	if (item.message == "addfurniturecategory") {
		addFurnitureCategory(item.categoryid, item.categorylabel);
	}	
    if (item.message == "addfurniture") {
        addFurniture(item.categoryid, item.furnitureid, item.furniturelabel, item.furnitureprice);
    }		

	if (item.message == "objecteditorposshow") {		
		$("#cameraspeeddata").val(""); 
		$("#lookspeedxdata").val(""); 
		$("#lookspeedydata").val(""); 
		$("#translatesnapdata").val(""); 
		$("#rotationsnapdata").val(""); 
		objecteditorcreatorPrepareInterface();
		$("#posmoretranslate").addClass("active");
		$("#posmorerotation").removeClass("active");
		$("#spacebuttonworld").addClass("active");
		$("#spacebuttonlocal").removeClass("active");		
		$("#objecteditorposshow").show();	
		$("#buttonsfurnitureeditshow").hide();	
		$("#buttonsfurniturebuyshow").show();	
		openMain();
	}		
	
	if (item.message == "objecteditorownposshow") {		
		$("#cameraspeeddata").val(""); 
		$("#lookspeedxdata").val(""); 
		$("#lookspeedydata").val(""); 
		$("#translatesnapdata").val(""); 
		$("#rotationsnapdata").val(""); 
		objecteditorcreatorPrepareInterface();
		$("#posmoretranslate").addClass("active");
		$("#posmorerotation").removeClass("active");
		$("#spacebuttonworld").addClass("active");
		$("#spacebuttonlocal").removeClass("active");		
		$("#objecteditorposshow").show();	
		$("#buttonsfurnitureeditshow").show();	
		$("#buttonsfurniturebuyshow").hide();	
		openMain();
	}			

	if (item.message == "yachtfurnitureownshow") {
		infurnitureownmenu = 1;
		$("#furnitureownItems").empty();
		openMain();
		$("#furnitureownMenu").show();
	}		

    if (item.message == "addfurnitureown") {
		const furnitureItem = $("<button>")
			.addClass("furnitureown-item")
			.attr("data-id", item.furnitureid)
			.html(`
				<img src="${item.furnitureimage}" alt="${item.furnitureobjectname}" onerror="this.src='img/default.webp'">
				<div class="furnitureown-name">${item.furnitureobjectname}</div>
			`)
			.click(() => {
				$(".furnitureobjecttextname").text(item.furnitureobjecttextname);
				$.post('https://'+yachtresourcename+'/editfurniture', JSON.stringify({
					furnitureid: item.furnitureid,
				}));
			});

		$("#furnitureownItems").append(furnitureItem);	
    }		

	if (item.message == "yachtmanagmentshow") {
		openMain();
		$("#showYachtActions").show();
		$("#showYachtFurniture").show();
		$("#showYachtManagment").show();
		$("#yachtTransferMenu").hide();
		$("#playersWithPermissionsMenu").hide();
		$("#addPermissionsMenu").hide();
		$("#mainMenuManagment").show();
	}		

	if (item.message == "yachtmanagment2show") {
		openMain();
		$("#showYachtActions").hide();
		$("#showYachtFurniture").show();
		$("#showYachtManagment").hide();
		$("#yachtTransferMenu").hide();
		$("#playersWithPermissionsMenu").hide();
		$("#addPermissionsMenu").hide();
		$("#mainMenuManagment").show();
	}		

	if (item.message == "yachtmanagmenthide") {
		$("#yachtTransferMenu").hide();
		$("#playersWithPermissionsMenu").hide();
		$("#addPermissionsMenu").hide();		
		$("#mainMenuManagment").hide();
	}		

	if (item.message == "removeobjectfromfurniturelist") {
		removeFurnitureItemById(item.furnitureid);
	}
	
	if (item.message == "yachtmanagmentaddpermissionsshow") {
		$(".playersaddnew-list").empty();
		openMain();
		$("#mainMenuManagment").hide();
		$("#addPermissionsMenu").show();
	}		

    if (item.message == "yachtmanagmentaddplayer") {
		const playersList = $(".playersaddnew-list");

		const playerManagementDiv = $("<div>").addClass("playermanagment");
		const playerNameSpan = $("<span>").addClass("player-name").text(item.playername);

		const addPermissionButton = $("<button>")
			.addClass("add-permission-button")
			.html('<i class="fas fa-plus"></i> Add Permissions')
			.click(() => {
				$.post('https://'+yachtresourcename+'/addplayerpermission', JSON.stringify({
					playeriddata: item.playeriddata,
				}));
			});

		playerManagementDiv.append(playerNameSpan, addPermissionButton);

		playersList.append(playerManagementDiv);
    }		

	if (item.message == "yachtmanagmentaddpermissionschangeshow") {
		$(".playerspermissions-list").empty();
		openMain();
		$("#mainMenuManagment").hide();
		$("#yachtTransferMenu").hide();
		$("#addPermissionsMenu").hide();		
		$("#playersWithPermissionsMenu").show();
	}		

    if (item.message == "yachtmanagmentaddplayerchange") {
		addPlayerPermissions(item.playerid, item.playername, {
			yacht_control: item.yachtcontrol,
			door_access: item.dooraccess,
			furniture_management: item.furnituremanagment,
			storage_access: item.storageaccess,
			wardrobe_access: item.wardrobeaccess,
		});
    }		
	
	if (item.message == "yachtmanagmenttransfershow") {
		$(".playerstransfer-list").empty();
		openMain();
		$("#mainMenuManagment").hide();
		$("#yachtTransferMenu").show();
	}		

    if (item.message == "yachtmanagmenttransferaddplayer") {
		const playersList = $(".playerstransfer-list");

		const playerManagementDiv = $("<div>")
			.addClass("playermanagment");

		const playerNameSpan = $("<span>")
			.addClass("player-name")
			.text(item.playername);

		const transferYachtButton = $("<button>")
			.addClass("transfer-yacht-button")
			.html('<i class="fas fa-exchange-alt"></i> Transfer Yacht')
			.click(() => {
				$.post(`https://${yachtresourcename}/transferplayeryacht`, JSON.stringify({
					playeriddata: item.playeriddata,
				}));
			});

		playerManagementDiv.append(playerNameSpan, transferYachtButton);

		playersList.append(playerManagementDiv);
    }		
	
	if (item.message == "buybalances") {
		balances = { cash: item.cash, bank: item.bank };
		updatePurchaseState();
	}

	if (item.message == "buyrejected") {
		closeConfirm();
	}

	if (item.message == "toast") {
		toast(item.text, item.type);
	}

	if (item.message == "hidebuymenu") {
		$("#confirm-modal").removeClass("open");
		$("#yachtbuyshow").hide();
	}
	
	if (item.message == "hide") {
		$("#infonotifyshow").hide();	
	}	
	
	if (item.message == "hideobjecteditor") {
		$("#objecteditorposshow").hide();	
	}		
	
	if (item.message == "hidefurnitureshop") {
		infurnituremenu = 0;
		$("#objecteditorposshow").hide();	
		$("#furnitureMenu").hide();	
	}	


	if (item.message == "hidefurnitureown") {
		infurnitureownmenu = 0;
		$("#objecteditorposshow").hide();	
		$("#furnitureownMenu").hide();	
	}		

	if (item.message == "hottubseatshow") {
		openMain();
		$("#seatshow").show();
	}	

	if (item.message == "hidehottubseat") {
		$("#seatshow").hide();
	}				
	
	if (item.message == "updateinterfacedata") {
		yachtresourcename = item.yachtresourcenamedata;
		let root = document.documentElement;
		const rgb = hexToRgb(item.interfacecolordata);
		if (rgb) {
			root.style.setProperty('--color', item.interfacecolordata);
			root.style.setProperty('--color-rgb', rgb);
		}
	}		
});

document.onkeyup = function (data) {
	if (data.which == 27) {
		if (infurnituremenu == 1) {
			$.post('https://'+yachtresourcename+'/yachtfurnitureclose', JSON.stringify({}));
		}
		if (infurnitureownmenu == 1) {
			$.post('https://'+yachtresourcename+'/yachtfurnitureeditclose', JSON.stringify({}));
		}
	}
};

$("#posmoretranslate").click(function () {
	$(this).addClass("active");
	$("#posmorerotation").removeClass("active");
	$.post('https://'+yachtresourcename+'/objecteditorcreatorchangemode', JSON.stringify({
		modetype: "translate"
	})); 		
});

$("#posmorerotation").click(function () {
	$(this).addClass("active");
	$("#posmoretranslate").removeClass("active");
	$.post('https://'+yachtresourcename+'/objecteditorcreatorchangemode', JSON.stringify({
		modetype: "rotate"
	})); 	
});

$("#spacebuttonworld").click(function () {
	$(this).addClass("active");
	$("#spacebuttonlocal").removeClass("active");
	$.post('https://'+yachtresourcename+'/objecteditorcreatorchangespace', JSON.stringify({
		spacetype: "world"
	})); 	
});

$(".createobjecteditorcreatorbutton").click(function () {
	$.post('https://'+yachtresourcename+'/furnituresaveobject', JSON.stringify({}));
});

$(".createobjecteditordeletebutton").click(function () {
	$.post('https://'+yachtresourcename+'/furnitureremoveobject', JSON.stringify({}));
});

$("#spacebuttonlocal").click(function () {
	$(this).addClass("active");
	$("#spacebuttonworld").removeClass("active");
	$.post('https://'+yachtresourcename+'/objecteditorcreatorchangespace', JSON.stringify({
		spacetype: "local"
	})); 	
});

$(".createobjecteditorbuybutton").click(function () {
	$.post('https://'+yachtresourcename+'/furniturebuyobject', JSON.stringify({}));
});

function cameraspeedchange(e) {
	$.post('https://'+yachtresourcename+'/objecteditorcreatorspeedchange', JSON.stringify({
		speedtype: "camera",
		speeddata: e.value
	})); 
}

function lookspeedxchange(e) {
	$.post('https://'+yachtresourcename+'/objecteditorcreatorspeedchange', JSON.stringify({
		speedtype: "lookx",
		speeddata: e.value
	})); 
}

function lookspeedychange(e) {
	$.post('https://'+yachtresourcename+'/objecteditorcreatorspeedchange', JSON.stringify({
		speedtype: "looky",
		speeddata: e.value
	})); 
}

function translatesnapchange(e) {
	$.post('https://'+yachtresourcename+'/objecteditorcreatorsnapchange', JSON.stringify({
		snaptype: "translate",
		snapdata: e.value
	})); 
}

function rotationsnapchange(e) {
	$.post('https://'+yachtresourcename+'/objecteditorcreatorsnapchange', JSON.stringify({
		snaptype: "rotate",
		snapdata: e.value
	})); 
}

function showCategories() {
    shopCategory = null;
    if (shopQuery) { shopQuery = ""; $("#searchInput").val(""); }
    renderShop();
}

function showFurnitureList(category) {
    shopCategory = category;
    renderShop();
}

function searchFurniture(query) {
    shopQuery = query || "";
    renderShop();
}

$("#searchInput").on("input", function () {
    searchFurniture($(this).val());
});
$("#shopSort").on("change", function () { shopSort = $(this).val(); renderShop(); });
$("#shopFavOnly").on("click", function () {
    shopFavOnly = !shopFavOnly;
    $(this).toggleClass("selected", shopFavOnly);
    renderShop();
});

function searchFurnitureown(query) {
    const lowerCaseQuery = query.toLowerCase();

    $(".furnitureown-item").hide();

    $(".furnitureown-item").each(function () {
        const itemName = $(this).find(".furnitureown-name").text().toLowerCase();
        if (itemName.includes(lowerCaseQuery)) {
            $(this).show();
        }
    });
}

$("#searchownInput").on("input", function () {
    const query = $(this).val();
    searchFurnitureown(query);
});

$("#backButton").click(showCategories);

const updateSelection = () => {
	calculateFinalPrice();
	if (typeof updatePurchaseState === "function") updatePurchaseState();
};

$(".color-picker div").on("click", function() {
    $(".color-picker div").removeClass("selected");
    $(this).addClass("selected");
    yachtColor = $(this).attr("data-color");
    updateSelection();
    $.post('https://'+yachtresourcename+'/buyyachtchangecolor', JSON.stringify({
        yachtcolorddata: yachtColor,
    }));
});

$(".light-type-picker div").on("click", function() {
    $(".light-type-picker div").removeClass("selected");
    $(this).addClass("selected");
    lightType = $(this).attr("data-light-type");
    updateSelection();
    $.post('https://'+yachtresourcename+'/buyyachtchangelight', JSON.stringify({
        ligthtcolorcategorydata: lightType,
        ligthtcolordata: lightColor,
    }));
});

$(".light-color-picker div").on("click", function() {
    $(".light-color-picker div").removeClass("selected");
    $(this).addClass("selected");
    lightColor = $(this).attr("data-light-color");
    updateSelection();
    $.post('https://'+yachtresourcename+'/buyyachtchangelight', JSON.stringify({
        ligthtcolorcategorydata: lightType,
        ligthtcolordata: lightColor,
    }));
});

$(document).on("click", ".railing-picker div", function() {
    $(".railing-picker div").removeClass("selected");
    $(this).addClass("selected");
    railingColor = parseInt($(this).attr("data-railing"), 10) || 1;
    updateSelection();
    $.post('https://'+yachtresourcename+'/buyyachtchangerailing', JSON.stringify({
        railingdata: railingColor,
    }));
});

$(".equipment-picker div").on("click", function() {
    $(".equipment-picker div").removeClass("selected");
    $(this).addClass("selected");
    equipment = $(this).attr("data-equipment");
    updateSelection();
});

$("#flag-select").on("change", function() {
    flag = $(this).val();
    updateSelection();
    $.post('https://'+yachtresourcename+'/buyyachtchangeflag', JSON.stringify({
        flagdata: flag,
    }));
});

$("#upper-text").on("input", function() {
    upperText = $(this).val();
    updatePreview();
    updateSelection();
    $.post('https://'+yachtresourcename+'/buyyachtchangename', JSON.stringify({
        uppertextdata: upperText,
        bottomtextdata: bottomText,
    }));
});

$("#bottom-text").on("input", function() {
    bottomText = $(this).val();
    updatePreview();
    updateSelection();
    $.post('https://'+yachtresourcename+'/buyyachtchangename', JSON.stringify({
        uppertextdata: upperText,
        bottomtextdata: bottomText,
    }));
});

$("#purchase-yacht").on("click", function() {
    if (validateSelection()) {
        openConfirm();
    }
});

$("#close-menu").on("click", function() {
    resetSelection(); 
	$.post('https://'+yachtresourcename+'/closebuymenu', JSON.stringify({}));
});

$("#change-camera").on("click", function() {
    $.post('https://'+yachtresourcename+'/buycamerachange', JSON.stringify({}));
});


// ── Buy menu: name rules, payment, flags, presets, preview ─────
let nameRules = { minLength: 1, maxLength: 24, blockedWords: [] };
let payment = "cash";
let paymentMethods = ["cash", "bank"];
let balances = { cash: 0, bank: 0 };
let previewTime = 0;
let previewWeather = 0;
let purchaseBusy = false;

function currentTotal() {
    return yachtPrice + (lightingPrices[lightType] || 0) + (railingPrices[railingColor] || 0) + (equipmentPrices[equipment] || 0) + upgradesPrice();
}

function nameProblem() {
    const words = nameRules.blockedWords || [];
    const all = (upperText + " " + bottomText).toLowerCase();
    for (let i = 0; i < words.length; i++) {
        if (words[i] && all.indexOf(String(words[i]).toLowerCase()) !== -1) return "That name is not allowed.";
    }
    const u = upperText.trim().length, b = bottomText.trim().length;
    if ((u > 0 && u < nameRules.minLength) || (b > 0 && b < nameRules.minLength)) {
        return "Each line needs at least " + nameRules.minLength + " character(s).";
    }
    return "";
}

function updateNameHint() {
    const problem = nameProblem();
    const $h = $("#name-hint");
    $h.toggleClass("error", !!problem);
    $h.html(problem ? '<span>' + problem + '</span>' :
        '<span>' + upperText.length + '/' + nameRules.maxLength + ' &nbsp;·&nbsp; ' + bottomText.length + '/' + nameRules.maxLength + '</span>');
    $("#upper-text, #bottom-text").toggleClass("invalid", !!problem);
    return !problem;
}

function updatePurchaseState() {
    const total = currentTotal();
    const enough = (balances[payment] || 0) >= total;
    $("#purchase-yacht").toggleClass("disabled", !enough)
        .html(enough ? '<i class="fas fa-check"></i> Purchase yacht' : '<i class="fas fa-lock"></i> Not enough in ' + payment);
    $("#pay-picker div").each(function () {
        const m = $(this).attr("data-pay");
        $(this).find("small").text(formatMoney(balances[m] || 0)).toggleClass("low", (balances[m] || 0) < total);
    });
    return enough;
}

function buildPayPicker() {
    const $p = $("#pay-picker").empty();
    paymentMethods.forEach(function (m) {
        const $d = $('<div></div>').attr("data-pay", m);
        $('<b></b>').text(m).appendTo($d);
        $('<small></small>').appendTo($d);
        if (m === payment) $d.addClass("selected");
        $d.appendTo($p);
    });
    updatePurchaseState();
}

$(document).on("click", "#pay-picker div", function () {
    payment = $(this).attr("data-pay");
    $("#pay-picker div").removeClass("selected");
    $(this).addClass("selected");
    updatePurchaseState();
});

// Flags (searchable list built from the hidden <select>)
const flagOptions = [];
$("#flag-select option").each(function () { flagOptions.push({ id: String($(this).val()), name: $(this).text() }); });

function renderFlagList() {
    const q = ($("#flag-search").val() || "").toLowerCase();
    const $l = $("#flag-list").empty();
    let shown = 0;
    flagOptions.forEach(function (f) {
        if (q && f.name.toLowerCase().indexOf(q) === -1) return;
        shown++;
        $('<div class="flag-item"></div>').attr("data-flag", f.id).toggleClass("selected", f.id === String(flag))
            .append($("<span>").text(f.name)).appendTo($l);
    });
    if (!shown) $l.append('<div class="flag-empty">No flags found</div>');
    const sel = $l.find(".selected")[0];
    if (sel && sel.scrollIntoView) sel.scrollIntoView({ block: "nearest" });
}

$("#flag-search").on("input", renderFlagList);
$(document).on("click", ".flag-item", function () {
    $("#flag-select").val($(this).attr("data-flag")).trigger("change");
});
$("#flag-select").on("change", function () { renderFlagList(); });

// Preview chips (time, weather, camera)
function buildChips(containerId, labels, withAuto, selectedIdx, onPick) {
    const $c = $(containerId).empty();
    const items = withAuto ? ["Auto"].concat(labels || []) : (labels || []);
    items.forEach(function (label, i) {
        const idx = withAuto ? i : i + 1;
        $('<div class="chip"></div>').text(label).attr("data-idx", idx)
            .toggleClass("selected", withAuto && idx === selectedIdx).appendTo($c);
    });
    $c.off("click").on("click", ".chip", function () {
        const idx = parseInt($(this).attr("data-idx"), 10);
        if (isNaN(idx)) return;
        if (withAuto) { $c.find(".chip").removeClass("selected"); $(this).addClass("selected"); }
        onPick(idx);
    });
}

function buildPreviewControls(item) {
    buildChips("#time-chips", item.timelist, true, 0, function (idx) {
        previewTime = idx;
        $.post('https://' + yachtresourcename + '/buypreviewenv', JSON.stringify({ time: idx }));
    });
    buildChips("#weather-chips", item.weatherlist, true, 0, function (idx) {
        previewWeather = idx;
        $.post('https://' + yachtresourcename + '/buypreviewenv', JSON.stringify({ weather: idx }));
    });
    buildChips("#cam-chips", item.camlabels, false, 0, function (idx) {
        $.post('https://' + yachtresourcename + '/buycamerapreset', JSON.stringify({ index: idx }));
    });
    $('<div class="chip" id="tour-chip"><i class="fas fa-play"></i> Tour</div>').appendTo("#cam-chips");
}

function buildSpecs(specs) {
    const $s = $("#specs-card").empty();
    (specs || []).forEach(function (sp) {
        const $d = $('<div class="spec"></div>');
        $d.append($("<i>").addClass("fas " + sp.icon));
        const $t = $("<div></div>").text(sp.label);
        $t.prepend($("<b>").text(sp.value));
        $d.append($t).appendTo($s);
    });
}

// Saved designs (kept in the browser profile of the game client)
const PRESET_KEY = "asyacht_presets";
let presetMemory = [];
function loadPresets() {
    try { return JSON.parse(localStorage.getItem(PRESET_KEY) || "[]") || []; } catch (e) { return presetMemory; }
}
function storePresets(list) {
    presetMemory = list;
    try { localStorage.setItem(PRESET_KEY, JSON.stringify(list)); } catch (e) { /* storage unavailable */ }
}

function currentDesign() {
    return { yachtColor: String(yachtColor), lightType: String(lightType), lightColor: String(lightColor),
        railing: String(railingColor), flag: String(flag), equipment: String(equipment), upper: upperText, bottom: bottomText };
}

function applyDesign(d) {
    $(".color-picker div[data-color='" + d.yachtColor + "']").trigger("click");
    $(".light-type-picker div[data-light-type='" + d.lightType + "']").trigger("click");
    $(".light-color-picker div[data-light-color='" + d.lightColor + "']").trigger("click");
    $(".railing-picker div[data-railing='" + d.railing + "']").trigger("click");
    $(".equipment-picker div[data-equipment='" + d.equipment + "']").trigger("click");
    $("#flag-select").val(String(d.flag)).trigger("change");
    $("#upper-text").val(d.upper || "").trigger("input");
    $("#bottom-text").val(d.bottom || "").trigger("input");
}

function renderPresets() {
    const $c = $("#preset-chips").empty();
    loadPresets().forEach(function (p, i) {
        const $chip = $('<div class="chip"></div>').attr("data-i", i);
        $("<span>").text(p.name).appendTo($chip);
        $('<i class="fas fa-xmark" title="Delete"></i>').attr("data-del", i).appendTo($chip);
        $chip.appendTo($c);
    });
}

$("#save-preset").on("click", function () {
    const list = loadPresets();
    if (list.length >= 6) { toast("You can save up to 6 designs. Delete one first.", "warning"); return; }
    const d = currentDesign();
    list.push({ name: (d.upper || "Design " + (list.length + 1)).substring(0, 14), d: d });
    storePresets(list);
    renderPresets();
    toast("Design saved.", "success");
});

$(document).on("click", "#preset-chips .chip", function (e) {
    const list = loadPresets();
    const del = $(e.target).attr("data-del");
    if (del !== undefined) {
        list.splice(parseInt(del, 10), 1);
        storePresets(list);
        renderPresets();
        return;
    }
    const p = list[parseInt($(this).attr("data-i"), 10)];
    if (p) applyDesign(p.d);
});

// Random + reset
function pickRandom($els) { return $els.eq(Math.floor(Math.random() * $els.length)); }

$("#random-design").on("click", function () {
    pickRandom($(".color-picker div")).trigger("click");
    pickRandom($(".light-type-picker div")).trigger("click");
    pickRandom($(".light-color-picker div")).trigger("click");
    pickRandom($(".railing-picker div")).trigger("click");
    pickRandom($(".equipment-picker div")).trigger("click");
    const f = flagOptions[Math.floor(Math.random() * flagOptions.length)];
    if (f) $("#flag-select").val(f.id).trigger("change");
});

$("#reset-design").on("click", function () {
    applyDesign({ yachtColor: "1", lightType: "1", lightColor: "1", railing: "1", equipment: "1", flag: "1", upper: "", bottom: "" });
    $("#flag-search").val("");
    renderFlagList();
});

// Confirmation step
function openConfirm() {
    if (!updateNameHint()) { toast(nameProblem(), "error"); return; }
    if (!updatePurchaseState()) { toast("Not enough money in your " + payment + " account.", "error"); return; }
    const flagName = (flagOptions.filter(function (f) { return f.id === String(flag); })[0] || {}).name || "";
    const railing = $(".railing-picker div.selected b").text();
    const rows = [
        ["Yacht", formatMoney(yachtPrice)],
        ["Lighting (type " + lightType + ")", formatMoney(lightingPrices[lightType] || 0)],
        ["Railing (" + railing + ")", formatMoney(railingPrices[railingColor] || 0)],
        ["Equipment", formatMoney(equipmentPrices[equipment] || 0)],
        ["Hull colour", "#" + yachtColor],
        ["Flag", flagName],
    ];
    const $r = $("#confirm-rows").empty();
    rows.forEach(function (r) { $("<div>").append($("<span>").text(r[0])).append($("<span>").text(r[1])).appendTo($r); });
    $("#confirm-name").text((upperText + " " + bottomText).trim());
    $("#confirm-total").text(formatMoney(currentTotal()));
    $("#confirm-pay").text("Paid from " + payment + ". Balance after purchase: " + formatMoney((balances[payment] || 0) - currentTotal()));
    $("#confirm-ok, #confirm-cancel").removeClass("busy");
    $("#confirm-modal").addClass("open");
}

function closeConfirm() { $("#confirm-modal").removeClass("open"); purchaseBusy = false; }

$("#confirm-cancel").on("click", closeConfirm);
$("#confirm-ok").on("click", function () {
    if (purchaseBusy) return;
    purchaseBusy = true;
    $("#confirm-ok, #confirm-cancel").addClass("busy");
    $.post('https://' + yachtresourcename + '/buyyacht', JSON.stringify({
        yachtcolorddata: yachtColor,
        ligthtcolorcategorydata: lightType,
        ligthtcolordata: lightColor,
        railingdata: railingColor,
        flagdata: flag,
        uppertextdata: upperText,
        bottomtextdata: bottomText,
        equipmentdata: equipment,
        paymentdata: payment,
        engine: buyUp.engine, storage: buyUp.storage, tenders: buyUp.tenders,
    }));
});

// UI click sound for anything interactive inside the buy menu
$(document).on("click", "#yachtbuyshow .color-picker div, #yachtbuyshow .light-type-picker div, #yachtbuyshow .light-color-picker div, #yachtbuyshow .railing-picker div, #yachtbuyshow .equipment-picker div, #yachtbuyshow .chip, #yachtbuyshow .flag-item, #yachtbuyshow .pay-picker div, #yachtbuyshow .mini-btn, #random-design, #reset-design", function () {
    playSound("click");
});

$("#upper-text, #bottom-text").on("input", updateNameHint);


resetSelection();
renderPresets();

$("#closeYachtTransferMenu").click(function () {
$("#yachtTransferMenu").hide();
$("#mainMenuManagment").show();
});

$("#closePlayersWithPermissionsMenu").click(function () {
$("#playersWithPermissionsMenu").hide();
$("#mainMenuManagment").show();
});

$("#closeAddPermissionsMenu").click(function () {
$("#addPermissionsMenu").hide();
$("#mainMenuManagment").show();
});

$("#closeMainMenu").click(function () {
$("#mainMenuManagment").hide();
	$.post('https://'+yachtresourcename+'/closemanagment', JSON.stringify({}));
});



$("#openOwnedFurniture").click(function () {
 $.post('https://'+yachtresourcename+'/chooseownfurniture', JSON.stringify({}));
});  

$("#openBuyFurniture").click(function () {
 $.post('https://'+yachtresourcename+'/choosebuyfurniture', JSON.stringify({}));
});    

$("#openAddPermissions").click(function () {
 $.post('https://'+yachtresourcename+'/chooseaddpermissions', JSON.stringify({}));
});    

$("#openYachtTransfer").click(function () {
 $.post('https://'+yachtresourcename+'/choosetransferyacht', JSON.stringify({}));
});    

$("#SellYacht").click(function () {
 $.post('https://'+yachtresourcename+'/sellyacht', JSON.stringify({}));
});    

$("#openPlayersWithPermissions").click(function () {
 $.post('https://'+yachtresourcename+'/choosepermissions', JSON.stringify({}));
});    

$("#furnitureClose").click(function () {
	$.post('https://'+yachtresourcename+'/yachtfurnitureclose', JSON.stringify({}));
});

$("#furnitureownClose").click(function () {
	$.post('https://'+yachtresourcename+'/yachtfurnitureeditclose', JSON.stringify({}));
});


// ── Upgrades panel (manage menu) ───────────────────────────
let upData = null;
let upSel = { color: 1, railing: 1, flag: 1, lightcat: 1, lightid: 1 };
const UP_LIGHT_COLORS = [[1, "#ffea00"], [2, "#0096ff"], [3, "#ff66ff"], [4, "#50c878"], [6, "#dc143c"], [5, "#8a2be2"], [7, "#ffbf00"], [8, "#ffffff"]];

function upNameProblem() {
    const rules = (upData && upData.namerules) || { minLength: 1, blockedWords: [] };
    const u = $("#up-upper").val(), b = $("#up-bottom").val();
    const all = (u + " " + b).toLowerCase();
    for (let i = 0; i < (rules.blockedWords || []).length; i++) {
        const w = String(rules.blockedWords[i]).toLowerCase();
        if (w && all.indexOf(w) !== -1) return "That name is not allowed.";
    }
    if (u.trim().length < rules.minLength || b.trim().length < rules.minLength) return "Both lines need a name.";
    return "";
}

function upUpdateButtons() {
    if (!upData) return;
    const nameChanged = $("#up-upper").val() !== upData.upper || $("#up-bottom").val() !== upData.bottom;
    const problem = upNameProblem();
    $("#up-name-hint").toggleClass("error", !!problem).text(problem);
    $("#up-rename").text("Rename · " + formatMoney(upData.renameprice)).toggleClass("disabled", !nameChanged || !!problem);

    const changed = upSel.color !== upData.color || upSel.railing !== upData.railing || upSel.flag !== upData.flag
        || upSel.lightcat !== upData.lightcat || upSel.lightid !== upData.lightid;
    $("#up-appearance").text("Apply changes · " + formatMoney(upData.appearanceprice)).toggleClass("disabled", !changed);
}

function renderTiers(containerId, list, current, detail, postName) {
    const $c = $(containerId).empty();
    list.forEach(function (t) {
        const state = t.id === current ? "current" : (t.id < current ? "owned" : "");
        const $t = $('<div class="tier"></div>').addClass(state).attr("data-tier", t.id);
        $("<b>").text(t.label).appendTo($t);
        $("<small>").text(detail(t)).appendTo($t);
        $('<div class="tier-price"></div>').text(state === "current" ? "Installed" : (state === "owned" ? "Owned" : formatMoney(t.price))).appendTo($t);
        $t.on("click", function () {
            if (state) return;
            playSound("click");
            $.post('https://' + yachtresourcename + '/' + postName, JSON.stringify({ tier: t.id }));
        });
        $t.appendTo($c);
    });
}

function renderUpgrades(d) {
    upData = d;
    upSel = { color: d.color, railing: d.railing, flag: d.flag, lightcat: d.lightcat, lightid: d.lightid };
    $("#up-balance").text("Cash " + formatMoney(d.cash) + "  ·  Bank " + formatMoney(d.bank));
    $("#up-upper").val(d.upper).attr("maxlength", d.namerules.maxLength);
    $("#up-bottom").val(d.bottom).attr("maxlength", d.namerules.maxLength);

    const $col = $("#up-colors").empty();
    for (let i = 1; i <= 16; i++) {
        $('<div></div>').attr("data-color", i).css("background-image", "url('img/yachtcolors/" + i + ".png')")
            .toggleClass("selected", i === upSel.color).appendTo($col);
    }

    const $rail = $("#up-railings").empty();
    d.railings.forEach(function (r) {
        const sw = r.swatch || ["#9fb3c4", "#e6eef5"];
        const $d = $('<div></div>').attr("data-railing", r.id).toggleClass("selected", r.id === upSel.railing);
        $('<span class="metal"></span>').css("background", "linear-gradient(90deg," + sw[0] + "," + sw[1] + "," + sw[0] + ")").appendTo($d);
        $("<b>").text(r.label).appendTo($d);
        $d.appendTo($rail);
    });

    const $flag = $("#up-flag").empty();
    flagOptions.forEach(function (f) { $("<option>").val(f.id).text(f.name).appendTo($flag); });
    $flag.val(String(upSel.flag));

    $("#up-lighttypes div").each(function () { $(this).toggleClass("selected", parseInt($(this).attr("data-type"), 10) === upSel.lightcat); });
    const $lc = $("#up-lightcolors").empty();
    UP_LIGHT_COLORS.forEach(function (c) {
        $('<div></div>').attr("data-lightid", c[0]).css("background-color", c[1]).toggleClass("selected", c[0] === upSel.lightid).appendTo($lc);
    });

    renderTiers("#up-engines", d.engines, d.enginetier, function (t) { return "x" + t.power + " power"; }, "upgradeengine");
    renderTiers("#up-storages", d.storages, d.storagetier, function (t) { return t.slots + " slots · " + Math.round(t.weight / 1000) + " kg"; }, "upgradestorage");
    renderExtras(d);
    renderComfort(d.comfort);
    upUpdateButtons();
}

$(document).on("click", "#up-colors div", function () {
    upSel.color = parseInt($(this).attr("data-color"), 10);
    $("#up-colors div").removeClass("selected"); $(this).addClass("selected");
    playSound("click"); upUpdateButtons();
});
$(document).on("click", "#up-railings div", function () {
    upSel.railing = parseInt($(this).attr("data-railing"), 10);
    $("#up-railings div").removeClass("selected"); $(this).addClass("selected");
    playSound("click"); upUpdateButtons();
});
$(document).on("click", "#up-lighttypes div", function () {
    upSel.lightcat = parseInt($(this).attr("data-type"), 10);
    $("#up-lighttypes div").removeClass("selected"); $(this).addClass("selected");
    playSound("click"); upUpdateButtons();
});
$(document).on("click", "#up-lightcolors div", function () {
    upSel.lightid = parseInt($(this).attr("data-lightid"), 10);
    $("#up-lightcolors div").removeClass("selected"); $(this).addClass("selected");
    playSound("click"); upUpdateButtons();
});
$("#up-flag").on("change", function () { upSel.flag = parseInt($(this).val(), 10); upUpdateButtons(); });
$("#up-upper, #up-bottom").on("input", upUpdateButtons);

$("#up-rename").on("click", function () {
    if ($(this).hasClass("disabled")) return;
    $.post('https://' + yachtresourcename + '/upgraderename', JSON.stringify({ upper: $("#up-upper").val(), bottom: $("#up-bottom").val() }));
});
$("#up-appearance").on("click", function () {
    if ($(this).hasClass("disabled")) return;
    $.post('https://' + yachtresourcename + '/upgradeappearance', JSON.stringify(upSel));
});

$("#openUpgrades").on("click", function () {
    $.post('https://' + yachtresourcename + '/chooseupgrades', JSON.stringify({}));
});
$("#closeUpgradesMenu").on("click", function () {
    $("#upgradesMenu").hide();
    $("#mainMenuManagment").show();
});

window.addEventListener('message', function (event) {
    const item = event.data;
    if (item.message == "upgradesshow") {
        openMain();
        $("#mainMenuManagment").hide();
        renderUpgrades(item);
        $("#upgradesMenu").show();
    }
    if (item.message == "yachtmanagmenthide" || item.message == "yachtmanagmentshow" || item.message == "yachtmanagment2show") {
        if (item.message == "yachtmanagmenthide") $("#upgradesMenu").hide();
        else $("#upgradesMenu").hide();
    }
});


// ── Fuel gauge while sailing ───────────────────────────────
function updateFuelHud(show, value) {
    let hud = document.getElementById("fuel-hud");
    if (!hud) {
        hud = document.createElement("div");
        hud.id = "fuel-hud";
        hud.innerHTML = '<i class="fas fa-gas-pump"></i><div class="fuel-bar"><div id="hud-fuel-fill"></div></div><span id="hud-fuel-text"></span>';
        document.documentElement.appendChild(hud);
    }
    hud.classList.toggle("show", !!show);
    if (show) {
        const v = Math.max(0, Math.min(100, Number(value) || 0));
        hud.classList.toggle("low", v <= 15);
        document.getElementById("hud-fuel-fill").style.width = v + "%";
        document.getElementById("hud-fuel-text").textContent = Math.round(v) + "%";
    }
}

function updateHullHud(show, value) {
    let hud = document.getElementById("hull-hud");
    if (!hud) {
        hud = document.createElement("div");
        hud.id = "hull-hud";
        hud.className = "fuel-hud-like";
        hud.innerHTML = '<i class="fas fa-ship"></i><div class="fuel-bar"><div id="hud-hull-fill"></div></div><span id="hud-hull-text"></span>';
        document.documentElement.appendChild(hud);
    }
    hud.classList.toggle("show", !!show);
    if (show) {
        const v = Math.max(0, Math.min(100, Number(value) || 0));
        hud.classList.toggle("low", v <= 30);
        document.getElementById("hud-hull-fill").style.width = v + "%";
        document.getElementById("hud-hull-text").textContent = Math.round(v) + "%";
    }
}

window.addEventListener('message', function (event) {
    const item = event.data;
    if (item.message == "fuelhud") updateFuelHud(item.show, item.value);
    if (item.message == "hullhud") updateHullHud(item.show, item.value);
});

// ── Upgrades: fuel, insurance, rentals ─────────────────────
function upDuration(sec) {
    sec = Math.max(0, Math.floor(sec || 0));
    const dd = Math.floor(sec / 86400), hh = Math.floor((sec % 86400) / 3600), mm = Math.floor((sec % 3600) / 60);
    if (dd > 0) return dd + " d " + hh + " h";
    if (hh > 0) return hh + " h " + mm + " min";
    return Math.max(1, mm) + " min";
}

function renderUpkeepAndCondition(d) {
    // upkeep
    $("#up-upkeep-section").toggle(!!d.upkeep);
    if (d.upkeep) {
        const u = d.upkeep;
        let text, cls = "";
        if (u.status === "ok") text = "Covered for " + upDuration(u.seconds) + ".";
        else if (u.status === "due") { text = "Overdue. The yacht locks in " + upDuration(u.graceDays * 86400 - u.seconds) + "."; cls = "warn"; }
        else { text = u.action === "repossess" ? "Overdue. The yacht may be repossessed." : "Locked: the yacht cannot sail until the upkeep is paid."; cls = "bad"; }
        text += " One payment covers " + u.intervalDays + " days" + (u.discount > 0 ? " (" + u.discount + "% marina discount applied)" : "") + ".";
        $("#up-upkeep-text").text(text).removeClass("warn bad").addClass(cls);
        $("#up-upkeep-pay").text("Pay upkeep · " + formatMoney(u.cost));
    }
    // hull condition
    $("#up-condition-section").toggle(!!d.condition);
    if (d.condition) {
        const v = Math.max(0, Math.min(100, d.condition.value));
        $("#up-cond-fill").css("width", v + "%").toggleClass("low", v <= 30);
        let note = Math.round(v) + "% hull condition.";
        if (v < 60) note += " Engine power is reduced.";
        if (d.condition.insureddiscount > 0) note += " " + d.condition.insureddiscount + "% insurance discount on repairs.";
        $("#up-cond-text").text(note);
        $("#up-repair").text(d.condition.repairprice > 0 ? "Repair · " + formatMoney(d.condition.repairprice) : "In good shape")
            .toggleClass("disabled", !(d.condition.repairprice > 0));
    }
}

function renderExtras(d) {
    renderUpkeepAndCondition(d);
    // fuel
    $("#up-fuel-section").toggle(d.fuel !== undefined && d.fuel !== null);
    if (d.fuel !== undefined && d.fuel !== null) {
        const v = Math.max(0, Math.min(100, d.fuel));
        $("#up-fuel-fill").css("width", v + "%").toggleClass("low", v <= 15);
        $("#up-fuel-text").text(Math.round(v) + "% in the tank");
        $("#up-refuel").text(d.refuelprice > 0 ? "Refuel · " + formatMoney(d.refuelprice) : "Tank full").toggleClass("disabled", !(d.refuelprice > 0));
    }
    // insurance
    $("#up-insurance-section").toggle(!!d.insurance);
    if (d.insurance) {
        const cmd = d.insurance.command ? "/" + d.insurance.command : "";
        $("#up-insurance-text").text((d.insurance.insured ? "Insured. " : "Not insured. ") +
            "Recovering a stuck yacht (" + cmd + ") costs " + formatMoney(d.insurance.recoveryfee) + ".");
        $("#up-insure").toggle(!d.insurance.insured).text("Insure yacht · " + formatMoney(d.insurance.price));
    }
    // rental
    $("#up-rental-section").toggle(!!d.rental);
    if (d.rental) {
        const $t = $("#up-rent-target").empty();
        (d.rental.nearby || []).forEach(function (p) { $("<option>").val(p.id).text(p.name + " (" + p.id + ")").appendTo($t); });
        if (!(d.rental.nearby || []).length) $("<option>").val("").text("No players nearby").appendTo($t);
        $("#up-rent-minutes").attr("max", d.rental.maxminutes);
        $("#up-rent-price").attr("max", d.rental.maxprice);
        $("#up-rent").toggleClass("disabled", !(d.rental.nearby || []).length);
    }
}

$("#up-refuel").on("click", function () {
    if ($(this).hasClass("disabled")) return;
    $.post('https://' + yachtresourcename + '/upgraderefuel', JSON.stringify({}));
});
$("#up-upkeep-pay").on("click", function () {
    comfortPost("upgradeupkeep", {});
});
$("#up-repair").on("click", function () {
    if ($(this).hasClass("disabled")) return;
    comfortPost("upgraderepair", {});
});
$("#up-insure").on("click", function () {
    $.post('https://' + yachtresourcename + '/upgradeinsure', JSON.stringify({}));
});
$("#up-rent").on("click", function () {
    if ($(this).hasClass("disabled")) return;
    const target = parseInt($("#up-rent-target").val(), 10);
    const minutes = parseInt($("#up-rent-minutes").val(), 10);
    const price = parseInt($("#up-rent-price").val(), 10);
    if (!target || !minutes || minutes < 5 || isNaN(price) || price < 0) {
        toast("Pick a player, at least 5 minutes and a price.", "warning");
        return;
    }
    $.post('https://' + yachtresourcename + '/upgraderental', JSON.stringify({ target: target, minutes: minutes, price: price }));
});

// ── Comfort & style ────────────────────────────────────────
let comfortData = null;
function comfortPost(name, body) { playSound("click"); $.post('https://' + yachtresourcename + '/' + name, JSON.stringify(body || {})); }

function renderComfort(c) {
    comfortData = c;
    $("#up-comfort").toggle(!!c);
    if (!c) return;

    const $lm = $("#up-lightmodes").empty();
    (c.lightmodes || []).forEach(function (m) {
        $('<div></div>').toggleClass("selected", m.id === c.lightmode).attr("data-mode", m.id).append($("<b>").text(m.label)).appendTo($lm);
    });

    $("#up-mood-section").toggle(!!(c.moods && c.moods.length));
    const $mo = $("#up-moods").empty();
    (c.moods || []).forEach(function (m) {
        $('<div></div>').toggleClass("selected", m.id === c.mood).attr("data-mood", m.id).append($("<b>").text(m.label)).appendTo($mo);
    });

    $("#up-radio-section").toggle(!!c.ambience);
    if (c.ambience) {
        $("#up-radio-note").text(c.ambience.owned ? "Plays for everyone standing on your yacht." : "One-off " + formatMoney(c.ambience.price) + " to unlock. Plays for everyone standing on your yacht.");
        const $st = $("#up-stations").empty();
        $('<div></div>').attr("data-station", "").toggleClass("selected", !c.ambience.current).append($("<b>").text("Off")).appendTo($st);
        c.ambience.stations.forEach(function (st) {
            $('<div></div>').attr("data-station", st.id).toggleClass("selected", c.ambience.current === st.id).append($("<b>").text(st.label)).appendTo($st);
        });
    }

    $("#up-hull-section").toggle(!!c.hull);
    if (c.hull) {
        $("#up-hull-note").text(c.hull.owned ? "Glowing lights along the hull." : "One-off " + formatMoney(c.hull.price) + " to install.");
        const $hc = $("#up-hullcolors").empty();
        c.hull.colors.forEach(function (col) {
            $('<div></div>').attr("data-hull", col.id).attr("title", col.label)
                .css("background-color", "rgb(" + col.rgb.join(",") + ")").toggleClass("selected", col.id === c.hull.color).appendTo($hc);
        });
        $("#up-hull-toggle").text(c.hull.owned ? (c.hull.on ? "Turn off" : "Turn on") : "Install and turn on");
    }

    $("#up-tender-section").toggle(!!c.tender);
    if (c.tender) {
        const $t = $("#up-tenders").empty();
        const cats = [];
        c.tender.options.forEach(function (o) { if (cats.indexOf(o.category) < 0) cats.push(o.category); });
        cats.forEach(function (cat) {
            const lim = c.tender.limits && c.tender.limits[cat];
            $('<div class="tender-cat"></div>').text(cat + (lim ? " (room for " + lim + ")" : "")).appendTo($t);
            const $g = $('<div class="tier-list"></div>').appendTo($t);
            c.tender.options.filter(function (o) { return o.category === cat; }).forEach(function (o) {
                const $d = $('<div class="tier"></div>').attr("data-tender", o.id).attr("data-owned", o.owned ? "1" : "0");
                $d.append($("<b>").text(o.label)).append($('<div class="tier-price"></div>').text(o.owned ? "Call it" : formatMoney(o.price)));
                if (o.owned) $('<span class="layout-del dock-btn" title="Store this vehicle again">Dock</span>').attr("data-dock", o.id).appendTo($d);
                $d.appendTo($g);
            });
        });
    }

    $("#up-layout-section").toggle(!!c.layoutsEnabled);
    if (c.layoutsEnabled) {
        const $l = $("#up-layouts").empty();
        c.layouts.forEach(function (l, i) {
            const $d = $('<div class="tier"></div>').attr("data-layout", i + 1);
            $d.append($("<b>").text(l.name)).append($("<small>").text(l.count + " pieces" + (l.missing > 0 ? " · " + l.missing + " not owned" : "")));
            $d.append($('<div class="tier-price"></div>').text("Load"));
            $('<span class="layout-del" title="Delete">&times;</span>').attr("data-del", i + 1).appendTo($d);
            const $a = $('<div class="layout-actions"></div>');
            if (c.sharing) $('<span title="Get a code you can give to other players">Share</span>').attr("data-share", i + 1).appendTo($a);
            if (l.missing > 0 && l.missingcost > 0) $('<span title="Buy the pieces you do not own yet and place everything"></span>').text("Complete · " + formatMoney(l.missingcost)).attr("data-complete", i + 1).appendTo($a);
            if ($a.children().length) $a.appendTo($d);
            $d.appendTo($l);
        });
        $("#up-layout-sharing").toggle(!!c.sharing);
    }
}

$(document).on("click", "#up-lightmodes div", function () { comfortPost("comfortlight", { mode: $(this).attr("data-mode") }); });
$(document).on("click", "#up-stations div", function () { comfortPost("comfortradio", { station: $(this).attr("data-station") || "" }); });
$(document).on("click", "#up-hullcolors div", function () {
    comfortPost("comfortHull", { color: parseInt($(this).attr("data-hull"), 10), on: comfortData ? (comfortData.hull.on || !comfortData.hull.owned) : true });
});
$("#up-hull-toggle").on("click", function () {
    if (!comfortData || !comfortData.hull) return;
    comfortPost("comfortHull", { color: comfortData.hull.color, on: !comfortData.hull.on });
});
$(document).on("click", "#up-tenders .dock-btn", function (e) {
    e.stopPropagation();
    comfortPost("comfortdock", { id: parseInt($(this).attr("data-dock"), 10) });
});
$(document).on("click", "#up-tenders .tier", function (e) {
    if ($(e.target).closest(".dock-btn").length) return;
    const id = parseInt($(this).attr("data-tender"), 10);
    comfortPost($(this).attr("data-owned") === "1" ? "comfortspawntender" : "comfortbuytender", { id: id });
});
$("#up-layout-save").on("click", function () { comfortPost("comfortsavelayout", { name: $("#up-layout-name").val() }); });
$(document).on("click", "#up-layouts .tier", function (e) {
    if ($(e.target).closest(".layout-del").length) return;
    comfortPost("comfortloadlayout", { index: parseInt($(this).attr("data-layout"), 10) });
});
$(document).on("click", "#up-moods div", function () { comfortPost("comfortmood", { mood: $(this).attr("data-mood") }); });
$(document).on("click", "#up-layouts [data-share]", function (e) {
    e.stopPropagation();
    comfortPost("comfortexportlayout", { index: parseInt($(this).attr("data-share"), 10) });
});
$(document).on("click", "#up-layouts [data-complete]", function (e) {
    e.stopPropagation();
    comfortPost("comfortbuymissing", { index: parseInt($(this).attr("data-complete"), 10) });
});
$("#up-layout-import").on("click", function () {
    const code = $("#up-layout-code").val().trim();
    if (!code) { toast("Paste a layout code first.", "warning"); return; }
    comfortPost("comfortimportlayout", { code: code });
    $("#up-layout-code").val("");
});
$("#up-share-copy").on("click", function () {
    const box = document.getElementById("up-share-code");
    box.focus(); box.select();
    let copied = false;
    try { copied = document.execCommand("copy"); } catch (e) { copied = false; }
    toast(copied ? "Code copied." : "Select the code and press Ctrl+C.", copied ? "success" : "info");
});
window.addEventListener('message', function (event) {
    const item = event.data;
    if (item.message == "layoutcode") {
        $("#up-share-name").text("Share code for \"" + item.name + "\"");
        $("#up-share-code").val(item.code);
        $("#up-layout-share").show();
        const box = document.getElementById("up-share-code");
        if (box) { box.focus(); box.select(); }
    }
});
$(document).on("click", "#up-layouts .layout-del", function (e) {
    e.stopPropagation();
    comfortPost("comfortdeletelayout", { index: parseInt($(this).attr("data-del"), 10) });
});

// buy menu camera tour
$(document).on("click", "#tour-chip", function () { playSound("click"); $.post('https://' + yachtresourcename + '/buytour', JSON.stringify({})); });
window.addEventListener('message', function (event) {
    if (event.data.message == "buytourstate") $("#tour-chip").toggleClass("selected", !!event.data.active);
});
