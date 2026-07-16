local source = game:HttpGet("https://amukerd.github.io/rbx-scripts/UI/Library.lua")

local chunk, err = loadstring(source)

print("source:", typeof(source))
print("chunk:", typeof(chunk))
print("error:", err)

if chunk then
    local success, result = pcall(chunk)

    print("success:", success)
    print("result:", result)
end
