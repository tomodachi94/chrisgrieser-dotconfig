#!/usr/bin/env osascript -l JavaScript
ObjC.import("stdlib");
const app = Application.currentApplication();
app.includeStandardAdditions = true;

function alfredMatcher(str) {
	const clean = str.replace(/[-()_.:#;,/\\[\]]/g, " ");
	const camelCaseSeperated = str.replace(/([A-Z])/g, " $1");
	return [clean, camelCaseSeperated, str].join(" ");
}

const getEnv = (path) => $.getenv(path).replace(/^~/, app.pathTo("home folder"));

//──────────────────────────────────────────────────────────────────────────────

const jsonArray = [];
const dotfileFolder = getEnv ("dotfile_folder");
/* eslint-disable no-multi-str, quotes */
const workArray = app.doShellScript (
	'PATH=/usr/local/bin/:/opt/homebrew/bin/:$PATH ;\
	cd "' + dotfileFolder + '" ; \
	fd --hidden --no-ignore \
	-E "Alfred.alfredpreferences" \
	-E "alacritty/colors/*" \
	-E "Marta/Themes/*" \
	-E "packer_compiled.lua" \
	-E "hammerspoon/Spoons/*" \
	-E "karabiner/automatic_backups/*" \
	-E "visualized keyboard layout/*.json" \
	-E "mac-migration" \
	-E "unused/*" \
	-E "fonts/*" \
	-E ".DS_Store" \
	-E ".git/"'
).split("\r");
/* eslint-enable no-multi-str, quotes */

workArray.forEach(file => {
	const filePath = dotfileFolder + file;
	const parts = file.split("/");
	const isFolder = file.endsWith("/");
	if (isFolder) parts.pop();
	const fileName = parts.pop();

	let parentPart = filePath.replace(/\/Users\/.*?\.config\/(.*\/).*$/, "$1");
	if (parentPart === ".") parentPart = "";

	let ext = fileName.split(".").pop();
	if (ext.includes("rc")) ext = "rc"; // rc files
	else if (ext.startsWith("z")) ext = "zsh"; // zsh dotfiles

	let iconObject;
	switch (ext) {
		case "json":
			iconObject = { "path": "icons/json.png" };
			break;
		case "lua":
			iconObject = { "path": "icons/lua.png" };
			break;
		case "yaml":
		case "yml":
			iconObject = { "path": "icons/yaml.png" };
			break;
		case "js":
			iconObject = { "path": "icons/js.png" };
			break;
		case "zsh":
		case "sh":
			iconObject = { "path": "icons/shell.png" };
			break;
		case "rc":
			iconObject = { "path": "icons/rc.png" };
			break;
		case "": // = folder
		default:
			iconObject = { "type": "fileicon", "path": filePath }; // by default, use file icon
	}

	jsonArray.push({
		"title": fileName,
		"subtitle": "▸ " + parentPart,
		"match": alfredMatcher (fileName),
		"icon": iconObject,
		"type": "file:skipcheck",
		"uid": filePath,
		"arg": filePath,
	});
});

JSON.stringify({ items: jsonArray });
