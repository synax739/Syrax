-- // Delta Mobil – MM2 ESP & Butonlu Aimbot (Bas-çek, ekranda buton)
-- // ESP: Rol renkli kutular, isim, mesafe.
-- // Aimbot: Ekranda özel AIM butonu, basılı tutunca en yakın katile kilitlenir.
-- // Anti-Ban: Rastgele yenileme, hız değişimi.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Ayarlar
local cfg = {
    esp_on = true,
    esp_box = true,
    esp_name = false,
    esp_dist = false,
    esp_hp = false,
    esp_maxDist = 500,
    aim_on = false,
    aim_smoothBase = 2.2,
    aim_maxDist = 120,
    team_check = true
}

-- Rol renkleri
local ROLE_COLORS = {
    Murderer = Color3.fromRGB(255, 0, 0),
    Sheriff   = Color3.fromRGB(0, 120, 255),
    Innocent  = Color3.fromRGB(0, 255, 0),
    Unknown   = Color3.fromRGB(255, 255, 0)
}

-- ////////////////////////////////////////////////
-- // MM2 Rol Tespiti
-- ////////////////////////////////////////////////
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

-- ////////////////////////////////////////////////
-- // ESP SİSTEMİ
-- ////////////////////////////////////////////////
local ESPData = {}

local function newDrawing(t)
    local ok, d = pcall(function() return Drawing.new(t) end)
    return ok and d or nil
end

local function createESP(plr)
    local d = {}
    d.box = newDrawing("Square")
    if d.box then d.box.Thickness = 2 d.box.Filled = false end
    d.name = newDrawing("Text")
    if d.name then d.name.Size = 13 d.name.Center = true d.name.Outline = true d.name.Color = Color3.new(1,1,1) end
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

local function getBox(character)
    local head = character:FindFirstChild("Head")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
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
        top = Vector2.new(cx, math.min(ts.Y, bs.Y))
    }
end

local function updateESP()
    local myRole = getPlayerRole(LocalPlayer)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        local role = getPlayerRole(plr)
        if cfg.team_check and role == myRole then
            if ESPData[plr] then removeESP(plr) end
            continue
        end
        local char = plr.Character
        if not char then
            if ESPData[plr] then removeESP(plr) end
            continue
        end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then
            if ESPData[plr] then removeESP(plr) end
            continue
        end
        if not cfg.esp_on then
            if ESPData[plr] then
                for _, v in pairs(ESPData[plr]) do v.Visible = false end
            end
            continue
        end
        local dist = 0
        local myChar = LocalPlayer.Character
        if myChar and myChar:FindFirstChild("HumanoidRootPart") then
            dist = (myChar.HumanoidRootPart.Position - hrp.Position).Magnitude
        end
        if dist > cfg.esp_maxDist then
            if ESPData[plr] then
                for _, v in pairs(ESPData[plr]) do v.Visible = false end
            end
            continue
        end
        if not ESPData[plr] then createESP(plr) end
        local d = ESPData[plr]
        if not d then continue end
        local box = getBox(char)
        if not box then
            for _, v in pairs(d) do v.Visible = false end
            continue
        end
        local color = ROLE_COLORS[role] or ROLE_COLORS.Unknown
        if cfg.esp_box and d.box then
            d.box.Visible = true
            d.box.Position = box.pos
            d.box.Size = box.size
            d.box.Color = color
        end
        if cfg.esp_name and d.name then
            d.name.Visible = true
            d.name.Text = plr.Name
            d.name.Position = box.top - Vector2.new(0, 15)
        end
        if d.role then
            d.role.Visible = true
            d.role.Text = role
            d.role.Color = color
            d.role.Position = box.top - Vector2.new(0, 30)
        end
    end
end

-- ////////////////////////////////////////////////
-- // AIMBOT (Buton ile manuel kontrol)
-- ////////////////////////////////////////////////
local aimButton = nil
local isAimButtonPressed = false

local function getClosestMurderer()
    local best = nil
    local bestDist = cfg.aim_maxDist
    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = myChar.HumanoidRootPart.Position
    local camPos = Camera.CFrame.Position
    local lookVec = Camera.CFrame.LookVector

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        if getPlayerRole(plr) ~= "Murderer" then continue end
        local char = plr.Character
        if not char then continue end
        local head = char:FindFirstChild("Head")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not (head or hrp) then continue end
        local targetPart = head or hrp
        local dist = (myPos - targetPart.Position).Magnitude
        if dist >= bestDist then continue end
        local toTarget = (targetPart.Position - camPos).Unit
        local angle = math.acos(math.clamp(lookVec:Dot(toTarget), -1, 1))
        if angle > math.rad(90) then continue end
        bestDist = dist
        best = plr
    end
    return best
end

local function aimAt(targetPlayer)
    local char = targetPlayer.Character
    if not char then return false end
    local head = char:FindFirstChild("Head")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local targetPart = head or hrp
    if not targetPart then return false end

    local targetPos = targetPart.Position
    local camPos = Camera.CFrame.Position
    local desiredLook = CFrame.lookAt(camPos, targetPos)

    local randomSmooth = cfg.aim_smoothBase + math.random() * 1.5
    local alpha = 1 / randomSmooth
    if alpha > 1 then alpha = 1 end
    Camera.CFrame = Camera.CFrame:Lerp(desiredLook, alpha)
    return true
end

local function updateAimbot()
    if not cfg.aim_on then
        isAimButtonPressed = false
        if aimButton then aimButton.Visible = false end
        return
    end

    -- Buton görünür olsun
    if aimButton then aimButton.Visible = true end

    if not isAimButtonPressed then return end

    -- Katil hedef bul ve kilitlen
    local myRole = getPlayerRole(LocalPlayer)
    if myRole == "Murderer" then return end

    local target = getClosestMurderer()
    if target then
        aimAt(target)
    end
end

-- ////////////////////////////////////////////////
-- // MOBİL AIM BUTONU
-- ////////////////////////////////////////////////
local function createAimButton()
    if aimButton then aimButton:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "AimButtonGui"
    gui.Parent = game.CoreGui or game.Players.LocalPlayer:WaitForChild("PlayerGui")
    gui.ResetOnSpawn = false

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 80, 0, 80)
    btn.Position = UDim2.new(0.5, -40, 0.7, 0) -- Alt orta
    btn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    btn.BackgroundTransparency = 0.5
    btn.Text = "AIM"
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 24
    btn.Parent = gui
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

    -- Sürüklenebilir yap
    local dragging = false
    local dragStart = nil
    local startPos = nil

    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            if cfg.aim_on then
                isAimButtonPressed = true
            end
            dragging = true
            dragStart = input.Position
            startPos = btn.Position
        end
    end)

    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            isAimButtonPressed = false
            dragging = false
        end
    end)

    btn.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    aimButton = btn
end

-- ////////////////////////////////////////////////
-- // MOBİL MENÜ
-- ////////////////////////////////////////////////
local function createMenu()
    local gui = Instance.new("ScreenGui")
    gui.Name = "MM2SecureUI"
    gui.Parent = game.CoreGui or game.Players.LocalPlayer:WaitForChild("PlayerGui")
    gui.ResetOnSpawn = false

    local openBtn = Instance.new("TextButton")
    openBtn.Size = UDim2.new(0, 40, 0, 40)
    openBtn.Position = UDim2.new(1, -50, 0, 10)
    openBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    openBtn.Text = "⚙"
    openBtn.TextColor3 = Color3.new(1,1,1)
    openBtn.Font = Enum.Font.SourceSansBold
    openBtn.TextSize = 20
    openBtn.Parent = gui
    Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 20)

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 200, 0, 160)
    frame.Position = UDim2.new(1, -210, 0, 60)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = gui

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, 0, 0, 25)
    title.BackgroundColor3 = Color3.fromRGB(40,40,40)
    title.Text = "MM2 Panel"
    title.TextColor3 = Color3.new(1,1,1)
    title.Font = Enum.Font.SourceSansBold

    local y = 30
    local function addToggle(name, default, callback)
        local btn = Instance.new("TextButton", frame)
        btn.Size = UDim2.new(1, -10, 0, 28)
        btn.Position = UDim2.new(0, 5, 0, y)
        btn.BackgroundColor3 = default and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
        btn.Text = name .. ": " .. (default and "AÇIK" or "KAPALI")
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Enum.Font.SourceSans
        btn.TextSize = 13
        local toggled = default
        btn.MouseButton1Click:Connect(function()
            toggled = not toggled
            btn.Text = name .. ": " .. (toggled and "AÇIK" or "KAPALI")
            btn.BackgroundColor3 = toggled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
            callback(toggled)
        end)
        y = y + 30
    end

    addToggle("ESP", cfg.esp_on, function(v) cfg.esp_on = v end)
    addToggle("Aimbot", cfg.aim_on, function(v)
        cfg.aim_on = v
        if not v then
            isAimButtonPressed = false
            if aimButton then aimButton.Visible = false end
        end
    end)
    addToggle("Takım Kontrol", cfg.team_check, function(v) cfg.team_check = v end)

    openBtn.MouseButton1Click:Connect(function()
        frame.Visible = not frame.Visible
    end)
end

-- ////////////////////////////////////////////////
-- // BAŞLATMA
-- ////////////////////////////////////////////////
Players.PlayerRemoving:Connect(function(p) removeESP(p) end)

createMenu()
createAimButton()

RunService.RenderStepped:Connect(function()
    updateESP()
    updateAimbot()
end)

print("🎯 MM2 ESP & Butonlu Aimbot hazır! Aimbot'u aç, ekrandaki kırmızı AIM butonuna basılı tutarak katile kilitlen.")
