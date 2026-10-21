--[[
    P3G HUB - Script Principal (Lógica)
    Carga la UI desde GitHub automáticamente.
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")

local RuntimeEnvironment = (getgenv and getgenv()) or _G
if RuntimeEnvironment.__P3G_HUB_CLEANUP then
    pcall(RuntimeEnvironment.__P3G_HUB_CLEANUP)
end

local trackedConnections = {}
local scriptAlive = true

local function TrackConnection(connection)
    table.insert(trackedConnections, connection)
    return connection
end

local function DisconnectTrackedConnections()
    for i = #trackedConnections, 1, -1 do
        local conn = trackedConnections[i]
        if conn then pcall(function() conn:Disconnect() end) end
        trackedConnections[i] = nil
    end
end

local RED = Color3.fromRGB(255, 30, 30)
local BLACK = Color3.fromRGB(0, 0, 0)

-- ============================================
--  VARIABLES
-- ============================================

local m1_enabled = false
local m1_size = 6.0
local m1_transparency = 0.7
local REACH_SIZE = 10
local reachMethod2Enabled = false
local reachTransparency2 = 1
local proxyEnabled = false
local ballProxies = {}
local proxyOriginalSizes = {}
local CharacterReachEnabled = false
local CharacterReachSize = 12.0
local CharacterVisualizerIntensity = 0.5
local PlatformEnabled = false
local PlatformSize = 15
local Smoothness = 0.95
local ShowPlatform = false
local PlatformTransparency = 0.7
local WalkSpeedValue = 26
local WalkSpeedEnabled = false
local DefaultWalkSpeed = 16
local JumpPowerEnabled = false
local JumpPowerValue = 50
local DefaultJumpPower = 50
local DIVE_RANGE = 40
local DIVE_SPEED = 45
local DIVE_LIFT = 28
local COOLDOWN = 0.2
local HIT_RADIUS = 6
local gkAutoDiveEnabled = false
local onCooldown = false
local animPlaying = false
local liveTrack = nil
local touchCD = false
local ANIM_HEADER = "rbxassetid://83669895507175"
local ANIM_BACK = "rbxassetid://133843606757895"
local ANIM_RIGHT = "rbxassetid://130737929982335"
local ANIM_LEFT = "rbxassetid://97298506180835"
local PRED_RANGE = 20
local PRED_TOUCH = 6
local PRED_GRAVITY = -98.1
local PRED_TIME = 1.4
local predOn = false
local predObjs = {}
local predConn = nil
local cachedPingGlobal = 0.06
local _reactActive = false
local _reactThread = nil
local _lastReactTT, _lastReactInterp = "13", "90"
local _gkReactActive = false
local _gkReactThread = nil
local _lastGkReactTT, _lastGkReactInterp = "13", "90"
local kickLoopEnabled = false
local kickReach = 20
local kickConnection = nil
local dribbleEnabled = false
local dribbleConn = nil
local dribbleSpeed = 26
local flyEnabled = false
local flySpeed = 40
local flyBV = nil
local flyConn = nil
local tpEnabled = false
local tpSpeed = 3
local tpConn = nil

local ballParts = {}
local ballVisualizers = {}
local reachOriginalProperties = {}
local platforms = {}
local platformRunning = false
local platformConnection = nil
local characterReachPart = nil
local characterReachWeld = nil
local characterReachOutline = nil
local walkSpeedConnection = nil
local currentHumanoid = nil
local changingWalkSpeed = false
local isCharacterRespawning = false

-- ============================================
--  AVATAR STEALER
-- ============================================

local function stopCharacterAnimations(humanoid)
    local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
    if not animator then return end
    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        track:Stop()
    end
end

local function cloneClassicAppearance(sourceModel, targetCharacter, targetHumanoid)
    if not sourceModel then return end
    for _, obj in pairs(targetCharacter:GetChildren()) do
        if obj:IsA("Accessory") or obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("BodyColors") or obj:IsA("CharacterMesh") then
            obj:Destroy()
        end
    end
    for _, obj in pairs(sourceModel:GetChildren()) do
        if obj:IsA("Accessory") then
            targetHumanoid:AddAccessory(obj:Clone())
        elseif obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("BodyColors") or obj:IsA("CharacterMesh") then
            obj:Clone().Parent = targetCharacter
        end
    end
    local targetHead = targetCharacter:FindFirstChild("Head")
    if targetHead then
        for _, child in pairs(targetHead:GetChildren()) do
            if child:IsA("Decal") and (child.Name == "face" or child.Name == "Face") then
                child:Destroy()
            end
        end
        local texture
        local sourceHead = sourceModel:FindFirstChild("Head")
        if sourceHead then
            for _, child in ipairs(sourceHead:GetDescendants()) do
                if child:IsA("Decal") and (child.Name == "face" or child.Name == "Face") then
                    texture = child.Texture
                    break
                end
            end
        end
        local face = Instance.new("Decal")
        face.Name = "face"
        face.Face = Enum.NormalId.Front
        face.Texture = texture or "rbxasset://textures/face.png"
        face.Parent = targetHead
    end
end

local function applyAvatarFromUserId(userId, character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    stopCharacterAnimations(humanoid)
    local okAppearance, appearanceModel = pcall(function()
        return Players:GetCharacterAppearanceAsync(userId)
    end)
    local okDescription, description = pcall(function()
        return Players:GetHumanoidDescriptionFromUserId(userId)
    end)
    if okDescription and description then
        pcall(function() humanoid:ApplyDescription(description) end)
    end
    if okAppearance and appearanceModel then
        cloneClassicAppearance(appearanceModel, character, humanoid)
    end
    local parent = character.Parent
    character.Parent = nil
    character.Parent = parent
    if appearanceModel then appearanceModel:Destroy() end
end

local function StealAvatarByName(username)
    if not username or username == "" then return end
    local success, userId = pcall(function()
        return Players:GetUserIdFromNameAsync(username)
    end)
    if success and userId and LocalPlayer.Character then
        applyAvatarFromUserId(userId, LocalPlayer.Character)
    end
end

-- ============================================
--  UTILITY FUNCTIONS
-- ============================================

local function getFootballFolder()
    return workspace:FindFirstChild("Footballs")
end

local function getClosestFootball()
    local folder = getFootballFolder()
    if not folder then return nil end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local best, closest = math.huge, nil
    for _, b in folder:GetChildren() do
        if b:IsA("BasePart") then
            local d = (b.Position - hrp.Position).Magnitude
            if d < best then best = d; closest = b end
        end
    end
    return closest, best
end

local function getKickRemote()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local gameRemote = remotes:FindFirstChild("Game")
        if gameRemote then
            local touch = gameRemote:FindFirstChild("Touch")
            if touch then return touch:FindFirstChild("Kick") end
        end
    end
    return nil
end

local function getAllBalls()
    local folder = getFootballFolder()
    if not folder then return {} end
    local balls = {}
    for _, obj in ipairs(folder:GetChildren()) do
        local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
        if part then table.insert(balls, part) end
    end
    return balls
end

local function inBox()
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    if not gui then return false end
    local main = gui:FindFirstChild("Main")
    if not main then return false end
    local values = main:FindFirstChild("Values")
    if not values then return false end
    local goalie = values:FindFirstChild("Goalie")
    if not goalie then return false end
    return goalie.Value == true
end

local function IsBallName(name)
    local lowered = string.lower(name or "")
    if lowered == "ball" or lowered == "football" or lowered == "soccerball" then return true end
    return string.find(lowered, "ball", 1, true) ~= nil
end

local function IsReasonableBallPart(part)
    local size = part.Size
    local largest = math.max(size.X, size.Y, size.Z)
    local smallest = math.min(size.X, size.Y, size.Z)
    if smallest <= 0.02 or largest > 20 then return false end
    if largest / smallest > 6 then return false end
    return true
end

local function RegisterBallPart(part)
    if part and part:IsA("BasePart") and part.Parent and IsReasonableBallPart(part) then
        if not ballParts[part] then ballParts[part] = true end
    end
end

local function RegisterBallCandidate(instance)
    if not instance or not instance.Parent then return end
    if (instance:IsA("BasePart") or instance:IsA("Model")) and IsBallName(instance.Name) then
        local part = instance:IsA("BasePart") and instance or instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart")
        if part then
            RegisterBallPart(part)
            if not proxyOriginalSizes[part] then proxyOriginalSizes[part] = part.Size end
        end
    end
end

TrackConnection(workspace.DescendantAdded:Connect(RegisterBallCandidate))

task.spawn(function()
    for _, instance in ipairs(workspace:GetDescendants()) do
        if not scriptAlive then return end
        RegisterBallCandidate(instance)
        task.wait()
    end
end)

-- ============================================
--  VISUALIZER
-- ============================================

local function CreateVisualizerP3g(ball, size, transparency)
    if ballVisualizers[ball] and ballVisualizers[ball].Parent then
        local vis = ballVisualizers[ball]
        vis.Size = Vector3.new(size, size, size)
        vis.Transparency = transparency
        vis.CFrame = ball.CFrame
        return vis
    end
    local visualizer = Instance.new("Part")
    visualizer.Name = "__BallVisualizer"
    visualizer.Size = Vector3.new(size, size, size)
    visualizer.CFrame = ball.CFrame
    visualizer.Anchored = true
    visualizer.CanCollide = false
    visualizer.CanTouch = false
    visualizer.CanQuery = false
    visualizer.CastShadow = false
    visualizer.Transparency = transparency
    visualizer.Material = Enum.Material.ForceField
    visualizer.Color = RED
    visualizer.Shape = ball.Shape
    visualizer.Massless = true
    visualizer.Parent = workspace
    local outline = Instance.new("Highlight")
    outline.Name = "__BallVisualizerOutline"
    outline.Adornee = visualizer
    outline.FillTransparency = 1
    outline.OutlineColor = RED
    outline.OutlineTransparency = 0.2
    outline.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    outline.Parent = visualizer
    ballVisualizers[ball] = visualizer
    return visualizer
end

local function RemoveVisualizerP3g(ball)
    if ballVisualizers[ball] then
        ballVisualizers[ball]:Destroy()
        ballVisualizers[ball] = nil
    end
end

local function UpdateVisualizers(size, transparency)
    for ball, visualizer in pairs(ballVisualizers) do
        if ball and ball.Parent and visualizer and visualizer.Parent then
            visualizer.CFrame = ball.CFrame
            if visualizer.Size ~= Vector3.new(size, size, size) then
                visualizer.Size = Vector3.new(size, size, size)
            end
            if visualizer.Transparency ~= transparency then
                visualizer.Transparency = transparency
            end
        else
            if visualizer then visualizer:Destroy() end
            ballVisualizers[ball] = nil
        end
    end
end

-- ============================================
--  BALL COLLISION PROXY
-- ============================================

local proxySyncConnection = nil

local function CreateCollisionProxy(ball)
    if ballProxies[ball] and ballProxies[ball].Parent then
        return ballProxies[ball]
    end
    local originalSize = proxyOriginalSizes[ball]
    if not originalSize then
        originalSize = ball.Size
        proxyOriginalSizes[ball] = originalSize
    end
    local proxy = Instance.new("Part")
    proxy.Name = "__CollisionProxy"
    proxy.Size = originalSize
    proxy.CFrame = ball.CFrame
    proxy.Anchored = true
    proxy.CanCollide = true
    proxy.CanTouch = true
    proxy.CanQuery = true
    proxy.Transparency = 1
    proxy.Material = Enum.Material.Plastic
    proxy.Color = Color3.new(1, 1, 1)
    proxy.Massless = true
    proxy.Shape = ball.Shape
    proxy.Parent = workspace
    ballProxies[ball] = proxy
    return proxy
end

local function RemoveCollisionProxy(ball)
    if ballProxies[ball] then
        ballProxies[ball]:Destroy()
        ballProxies[ball] = nil
    end
end

local function StartProxySystem()
    if proxySyncConnection then proxySyncConnection:Disconnect() end
    if not proxyEnabled then return end
    local folder = getFootballFolder()
    if folder then
        for _, ball in folder:GetChildren() do
            if ball:IsA("BasePart") then
                if not proxyOriginalSizes[ball] then proxyOriginalSizes[ball] = ball.Size end
                CreateCollisionProxy(ball)
            end
        end
    end
    proxySyncConnection = RunService.Heartbeat:Connect(function()
        if not proxyEnabled then return end
        local folder = getFootballFolder()
        if not folder then return end
        for _, ball in folder:GetChildren() do
            if ball:IsA("BasePart") then
                if not proxyOriginalSizes[ball] then proxyOriginalSizes[ball] = ball.Size end
                if not ballProxies[ball] or not ballProxies[ball].Parent then
                    CreateCollisionProxy(ball)
                else
                    ballProxies[ball].CFrame = ball.CFrame
                end
            end
        end
        for ball, proxy in pairs(ballProxies) do
            if not ball or not ball.Parent then RemoveCollisionProxy(ball) end
        end
    end)
end

local function StopProxySystem()
    if proxySyncConnection then proxySyncConnection:Disconnect(); proxySyncConnection = nil end
    for ball, proxy in pairs(ballProxies) do RemoveCollisionProxy(ball) end
    table.clear(ballProxies)
end

-- ============================================
--  REACH METHOD 1
-- ============================================

local m1_connection = nil
local m1_visualizer_connection = nil
local m1_grey_color = Color3.fromRGB(128, 128, 128)

local function ApplyReachMethod1(ball)
    if not ball or not ball.Parent or not ball:IsA("BasePart") then return end
    if not reachOriginalProperties[ball] then
        reachOriginalProperties[ball] = {
            Size = ball.Size,
            Transparency = ball.Transparency,
            CanCollide = ball.CanCollide,
            Color = ball.Color
        }
    end
    ball.Size = Vector3.new(m1_size, m1_size, m1_size)
    ball.Transparency = 1
    ball.CanCollide = false
    ball.Color = m1_grey_color
end

local function RestoreBallMethod1(ball)
    if reachOriginalProperties[ball] then
        local props = reachOriginalProperties[ball]
        pcall(function()
            ball.Size = props.Size
            ball.Transparency = props.Transparency
            ball.CanCollide = props.CanCollide
            ball.Color = props.Color
        end)
        reachOriginalProperties[ball] = nil
    end
    RemoveVisualizerP3g(ball)
end

local function StartMethod1()
    if m1_connection then m1_connection:Disconnect(); m1_connection = nil end
    if m1_visualizer_connection then m1_visualizer_connection:Disconnect(); m1_visualizer_connection = nil end
    if not m1_enabled then return end
    for ball in pairs(ballParts) do
        if ball and ball.Parent then
            ApplyReachMethod1(ball)
            CreateVisualizerP3g(ball, m1_size, m1_transparency)
        end
    end
    m1_connection = RunService.RenderStepped:Connect(function()
        if not m1_enabled then return end
        local folder = getFootballFolder()
        if not folder then return end
        for _, b in folder:GetChildren() do
            if b:IsA("BasePart") then
                if not ballParts[b] then ballParts[b] = true end
                ApplyReachMethod1(b)
                if not ballVisualizers[b] or not ballVisualizers[b].Parent then
                    CreateVisualizerP3g(b, m1_size, m1_transparency)
                end
            end
        end
    end)
    m1_visualizer_connection = RunService.Heartbeat:Connect(function()
        if not m1_enabled then return end
        UpdateVisualizers(m1_size, m1_transparency)
    end)
end

local function StopMethod1()
    if m1_connection then m1_connection:Disconnect(); m1_connection = nil end
    if m1_visualizer_connection then m1_visualizer_connection:Disconnect(); m1_visualizer_connection = nil end
    for ball in pairs(ballVisualizers) do RemoveVisualizerP3g(ball) end
    for ball, props in pairs(reachOriginalProperties) do
        if ball and ball.Parent then RestoreBallMethod1(ball) end
        reachOriginalProperties[ball] = nil
    end
end

-- ============================================
--  REACH METHOD 2
-- ============================================

local method2_trackedParts = {}
local method2_indicator = nil
local method2_visualizer_connection = nil
local originalColors = {}
local originalSizes = {}

local function SetupMethod2()
    if getgenv().Reach then getgenv().Reach = nil end
    if getgenv().ReachConnections then
        for _, connection in ipairs(getgenv().ReachConnections) do
            pcall(function() connection:Disconnect() end)
        end
        getgenv().ReachConnections = nil
    end
    getgenv().ReachConnections = {}
    getgenv().Reach = {
        Enabled = false,
        Size = REACH_SIZE,
        Transparency = reachTransparency2,
        Distance = 100
    }
    local character = LocalPlayer.Character
    if not character then character = LocalPlayer.CharacterAdded:Wait() end
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    local footballs = getFootballFolder()
    if not footballs then
        footballs = Instance.new("Folder")
        footballs.Name = "Footballs"
        footballs.Parent = workspace
    end
    method2_trackedParts = {}
    originalSizes = {}
    originalColors = {}
    local function onChildAdded(item)
        if item:IsA("BasePart") then
            method2_trackedParts[item] = true
            originalSizes[item] = item.Size
            originalColors[item] = item.Color
        end
    end
    for _, part in ipairs(footballs:GetChildren()) do
        if part:IsA("BasePart") then
            method2_trackedParts[part] = true
            originalSizes[part] = part.Size
            originalColors[part] = part.Color
        end
    end
    table.insert(getgenv().ReachConnections, footballs.ChildAdded:Connect(onChildAdded))
    table.insert(getgenv().ReachConnections, footballs.ChildRemoved:Connect(function(child)
        method2_trackedParts[child] = nil
        originalSizes[child] = nil
        originalColors[child] = nil
        RemoveVisualizerP3g(child)
    end))
    local function updateReachSize()
        local currentSize = getgenv().Reach.Size or REACH_SIZE
        for part in pairs(method2_trackedParts) do
            if part and part.Parent then
                part.Size = Vector3.new(currentSize, currentSize, currentSize)
                part.Color = Color3.fromRGB(128, 128, 128)
                part.CanCollide = false
            end
        end
    end
    local function resetParts()
        for part in pairs(method2_trackedParts) do
            if part and part.Parent then
                if originalSizes[part] then part.Size = originalSizes[part] end
                if originalColors[part] then part.Color = originalColors[part] end
                part.CanCollide = true
                if reachOriginalProperties[part] and reachOriginalProperties[part].Transparency then
                    part.Transparency = reachOriginalProperties[part].Transparency
                else
                    part.Transparency = 0
                end
            end
            RemoveVisualizerP3g(part)
        end
    end
    local function findNearestPart()
        local nearest, nearestDist = nil, math.huge
        for part in pairs(method2_trackedParts) do
            if part and part.Parent then
                local dist = (part.Position - humanoidRootPart.Position).Magnitude
                if dist < nearestDist then nearestDist = dist; nearest = part end
            end
        end
        return nearest, nearestDist
    end
    if method2_indicator then method2_indicator:Destroy() end
    method2_indicator = Instance.new("Part")
    method2_indicator.Name = "BallFollowPart"
    method2_indicator.Shape = Enum.PartType.Ball
    method2_indicator.Size = Vector3.new(2.25, 2.25, 2.25)
    method2_indicator.Anchored = true
    method2_indicator.CanCollide = true
    method2_indicator.CanTouch = false
    method2_indicator.CanQuery = false
    method2_indicator.Transparency = 0.5
    method2_indicator.Material = Enum.Material.ForceField
    method2_indicator.Color = Color3.fromRGB(0, 200, 255)
    method2_indicator.Parent = workspace
    table.insert(getgenv().ReachConnections, RunService.Heartbeat:Connect(function()
        if not reachMethod2Enabled then return end
        local nearest, distance = findNearestPart()
        if not nearest or distance > getgenv().Reach.Distance then
            resetParts()
            if method2_indicator then method2_indicator.CFrame = CFrame.new(0, -1000, 0) end
        else
            updateReachSize()
            if method2_indicator then method2_indicator.CFrame = nearest.CFrame end
            if nearest and nearest.Parent then
                if not ballVisualizers[nearest] or not ballVisualizers[nearest].Parent then
                    CreateVisualizerP3g(nearest, REACH_SIZE, reachTransparency2)
                end
            end
        end
    end))
    if method2_visualizer_connection then method2_visualizer_connection:Disconnect() end
    method2_visualizer_connection = RunService.Heartbeat:Connect(function()
        if not reachMethod2Enabled then return end
        for ball, visualizer in pairs(ballVisualizers) do
            if ball and ball.Parent and visualizer and visualizer.Parent then
                visualizer.CFrame = ball.CFrame
                local currentSize = getgenv().Reach.Size or REACH_SIZE
                if visualizer.Size ~= Vector3.new(currentSize, currentSize, currentSize) then
                    visualizer.Size = Vector3.new(currentSize, currentSize, currentSize)
                end
                local currentTransparency = getgenv().Reach.Transparency or 1
                if visualizer.Transparency ~= currentTransparency then
                    visualizer.Transparency = currentTransparency
                end
            else
                if visualizer then visualizer:Destroy() end
                ballVisualizers[ball] = nil
            end
        end
    end)
    getgenv().DisableReach = function()
        if getgenv().ReachConnections then
            for _, connection in ipairs(getgenv().ReachConnections) do
                connection:Disconnect()
            end
        end
        if method2_visualizer_connection then method2_visualizer_connection:Disconnect(); method2_visualizer_connection = nil end
        resetParts()
        if method2_indicator then method2_indicator:Destroy(); method2_indicator = nil end
        getgenv().Reach = nil
        getgenv().ReachConnections = nil
    end
end

local function StartMethod2()
    if reachMethod2Enabled then SetupMethod2() end
end

local function StopMethod2()
    if getgenv().DisableReach then getgenv().DisableReach() end
    if method2_visualizer_connection then method2_visualizer_connection:Disconnect(); method2_visualizer_connection = nil end
    for ball in pairs(ballVisualizers) do RemoveVisualizerP3g(ball) end
end

-- ============================================
--  CHARACTER REACH
-- ============================================

local function CharacterIntensityToTransparency(intensity)
    return math.clamp(0.95 - (math.clamp(intensity, 0.1, 1) * 0.65), 0.3, 0.9)
end

local function CharacterIntensityToOutlineTransparency(intensity)
    return math.clamp(0.78 - (math.clamp(intensity, 0.1, 1) * 0.68), 0.1, 0.72)
end

local function DestroyCharacterReach()
    if characterReachWeld then characterReachWeld:Destroy(); characterReachWeld = nil end
    if characterReachOutline then characterReachOutline:Destroy(); characterReachOutline = nil end
    if characterReachPart then characterReachPart:Destroy(); characterReachPart = nil end
end

local function RefreshCharacterReach(character)
    if not CharacterReachEnabled then DestroyCharacterReach(); return end
    character = character or LocalPlayer.Character
    if not character or not character.Parent then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if characterReachPart and characterReachPart.Parent ~= character then DestroyCharacterReach() end
    if not characterReachPart then
        local sphere = Instance.new("Part")
        sphere.Name = "P3gCharacterReach"
        sphere.Shape = Enum.PartType.Ball
        sphere.Size = Vector3.new(CharacterReachSize, CharacterReachSize, CharacterReachSize)
        sphere.CFrame = root.CFrame
        sphere.Anchored = false
        sphere.Massless = true
        sphere.CanCollide = false
        sphere.CanTouch = true
        sphere.CanQuery = true
        sphere.CastShadow = false
        sphere.Material = Enum.Material.ForceField
        sphere.Color = RED
        sphere.Transparency = CharacterIntensityToTransparency(CharacterVisualizerIntensity)
        sphere.Parent = character
        local outline = Instance.new("Highlight")
        outline.Name = "P3gCharacterReachOutline"
        outline.Adornee = sphere
        outline.FillTransparency = 1
        outline.OutlineColor = RED
        outline.OutlineTransparency = CharacterIntensityToOutlineTransparency(CharacterVisualizerIntensity)
        outline.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        outline.Parent = sphere
        local weld = Instance.new("WeldConstraint")
        weld.Name = "P3gCharacterReachWeld"
        weld.Part0 = root
        weld.Part1 = sphere
        weld.Parent = sphere
        characterReachPart = sphere
        characterReachOutline = outline
        characterReachWeld = weld
    end
    local targetSize = Vector3.new(CharacterReachSize, CharacterReachSize, CharacterReachSize)
    if characterReachPart.Size ~= targetSize then characterReachPart.Size = targetSize end
    characterReachPart.Color = RED
    local targetTransparency = CharacterIntensityToTransparency(CharacterVisualizerIntensity)
    if characterReachPart.Transparency ~= targetTransparency then characterReachPart.Transparency = targetTransparency end
    if characterReachOutline then
        characterReachOutline.OutlineColor = RED
        characterReachOutline.OutlineTransparency = CharacterIntensityToOutlineTransparency(CharacterVisualizerIntensity)
    end
end

local function StartCharacterReachSystem()
    if not CharacterReachEnabled then return end
    local character = LocalPlayer.Character
    if character then RefreshCharacterReach(character) end
end

local function StopCharacterReachSystem()
    DestroyCharacterReach()
end

TrackConnection(LocalPlayer.CharacterAdded:Connect(function()
    if CharacterReachEnabled then
        task.defer(function()
            if scriptAlive and CharacterReachEnabled then StartCharacterReachSystem() end
        end)
    end
end))

-- ============================================
--  PLATFORM SYSTEM
-- ============================================

local function createPlatform(ballPart)
    local existing = platforms[ballPart]
    if existing and existing.part and existing.part.Parent then return existing end
    local platform = Instance.new("Part")
    platform.Name = "P3gAirPlatform"
    platform.Size = Vector3.new(PlatformSize, 0.2, PlatformSize)
    platform.Position = ballPart.Position - Vector3.new(0, 2, 0)
    platform.Anchored = true
    platform.CanCollide = true
    platform.CanTouch = false
    platform.CanQuery = false
    platform.CastShadow = false
    platform.Color = RED
    platform.Material = Enum.Material.SmoothPlastic
    platform.Transparency = ShowPlatform and PlatformTransparency or 1
    platform.Parent = workspace
    local data = { part = platform, lastPosition = platform.Position, lastCanCollide = true }
    platforms[ballPart] = data
    return data
end

local function removePlatform(ballPart)
    local data = platforms[ballPart]
    if data and data.part then data.part:Destroy() end
    platforms[ballPart] = nil
end

local function ClearAllPlatforms()
    for ballPart, data in pairs(platforms) do
        if data and data.part then data.part:Destroy() end
        platforms[ballPart] = nil
    end
end

local function UpdatePlatformSize()
    local targetSize = Vector3.new(PlatformSize, 0.2, PlatformSize)
    for _, data in pairs(platforms) do
        local part = data and data.part
        if part and part.Parent and part.Size ~= targetSize then part.Size = targetSize end
    end
end

local function UpdatePlatformVisibility()
    local targetTransparency = ShowPlatform and PlatformTransparency or 1
    for _, data in pairs(platforms) do
        local part = data and data.part
        if part and part.Parent and part.Transparency ~= targetTransparency then
            part.Transparency = targetTransparency
        end
    end
end

local function UpdatePlatformSystem(deltaTime)
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local smoothness = math.clamp(Smoothness, 0.1, 1)
    local alpha
    if smoothness >= 0.999 then alpha = 1
    else
        local response = 8 + (smoothness * 92)
        alpha = 1 - math.exp(-response * math.min(deltaTime, 1 / 15))
    end
    for ballPart in pairs(ballParts) do
        if not ballPart.Parent then
            ballParts[ballPart] = nil
            removePlatform(ballPart)
        else
            local inAir = true
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = {ballPart, character}
            local result = workspace:Raycast(ballPart.Position, Vector3.new(0, -3.25, 0), params)
            inAir = result == nil
            if inAir then
                local data = createPlatform(ballPart)
                local platform = data.part
                local targetPosition = ballPart.Position - Vector3.new(0, 2, 0)
                local newPosition = alpha >= 0.999 and targetPosition or data.lastPosition:Lerp(targetPosition, alpha)
                if (platform.Position - newPosition).Magnitude > 0.0001 then platform.Position = newPosition end
                data.lastPosition = newPosition
                if root then
                    local shouldCollide = root.Position.Y >= platform.Position.Y
                    if shouldCollide ~= data.lastCanCollide then
                        platform.CanCollide = shouldCollide
                        data.lastCanCollide = shouldCollide
                    end
                end
            else
                removePlatform(ballPart)
            end
        end
    end
end

local function StartPlatformSystem()
    if platformRunning or not PlatformEnabled then return end
    platformRunning = true
    platformConnection = RunService.Heartbeat:Connect(function(deltaTime)
        if not scriptAlive or not PlatformEnabled or not platformRunning then return end
        UpdatePlatformSystem(deltaTime)
    end)
end

local function StopPlatformSystem()
    platformRunning = false
    if platformConnection then platformConnection:Disconnect(); platformConnection = nil end
    ClearAllPlatforms()
end

-- ============================================
--  GK AUTO DIVE
-- ============================================

local function stopAnim()
    if liveTrack then pcall(function() liveTrack:Stop() end); liveTrack = nil end
    animPlaying = false
end

local function playAnim(char, animId)
    stopAnim()
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    animPlaying = true
    local anim = Instance.new("Animation")
    anim.AnimationId = animId
    local track = hum:LoadAnimation(anim)
    liveTrack = track
    track:Play()
    track.Stopped:Connect(function()
        animPlaying = false
        liveTrack = nil
        pcall(function() anim:Destroy() end)
    end)
    task.delay(4, function()
        if liveTrack == track then stopAnim(); pcall(function() anim:Destroy() end) end
    end)
end

local function getMostDangerousBall()
    local char = LocalPlayer.Character
    if not char then return nil, math.huge end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, math.huge end
    local balls = getAllBalls()
    if #balls == 0 then return nil, math.huge end
    local bestBall, bestScore = nil, -math.huge
    for _, ball in ipairs(balls) do
        local toPlayer = hrp.Position - ball.Position
        local dist = toPlayer.Magnitude
        if dist > DIVE_RANGE then continue end
        local vel = ball.AssemblyLinearVelocity
        local speed = vel.Magnitude
        local approachFactor = 0
        if speed > 1 and dist > 0 then approachFactor = vel.Unit:Dot(toPlayer.Unit) end
        local score = (approachFactor * speed) + (1 / math.max(dist, 1)) * 10
        if score > bestScore then bestScore = score; bestBall = ball end
    end
    if not bestBall then
        local minDist = math.huge
        for _, ball in ipairs(balls) do
            local d = (ball.Position - hrp.Position).Magnitude
            if d < minDist then minDist = d; bestBall = ball end
        end
    end
    return bestBall
end

local function pickDive(hrp, ballPos)
    local lpos = hrp.CFrame:PointToObjectSpace(ballPos)
    if lpos.Y > 4 then
        return ANIM_HEADER, { Right = false, Ground = false, Left = false }
    end
    if math.abs(lpos.X) >= math.abs(lpos.Z) then
        if lpos.X > 0 then
            return ANIM_RIGHT, { Right = true, Ground = false, Left = false }
        else
            return ANIM_LEFT, { Right = false, Ground = false, Left = true }
        end
    else
        if lpos.Z < 0 then
            return ANIM_HEADER, { Right = false, Ground = false, Left = false }
        else
            return ANIM_BACK, { Right = false, Ground = false, Left = false }
        end
    end
end

local function reachTouchAll()
    for _, ball in ipairs(getAllBalls()) do
        local origSize = ball.Size
        local origCollide = ball.CanCollide
        pcall(function()
            ball.Size = Vector3.new(10, 10, 10)
            ball.CanCollide = false
        end)
        task.delay(0.18, function()
            pcall(function()
                if ball and ball.Parent then
                    ball.Size = origSize
                    ball.CanCollide = origCollide
                end
            end)
        end)
    end
end

local function fireAllKicks(hrp, flags)
    local remote = getKickRemote()
    if not remote then return end
    local cf = CFrame.new(hrp.Position, hrp.Position + hrp.CFrame.LookVector)
    for _, ball in ipairs(getAllBalls()) do
        local args = {{ ball, "Dive", 1, flags, cf, Vector3.zero }}
        pcall(function() remote:FireServer(unpack(args)) end)
    end
end

local function doDive(ball)
    if onCooldown or animPlaying then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    onCooldown = true
    local ballPos = ball.Position
    local animId, flags = pickDive(hrp, ballPos)
    local flat = Vector3.new(ballPos.X - hrp.Position.X, 0, ballPos.Z - hrp.Position.Z)
    if flat.Magnitude < 0.01 then flat = hrp.CFrame.LookVector * Vector3.new(1, 0, 1) end
    flat = flat.Unit
    local launchVel = flat * DIVE_SPEED + Vector3.new(0, DIVE_LIFT, 0)
    hrp.AssemblyLinearVelocity = launchVel
    local frames = 0
    local pushConn = RunService.Heartbeat:Connect(function()
        frames = frames + 1
        if frames <= 3 then pcall(function() hrp.AssemblyLinearVelocity = launchVel end)
        else pushConn:Disconnect() end
    end)
    playAnim(char, animId)
    for _, t in ipairs({0.08, 0.22, 0.38, 0.52}) do
        task.delay(t, function() reachTouchAll() end)
    end
    local loopStart = tick()
    local loopConn = RunService.PreSimulation:Connect(function()
        local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not h then loopConn:Disconnect(); return end
        for _, b in ipairs(getAllBalls()) do
            if (b.Position - h.Position).Magnitude < 5 then loopConn:Disconnect(); return end
        end
        if tick() - loopStart >= 3.5 then loopConn:Disconnect(); return end
        fireAllKicks(h, flags)
    end)
    task.delay(COOLDOWN, function() onCooldown = false end)
end

-- ============================================
--  BALL PREDICTION
-- ============================================

local function nearestFootballToPlayer()
    local footballs = workspace:FindFirstChild("Footballs")
    if not footballs then return nil end
    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end
    local best, bestDistance = nil, math.huge
    for _, object in pairs(footballs:GetChildren()) do
        if object:IsA("BasePart") then
            local distance = (object.Position - rootPart.Position).Magnitude
            if distance < bestDistance then
                bestDistance = distance
                best = object
            end
        end
    end
    return best
end

local function createBallPredictionFX()
    local folder = Instance.new("Folder")
    folder.Name = "BallPredictionFX"
    folder.Parent = workspace
    local startAttachment = Instance.new("Attachment")
    startAttachment.Name = "PredictStart"
    local endPart = Instance.new("Part")
    endPart.Name = "PredictEndPart"
    endPart.Size = Vector3.new(0.1, 0.1, 0.1)
    endPart.Transparency = 1
    endPart.Anchored = true
    endPart.CanCollide = false
    endPart.Parent = folder
    local endAttachment = Instance.new("Attachment")
    endAttachment.Name = "PredictEnd"
    endAttachment.Parent = endPart
    local beam = Instance.new("Beam")
    beam.Attachment0 = startAttachment
    beam.Attachment1 = endAttachment
    beam.Width0 = 0.4
    beam.Width1 = 0.4
    beam.FaceCamera = true
    beam.ZOffset = -0.1
    beam.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 76, 76)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 150, 150)),
    })
    beam.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.1),
        NumberSequenceKeypoint.new(0.8, 0.3),
        NumberSequenceKeypoint.new(1, 1),
    })
    beam.Parent = folder
    local impactMarker = Instance.new("Part")
    impactMarker.Shape = Enum.PartType.Ball
    impactMarker.Size = Vector3.new(0.8, 0.8, 0.8)
    impactMarker.Color = Color3.fromRGB(255, 76, 76)
    impactMarker.Material = Enum.Material.Neon
    impactMarker.Anchored = true
    impactMarker.CanCollide = false
    impactMarker.Transparency = 0.2
    impactMarker.Parent = folder
    return folder, beam, startAttachment, endAttachment, impactMarker
end

local predictionConnection
local predictionFolder
local predictionBeam
local predictionStart
local predictionEnd
local predictionMarker
local predictionBall

local function startPrediction97mzu()
    if predictionConnection then predictionConnection:Disconnect() end
    predictionFolder, predictionBeam, predictionStart, predictionEnd, predictionMarker = createBallPredictionFX()
    predictionConnection = RunService.RenderStepped:Connect(function()
        local ball = nearestFootballToPlayer()
        local usable = ball and ball.AssemblyLinearVelocity.Magnitude > 0.5
        if usable then
            if predictionBall ~= ball then
                predictionBall = ball
                predictionStart.Parent = ball
            end
            predictionFolder.Parent = workspace
            local position = ball.Position
            local velocity = ball.AssemblyLinearVelocity
            local gravity = Vector3.new(0, -workspace.Gravity, 0)
            local t = 1.2
            local predicted = position + velocity * t + gravity * 0.5 * 1.44
            predictionEnd.Parent.Position = predicted
            local fromStart = predicted - position
            local fromEnd = position - predicted
            predictionBeam.CurveSize0 = fromStart.Magnitude * 0.5
            predictionBeam.CurveSize1 = fromEnd.Magnitude * 0.5
            if fromStart.Magnitude > 0 then predictionStart.WorldAxis = fromStart.Unit end
            if fromEnd.Magnitude > 0 then predictionEnd.WorldAxis = fromEnd.Unit end
            predictionMarker.Position = predicted
        else
            if predictionFolder then predictionFolder.Parent = nil end
            predictionBall = nil
        end
    end)
end

local function stopPrediction97mzu()
    if predictionConnection then predictionConnection:Disconnect(); predictionConnection = nil end
    if predictionFolder then predictionFolder:Destroy(); predictionFolder = nil end
    predictionBeam = nil; predictionStart = nil; predictionEnd = nil; predictionMarker = nil; predictionBall = nil
end

-- ============================================
--  IMPACT DISTANCE
-- ============================================

local impactFolder
local impactPart
local impactConnection

local function startImpactDistance()
    if impactConnection then impactConnection:Disconnect() end
    impactFolder = Instance.new("Folder")
    impactFolder.Name = "ImpactDistanceFX"
    impactFolder.Parent = workspace
    impactPart = Instance.new("Part")
    impactPart.Shape = Enum.PartType.Cylinder
    impactPart.Size = Vector3.new(0.1, 4, 4)
    impactPart.Color = Color3.fromRGB(255, 76, 76)
    impactPart.Material = Enum.Material.Neon
    impactPart.Anchored = true
    impactPart.CanCollide = false
    impactPart.Transparency = 0.4
    impactPart.CFrame = CFrame.new() * CFrame.Angles(0, 0, math.rad(90))
    impactPart.Parent = impactFolder
    impactConnection = RunService.RenderStepped:Connect(function()
        local ball = nearestFootballToPlayer()
        if not ball or ball.AssemblyLinearVelocity.Magnitude <= 0.5 then
            if impactFolder then impactFolder.Parent = nil end
            return
        end
        impactFolder.Parent = workspace
        local position = ball.Position
        local velocity = ball.AssemblyLinearVelocity
        local gravity = Vector3.new(0, -workspace.Gravity, 0)
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
        local impactPosition
        for t = 0, 3, 0.05 do
            local nextT = t + 0.05
            local p0 = position + velocity * t + gravity * 0.5 * (t ^ 2)
            local p1 = position + velocity * nextT + gravity * 0.5 * (nextT ^ 2)
            local hit = workspace:Raycast(p0, p1 - p0, rayParams)
            if hit then impactPosition = hit.Position; break end
        end
        if impactPosition then
            impactPart.Transparency = 0.4
            impactPart.CFrame = CFrame.new(impactPosition) * CFrame.Angles(0, 0, math.rad(90))
        else
            impactPart.Transparency = 1
        end
    end)
end

local function stopImpactDistance()
    if impactConnection then impactConnection:Disconnect(); impactConnection = nil end
    if impactFolder then impactFolder:Destroy(); impactFolder = nil end
    impactPart = nil
end

-- ============================================
--  BALL STATS
-- ============================================

local statsFolder
local statsBillboard
local statsLabel
local statsConnection

local function startBallStats()
    if statsConnection then statsConnection:Disconnect() end
    statsFolder = Instance.new("Folder")
    statsFolder.Name = "BallStatsFX"
    statsFolder.Parent = workspace
    statsBillboard = Instance.new("BillboardGui")
    statsBillboard.Size = UDim2.new(0, 200, 0, 50)
    statsBillboard.StudsOffset = Vector3.new(0, 2.5, 0)
    statsBillboard.AlwaysOnTop = true
    statsBillboard.Parent = statsFolder
    statsLabel = Instance.new("TextLabel")
    statsLabel.Size = UDim2.new(1, 0, 1, 0)
    statsLabel.BackgroundTransparency = 1
    statsLabel.TextColor3 = Color3.fromRGB(255, 76, 76)
    statsLabel.TextStrokeTransparency = 0
    statsLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    statsLabel.Font = Enum.Font.SourceSansBold
    statsLabel.TextSize = 14
    statsLabel.Parent = statsBillboard
    statsConnection = RunService.RenderStepped:Connect(function()
        local ball = nearestFootballToPlayer()
        if not ball then
            if statsFolder then statsFolder.Parent = nil end
            return
        end
        statsFolder.Parent = workspace
        statsBillboard.Adornee = ball
        local speed = math.floor(ball.AssemblyLinearVelocity.Magnitude)
        local altitude = math.floor(ball.Position.Y)
        local character = LocalPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        local distance = 0
        if rootPart then distance = math.floor((ball.Position - rootPart.Position).Magnitude) end
        statsLabel.Text = string.format("Speed: %d SPS\nAlt: %d | Dist: %d studs", speed, altitude, distance)
    end)
end

local function stopBallStats()
    if statsConnection then statsConnection:Disconnect(); statsConnection = nil end
    if statsFolder then statsFolder:Destroy(); statsFolder = nil end
    statsBillboard = nil; statsLabel = nil
end

-- ============================================
--  REACT SYSTEM
-- ============================================

local function sf(k, v)
    if not setfflag then return end
    local ck = k:gsub("^DFInt",""):gsub("^DFFlag",""):gsub("^FFlag",""):gsub("^FInt","")
    pcall(function()
        if getfflag and getfflag(ck) ~= nil then setfflag(ck, v)
        else setfflag(k, v) end
    end)
end

local function applyReact(tt, interp)
    _lastReactTT = tt; _lastReactInterp = interp
    if _reactThread then task.cancel(_reactThread); _reactThread = nil end
    if not _reactActive then return end
    local flags = {
        ["DFIntTargetTimeDelayFacctorTenths"] = tt,
        ["FIntInterpolationMaxDelayMSec"] = interp,
    }
    _reactThread = task.spawn(function()
        while true do
            for k, v in pairs(flags) do pcall(function() sf(k, v) end) end
            task.wait(20)
        end
    end)
end

local function applyGkReact(tt, interp)
    _lastGkReactTT = tt; _lastGkReactInterp = interp
    if _gkReactThread then task.cancel(_gkReactThread); _gkReactThread = nil end
    if not _gkReactActive then return end
    local flags = {
        ["DFIntTargetTimeDelayFacctorTenths"] = tt,
        ["FIntInterpolationMaxDelayMSec"] = interp,
    }
    _gkReactThread = task.spawn(function()
        while true do
            for k, v in pairs(flags) do pcall(function() sf(k, v) end) end
            task.wait(20)
        end
    end)
end

-- ============================================
--  FFLAGS
-- ============================================

local function pingReducer()
    local removable = { ParticleEmitter = true, Smoke = true, Fire = true }
    task.spawn(function()
        local descendants = workspace:GetDescendants()
        for i = #descendants, 1, -1 do
            local obj = descendants[i]
            if obj and removable[obj.ClassName] then obj:Destroy() end
        end
    end)
end

local function darkAbyss()
    for _, child in pairs(Lighting:GetChildren()) do
        if child:IsA("Sky") then child:Destroy() end
    end
    local sky = Instance.new("Sky")
    sky.Name = "97mzuDarkSky"
    sky.SkyboxBk = "rbxassetid://0"
    sky.SkyboxDn = "rbxassetid://0"
    sky.SkyboxFt = "rbxassetid://0"
    sky.SkyboxLf = "rbxassetid://0"
    sky.SkyboxRt = "rbxassetid://0"
    sky.SkyboxUp = "rbxassetid://0"
    sky.Parent = Lighting
    Lighting.Ambient = Color3.fromRGB(128, 128, 128)
    Lighting.OutdoorAmbient = Color3.fromRGB(100, 100, 100)
    Lighting.FogColor = Color3.fromRGB(120, 120, 120)
    Lighting.FogEnd = 1000
end

local savedPostEffects = {}
local function disablePostFX(enabled)
    if enabled then
        for _, obj in pairs(Lighting:GetChildren()) do
            if obj:IsA("PostEffect") then savedPostEffects[obj] = obj.Enabled; obj.Enabled = false end
        end
        local camera = workspace.CurrentCamera
        if camera then
            for _, obj in pairs(camera:GetChildren()) do
                if obj:IsA("PostEffect") then savedPostEffects[obj] = obj.Enabled; obj.Enabled = false end
            end
        end
    else
        for obj, prev in pairs(savedPostEffects) do
            if obj and obj.Parent then obj.Enabled = prev end
        end
        table.clear(savedPostEffects)
    end
end

local overrideState = { materials = {}, reflectance = {}, quality = nil, globalShadows = nil }

local function overrideTexture(enabled)
    if enabled then
        overrideState.quality = settings().Rendering.QualityLevel
        overrideState.globalShadows = Lighting.GlobalShadows
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level03 end)
        Lighting.GlobalShadows = false
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                overrideState.materials[obj] = obj.Material
                overrideState.reflectance[obj] = obj.Reflectance
                obj.Material = Enum.Material.SmoothPlastic
                obj.Reflectance = 0
            elseif obj:IsA("Texture") or obj:IsA("Decal") then
                obj.Transparency = 1
            end
        end
    else
        pcall(function()
            if overrideState.quality then settings().Rendering.QualityLevel = overrideState.quality end
        end)
        if overrideState.globalShadows ~= nil then Lighting.GlobalShadows = overrideState.globalShadows end
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local mat = overrideState.materials[obj]
                if mat then obj.Material = mat end
                local ref = overrideState.reflectance[obj]
                if ref ~= nil then obj.Reflectance = ref end
            elseif obj:IsA("Texture") or obj:IsA("Decal") then
                obj.Transparency = 0
            end
        end
        table.clear(overrideState.materials); table.clear(overrideState.reflectance)
    end
end

local disablePlayerShadowsConnection
local function disablePlayerShadows(enabled)
    if disablePlayerShadowsConnection then disablePlayerShadowsConnection:Disconnect(); disablePlayerShadowsConnection = nil end
    if not enabled then return end
    local function applyCharacter(character)
        if not character then return end
        for _, obj in pairs(character:GetDescendants()) do
            if obj:IsA("BasePart") then obj.CastShadow = false end
        end
    end
    local function bindPlayer(player)
        if player.Character then applyCharacter(player.Character) end
        player.CharacterAdded:Connect(applyCharacter)
    end
    for _, player in pairs(Players:GetPlayers()) do bindPlayer(player) end
    disablePlayerShadowsConnection = Players.PlayerAdded:Connect(bindPlayer)
end

-- ============================================
--  SKY TEXTURES
-- ============================================

local function auroraSky()
    local sky = Instance.new("Sky")
    sky.SkyboxBk = "rbxassetid://75955506846727"
    sky.SkyboxDn = "rbxassetid://117391257413562"
    sky.SkyboxFt = "rbxassetid://109900307855247"
    sky.SkyboxLf = "rbxassetid://99736968434760"
    sky.SkyboxRt = "rbxassetid://130270741662079"
    sky.SkyboxUp = "rbxassetid://102086995250620"
    sky.Parent = Lighting
end

local function fullNightSky()
    local sky = Instance.new("Sky")
    sky.Parent = Lighting
    sky.CelestialBodiesShown = false
    local texture = "http://www.roblox.com/asset/?id=17055447520"
    sky.SkyboxBk = texture; sky.SkyboxDn = texture; sky.SkyboxFt = texture
    sky.SkyboxLf = texture; sky.SkyboxRt = texture; sky.SkyboxUp = texture
end

local function sakuraPinkSky()
    local sky = Instance.new("Sky")
    sky.Parent = Lighting
    sky.SkyboxBk = "http://www.roblox.com/asset/?id=271042516"
    sky.SkyboxDn = "http://www.roblox.com/asset/?id=271077243"
    sky.SkyboxFt = "http://www.roblox.com/asset/?id=271042556"
    sky.SkyboxLf = "http://www.roblox.com/asset/?id=271042310"
    sky.SkyboxRt = "http://www.roblox.com/asset/?id=271042467"
    sky.SkyboxUp = "http://www.roblox.com/asset/?id=271077958"
    sky.StarCount = 5000
end

-- ============================================
--  200 KICKS
-- ============================================

local function fireKick()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local ball, dist = getClosestFootball()
    if not ball or dist > kickReach then return end
    local kickRemote = getKickRemote()
    if not kickRemote then return end
    local Camera = workspace.CurrentCamera
    if not Camera then return end
    local lookVector = Camera.CFrame.LookVector
    local direction = CFrame.new(hrp.Position + lookVector * 5, hrp.Position + lookVector * 10)
    local args = {{ ball, "Shoot", 1, { Right = false, Ground = true, Left = false }, direction, Vector3.zero }}
    pcall(function() kickRemote:FireServer(unpack(args)) end)
end

-- ============================================
--  FLY SYSTEM
-- ============================================

local function flyCleanup()
    if flyBV then pcall(function() flyBV:Destroy() end); flyBV = nil end
    pcall(function()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then hum.PlatformStand = false end
    end)
end

-- ============================================
--  WALKSPEED & JUMP POWER
-- ============================================

local function SetWalkSpeedSafely(humanoid, value)
    if not humanoid or not humanoid.Parent then return end
    if humanoid.WalkSpeed == value then return end
    changingWalkSpeed = true
    humanoid.WalkSpeed = value
    changingWalkSpeed = false
end

local function ApplyWalkSpeed(character)
    if not WalkSpeedEnabled or isCharacterRespawning then return end
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then currentHumanoid = humanoid; SetWalkSpeedSafely(humanoid, WalkSpeedValue) end
end

local function StopWalkSpeedLoop(restoreDefault)
    if walkSpeedConnection then walkSpeedConnection:Disconnect(); walkSpeedConnection = nil end
    local humanoid = currentHumanoid or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"))
    if restoreDefault and humanoid then SetWalkSpeedSafely(humanoid, DefaultWalkSpeed) end
    currentHumanoid = nil
end

local function StartWalkSpeedLoop()
    StopWalkSpeedLoop(false)
    if not WalkSpeedEnabled then return end
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    DefaultWalkSpeed = humanoid.WalkSpeed
    currentHumanoid = humanoid
    SetWalkSpeedSafely(humanoid, WalkSpeedValue)
    walkSpeedConnection = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if not scriptAlive or not WalkSpeedEnabled or changingWalkSpeed then return end
        if humanoid ~= currentHumanoid or not humanoid.Parent then return end
        SetWalkSpeedSafely(humanoid, WalkSpeedValue)
    end)
end

local function ApplyJumpPower(character)
    if not JumpPowerEnabled or isCharacterRespawning then return end
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.JumpPower = JumpPowerValue
        pcall(function() humanoid.JumpHeight = JumpPowerValue / 7 end)
    end
end

local function ResetJumpPower(character)
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.JumpPower = DefaultJumpPower
        pcall(function() humanoid.JumpHeight = DefaultJumpPower / 7 end)
    end
end

local function OnCharacterAdded(character)
    isCharacterRespawning = true
    local humanoid = character:WaitForChild("Humanoid")
    if not scriptAlive or not character.Parent then return end
    DefaultWalkSpeed = humanoid.WalkSpeed
    DefaultJumpPower = humanoid.JumpPower
    currentHumanoid = humanoid
    isCharacterRespawning = false
    if WalkSpeedEnabled then StartWalkSpeedLoop() end
    if JumpPowerEnabled then ApplyJumpPower(character) end
end

TrackConnection(LocalPlayer.CharacterAdded:Connect(OnCharacterAdded))

if LocalPlayer.Character then task.spawn(OnCharacterAdded, LocalPlayer.Character) end

-- ============================================
--  LOOPS (Originales de tu script)
-- ============================================

RunService.Heartbeat:Connect(function()
    if not gkAutoDiveEnabled then return end
    if not inBox() then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local ball = getMostDangerousBall()
    if not ball then return end
    local dist = (ball.Position - hrp.Position).Magnitude
    if dist < 4.5 and not touchCD then
        touchCD = true
        reachTouchAll()
        task.delay(0.08, function() touchCD = false end)
    end
    if not onCooldown and not animPlaying and dist <= HIT_RADIUS then doDive(ball) end
end)

RunService.Heartbeat:Connect(function()
    pcall(function() cachedPingGlobal = math.clamp(LocalPlayer:GetNetworkPing(), 0.008, 0.30) end)
end)

RunService.Heartbeat:Connect(function()
    if not WalkSpeedEnabled then return end
    pcall(function()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = WalkSpeedValue end
    end)
end)

RunService.Heartbeat:Connect(function()
    if not JumpPowerEnabled then return end
    pcall(function()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then hum.UseJumpPower = true; hum.JumpPower = JumpPowerValue end
    end)
end)

-- ============================================
--  CLEANUP
-- ============================================

RuntimeEnvironment.__P3G_HUB_CLEANUP = function()
    scriptAlive = false
    m1_enabled = false; reachMethod2Enabled = false; proxyEnabled = false
    CharacterReachEnabled = false; PlatformEnabled = false
    WalkSpeedEnabled = false; JumpPowerEnabled = false
    flyEnabled = false; tpEnabled = false
    kickLoopEnabled = false; dribbleEnabled = false
    gkAutoDiveEnabled = false; predOn = false
    _reactActive = false; _gkReactActive = false

    StopMethod1(); StopMethod2(); StopProxySystem()
    StopCharacterReachSystem(); StopPlatformSystem()
    flyCleanup()
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if tpConn then tpConn:Disconnect(); tpConn = nil end
    if kickConnection then kickConnection:Disconnect(); kickConnection = nil end
    if dribbleConn then dribbleConn:Disconnect(); dribbleConn = nil end
    if predConn then predConn:Disconnect(); predConn = nil end
    if _reactThread then task.cancel(_reactThread); _reactThread = nil end
    if _gkReactThread then task.cancel(_gkReactThread); _gkReactThread = nil end
    stopAnim()

    stopPrediction97mzu(); stopImpactDistance(); stopBallStats()
    if disablePlayerShadowsConnection then
        disablePlayerShadowsConnection:Disconnect()
        disablePlayerShadowsConnection = nil
    end

    ClearAllPlatforms()
    StopWalkSpeedLoop(true)
    ResetJumpPower(LocalPlayer.Character)

    table.clear(ballParts); table.clear(ballVisualizers); table.clear(ballProxies)
    table.clear(proxyOriginalSizes); table.clear(reachOriginalProperties)
    table.clear(platforms); table.clear(predObjs)
    table.clear(originalColors); table.clear(originalSizes); table.clear(method2_trackedParts)

    DisconnectTrackedConnections()
end

-- ============================================
--  API PARA LA UI (GITHUB)
-- ============================================

local UI_API = {
    -- Funciones del juego
    StartMethod1 = StartMethod1,
    StopMethod1 = StopMethod1,
    StartMethod2 = StartMethod2,
    StopMethod2 = StopMethod2,
    StartProxySystem = StartProxySystem,
    StopProxySystem = StopProxySystem,
    StartCharacterReachSystem = StartCharacterReachSystem,
    StopCharacterReachSystem = StopCharacterReachSystem,
    RefreshCharacterReach = RefreshCharacterReach,
    UpdateVisualizers = UpdateVisualizers,
    stopAnim = stopAnim,
    startPrediction97mzu = startPrediction97mzu,
    stopPrediction97mzu = stopPrediction97mzu,
    startImpactDistance = startImpactDistance,
    stopImpactDistance = stopImpactDistance,
    StealAvatarByName = StealAvatarByName,
    StartWalkSpeedLoop = StartWalkSpeedLoop,
    StopWalkSpeedLoop = StopWalkSpeedLoop,
    ApplyWalkSpeed = ApplyWalkSpeed,
    ApplyJumpPower = ApplyJumpPower,
    ResetJumpPower = ResetJumpPower,
    fireKick = fireKick,
    getClosestFootball = getClosestFootball,
    StartPlatformSystem = StartPlatformSystem,
    StopPlatformSystem = StopPlatformSystem,
    UpdatePlatformSize = UpdatePlatformSize,
    sf = sf,
    pingReducer = pingReducer,
    darkAbyss = darkAbyss,
    auroraSky = auroraSky,
    fullNightSky = fullNightSky,
    sakuraPinkSky = sakuraPinkSky,
    overrideTexture = overrideTexture,
    disablePlayerShadows = disablePlayerShadows,
    applyReact = applyReact,
    Cleanup = function() 
        if RuntimeEnvironment.__P3G_HUB_CLEANUP then RuntimeEnvironment.__P3G_HUB_CLEANUP() end 
    end,

    -- Diccionario de Variables (Para que la UI las lea y escriba)
    Vars = {
        m1_enabled = m1_enabled,
        reachMethod2Enabled = reachMethod2Enabled,
        proxyEnabled = proxyEnabled,
        CharacterReachEnabled = CharacterReachEnabled,
        gkAutoDiveEnabled = gkAutoDiveEnabled,
        WalkSpeedEnabled = WalkSpeedEnabled,
        WalkSpeedValue = WalkSpeedValue,
        JumpPowerEnabled = JumpPowerEnabled,
        JumpPowerValue = JumpPowerValue,
        _reactActive = _reactActive,
        kickLoopEnabled = kickLoopEnabled,
        kickReach = kickReach,
        dribbleEnabled = dribbleEnabled,
        dribbleSpeed = dribbleSpeed,
        PlatformEnabled = PlatformEnabled,
        PlatformSize = PlatformSize,
        m1_size = m1_size,
        m1_transparency = m1_transparency,
        CharacterReachSize = CharacterReachSize,
        DIVE_RANGE = DIVE_RANGE,
        DIVE_SPEED = DIVE_SPEED,
        _lastReactTT = _lastReactTT,
        _lastReactInterp = _lastReactInterp,
    },
    
    -- Hilos y Conexiones (Para que la UI pueda guardar estados)
    Threads = {},
    Connections = {},
}

-- Funciones Helper para que la UI modifique el script principal
function UI_API.GetVar(name) return UI_API.Vars[name] end
function UI_API.SetVar(name, value) UI_API.Vars[name] = value end
function UI_API.GetThread(name) return UI_API.Threads[name] end
function UI_API.SetThread(name, value) UI_API.Threads[name] = value end
function UI_API.GetConnection(name) return UI_API.Connections[name] end
function UI_API.SetConnection(name, value) UI_API.Connections[name] = value end

-- ============================================
-- CARGAR LA UI DESDE GITHUB
-- ============================================
local UI_URL = "https://raw.githubusercontent.com/user913945673657265478/ui/refs/heads/main/ui.lua"

local success, err = pcall(function()
    local uiCode = game:HttpGet(UI_URL)
    local loadUI = loadstring(uiCode)
    if loadUI then
        local UI_Instance = loadUI() -- Carga la función
        UI_Instance(UI_API) -- Le pasa la API a la UI para que funcione
    else
        warn("Error al compilar la UI")
    end
end)

if not success then
    warn("Error al cargar la UI desde GitHub: " .. tostring(err))
end
