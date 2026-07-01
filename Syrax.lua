-- // Delta Mobil – MM2: Panel + Zıplama Butonu (Sürüklenebilir)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local cfg = {
    esp_on = true,
    esp_box = true,
    esp_dist = true,
    esp_maxDist = 500,
    aim_on = false,
    aim_maxDist = 120,
    aim_smoothBase = 2.0,
    speed_on = false,
    speed_value = 30,
    jump_on = false,
    team_check = false
}

local jumpButton = nil  -- zıplama butonu

-- Rol renkleri
local ROLE_COLORS = {
    Murderer = Color3.fromRGB(255, 0, 0),
    Sheriff  = Color3.fromRGB(0, 120, 255),
    Innocent = Color3.fromRGB(0, 255, 0),
    Unknown  = Color3.fromRGB(255, 255, 0)
}

-- ==============================================
-- Rol Tespiti
-- ==============================================
local function getPlayerRole(plr)
    local char = plr.Character
    if not char then return "Unknown" end
    local backpack = plr:FindFirstChild("Backpack") or plr
    if backpack:FindFirstChild("Knife") or backpack:FindFirstChild("Murderer") or backpack:FindFirstChild("Killer") then
        return "Murderer"
    end
    if char:FindFirstChild("Knife") or char:FindFirstChild("MurdererWeapon") then
        return "Murderer"
    end
    if backpack:FindFirstChild("Gun") or backpack:FindFirstChild("Sheriff") or backpack:FindFirstChild("Revolver") or backpack:FindFirstChild("Pistol") then
        return "Sheriff"
    end
    if char:FindFirstChild("Gun") or char:FindFirstChild("SheriffWeapon") then
        return "Sheriff"
    end
    local roleObj = plr:FindFirstChild("Role") or plr:FindFirstChild("PlayerRole")
    if roleObj and roleObj:IsA("StringValue") then
        local roleName = roleObj.Value
        if roleName == "Murderer" or roleName == "Killer" then return "Murderer" end
        if roleName == "Sheriff" or roleName == "Hero" then return "Sheriff" end
        if roleName == "Innocent" or roleName == "Civilian" then return "Innocent" end
    end
    return "Innocent"
end

-- ==============================================
-- ESP
-- ==============================================
local ESPData = {}

local function newDrawing(t)
    local ok, d = pcall(function() return Drawing.new(t) end)
    return ok and d or nil
end

local function createESP(plr)
    local d = {}
    d.box = newDrawing("Square")
    if d.box then d.box.Thickness = 2 d.box.Filled = false end
    d.dist = newDrawing("Text")
    if d.dist then d.dist.Size = 13 d.dist.Center = true d.dist.Outline = true d.dist.Color = Color3.new(1,1,1) end
    d.role = newDrawing("Text")
    if d.role then d.role.Size = 12 d.role.Center = true d.role.Outline = true end
    ESPData[plr] = d
end

local function removeESP(plr)
    local d = ESPData[plr]
    if not d then return end
    for _, v in pairs(d) do pcall(function() v:Remove() end) end
    ESPData[plr] = nil
end

local function isInFront(pos)
    local camPos = Camera.CFrame.Position
    return Camera.CFrame.LookVector:Dot((pos - camPos).Unit) > 0
end

local function getBox(character)
    local head = character:FindFirstChild("Head")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local hum = character:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return nil end
    local top = head and (head.Position + Vector3.new(0, 1.5, 0)) or (hrp.Position + Vector3.new(0, 2.5, 0))
    local bottom = hrp.Position - Vector3.new(0, 3, 0)
    local ts, on1 = Camera:WorldToViewportPoint(top)
    local bs, on2 = Camera:WorldToViewportPoint(bottom)
    if not on1 and not on2 then return nil end
    local h = math.abs(ts.Y - bs.Y)
    local w = h * 0.5
    local cx = (ts.X + bs.X) / 2
    return {
        pos = Vector2.new(cx - w/2, math.min(ts.Y, bs.Y)),
        size = Vector2.new(w, h),
        top = Vector2.new(cx, math.min(ts.Y, bs.Y)),
        bottom = Vector2.new(cx, math.min(ts.Y, bs.Y) + h)
    }
end

local function updateESP()
    local my = LocalPlayer.Character
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        local role = getPlayerRole(plr)
        if cfg.team_check and role == getPlayerRole(LocalPlayer) then
            if ESPData[plr] then removeESP(plr) end
            continue
        end
        local char = plr.Character
        if not char then
            if ESPData[plr] then removeESP(plr) end
            continue
        end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then
            if ESPData[plr] then removeESP(plr) end
            continue
        end

        if not cfg.esp_on then
            if ESPData[plr] then for _, v in pairs(ESPData[plr]) do v.Visible = false end end
            continue
        end

        if not isInFront(hrp.Position) then
            if ESPData[plr] then for _, v in pairs(ESPData[plr]) do v.Visible = false end end
            continue
        end

        local dist = 0
        if my and my:FindFirstChild("HumanoidRootPart") then
            dist = (my.HumanoidRootPart.Position - hrp.Position).Magnitude
        end
        if dist > cfg.esp_maxDist then
            if ESPData[plr] then for _, v in pairs(ESPData[plr]) do v.Visible = false end end
            continue
        end

        if not ESPData[plr] then createESP(plr) end
        local d = ESPData[plr]
        if not d then continue end
        local box = getBox(char)
        if not box then for _, v in pairs(d) do v.Visible = false end continue end

        local color = ROLE_COLORS[role] or ROLE_COLORS.Unknown
        if cfg.esp_box and d.box then
            d.box.Visible = true d.box.Position = box.pos d.box.Size = box.size d.box.Color = color
        end
        if cfg.esp_dist and d.dist then
            d.dist.Visible = true d.dist.Text = math.floor(dist) .. "m" d.dist.Position = box.bottom + Vector2.new(0, 2)
        end
        if d.role then
            d.role.Visible = true d.role.Text = role d.role.Color = color d.role.Position = box.top - Vector2.new(0, 15)
        end
    end
end

-- ==============================================
-- ŞERİF AIMBOT
-- ==============================================
local function hasGun()
    local myChar = LocalPlayer.Character
    if not myChar then return false end
    for _, v in ipairs(myChar:GetChildren()) do if v:IsA("Tool") and v.Name == "Gun" then return true end end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then for _, v in ipairs(bp:GetChildren()) do if v:IsA("Tool") and v.Name == "Gun" then return true end end end
    return false
end

local function getClosestMurderer()
    local best, bestDist = nil, cfg.aim_maxDist
    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = myChar.HumanoidRootPart.Position
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer or getPlayerRole(plr) ~= "Murderer" then continue end
        local char = plr.Character
        if not char then continue end
        local head, hrp = char:FindFirstChild("Head"), char:FindFirstChild("HumanoidRootPart")
        if not (head or hrp) then continue end
        local targetPos = head and head.Position or hrp.Position
        local dist = (myPos - targetPos).Magnitude
        if dist < bestDist then bestDist = dist best = plr end
    end
    return best
end

local function aimAt(targetPlayer)
    local char = targetPlayer.Character
    if not char then return end
    local head, hrp = char:FindFirstChild("Head"), char:FindFirstChild("HumanoidRootPart")
    local targetPart = head or hrp
    if not targetPart then return end
    local targetPos = targetPart.Position
    local camPos = Camera.CFrame.Position
    Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(camPos, targetPos), 1 / cfg.aim_smoothBase)
    local myChar = LocalPlayer.Character
    if myChar and myChar:FindFirstChild("HumanoidRootPart") then
        local root = myChar.HumanoidRootPart
        local flatTarget = Vector3.new(targetPos.X, root.Position.Y, targetPos.Z)
        local hum = myChar:FindFirstChildOfClass("Humanoid")
        if hum then hum.AutoRotate = false end
        pcall(function() root.CFrame = root.CFrame:Lerp(CFrame.lookAt(root.Position, flatTarget), 1 / cfg.aim_smoothBase) end)
    end
end

local function updateAimbot()
    if not cfg.aim_on or getPlayerRole(LocalPlayer) ~= "Sheriff" or not hasGun() then return end
    local target = getClosestMurderer()
    if target then aimAt(target) end
end

-- ==============================================
-- SPEED HACK
-- ==============================================
local function applySpeed()
    if LocalPlayer.Character and cfg.speed_on then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = cfg.speed_value end
    end
end
LocalPlayer.CharacterAdded:Connect(function() if cfg.speed_on then wait(0.2) applySpeed() end end)

-- ==============================================
-- SINIRSIZ ZIPLAMA (Sürüklenebilir Buton)
-- ==============================================
local function createJumpButton()
    if jumpButton then jumpButton:Destroy() end
    local gui = Instance.new("ScreenGui", game.CoreGui)
    gui.Name = "JumpButtonGui"

    local btn = Instance.new("TextButton", gui)
    btn.Size = UDim2.new(0, 80, 0, 80)
    btn.Position = UDim2.new(1, -100, 0.8, -40)
    btn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    btn.BackgroundTransparency = 0.5
    btn.Text = "ZIPLA"
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 20
    btn.Visible = cfg.jump_on
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

    -- Sürükleme
    local drag, dragStart, startPos = false, nil, nil
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = true dragStart = input.Position startPos = btn.Position
        end
    end)
    btn.InputEnded:Connect(function() drag = false end)
    btn.InputChanged:Connect(function(input)
        if drag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)

    -- Zıplama eylemi
    btn.MouseButton1Click:Connect(function()
        if not cfg.jump_on then return end
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end
        hum.JumpPower = 16
        local vel = hrp.Velocity
        hrp.Velocity = Vector3.new(vel.X, 50, vel.Z)
        if hum.FloorMaterial ~= Enum.Material.Air then hum.Jump = true end
    end)

    jumpButton = btn
end

-- Butonu cfg.jump_on değiştiğinde kontrol etmek için RenderStepped içinde izleyelim
local function updateJumpButton()
    if jumpButton then jumpButton.Visible = cfg.jump_on end
end

-- ==============================================
-- PANEL
-- ==============================================
local function createPanel()
    local gui = Instance.new("ScreenGui", game.CoreGui)
    gui.Name = "MM2Hack"
    local openBtn = Instance.new("TextButton", gui)
    openBtn.Size = UDim2.new(0,40,0,40) openBtn.Position = UDim2.new(1,-50,0,10)
    openBtn.BackgroundColor3 = Color3.fromRGB(60,60,60) openBtn.Text = "⚙"
    openBtn.TextColor3 = Color3.new(1,1,1) openBtn.Font = Enum.Font.SourceSansBold openBtn.TextSize = 20

    local panel = Instance.new("Frame", gui)
    panel.Size = UDim2.new(0,280,0,200) panel.Position = UDim2.new(1,-290,0,60)
    panel.BackgroundColor3 = Color3.fromRGB(25,25,25) panel.Visible = false
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0,8)

    local drag, dragStart, startPos = false, nil, nil
    panel.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = true dragStart = input.Position startPos = panel.Position
        end
    end)
    panel.InputEnded:Connect(function() drag = false end)
    panel.InputChanged:Connect(function(input)
        if drag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)

    local title = Instance.new("TextLabel", panel)
    title.Size = UDim2.new(1,0,0,28) title.BackgroundColor3 = Color3.fromRGB(40,40,40)
    title.Text = "MM2 Panel" title.TextColor3 = Color3.new(1,1,1) title.Font = Enum.Font.SourceSansBold

    local sidebar = Instance.new("Frame", panel)
    sidebar.Size = UDim2.new(0,80,1,-28) sidebar.Position = UDim2.new(0,0,0,28)
    sidebar.BackgroundColor3 = Color3.fromRGB(35,35,35)

    local content = Instance.new("Frame", panel)
    content.Size = UDim2.new(1,-80,1,-28) content.Position = UDim2.new(0,80,0,28)
    content.BackgroundColor3 = Color3.fromRGB(30,30,30)

    local currentPage = nil
    local function showPage(p) if currentPage then currentPage.Visible = false end
        if p then p.Visible = true currentPage = p end end
    local function addCategory(name, y, page)
        local btn = Instance.new("TextButton", sidebar)
        btn.Size = UDim2.new(1,-6,0,32) btn.Position = UDim2.new(0,3,0,y)
        btn.BackgroundColor3 = Color3.fromRGB(60,60,60) btn.Text = name
        btn.TextColor3 = Color3.new(1,1,1) btn.Font = Enum.Font.SourceSansBold btn.TextSize = 13
        btn.MouseButton1Click:Connect(function() showPage(page) end)
    end
    local function addToggle(parent, name, default, callback, yPos)
        local btn = Instance.new("TextButton", parent)
        btn.Size = UDim2.new(1,-10,0,28) btn.Position = UDim2.new(0,5,0,yPos)
        btn.BackgroundColor3 = default and Color3.fromRGB(0,150,0) or Color3.fromRGB(150,0,0)
        btn.Text = name .. ": " .. (default and "AÇIK" or "KAPALI") btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Enum.Font.SourceSans btn.TextSize = 12
        local toggled = default
        btn.MouseButton1Click:Connect(function()
            toggled = not toggled btn.Text = name .. ": " .. (toggled and "AÇIK" or "KAPALI")
            btn.BackgroundColor3 = toggled and Color3.fromRGB(0,150,0) or Color3.fromRGB(150,0,0) callback(toggled)
        end)
    end

    -- ESP Sayfası
    local espPage = Instance.new("Frame", content) espPage.Size = UDim2.new(1,0,1,0) espPage.BackgroundTransparency = 1
    addToggle(espPage, "ESP", cfg.esp_on, function(v) cfg.esp_on = v end, 5)
    addToggle(espPage, "Kutu", cfg.esp_box, function(v) cfg.esp_box = v end, 35)
    addToggle(espPage, "Mesafe", cfg.esp_dist, function(v) cfg.esp_dist = v end, 65)

    -- Şerif Aim
    local aimPage = Instance.new("Frame", content) aimPage.Size = UDim2.new(1,0,1,0) aimPage.BackgroundTransparency = 1
    addToggle(aimPage, "Şerif Aim", cfg.aim_on, function(v) cfg.aim_on = v end, 5)

    -- Katil (Speed + Jump)
    local killerPage = Instance.new("Frame", content) killerPage.Size = UDim2.new(1,0,1,0) killerPage.BackgroundTransparency = 1
    addToggle(killerPage, "Speed Hack", cfg.speed_on, function(v)
        cfg.speed_on = v
        if v then applySpeed() else if LocalPlayer.Character then local h = LocalPlayer.Character:FindFirstChildOfClass("Humanoid") if h then h.WalkSpeed = 16 end end end
    end, 5)
    addToggle(killerPage, "Sınırsız Zıpla", cfg.jump_on, function(v)
        cfg.jump_on = v
        -- Buton görünürlüğünü güncelle
        if jumpButton then jumpButton.Visible = v end
    end, 35)

    addCategory("ESP", 5, espPage)
    addCategory("Şerif Aim", 42, aimPage)
    addCategory("Katil", 79, killerPage)
    showPage(espPage)

    openBtn.MouseButton1Click:Connect(function() panel.Visible = not panel.Visible end)
end

-- ==============================================
-- BAŞLATMA
-- ==============================================
Players.PlayerRemoving:Connect(function(p) removeESP(p) end)
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function() if ESPData[p] then removeESP(p) end end)
end)

createPanel()
createJumpButton()
applySpeed()

RunService.RenderStepped:Connect(function()
    updateESP()
    updateAimbot()
    updateJumpButton()
end)

print("🔪 MM2: Zıplama Butonu aktif! Sınırsız Zıpla'yı aç, yeşil butona basarak zıpla.")
