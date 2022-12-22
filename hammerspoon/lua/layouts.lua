require("lua.utils")
require("lua.window-management")
require("lua.private")
local useLayout = hs.layout.apply
--------------------------------------------------------------------------------
-- HELPERS
local function dockSwitcher(targetMode)
	hs.execute("zsh ./helpers/dock-switching/dock-switcher.sh --load " .. targetMode)
end

local function alacrittyFontSize(size)
	hs.execute("VALUE=" .. tostring(size) .. [[
		ALACRITTY_CONFIG="$HOME/.config/alacritty/alacritty.yml"
		MAN_PAGE_CONFIG="$HOME/.config/alacritty/man-page.yml"
		sed -i '' "s/size: .*/size: $VALUE/" "$ALACRITTY_CONFIG"
		sed -i '' "s/size: .*/size: $VALUE/" "$MAN_PAGE_CONFIG"
	]])
end

local function showAllSidebars()
	if appIsRunning("Highlights") then app("Highlights"):selectMenuItem { "View", "Show Sidebar" } end
	openLinkInBackground("obsidian://sidebar?showLeft=false&showRight=true")
	openLinkInBackground("drafts://x-callback-url/runAction?text=&action=show-sidebar")
end

local function isWeekend()
	local weekday = os.date():sub(1, 3)
	return weekday == "Sun" or weekday == "Sat"
end

--------------------------------------------------------------------------------
-- LAYOUTS
function movieModeLayout()
	holeCover()
	iMacDisplay:setBrightness(0)

	runWithDelays({ 0, 0.5, 1, 1.5 }, function() openIfNotRunning("YouTube") end)

	killIfRunning("Obsidian")
	killIfRunning("Drafts")
	killIfRunning("Neovide")
	killIfRunning("neovide")
	killIfRunning("Slack")
	killIfRunning("Discord")
	killIfRunning("BusyCal")
	killIfRunning("Mimestream")
	killIfRunning("Alfred Preferences")
	killIfRunning("Finder")
	killIfRunning("Warp")
	killIfRunning("Highlights")
	killIfRunning("Alacritty")
	killIfRunning("alacritty")
	killIfRunning("Twitterrific")

	dockSwitcher("movie")
	setDarkmode(true)
end

local layoutChangeActive = false
function homeModeLayout()
	local brightness = betweenTime(1, 8) and 0 or 0.8
	iMacDisplay:setBrightness(brightness)

	holeCover()

	openIfNotRunning("Discord")
	openIfNotRunning("Mimestream")
	if not (isWeekend()) then openIfNotRunning("Slack") end
	openIfNotRunning("Brave Browser")
	openIfNotRunning("Twitterrific")
	openIfNotRunning("Drafts")

	killIfRunning("Finder")
	killIfRunning("YouTube")
	killIfRunning("Netflix")
	killIfRunning("IINA")
	killIfRunning("Twitch")
	privateClosers()

	dockSwitcher("home")

	useLayout {
		{ "Twitterrific", nil, iMacDisplay, toTheSide, nil, nil },
		{ "Brave Browser", nil, iMacDisplay, pseudoMaximized, nil, nil },
		{ "Highlights", nil, iMacDisplay, pseudoMaximized, nil, nil },
		{ "Neovide", nil, iMacDisplay, pseudoMaximized, nil, nil },
		{ "neovide", nil, iMacDisplay, pseudoMaximized, nil, nil },
		{ "Slack", nil, iMacDisplay, pseudoMaximized, nil, nil },
		{ "Discord", nil, iMacDisplay, pseudoMaximized, nil, nil },
		{ "Warp", nil, iMacDisplay, pseudoMaximized, nil, nil },
		{ "Obsidian", nil, iMacDisplay, pseudoMaximized, nil, nil },
		{ "Drafts", nil, iMacDisplay, pseudoMaximized, nil, nil },
		{ "Mimestream", nil, iMacDisplay, pseudoMaximized, nil, nil },
		{ "alacritty", nil, iMacDisplay, pseudoMaximized, nil, nil },
		{ "Alacritty", nil, iMacDisplay, pseudoMaximized, nil, nil },
	}

	showAllSidebars()
	runWithDelays({ 0.5, 1 }, function() app("Drafts"):activate() end)

	if screenIsUnlocked() and not layoutChangeActive then
		layoutChangeActive = true
		runWithDelays(2, function()
			twitterrificAction("scrollup")
			layoutChangeActive = false
		end)
	end

	-- wait until sync is finished, to avoid merge conflict
	hs.timer
		.waitUntil(
			function() return not (gitDotfileSyncTask and gitDotfileSyncTask:isRunning()) end,
			function() alacrittyFontSize(26) end
		)
		:start()
end

function officeModeLayout()
	local screen1 = hs.screen.allScreens()[1]
	local screen2 = hs.screen.allScreens()[2]

	openIfNotRunning("Discord")
	openIfNotRunning("Mimestream")
	openIfNotRunning("Slack")
	openIfNotRunning("Brave Browser")
	openIfNotRunning("Obsidian")
	openIfNotRunning("TweetDeck")
	openIfNotRunning("Drafts")

	dockSwitcher("office") -- separate layout to include "TweetDeck"

	local top = { x = 0, y = 0.015, w = 1, h = 0.485 }
	local bottom = { x = 0, y = 0.5, w = 1, h = 0.5 }
	officeLayout = {
		-- screen 2
		{ "TweetDeck", nil, screen2, top, nil, nil },
		{ "Discord", nil, screen2, bottom, nil, nil },
		{ "Slack", nil, screen2, bottom, nil, nil },
		-- screen 1
		{ "Brave Browser", nil, screen1, maximized, nil, nil },
		{ "Obsidian", nil, screen1, maximized, nil, nil },
		{ "Neovide", nil, screen1, maximized, nil, nil },
		{ "neovide", nil, screen1, maximized, nil, nil },
		{ "Drafts", nil, screen1, maximized, nil, nil },
		{ "Mimestream", nil, screen1, maximized, nil, nil },
		{ "alacritty", nil, screen1, maximized, nil, nil },
		{ "Alacritty", nil, screen1, maximized, nil, nil },
		{ "Warp", nil, screen1, maximized, nil, nil },
	}

	useLayout(officeLayout)
	showAllSidebars()
	runWithDelays(0.3, function() useLayout(officeLayout) end)
	runWithDelays(0.5, function() app("Drafts"):activate() end)

	-- wait until sync is finished, to avoid merge conflict
	hs.timer
		.waitUntil(
			function() return not (gitDotfileSyncTask and gitDotfileSyncTask:isRunning()) end,
			function() alacrittyFontSize(24) end
		)
		:start()
end

local function motherMovieModeLayout()
	if not (isProjector()) then return end
	iMacDisplay:setBrightness(0)

	runWithDelays({ 0, 1 }, function() openIfNotRunning("YouTube") end)
	killIfRunning("Obsidian")
	killIfRunning("Drafts")
	killIfRunning("Slack")
	killIfRunning("Discord")
	killIfRunning("Mimestream")
	killIfRunning("Alfred Preferences")
	killIfRunning("Warp")
	killIfRunning("neovide")
	killIfRunning("Neovide")
	killIfRunning("alacritty")
	killIfRunning("Alacritty")
	killIfRunning("Twitterrific")

	dockSwitcher("mother-movie")
end

local function motherHomeModeLayout()
	local brightness = betweenTime(1, 8) and 0 or 0.8
	iMacDisplay:setBrightness(brightness)

	openIfNotRunning("Discord")
	if not (isWeekend()) then openIfNotRunning("Slack") end
	openIfNotRunning("Obsidian")
	openIfNotRunning("Mimestream")
	openIfNotRunning("Brave Browser")
	openIfNotRunning("Twitterrific")
	openIfNotRunning("Drafts")

	killIfRunning("YouTube")
	killIfRunning("Netflix")
	killIfRunning("IINA")
	killIfRunning("Twitch")
	privateClosers()

	alacrittyFontSize(25)
	dockSwitcher("home")

	local motherHomeLayout = {
		{ "Twitterrific", nil, iMacDisplay, toTheSide, nil, nil },
		{ "Brave Browser", nil, iMacDisplay, pseudoMaximized, nil, nil },
		{ "Warp", nil, iMacDisplay, pseudoMaximized, nil, nil },
		{ "Slack", nil, iMacDisplay, pseudoMaximized, nil, nil },
		{ "Discord", nil, iMacDisplay, pseudoMaximized, nil, nil },
		{ "Obsidian", nil, iMacDisplay, pseudoMaximized, nil, nil },
		{ "Drafts", nil, iMacDisplay, pseudoMaximized, nil, nil },
		{ "Mimestream", nil, iMacDisplay, pseudoMaximized, nil, nil },
		{ "alacritty", nil, iMacDisplay, pseudoMaximized, nil, nil },
		{ "Alacritty", nil, iMacDisplay, pseudoMaximized, nil, nil },
	}

	runWithDelays({ 0, 0.1, 0.2 }, function() useLayout(motherHomeLayout) end)
	showAllSidebars()

end

--------------------------------------------------------------------------------
-- SET LAYOUT AUTOMATICALLY + VIA HOTKEY
local function setLayout()
	if isAtOffice() then
		officeModeLayout()
	elseif isIMacAtHome() and isProjector() then
		movieModeLayout()
	elseif isIMacAtHome() and not isProjector() then
		homeModeLayout()
	elseif isAtMother() and isProjector() then
		motherMovieModeLayout()
	elseif isAtMother() and not isProjector() then
		motherHomeModeLayout()
	end
end

-- watcher + hotkey
displayCountWatcher = hs.screen.watcher.new(setLayout):start()
hotkey(hyper, "home", setLayout) -- hyper + eject on Apple Keyboard

--------------------------------------------------------------------------------

-- Open at Mouse Screen
wf_appsOnMouseScreen = wf.new {
	"Drafts",
	"Brave Browser",
	"Mimestream",
	"Obsidian",
	"Alacritty",
	"alacritty",
	"Warp",
	"Slack",
	"IINA",
	"Hammerspoon",
	"Discord",
	"Neovide",
	"neovide",
	"Espanso",
	"BusyCal",
	"Alfred Preferences",
	"System Preferences",
	"YouTube",
	"Netflix",
	"Finder",
}

wf_appsOnMouseScreen:subscribe(wf.windowCreated, function(newWin)
	local mouseScreen = hs.mouse.getCurrentScreen()
	if not mouseScreen then return end
	local screenOfWindow = newWin:screen()
	if not isProjector() or mouseScreen:name() == screenOfWindow:name() then return end

	local appn = newWin:application():name()
	runWithDelays({ 0.1, 0.3 }, function()
		if not (mouseScreen:name() == screenOfWindow:name()) then newWin:moveToScreen(mouseScreen) end

		if appn == "Finder" or appn == "Script Editor" or appn == "Hammerspoon" then
			moveResize(newWin, centered)
		else
			moveResize(newWin, maximized)
		end
	end)
end)
