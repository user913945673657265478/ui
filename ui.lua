-- Archivo: ui.lua para GitHub
-- P3G HUB Interface (Optimizado)

return function(API)
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
    local CoreGui = game:GetService("CoreGui")
    local Lighting = game:GetService("Lighting")

    local Colors = {
        MainBg = Color3.fromRGB(25, 25, 28),       
        SidebarBg = Color3.fromRGB(20, 20, 22),    
        ItemBg = Color3.fromRGB(40, 40, 45),       
        Text = Color3.fromRGB(240, 240, 240),      
        SubText = Color3.fromRGB(140, 140, 150),   
        Accent = Color3.fromRGB(255, 255, 255),    
        Green = Color3.fromRGB(80, 200, 120),      
        Red = Color3.fromRGB(200, 50, 50),
        DarkGrey = Color3.fromRGB(60, 60, 65),
        Divider = Color3.fromRGB(60, 60, 65),      
    }

    local GradColor1 = Color3.fromRGB(120, 15, 15) 
    local GradColor2 = Color3.fromRGB(5, 5, 5)   

    local isUIOpen = false
    local currentTabName = "Reach"

    local function Create(class, props)
        local obj = Instance.new(class)
        for k, v in pairs(props) do obj[k] = v end
        return obj
    end

    local function AddCorner(parent, radius)
        return Create("UICorner", {CornerRadius = UDim.new(0, radius or 6), Parent = parent})
    end

    local function AddStroke(parent, color, thickness)
        return Create("UIStroke", {Color = color or Color3.fromRGB(60, 60, 65), Thickness = thickness or 1, Parent = parent})
    end

    if CoreGui:FindFirstChild("P3G_HUB_UI") then
        CoreGui:FindFirstChild("P3G_HUB_UI"):Destroy()
    end

    local Blur = Lighting:FindFirstChild("P3G_Blur") or Create("BlurEffect", {Name = "P3G_Blur", Size = 10, Parent = Lighting})
    Blur.Enabled = false

    local ScreenGui = Create("ScreenGui", {
        Name = "P3G_HUB_UI",
        ResetOnSpawn = false,
        Parent = CoreGui
    })

    local MainFrame = Create("Frame", {
        Name = "Main",
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, -300, 0.5, -225),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        Parent = ScreenGui
    })
    AddCorner(MainFrame, 12)
    AddStroke(MainFrame, Color3.fromRGB(80, 80, 80), 1)

    Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, GradColor1),
            ColorSequenceKeypoint.new(1, GradColor2)
        }),
        Rotation = 135,
        Parent = MainFrame
    })

    task.spawn(function()
        task.wait(0.1)
        TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 600, 0, 450)}):Play()
        TweenService:Create(Blur, TweenInfo.new(0.4), {Size = 10}):Play()
        Blur.Enabled = true
        isUIOpen = true
    end)

    local TopBar = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 45),
        BackgroundTransparency = 1,
        Parent = MainFrame
    })

    Create("TextLabel", {
        Text = "P3G HUB",
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = Colors.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 150, 1, 0),
        Position = UDim2.new(0.5, -75, 0, 0),
        Parent = TopBar
    })

    local function CloseUI()
        if not isUIOpen then return end
        isUIOpen = false
        TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)}):Play()
        TweenService:Create(Blur, TweenInfo.new(0.3), {Size = 0}):Play()
        task.wait(0.3)
        Blur.Enabled = false
        ScreenGui.Enabled = false
    end

    local function OpenUI()
        if isUIOpen then return end
        isUIOpen = true
        ScreenGui.Enabled = true
        Blur.Enabled = true
        TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 600, 0, 450)}):Play()
        TweenService:Create(Blur, TweenInfo.new(0.4), {Size = 10}):Play()
    end

    local function CreateWindowBtn(text, posX, color, callback)
        local btn = Create("TextButton", {
            Text = text, Font = Enum.Font.Gotham, TextSize = 18, TextColor3 = Colors.SubText,
            BackgroundTransparency = 1, Size = UDim2.new(0, 30, 1, 0), Position = UDim2.new(1, posX, 0, 0), Parent = TopBar
        })
        btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.2), {TextColor3 = color}):Play() end)
        btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.2), {TextColor3 = Colors.SubText}):Play() end)
        if callback then btn.MouseButton1Click:Connect(callback) end
        return btn
    end

    CreateWindowBtn("—", -80, Colors.Text, function() CloseUI() end)
    CreateWindowBtn("×", -40, Colors.Red, function() 
        ScreenGui:Destroy()
        if Blur then Blur:Destroy() end
        if API.Cleanup then API.Cleanup() end
    end)

    Create("Frame", {
        Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Colors.Divider, BackgroundTransparency = 0.5, BorderSizePixel = 0, Parent = TopBar
    })

    local dragging = false
    local dragStart, startPos
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = input.Position; startPos = MainFrame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    local Sidebar = Create("Frame", {
        Size = UDim2.new(0, 150, 1, -45), Position = UDim2.new(0, 0, 0, 45),
        BackgroundTransparency = 1, Parent = MainFrame
    })
    Create("Frame", {Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, 0, 0, 0), BackgroundColor3 = Colors.Divider, BackgroundTransparency = 0.6, BorderSizePixel = 0, Parent = Sidebar})
    local SidebarContainer = Create("Frame", {Size = UDim2.new(1, -20, 1, -20), Position = UDim2.new(0, 10, 0, 10), BackgroundTransparency = 1, Parent = Sidebar})
    Create("UIListLayout", {Padding = UDim.new(0, 5), Parent = SidebarContainer})

    local ContentArea = Create("ScrollingFrame", {
        Size = UDim2.new(1, -170, 1, -60), Position = UDim2.new(0, 160, 0, 55),
        BackgroundTransparency = 1, ScrollBarThickness = 0, CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = MainFrame
    })
    Create("UIListLayout", {Padding = UDim.new(0, 8), Parent = ContentArea})

    local function ClearContent()
        for _, child in pairs(ContentArea:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
        end
    end

    local function CreateTextBox(title, placeholder, callback)
        local container = Create("Frame", {Size = UDim2.new(1, -10, 0, 55), BackgroundColor3 = Colors.ItemBg, BackgroundTransparency = 0.2, Parent = ContentArea})
        AddCorner(container, 8); AddStroke(container, Colors.Divider, 1)
        Create("TextLabel", {Text = title, Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = Colors.Text, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.new(0, 15, 0, 8), Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Parent = container})
        local boxBg = Create("Frame", {Size = UDim2.new(0, 180, 0, 25), Position = UDim2.new(1, -195, 0.5, -5), BackgroundColor3 = Color3.fromRGB(20, 20, 22), BackgroundTransparency = 0.3, Parent = container})
        AddCorner(boxBg, 6)
        local input = Create("TextBox", {Size = UDim2.new(1, -10, 1, 0), Position = UDim2.new(0, 5, 0, 0), BackgroundTransparency = 1, Text = "", PlaceholderText = placeholder, PlaceholderColor3 = Colors.SubText, TextColor3 = Colors.Text, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = boxBg})
        input.FocusLost:Connect(function() if callback then callback(input.Text) end end)
    end

    local function CreateButton(name, callback)
        local btn = Create("TextButton", {Size = UDim2.new(1, -10, 0, 45), BackgroundColor3 = Colors.ItemBg, BackgroundTransparency = 0.2, Text = "  " .. name, Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = Colors.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = ContentArea})
        AddCorner(btn, 8); AddStroke(btn, Colors.Divider, 1)
        btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.5}):Play() end)
        btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.2}):Play() end)
        btn.MouseButton1Click:Connect(function() if callback then callback() end end)
    end

    local function CreateToggle(name, default, callback)
        local container = Create("Frame", {Size = UDim2.new(1, -10, 0, 45), BackgroundColor3 = Colors.ItemBg, BackgroundTransparency = 0.2, Parent = ContentArea})
        AddCorner(container, 8); AddStroke(container, Colors.Divider, 1)
        Create("TextLabel", {Text = name, Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = Colors.Text, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.new(0, 15, 0, 0), Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = container})
        local toggleBg = Create("Frame", {Size = UDim2.new(0, 36, 0, 18), Position = UDim2.new(1, -55, 0.5, -9), BackgroundColor3 = default and Colors.Accent or Colors.DarkGrey, Parent = container})
        AddCorner(toggleBg, 10)
        local knob = Create("Frame", {Size = UDim2.new(0, 14, 0, 14), Position = default and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7), BackgroundColor3 = default and Color3.fromRGB(20, 20, 22) or Colors.SubText, Parent = toggleBg})
        AddCorner(knob, 10)
        local isOn = default
        local btn = Create("TextButton", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", Parent = container})
        btn.MouseButton1Click:Connect(function()
            isOn = not isOn
            local targetPos = isOn and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
            local targetColorBg = isOn and Colors.Accent or Colors.DarkGrey
            local targetColorKnob = isOn and Color3.fromRGB(20, 20, 22) or Colors.SubText
            TweenService:Create(knob, TweenInfo.new(0.2), {Position = targetPos, BackgroundColor3 = targetColorKnob}):Play()
            TweenService:Create(toggleBg, TweenInfo.new(0.2), {BackgroundColor3 = targetColorBg}):Play()
            if callback then callback(isOn) end
        end)
    end

    local function CreateSlider(name, min, max, default, callback)
        local container = Create("Frame", {Size = UDim2.new(1, -10, 0, 55), BackgroundColor3 = Colors.ItemBg, BackgroundTransparency = 0.2, Parent = ContentArea})
        AddCorner(container, 8); AddStroke(container, Colors.Divider, 1)
        Create("TextLabel", {Text = name, Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = Colors.Text, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.new(0, 15, 0, 8), Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Parent = container})
        local valueBox = Create("Frame", {Size = UDim2.new(0, 45, 0, 22), Position = UDim2.new(1, -60, 0, 8), BackgroundColor3 = Color3.fromRGB(20, 20, 22), BackgroundTransparency = 0.3, Parent = container})
        AddCorner(valueBox, 4)
        local valueText = Create("TextLabel", {Text = tostring(default), Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Colors.Text, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = valueBox})
        local barBg = Create("Frame", {Size = UDim2.new(1, -30, 0, 3), Position = UDim2.new(0, 15, 1, -15), BackgroundColor3 = Colors.DarkGrey, Parent = container})
        AddCorner(barBg, 2)
        local fill = Create("Frame", {Size = UDim2.new((default - min) / (max - min), 0, 1, 0), BackgroundColor3 = Colors.Accent, Parent = barBg})
        AddCorner(fill, 2)
        local knob = Create("Frame", {Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(1, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Colors.Text, Parent = fill})
        AddCorner(knob, 10)
        local sliderArea = Create("TextButton", {Size = UDim2.new(1, -30, 0, 20), Position = UDim2.new(0, 15, 1, -25), BackgroundTransparency = 1, Text = "", Parent = container})
        local draggingSlider = false
        local function UpdateSlider(input)
            local mousePos = UserInputService:GetMouseLocation()
            local relX = math.clamp(mousePos.X - barBg.AbsolutePosition.X, 0, barBg.AbsoluteSize.X)
            local alpha = relX / barBg.AbsoluteSize.X
            fill.Size = UDim2.new(alpha, 0, 1, 0)
            local val = math.floor(min + ((max - min) * alpha))
            valueText.Text = tostring(val)
            if callback then callback(val) end
        end
        sliderArea.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingSlider = true; UpdateSlider(input) end end)
        UserInputService.InputChanged:Connect(function(input) if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then UpdateSlider(input) end end)
        UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingSlider = false end end)
    end

    local SidebarButtons = {"Home", "Reach", "GK", "Character", "React", "Helpers", "FFlags"}

    local function ChangeTab(tabName)
        ClearContent()
        
        if tabName == "Home" then
            CreateButton("Made By 0m3", function() end)
            CreateButton("Last Update: 8/8/2026", function() end)
            CreateButton("P3gOnTop!", function() end)

        elseif tabName == "Reach" then
            CreateToggle("Reach No Ball Collision", API.GetVar("m1_enabled"), function(v)
                API.SetVar("m1_enabled", v)
                if v and API.GetVar("reachMethod2Enabled") then API.SetVar("reachMethod2Enabled", false); API.StopMethod2() end
                if v then API.StartMethod1() else API.StopMethod1() end
            end)
            CreateSlider("Reach Size", 1, 30, API.GetVar("m1_size"), function(v) API.SetVar("m1_size", v); if API.GetVar("m1_enabled") then API.UpdateVisualizers(API.GetVar("m1_size"), API.GetVar("m1_transparency")) end end)
            CreateSlider("Visualizer Transparency", 0, 100, API.GetVar("m1_transparency") * 100, function(v) API.SetVar("m1_transparency", v / 100); if API.GetVar("m1_enabled") then API.UpdateVisualizers(API.GetVar("m1_size"), API.GetVar("m1_transparency")) end end)
            CreateToggle("Enable Collision Proxy", API.GetVar("proxyEnabled"), function(v) API.SetVar("proxyEnabled", v); if v then API.StartProxySystem() else API.StopProxySystem() end end)
            CreateToggle("Character Reach", API.GetVar("CharacterReachEnabled"), function(v) API.SetVar("CharacterReachEnabled", v); if v then API.StartCharacterReachSystem() else API.StopCharacterReachSystem() end end)
            CreateSlider("Char Reach Size", 1, 30, API.GetVar("CharacterReachSize"), function(v) API.SetVar("CharacterReachSize", v); if API.GetVar("CharacterReachEnabled") then API.RefreshCharacterReach() end end)

        elseif tabName == "GK" then
            CreateToggle("Enable Auto Dive", API.GetVar("gkAutoDiveEnabled"), function(v) API.SetVar("gkAutoDiveEnabled", v); if not v then API.stopAnim() end end)
            CreateSlider("Dive Range", 10, 60, API.GetVar("DIVE_RANGE"), function(v) API.SetVar("DIVE_RANGE", v) end)
            CreateSlider("Dive Speed", 20, 100, API.GetVar("DIVE_SPEED"), function(v) API.SetVar("DIVE_SPEED", v) end)
            CreateToggle("Ball Prediction", false, function(v) if v then API.startPrediction97mzu() else API.stopPrediction97mzu() end end)
            CreateToggle("Impact Distance", false, function(v) if v then API.startImpactDistance() else API.stopImpactDistance() end end)

        elseif tabName == "Character" then
            CreateTextBox("Avatar Stealer", "Enter username...", function(v) if v and v ~= "" then API.StealAvatarByName(v) end end)
            CreateButton("Fullbright", function() loadstring(game:HttpGet("https://pastebin.com/raw/5ic4YxBU", true))() end)
            CreateToggle("WalkSpeed Enabled", API.GetVar("WalkSpeedEnabled"), function(v) API.SetVar("WalkSpeedEnabled", v); if v then API.StartWalkSpeedLoop() else API.StopWalkSpeedLoop(true) end end)
            CreateSlider("WalkSpeed", 16, 50, API.GetVar("WalkSpeedValue"), function(v) API.SetVar("WalkSpeedValue", v); if API.GetVar("WalkSpeedEnabled") then API.ApplyWalkSpeed(game.Players.LocalPlayer.Character) end end)
            CreateToggle("Jump Power Enabled", API.GetVar("JumpPowerEnabled"), function(v) API.SetVar("JumpPowerEnabled", v); if not v then API.ResetJumpPower(game.Players.LocalPlayer.Character) end end)
            CreateSlider("Jump Power", 50, 200, API.GetVar("JumpPowerValue"), function(v) API.SetVar("JumpPowerValue", v); if API.GetVar("JumpPowerEnabled") then API.ApplyJumpPower(game.Players.LocalPlayer.Character) end end)

        elseif tabName == "React" then
            CreateToggle("Enable React", API.GetVar("_reactActive"), function(v) API.SetVar("_reactActive", v); if not v then if API.GetThread("_reactThread") then task.cancel(API.GetThread("_reactThread")); API.SetThread("_reactThread", nil) end else API.applyReact(API.GetVar("_lastReactTT"), API.GetVar("_lastReactInterp")) end end)
            CreateButton("React 15% (Safest)", function() API.applyReact("13", "90") end)
            CreateButton("React 25% (Light)", function() API.applyReact("12", "85") end)
            CreateButton("React 50% (Balanced)", function() API.applyReact("10", "75") end)
            CreateButton("React 100% (Maximum)", function() API.applyReact("6", "70") end)

        elseif tabName == "Helpers" then
            CreateToggle("Enable Kick Loop", API.GetVar("kickLoopEnabled"), function(v)
                API.SetVar("kickLoopEnabled", v)
                if v then
                    if not API.GetConnection("kickConnection") then API.SetConnection("kickConnection", game:GetService("RunService").PreSimulation:Connect(function() if API.GetVar("kickLoopEnabled") then API.fireKick() end end)) end
                else
                    if API.GetConnection("kickConnection") then API.GetConnection("kickConnection"):Disconnect(); API.SetConnection("kickConnection", nil) end
                end
            end)
            CreateSlider("Kick Reach", 5, 50, API.GetVar("kickReach"), function(v) API.SetVar("kickReach", v) end)
            CreateToggle("Enable INF Dribble", API.GetVar("dribbleEnabled"), function(v)
                API.SetVar("dribbleEnabled", v)
                if v then
                    if API.GetConnection("dribbleConn") then API.GetConnection("dribbleConn"):Disconnect() end
                    API.SetConnection("dribbleConn", game:GetService("RunService").Heartbeat:Connect(function()
                        if not API.GetVar("dribbleEnabled") then return end
                        local char = game.Players.LocalPlayer.Character
                        if not char then return end
                        local hum = char:FindFirstChild("Humanoid")
                        local ball = API.getClosestFootball()
                        if hum and ball then hum.WalkSpeed = API.GetVar("dribbleSpeed"); hum:MoveTo(ball.Position) end
                    end))
                else
                    if API.GetConnection("dribbleConn") then API.GetConnection("dribbleConn"):Disconnect(); API.SetConnection("dribbleConn", nil) end
                end
            end)
            CreateToggle("Enable Air Helper", API.GetVar("PlatformEnabled"), function(v) API.SetVar("PlatformEnabled", v); if v then API.StartPlatformSystem() else API.StopPlatformSystem() end end)
            CreateSlider("Platform Size", 3, 30, API.GetVar("PlatformSize"), function(v) API.SetVar("PlatformSize", v); API.UpdatePlatformSize() end)

        elseif tabName == "FFlags" then
            CreateButton("Ping Reducer", function() API.pingReducer() end)
            CreateButton("FFlagDarkAbyss", function() API.darkAbyss() end)
            CreateButton("Aurora Sky", function() API.auroraSky() end)
            CreateButton("Full Night Sky", function() API.fullNightSky() end)
            CreateButton("Sakura Pink Sky", function() API.sakuraPinkSky() end)
            CreateToggle("FFlagOverrideTexture", false, function(v) API.overrideTexture(v) end)
            CreateToggle("Disable Player Shadows", false, function(v) API.disablePlayerShadows(v) end)
            CreateButton("Apply All Flags", function()
                pcall(function()
                    API.sf("DFIntTargetTimeDelayFacctorTenths", "12")
                    API.sf("FIntInterpolationMaxDelayMSec", "8")
                    API.sf("DFIntS2PhysicsSenderRate", "90")
                    API.sf("DFIntTaskSchedulerTargetFps", "9999")
                end)
            end)
        end
    end

    for _, name in ipairs(SidebarButtons) do
        local isSelected = (name == "Reach")
        local btn = Create("TextButton", {
            Name = name, Text = "   " .. name, Font = Enum.Font.Gotham, TextSize = 14,
            TextColor3 = isSelected and Colors.Text or Colors.SubText, TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundColor3 = isSelected and Colors.ItemBg or Colors.MainBg, BackgroundTransparency = isSelected and 0.5 or 1,
            Size = UDim2.new(1, 0, 0, 35), Parent = SidebarContainer
        })
        AddCorner(btn, 8)
        if isSelected then AddStroke(btn, Colors.Divider, 1) end

        btn.MouseEnter:Connect(function() if not isSelected then TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Colors.ItemBg, BackgroundTransparency = 0.8}):Play() end end)
        btn.MouseLeave:Connect(function() if not isSelected then TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play() end end)

        btn.MouseButton1Click:Connect(function()
            for _, otherBtn in pairs(SidebarContainer:GetChildren()) do
                if otherBtn:IsA("TextButton") then
                    TweenService:Create(otherBtn, TweenInfo.new(0.2), {TextColor3 = Colors.SubText, BackgroundTransparency = 1}):Play()
                end
            end
            TweenService:Create(btn, TweenInfo.new(0.2), {TextColor3 = Colors.Text, BackgroundTransparency = 0.5}):Play()
            currentTabName = name
            ChangeTab(name)
        end)
    end

    ChangeTab("Reach")

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.RightControl then
            if isUIOpen then CloseUI() else OpenUI() end
        end
    end)
end
