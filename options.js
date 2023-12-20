const PREFS = {
	"fastnav_scroll_page": {
		"type": "checked",
		"default": true
	}
};

async function saveOptions() { 
	browser.runtime.sendMessage({action: "notify", data: "Saved preferences"});

	const values = {};
	for(let p in PREFS) {
		values[p] = document.getElementById(p)[PREFS[p].type];
	}

	await browser.storage.local.set(values);
	browser.runtime.sendMessage({action: "refresh-options"});
}

async function restoreOptions() {
	let result = await browser.storage.local.get(Object.keys(PREFS));
	
	let val;
	for(let p in PREFS) {
		if(p in result) {
			val = result[p];
		}
		else {
			val = PREFS[p].default;
		}
		document.getElementById(p)[PREFS[p].type] = val;
		//console.log("options.js val restored is " + val);
	}
}

function init(){
	restoreOptions();
	document.querySelector("form").style.display = "block";
	document.querySelector(".refreshOptions").style.display = "none";
}

window.addEventListener("DOMContentLoaded", init, { passive: true });
document.querySelector("form").addEventListener("submit", (e) => { e.preventDefault(); saveOptions(); }, { passive: false });
