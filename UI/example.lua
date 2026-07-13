local Library = loadstring(game:HttpGet("https://amukerd.github.io/rbx-scripts/UI/Library.lua"))()

local Window = Library:CreateWindow("My Window")
local Tab1 = Window:CreateTab("Main")

Tab1:CreateButton("Do thing", function()
    print("clicked")
end)

Tab1:CreateToggle("Enable X", false, function(state)
    print(state)
end)

Tab1:CreateDropdown("Mode", {"A","B","C"}, "A", function(choice)
    print(choice) 
end)

Tab1:CreateTextbox("Name", "Type here...", function(text)
    print(text)
end)
