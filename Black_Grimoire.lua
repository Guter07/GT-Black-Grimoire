local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local VERSION = "1.3"

local GITHUB_OWNER = "daviitthu"
local GITHUB_REPO = "GT-Black-Grimoire"
local GITHUB_FILE = "whitelist.txt"
local GITHUB_BRANCH = "main"

local WHITELIST_URL = string.format(
    "https://raw.githubusercontent.com/%s/%s/%s/%s",
    GITHUB_OWNER,
    GITHUB_REPO,
    GITHUB_BRANCH,
    GITHUB_FILE
)

local function checkWhitelist()
    local maxAttempts = 3
    local result = nil
    local success = false

    for attempt = 1, maxAttempts do
        local ok, res = pcall(function()
            return game:HttpGet(WHITELIST_URL)
        end)

        if ok and res and #res > 0 then
            success = true
            result = res
            break
        end

        task.wait(1 + attempt * 0.5)
    end

    if not success then
        player:Kick("Erro ao verificar acesso.")
        return
    end

    local authorized = false
    for line in string.gmatch(result, "[^\r\n]+") do
        local trimmed = line:match("^%s*(.-)%s*$")
        if trimmed == player.Name or trimmed == tostring(player.UserId) then
            authorized = true
            break
        end
    end

    if not authorized then
        player:Kick("Acesso negado.")
    end
end

checkWhitelist()

local farmEnabled = false
local selectedNPCs = {}
local selectedPlayers = {}
local connection
local npcButtons = {}
local playerButtons = {}
local toolButtons = {}
local selectedTool = "Combat"
local toolRefreshConnection
local combatMode = "NPCs"

local toolsExpanded = true
local targetsExpanded = true
local combatExpanded = true
local teleportExpanded = true

local teleportLocations = {
    ["Dungeon"] = {y = 45.1918830871582, x = 139.3099365234375, z = -2548.953857421875},
    ["Javali"] = {y = 45.073970794677737, x = -77.96652221679688, z = -1789.088134765625},
    ["Boss Licht"] = {y = 45.073970794677737, x = 87.90877532958985, z = -2086.21630859375},
    ["Bruxa"] = {y = 41.31300735473633, x = -4768.6005859375, z = -1969.3746337890626},
    ["Torre"] = {y = 54.950958251953128, x = 17.979358673095704, z = -1549.8367919921876},
    ["Golem"] = {y = 45.073970794677737, x = -933.8577880859375, z = -2539.48486328125}
}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GTMenuGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local function teleportToLocation(locationName)
    if not teleportLocations[locationName] then
        return false
    end
    
    local location = teleportLocations[locationName]
    local character = player.Character
    
    if not character then
        return false
    end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    
    if not humanoidRootPart or not humanoid then
        return false
    end
    
    local targetPosition = Vector3.new(location.x, location.y, location.z)
    
    humanoid.PlatformStand = true
    
    local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(humanoidRootPart, tweenInfo, {CFrame = CFrame.new(targetPosition)})
    tween:Play()
    
    spawn(function()
        wait(1.2)
        humanoid.PlatformStand = false
    end)
    
    return true
end

local function createMainMenu()
    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(0, 50, 0, 50)
    toggleButton.Position = UDim2.new(0.5, -25, 0, 80)
    toggleButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    toggleButton.Text = "GT"
    toggleButton.TextColor3 = Color3.new(1, 1, 1)
    toggleButton.TextSize = 16
    toggleButton.Font = Enum.Font.SourceSansBold
    toggleButton.BorderSizePixel = 1
    toggleButton.BorderColor3 = Color3.new(0.4, 0.4, 0.4)
    toggleButton.Parent = screenGui
    
    local corner1 = Instance.new("UICorner")
    corner1.CornerRadius = UDim.new(0, 25)
    corner1.Parent = toggleButton
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 280, 0, 500)
    mainFrame.Position = UDim2.new(0.5, -140, 0, 140)
    mainFrame.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
    mainFrame.BorderSizePixel = 1
    mainFrame.BorderColor3 = Color3.new(0.3, 0.3, 0.3)
    mainFrame.Visible = false
    mainFrame.Parent = screenGui
    
    local corner2 = Instance.new("UICorner")
    corner2.CornerRadius = UDim.new(0, 6)
    corner2.Parent = mainFrame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -40, 0, 30)
    titleLabel.Position = UDim2.new(0, 10, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "GT Menu v" .. VERSION
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.TextSize = 16
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.Parent = mainFrame
    
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 25, 0, 25)
    closeButton.Position = UDim2.new(1, -30, 0, 5)
    closeButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextSize = 12
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.BorderSizePixel = 0
    closeButton.Parent = mainFrame
    
    local corner3 = Instance.new("UICorner")
    corner3.CornerRadius = UDim.new(0, 3)
    corner3.Parent = closeButton
    
    local combatHeaderButton = Instance.new("TextButton")
    combatHeaderButton.Size = UDim2.new(1, -20, 0, 25)
    combatHeaderButton.Position = UDim2.new(0, 10, 0, 40)
    combatHeaderButton.BackgroundColor3 = Color3.new(0.25, 0.25, 0.25)
    combatHeaderButton.BorderSizePixel = 0
    combatHeaderButton.Text = "Combate ▼"
    combatHeaderButton.TextColor3 = Color3.new(1, 1, 1)
    combatHeaderButton.TextSize = 12
    combatHeaderButton.Font = Enum.Font.SourceSansBold
    combatHeaderButton.Parent = mainFrame
    
    local corner4 = Instance.new("UICorner")
    corner4.CornerRadius = UDim.new(0, 4)
    corner4.Parent = combatHeaderButton
    
    local combatFrame = Instance.new("Frame")
    combatFrame.Size = UDim2.new(1, -20, 0, 70)
    combatFrame.Position = UDim2.new(0, 10, 0, 70)
    combatFrame.BackgroundTransparency = 1
    combatFrame.Parent = mainFrame
    
    local npcModeButton = Instance.new("TextButton")
    npcModeButton.Size = UDim2.new(0, 70, 0, 30)
    npcModeButton.Position = UDim2.new(0, 0, 0, 0)
    npcModeButton.BackgroundColor3 = Color3.new(0.2, 0.6, 0.2)
    npcModeButton.Text = "NPCs"
    npcModeButton.TextColor3 = Color3.new(1, 1, 1)
    npcModeButton.TextSize = 12
    npcModeButton.Font = Enum.Font.SourceSans
    npcModeButton.BorderSizePixel = 0
    npcModeButton.Parent = combatFrame
    
    local corner4a = Instance.new("UICorner")
    corner4a.CornerRadius = UDim.new(0, 4)
    corner4a.Parent = npcModeButton
    
    local pvpModeButton = Instance.new("TextButton")
    pvpModeButton.Size = UDim2.new(0, 70, 0, 30)
    pvpModeButton.Position = UDim2.new(0, 80, 0, 0)
    pvpModeButton.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
    pvpModeButton.Text = "PvP"
    pvpModeButton.TextColor3 = Color3.new(1, 1, 1)
    pvpModeButton.TextSize = 12
    pvpModeButton.Font = Enum.Font.SourceSans
    pvpModeButton.BorderSizePixel = 0
    pvpModeButton.Parent = combatFrame
    
    local corner4b = Instance.new("UICorner")
    corner4b.CornerRadius = UDim.new(0, 4)
    corner4b.Parent = pvpModeButton
    
    local farmButton = Instance.new("TextButton")
    farmButton.Size = UDim2.new(0, 70, 0, 30)
    farmButton.Position = UDim2.new(0, 160, 0, 0)
    farmButton.BackgroundColor3 = Color3.new(0.2, 0.6, 0.2)
    farmButton.Text = "Iniciar"
    farmButton.TextColor3 = Color3.new(1, 1, 1)
    farmButton.TextSize = 12
    farmButton.Font = Enum.Font.SourceSans
    farmButton.BorderSizePixel = 0
    farmButton.Parent = combatFrame
    
    local corner4c = Instance.new("UICorner")
    corner4c.CornerRadius = UDim.new(0, 4)
    corner4c.Parent = farmButton
    
    local statusFrame = Instance.new("Frame")
    statusFrame.Size = UDim2.new(1, 0, 0, 20)
    statusFrame.Position = UDim2.new(0, 0, 0, 40)
    statusFrame.BackgroundColor3 = Color3.new(0.25, 0.25, 0.25)
    statusFrame.BorderSizePixel = 0
    statusFrame.Parent = combatFrame
    
    local corner4d = Instance.new("UICorner")
    corner4d.CornerRadius = UDim.new(0, 3)
    corner4d.Parent = statusFrame
    
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -10, 1, 0)
    statusLabel.Position = UDim2.new(0, 5, 0, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Status: Pronto"
    statusLabel.TextColor3 = Color3.new(1, 1, 1)
    statusLabel.TextSize = 10
    statusLabel.Font = Enum.Font.SourceSans
    statusLabel.Parent = statusFrame
    
    local toolsHeaderButton = Instance.new("TextButton")
    toolsHeaderButton.Size = UDim2.new(1, -20, 0, 25)
    toolsHeaderButton.Position = UDim2.new(0, 10, 0, 150)
    toolsHeaderButton.BackgroundColor3 = Color3.new(0.25, 0.25, 0.25)
    toolsHeaderButton.BorderSizePixel = 0
    toolsHeaderButton.Text = "Ferramentas ▼"
    toolsHeaderButton.TextColor3 = Color3.new(1, 1, 1)
    toolsHeaderButton.TextSize = 12
    toolsHeaderButton.Font = Enum.Font.SourceSansBold
    toolsHeaderButton.Parent = mainFrame
    
    local corner5 = Instance.new("UICorner")
    corner5.CornerRadius = UDim.new(0, 4)
    corner5.Parent = toolsHeaderButton
    
    local toolsFrame = Instance.new("Frame")
    toolsFrame.Size = UDim2.new(1, -20, 0, 90)
    toolsFrame.Position = UDim2.new(0, 10, 0, 180)
    toolsFrame.BackgroundTransparency = 1
    toolsFrame.Parent = mainFrame
    
    local selectedToolFrame = Instance.new("Frame")
    selectedToolFrame.Size = UDim2.new(1, -60, 0, 20)
    selectedToolFrame.Position = UDim2.new(0, 0, 0, 0)
    selectedToolFrame.BackgroundColor3 = Color3.new(0.25, 0.25, 0.25)
    selectedToolFrame.BorderSizePixel = 0
    selectedToolFrame.Parent = toolsFrame
    
    local corner6a = Instance.new("UICorner")
    corner6a.CornerRadius = UDim.new(0, 3)
    corner6a.Parent = selectedToolFrame
    
    local selectedToolLabel = Instance.new("TextLabel")
    selectedToolLabel.Size = UDim2.new(1, -10, 1, 0)
    selectedToolLabel.Position = UDim2.new(0, 5, 0, 0)
    selectedToolLabel.BackgroundTransparency = 1
    selectedToolLabel.Text = selectedTool
    selectedToolLabel.TextColor3 = Color3.new(0.3, 1, 0.3)
    selectedToolLabel.TextSize = 10
    selectedToolLabel.Font = Enum.Font.SourceSans
    selectedToolLabel.Parent = selectedToolFrame
    
    local refreshToolsButton = Instance.new("TextButton")
    refreshToolsButton.Size = UDim2.new(0, 50, 0, 20)
    refreshToolsButton.Position = UDim2.new(1, -50, 0, 0)
    refreshToolsButton.BackgroundColor3 = Color3.new(0.6, 0.4, 0.2)
    refreshToolsButton.Text = "Refresh"
    refreshToolsButton.TextColor3 = Color3.new(1, 1, 1)
    refreshToolsButton.TextSize = 9
    refreshToolsButton.Font = Enum.Font.SourceSans
    refreshToolsButton.BorderSizePixel = 0
    refreshToolsButton.Parent = toolsFrame
    
    local corner6b = Instance.new("UICorner")
    corner6b.CornerRadius = UDim.new(0, 3)
    corner6b.Parent = refreshToolsButton
    
    local toolScrollFrame = Instance.new("ScrollingFrame")
    toolScrollFrame.Size = UDim2.new(1, 0, 0, 60)
    toolScrollFrame.Position = UDim2.new(0, 0, 0, 25)
    toolScrollFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    toolScrollFrame.BorderSizePixel = 1
    toolScrollFrame.BorderColor3 = Color3.new(0.3, 0.3, 0.3)
    toolScrollFrame.ScrollBarThickness = 4
    toolScrollFrame.ScrollBarImageColor3 = Color3.new(0.5, 0.5, 0.5)
    toolScrollFrame.Parent = toolsFrame
    
    local corner7 = Instance.new("UICorner")
    corner7.CornerRadius = UDim.new(0, 3)
    corner7.Parent = toolScrollFrame
    
    local toolListLayout = Instance.new("UIListLayout")
    toolListLayout.SortOrder = Enum.SortOrder.Name
    toolListLayout.Padding = UDim.new(0, 1)
    toolListLayout.Parent = toolScrollFrame
    
    local targetsHeaderButton = Instance.new("TextButton")
    targetsHeaderButton.Size = UDim2.new(1, -20, 0, 25)
    targetsHeaderButton.Position = UDim2.new(0, 10, 0, 280)
    targetsHeaderButton.BackgroundColor3 = Color3.new(0.25, 0.25, 0.25)
    targetsHeaderButton.BorderSizePixel = 0
    targetsHeaderButton.Text = "Alvos ▼"
    targetsHeaderButton.TextColor3 = Color3.new(1, 1, 1)
    targetsHeaderButton.TextSize = 12
    targetsHeaderButton.Font = Enum.Font.SourceSansBold
    targetsHeaderButton.Parent = mainFrame
    
    local corner8 = Instance.new("UICorner")
    corner8.CornerRadius = UDim.new(0, 4)
    corner8.Parent = targetsHeaderButton
    
    local targetsFrame = Instance.new("Frame")
    targetsFrame.Size = UDim2.new(1, -20, 0, 130)
    targetsFrame.Position = UDim2.new(0, 10, 0, 310)
    targetsFrame.BackgroundTransparency = 1
    targetsFrame.Parent = mainFrame
    
    local refreshTargetsButton = Instance.new("TextButton")
    refreshTargetsButton.Size = UDim2.new(0, 50, 0, 20)
    refreshTargetsButton.Position = UDim2.new(1, -50, 0, 0)
    refreshTargetsButton.BackgroundColor3 = Color3.new(0.2, 0.4, 0.6)
    refreshTargetsButton.Text = "Refresh"
    refreshTargetsButton.TextColor3 = Color3.new(1, 1, 1)
    refreshTargetsButton.TextSize = 9
    refreshTargetsButton.Font = Enum.Font.SourceSans
    refreshTargetsButton.BorderSizePixel = 0
    refreshTargetsButton.Parent = targetsFrame
    
    local corner8a = Instance.new("UICorner")
    corner8a.CornerRadius = UDim.new(0, 3)
    corner8a.Parent = refreshTargetsButton
    
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, 0, 0, 100)
    scrollFrame.Position = UDim2.new(0, 0, 0, 25)
    scrollFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    scrollFrame.BorderSizePixel = 1
    scrollFrame.BorderColor3 = Color3.new(0.3, 0.3, 0.3)
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.ScrollBarImageColor3 = Color3.new(0.5, 0.5, 0.5)
    scrollFrame.Parent = targetsFrame
    
    local corner9 = Instance.new("UICorner")
    corner9.CornerRadius = UDim.new(0, 3)
    corner9.Parent = scrollFrame
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.Name
    listLayout.Padding = UDim.new(0, 1)
    listLayout.Parent = scrollFrame
    
    local teleportHeaderButton = Instance.new("TextButton")
    teleportHeaderButton.Size = UDim2.new(1, -20, 0, 25)
    teleportHeaderButton.Position = UDim2.new(0, 10, 0, 450)
    teleportHeaderButton.BackgroundColor3 = Color3.new(0.25, 0.25, 0.25)
    teleportHeaderButton.BorderSizePixel = 0
    teleportHeaderButton.Text = "Teleporte ▼"
    teleportHeaderButton.TextColor3 = Color3.new(1, 1, 1)
    teleportHeaderButton.TextSize = 12
    teleportHeaderButton.Font = Enum.Font.SourceSansBold
    teleportHeaderButton.Parent = mainFrame
    
    local corner10 = Instance.new("UICorner")
    corner10.CornerRadius = UDim.new(0, 4)
    corner10.Parent = teleportHeaderButton
    
    local teleportFrame = Instance.new("Frame")
    teleportFrame.Size = UDim2.new(1, -20, 0, 120)
    teleportFrame.Position = UDim2.new(0, 10, 0, 480)
    teleportFrame.BackgroundTransparency = 1
    teleportFrame.Parent = mainFrame
    
    local teleportScrollFrame = Instance.new("ScrollingFrame")
    teleportScrollFrame.Size = UDim2.new(1, 0, 0, 90)
    teleportScrollFrame.Position = UDim2.new(0, 0, 0, 0)
    teleportScrollFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    teleportScrollFrame.BorderSizePixel = 1
    teleportScrollFrame.BorderColor3 = Color3.new(0.3, 0.3, 0.3)
    teleportScrollFrame.ScrollBarThickness = 4
    teleportScrollFrame.ScrollBarImageColor3 = Color3.new(0.5, 0.5, 0.5)
    teleportScrollFrame.Parent = teleportFrame
    
    local corner11 = Instance.new("UICorner")
    corner11.CornerRadius = UDim.new(0, 3)
    corner11.Parent = teleportScrollFrame
    
    local teleportListLayout = Instance.new("UIListLayout")
    teleportListLayout.SortOrder = Enum.SortOrder.Name
    teleportListLayout.Padding = UDim.new(0, 2)
    teleportListLayout.Parent = teleportScrollFrame
    
    local creditsLabel = Instance.new("TextLabel")
    creditsLabel.Size = UDim2.new(1, -20, 0, 15)
    creditsLabel.Position = UDim2.new(0, 10, 1, -20)
    creditsLabel.BackgroundTransparency = 1
    creditsLabel.Text = "Créditos: Guter07 | Discord: _ninguem2.0_"
    creditsLabel.TextColor3 = Color3.new(0.6, 0.6, 0.6)
    creditsLabel.TextSize = 8
    creditsLabel.Font = Enum.Font.SourceSans
    creditsLabel.Parent = mainFrame
    
    local attackSpeed = 0.08
    
    local function updateSectionVisibility()
        combatFrame.Visible = combatExpanded
        combatHeaderButton.Text = combatExpanded and "Combate ▼" or "Combate ▶"
        
        toolsFrame.Visible = toolsExpanded
        toolsHeaderButton.Text = toolsExpanded and "Ferramentas ▼" or "Ferramentas ▶"
        
        targetsFrame.Visible = targetsExpanded
        targetsHeaderButton.Text = targetsExpanded and "Alvos ▼" or "Alvos ▶"
        
        teleportFrame.Visible = teleportExpanded
        teleportHeaderButton.Text = teleportExpanded and "Teleporte ▼" or "Teleporte ▶"
        
        local yPos = 40
        
        combatHeaderButton.Position = UDim2.new(0, 10, 0, yPos)
        yPos = yPos + 30
        
        if combatExpanded then
            combatFrame.Position = UDim2.new(0, 10, 0, yPos)
            yPos = yPos + 75
        end
        
        toolsHeaderButton.Position = UDim2.new(0, 10, 0, yPos)
        yPos = yPos + 30
        
        if toolsExpanded then
            toolsFrame.Position = UDim2.new(0, 10, 0, yPos)
            yPos = yPos + 95
        end
        
        targetsHeaderButton.Position = UDim2.new(0, 10, 0, yPos)
        yPos = yPos + 30
        
        if targetsExpanded then
            targetsFrame.Position = UDim2.new(0, 10, 0, yPos)
            yPos = yPos + 135
        end
        
        teleportHeaderButton.Position = UDim2.new(0, 10, 0, yPos)
        yPos = yPos + 30
        
        if teleportExpanded then
            teleportFrame.Position = UDim2.new(0, 10, 0, yPos)
            yPos = yPos + 125
        end
        
        mainFrame.Size = UDim2.new(0, 280, 0, math.max(300, yPos + 25))
    end
    
    local function makeDraggable(gui)
        local dragging
        local dragInput
        local dragStart
        local startPos

        local function update(input)
            local delta = input.Position - dragStart
            gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end

        gui.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = gui.Position
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)

        gui.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                update(input)
            end
        end)
    end
    
    makeDraggable(toggleButton)
    makeDraggable(mainFrame)
    
    local function getTool()
        for _, tool in pairs(player.Backpack:GetChildren()) do
            if tool.Name == selectedTool then
                return tool
            end
        end
        if player.Character then
            for _, tool in pairs(player.Character:GetChildren()) do
                if tool.Name == selectedTool and tool:IsA("Tool") then
                    return tool
                end
            end
        end
        return nil
    end
    
    local function equipTool()
        local tool = getTool()
        if tool and player.Character and player.Character:FindFirstChild("Humanoid") then
            if tool.Parent == player.Backpack then
                player.Character.Humanoid:EquipTool(tool)
            end
            return tool
        end
        return nil
    end
    
    local function getNearestSelectedNPC()
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            return nil
        end
        
        local badNPCs = nil
        for _, child in pairs(Workspace:GetChildren()) do
            if string.match(child.Name, "^BadEntities%d*$") then
                badNPCs = child
                break
            end
        end
        if not badNPCs then return nil end
        
        local nearestNPC = nil
        local nearestDistance = math.huge
        
        for npcName, _ in pairs(selectedNPCs) do
            for _, npc in pairs(badNPCs:GetChildren()) do
                if npc.Name == npcName and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 and npc:FindFirstChild("HumanoidRootPart") then
                    local distance = (player.Character.HumanoidRootPart.Position - npc.HumanoidRootPart.Position).Magnitude
                    if distance < nearestDistance then
                        nearestDistance = distance
                        nearestNPC = npc
                    end
                end
            end
        end
        
        return nearestNPC
    end
    
    local function getNearestSelectedPlayer()
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            return nil
        end
        
        local nearestPlayer = nil
        local nearestDistance = math.huge
        
        for playerName, _ in pairs(selectedPlayers) do
            local targetPlayer = Players:FindFirstChild(playerName)
            if targetPlayer and targetPlayer ~= player and targetPlayer.Character and 
               targetPlayer.Character:FindFirstChild("Humanoid") and 
               targetPlayer.Character.Humanoid.Health > 0 and 
               targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                
                local distance = (player.Character.HumanoidRootPart.Position - targetPlayer.Character.HumanoidRootPart.Position).Magnitude
                if distance < nearestDistance then
                    nearestDistance = distance
                    nearestPlayer = targetPlayer
                end
            end
        end
        
        return nearestPlayer
    end
    
    local function moveToTarget(target)
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") or not target then
            return
        end
        
        local targetRoot = target:IsA("Player") and target.Character:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("HumanoidRootPart")
        if not targetRoot then return end
        
        local targetPosition = targetRoot.Position + targetRoot.CFrame.LookVector * -3
        targetPosition = Vector3.new(targetPosition.X, targetPosition.Y, targetPosition.Z)
        
        player.Character.HumanoidRootPart.CFrame = CFrame.new(targetPosition, targetRoot.Position)
    end
    
    local function attackTarget()
        if not farmEnabled then return end
        
        local tool = equipTool()
        if tool then
            tool:Activate()
            wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
            wait(0.01)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        end
    end
    
    local function refreshToolList()
        for _, button in pairs(toolButtons) do
            button:Destroy()
        end
        toolButtons = {}
        
        local tools = {}
        
        for _, tool in pairs(player.Backpack:GetChildren()) do
            if tool:IsA("Tool") then
                tools[tool.Name] = tool
            end
        end
        
        if player.Character then
            for _, tool in pairs(player.Character:GetChildren()) do
                if tool:IsA("Tool") then
                    tools[tool.Name] = tool
                end
            end
        end
        
        local yPos = 0
        for toolName, _ in pairs(tools) do
            local button = Instance.new("TextButton")
            button.Size = UDim2.new(1, -6, 0, 18)
            button.Position = UDim2.new(0, 3, 0, yPos)
            button.BackgroundColor3 = (toolName == selectedTool) and Color3.new(0.2, 0.6, 0.2) or Color3.new(0.25, 0.25, 0.25)
            button.Text = (toolName == selectedTool and "[✓] " or "[ ] ") .. toolName
            button.TextColor3 = Color3.new(1, 1, 1)
            button.TextSize = 9
            button.Font = Enum.Font.SourceSans
            button.BorderSizePixel = 0
            button.Parent = toolScrollFrame
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 2)
            corner.Parent = button
            
            button.MouseButton1Click:Connect(function()
                if toolButtons[selectedTool] then
                    toolButtons[selectedTool].BackgroundColor3 = Color3.new(0.25, 0.25, 0.25)
                    toolButtons[selectedTool].Text = "[ ] " .. selectedTool
                end
                
                selectedTool = toolName
                selectedToolLabel.Text = selectedTool
                button.BackgroundColor3 = Color3.new(0.2, 0.6, 0.2)
                button.Text = "[✓] " .. toolName
                
                for name, btn in pairs(toolButtons) do
                    if name ~= toolName then
                        btn.BackgroundColor3 = Color3.new(0.25, 0.25, 0.25)
                        btn.Text = "[ ] " .. name
                    end
                end
            end)
            
            toolButtons[toolName] = button
            yPos = yPos + 20
        end
        
        toolScrollFrame.CanvasSize = UDim2.new(0, 0, 0, yPos)
        
        if not tools[selectedTool] then
            local firstTool = next(tools)
            if firstTool then
                selectedTool = firstTool
                selectedToolLabel.Text = selectedTool
            end
        end
    end
    
    local function refreshNPCList()
        for _, button in pairs(npcButtons) do
            button:Destroy()
        end
        npcButtons = {}
        
        local badNPCs = nil
        for _, child in pairs(Workspace:GetChildren()) do
            if string.match(child.Name, "^BadEntities%d*$") then
                badNPCs = child
                break
            end
        end
        if not badNPCs then 
            statusLabel.Text = "Status: Nenhum NPC encontrado"
            return 
        end
        
        local npcNames = {}
        for _, npc in pairs(badNPCs:GetChildren()) do
            if npc:FindFirstChild("Humanoid") then
                npcNames[npc.Name] = true
            end
        end
        
        local yPos = 0
        for npcName, _ in pairs(npcNames) do
            local button = Instance.new("TextButton")
            button.Size = UDim2.new(1, -6, 0, 20)
            button.Position = UDim2.new(0, 3, 0, yPos)
            button.BackgroundColor3 = selectedNPCs[npcName] and Color3.new(0.2, 0.6, 0.2) or Color3.new(0.25, 0.25, 0.25)
            button.Text = (selectedNPCs[npcName] and "[✓] " or "[ ] ") .. npcName
            button.TextColor3 = Color3.new(1, 1, 1)
            button.TextSize = 10
            button.Font = Enum.Font.SourceSans
            button.BorderSizePixel = 0
            button.Parent = scrollFrame
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 2)
            corner.Parent = button
            
            button.MouseButton1Click:Connect(function()
                if selectedNPCs[npcName] then
                    selectedNPCs[npcName] = nil
                    button.BackgroundColor3 = Color3.new(0.25, 0.25, 0.25)
                    button.Text = "[ ] " .. npcName
                else
                    selectedNPCs[npcName] = true
                    button.BackgroundColor3 = Color3.new(0.2, 0.6, 0.2)
                    button.Text = "[✓] " .. npcName
                end
            end)
            
            npcButtons[npcName] = button
            yPos = yPos + 22
        end
        
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yPos)
        statusLabel.Text = "Status: Lista de NPCs atualizada"
    end
    
    local function refreshPlayerList()
        for _, button in pairs(playerButtons) do
            button:Destroy()
        end
        playerButtons = {}
        
        local yPos = 0
        for _, targetPlayer in pairs(Players:GetPlayers()) do
            if targetPlayer ~= player then
                local button = Instance.new("TextButton")
                button.Size = UDim2.new(1, -6, 0, 20)
                button.Position = UDim2.new(0, 3, 0, yPos)
                button.BackgroundColor3 = selectedPlayers[targetPlayer.Name] and Color3.new(0.6, 0.2, 0.2) or Color3.new(0.25, 0.25, 0.25)
                button.Text = (selectedPlayers[targetPlayer.Name] and "[🎯] " or "[ ] ") .. targetPlayer.Name
                button.TextColor3 = Color3.new(1, 1, 1)
                button.TextSize = 10
                button.Font = Enum.Font.SourceSans
                button.BorderSizePixel = 0
                button.Parent = scrollFrame
                
                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 2)
                corner.Parent = button
                
                button.MouseButton1Click:Connect(function()
                    if selectedPlayers[targetPlayer.Name] then
                        selectedPlayers[targetPlayer.Name] = nil
                        button.BackgroundColor3 = Color3.new(0.25, 0.25, 0.25)
                        button.Text = "[ ] " .. targetPlayer.Name
                    else
                        selectedPlayers[targetPlayer.Name] = true
                        button.BackgroundColor3 = Color3.new(0.6, 0.2, 0.2)
                        button.Text = "[🎯] " .. targetPlayer.Name
                    end
                end)
                
                playerButtons[targetPlayer.Name] = button
                yPos = yPos + 22
            end
        end
        
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yPos)
        statusLabel.Text = "Status: Lista de jogadores atualizada"
    end
    
    local function switchCombatMode(mode)
        combatMode = mode
        
        for _, button in pairs(npcButtons) do
            button:Destroy()
        end
        npcButtons = {}
        
        for _, button in pairs(playerButtons) do
            button:Destroy()
        end
        playerButtons = {}
        
        selectedNPCs = {}
        selectedPlayers = {}
        
        if mode == "NPCs" then
            npcModeButton.BackgroundColor3 = Color3.new(0.2, 0.6, 0.2)
            pvpModeButton.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
            refreshNPCList()
        else
            npcModeButton.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
            pvpModeButton.BackgroundColor3 = Color3.new(0.6, 0.2, 0.2)
            refreshPlayerList()
        end
        
        if farmEnabled then
            farmEnabled = false
            farmButton.Text = "Iniciar"
            farmButton.BackgroundColor3 = Color3.new(0.2, 0.6, 0.2)
            if connection then
                connection:Disconnect()
            end
        end
    end
    
    local function refreshTeleportList()
        for _, child in pairs(teleportScrollFrame:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        local yPos = 0
        for locationName, _ in pairs(teleportLocations) do
            local button = Instance.new("TextButton")
            button.Size = UDim2.new(1, -6, 0, 25)
            button.Position = UDim2.new(0, 3, 0, yPos)
            button.BackgroundColor3 = Color3.new(0.3, 0.3, 0.5)
            button.Text = locationName
            button.TextColor3 = Color3.new(1, 1, 1)
            button.TextSize = 11
            button.Font = Enum.Font.SourceSans
            button.BorderSizePixel = 0
            button.Parent = teleportScrollFrame
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 3)
            corner.Parent = button
            
            button.MouseButton1Click:Connect(function()
                statusLabel.Text = "Status: Teleportando para " .. locationName
                local success = teleportToLocation(locationName)
                if success then
                    statusLabel.Text = "Status: Teleportado para " .. locationName
                else
                    statusLabel.Text = "Status: Falha no teleporte"
                end
            end)
            
            yPos = yPos + 27
        end
        
        teleportScrollFrame.CanvasSize = UDim2.new(0, 0, 0, yPos)
    end
    
    local function startFarm()
        if connection then
            connection:Disconnect()
        end
        
        connection = RunService.Heartbeat:Connect(function()
            if not farmEnabled then return end
            
            if not player.Character or not player.Character:FindFirstChild("Humanoid") or player.Character.Humanoid.Health <= 0 then
                statusLabel.Text = "Status: Aguardando respawn..."
                return
            end
            
            local target = nil
            local targetName = ""
            
            if combatMode == "NPCs" then
                if next(selectedNPCs) == nil then
                    statusLabel.Text = "Status: Nenhum NPC selecionado"
                    return
                end
                target = getNearestSelectedNPC()
                if target then
                    targetName = target.Name
                end
            else
                if next(selectedPlayers) == nil then
                    statusLabel.Text = "Status: Nenhum jogador selecionado"
                    return
                end
                target = getNearestSelectedPlayer()
                if target then
                    targetName = target.Name
                end
            end
            
            if target then
                statusLabel.Text = "Status: Atacando " .. targetName
                moveToTarget(target)
                attackTarget()
            else
                statusLabel.Text = "Status: Procurando alvos..."
            end
            
            wait(attackSpeed)
        end)
    end
    
    local function stopFarm()
        farmEnabled = false
        if connection then
            connection:Disconnect()
            connection = nil
        end
        statusLabel.Text = "Status: Parado"
    end
    
    combatHeaderButton.MouseButton1Click:Connect(function()
        combatExpanded = not combatExpanded
        updateSectionVisibility()
    end)
    
    toolsHeaderButton.MouseButton1Click:Connect(function()
        toolsExpanded = not toolsExpanded
        updateSectionVisibility()
    end)
    
    targetsHeaderButton.MouseButton1Click:Connect(function()
        targetsExpanded = not targetsExpanded
        updateSectionVisibility()
    end)
    
    teleportHeaderButton.MouseButton1Click:Connect(function()
        teleportExpanded = not teleportExpanded
        updateSectionVisibility()
    end)
    
    toggleButton.MouseButton1Click:Connect(function()
        mainFrame.Visible = not mainFrame.Visible
        
        if mainFrame.Visible then
            toggleButton.BackgroundColor3 = Color3.new(0.4, 0.2, 0.2)
            toggleButton.BorderColor3 = Color3.new(0.6, 0.3, 0.3)
        else
            toggleButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
            toggleButton.BorderColor3 = Color3.new(0.4, 0.4, 0.4)
        end
    end)
    
    closeButton.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
        toggleButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
        toggleButton.BorderColor3 = Color3.new(0.4, 0.4, 0.4)
    end)
    
    npcModeButton.MouseButton1Click:Connect(function()
        switchCombatMode("NPCs")
    end)
    
    pvpModeButton.MouseButton1Click:Connect(function()
        switchCombatMode("Players")
    end)
    
    farmButton.MouseButton1Click:Connect(function()
        farmEnabled = not farmEnabled
        
        if farmEnabled then
            farmButton.Text = "Parar"
            farmButton.BackgroundColor3 = Color3.new(0.6, 0.2, 0.2)
            startFarm()
        else
            farmButton.Text = "Iniciar"
            farmButton.BackgroundColor3 = Color3.new(0.2, 0.6, 0.2)
            stopFarm()
        end
    end)
    
    refreshTargetsButton.MouseButton1Click:Connect(function()
        if combatMode == "NPCs" then
            refreshNPCList()
        else
            refreshPlayerList()
        end
    end)
    
    refreshToolsButton.MouseButton1Click:Connect(function()
        refreshToolList()
    end)
    
    player.CharacterAdded:Connect(function()
        wait(2)
        if farmEnabled then
            startFarm()
        end
    end)
    
    Players.PlayerAdded:Connect(function()
        if combatMode == "Players" and mainFrame.Visible then
            wait(1)
            refreshPlayerList()
        end
    end)
    
    Players.PlayerRemoving:Connect(function(removedPlayer)
        if selectedPlayers[removedPlayer.Name] then
            selectedPlayers[removedPlayer.Name] = nil
        end
        if combatMode == "Players" and mainFrame.Visible then
            refreshPlayerList()
        end
    end)
    
    if player.Character then
        player.Character.ChildAdded:Connect(function(child)
            if child:IsA("Humanoid") then
                child.Died:Connect(function()
                    if farmEnabled then
                        statusLabel.Text = "Status: Morreu - Reiniciando..."
                    end
                end)
            end
        end)
    end
    
    spawn(function()
        wait(1)
        refreshToolList()
        refreshTeleportList()
        switchCombatMode("NPCs")
        updateSectionVisibility()
    end)
    
    toolRefreshConnection = spawn(function()
        while true do
            wait(3)
            if mainFrame.Visible and toolsExpanded then
                refreshToolList()
            end
        end
    end)
end

createMainMenu()
