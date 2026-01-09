-- ███████╗ ██████╗██╗      ██████╗██████╗ ███████╗███████╗
-- ██╔════╝██╔════╝██║     ██╔════╝██╔══██╗██╔════╝██╔════╝
-- █████╗  ██║     ██║     ██║     ██████╔╝█████╗  ███████╗
-- ██╔══╝  ██║     ██║     ██║     ██╔═══╝ ██╔══╝  ╚════██║
-- ███████╗╚██████╗███████╗╚██████╗██║     ███████╗███████║
-- ╚══════╝ ╚═════╝╚══════╝ ╚═════╝╚═╝     ╚══════╝╚══════╝
-- ECLIPSE HUB - AIMBOT AUTOMÁTICO
-- SEM BOTÃO PARA SEGURAR, FUNCIONA AUTOMATICAMENTE

-- Verificar se já está carregado
if _G.EclipseHubLoaded then return end
_G.EclipseHubLoaded = true

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

-- Player
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local Camera = Workspace.CurrentCamera

-- Configurações
local Config = {
    -- Aimbot
    Enabled = true,
    TargetPart = "Head",
    Smoothness = 0.8,
    Prediction = 0.16,
    
    -- FOV
    UseFOV = true,
    FOVSize = 200,
    FOVVisible = true,
    FOVColor = Color3.fromRGB(148, 0, 211),
    
    -- ESP
    ESP = true,
    BoxESP = true,
    NameESP = true,
    HealthESP = true,
    TeamCheck = true,
    ShowTeam = false,
    VisibleCheck = false,
    IgnoreDead = true,
    
    -- Visual
    Crosshair = true,
    ShowTarget = true,
    Notifications = true,
    
    -- Menu
    MenuOpen = false,
    TouchButtonSize = 60
}

-- Variáveis
local CurrentTarget = nil
local MainGUI = nil
local ESPData = {}
local FOVCircle = nil
local MenuFrame = nil
local CrosshairFrame = nil
local TargetIndicator = nil
local Connections = {}

-- Sistema de Notificações
local function ShowNotification(title, message, duration)
    if not Config.Notifications then return end
    
    duration = duration or 3
    
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "🌑 " .. title,
        Text = message,
        Duration = duration
    })
end

-- Criar FOV Circle
local function CreateFOV()
    if FOVCircle then 
        FOVCircle:Remove()
        FOVCircle = nil
    end
    
    if not Config.UseFOV then return end
    
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Visible = Config.FOVVisible
    FOVCircle.Color = Config.FOVColor
    FOVCircle.Thickness = 2
    FOVCircle.NumSides = 64
    FOVCircle.Filled = false
    FOVCircle.Radius = Config.FOVSize
    FOVCircle.Transparency = 0.5
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end

-- Sistema ESP
local function UpdateESP()
    if not Config.ESP then
        for player, data in pairs(ESPData) do
            if data.Box then data.Box.Visible = false end
            if data.Name then data.Name.Visible = false end
            if data.Health then data.Health.Visible = false end
        end
        return
    end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player == Player then continue end
        
        -- Verificar time
        if Config.TeamCheck then
            if player.Team and Player.Team and player.Team == Player.Team and not Config.ShowTeam then
                if ESPData[player] then
                    if ESPData[player].Box then ESPData[player].Box.Visible = false end
                    if ESPData[player].Name then ESPData[player].Name.Visible = false end
                    if ESPData[player].Health then ESPData[player].Health.Visible = false end
                end
                continue
            end
        end
        
        local character = player.Character
        if not character then
            if ESPData[player] then
                if ESPData[player].Box then ESPData[player].Box.Visible = false end
                if ESPData[player].Name then ESPData[player].Name.Visible = false end
                if ESPData[player].Health then ESPData[player].Health.Visible = false end
            end
            continue
        end
        
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid or (Config.IgnoreDead and humanoid.Health <= 0) then
            if ESPData[player] then
                if ESPData[player].Box then ESPData[player].Box.Visible = false end
                if ESPData[player].Name then ESPData[player].Name.Visible = false end
                if ESPData[player].Health then ESPData[player].Health.Visible = false end
            end
            continue
        end
        
        local head = character:FindFirstChild("Head")
        if not head then continue end
        
        local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position)
        
        if not headOnScreen then
            if ESPData[player] then
                if ESPData[player].Box then ESPData[player].Box.Visible = false end
                if ESPData[player].Name then ESPData[player].Name.Visible = false end
                if ESPData[player].Health then ESPData[player].Health.Visible = false end
            end
            continue
        end
        
        -- Criar ESP objects se não existirem
        if not ESPData[player] then
            ESPData[player] = {}
            
            -- Box
            ESPData[player].Box = Drawing.new("Square")
            ESPData[player].Box.Thickness = 2
            ESPData[player].Box.Filled = false
            
            -- Nome
            ESPData[player].Name = Drawing.new("Text")
            ESPData[player].Name.Size = 14
            ESPData[player].Name.Center = true
            ESPData[player].Name.Outline = true
            
            -- Vida
            ESPData[player].Health = Drawing.new("Text")
            ESPData[player].Health.Size = 12
            ESPData[player].Health.Center = true
            ESPData[player].Health.Outline = true
        end
        
        -- Determinar cor baseada no time
        local boxColor
        if Config.TeamCheck then
            local isEnemy = not (player.Team and Player.Team and player.Team == Player.Team)
            if isEnemy then
                boxColor = Color3.fromRGB(255, 50, 50) -- Vermelho para inimigos
            else
                boxColor = Color3.fromRGB(50, 255, 50) -- Verde para aliados
            end
        else
            boxColor = Color3.fromRGB(255, 50, 50) -- Vermelho para todos
        end
        
        -- Calcular tamanho da box
        local distance = (Camera.CFrame.Position - head.Position).Magnitude
        local size = math.clamp(1000 / distance, 15, 50)
        local boxSize = Vector2.new(size * 1.5, size * 2)
        
        -- Atualizar Box ESP
        if Config.BoxESP then
            ESPData[player].Box.Visible = true
            ESPData[player].Box.Size = boxSize
            ESPData[player].Box.Position = Vector2.new(headPos.X - boxSize.X/2, headPos.Y - boxSize.Y/2)
            ESPData[player].Box.Color = boxColor
        else
            ESPData[player].Box.Visible = false
        end
        
        -- Atualizar Nome ESP
        if Config.NameESP then
            ESPData[player].Name.Visible = true
            ESPData[player].Name.Text = player.Name
            ESPData[player].Name.Position = Vector2.new(headPos.X, headPos.Y - boxSize.Y/2 - 15)
            ESPData[player].Name.Color = boxColor
        else
            ESPData[player].Name.Visible = false
        end
        
        -- Atualizar Vida ESP
        if Config.HealthESP then
            ESPData[player].Health.Visible = true
            local healthPercent = humanoid.Health / humanoid.MaxHealth
            
            -- Cor baseada na vida
            if healthPercent > 0.6 then
                ESPData[player].Health.Color = Color3.fromRGB(0, 255, 0)
            elseif healthPercent > 0.3 then
                ESPData[player].Health.Color = Color3.fromRGB(255, 255, 0)
            else
                ESPData[player].Health.Color = Color3.fromRGB(255, 50, 50)
            end
            
            ESPData[player].Health.Text = math.floor(humanoid.Health) .. " HP"
            ESPData[player].Health.Position = Vector2.new(headPos.X, headPos.Y + boxSize.Y/2 + 10)
        else
            ESPData[player].Health.Visible = false
        end
    end
end

-- Sistema de Aimbot Automático
local function GetClosestTarget()
    if not Config.Enabled then return nil end
    
    local closestPlayer = nil
    local closestDistance = math.huge
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, player in pairs(Players:GetPlayers()) do
        if player == Player then continue end
        
        -- Verificar time
        if Config.TeamCheck then
            if player.Team and Player.Team and player.Team == Player.Team then
                continue
            end
        end
        
        local character = player.Character
        if not character then continue end
        
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid or (Config.IgnoreDead and humanoid.Health <= 0) then continue end
        
        local targetPart = character:FindFirstChild(Config.TargetPart) or character:FindFirstChild("Head")
        if not targetPart then continue end
        
        local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
        if not onScreen then continue end
        
        local screenPoint = Vector2.new(screenPos.X, screenPos.Y)
        local distance = (center - screenPoint).Magnitude
        
        -- Verificar FOV
        if Config.UseFOV and distance > Config.FOVSize then
            continue
        end
        
        -- Verificar visibilidade (opcional)
        if Config.VisibleCheck then
            local ray = Ray.new(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position).Unit * 1000)
            local hit, hitPos = Workspace:FindPartOnRayWithIgnoreList(ray, {Player.Character})
            if hit and not hit:IsDescendantOf(character) then
                continue
            end
        end
        
        if distance < closestDistance then
            closestDistance = distance
            closestPlayer = player
        end
    end
    
    return closestPlayer
end

-- Aimbot Automático (funciona sempre que há alvo)
local function AutoAim()
    if not Config.Enabled then 
        CurrentTarget = nil
        return 
    end
    
    local targetPlayer = GetClosestTarget()
    if not targetPlayer then
        CurrentTarget = nil
        return
    end
    
    -- Atualizar indicador de alvo
    if Config.ShowTarget and TargetIndicator then
        local character = targetPlayer.Character
        if character then
            local head = character:FindFirstChild("Head")
            if head then
                local screenPos = Camera:WorldToViewportPoint(head.Position)
                TargetIndicator.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y)
                TargetIndicator.Visible = true
            end
        end
    end
    
    -- Executar aimbot
    local character = targetPlayer.Character
    if not character then return end
    
    local targetPart = character:FindFirstChild(Config.TargetPart) or character:FindFirstChild("Head")
    if not targetPart then return end
    
    -- Calcular posição com predição
    local targetPosition = targetPart.Position
    if targetPart:IsA("BasePart") then
        targetPosition = targetPosition + (targetPart.Velocity * Config.Prediction)
    end
    
    -- Calcular direção
    local cameraCFrame = Camera.CFrame
    local lookVector = cameraCFrame.LookVector
    local targetDirection = (targetPosition - cameraCFrame.Position).Unit
    
    -- Aplicar suavidade
    local smoothness = math.clamp(Config.Smoothness, 0.1, 1)
    local newLookVector = lookVector:Lerp(targetDirection, smoothness * 0.5)
    
    -- Criar novo CFrame e aplicar
    local newCFrame = CFrame.new(cameraCFrame.Position, cameraCFrame.Position + newLookVector)
    Camera.CFrame = Camera.CFrame:Lerp(newCFrame, smoothness * 0.3)
    
    CurrentTarget = targetPlayer
end

-- Criar Menu de Configurações
local function CreateMenu()
    if MenuFrame then MenuFrame:Destroy() end
    
    MenuFrame = Instance.new("Frame")
    MenuFrame.Name = "EclipseMenu"
    MenuFrame.Size = UDim2.new(0, 350, 0, 450)
    MenuFrame.Position = UDim2.new(0.5, -175, 0.5, -225)
    MenuFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    MenuFrame.BackgroundTransparency = 0.1
    MenuFrame.BorderSizePixel = 0
    MenuFrame.Visible = Config.MenuOpen
    MenuFrame.ZIndex = 100
    MenuFrame.Active = true
    MenuFrame.Draggable = true
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 12)
    UICorner.Parent = MenuFrame
    
    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(148, 0, 211)
    UIStroke.Thickness = 2
    UIStroke.Parent = MenuFrame
    
    -- Barra de Título
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 40)
    TitleBar.BackgroundColor3 = Color3.fromRGB(148, 0, 211)
    TitleBar.BackgroundTransparency = 0.2
    TitleBar.BorderSizePixel = 0
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = TitleBar
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -50, 1, 0)
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "🌑 ECLIPSE HUB"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 18
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TitleBar
    
    local CloseButton = Instance.new("TextButton")
    CloseButton.Name = "CloseButton"
    CloseButton.Size = UDim2.new(0, 30, 0, 30)
    CloseButton.Position = UDim2.new(1, -35, 0.5, -15)
    CloseButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    CloseButton.Text = "X"
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.TextSize = 16
    CloseButton.Font = Enum.Font.GothamBold
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = CloseButton
    
    CloseButton.MouseButton1Click:Connect(function()
        Config.MenuOpen = false
        MenuFrame.Visible = false
    end)
    
    CloseButton.Parent = TitleBar
    TitleBar.Parent = MenuFrame
    
    -- Container das Opções
    local OptionsContainer = Instance.new("ScrollingFrame")
    OptionsContainer.Name = "OptionsContainer"
    OptionsContainer.Size = UDim2.new(1, -20, 1, -60)
    OptionsContainer.Position = UDim2.new(0, 10, 0, 50)
    OptionsContainer.BackgroundTransparency = 1
    OptionsContainer.ScrollBarThickness = 6
    OptionsContainer.ScrollBarImageColor3 = Color3.fromRGB(148, 0, 211)
    OptionsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    OptionsContainer.Parent = MenuFrame
    
    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Padding = UDim.new(0, 8)
    UIListLayout.Parent = OptionsContainer
    
    -- Função para criar Toggles
    local function CreateToggle(name, configKey)
        local toggleFrame = Instance.new("Frame")
        toggleFrame.Size = UDim2.new(1, 0, 0, 40)
        toggleFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        toggleFrame.BackgroundTransparency = 0.1
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = toggleFrame
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.7, -10, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize = 14
        label.Font = Enum.Font.GothamBold
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = toggleFrame
        
        local toggleButton = Instance.new("TextButton")
        toggleButton.Size = UDim2.new(0, 50, 0, 25)
        toggleButton.Position = UDim2.new(1, -60, 0.5, -12.5)
        toggleButton.BackgroundColor3 = Config[configKey] and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
        toggleButton.Text = ""
        toggleButton.AutoButtonColor = false
        
        local toggleCorner = Instance.new("UICorner")
        toggleCorner.CornerRadius = UDim.new(0, 12)
        toggleCorner.Parent = toggleButton
        
        local toggleCircle = Instance.new("Frame")
        toggleCircle.Size = UDim2.new(0, 21, 0, 21)
        toggleCircle.Position = Config[configKey] and UDim2.new(1, -23, 0.5, -10.5) or UDim2.new(0, 2, 0.5, -10.5)
        toggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        toggleCircle.BorderSizePixel = 0
        
        local circleCorner = Instance.new("UICorner")
        circleCorner.CornerRadius = UDim.new(1, 0)
        circleCorner.Parent = toggleCircle
        
        toggleCircle.Parent = toggleButton
        toggleButton.Parent = toggleFrame
        
        toggleButton.MouseButton1Click:Connect(function()
            Config[configKey] = not Config[configKey]
            toggleButton.BackgroundColor3 = Config[configKey] and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
            
            local tween = TweenService:Create(toggleCircle, TweenInfo.new(0.2), {
                Position = Config[configKey] and UDim2.new(1, -23, 0.5, -10.5) or UDim2.new(0, 2, 0.5, -10.5)
            })
            tween:Play()
            
            -- Atualizar sistemas específicos
            if configKey == "UseFOV" or configKey == "FOVVisible" then
                CreateFOV()
            elseif configKey == "ESP" and not Config.ESP then
                for player, data in pairs(ESPData) do
                    if data.Box then data.Box.Visible = false end
                    if data.Name then data.Name.Visible = false end
                    if data.Health then data.Health.Visible = false end
                end
            end
            
            ShowNotification("Config", name .. ": " .. (Config[configKey] and "ON" or "OFF"), 2)
        end)
        
        return toggleFrame
    end
    
    -- Função para criar Sliders
    local function CreateSlider(name, configKey, min, max)
        local sliderFrame = Instance.new("Frame")
        sliderFrame.Size = UDim2.new(1, 0, 0, 50)
        sliderFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        sliderFrame.BackgroundTransparency = 0.1
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = sliderFrame
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -20, 0, 20)
        label.Position = UDim2.new(0, 10, 0, 5)
        label.BackgroundTransparency = 1
        label.Text = name .. ": " .. Config[configKey]
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize = 14
        label.Font = Enum.Font.GothamBold
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = sliderFrame
        
        local slider = Instance.new("Frame")
        slider.Size = UDim2.new(1, -20, 0, 6)
        slider.Position = UDim2.new(0, 10, 1, -15)
        slider.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        
        local sliderCorner = Instance.new("UICorner")
        sliderCorner.CornerRadius = UDim.new(1, 0)
        sliderCorner.Parent = slider
        
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((Config[configKey] - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(148, 0, 211)
        
        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(1, 0)
        fillCorner.Parent =
