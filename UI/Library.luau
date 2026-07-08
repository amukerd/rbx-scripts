--[[
	============================================================================
	 Modular UI Library — Tabs / Sections / Toggles / Buttons / Text Displays
	============================================================================

	FEATURES
	  • Window with a sidebar of Tabs
	  • Each Tab holds any number of Sections
	  • Each Section can contain:
	       - Toggles   (switch + label to the right + optional hover tooltip)
	       - Buttons   (click to fire a callback)
	       - TextDisplays (static/updatable read-only text, e.g. status lines)

	USAGE
	  local UILib  = require(path.to.UILibrary)
	  local Window = UILib.new({ Title = "My UI" })

	  local Tab1 = Window:AddTab("Main")
	  local Section1 = Tab1:AddSection("Settings")

	  Section1:AddToggle({
	      Text     = "Enable Feature",
	      Hover    = "Turns the feature on or off",
	      Default  = false,
	      Callback = function(state) print("Toggle:", state) end,
	  })

	  Section1:AddButton({
	      Text     = "Click Me",
	      Callback = function() print("Button clicked") end,
	  })

	  local Status = Section1:AddTextDisplay({ Text = "Status: Idle" })
	  Status:Set("Status: Running") -- update it later

	  Window:SetTab(Tab1) -- optional, select a tab programmatically
	============================================================================
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Works in normal LocalScripts (parents to PlayerGui) and in executor
-- environments that expose gethui() for a protected GUI container.
local function getGuiParent()
	local ok, hui = pcall(function()
		return gethui and gethui()
	end)
	if ok and hui then
		return hui
	end
	return PlayerGui
end

--// Theme -------------------------------------------------------------------

local THEME = {
	Background   = Color3.fromRGB(24, 24, 28),
	Sidebar      = Color3.fromRGB(18, 18, 22),
	Section      = Color3.fromRGB(30, 30, 35),
	Element      = Color3.fromRGB(38, 38, 44),
	ElementHover = Color3.fromRGB(46, 46, 53),
	Accent       = Color3.fromRGB(0, 170, 255),
	Text         = Color3.fromRGB(235, 235, 240),
	SubText      = Color3.fromRGB(150, 150, 158),
	Stroke       = Color3.fromRGB(50, 50, 58),
}

local FONT = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold

--// Utility ------------------------------------------------------------------

local function create(className, props, children)
	local inst = Instance.new(className)
	for prop, value in pairs(props or {}) do
		inst[prop] = value
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	return inst
end

local function corner(radius)
	return create("UICorner", { CornerRadius = UDim.new(0, radius or 6) })
end

local function stroke(color, thickness)
	return create("UIStroke", {
		Color = color or THEME.Stroke,
		Thickness = thickness or 1,
	})
end

local function tween(inst, props, time, style, direction)
	local info = TweenInfo.new(time or 0.18, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out)
	local t = TweenService:Create(inst, info, props)
	t:Play()
	return t
end

--// Shared tooltip -----------------------------------------------------------
-- One tooltip instance is reused by every hoverable element in the window.

local function createTooltip(screenGui)
	local label
	local tooltip = create("Frame", {
		Name = "Tooltip",
		BackgroundColor3 = THEME.Element,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 1000,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 0, 26),
		Parent = screenGui,
	}, {
		corner(4),
		stroke(THEME.Stroke, 1),
		create("UIPadding", {
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
		}),
	})

	label = create("TextLabel", {
		Name = "Label",
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		Font = FONT,
		TextSize = 13,
		TextColor3 = THEME.Text,
		Text = "",
		ZIndex = 1001,
		Parent = tooltip,
	})

	local moveConn

	local function reposition()
		local mouseLoc = UserInputService:GetMouseLocation()
		tooltip.Position = UDim2.new(0, mouseLoc.X + 18, 0, mouseLoc.Y - 8)
	end

	local function show(text)
		if not text or text == "" then
			return
		end
		label.Text = text
		tooltip.Visible = true
		reposition()
		if moveConn then
			moveConn:Disconnect()
		end
		moveConn = UserInputService.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				reposition()
			end
		end)
	end

	local function hide()
		tooltip.Visible = false
		if moveConn then
			moveConn:Disconnect()
			moveConn = nil
		end
	end

	return { Show = show, Hide = hide }
end

--// Library root -------------------------------------------------------------

local UILib = {}
UILib.__index = UILib

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Section = {}
Section.__index = Section

--------------------------------------------------------------------------------
-- Window
--------------------------------------------------------------------------------

function UILib.new(config)
	config = config or {}
	local title = config.Title or "Window"

	local screenGui = create("ScreenGui", {
		Name = "ModularUI",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = getGuiParent(),
	})

	local main = create("Frame", {
		Name = "Main",
		BackgroundColor3 = THEME.Background,
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, -300, 0.5, -190),
		Size = UDim2.new(0, 600, 0, 380),
		Parent = screenGui,
	}, {
		corner(8),
		stroke(THEME.Stroke, 1),
	})

	local topBar = create("Frame", {
		Name = "TopBar",
		BackgroundColor3 = THEME.Sidebar,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 36),
		Parent = main,
	}, {
		corner(8),
	})
	-- square off the bottom corners of the top bar so it blends into the body
	create("Frame", {
		BackgroundColor3 = THEME.Sidebar,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, -8),
		Size = UDim2.new(1, 0, 0, 8),
		Parent = topBar,
	})

	create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 14, 0, 0),
		Size = UDim2.new(1, -28, 1, 0),
		Font = FONT_BOLD,
		TextSize = 15,
		TextColor3 = THEME.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = title,
		Parent = topBar,
	})

	-- Dragging via the top bar
	do
		local dragging, dragStart, startPos
		topBar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = main.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - dragStart
				main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			end
		end)
	end

	local sidebar = create("Frame", {
		Name = "Sidebar",
		BackgroundColor3 = THEME.Sidebar,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 36),
		Size = UDim2.new(0, 140, 1, -36),
		Parent = main,
	})

	create("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = sidebar,
	})
	create("UIPadding", {
		PaddingTop = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		Parent = sidebar,
	})

	local content = create("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 140, 0, 36),
		Size = UDim2.new(1, -140, 1, -36),
		Parent = main,
	})

	local tooltip = createTooltip(screenGui)

	local self = setmetatable({
		ScreenGui = screenGui,
		Main = main,
		Sidebar = sidebar,
		Content = content,
		Tooltip = tooltip,
		Tabs = {},
		ActiveTab = nil,
	}, Window)

	return self
end

function Window:SetTab(tabObj)
	if self.ActiveTab == tabObj then
		return
	end
	if self.ActiveTab then
		self.ActiveTab.Page.Visible = false
		self.ActiveTab.Button.BackgroundColor3 = THEME.Sidebar
		self.ActiveTab.Button.Label.TextColor3 = THEME.SubText
	end
	tabObj.Page.Visible = true
	tabObj.Button.BackgroundColor3 = THEME.Element
	tabObj.Button.Label.TextColor3 = THEME.Text
	self.ActiveTab = tabObj
end

function Window:AddTab(name)
	local button = create("TextButton", {
		Name = name,
		BackgroundColor3 = THEME.Sidebar,
		AutoButtonColor = false,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 32),
		Text = "",
		Parent = self.Sidebar,
	}, { corner(6) })

	local label = create("TextLabel", {
		Name = "Label",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -16, 1, 0),
		Position = UDim2.new(0, 12, 0, 0),
		Font = FONT,
		TextSize = 14,
		TextColor3 = THEME.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = name,
		Parent = button,
	})
	button.Label = label

	local page = create("ScrollingFrame", {
		Name = name .. "Page",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = THEME.Accent,
		Visible = false,
		Parent = self.Content,
	})

	create("UIListLayout", {
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = page,
	})
	create("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		Parent = page,
	})

	local tabObj = setmetatable({
		Window = self,
		Button = button,
		Page = page,
		Sections = {},
	}, Tab)

	button.MouseButton1Click:Connect(function()
		self:SetTab(tabObj)
	end)
	button.MouseEnter:Connect(function()
		if self.ActiveTab ~= tabObj then
			tween(button, { BackgroundColor3 = THEME.ElementHover }, 0.12)
		end
	end)
	button.MouseLeave:Connect(function()
		if self.ActiveTab ~= tabObj then
			tween(button, { BackgroundColor3 = THEME.Sidebar }, 0.12)
		end
	end)

	table.insert(self.Tabs, tabObj)
	if not self.ActiveTab then
		self:SetTab(tabObj)
	end

	return tabObj
end

--------------------------------------------------------------------------------
-- Tab
--------------------------------------------------------------------------------

function Tab:AddSection(name)
	local section = create("Frame", {
		Name = name,
		BackgroundColor3 = THEME.Section,
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		Parent = self.Page,
	}, { corner(6), stroke(THEME.Stroke, 1) })

	create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -20, 0, 28),
		Position = UDim2.new(0, 12, 0, 4),
		Font = FONT_BOLD,
		TextSize = 14,
		TextColor3 = THEME.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = name,
		Parent = section,
	})

	local body = create("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(0, 0, 0, 32),
		Size = UDim2.new(1, 0, 0, 0),
		Parent = section,
	})

	create("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = body,
	})
	create("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
		Parent = body,
	})

	local sectionObj = setmetatable({
		Tab = self,
		Frame = section,
		Body = body,
		Window = self.Window,
	}, Section)

	table.insert(self.Sections, sectionObj)
	return sectionObj
end

--------------------------------------------------------------------------------
-- Section elements
--------------------------------------------------------------------------------

-- Attach hover-tooltip behaviour to any GuiObject.
local function attachHover(window, guiObject, text)
	if not text or text == "" then
		return
	end
	guiObject.MouseEnter:Connect(function()
		window.Tooltip.Show(text)
	end)
	guiObject.MouseLeave:Connect(function()
		window.Tooltip.Hide()
	end)
end

function Section:AddToggle(config)
	config = config or {}
	local text = config.Text or "Toggle"
	local hover = config.Hover
	local state = config.Default == true
	local callback = config.Callback

	local row = create("Frame", {
		Name = "Toggle_" .. text,
		BackgroundColor3 = THEME.Element,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 36),
		Parent = self.Body,
	}, { corner(6) })

	local switchBg = create("Frame", {
		Name = "Switch",
		BackgroundColor3 = state and THEME.Accent or THEME.Sidebar,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 10, 0.5, -11),
		Size = UDim2.new(0, 40, 0, 22),
		Parent = row,
	}, { corner(11), stroke(THEME.Stroke, 1) })

	local knob = create("Frame", {
		Name = "Knob",
		BackgroundColor3 = THEME.Text,
		BorderSizePixel = 0,
		Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9),
		Size = UDim2.new(0, 18, 0, 18),
		Parent = switchBg,
	}, { corner(9) })

	create("TextLabel", {
		Name = "Label",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 60, 0, 0),
		Size = UDim2.new(1, -70, 1, 0),
		Font = FONT,
		TextSize = 14,
		TextColor3 = THEME.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = text,
		Parent = row,
	})

	local clickArea = create("TextButton", {
		Name = "ClickArea",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Text = "",
		Parent = row,
	})

	local api = { State = state }

	local function render()
		tween(switchBg, { BackgroundColor3 = api.State and THEME.Accent or THEME.Sidebar }, 0.15)
		tween(knob, { Position = api.State and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9) }, 0.15)
	end

	function api:Set(newState, silent)
		self.State = newState and true or false
		render()
		if callback and not silent then
			task.spawn(callback, self.State)
		end
	end

	clickArea.MouseButton1Click:Connect(function()
		api:Set(not api.State)
	end)
	clickArea.MouseEnter:Connect(function()
		tween(row, { BackgroundColor3 = THEME.ElementHover }, 0.12)
	end)
	clickArea.MouseLeave:Connect(function()
		tween(row, { BackgroundColor3 = THEME.Element }, 0.12)
	end)

	attachHover(self.Window, row, hover)

	return api
end

function Section:AddButton(config)
	config = config or {}
	local text = config.Text or "Button"
	local hover = config.Hover
	local callback = config.Callback

	local button = create("TextButton", {
		Name = "Button_" .. text,
		BackgroundColor3 = THEME.Element,
		AutoButtonColor = false,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 34),
		Font = FONT,
		TextSize = 14,
		TextColor3 = THEME.Text,
		Text = text,
		Parent = self.Body,
	}, { corner(6) })

	button.MouseEnter:Connect(function()
		tween(button, { BackgroundColor3 = THEME.ElementHover }, 0.12)
	end)
	button.MouseLeave:Connect(function()
		tween(button, { BackgroundColor3 = THEME.Element }, 0.12)
	end)
	button.MouseButton1Down:Connect(function()
		tween(button, { BackgroundColor3 = THEME.Accent }, 0.08)
	end)
	button.MouseButton1Up:Connect(function()
		tween(button, { BackgroundColor3 = THEME.ElementHover }, 0.12)
	end)
	button.MouseButton1Click:Connect(function()
		if callback then
			task.spawn(callback)
		end
	end)

	attachHover(self.Window, button, hover)

	return { Instance = button }
end

function Section:AddTextDisplay(config)
	config = config or {}
	local text = config.Text or ""

	local label = create("TextLabel", {
		Name = "TextDisplay",
		BackgroundColor3 = THEME.Element,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 30),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = FONT,
		TextSize = 13,
		TextColor3 = THEME.SubText,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Text = text,
		Parent = self.Body,
	}, { corner(6) })

	create("UIPadding", {
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		PaddingTop = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 6),
		Parent = label,
	})

	local api = { Instance = label }
	function api:Set(newText)
		label.Text = newText
	end

	return api
end

return UILib
