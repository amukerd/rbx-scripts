--[[
	Example usage of UILibrary.lua

	Put UILibrary.lua as a ModuleScript somewhere (e.g. ReplicatedStorage),
	then require it from a LocalScript like this one.
]]

local UILib = loadstring(game:HttpGet("https://raw.githubusercontent.com/amukerd/rbx-scripts/refs/heads/main/UI/Library.luau"))()

local Window = UILib.new({ Title = "Example UI" })

-- ===== Tab 1: Main =====
local MainTab = Window:AddTab("Main")

local GeneralSection = MainTab:AddSection("General")

GeneralSection:AddToggle({
	Text = "Enable ESP",
	Hover = "Highlights players through walls",
	Default = false,
	Callback = function(state)
		print("ESP:", state)
	end,
})

GeneralSection:AddToggle({
	Text = "Auto Farm",
	Hover = "Automatically collects nearby items",
	Default = true,
	Callback = function(state)
		print("Auto Farm:", state)
	end,
})

GeneralSection:AddButton({
	Text = "Teleport to Spawn",
	Hover = "Instantly moves your character to spawn",
	Callback = function()
		print("Teleporting to spawn...")
	end,
})

local statusDisplay = GeneralSection:AddTextDisplay({
	Text = "Status: Idle",
})

GeneralSection:AddButton({
	Text = "Run Task",
	Callback = function()
		statusDisplay:Set("Status: Running...")
		task.wait(1)
		statusDisplay:Set("Status: Done!")
	end,
})

-- ===== Tab 2: Settings =====
local SettingsTab = Window:AddTab("Settings")

local DisplaySection = SettingsTab:AddSection("Display")

DisplaySection:AddToggle({
	Text = "Show FPS Counter",
	Hover = "Displays your current frame rate on screen",
	Default = false,
	Callback = function(state)
		print("FPS Counter:", state)
	end,
})

DisplaySection:AddTextDisplay({
	Text = "Version 1.0.0",
})

local MiscSection = SettingsTab:AddSection("Misc")

MiscSection:AddButton({
	Text = "Reset Settings",
	Hover = "Resets all toggles back to default",
	Callback = function()
		print("Settings reset")
	end,
})
