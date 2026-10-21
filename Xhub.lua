local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- ================= REMOTES =================
local function waitRemote(parent, name, timeout)
    if not parent then return nil end
    local r = parent:FindFirstChild(name)
    if r then return r end
    local t = tick()
    while tick() - t < (timeout or 5) do
        task.wait(0.1)
        r = parent:FindFirstChild(name)
        if r then return r end
    end
    return nil
end

local GrabEvents      = ReplicatedStorage:WaitForChild("GrabEvents", 10)
local MenuToys        = ReplicatedStorage:WaitForChild("MenuToys", 10)
local PlayerEvents    = ReplicatedStorage:WaitForChild("PlayerEvents", 10)
local CharacterEvents = ReplicatedStorage:WaitForChild("CharacterEvents", 10)

local SetNetworkOwner = waitRemote(GrabEvents, "SetNetworkOwner")
local DestroyGrabLine = waitRemote(GrabEvents, "DestroyGrabLine")
local CreateGrabLine  = waitRemote(GrabEvents, "CreateGrabLine")
local SpawnToyRF      = waitRemote(MenuToys, "SpawnToyRemoteFunction")
local DeleteToyRE     = waitRemote(MenuToys, "DestroyToy")
local StickyPartEvent = waitRemote(PlayerEvents, "StickyPartEvent")

local function fire(remote, ...)
    if remote then pcall(function() remote:FireServer(...) end) end
end
local function invoke(remote, ...)
    if remote then
        local ok, r = pcall(function() return remote:InvokeServer(...) end)
        if ok then return r end
    end
    return nil
end
local function getRoot()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getInv(waitTime)
    local name = LocalPlayer.Name .. "SpawnedInToys"
    local f = workspace:FindFirstChild(name)
    if f then return f end
    if waitTime then
        local t = tick()
        while tick() - t < waitTime do
            task.wait(0.1)
            f = workspace:FindFirstChild(name)
            if f then return f end
        end
    end
    return nil
end
local function waitCanSpawn(timeout)
    local c = LocalPlayer:FindFirstChild("CanSpawnToy")
    if not c then return true end
    local t = tick()
    while not c.Value and tick() - t < (timeout or 5) do
        task.wait(0.05)
    end
    return c.Value
end
local function cleanupAllBodies()
    for _, p in Players:GetPlayers() do
        if p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _, v in ipairs(hrp:GetChildren()) do
                    if v:IsA("BodyPosition") or v:IsA("BodyGyro") or v:IsA("BodyVelocity")
                       or v:IsA("BodyAngularVelocity") or v.Name == "SkyVelocity" or v.Name == "ComboSky"
                       or v.Name == "ComboSpin" or v.Name == "FB_Vel" then
                        pcall(function() v:Destroy() end)
                    end
                end
            end
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                pcall(function() hum.PlatformStand = false end)
                pcall(function() hum.AutoRotate = true end)
            end
        end
    end
end

-- ================= GUI =================
local gui = Instance.new("ScreenGui")
gui.Name = "ComboKickPro"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
pcall(function() gui.Parent = LocalPlayer:WaitForChild("PlayerGui", 5) end)
if not gui.Parent then pcall(function() gui.Parent = game:GetService("CoreGui") end) end
if not gui.Parent then return end

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 55, 0, 55)
toggleBtn.Position = UDim2.new(0, 15, 0.5, -27)
toggleBtn.Text = "K"
toggleBtn.TextSize = 24
toggleBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
toggleBtn.TextColor3 = Color3.fromRGB(255, 220, 0)
toggleBtn.Font = Enum.Font.GothamBlack
toggleBtn.BorderSizePixel = 0
toggleBtn.Parent = gui
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0)
Instance.new("UIStroke", toggleBtn).Color = Color3.fromRGB(255, 200, 0)

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 290, 0, 250)
main.Position = UDim2.new(0, 85, 0.5, -125)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
main.BorderSizePixel = 0
main.Visible = false
main.Active = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

local dragBar = Instance.new("Frame")
dragBar.Size = UDim2.new(1, 0, 0, 40)
dragBar.BackgroundTransparency = 1
dragBar.Active = true
dragBar.Parent = main

local dragging, dragStart, startPos
dragBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = main.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

toggleBtn.MouseButton1Click:Connect(function() main.Visible = not main.Visible end)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -50, 0, 40)
title.Position = UDim2.new(0, 15, 0, 0)
title.BackgroundTransparency = 1
title.Text = "🔥 COMBO KICK PRO"
title.TextColor3 = Color3.fromRGB(255, 200, 0)
title.Font = Enum.Font.GothamBlack
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = dragBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 26, 0, 26)
closeBtn.Position = UDim2.new(1, -34, 0, 7)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 13
closeBtn.BorderSizePixel = 0
closeBtn.Parent = dragBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1, 0)
closeBtn.MouseButton1Click:Connect(function() main.Visible = false end)

-- Target input
local targetLabel = Instance.new("TextLabel")
targetLabel.Size = UDim2.new(1, -30, 0, 18)
targetLabel.Position = UDim2.new(0, 15, 0, 48)
targetLabel.BackgroundTransparency = 1
targetLabel.Text = "🎯 Target (username):"
targetLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
targetLabel.Font = Enum.Font.GothamBold
targetLabel.TextSize = 12
targetLabel.TextXAlignment = Enum.TextXAlignment.Left
targetLabel.Parent = main

local targetBox = Instance.new("TextBox")
targetBox.Size = UDim2.new(1, -30, 0, 34)
targetBox.Position = UDim2.new(0, 15, 0, 70)
targetBox.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
targetBox.TextColor3 = Color3.new(1,1,1)
targetBox.PlaceholderText = "Nhập tên user..."
targetBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 130)
targetBox.Text = ""
targetBox.Font = Enum.Font.Gotham
targetBox.TextSize = 14
targetBox.TextXAlignment = Enum.TextXAlignment.Left
targetBox.ClearTextOnFocus = false
targetBox.BorderSizePixel = 0
targetBox.Parent = main
Instance.new("UICorner", targetBox).CornerRadius = UDim.new(0, 8)
local pad = Instance.new("UIPadding", targetBox)
pad.PaddingLeft = UDim.new(0, 10)

-- NÚT COMBO KICK (TO)
local comboBtn = Instance.new("TextButton")
comboBtn.Size = UDim2.new(1, -30, 0, 55)
comboBtn.Position = UDim2.new(0, 15, 0, 118)
comboBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
comboBtn.Text = "🔥 COMBO KICK 🔥"
comboBtn.TextColor3 = Color3.fromRGB(255, 220, 0)
comboBtn.Font = Enum.Font.GothamBlack
comboBtn.TextSize = 18
comboBtn.BorderSizePixel = 0
comboBtn.Parent = main
Instance.new("UICorner", comboBtn).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", comboBtn).Color = Color3.fromRGB(255, 200, 0)
Instance.new("UIStroke", comboBtn).Thickness = 2

local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(1, -30, 0, 32)
stopBtn.Position = UDim2.new(0, 15, 0, 182)
stopBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
stopBtn.Text = "■ STOP"
stopBtn.TextColor3 = Color3.new(1,1,1)
stopBtn.Font = Enum.Font.GothamBold
stopBtn.TextSize = 13
stopBtn.BorderSizePixel = 0
stopBtn.Parent = main
Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 8)

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -30, 0, 16)
statusLabel.Position = UDim2.new(0, 15, 0, 222)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Idle"
statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 11
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = main

local function setStatus(text, color)
    statusLabel.Text = "Status: " .. tostring(text)
    statusLabel.TextColor3 = color or Color3.fromRGB(150, 150, 150)
end

-- ================= STATE =================
local active = false

local function stopAll()
    active = false
    cleanupAllBodies()
    -- Xóa shuriken đang gắn
    local inv = getInv()
    if inv then
        for _, c in ipairs(inv:GetChildren()) do
            if c.Name == "NinjaShuriken" or tonumber(c.Name) then
                pcall(function() fire(DeleteToyRE, c) end)
            end
        end
    end
    -- Xóa pallet
    if inv then
        for _, c in ipairs(inv:GetChildren()) do
            if c.Name == "PalletLightBrown" then
                pcall(function() fire(DeleteToyRE, c) end)
            end
        end
    end
    comboBtn.Text = "🔥 COMBO KICK 🔥"
    comboBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
    setStatus("Stopped", Color3.fromRGB(200, 100, 100))
end

local function findTarget(input)
    input = input:match("^%s*(.-)%s*$")
    if input == "" then return nil end
    local p = Players:FindFirstChild(input)
    if p then return p end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Name:lower() == input:lower() or plr.DisplayName:lower() == input:lower() then
            return plr
        end
    end
    return nil
end

-- ================= CORE: BRING =================
local function bringTarget(tRoot, myRoot)
    if not tRoot or not tRoot.Parent or not myRoot then return end
    local saved = myRoot.CFrame
    local st = tick()
    while tick() - st < 0.35 do
        if not tRoot.Parent then break end
        myRoot.CFrame = tRoot.CFrame * CFrame.new(0, -15, 0)
        for i = 1, 3 do fire(SetNetworkOwner, tRoot, tRoot.CFrame) end
        fire(DestroyGrabLine, tRoot)
        RunService.Heartbeat:Wait()
    end
    if myRoot.Parent then
        myRoot.CFrame = saved
        myRoot.AssemblyLinearVelocity = Vector3.zero
        myRoot.AssemblyAngularVelocity = Vector3.zero
    end
end

-- ================= COMBO: KICK CHÍNH =================
local function startCombo(targetName)
    active = true
    comboBtn.Text = "🔥 KICKING... 🔥"
    comboBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 80)
    setStatus("Combo running on " .. targetName, Color3.fromRGB(100, 200, 120))

    -- ============ LOOP 1: CORE (Bring + SetNetworkOwner spam + SkyVelocity + Spin) ============
    task.spawn(function()
        while active do
            local t = Players:FindFirstChild(targetName)
            local tChar = t and t.Character
            local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
            local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")
            local myRoot = getRoot()

            if not tRoot or not tHum or tHum.Health <= 0 or not myRoot then
                task.wait(0.2)
                continue
            end

            -- 1) Bring nếu target ở xa
            if (tRoot.Position - myRoot.Position).Magnitude > 29 then
                bringTarget(tRoot, myRoot)
            end

            -- 2) CORE: Spam network ownership (bắt buộc)
            for i = 1, 5 do
                fire(SetNetworkOwner, tRoot, tRoot.CFrame)
                fire(DestroyGrabLine, tRoot)
            end

            -- 3) SKY VELOCITY — bay cực mạnh
            if tRoot:FindFirstChild("ComboSky") then
                pcall(function()
                    tRoot.ComboSky.Velocity = Vector3.new(
                        math.random(-1e10, 1e10),
                        1e15,
                        math.random(-1e10, 1e10)
                    )
                end)
            else
                local bv = Instance.new("BodyVelocity", tRoot)
                bv.Name = "ComboSky"
                bv.Velocity = Vector3.new(math.random(-1e10, 1e10), 1e15, math.random(-1e10, 1e10))
                bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bv.P = 2000
            end

            -- 4) SPIN — xoay tít
            if tRoot:FindFirstChild("ComboSpin") then
                pcall(function()
                    tRoot.ComboSpin.AngularVelocity = Vector3.new(
                        math.random(-20000, 20000),
                        math.random(-20000, 20000),
                        math.random(-20000, 20000)
                    )
                end)
            else
                local bav = Instance.new("BodyAngularVelocity", tRoot)
                bav.Name = "ComboSpin"
                bav.AngularVelocity = Vector3.new(20000, 20000, 20000)
                bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            end

            -- 5) FORCE ragdoll state
            pcall(function()
                tHum.PlatformStand = true
                tHum.Sit = false
                tHum.BreakJointsOnDeath = false
            end)

            task.wait(0.03)
        end
    end)

    -- ============ LOOP 2: PALLET FLING (song song) ============
    task.spawn(function()
        task.wait(0.5)
        if not active then return end
        local myRoot = getRoot()
        if not myRoot then return end
        local homePos = Vector3.new(183.2, -9.6, -559.3)
        local minY = -45

        local function findPallet()
            local inv = getInv()
            if inv then
                for _, p in ipairs(inv:GetChildren()) do
                    if p.Name == "PalletLightBrown" then
                        local sp = p:FindFirstChild("SoundPart")
                        if sp then return p, sp end
                    end
                end
            end
            return nil, nil
        end

        -- Xóa pallet cũ trước
        local oldPallet = findPallet()
        if oldPallet then pcall(function() fire(DeleteToyRE, oldPallet) end) end
        task.wait(0.3)

        -- Spawn mới
        waitCanSpawn(5)
        pcall(function()
            invoke(SpawnToyRF, "PalletLightBrown", myRoot.CFrame * CFrame.new(0, -1, 13), Vector3.zero)
        end)

        local pallet, sp = nil, nil
        local wt = tick()
        while tick() - wt < 5 and active do
            task.wait(0.15)
            pallet, sp = findPallet()
            if pallet and sp then break end
        end

        if not pallet or not sp then
            setStatus("Pallet failed — core kick only", Color3.fromRGB(255, 180, 100))
            return
        end

        -- Chiếm quyền pallet
        local mp = getRoot()
        if mp then
            mp.CFrame = sp.CFrame * CFrame.new(0, 3, 0)
            task.wait(0.15)
            fire(SetNetworkOwner, sp, mp.CFrame)
            task.wait(0.05)
            fire(CreateGrabLine, sp, Vector3.zero, sp.Position, false)
            task.wait(0.05)
            fire(DestroyGrabLine, sp)
            task.wait(0.05)
            fire(SetNetworkOwner, sp, mp.CFrame)
        end

        -- Loop fling
        while active do
            local t = Players:FindFirstChild(targetName)
            local tHRP = t and t.Character and t.Character:FindFirstChild("HumanoidRootPart")
            if not tHRP or not sp.Parent then task.wait(0.2) continue end

            pcall(function()
                sp.CFrame = (tHRP.CFrame + tHRP.AssemblyLinearVelocity * 0.17) * CFrame.new(0, 0, 3)
                sp.AssemblyLinearVelocity = Vector3.zero
                sp.AssemblyAngularVelocity = Vector3.zero
            end)

            local flingStart = tick()
            while tick() - flingStart < 0.1 and active do
                if not tHRP.Parent then break end
                local newPos = Vector3.new(
                    tHRP.Position.X + math.random(-8, 8),
                    math.max(tHRP.Position.Y + math.random(-2, 5), minY),
                    tHRP.Position.Z + math.random(-8, 8)
                )
                pcall(function()
                    sp.CFrame = CFrame.new(newPos)
                    sp.AssemblyLinearVelocity = Vector3.new(math.random(-300,300), math.random(-200,400), math.random(-300,300))
                    sp.AssemblyAngularVelocity = Vector3.new(math.random(-500,500), math.random(-500,500), math.random(-500,500))
                end)
                task.wait(0.02)
            end

            pcall(function()
                sp.CFrame = CFrame.new(homePos)
                sp.AssemblyLinearVelocity = Vector3.zero
                sp.AssemblyAngularVelocity = Vector3.zero
            end)
            task.wait(0.25)
        end
    end)

    -- ============ LOOP 3: SHURIKEN GẮN (song song, mỗi 3s 1 cái) ============
    task.spawn(function()
        task.wait(1)
        while active do
            local t = Players:FindFirstChild(targetName)
            local tRoot = t and t.Character and t.Character:FindFirstChild("HumanoidRootPart")
            local inv = getInv(3)
            if not tRoot or not inv then task.wait(0.5) continue end

            waitCanSpawn(3)
            local shur = nil
            local conn = inv.ChildAdded:Connect(function(c)
                if c.Name == "NinjaShuriken" and not shur then shur = c end
            end)
            pcall(function()
                invoke(SpawnToyRF, "NinjaShuriken", tRoot.Position + Vector3.new(0, 0, 18), Vector3.zero)
            end)
            local st = tick()
            while not shur and tick() - st < 1 and active do task.wait() end
            if conn then conn:Disconnect() end
            if not shur then shur = inv:FindFirstChild("NinjaShuriken") end

            if shur then
                local sticky = shur:FindFirstChild("StickyPart")
                if sticky then
                    local soundPart = shur:FindFirstChild("SoundPart") or sticky
                    fire(SetNetworkOwner, soundPart, soundPart.CFrame)
                    task.wait(0.05)
                    fire(StickyPartEvent, sticky, tRoot, CFrame.Angles(0, 0, 0))
                end
                shur.Name = "ComboShur_" .. tostring(math.random(1000, 9999))
            end
            task.wait(3)
        end
    end)

    -- ============ LOOP 4: AUTO RESPAWN KEEP-UP ============
    task.spawn(function()
        while active do
            local t = Players:FindFirstChild(targetName)
            if t and t.Character then
                local tHum = t.Character:FindFirstChildOfClass("Humanoid")
                if tHum and tHum.Health > 0 then
                    -- Heal check: nếu target bị hồi sinh thì tiếp tục
                end
            end
            task.wait(0.5)
        end
    end)
end

-- ================= BUTTON EVENTS =================
comboBtn.MouseButton1Click:Connect(function()
    if active then
        stopAll()
        return
    end

    local name = targetBox.Text:match("^%s*(.-)%s*$")
    if name == "" then
        setStatus("Nhập tên target!", Color3.fromRGB(200, 100, 100))
        return
    end

    local tp = findTarget(name)
    if not tp then
        setStatus("Không tìm thấy: " .. name, Color3.fromRGB(200, 100, 100))
        return
    end
    if tp == LocalPlayer then
        setStatus("Không thể kick chính mình", Color3.fromRGB(200, 100, 100))
        return
    end
    if not tp.Character or not tp.Character:FindFirstChild("HumanoidRootPart") then
        setStatus("Target chưa spawn", Color3.fromRGB(200, 100, 100))
        return
    end

    startCombo(tp.Name)
end)

stopBtn.MouseButton1Click:Connect(function()
    stopAll()
end)

-- Auto stop khi mình chết
LocalPlayer.CharacterAdded:Connect(function()
    if active then
        task.wait(1)
        stopAll()
    end
end)

-- Nhấn K để mở/đóng
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.K then
        main.Visible = not main.Visible
    end
end)