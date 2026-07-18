local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local Library = {
    Version = "1.0.0"
}

local function Create(className, properties)
    local object = Instance.new(className)

    for property, value in pairs(properties or {}) do
        object[property] = value
    end

    return object
end

local function Tween(object, properties, duration)
    local tween = TweenService:Create(
        object,
        TweenInfo.new(
            duration or 0.18,
            Enum.EasingStyle.Quint,
            Enum.EasingDirection.Out
        ),
        properties
    )

    tween:Play()
    return tween
end

local function RunCallback(callback, ...)
    if typeof(callback) ~= "function" then
        return
    end

    local arguments = table.pack(...)

    task.spawn(function()
        local success, result = pcall(function()
            callback(table.unpack(arguments, 1, arguments.n))
        end)

        if not success then
            warn("[Universal UI] " .. tostring(result))
        end
    end)
end

local function GetParent()
    if typeof(gethui) == "function" then
        local success, result = pcall(gethui)

        if success and result then
            return result
        end
    end

    local success = pcall(function()
        local test = Instance.new("Folder")
        test.Name = "UniversalUITest"
        test.Parent = CoreGui
        test:Destroy()
    end)

    if success then
        return CoreGui
    end

    return LocalPlayer:WaitForChild("PlayerGui")
end

local function Round(value, increment)
    increment = increment or 1
    return math.floor((value / increment) + 0.5) * increment
end

local function FormatNumber(value, increment)
    if increment >= 1 then
        return tostring(math.floor(value + 0.5))
    end

    local text = string.format("%.3f", value)
    text = text:gsub("0+$", "")
    text = text:gsub("%.$", "")

    return text
end

local function MakeDraggable(object, handle)
    local dragging = false
    local dragInput
    local dragStart
    local startPosition

    handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        dragging = true
        dragStart = input.Position
        startPosition = object.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging or input ~= dragInput then
            return
        end

        local delta = input.Position - dragStart

        object.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end)
end

function Library:CreateWindow(configuration)
    configuration = configuration or {}

    local title = configuration.Title or "Universal UI"
    local subtitle = configuration.Subtitle or "Universal UI Library"
    local accent = configuration.Accent or Color3.fromRGB(125, 91, 255)
    local size = configuration.Size or Vector2.new(650, 430)
    local toggleKey = configuration.ToggleKey or Enum.KeyCode.RightShift

    if typeof(size) ~= "Vector2" then
        size = Vector2.new(650, 430)
    end

    local parent = GetParent()
    local screenName = configuration.Name or "UniversalUI"

    local previous = parent:FindFirstChild(screenName)

    if previous then
        previous:Destroy()
    end

    local ScreenGui = Create("ScreenGui", {
        Name = screenName,
        Parent = parent,
        ResetOnSpawn = false,
        IgnoreGuiInset = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999999
    })

    local WindowFrame = Create("Frame", {
        Name = "Window",
        Parent = ScreenGui,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(size.X, size.Y),
        BackgroundColor3 = Color3.fromRGB(17, 17, 22),
        BorderSizePixel = 0,
        ClipsDescendants = true
    })

    Create("UICorner", {
        Parent = WindowFrame,
        CornerRadius = UDim.new(0, 12)
    })

    Create("UIStroke", {
        Parent = WindowFrame,
        Color = Color3.fromRGB(70, 70, 84),
        Transparency = 0.25,
        Thickness = 1
    })

    local TopBar = Create("Frame", {
        Name = "TopBar",
        Parent = WindowFrame,
        Size = UDim2.new(1, 0, 0, 52),
        BackgroundColor3 = Color3.fromRGB(22, 22, 28),
        BorderSizePixel = 0,
        Active = true
    })

    Create("Frame", {
        Parent = TopBar,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Color3.fromRGB(48, 48, 58),
        BorderSizePixel = 0
    })

    local TitleLabel = Create("TextLabel", {
        Parent = TopBar,
        Position = UDim2.fromOffset(16, 6),
        Size = UDim2.new(1, -115, 0, 21),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = tostring(title),
        TextColor3 = Color3.fromRGB(245, 245, 250),
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local SubtitleLabel = Create("TextLabel", {
        Parent = TopBar,
        Position = UDim2.fromOffset(16, 27),
        Size = UDim2.new(1, -115, 0, 16),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = tostring(subtitle),
        TextColor3 = Color3.fromRGB(145, 145, 158),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local MinimizeButton = Create("TextButton", {
        Parent = TopBar,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -50, 0.5, 0),
        Size = UDim2.fromOffset(31, 31),
        BackgroundColor3 = Color3.fromRGB(34, 34, 42),
        AutoButtonColor = false,
        Font = Enum.Font.GothamBold,
        Text = "—",
        TextColor3 = Color3.fromRGB(220, 220, 228),
        TextSize = 15
    })

    Create("UICorner", {
        Parent = MinimizeButton,
        CornerRadius = UDim.new(0, 8)
    })

    local CloseButton = Create("TextButton", {
        Parent = TopBar,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(31, 31),
        BackgroundColor3 = Color3.fromRGB(34, 34, 42),
        AutoButtonColor = false,
        Font = Enum.Font.GothamBold,
        Text = "×",
        TextColor3 = Color3.fromRGB(235, 235, 242),
        TextSize = 18
    })

    Create("UICorner", {
        Parent = CloseButton,
        CornerRadius = UDim.new(0, 8)
    })

    local Body = Create("Frame", {
        Parent = WindowFrame,
        Position = UDim2.fromOffset(0, 52),
        Size = UDim2.new(1, 0, 1, -52),
        BackgroundTransparency = 1
    })

    local Sidebar = Create("Frame", {
        Parent = Body,
        Size = UDim2.new(0, 150, 1, 0),
        BackgroundColor3 = Color3.fromRGB(20, 20, 25),
        BorderSizePixel = 0
    })

    Create("Frame", {
        Parent = Sidebar,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        BackgroundColor3 = Color3.fromRGB(46, 46, 56),
        BorderSizePixel = 0
    })

    local TabHolder = Create("ScrollingFrame", {
        Parent = Sidebar,
        Position = UDim2.fromOffset(8, 10),
        Size = UDim2.new(1, -16, 1, -20),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new()
    })

    Create("UIListLayout", {
        Parent = TabHolder,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    local PageHolder = Create("Frame", {
        Parent = Body,
        Position = UDim2.fromOffset(150, 0),
        Size = UDim2.new(1, -150, 1, 0),
        BackgroundTransparency = 1
    })

    local NotificationHolder = Create("Frame", {
        Parent = ScreenGui,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -16, 1, -16),
        Size = UDim2.fromOffset(310, 400),
        BackgroundTransparency = 1
    })

    Create("UIListLayout", {
        Parent = NotificationHolder,
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    MakeDraggable(WindowFrame, TopBar)

    local Window = {
        ScreenGui = ScreenGui,
        Frame = WindowFrame,
        Tabs = {},
        SelectedTab = nil,
        Minimized = false,
        Visible = true
    }

    function Window:Notify(text, duration)
        local Notification = Create("Frame", {
            Parent = NotificationHolder,
            Size = UDim2.fromOffset(295, 58),
            BackgroundColor3 = Color3.fromRGB(25, 25, 31),
            BackgroundTransparency = 1,
            BorderSizePixel = 0
        })

        Create("UICorner", {
            Parent = Notification,
            CornerRadius = UDim.new(0, 10)
        })

        local stroke = Create("UIStroke", {
            Parent = Notification,
            Color = accent,
            Transparency = 1,
            Thickness = 1
        })

        local label = Create("TextLabel", {
            Parent = Notification,
            Position = UDim2.fromOffset(14, 0),
            Size = UDim2.new(1, -28, 1, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamMedium,
            Text = tostring(text),
            TextColor3 = Color3.fromRGB(240, 240, 246),
            TextTransparency = 1,
            TextSize = 13,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left
        })

        Tween(Notification, {
            BackgroundTransparency = 0
        })

        Tween(stroke, {
            Transparency = 0.3
        })

        Tween(label, {
            TextTransparency = 0
        })

        task.delay(duration or 3, function()
            if not Notification.Parent then
                return
            end

            Tween(Notification, {
                BackgroundTransparency = 1
            })

            Tween(stroke, {
                Transparency = 1
            })

            Tween(label, {
                TextTransparency = 1
            })

            task.wait(0.2)

            if Notification.Parent then
                Notification:Destroy()
            end
        end)
    end

    function Window:SetTitle(newTitle)
        TitleLabel.Text = tostring(newTitle)
    end

    function Window:SetSubtitle(newSubtitle)
        SubtitleLabel.Text = tostring(newSubtitle)
    end

    function Window:SetVisible(state)
        self.Visible = state == true
        ScreenGui.Enabled = self.Visible
    end

    function Window:Toggle()
        self:SetVisible(not self.Visible)
    end

    function Window:Destroy()
        ScreenGui:Destroy()
    end

    function Window:SelectTab(tab)
        if typeof(tab) == "string" then
            tab = self.Tabs[tab]
        end

        if not tab then
            return
        end

        for _, otherTab in pairs(self.Tabs) do
            otherTab.Page.Visible = false

            Tween(otherTab.Button, {
                BackgroundColor3 = Color3.fromRGB(27, 27, 34)
            })

            Tween(otherTab.Text, {
                TextColor3 = Color3.fromRGB(165, 165, 178)
            })

            Tween(otherTab.Indicator, {
                BackgroundTransparency = 1
            })
        end

        tab.Page.Visible = true

        Tween(tab.Button, {
            BackgroundColor3 = Color3.fromRGB(37, 37, 47)
        })

        Tween(tab.Text, {
            TextColor3 = Color3.fromRGB(245, 245, 250)
        })

        Tween(tab.Indicator, {
            BackgroundTransparency = 0
        })

        self.SelectedTab = tab.Name
    end

    function Window:CreateTab(name)
        name = tostring(name or "Tab")

        local TabButton = Create("TextButton", {
            Parent = TabHolder,
            Size = UDim2.new(1, 0, 0, 38),
            BackgroundColor3 = Color3.fromRGB(27, 27, 34),
            AutoButtonColor = false,
            Text = ""
        })

        Create("UICorner", {
            Parent = TabButton,
            CornerRadius = UDim.new(0, 8)
        })

        local Indicator = Create("Frame", {
            Parent = TabButton,
            Position = UDim2.new(0, 0, 0.5, -10),
            Size = UDim2.fromOffset(3, 20),
            BackgroundColor3 = accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0
        })

        Create("UICorner", {
            Parent = Indicator,
            CornerRadius = UDim.new(1, 0)
        })

        local TabText = Create("TextLabel", {
            Parent = TabButton,
            Position = UDim2.fromOffset(14, 0),
            Size = UDim2.new(1, -22, 1, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamMedium,
            Text = name,
            TextColor3 = Color3.fromRGB(165, 165, 178),
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left
        })

        local Page = Create("ScrollingFrame", {
            Parent = PageHolder,
            Position = UDim2.fromOffset(12, 12),
            Size = UDim2.new(1, -24, 1, -24),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Color3.fromRGB(90, 90, 105),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.new(),
            Visible = false
        })

        Create("UIListLayout", {
            Parent = Page,
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder
        })

        local Tab = {
            Name = name,
            Button = TabButton,
            Text = TabText,
            Indicator = Indicator,
            Page = Page
        }

        self.Tabs[name] = Tab

        TabButton.MouseButton1Click:Connect(function()
            self:SelectTab(Tab)
        end)

        TabButton.MouseEnter:Connect(function()
            if self.SelectedTab ~= name then
                Tween(TabButton, {
                    BackgroundColor3 = Color3.fromRGB(32, 32, 40)
                })
            end
        end)

        TabButton.MouseLeave:Connect(function()
            if self.SelectedTab ~= name then
                Tween(TabButton, {
                    BackgroundColor3 = Color3.fromRGB(27, 27, 34)
                })
            end
        end)

        function Tab:CreateSection(text)
            return Create("TextLabel", {
                Parent = Page,
                Size = UDim2.new(1, 0, 0, 27),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Text = string.upper(tostring(text or "Section")),
                TextColor3 = Color3.fromRGB(130, 130, 145),
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Bottom
            })
        end

        function Tab:CreateLabel(text)
            local Holder = Create("Frame", {
                Parent = Page,
                Size = UDim2.new(1, 0, 0, 42),
                BackgroundColor3 = Color3.fromRGB(25, 25, 31),
                BorderSizePixel = 0
            })

            Create("UICorner", {
                Parent = Holder,
                CornerRadius = UDim.new(0, 9)
            })

            Create("UIStroke", {
                Parent = Holder,
                Color = Color3.fromRGB(62, 62, 74),
                Transparency = 0.45
            })

            local Label = Create("TextLabel", {
                Parent = Holder,
                Position = UDim2.fromOffset(13, 0),
                Size = UDim2.new(1, -26, 1, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                Text = tostring(text or ""),
                TextColor3 = Color3.fromRGB(205, 205, 215),
                TextSize = 13,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local Object = {}

            function Object:Set(newText)
                Label.Text = tostring(newText)
            end

            return Object
        end

        function Tab:CreateButton(options)
            options = options or {}

            local name = options.Name or "Button"
            local description = options.Description or ""
            local callback = options.Callback

            local height = description ~= "" and 54 or 44

            local Button = Create("TextButton", {
                Parent = Page,
                Size = UDim2.new(1, 0, 0, height),
                BackgroundColor3 = Color3.fromRGB(27, 27, 34),
                AutoButtonColor = false,
                Text = ""
            })

            Create("UICorner", {
                Parent = Button,
                CornerRadius = UDim.new(0, 9)
            })

            Create("UIStroke", {
                Parent = Button,
                Color = Color3.fromRGB(62, 62, 74),
                Transparency = 0.4
            })

            local NameLabel = Create("TextLabel", {
                Parent = Button,
                Position = UDim2.fromOffset(13, description ~= "" and 7 or 0),
                Size = UDim2.new(1, -58, 0, description ~= "" and 22 or height),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamMedium,
                Text = tostring(name),
                TextColor3 = Color3.fromRGB(235, 235, 242),
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            if description ~= "" then
                Create("TextLabel", {
                    Parent = Button,
                    Position = UDim2.fromOffset(13, 27),
                    Size = UDim2.new(1, -58, 0, 18),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    Text = tostring(description),
                    TextColor3 = Color3.fromRGB(140, 140, 154),
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
            end

            local Arrow = Create("TextLabel", {
                Parent = Button,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -13, 0.5, 0),
                Size = UDim2.fromOffset(24, 24),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Text = "›",
                TextColor3 = accent,
                TextSize = 22
            })

            Button.MouseEnter:Connect(function()
                Tween(Button, {
                    BackgroundColor3 = Color3.fromRGB(35, 35, 44)
                })

                Tween(Arrow, {
                    Position = UDim2.new(1, -9, 0.5, 0)
                })
            end)

            Button.MouseLeave:Connect(function()
                Tween(Button, {
                    BackgroundColor3 = Color3.fromRGB(27, 27, 34)
                })

                Tween(Arrow, {
                    Position = UDim2.new(1, -13, 0.5, 0)
                })
            end)

            Button.MouseButton1Click:Connect(function()
                RunCallback(callback)
            end)

            local Object = {}

            function Object:SetName(newName)
                NameLabel.Text = tostring(newName)
            end

            function Object:Fire()
                RunCallback(callback)
            end

            function Object:SetCallback(newCallback)
                callback = newCallback
            end

            return Object
        end

        function Tab:CreateToggle(options)
            options = options or {}

            local name = options.Name or "Toggle"
            local description = options.Description or ""
            local callback = options.Callback
            local enabled = options.Default == true

            local height = description ~= "" and 58 or 46

            local ToggleButton = Create("TextButton", {
                Parent = Page,
                Size = UDim2.new(1, 0, 0, height),
                BackgroundColor3 = Color3.fromRGB(27, 27, 34),
                AutoButtonColor = false,
                Text = ""
            })

            Create("UICorner", {
                Parent = ToggleButton,
                CornerRadius = UDim.new(0, 9)
            })

            Create("UIStroke", {
                Parent = ToggleButton,
                Color = Color3.fromRGB(62, 62, 74),
                Transparency = 0.4
            })

            Create("TextLabel", {
                Parent = ToggleButton,
                Position = UDim2.fromOffset(13, description ~= "" and 8 or 0),
                Size = UDim2.new(1, -78, 0, description ~= "" and 22 or height),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamMedium,
                Text = tostring(name),
                TextColor3 = Color3.fromRGB(235, 235, 242),
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            if description ~= "" then
                Create("TextLabel", {
                    Parent = ToggleButton,
                    Position = UDim2.fromOffset(13, 29),
                    Size = UDim2.new(1, -78, 0, 18),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    Text = tostring(description),
                    TextColor3 = Color3.fromRGB(140, 140, 154),
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
            end

            local Track = Create("Frame", {
                Parent = ToggleButton,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -13, 0.5, 0),
                Size = UDim2.fromOffset(42, 23),
                BackgroundColor3 = enabled and accent or Color3.fromRGB(55, 55, 66),
                BorderSizePixel = 0
            })

            Create("UICorner", {
                Parent = Track,
                CornerRadius = UDim.new(1, 0)
            })

            local Knob = Create("Frame", {
                Parent = Track,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = enabled
                    and UDim2.new(1, -12, 0.5, 0)
                    or UDim2.new(0, 12, 0.5, 0),
                Size = UDim2.fromOffset(17, 17),
                BackgroundColor3 = Color3.fromRGB(245, 245, 250),
                BorderSizePixel = 0
            })

            Create("UICorner", {
                Parent = Knob,
                CornerRadius = UDim.new(1, 0)
            })

            local Object = {}

            function Object:Set(state, silent)
                enabled = state == true

                Tween(Track, {
                    BackgroundColor3 = enabled
                        and accent
                        or Color3.fromRGB(55, 55, 66)
                })

                Tween(Knob, {
                    Position = enabled
                        and UDim2.new(1, -12, 0.5, 0)
                        or UDim2.new(0, 12, 0.5, 0)
                })

                if not silent then
                    RunCallback(callback, enabled)
                end
            end

            function Object:Get()
                return enabled
            end

            function Object:Toggle()
                self:Set(not enabled)
            end

            function Object:SetCallback(newCallback)
                callback = newCallback
            end

            ToggleButton.MouseButton1Click:Connect(function()
                Object:Set(not enabled)
            end)

            if options.FireOnStart then
                RunCallback(callback, enabled)
            end

            return Object
        end

        function Tab:CreateSlider(options)
            options = options or {}

            local name = options.Name or "Slider"
            local minimum = tonumber(options.Min) or 0
            local maximum = tonumber(options.Max) or 100
            local increment = tonumber(options.Increment) or 1
            local callback = options.Callback

            if maximum <= minimum then
                maximum = minimum + 1
            end

            if increment <= 0 then
                increment = 1
            end

            local value = math.clamp(
                tonumber(options.Default) or minimum,
                minimum,
                maximum
            )

            local SliderFrame = Create("Frame", {
                Parent = Page,
                Size = UDim2.new(1, 0, 0, 65),
                BackgroundColor3 = Color3.fromRGB(27, 27, 34),
                BorderSizePixel = 0
            })

            Create("UICorner", {
                Parent = SliderFrame,
                CornerRadius = UDim.new(0, 9)
            })

            Create("UIStroke", {
                Parent = SliderFrame,
                Color = Color3.fromRGB(62, 62, 74),
                Transparency = 0.4
            })

            Create("TextLabel", {
                Parent = SliderFrame,
                Position = UDim2.fromOffset(13, 7),
                Size = UDim2.new(1, -88, 0, 23),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamMedium,
                Text = tostring(name),
                TextColor3 = Color3.fromRGB(235, 235, 242),
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local ValueLabel = Create("TextLabel", {
                Parent = SliderFrame,
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -13, 0, 7),
                Size = UDim2.fromOffset(65, 23),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Text = FormatNumber(value, increment),
                TextColor3 = accent,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Right
            })

            local Bar = Create("Frame", {
                Parent = SliderFrame,
                Position = UDim2.new(0, 13, 1, -22),
                Size = UDim2.new(1, -26, 0, 6),
                BackgroundColor3 = Color3.fromRGB(50, 50, 60),
                BorderSizePixel = 0
            })

            Create("UICorner", {
                Parent = Bar,
                CornerRadius = UDim.new(1, 0)
            })

            local startingPercentage = (value - minimum) / (maximum - minimum)

            local Fill = Create("Frame", {
                Parent = Bar,
                Size = UDim2.fromScale(startingPercentage, 1),
                BackgroundColor3 = accent,
                BorderSizePixel = 0
            })

            Create("UICorner", {
                Parent = Fill,
                CornerRadius = UDim.new(1, 0)
            })

            local Knob = Create("Frame", {
                Parent = Bar,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(startingPercentage, 0.5),
                Size = UDim2.fromOffset(15, 15),
                BackgroundColor3 = Color3.fromRGB(245, 245, 250),
                BorderSizePixel = 0,
                ZIndex = 3
            })

            Create("UICorner", {
                Parent = Knob,
                CornerRadius = UDim.new(1, 0)
            })

            local Hitbox = Create("TextButton", {
                Parent = SliderFrame,
                Position = UDim2.new(0, 9, 1, -34),
                Size = UDim2.new(1, -18, 0, 28),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = 4
            })

            local dragging = false
            local Object = {}

            function Object:Set(newValue, silent)
                newValue = tonumber(newValue) or minimum
                newValue = math.clamp(newValue, minimum, maximum)
                newValue = Round(newValue - minimum, increment) + minimum
                value = math.clamp(newValue, minimum, maximum)

                local percentage = (value - minimum) / (maximum - minimum)

                Tween(Fill, {
                    Size = UDim2.fromScale(percentage, 1)
                }, 0.1)

                Tween(Knob, {
                    Position = UDim2.fromScale(percentage, 0.5)
                }, 0.1)

                ValueLabel.Text = FormatNumber(value, increment)

                if not silent then
                    RunCallback(callback, value)
                end
            end

            function Object:Get()
                return value
            end

            function Object:SetCallback(newCallback)
                callback = newCallback
            end

            local function Update(inputPosition)
                if Bar.AbsoluteSize.X <= 0 then
                    return
                end

                local percentage = math.clamp(
                    (inputPosition.X - Bar.AbsolutePosition.X)
                    / Bar.AbsoluteSize.X,
                    0,
                    1
                )

                Object:Set(minimum + ((maximum - minimum) * percentage))
            end

            Hitbox.InputBegan:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.MouseButton1
                    and input.UserInputType ~= Enum.UserInputType.Touch then
                    return
                end

                dragging = true
                Update(input.Position)

                Tween(Knob, {
                    Size = UDim2.fromOffset(18, 18)
                }, 0.1)
            end)

            UserInputService.InputChanged:Connect(function(input)
                if not dragging then
                    return
                end

                if input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch then
                    Update(input.Position)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.MouseButton1
                    and input.UserInputType ~= Enum.UserInputType.Touch then
                    return
                end

                dragging = false

                Tween(Knob, {
                    Size = UDim2.fromOffset(15, 15)
                }, 0.1)
            end)

            if options.FireOnStart then
                RunCallback(callback, value)
            end

            return Object
        end

        function Tab:CreateTextbox(options)
            options = options or {}

            local name = options.Name or "Textbox"
            local placeholder = options.Placeholder or "Enter text..."
            local callback = options.Callback

            local Holder = Create("Frame", {
                Parent = Page,
                Size = UDim2.new(1, 0, 0, 72),
                BackgroundColor3 = Color3.fromRGB(27, 27, 34),
                BorderSizePixel = 0
            })

            Create("UICorner", {
                Parent = Holder,
                CornerRadius = UDim.new(0, 9)
            })

            Create("UIStroke", {
                Parent = Holder,
                Color = Color3.fromRGB(62, 62, 74),
                Transparency = 0.4
            })

            Create("TextLabel", {
                Parent = Holder,
                Position = UDim2.fromOffset(13, 5),
                Size = UDim2.new(1, -26, 0, 24),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamMedium,
                Text = tostring(name),
                TextColor3 = Color3.fromRGB(235, 235, 242),
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local InputHolder = Create("Frame", {
                Parent = Holder,
                Position = UDim2.fromOffset(11, 32),
                Size = UDim2.new(1, -22, 0, 29),
                BackgroundColor3 = Color3.fromRGB(20, 20, 26),
                BorderSizePixel = 0
            })

            Create("UICorner", {
                Parent = InputHolder,
                CornerRadius = UDim.new(0, 7)
            })

            local InputStroke = Create("UIStroke", {
                Parent = InputHolder,
                Color = Color3.fromRGB(65, 65, 78),
                Transparency = 0.45
            })

            local TextBox = Create("TextBox", {
                Parent = InputHolder,
                Position = UDim2.fromOffset(9, 0),
                Size = UDim2.new(1, -18, 1, 0),
                BackgroundTransparency = 1,
                ClearTextOnFocus = false,
                Font = Enum.Font.Gotham,
                PlaceholderText = tostring(placeholder),
                PlaceholderColor3 = Color3.fromRGB(100, 100, 114),
                Text = tostring(options.Default or ""),
                TextColor3 = Color3.fromRGB(225, 225, 232),
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            TextBox.Focused:Connect(function()
                Tween(InputStroke, {
                    Color = accent,
                    Transparency = 0.05
                })
            end)

            TextBox.FocusLost:Connect(function(enterPressed)
                Tween(InputStroke, {
                    Color = Color3.fromRGB(65, 65, 78),
                    Transparency = 0.45
                })

                RunCallback(callback, TextBox.Text, enterPressed)
            end)

            local Object = {}

            function Object:Set(text)
                TextBox.Text = tostring(text)
            end

            function Object:Get()
                return TextBox.Text
            end

            function Object:Clear()
                TextBox.Text = ""
            end

            function Object:SetCallback(newCallback)
                callback = newCallback
            end

            return Object
        end

        if not self.SelectedTab then
            self:SelectTab(Tab)
        end

        return Tab
    end

    MinimizeButton.MouseButton1Click:Connect(function()
        Window.Minimized = not Window.Minimized
        Body.Visible = not Window.Minimized
        SubtitleLabel.Visible = not Window.Minimized
        MinimizeButton.Text = Window.Minimized and "+" or "—"

        Tween(WindowFrame, {
            Size = Window.Minimized
                and UDim2.fromOffset(size.X, 52)
                or UDim2.fromOffset(size.X, size.Y)
        })
    end)

    CloseButton.MouseButton1Click:Connect(function()
        Window:Destroy()
    end)

    MinimizeButton.MouseEnter:Connect(function()
        Tween(MinimizeButton, {
            BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        })
    end)

    MinimizeButton.MouseLeave:Connect(function()
        Tween(MinimizeButton, {
            BackgroundColor3 = Color3.fromRGB(34, 34, 42)
        })
    end)

    CloseButton.MouseEnter:Connect(function()
        Tween(CloseButton, {
            BackgroundColor3 = Color3.fromRGB(185, 55, 70)
        })
    end)

    CloseButton.MouseLeave:Connect(function()
        Tween(CloseButton, {
            BackgroundColor3 = Color3.fromRGB(34, 34, 42)
        })
    end)

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end

        if input.KeyCode == toggleKey then
            Window:Toggle()
        end
    end)

    return Window
end

return Library
