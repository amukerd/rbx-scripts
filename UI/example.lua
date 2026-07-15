local Library = loadstring(game:HttpGet("https://amukerd.github.io/rbx-scripts/UI/Library.lua"))()

local Window = Library:CreateWindow("KerdHub")
local Tab1 = Window:CreateTab("Main")

Tab1:CreateButton("Button", function()
    print("clicked")
end)

Tab1:CreateToggle("Enable", false, function(state)
    print(state)
end)

Tab1:CreateSpacer("Spacer")

Tab1:CreateDropdown("Mode",  {"A","B","C","D","E","F","G","H","I","J","K","m","l","k","j","i","h","g","Kf","e","d","c","b","a"}, "A", function(choice)
    print(choice)
end)

local function GetModeNames()
    return {"A", "B", "C", "D", "E"}
end

Tab1:CreateDropdown("Mode2", GetModeNames(), "A", function(choice)
    print(choice) 
end)

Tab1:CreateTextbox("Number", "Type here...", function(text)
    print(text)
end)


local Tab2 = Window:CreateTab("Settings")

Tab2:CreateButton("Button 2", function()
    print("clicked")
end)

Tab2:CreateToggle("Enable B", false, function(state)
    print(state)
end)

Tab2:CreateSpacer("Spacer 2")

Tab2:CreateDropdown("Mode", {"A","B","C"}, "A", function(choice)
    print(choice) 
end)

Tab2:CreateTextbox("Name", "Type here...", function(text)
    print(text)
end)


local Tab3 = Window:CreateTab("Main")

Tab3:CreateButton("Do thing", function()
    print("clicked")
end)

Tab3:CreateToggle("Enable X", false, function(state)
    print(state)
end)

Tab3:CreateSpacer("Spacer")

Tab3:CreateDropdown("Mode", {"A","B","C"}, "A", function(choice)
    print(choice) 
end)

Tab3:CreateTextbox("Name", "Type here...", function(text)
    print(text)
end)

local Tab4 = Window:CreateTab("Main")
local Tab5 = Window:CreateTab("Main")
local Tab6 = Window:CreateTab("Main")
local Tab7 = Window:CreateTab("Main")
local Tab8 = Window:CreateTab("Main")
local Tab9 = Window:CreateTab("Main")
local Tab10 = Window:CreateTab("Main")
local Tab11 = Window:CreateTab("Main")
local Tab12 = Window:CreateTab("Main")
local Tab13 = Window:CreateTab("Main")
local Tab14 = Window:CreateTab("Main")
local Tab15 = Window:CreateTab("Main")
local Tab16 = Window:CreateTab("Main")
