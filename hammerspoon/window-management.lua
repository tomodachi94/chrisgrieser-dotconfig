require("utils")
require("twitterrific-iina")
require("private")

--------------------------------------------------------------------------------
-- WINDOW MANAGEMENT UTILS
if (isIMacAtHome()) then
	pseudoMaximized = {x=0, y=0, w=0.815, h=1}
else
	pseudoMaximized = {x=0, y=0, w=0.7875, h=1}
end

maximized = hs.layout.maximized
wf = hs.window.filter
if isAtOffice() then
	baseLayout = maximized
else
	baseLayout = pseudoMaximized
end
iMacDisplay = hs.screen("Built%-in") -- % to escape hyphen (is a quantifier in lua patterns)

function numberOfScreens()
	return #(hs.screen.allScreens())
end

function isPseudoMaximized (win)
	if not(win) then return false end
	local max = hs.screen.mainScreen():frame()
	local dif = win:frame().w - pseudoMaximized.w*max.w
	local widthOkay = (dif > -15 and dif < 15) -- leeway for some apps
	return widthOkay
end

function isHalf (win)
	if not(win) then return false end
	local max = hs.screen.mainScreen():frame()
	local dif = win:frame().w - 0.5*max.w
	return (dif > -15 and dif < 15) -- leeway for some apps
end

--------------------------------------------------------------------------------
-- WINDOW BASE MOVEMENT & SIDEBARS

-- requires these two actiosn beeing installed:
-- https://directory.getdrafts.com/a/2BS & https://directory.getdrafts.com/a/2BR
function toggleDraftsSidebar (draftsWin)
	runDelayed(0.05, function ()
		local drafts_w = draftsWin:frame().w
		local screen_w = draftsWin:screen():frame().w
		if (drafts_w / screen_w > 0.6) then
			-- using URI scheme since they are more reliable than the menu item
			hs.urlevent.openURL("drafts://x-callback-url/runAction?text=&action=show-sidebar")
		else
			hs.urlevent.openURL("drafts://x-callback-url/runAction?text=&action=hide-sidebar")
		end
	end)
	-- repetitation for some rare cases with lag needed
	runDelayed(0.2, function ()
		local drafts_w = draftsWin:frame().w
		local screen_w = draftsWin:screen():frame().w
		if (drafts_w / screen_w > 0.6) then
			hs.urlevent.openURL("drafts://x-callback-url/runAction?text=&action=show-sidebar")
		else
			hs.urlevent.openURL("drafts://x-callback-url/runAction?text=&action=hide-sidebar")
		end
	end)
end

function toggleHighlightsSidebar (highlightsWin)
	runDelayed(0.3, function ()
		local highlights_w = highlightsWin:frame().w
		local screen_w = highlightsWin:screen():frame().w
		local highlightsApp = hs.application("Highlights")
		highlightsApp:activate()
		if (highlights_w / screen_w > 0.6) then
			highlightsApp:selectMenuItem({"View", "Show Sidebar"})
		else
			highlightsApp:selectMenuItem({"View", "Hide Sidebar"})
		end
	end)
end

-- requires Obsidian Sidebar Toggler Plugin
-- https://github.com/chrisgrieser/obsidian-sidebar-toggler
function toggleObsidianSidebar (obsiWin)
	runDelayed(0.05, function ()
		-- prevent popout window resizing to affect sidebars
		local numberOfObsiWindows = #(hs.application("Obsidian"):allWindows())
		if (numberOfObsiWindows > 1) then return end

		local obsi_width = obsiWin:frame().w
		local screen_width = obsiWin:screen():frame().w
		if (obsi_width / screen_width > 0.6) then
			hs.urlevent.openURL("obsidian://sidebar?showLeft=true&showRight=false")
		else
			hs.urlevent.openURL("obsidian://sidebar?showLeft=false&showRight=false")
		end
	end)
	runDelayed(0.2, function ()
		local numberOfObsiWindows = #(hs.application("Obsidian"):allWindows())
		if (numberOfObsiWindows > 1) then return end

		local obsi_width = obsiWin:frame().w
		local screen_width = obsiWin:screen():frame().w
		if (obsi_width / screen_width > 0.6) then
			hs.urlevent.openURL("obsidian://sidebar?showLeft=true&showRight=false")
		else
			hs.urlevent.openURL("obsidian://sidebar?showLeft=false&showRight=false")
		end
	end)
end

function moveResizeCurWin(direction)
	local win = hs.window.focusedWindow()
	local position

	if (direction == "left") then
		position = hs.layout.left50
	elseif (direction == "right") then
		position = hs.layout.right50
	elseif (direction == "up") then
		position = {x=0, y=0, w=1, h=0.5}
	elseif (direction == "down") then
		position = {x=0, y=0.5, w=1, h=0.5}
	elseif (direction == "pseudo-maximized") then
		position = pseudoMaximized
	elseif (direction == "maximized") then
		position = maximized
	elseif (direction == "centered") then
		position = {x=0.2, y=0.1, w=0.6, h=0.8}
	end

	-- workaround for https://github.com/Hammerspoon/hammerspoon/issues/2316
	moveResize(win, position)

	if win:application():name() == "Drafts" then toggleDraftsSidebar(win)
	elseif win:application():name() == "Obsidian" then toggleObsidianSidebar(win)
	elseif win:application():name() == "Highlights" then toggleHighlightsSidebar(win)
	end
end

-- replaces `win:moveToUnit(pos)`
function moveResize(win, pos)
	win:moveToUnit(pos)
	-- has to repeat due to bug for some apps... >:(
	hs.timer.delayed.new(0.3, function () win:moveToUnit(pos) end):start()
end

function dockSwitcher (targetMode)
	hs.execute("zsh ./dock-switching/dock-switcher.sh --load "..targetMode)
end

function sublimeFontSize (size)
	local toSize = tostring(size)
	hs.execute("VALUE="..toSize..[[
		SUBLIME_CONFIG="$HOME/Library/Application Support/Sublime Text/Packages/User/Preferences.sublime-settings"
		sed -i '' "s/\"font_size\": .*,/\"font_size\": $VALUE,/" "$SUBLIME_CONFIG"
	]])
end


function moveToOtherDisplay ()
	local win = hs.window.focusedWindow()
	local targetScreen = win:screen():next()
	win:moveToScreen(targetScreen, true)

	-- workaround for ensuring proper resizing
	runDelayed(0.25, function ()
		win_ = hs.window.focusedWindow()
		win_:setFrameInScreenBounds(win_:frame())
	end)
end

--------------------------------------------------------------------------------
-- HOTKEYS
function controlSpace ()
	if frontapp() == "Finder" or frontapp() == "Script Editor" then
		size = "centered"
	elseif isIMacAtHome() or isAtMother() then
		local currentWin = hs.window.focusedWindow()
		if isPseudoMaximized(currentWin) then
			size = "maximized"
		else
			size = "pseudo-maximized"
		end
	else
		size = "maximized"
	end

	moveResizeCurWin(size)
end

hotkey(hyper, "up", function() moveResizeCurWin("up") end)
hotkey(hyper, "down", function() moveResizeCurWin("down") end)
hotkey(hyper, "right", function() moveResizeCurWin("right") end)
hotkey(hyper, "left", function() moveResizeCurWin("left") end)
hotkey(hyper, "pagedown", moveToOtherDisplay)
hotkey(hyper, "pageup", moveToOtherDisplay)
hotkey({"ctrl"}, "space", controlSpace)
hotkey({"fn"}, "space", controlSpace) -- for Apple Keyboards


--------------------------------------------------------------------------------
-- APP-SPECIFIC WINDOW BEHAVIOR
-- - https://www.hammerspoon.org/go/#winfilters
-- - https://github.com/dmgerman/hs_select_window.spoon/blob/main/init.lua

-- BROWSER
-- split when second window is opened
-- change sizing back, when back to one window
wf_browser = wf.new("Brave Browser"):setOverrideFilter{rejectTitles={" %(Private%)$","^Picture in Picture$"}, allowRoles='AXStandardWindow', hasTitlebar=true}
wf_browser:subscribe(wf.windowCreated, function ()
	if #wf_browser:getWindows() == 2 then
		local win1 = wf_browser:getWindows()[1]
		local win2 = wf_browser:getWindows()[2]
		moveResize(win1, hs.layout.left50)
		moveResize(win2, hs.layout.right50)
	end
end)
wf_browser:subscribe(wf.windowDestroyed, function ()
	if #wf_browser:getWindows() == 1 then
		local win = wf_browser:getWindows()[1]
		moveResize(win, baseLayout)
	end
end)

-- Automatically hide Browser when no window
wf_browser_all = wf.new("Brave Browser"):setOverrideFilter{allowRoles='AXStandardWindow'}
wf_browser_all:subscribe(wf.windowDestroyed, function ()
	if #wf_browser_all:getWindows() == 0 then
		hs.application("Brave Browser"):hide()
	end
end)

-- FINDER: hide when no window
wf_finder = wf.new("Finder")
wf_finder:subscribe(wf.windowDestroyed, function ()
	if #wf_finder:getWindows() == 0 then
		hs.application("Finder"):hide()
	end
end)

-- keep TWITTERRIFIC visible, when active window is pseudomaximized
function twitterrificNextToPseudoMax(_, eventType)
	if not(eventType == aw.activated or eventType == aw.launching) then return end
	if not(appIsRunning("Twitterrific")) then return end

	local currentWin = hs.window.focusedWindow()
	if isPseudoMaximized(currentWin) then
		hs.application("Twitterrific"):mainWindow():raise()
	end
end
anyAppActivationWatcher = aw.new(twitterrificNextToPseudoMax)
anyAppActivationWatcher:start()

-- Minimize first ZOOM Window, when second is open
wf_zoom = wf.new("zoom.us")
wf_zoom:subscribe(wf.windowCreated, function ()
	if #wf_zoom:getWindows() == 2 then
		runDelayed (1.3, function()
			hs.application("zoom.us"):findWindow("^Zoom$"):close()
		end)
	end
end)

-- SUBLIME
wf_sublime = wf.new("Sublime Text"):setOverrideFilter{allowRoles='AXStandardWindow'}
wf_sublime:subscribe(wf.windowCreated, function (newWindow)
	-- if new window is a settings window, maximize it
	if newWindow:title():match("sublime%-settings$") or newWindow:title():match("sublime%-keymap$") then
		moveResizeCurWin("maximized")

	-- command-line-edit window = split with alacritty (using EDITOR='subl --new-window --wait')
	elseif newWindow:title():match("^zsh%w+$") then
		local alacrittyWin = hs.application("alacritty"):mainWindow()
		moveResize(alacrittyWin, hs.layout.left50)
		moveResize(newWindow, hs.layout.right50)
		newWindow:becomeMain() -- so cmd-tabbing activates this window and not any other one
		hs.osascript.applescript([[
			tell application "System Events"
				tell process "Sublime Text"
					click menu item "Bash" of menu of menu item "Syntax" of menu "View" of menu bar 1
				end tell
			end tell
		]])

	-- workaround for Window positioning issue, will be fixed with build 4130 being released
	-- https://github.com/sublimehq/sublime_text/issues/5237
	elseif isAtOffice() or isProjector() then
		moveResizeCurWin("maximized")
		runDelayed(0.2, function () moveResizeCurWin("maximized") end)
	else
		moveResizeCurWin("pseudo-maximized")
		runDelayed(0.2, function () moveResizeCurWin("pseudo-maximized") end)
		runDelayed(0.5, function () moveResizeCurWin("pseudo-maximized") end)
		hs.application("Twitterrific"):mainWindow():raise()
	end
end)
wf_sublime:subscribe(wf.windowDestroyed, function ()
	-- don't leave windowless app behind
	if #wf_sublime:getWindows() == 0 and appIsRunning("Sublime Text") then
		hs.application("Sublime Text"):kill()
	end
	-- editing command line finished
	if not(hs.application("alacritty")) then return end
	local alacrittyWin = hs.application("alacritty"):mainWindow()
	if isHalf(alacrittyWin) then
		moveResize(alacrittyWin, baseLayout)
		alacrittyWin:focus()
		keystroke({}, "space") -- to redraw zsh-syntax highlighting of the buffer
	end
end)
wf_sublime:subscribe(wf.windowFocused, function (focusedWin)
	-- editing command line: paired activation of both windows
	if not(appIsRunning("alacritty")) then return end
	local alacrittyWin = hs.application("alacritty"):mainWindow()
	if focusedWin:title():match("^zsh%w+$") and isHalf(alacrittyWin) then
		alacrittyWin:raise()
	end
end)

-- MARTA
wf_marta = wf.new("Marta"):setOverrideFilter{allowRoles='AXStandardWindow'}
wf_marta:subscribe(wf.windowCreated, function ()
	killIfRunning("Finder")
	runDelayed(0.1, function () -- close other tabs, needed cause: https://github.com/marta-file-manager/marta-issues/issues/896
		keystroke({"shift"}, "w", 1, hs.application("Marta"))
	end)
	if isAtOffice() or isProjector() then
		moveResizeCurWin("maximized")
	else
		moveResizeCurWin("pseudo-maximized")
		hs.application("Twitterrific"):mainWindow():raise()
	end
end)

-- ALACRITTY
wf_alacritty = wf.new("alacritty"):setOverrideFilter{rejectTitles="^cheatsheet$"}
wf_alacritty:subscribe(wf.windowCreated, function ()
	if isAtOffice() or isProjector() then
		moveResizeCurWin("maximized")
	else
		moveResizeCurWin("pseudo-maximized")
		hs.application("Twitterrific"):mainWindow():raise()
	end
end)
