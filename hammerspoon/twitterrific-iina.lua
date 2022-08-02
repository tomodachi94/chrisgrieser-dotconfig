require("utils")

function twitterrificScrollUp ()
	twitterrificScrolling = true
	local previousApp = hs.application.frontmostApplication():name()
	local prevMousePos = hs.mouse.absolutePosition()

	local twitterrific = hs.application("Twitterrific")
	twitterrific:activate() -- needs activation, cause sending to app in background doesn't work w/ cmd
	local twitterrificWins = twitterrific:allWindows()

	for i = 1, #twitterrificWins do
		local f = twitterrificWins[i]:frame()
		local pos = {
			x = f.x + f.w * 0.09,
			y = f.y + 140,
		}
		keystroke({"cmd"}, "1") -- properly up (to avoid clicking on tweet content)
		hs.eventtap.leftClick(pos)
		keystroke({"cmd"}, "k") -- mark all as red
		keystroke({"cmd"}, "j") -- scroll up
		keystroke({}, "down") -- enable j/k movement
	end

	if #twitterrificWins > 1 then
		-- so the main window is controlled by the pagedown/up/shift-home actions
		twitterrific:getWindow("@pseudo_meta - Home"):focus()
	end

	hs.mouse.absolutePosition(prevMousePos)
	hs.application(previousApp):activate()
	twitterrificScrolling = false
end

function pagedownAction ()
	if appIsRunning("IINA") then
		keystroke({}, "right", 1, hs.application("IINA"))
	else
		keystroke({}, "down", 1, hs.application("Twitterrific"))
	end
end
function pageupAction ()
	if appIsRunning("IINA") then
		keystroke({}, "left", 1, hs.application("IINA"))
	else
		keystroke({}, "up", 1, hs.application("Twitterrific"))
	end
end
function homeAction ()
	if appIsRunning("IINA") then
		keystroke({}, "Space", 1, hs.application("IINA"))
	elseif appIsRunning("zoom.us") then
		alert("🔈/🔇") -- toggle mute
		keystroke({"shift", "command"}, "A", 1, hs.application("zoom.us"))
	else
		twitterrificScrollUp()
	end
end

function endAction ()
	if appIsRunning("zoom.us") then
		alert("📹/⬛️") -- toggle video
		keystroke({"shift", "command"}, "V", 1, hs.application("zoom.us"))
	else
		hs.application("Twitterrific"):activate()
	end
end

-- IINA: Full Screen when on projector
function iinaLaunch(appName, eventType, appObject)
	if (eventType == aw.launched) then
		if (appName == "IINA") then
			local isProjector = hs.screen.primaryScreen():name() == "ViewSonic PJ"
			if isProjector then
				-- going full screen apparently needs a small delay
				hs.timer.delayed.new(0.8, function()
					appObject:selectMenuItem({"Video", "Enter Full Screen"})
				end):start()
			end
		end
	end
end
iinaAppLauncher = aw.new(iinaLaunch)
iinaAppLauncher:start()

--------------------------------------------------------------------------------
-- raise all windows on activation,
-- open both windows on launch
-- only active in office & when not using twitterrificScrollUp()
function twitterificAppActivated(appName, eventType, appObject)
	if appName ~= "Twitterrific" or twitterrificScrolling then return end

	if isAtOffice() then
		if (eventType == aw.launched) then
			runDelayed(1, function ()
				twitterrific = hs.application("Twitterrific")
				-- switch to list view has (to be done via keystroke, since headless)
				keystroke({"cmd"}, "T", twitterrific)
				keystroke({"cmd"}, "5", twitterrific)
				keystroke({}, "down", twitterrific)
				keystroke({}, "return", twitterrific)
			end)
		elseif (eventType == aw.activated) then
			appObject:getWindow("@pseudo_meta - List"):raise()
			appObject:getWindow("@pseudo_meta - Home"):focus()
		end

	elseif isIMacAtHome() and (eventType == aw.launched) then
		runDelayed(1, twitterrificScrollUp)
	end

end
twitterrificScrolling = false
twitterificAppWatcher = aw.new(twitterificAppActivated)
if isAtOffice() then twitterificAppWatcher:start() end

--------------------------------------------------------------------------------
-- Hotkeys
hotkey({}, "pagedown", pagedownAction, nil, pagedownAction)
hotkey({}, "pageup", pageupAction, nil, pageupAction)
hotkey({}, "home", homeAction)
hotkey({}, "end", endAction)

