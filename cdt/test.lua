local function getBoothOwners()
  local owners = {}
  for _, booth in ipairs(workspace.Map.PlayerBooths:GetChildren()) do
    local ok, label = pcall(function()
      return booth.PlayerBooth.PlayerNameText.SurfaceGui.Text
    end)
    if ok and label.Text ~= "UNCLAIMED!" then
      local name = label.Text:match("^(.+)'s BOOTH!$")
      if name then owners[name:lower()] = true end
    end
  end
  return owners
end
