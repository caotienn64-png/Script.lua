--[[
    CAO TIẾN MENU - LocalScript
    Phím:
    F          = Bật/Tắt Fly
    T          = Mở/Đóng Menu
    LeftShift  = Sprint
    Space      = Bay lên
    LeftCtrl   = Bay xuống
    W/A/S/D    = Di chuyển khi bay
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Config = {
    WalkSpeed = 16,
    SprintSpeed = 80,

    FlySpeed = 150,
    MinFlySpeed = 30,
    MaxFlySpeed = 600,
    FlySpeedStep = 30,

    JumpPower = 70,
}

local character
local humanoid
local root

local flying = false
local sprinting = false
local menuOpen = true

local bodyGyro
local bodyVelocity

local savedPosition
local currentFlySpeed = Config.FlySpeed

--==================================================
-- GUI
--==================================================

local oldGui = playerGui:FindFirstChild("CaoTienMenu")
if oldGui then
    oldGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CaoTienMenu"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local shadow = Instance.new("ImageLabel")
shadow.Name = "Shadow"
shadow.Size = UDim2.fromOffset(280, 420)
shadow.Position = UDim2.new(0, 12, 0.5, -210)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://1316045217"
shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
shadow.ImageTransparency = 0.6
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(10, 10, 118, 118)
shadow.Parent = screenGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "Main"
mainFrame.Size = UDim2.fromOffset(260, 400)
mainFrame.Position = UDim2.new(0, 25, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 16)
mainCorner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(0, 180, 255)
stroke.Thickness = 1.5
stroke.Transparency = 0.4
stroke.Parent = mainFrame

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 55)
header.BackgroundColor3 = Color3.fromRGB(0, 160, 255)
header.BorderSizePixel = 0
header.Parent = mainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 16)
headerCorner.Parent = header

local headerFix = Instance.new("Frame")
headerFix.Size = UDim2.new(1, 0, 0, 20)
headerFix.Position = UDim2.new(0, 0, 1, -20)
headerFix.BackgroundColor3 = Color3.fromRGB(0, 160, 255)
headerFix.BorderSizePixel = 0
headerFix.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -55, 1, 0)
title.Position = UDim2.fromOffset(12, 0)
title.BackgroundTransparency = 1
title.Text = "⚡ CAO TIẾN MENU"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(30, 30)
closeBtn.Position = UDim2.new(1, -40, 0.5, -15)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.AutoButtonColor = false
closeBtn.Parent = header

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeBtn

local statusBar = Instance.new("Frame")
statusBar.Size = UDim2.new(1, -24, 0, 32)
statusBar.Position = UDim2.fromOffset(12, 65)
statusBar.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
statusBar.BorderSizePixel = 0
statusBar.Parent = mainFrame

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 10)
statusCorner.Parent = statusBar

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -16, 1, 0)
statusLabel.Position = UDim2.fromOffset(8, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(180, 255, 180)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 13
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = statusBar

local function createButton(text, yPos, color, icon)
    local button = Instance.new("TextButton")

    button.Size = UDim2.new(1, -24, 0, 42)
    button.Position = UDim2.fromOffset(12, yPos)
    button.BackgroundColor3 = color
    button.BorderSizePixel = 0
    button.Text = (icon or "") .. "  " .. text
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 15
    button.AutoButtonColor = false
    button.Parent = mainFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = button

    button.MouseEnter:Connect(function()
        local brighter = Color3.new(
            math.min(color.R * 1.2, 1),
            math.min(color.G * 1.2, 1),
            math.min(color.B * 1.2, 1)
        )

        TweenService:Create(
            button,
            TweenInfo.new(0.15),
            {BackgroundColor3 = brighter}
        ):Play()
    end)

    button.MouseLeave:Connect(function()
        TweenService:Create(
            button,
            TweenInfo.new(0.15),
            {BackgroundColor3 = color}
        ):Play()
    end)

    return button
end

local flyBtn = createButton(
    "BẬT / TẮT BAY (F)",
    110,
    Color3.fromRGB(0, 190, 100),
    "✈️"
)

local sprintBtn = createButton(
    "SPRINT (SHIFT)",
    160,
    Color3.fromRGB(255, 140, 0),
    "🏃"
)

local speedUpBtn = createButton(
    "TĂNG TỐC BAY (+)",
    210,
    Color3.fromRGB(0, 140, 255),
    "⬆️"
)

local speedDownBtn = createButton(
    "GIẢM TỐC BAY (-)",
    260,
    Color3.fromRGB(0, 110, 200),
    "⬇️"
)

local savePosBtn = createButton(
    "LƯU VỊ TRÍ",
    310,
    Color3.fromRGB(255, 180, 0),
    "📍"
)

local loadPosBtn = createButton(
    "BAY ĐẾN VỊ TRÍ",
    360,
    Color3.fromRGB(220, 50, 80),
    "🚀"
)

--==================================================
-- STATUS
--==================================================

local function updateStatus()
    local stateText

    if flying then
        stateText = "🔴 Đang bay"
    else
        stateText = "🟢 Sẵn sàng"
    end

    statusLabel.Text =
        stateText ..
        "  |  Tốc độ bay: " ..
        tostring(currentFlySpeed)

    if flying then
        statusLabel.TextColor3 = Color3.fromRGB(255, 120, 120)
    else
        statusLabel.TextColor3 = Color3.fromRGB(180, 255, 180)
    end
end

--==================================================
-- FLY
--==================================================

local function cleanupFly()
    if bodyGyro then
        bodyGyro:Destroy()
        bodyGyro = nil
    end

    if bodyVelocity then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end

    if humanoid and humanoid.Parent then
        humanoid.PlatformStand = false
    end

    flying = false
end

local function startFly()
    if flying then
        return
    end

    if not character or not character.Parent then
        return
    end

    if not humanoid or not humanoid.Parent then
        return
    end

    if not root or not root.Parent then
        return
    end

    flying = true

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.Name = "CaoTienFlyGyro"
    bodyGyro.P = 90000
    bodyGyro.D = 500
    bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bodyGyro.CFrame = root.CFrame
    bodyGyro.Parent = root

    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Name = "CaoTienFlyVelocity"
    bodyVelocity.Velocity = Vector3.zero
    bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bodyVelocity.P = 9000
    bodyVelocity.Parent = root

    humanoid.PlatformStand = true

    flyBtn.Text = "🛑  TẮT BAY (F)"
    flyBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)

    updateStatus()
end

local function stopFly()
    if not flying then
        return
    end

    cleanupFly()

    flyBtn.Text = "✈️  BẬT / TẮT BAY (F)"
    flyBtn.BackgroundColor3 = Color3.fromRGB(0, 190, 100)

    updateStatus()
end

local function toggleFly()
    if flying then
        stopFly()
    else
        startFly()
    end
end

--==================================================
-- SPRINT
--==================================================

local function setSprint(state)
    sprinting = state

    if humanoid and humanoid.Parent then
        if not flying then
            humanoid.WalkSpeed =
                sprinting and Config.SprintSpeed or Config.WalkSpeed
        end
    end

    if sprinting then
        sprintBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 0)
        sprintBtn.Text = "🔥  ĐANG SPRINT"
    else
        sprintBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
        sprintBtn.Text = "🏃  SPRINT (SHIFT)"
    end
end

--==================================================
-- MENU
--==================================================

local function toggleMenu()
    menuOpen = not menuOpen

    mainFrame.Visible = menuOpen
    shadow.Visible = menuOpen
end

--==================================================
-- BUTTON EVENTS
--==================================================

flyBtn.MouseButton1Click:Connect(function()
    toggleFly()
end)

sprintBtn.MouseButton1Click:Connect(function()
    setSprint(not sprinting)
end)

speedUpBtn.MouseButton1Click:Connect(function()
    currentFlySpeed = math.min(
        currentFlySpeed + Config.FlySpeedStep,
        Config.MaxFlySpeed
    )

    updateStatus()
end)

speedDownBtn.MouseButton1Click:Connect(function()
    currentFlySpeed = math.max(
        currentFlySpeed - Config.FlySpeedStep,
        Config.MinFlySpeed
    )

    updateStatus()
end)

savePosBtn.MouseButton1Click:Connect(function()
    if root and root.Parent then
        savedPosition = root.CFrame

        savePosBtn.Text = "✅  ĐÃ LƯU!"

        task.delay(1.2, function()
            if savePosBtn and savePosBtn.Parent then
                savePosBtn.Text = "📍  LƯU VỊ TRÍ"
            end
        end)
    end
end)

loadPosBtn.MouseButton1Click:Connect(function()
    if not savedPosition then
        return
    end

    if not root or not root.Parent then
        return
    end

    local wasFlying = flying

    if wasFlying then
        stopFly()
    end

    root.CFrame = savedPosition
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero

    if wasFlying then
        task.wait()
        startFly()
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    toggleMenu()
end)

--==================================================
-- KEYBOARD
--==================================================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then
        return
    end

    if input.KeyCode == Enum.KeyCode.F then
        toggleFly()

    elseif input.KeyCode == Enum.KeyCode.T then
        toggleMenu()

    elseif input.KeyCode == Enum.KeyCode.LeftShift then
        setSprint(true)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftShift then
        setSprint(false)
    end
end)

--==================================================
-- FLY MOVEMENT
--==================================================

RunService.RenderStepped:Connect(function()
    if not flying then
        return
    end

    if not bodyVelocity or not bodyGyro then
        return
    end

    if not root or not root.Parent then
        cleanupFly()
        updateStatus()
        return
    end

    if not humanoid or not humanoid.Parent then
        cleanupFly()
        updateStatus()
        return
    end

    local camera = workspace.CurrentCamera

    if not camera then
        return
    end

    local direction = Vector3.zero

    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        direction += camera.CFrame.LookVector
    end

    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        direction -= camera.CFrame.LookVector
    end

    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        direction -= camera.CFrame.RightVector
    end

    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        direction += camera.CFrame.RightVector
    end

    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        direction += Vector3.new(0, 1, 0)
    end

    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        direction -= Vector3.new(0, 1, 0)
    end

    if direction.Magnitude > 0.01 then
        bodyVelocity.Velocity =
            direction.Unit * currentFlySpeed
    else
        bodyVelocity.Velocity = Vector3.zero
    end

    bodyGyro.CFrame = camera.CFrame
end)

--==================================================
-- CHARACTER
--==================================================

local function setupCharacter(newCharacter)
    cleanupFly()

    character = newCharacter

    humanoid = character:WaitForChild("Humanoid", 10)
    root = character:WaitForChild("HumanoidRootPart", 10)

    if not humanoid or not root then
        return
    end

    humanoid.WalkSpeed = Config.WalkSpeed
    humanoid.UseJumpPower = true
    humanoid.JumpPower = Config.JumpPower

    sprinting = false

    flyBtn.Text = "✈️  BẬT / TẮT BAY (F)"
    flyBtn.BackgroundColor3 = Color3.fromRGB(0, 190, 100)

    sprintBtn.Text = "🏃  SPRINT (SHIFT)"
    sprintBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 0)

    updateStatus()

    humanoid.Died:Connect(function()
        cleanupFly()
        sprinting = false
        updateStatus()
    end)
end

if player.Character then
    task.spawn(setupCharacter, player.Character)
end

player.CharacterAdded:Connect(function(newCharacter)
    setupCharacter(newCharacter)
end)

--==================================================
-- START
--==================================================

updateStatus()

print("✅ Cao Tiến Menu đã sẵn sàng!")
print("F = Fly | T = Menu | Shift = Sprint")
