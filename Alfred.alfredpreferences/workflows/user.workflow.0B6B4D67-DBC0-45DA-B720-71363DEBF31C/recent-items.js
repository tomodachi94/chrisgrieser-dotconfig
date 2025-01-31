#!/usr/bin/env osascript -l JavaScript

const app = Application.currentApplication();
app.includeStandardAdditions = true;

function alfredMatcher(str) {
	const clean = str.replace(/[-()_.:#;,/\\[\]]/g, " ");
	const camelCaseSeperated = str.replace(/([A-Z])/g, " $1");
	return [clean, camelCaseSeperated, str].join(" ");
}

//──────────────────────────────────────────────────────────────────────────────

// ensure Finder runs. Launching via Applescript seems to be the only method not
// causing some sort of crash
app.doShellScript(`osascript -e 'tell application "Finder" to launch'`);

const recentItems = app.doShellScript(`osascript -e 'tell application "System Events" to tell (process 1 where frontmost is true) to set allItems to every menu item of menu of menu item "Recent Items" of menu 1 of menu bar 1'`)
	.split(", ")
	.map(item => item.slice(10).split(" of ")[0]);

const start = recentItems.indexOf("Documents") + 1;
console.log("start: " + start);
const end = recentItems.indexOf("Servers") - 1;

let i = 0;
const recentFolders = app.doShellScript(`osascript -e 'tell application "System Events" to tell (process "Finder") to set allItems to every menu item of menu of menu item "Recent Folders" of menu "Go" of menu bar 1'`)
	.split(", ")
	.slice(0, -2)
	.map(item => item.slice(10).split(" of ")[0])
	.map(item => {
		i++;
		return { "name": item, "id": i, "type": "d" };
	});

i = 0;
const recentItemsMap = recentItems
	.map(item => {
		// INFO workaround with id necessary, since only file names, but not file paths are
		// saved in the menu, so that the IDs need to be used to emulate a click in
		// the next applescript step
		i++;
		return { "name": item, "id": i, "type": "f" };
	})
	.slice(start, end)
	.filter(item => !item.name.includes("“"));

const recentAll = [...recentFolders, ...recentItemsMap]
	.map(item => {
		let revealID = item.id;
		let iconPath = "folder.png";
		let subtitle = "❌ not available for folder";
		if (item.type === "f") { // type: [f]ile, [d]irectory
			revealID++; // id + 1 = reveal in Finder
			iconPath = "file.png";
			subtitle = "⌥: Reveal in Finder";
		}
		const openArg = item.type + item.id.toString();
		const revealArg = item.type + revealID.toString();

		return {
			"title": item.name,
			"uid": item.name,
			"match": alfredMatcher(item.name),
			"mods": {
				"alt": {
					"arg": revealArg,
					"valid": item.type === "f",
					"subtitle": subtitle,
				},
			},
			"icon": { "path": iconPath },
			"arg": openArg,
		};
	});

JSON.stringify({ items: recentAll });
