--[[
    Library.lua
    A lightweight, self-contained script UI library.

    Usage:
        local Library = loadstring(game:HttpGet("..."))()
        local Window = Library:CreateWindow("My Window")

        local Tab1 = Window:CreateTab("Main")
        Tab1:CreateButton("Click me", function() print("clicked") end)
        Tab1:CreateToggle("Enabled", false, function(state) print(state) end)
        Tab1:CreateDropdown("Mode", {"A","B","C"}, "A", function(choice) print(choice) end)
        Tab1:CreateTextbox("Name", "Type here", function(text) print(text) end)
        Tab1:CreateSlider("Speed", 0, 100, 50, function(value) print(value) end)
]]

local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LIBRARY_NAME = "KERDUI"

-- ===== Cleanup: destroy any previous instance so re-executing refreshes cleanly =====
local existing = CoreGui:FindFirstChild(LIBRARY_NAME)
if existing then
    existing:Destroy()
end

local Library = {}
Library.__index = Library

-- ===== Helpers =====

local function create(class, props, children)
    local inst = Instance.new(class)
    for prop, value in pairs(props or {}) do
        inst[prop] = value
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    return inst
end

local function corner(radius)
    return create("UICorner", { CornerRadius = UDim.new(0, radius or 8) })
end

local function tween(inst, props, time)
    local t = TweenService:Create(inst, TweenInfo.new(time or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

-- Makes `frame` draggable using `handle` as the grab region
local function makeDraggable(frame, handle)
    local dragging = false
    local dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- Makes `frame` resizable by dragging a small handle at one of its corners
local function makeResizable(frame, handle, cornerName, minSize)
    minSize = minSize or Vector2.new(300, 200)
    local dragging = false
    local dragStart, startSize, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startSize = frame.Size
            startPos = frame.Position
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart

            local newWidth = startSize.X.Offset
            local newHeight = startSize.Y.Offset
            local newX = startPos.X.Offset
            local newY = startPos.Y.Offset

            if cornerName == "BottomRight" then
                newWidth = math.max(minSize.X, startSize.X.Offset + delta.X)
                newHeight = math.max(minSize.Y, startSize.Y.Offset + delta.Y)
            elseif cornerName == "BottomLeft" then
                newWidth = math.max(minSize.X, startSize.X.Offset - delta.X)
                newHeight = math.max(minSize.Y, startSize.Y.Offset + delta.Y)
                newX = startPos.X.Offset + (startSize.X.Offset - newWidth)
            end

            frame.Size = UDim2.new(0, newWidth, 0, newHeight)
            frame.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
        end
    end)
end

-- ===== Theme =====
local Theme = {
    Background = Color3.fromRGB(24, 24, 27),
    Secondary = Color3.fromRGB(32, 32, 36),
    Accent = Color3.fromRGB(90, 120, 255),
    Border = Color3.fromRGB(45, 45, 50),
    Text = Color3.fromRGB(235, 235, 240),
    SubText = Color3.fromRGB(160, 160, 168),
}

-- ===== Window =====

function Library:CreateWindow(title)
    local ScreenGui = create("ScreenGui", {
        Name = LIBRARY_NAME,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = CoreGui,
    })

    local Main = create("Frame", {
        Name = "Main",
        Size = UDim2.new(0, 560, 0, 400),
        Position = UDim2.new(0.5, -280, 0.5, -200),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Parent = ScreenGui,
    }, { corner(10) })

    -- subtle outline
    create("UIStroke", {
        Color = Theme.Border,
        Thickness = 1,
        Parent = Main,
    })

    -- Top bar
    local TopBar = create("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Theme.Secondary,
        BorderSizePixel = 0,
        Parent = Main,
    }, { corner(10) })

    -- cover bottom corners of topbar so it looks flush, not rounded at the bottom
    create("Frame", {
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0, 0, 1, -10),
        BackgroundColor3 = Theme.Secondary,
        BorderSizePixel = 0,
        ZIndex = 1,
        Parent = TopBar,
    })

    local Title = create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        BackgroundTransparency = 1,
        Text = title or "Window",
        TextColor3 = Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TopBar,
    })

    makeDraggable(Main, TopBar)

    -- Tab list (left side)
    local TabList = create("Frame", {
        Name = "TabList",
        Size = UDim2.new(0, 140, 1, -40),
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundColor3 = Theme.Secondary,
        BorderSizePixel = 0,
        Parent = Main,
    })

    local TabListLayout = create("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = TabList,
    })
    create("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        Parent = TabList,
    })

    -- Section container (right side)
    local SectionContainer = create("Frame", {
        Name = "SectionContainer",
        Size = UDim2.new(1, -140, 1, -40),
        Position = UDim2.new(0, 140, 0, 40),
        BackgroundTransparency = 1,
        ClipsDescendants = false,
        Parent = Main,
    })

    -- Resize handles at each corner
    local handleSize = 32
    local corners = {
        { name = "BottomLeft",  anchor = Vector2.new(0, 1), pos = UDim2.new(0, 0, 1, -handleSize) },
        { name = "BottomRight", anchor = Vector2.new(1, 1), pos = UDim2.new(1, -handleSize, 1, -handleSize) },
    }

    for _, c in ipairs(corners) do
        local handle = create("Frame", {
            Name = "Resize_" .. c.name,
            Size = UDim2.new(0, handleSize, 0, handleSize),
            Position = c.pos,
            BackgroundTransparency = 1,
            ZIndex = 10,
            Parent = Main,
        })
        makeResizable(Main, handle, c.name, Vector2.new(400, 250))
    end

    local Window = setmetatable({
        ScreenGui = ScreenGui,
        Main = Main,
        TabList = TabList,
        SectionContainer = SectionContainer,
        Tabs = {},
        ActiveTab = nil,
    }, { __index = {} })

    -- ===== Tab creation =====
    function Window:CreateTab(name)
        local TabButton = create("TextButton", {
            Name = name .. "TabButton",
            Size = UDim2.new(1, 0, 0, 36), -- Made a bit taller
            BackgroundColor3 = Theme.Background,
            AutoButtonColor = false,
            Text = name,
            TextColor3 = Theme.SubText,
            Font = Enum.Font.GothamMedium,
            TextSize = 14,
            Parent = TabList,
        }, { corner(6) })

        local Section = create("ScrollingFrame", {
            Name = name .. "Section",
            Size = UDim2.new(1, -20, 1, -20),
            Position = UDim2.new(0, 10, 0, 10),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Theme.Accent,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
            ClipsDescendants = false, -- Prevent dropdown menus from cropping
            Parent = SectionContainer,
        })

        local Layout = create("UIListLayout", {
            Padding = UDim.new(0, 10), -- Extra padding space between objects
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = Section,
        })

        local Tab = setmetatable({ Section = Section, Button = TabButton }, { __index = {} })

        local function selectTab()
            for _, t in pairs(Window.Tabs) do
                t.Section.Visible = false
                tween(t.Button, { BackgroundColor3 = Theme.Background, TextColor3 = Theme.SubText }, 0.12)
            end
            Section.Visible = true
            tween(TabButton, { BackgroundColor3 = Theme.Accent, TextColor3 = Theme.Text }, 0.12)
            Window.ActiveTab = Tab
        end

        TabButton.MouseButton1Click:Connect(selectTab)

        Window.Tabs[name] = Tab

        if not Window.ActiveTab then
            selectTab()
        end

        -- ===== Controls =====

        function Tab:CreateButton(text, callback)
            callback = callback or function() end
            local Btn = create("TextButton", {
                Size = UDim2.new(1, 0, 0, 40), -- Increased height from 36
                BackgroundColor3 = Theme.Secondary,
                AutoButtonColor = false,
                Text = text,
                TextColor3 = Theme.Text,
                Font = Enum.Font.Gotham,
                TextSize = 14,
                Parent = Section,
            }, { corner(6) })

            Btn.MouseButton1Click:Connect(function()
                tween(Btn, { BackgroundColor3 = Theme.Accent }, 0.1)
                task.delay(0.1, function()
                    tween(Btn, { BackgroundColor3 = Theme.Secondary }, 0.15)
                end)
                callback()
            end)

            return Btn
        end

        function Tab:CreateToggle(text, default, callback)
            callback = callback or function() end
            local state = default or false

            local Holder = create("Frame", {
                Size = UDim2.new(1, 0, 0, 40), -- Increased height from 36
                BackgroundColor3 = Theme.Secondary,
                Parent = Section,
            }, { corner(6) })

            create("TextLabel", {
                Size = UDim2.new(1, -60, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                Text = text,
                TextColor3 = Theme.Text,
                Font = Enum.Font.Gotham,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Holder,
            })

            local Switch = create("Frame", {
                Size = UDim2.new(0, 42, 0, 22),
                Position = UDim2.new(1, -52, 0.5, -11),
                BackgroundColor3 = state and Theme.Accent or Theme.Border,
                Parent = Holder,
            }, { corner(11) })

            local Knob = create("Frame", {
                Size = UDim2.new(0, 18, 0, 18),
                Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9),
                BackgroundColor3 = Theme.Text,
                Parent = Switch,
            }, { corner(9) })

            local ClickCatcher = create("TextButton", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                Parent = Holder,
            })

            ClickCatcher.MouseButton1Click:Connect(function()
                state = not state
                tween(Switch, { BackgroundColor3 = state and Theme.Accent or Theme.Border }, 0.15)
                tween(Knob, { Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9) }, 0.15)
                callback(state)
            end)

            return Holder
        end

        function Tab:CreateDropdown(text, options, default, callback)
            options = options or {}
            callback = callback or function() end
            local selected = default or options[1]
            local open = false

            local Holder = create("Frame", {
                Size = UDim2.new(1, 0, 0, 40), -- Base size elevated from 36
                BackgroundColor3 = Theme.Secondary,
                ClipsDescendants = false,
                ZIndex = 10, -- Ensures dropdown content renders clearly over elements below it
                Parent = Section,
            }, { corner(6) })

            local TitleLabel = create("TextLabel", {
                Size = UDim2.new(0.4, -12, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                Text = text,
                TextColor3 = Theme.Text,
                Font = Enum.Font.Gotham,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Holder,
            })

            -- Sleek interactive selector box container
            local ComboContainer = create("Frame", {
                Size = UDim2.new(0.6, -12, 0, 28),
                Position = UDim2.new(0.4, 0, 0.5, -14),
                BackgroundColor3 = Theme.Background,
                Parent = Holder,
            }, { corner(6) })

            local Stroke = create("UIStroke", {
                Color = Theme.Border,
                Thickness = 1,
                Parent = ComboContainer
            })

            local SelectedLabel = create("TextLabel", {
                Size = UDim2.new(1, -30, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text = tostring(selected),
                TextColor3 = Theme.SubText,
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = ComboContainer,
            })

            local ArrowIcon = create("TextLabel", {
                Size = UDim2.new(0, 20, 1, 0),
                Position = UDim2.new(1, -24, 0, 0),
                BackgroundTransparency = 1,
                Text = "▼",
                TextColor3 = Theme.SubText,
                Font = Enum.Font.Gotham,
                TextSize = 10,
                TextYAlignment = Enum.TextYAlignment.Center,
                TextXAlignment = Enum.TextXAlignment.Center,
                Parent = ComboContainer,
            })

            -- Modern unified scrolling window for entries
            local OptionList = create("ScrollingFrame", {
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 1, 4),
                BackgroundColor3 = Theme.Background,
                Visible = false,
                BorderSizePixel = 0,
                ScrollBarThickness = 4,
                ScrollBarImageColor3 = Theme.Accent,
                CanvasSize = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ZIndex = 12,
                Parent = ComboContainer,
            }, { corner(6) })

            create("UIStroke", {
                Color = Theme.Border,
                Thickness = 1,
                Parent = OptionList
            })

            local OptLayout = create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 2),
                Parent = OptionList,
            })

            create("UIPadding", {
                PaddingTop = UDim.new(0, 4),
                PaddingBottom = UDim.new(0, 4),
                PaddingLeft = UDim.new(0, 4),
                PaddingRight = UDim.new(0, 4),
                Parent = OptionList,
            })

            local ToggleButton = create("TextButton", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = 3,
                Parent = ComboContainer,
            })

            -- Calculate height based on options up to a max cutoff limit
            local maxDisplayItems = math.min(#options, 5)
            local targetHeight = (maxDisplayItems * 32) + 8

            ToggleButton.MouseButton1Click:Connect(function()
                open = not open
                if open then
                    OptionList.Visible = true
                    tween(ArrowIcon, { Rotation = 180 }, 0.15)
                    tween(OptionList, { Size = UDim2.new(1, 0, 0, targetHeight) }, 0.15)
                else
                    tween(ArrowIcon, { Rotation = 0 }, 0.15)
                    local t = tween(OptionList, { Size = UDim2.new(1, 0, 0, 0) }, 0.15)
                    t.Completed:Connect(function()
                        if not open then OptionList.Visible = false end
                    end)
                end
            end)

            for i, opt in ipairs(options) do
                local OptBtn = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundColor3 = Theme.Background,
                    AutoButtonColor = false,
                    Text = "  " .. tostring(opt),
                    TextColor3 = Theme.Text,
                    Font = Enum.Font.Gotham,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 13,
                    LayoutOrder = i,
                    Parent = OptionList,
                }, { corner(4) })

                OptBtn.MouseEnter:Connect(function()
                    tween(OptBtn, { BackgroundColor3 = Theme.Secondary, TextColor3 = Theme.Accent }, 0.1)
                end)

                OptBtn.MouseLeave:Connect(function()
                    tween(OptBtn, { BackgroundColor3 = Theme.Background, TextColor3 = Theme.Text }, 0.1)
                end)

                OptBtn.MouseButton1Click:Connect(function()
                    selected = opt
                    SelectedLabel.Text = tostring(opt)
                    open = false
                    tween(ArrowIcon, { Rotation = 0 }, 0.15)
                    local t = tween(OptionList, { Size = UDim2.new(1, 0, 0, 0) }, 0.15)
                    t.Completed:Connect(function()
                        if not open then OptionList.Visible = false end
                    end)
                    callback(selected)
                end)
            end

            return Holder
        end

        function Tab:CreateTextbox(text, placeholder, callback)
            callback = callback or function() end

            local Holder = create("Frame", {
                Size = UDim2.new(1, 0, 0, 40), -- Increased height from 36
                BackgroundColor3 = Theme.Secondary,
                Parent = Section,
            }, { corner(6) })

            create("TextLabel", {
                Size = UDim2.new(0.4, -12, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                Text = text,
                TextColor3 = Theme.Text,
                Font = Enum.Font.Gotham,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Holder,
            })

            local Box = create("TextBox", {
                Size = UDim2.new(0.6, -12, 0, 28),
                Position = UDim2.new(0.4, 0, 0.5, -14),
                BackgroundColor3 = Theme.Background,
                PlaceholderText = placeholder or "",
                Text = "",
                TextColor3 = Theme.Text,
                PlaceholderColor3 = Theme.SubText,
                Font = Enum.Font.Gotham,
                TextSize = 13,
                ClearTextOnFocus = false,
                Parent = Holder,
            }, { corner(5) })

            create("UIStroke", {
                Color = Theme.Border,
                Thickness = 1,
                Parent = Box
            })

            Box.FocusLost:Connect(function(enterPressed)
                callback(Box.Text, enterPressed)
            end)

            return Holder
        end

        function Tab:CreateSlider(text, min, max, default, callback)
            min, max = min or 0, max or 100
            default = default or min
            callback = callback or function() end
            local dragging = false

            local Holder = create("Frame", {
                Size = UDim2.new(1, 0, 0, 48), -- Increased from 46
                BackgroundColor3 = Theme.Secondary,
                Parent = Section,
            }, { corner(6) })

            local Label = create("TextLabel", {
                Size = UDim2.new(1, -24, 0, 20),
                Position = UDim2.new(0, 12, 0, 4),
                BackgroundTransparency = 1,
                Text = text .. ": " .. tostring(default),
                TextColor3 = Theme.Text,
                Font = Enum.Font.Gotham,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Holder,
            })

            local Track = create("Frame", {
                Size = UDim2.new(1, -24, 0, 6),
                Position = UDim2.new(0, 12, 1, -14),
                BackgroundColor3 = Theme.Border,
                Parent = Holder,
            }, { corner(3) })

            local Fill = create("Frame", {
                Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
                BackgroundColor3 = Theme.Accent,
                Parent = Track,
            }, { corner(3) })

            local function setFromX(xPos)
                local relative = math.clamp((xPos - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                local value = math.floor(min + (max - min) * relative)
                Fill.Size = UDim2.new(relative, 0, 1, 0)
                Label.Text = text .. ": " .. tostring(value)
                callback(value)
            end

            Track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    setFromX(input.Position.X)
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    setFromX(input.Position.X)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            return Holder
        end

        return Tab
    end

    return Window
end

return Library
