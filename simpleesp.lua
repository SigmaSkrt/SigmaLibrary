local Environment = getgenv and getgenv() or _G

if Environment.SimpleESPUnload then
	pcall(Environment.SimpleESPUnload)
end

local UI = (function()
--[[
	UILibrary
	A self-contained dark UI library for Roblox. Place this ModuleScript
	anywhere a LocalScript can reach it (ReplicatedStorage is typical).

	Quick start:
		local UI = require(path.to.UILibrary)
		local Window = UI.new({ Title = "My Menu" })
		local Tab = Window:AddTab("Main")
		Tab:AddToggle("Enable", false, function(on) print(on) end)

	Works with mouse and touch. Press Right Shift on PC to show/hide.
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local UIParent = LocalPlayer:WaitForChild("PlayerGui")
if gethui then
	local ok, result = pcall(gethui)
	if ok and result then
		UIParent = result
	end
end

----------------------------------------------------------------------
-- THEME  (change these to restyle everything)
----------------------------------------------------------------------

local Theme = {
	Ink = Color3.fromRGB(18, 19, 22),
	Panel = Color3.fromRGB(26, 28, 32),
	Raised = Color3.fromRGB(35, 38, 43),
	Line = Color3.fromRGB(46, 50, 56),
	Text = Color3.fromRGB(226, 229, 234),
	Muted = Color3.fromRGB(139, 146, 156),
	Accent = Color3.fromRGB(217, 164, 65),
	AccentText = Color3.fromRGB(18, 19, 22),
}

local Speed = 0.18
local Ease = Enum.EasingStyle.Quad
local Dir = Enum.EasingDirection.Out

----------------------------------------------------------------------
-- UTILITIES
----------------------------------------------------------------------

local function New(class, props, parent)
	local obj = Instance.new(class)
	for key, value in pairs(props or {}) do
		obj[key] = value
	end
	obj.Parent = parent
	return obj
end

local function Corner(obj, radius)
	return New("UICorner", { CornerRadius = UDim.new(0, radius or 6) }, obj)
end

local function Stroke(obj, color, thickness)
	return New("UIStroke", {
		Color = color or Theme.Line,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, obj)
end

local function Pad(obj, top, bottom, left, right)
	return New("UIPadding", {
		PaddingTop = UDim.new(0, top or 0),
		PaddingBottom = UDim.new(0, bottom or 0),
		PaddingLeft = UDim.new(0, left or 0),
		PaddingRight = UDim.new(0, right or 0),
	}, obj)
end

local function Tween(obj, props, duration)
	local tween = TweenService:Create(obj, TweenInfo.new(duration or Speed, Ease, Dir), props)
	tween:Play()
	return tween
end

local function IsTouch()
	return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end

local function Round(value, decimals)
	local mult = 10 ^ (decimals or 0)
	return math.floor(value * mult + 0.5) / mult
end

local function ToHex(color)
	return string.format("#%02X%02X%02X",
		math.floor(color.R * 255 + 0.5),
		math.floor(color.G * 255 + 0.5),
		math.floor(color.B * 255 + 0.5))
end

----------------------------------------------------------------------
-- LIBRARY
----------------------------------------------------------------------

local Library = {}
Library.__index = Library

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

function Library.new(config)
	config = config or {}

	local self = setmetatable({}, Window)

	self.Title = config.Title or "Menu"
	self.Keybind = config.Keybind or Enum.KeyCode.RightShift
	self.Accent = config.Accent or Theme.Accent
	self.Connections = {}
	self.Tabs = {}
	self.AccentParts = {}
	self.Visible = true
	self.ActiveTab = nil

	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)

	local width = math.clamp(math.floor(viewport.X * 0.5), 300, 580)
	local height = math.clamp(math.floor(viewport.Y * 0.62), 250, 420)
	local sidebar = width < 380 and 92 or 124

	self.SidebarWidth = sidebar

	----------------------------------------------------------------
	-- Root
	----------------------------------------------------------------

	local gui = New("ScreenGui", {
		Name = "SimpleESP_NewUI",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 100,
	}, UIParent)

	self.Gui = gui

	local root = New("Frame", {
		Name = "Window",
		Size = UDim2.fromOffset(width, height),
		Position = UDim2.fromOffset(
			math.floor((viewport.X - width) / 2),
			math.floor((viewport.Y - height) / 2)
		),
		BackgroundColor3 = Theme.Ink,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, gui)
	Corner(root, 10)
	Stroke(root, Theme.Line)

	self.Root = root

	----------------------------------------------------------------
	-- Topbar
	----------------------------------------------------------------

	local topbar = New("Frame", {
		Name = "Topbar",
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
	}, root)

	New("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -1),
		BackgroundColor3 = Theme.Line,
		BorderSizePixel = 0,
	}, topbar)

	local titleDot = New("Frame", {
		Size = UDim2.fromOffset(6, 6),
		Position = UDim2.new(0, 14, 0.5, -3),
		BackgroundColor3 = self.Accent,
		BorderSizePixel = 0,
	}, topbar)
	Corner(titleDot, 3)
	table.insert(self.AccentParts, { Object = titleDot, Property = "BackgroundColor3" })

	New("TextLabel", {
		Size = UDim2.new(1, -120, 1, 0),
		Position = UDim2.fromOffset(28, 0),
		BackgroundTransparency = 1,
		Text = self.Title,
		TextColor3 = Theme.Text,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, topbar)

	local function TopButton(symbol, offset)
		local button = New("TextButton", {
			Size = UDim2.fromOffset(26, 26),
			Position = UDim2.new(1, offset, 0.5, -13),
			BackgroundColor3 = Theme.Raised,
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Text = symbol,
			TextColor3 = Theme.Muted,
			TextSize = 15,
			Font = Enum.Font.GothamBold,
			BorderSizePixel = 0,
		}, topbar)
		Corner(button, 6)

		button.MouseEnter:Connect(function()
			Tween(button, { BackgroundTransparency = 0, TextColor3 = Theme.Text }, 0.12)
		end)
		button.MouseLeave:Connect(function()
			Tween(button, { BackgroundTransparency = 1, TextColor3 = Theme.Muted }, 0.12)
		end)

		return button
	end

	local closeButton = TopButton("×", -34)
	local minButton = TopButton("–", -66)

	----------------------------------------------------------------
	-- Sidebar
	----------------------------------------------------------------

	local sidebarFrame = New("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, sidebar, 1, -40),
		Position = UDim2.fromOffset(0, 40),
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
	}, root)

	New("Frame", {
		Size = UDim2.new(0, 1, 1, 0),
		Position = UDim2.new(1, -1, 0, 0),
		BackgroundColor3 = Theme.Line,
		BorderSizePixel = 0,
	}, sidebarFrame)

	local tabList = New("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, sidebarFrame)
	Pad(tabList, 10, 10, 0, 0)

	New("UIListLayout", {
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, tabList)

	self.TabList = tabList

	-- The sliding brass rail. This is the one flourish.
	local rail = New("Frame", {
		Name = "Rail",
		Size = UDim2.fromOffset(3, 16),
		Position = UDim2.fromOffset(0, 10),
		BackgroundColor3 = self.Accent,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 3,
	}, sidebarFrame)
	Corner(rail, 2)
	table.insert(self.AccentParts, { Object = rail, Property = "BackgroundColor3" })

	self.Rail = rail

	----------------------------------------------------------------
	-- Content
	----------------------------------------------------------------

	local content = New("Frame", {
		Name = "Content",
		Size = UDim2.new(1, -sidebar, 1, -40),
		Position = UDim2.fromOffset(sidebar, 40),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
	}, root)

	self.Content = content

	----------------------------------------------------------------
	-- Restore pill (shown when hidden)
	----------------------------------------------------------------

	local restore = New("TextButton", {
		Name = "Restore",
		Size = UDim2.fromOffset(46, 46),
		Position = UDim2.fromOffset(18, math.floor(viewport.Y / 2) - 23),
		BackgroundColor3 = Theme.Panel,
		AutoButtonColor = false,
		Text = "",
		BorderSizePixel = 0,
		Visible = false,
	}, gui)
	Corner(restore, 23)
	Stroke(restore, Theme.Line)

	local restoreDot = New("Frame", {
		Size = UDim2.fromOffset(10, 10),
		Position = UDim2.new(0.5, -5, 0.5, -5),
		BackgroundColor3 = self.Accent,
		BorderSizePixel = 0,
	}, restore)
	Corner(restoreDot, 5)
	table.insert(self.AccentParts, { Object = restoreDot, Property = "BackgroundColor3" })

	self.Restore = restore

	----------------------------------------------------------------
	-- Behaviour
	----------------------------------------------------------------

	self:_MakeDraggable(root, topbar)
	self:_MakeDraggable(restore, restore, function()
		self:Show()
	end)

	closeButton.Activated:Connect(function()
		self:Hide()
	end)

	minButton.Activated:Connect(function()
		self:Hide()
	end)

	table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == self.Keybind then
			self:Toggle()
		end
	end))

	table.insert(self.Connections, RunService.Heartbeat:Connect(function()
		local cam = workspace.CurrentCamera
		if not cam then return end
		if cam.ViewportSize ~= viewport then
			viewport = cam.ViewportSize
			root.Position = self:_Clamp(root, root.Position)
			restore.Position = self:_Clamp(restore, restore.Position)
		end
	end))

	-- Open animation
	root.Size = UDim2.fromOffset(math.floor(width * 0.98), math.floor(height * 0.98))
	Tween(root, { Size = UDim2.fromOffset(width, height) }, 0.22)

	self.Width = width
	self.Height = height

	return self
end

----------------------------------------------------------------------
-- WINDOW: internal helpers
----------------------------------------------------------------------

function Window:_Clamp(frame, position)
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
	local size = frame.AbsoluteSize

	if size.X <= 0 or size.Y <= 0 then
		size = Vector2.new(frame.Size.X.Offset, frame.Size.Y.Offset)
	end

	local margin = 8
	local x = position.X.Scale * viewport.X + position.X.Offset
	local y = position.Y.Scale * viewport.Y + position.Y.Offset

	x = math.clamp(x, margin, math.max(margin, viewport.X - size.X - margin))
	y = math.clamp(y, margin, math.max(margin, viewport.Y - size.Y - margin))

	return UDim2.fromOffset(math.floor(x), math.floor(y))
end

function Window:_MakeDraggable(frame, handle, onTap)
	local dragging = false
	local activeInput, startPos, startFramePos
	local moved = false

	handle.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		dragging = true
		moved = false
		activeInput = input
		startPos = input.Position
		startFramePos = frame.Position
	end)

	table.insert(self.Connections, UserInputService.InputChanged:Connect(function(input)
		if not dragging or not startPos then return end

		local matches = (activeInput and input == activeInput)
			or (input.UserInputType == Enum.UserInputType.MouseMovement
				and activeInput
				and activeInput.UserInputType == Enum.UserInputType.MouseButton1)

		if not matches then return end

		local delta = input.Position - startPos
		if delta.Magnitude >= 6 then
			moved = true
		end

		frame.Position = UDim2.fromOffset(
			startFramePos.X.Offset + delta.X,
			startFramePos.Y.Offset + delta.Y
		)
	end))

	table.insert(self.Connections, UserInputService.InputEnded:Connect(function(input)
		if not dragging then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		dragging = false
		activeInput = nil
		frame.Position = self:_Clamp(frame, frame.Position)

		if not moved and onTap then
			onTap()
		end
	end))
end

function Window:_MoveRail(button)
	local rail = self.Rail

	-- UIListLayout owns the button's Position, so measure in absolute space
	-- and convert back to a sidebar-relative offset.
	local function target()
		local offset = button.AbsolutePosition.Y - self.Rail.Parent.AbsolutePosition.Y
		return math.floor(offset + (button.AbsoluteSize.Y - 16) / 2)
	end

	if not rail.Visible then
		task.defer(function()
			rail.Visible = true
			rail.Position = UDim2.fromOffset(0, target())
		end)
	else
		Tween(rail, { Position = UDim2.fromOffset(0, target()) }, 0.2)
	end
end

----------------------------------------------------------------------
-- WINDOW: public
----------------------------------------------------------------------

function Window:Show()
	self.Visible = true
	self.Root.Visible = true
	self.Restore.Visible = false
	self.Root.Position = self:_Clamp(self.Root, self.Root.Position)

	self.Root.Size = UDim2.fromOffset(
		math.floor(self.Width * 0.98),
		math.floor(self.Height * 0.98)
	)
	Tween(self.Root, { Size = UDim2.fromOffset(self.Width, self.Height) }, 0.2)
end

function Window:Hide()
	self.Visible = false
	self.Restore.Position = self:_Clamp(self.Restore, self.Root.Position)

	local tween = Tween(self.Root, {
		Size = UDim2.fromOffset(math.floor(self.Width * 0.97), math.floor(self.Height * 0.97)),
	}, 0.14)

	tween.Completed:Connect(function()
		if not self.Visible then
			self.Root.Visible = false
			self.Restore.Visible = true
		end
	end)
end

function Window:Toggle()
	if self.Visible then
		self:Hide()
	else
		self:Show()
	end
end

function Window:SetAccent(color)
	self.Accent = color
	for _, entry in ipairs(self.AccentParts) do
		if entry.Object and entry.Object.Parent then
			if not entry.OnlyWhen or entry.OnlyWhen() then
				entry.Object[entry.Property] = color
			end
		end
	end
end

function Window:Destroy()
	for _, connection in ipairs(self.Connections) do
		pcall(function()
			connection:Disconnect()
		end)
	end
	self.Connections = {}

	if self.Gui then
		self.Gui:Destroy()
	end
end

function Window:AddTab(name)
	local tab = setmetatable({}, Tab)
	tab.Window = self
	tab.Name = name

	local index = #self.Tabs
	local buttonHeight = 30

	local button = New("TextButton", {
		Name = name,
		Size = UDim2.new(1, -12, 0, buttonHeight),
		Position = UDim2.fromOffset(0, index * (buttonHeight + 2)),
		BackgroundColor3 = Theme.Raised,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = name,
		TextColor3 = Theme.Muted,
		TextSize = 12,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		BorderSizePixel = 0,
		LayoutOrder = index,
	}, self.TabList)
	Corner(button, 6)
	Pad(button, 0, 0, 12, 0)

	local page = New("ScrollingFrame", {
		Name = name .. "Page",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.Line,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Visible = false,
	}, self.Content)
	Pad(page, 14, 16, 14, 12)

	New("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, page)

	tab.Button = button
	tab.Page = page
	tab.Order = 0

	button.MouseEnter:Connect(function()
		if self.ActiveTab ~= tab then
			Tween(button, { TextColor3 = Theme.Text }, 0.12)
		end
	end)

	button.MouseLeave:Connect(function()
		if self.ActiveTab ~= tab then
			Tween(button, { TextColor3 = Theme.Muted }, 0.12)
		end
	end)

	button.Activated:Connect(function()
		self:SelectTab(tab)
	end)

	table.insert(self.Tabs, tab)

	if not self.ActiveTab then
		self:SelectTab(tab)
	end

	return tab
end

function Window:SelectTab(tab)
	if self.ActiveTab == tab then return end

	if self.ActiveTab then
		local old = self.ActiveTab
		old.Page.Visible = false
		Tween(old.Button, { BackgroundTransparency = 1, TextColor3 = Theme.Muted }, 0.15)
	end

	self.ActiveTab = tab

	Tween(tab.Button, { BackgroundTransparency = 0, TextColor3 = Theme.Text }, 0.15)
	self:_MoveRail(tab.Button)

	tab.Page.Visible = true
	tab.Page.Position = UDim2.fromOffset(0, 8)
	Tween(tab.Page, { Position = UDim2.fromOffset(0, 0) }, 0.2)
end

----------------------------------------------------------------------
-- TAB: shared row scaffolding
----------------------------------------------------------------------

function Tab:_NextOrder()
	self.Order = self.Order + 1
	return self.Order
end

function Tab:_Row(height, clip)
	local row = New("Frame", {
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
		ClipsDescendants = clip or false,
		LayoutOrder = self:_NextOrder(),
	}, self.Page)
	Corner(row, 8)
	Stroke(row, Theme.Line)
	return row
end

function Tab:_Label(parent, text, width)
	return New("TextLabel", {
		Size = UDim2.new(0, width or 160, 0, 38),
		Position = UDim2.fromOffset(12, 0),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = Theme.Text,
		TextSize = 13,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, parent)
end

----------------------------------------------------------------------
-- TAB: controls
----------------------------------------------------------------------

function Tab:AddSection(text)
	local holder = New("Frame", {
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		LayoutOrder = self:_NextOrder(),
	}, self.Page)

	local label = New("TextLabel", {
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Text = string.upper(text),
		TextColor3 = Theme.Muted,
		TextSize = 10,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Bottom,
	}, holder)

	local rule = New("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -5),
		BackgroundColor3 = Theme.Line,
		BorderSizePixel = 0,
	}, holder)

	label:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		rule.Size = UDim2.new(1, -(label.AbsoluteSize.X + 10), 0, 1)
		rule.Position = UDim2.new(0, label.AbsoluteSize.X + 10, 1, -5)
	end)

	task.defer(function()
		rule.Size = UDim2.new(1, -(label.AbsoluteSize.X + 10), 0, 1)
		rule.Position = UDim2.new(0, label.AbsoluteSize.X + 10, 1, -5)
	end)

	return holder
end

function Tab:AddLabel(text)
	local row = self:_Row(34)
	New("TextLabel", {
		Size = UDim2.new(1, -24, 1, 0),
		Position = UDim2.fromOffset(12, 0),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = Theme.Muted,
		TextSize = 12,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
	}, row)
	return row
end

function Tab:AddButton(text, callback)
	local row = self:_Row(38)
	row.BackgroundColor3 = Theme.Raised

	local button = New("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = text,
		TextColor3 = Theme.Text,
		TextSize = 13,
		Font = Enum.Font.GothamMedium,
	}, row)

	button.MouseEnter:Connect(function()
		Tween(row, { BackgroundColor3 = Theme.Line }, 0.12)
	end)
	button.MouseLeave:Connect(function()
		Tween(row, { BackgroundColor3 = Theme.Raised }, 0.12)
	end)

	button.Activated:Connect(function()
		-- brief press-in, then settle
		Tween(row, { Size = UDim2.new(1, -4, 0, 36) }, 0.07).Completed:Connect(function()
			Tween(row, { Size = UDim2.new(1, 0, 0, 38) }, 0.12)
		end)
		if callback then
			task.spawn(callback)
		end
	end)

	return row
end

function Tab:AddToggle(text, default, callback)
	local window = self.Window
	local row = self:_Row(38)
	self:_Label(row, text, 180)

	local state = default and true or false

	local track = New("TextButton", {
		Size = UDim2.fromOffset(38, 20),
		Position = UDim2.new(1, -50, 0.5, -10),
		BackgroundColor3 = state and window.Accent or Theme.Raised,
		AutoButtonColor = false,
		Text = "",
		BorderSizePixel = 0,
	}, row)
	Corner(track, 10)

	local knob = New("Frame", {
		Size = UDim2.fromOffset(14, 14),
		Position = state and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3),
		BackgroundColor3 = state and Theme.AccentText or Theme.Muted,
		BorderSizePixel = 0,
	}, track)
	Corner(knob, 7)

	local hit = New("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
	}, row)

	local control = {}

	function control:Set(value, silent)
		state = value and true or false

		Tween(track, {
			BackgroundColor3 = state and window.Accent or Theme.Raised,
		}, 0.16)

		Tween(knob, {
			Position = state and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3),
			BackgroundColor3 = state and Theme.AccentText or Theme.Muted,
		}, 0.16)

		if callback and not silent then
			task.spawn(callback, state)
		end
	end

	function control:Get()
		return state
	end

	local function flip()
		control:Set(not state)
	end

	hit.Activated:Connect(flip)
	track.Activated:Connect(flip)

	table.insert(window.AccentParts, {
		Object = track,
		Property = "BackgroundColor3",
		OnlyWhen = function() return state end,
	})

	return control
end

function Tab:AddSlider(text, options, callback)
	options = options or {}
	local min = options.Min or 0
	local max = options.Max or 100
	local decimals = options.Decimals or 0
	local suffix = options.Suffix or ""
	local value = math.clamp(options.Default or min, min, max)

	local row = self:_Row(52)
	self:_Label(row, text, 160).Size = UDim2.new(0, 160, 0, 30)

	local readout = New("TextLabel", {
		Size = UDim2.new(0, 70, 0, 30),
		Position = UDim2.new(1, -82, 0, 0),
		BackgroundTransparency = 1,
		Text = Round(value, decimals) .. suffix,
		TextColor3 = Theme.Muted,
		TextSize = 12,
		Font = Enum.Font.Code,
		TextXAlignment = Enum.TextXAlignment.Right,
	}, row)

	local track = New("Frame", {
		Size = UDim2.new(1, -24, 0, 4),
		Position = UDim2.new(0, 12, 0, 34),
		BackgroundColor3 = Theme.Raised,
		BorderSizePixel = 0,
	}, row)
	Corner(track, 2)

	local fill = New("Frame", {
		Size = UDim2.fromScale((value - min) / (max - min), 1),
		BackgroundColor3 = self.Window.Accent,
		BorderSizePixel = 0,
	}, track)
	Corner(fill, 2)
	table.insert(self.Window.AccentParts, { Object = fill, Property = "BackgroundColor3" })

	local knob = New("Frame", {
		Size = UDim2.fromOffset(12, 12),
		Position = UDim2.new((value - min) / (max - min), -6, 0.5, -6),
		BackgroundColor3 = Theme.Text,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, track)
	Corner(knob, 6)

	local hit = New("TextButton", {
		Size = UDim2.new(1, -24, 0, 26),
		Position = UDim2.new(0, 12, 0, 23),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
	}, row)

	local control = {}
	local dragging = false

	function control:Set(newValue, silent, instant)
		value = math.clamp(newValue, min, max)
		local alpha = (value - min) / (max - min)
		local duration = instant and 0 or 0.1

		if instant then
			fill.Size = UDim2.fromScale(alpha, 1)
			knob.Position = UDim2.new(alpha, -6, 0.5, -6)
		else
			Tween(fill, { Size = UDim2.fromScale(alpha, 1) }, duration)
			Tween(knob, { Position = UDim2.new(alpha, -6, 0.5, -6) }, duration)
		end

		readout.Text = Round(value, decimals) .. suffix

		if callback and not silent then
			task.spawn(callback, Round(value, decimals))
		end
	end

	function control:Get()
		return Round(value, decimals)
	end

	local function updateFromInput(input)
		local alpha = math.clamp(
			(input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1),
			0, 1
		)
		control:Set(min + (max - min) * alpha, false, true)
	end

	hit.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		dragging = true
		Tween(knob, { Size = UDim2.fromOffset(14, 14), Position = UDim2.new(
			(value - min) / (max - min), -7, 0.5, -7) }, 0.1)
		updateFromInput(input)
	end)

	table.insert(self.Window.Connections, UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			updateFromInput(input)
		end
	end))

	table.insert(self.Window.Connections, UserInputService.InputEnded:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
			local alpha = (value - min) / (max - min)
			Tween(knob, {
				Size = UDim2.fromOffset(12, 12),
				Position = UDim2.new(alpha, -6, 0.5, -6),
			}, 0.12)
		end
	end))

	return control
end

function Tab:AddDropdown(text, items, default, callback)
	items = items or {}

	local rowHeight = 38
	local itemHeight = 28
	local row = self:_Row(rowHeight, true)

	self:_Label(row, text, 140)

	local selected = default or items[1] or ""
	local open = false

	local valueLabel = New("TextLabel", {
		Size = UDim2.new(0, 112, 0, rowHeight),
		Position = UDim2.new(1, -158, 0, 0),
		BackgroundTransparency = 1,
		Text = tostring(selected),
		TextColor3 = Theme.Muted,
		TextSize = 12,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, row)

	local arrow = New("Frame", {
		Size = UDim2.fromOffset(16, 16),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -20, 0, math.floor(rowHeight / 2)),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Rotation = 0,
	}, row)

	local arrowLeft = New("Frame", {
		Size = UDim2.fromOffset(8, 2),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(5, 7),
		BackgroundColor3 = Theme.Muted,
		BorderSizePixel = 0,
		Rotation = 45,
	}, arrow)
	Corner(arrowLeft, 1)

	local arrowRight = New("Frame", {
		Size = UDim2.fromOffset(8, 2),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(11, 7),
		BackgroundColor3 = Theme.Muted,
		BorderSizePixel = 0,
		Rotation = -45,
	}, arrow)
	Corner(arrowRight, 1)

	local header = New("TextButton", {
		Size = UDim2.new(1, 0, 0, rowHeight),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
	}, row)

	local list = New("Frame", {
		Size = UDim2.new(1, -16, 0, 0),
		Position = UDim2.fromOffset(8, rowHeight),
		BackgroundTransparency = 1,
	}, row)

	New("UIListLayout", {
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, list)

	local control = {}
	local buttons = {}

	local function refresh()
		valueLabel.Text = tostring(selected)
		for value, button in pairs(buttons) do
			local active = value == selected
			Tween(button, {
				TextColor3 = active and Theme.Text or Theme.Muted,
				BackgroundTransparency = active and 0 or 1,
			}, 0.12)
		end
	end

	function control:Set(value, silent)
		selected = value
		refresh()
		if callback and not silent then
			task.spawn(callback, value)
		end
	end

	function control:Get()
		return selected
	end

	local function setOpen(state)
		open = state
		local listHeight = #items * (itemHeight + 2) + 6
		Tween(row, {
			Size = UDim2.new(1, 0, 0, state and (rowHeight + listHeight) or rowHeight),
		}, 0.2)
		Tween(arrow, { Rotation = state and 180 or 0 }, 0.2)
	end

	function control:SetItems(newItems)
		items = newItems
		for _, button in pairs(buttons) do
			button:Destroy()
		end
		buttons = {}
		control:_Build()
		if open then setOpen(true) end
	end

	function control:_Build()
		for index, item in ipairs(items) do
			local button = New("TextButton", {
				Size = UDim2.new(1, 0, 0, itemHeight),
				BackgroundColor3 = Theme.Raised,
				BackgroundTransparency = 1,
				AutoButtonColor = false,
				Text = tostring(item),
				TextColor3 = Theme.Muted,
				TextSize = 12,
				Font = Enum.Font.Gotham,
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = index,
				BorderSizePixel = 0,
			}, list)
			Corner(button, 5)
			Pad(button, 0, 0, 10, 0)

			button.Activated:Connect(function()
				control:Set(item)
				setOpen(false)
			end)

			buttons[item] = button
		end
		refresh()
	end

	control:_Build()

	header.Activated:Connect(function()
		setOpen(not open)
	end)

	return control
end

function Tab:AddTextbox(text, placeholder, callback)
	local row = self:_Row(38)
	self:_Label(row, text, 120)

	local field = New("TextBox", {
		Size = UDim2.new(0, 150, 0, 26),
		Position = UDim2.new(1, -162, 0.5, -13),
		BackgroundColor3 = Theme.Raised,
		Text = "",
		PlaceholderText = placeholder or "",
		PlaceholderColor3 = Theme.Muted,
		TextColor3 = Theme.Text,
		TextSize = 12,
		Font = Enum.Font.Gotham,
		ClearTextOnFocus = false,
		BorderSizePixel = 0,
	}, row)
	Corner(field, 6)
	Pad(field, 0, 0, 8, 8)

	local stroke = Stroke(field, Theme.Line)

	field.Focused:Connect(function()
		Tween(stroke, { Color = self.Window.Accent }, 0.14)
	end)

	field.FocusLost:Connect(function(enterPressed)
		Tween(stroke, { Color = Theme.Line }, 0.14)
		if callback then
			task.spawn(callback, field.Text, enterPressed)
		end
	end)

	local control = {}

	function control:Set(value)
		field.Text = value
	end

	function control:Get()
		return field.Text
	end

	return control
end

function Tab:AddColorPicker(text, default, callback)
	local rowHeight = 38
	local panelHeight = 148

	local row = self:_Row(rowHeight, true)
	self:_Label(row, text, 140)

	local color = default or Color3.fromRGB(217, 164, 65)
	local hue, saturation, brightness = Color3.toHSV(color)
	local open = false

	local swatch = New("Frame", {
		Size = UDim2.fromOffset(30, 18),
		Position = UDim2.new(1, -44, 0, 10),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
	}, row)
	Corner(swatch, 5)
	Stroke(swatch, Theme.Line)

	local header = New("TextButton", {
		Size = UDim2.new(1, 0, 0, rowHeight),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
	}, row)

	-- Saturation / brightness field
	local field = New("Frame", {
		Size = UDim2.new(1, -70, 0, 100),
		Position = UDim2.fromOffset(12, rowHeight + 4),
		BackgroundColor3 = Color3.fromHSV(hue, 1, 1),
		BorderSizePixel = 0,
	}, row)
	Corner(field, 6)
	Stroke(field, Theme.Line)

	local whiteLayer = New("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
	}, field)
	Corner(whiteLayer, 6)
	New("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
	}, whiteLayer)

	local blackLayer = New("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
	}, field)
	Corner(blackLayer, 6)
	New("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0),
		}),
	}, blackLayer)

	local cursor = New("Frame", {
		Size = UDim2.fromOffset(10, 10),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(saturation, 1 - brightness),
		BackgroundTransparency = 1,
		ZIndex = 3,
	}, field)
	Corner(cursor, 5)
	Stroke(cursor, Color3.new(1, 1, 1), 2)

	-- Hue strip
	local hueBar = New("Frame", {
		Size = UDim2.fromOffset(16, 100),
		Position = UDim2.new(1, -46, 0, rowHeight + 4),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
	}, row)
	Corner(hueBar, 6)
	Stroke(hueBar, Theme.Line)

	New("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
			ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
			ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
			ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
		}),
	}, hueBar)

	local hueCursor = New("Frame", {
		Size = UDim2.new(1, 6, 0, 3),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, hue, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 3,
	}, hueBar)
	Corner(hueCursor, 2)

	local hexLabel = New("TextLabel", {
		Size = UDim2.new(1, -24, 0, 18),
		Position = UDim2.fromOffset(12, rowHeight + 110),
		BackgroundTransparency = 1,
		Text = ToHex(color),
		TextColor3 = Theme.Muted,
		TextSize = 11,
		Font = Enum.Font.Code,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)

	local control = {}

	local function apply(silent)
		color = Color3.fromHSV(hue, saturation, brightness)
		swatch.BackgroundColor3 = color
		field.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
		cursor.Position = UDim2.fromScale(saturation, 1 - brightness)
		hueCursor.Position = UDim2.new(0.5, 0, hue, 0)
		hexLabel.Text = ToHex(color)

		if callback and not silent then
			task.spawn(callback, color)
		end
	end

	function control:Set(newColor, silent)
		hue, saturation, brightness = Color3.toHSV(newColor)
		apply(silent)
	end

	function control:Get()
		return color
	end

	local draggingField = false
	local draggingHue = false

	local function updateField(input)
		saturation = math.clamp(
			(input.Position.X - field.AbsolutePosition.X) / math.max(field.AbsoluteSize.X, 1), 0, 1)
		brightness = 1 - math.clamp(
			(input.Position.Y - field.AbsolutePosition.Y) / math.max(field.AbsoluteSize.Y, 1), 0, 1)
		apply()
	end

	local function updateHue(input)
		hue = math.clamp(
			(input.Position.Y - hueBar.AbsolutePosition.Y) / math.max(hueBar.AbsoluteSize.Y, 1), 0, 1)
		apply()
	end

	field.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			draggingField = true
			updateField(input)
		end
	end)

	hueBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			draggingHue = true
			updateHue(input)
		end
	end)

	table.insert(self.Window.Connections, UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		if draggingField then updateField(input) end
		if draggingHue then updateHue(input) end
	end))

	table.insert(self.Window.Connections, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			draggingField = false
			draggingHue = false
		end
	end))

	header.Activated:Connect(function()
		open = not open
		Tween(row, {
			Size = UDim2.new(1, 0, 0, open and (rowHeight + panelHeight) or rowHeight),
		}, 0.22)
	end)

	return control
end

----------------------------------------------------------------------

Library.Theme = Theme

return Library

end)()


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local EngineConnections = {}
local Visuals = {}
local Running = true

local UIParent = LocalPlayer:WaitForChild("PlayerGui")
if gethui then
	local ok, result = pcall(gethui)
	if ok and result then
		UIParent = result
	end
end

for _, parent in ipairs({UIParent, LocalPlayer:FindFirstChild("PlayerGui"), CoreGui}) do
	if parent then
		for _, name in ipairs({"SimpleESP_GUI", "SimpleESP_Highlights", "SimpleESP_NewUI"}) do
			local old = parent:FindFirstChild(name)
			if old then
				pcall(function()
					old:Destroy()
				end)
			end
		end
	end
end

local DefaultColor = Color3.fromRGB(255, 85, 95)
local DefaultAccent = Color3.fromRGB(217, 164, 65)

local Settings = {
	Enabled = true,
	Box = true,
	Skeleton = false,
	Tracers = false,
	Chams = false,
	Names = true,
	Distance = true,
	Health = true,
	SelfESP = false,
	TeamCheck = false,
	Rainbow = false,
	ESPColor = DefaultColor,
	MaxDistance = 2500,
	BoxThickness = 1.5,
	SkeletonThickness = 1.5,
	TracerThickness = 1.5,
	RainbowSpeed = 5,
	TracerOrigin = "Bottom"
}

local LastManualColor = DefaultColor

local HighlightFolder = Instance.new("Folder")
HighlightFolder.Name = "SimpleESP_Highlights"
HighlightFolder.Parent = UIParent

local function NewDrawing(kind, properties)
	local object = Drawing.new(kind)
	for property, value in pairs(properties) do
		object[property] = value
	end
	return object
end

local function CreateVisuals(player)
	if Visuals[player] then
		return Visuals[player]
	end

	local data = {
		Box = NewDrawing("Square", {
			Visible = false,
			Filled = false,
			Thickness = Settings.BoxThickness,
			Transparency = 1
		}),
		BoxOutline = NewDrawing("Square", {
			Visible = false,
			Filled = false,
			Thickness = Settings.BoxThickness + 2,
			Transparency = 0.65,
			Color = Color3.new(0, 0, 0)
		}),
		Tracer = NewDrawing("Line", {
			Visible = false,
			Thickness = Settings.TracerThickness,
			Transparency = 1
		}),
		Name = NewDrawing("Text", {
			Visible = false,
			Center = true,
			Outline = true,
			Size = 14,
			Font = 2,
			Transparency = 1
		}),
		Distance = NewDrawing("Text", {
			Visible = false,
			Center = true,
			Outline = true,
			Size = 13,
			Font = 2,
			Transparency = 1
		}),
		HealthBack = NewDrawing("Line", {
			Visible = false,
			Thickness = 4,
			Transparency = 0.8,
			Color = Color3.new(0, 0, 0)
		}),
		HealthFill = NewDrawing("Line", {
			Visible = false,
			Thickness = 2,
			Transparency = 1
		}),
		Skeleton = {},
		Bones = {},
		R6Motors = {},
		Character = nil,
		LastBoneScan = 0,
		Highlight = nil
	}

	for index = 1, 48 do
		data.Skeleton[index] = NewDrawing("Line", {
			Visible = false,
			Thickness = Settings.SkeletonThickness,
			Transparency = 1
		})
	end

	Visuals[player] = data
	return data
end

local function HideVisuals(data)
	data.Box.Visible = false
	data.BoxOutline.Visible = false
	data.Tracer.Visible = false
	data.Name.Visible = false
	data.Distance.Visible = false
	data.HealthBack.Visible = false
	data.HealthFill.Visible = false

	for _, line in ipairs(data.Skeleton) do
		line.Visible = false
	end

	if data.Highlight then
		data.Highlight.Enabled = false
	end
end

local function RemoveVisuals(player)
	local data = Visuals[player]
	if not data then
		return
	end

	for _, object in ipairs({
		data.Box,
		data.BoxOutline,
		data.Tracer,
		data.Name,
		data.Distance,
		data.HealthBack,
		data.HealthFill
	}) do
		pcall(function()
			object:Remove()
		end)
	end

	for _, line in ipairs(data.Skeleton) do
		pcall(function()
			line:Remove()
		end)
	end

	if data.Highlight then
		pcall(function()
			data.Highlight:Destroy()
		end)
	end

	Visuals[player] = nil
end

local function IsCharacterPart(character, part)
	return part
		and part:IsA("BasePart")
		and part:IsDescendantOf(character)
		and part.Name ~= "HumanoidRootPart"
		and part.Name ~= "Handle"
end

local function BuildBones(data, character)
	data.Bones = {}
	data.R6Motors = {}
	data.Character = character
	data.LastBoneScan = os.clock()

	for _, object in ipairs(character:GetDescendants()) do
		if object:IsA("Motor6D") then
			data.R6Motors[object.Name] = object

			local part0 = object.Part0
			local part1 = object.Part1

			if IsCharacterPart(character, part0)
				and IsCharacterPart(character, part1)
				and object.Name ~= "RootJoint"
				and object.Name ~= "Root" then
				data.Bones[#data.Bones + 1] = {
					Motor = object,
					Part0 = part0,
					Part1 = part1
				}
			end
		end
	end
end

local function GetBoundingBox(character)
	local success, characterCFrame, characterSize = pcall(function()
		return character:GetBoundingBox()
	end)

	if not success then
		return
	end

	local points = {}

	for x = -1, 1, 2 do
		for y = -1, 1, 2 do
			for z = -1, 1, 2 do
				local worldPosition = characterCFrame:PointToWorldSpace(Vector3.new(
					characterSize.X * x / 2,
					characterSize.Y * y / 2,
					characterSize.Z * z / 2
				))

				local screenPosition = Camera:WorldToViewportPoint(worldPosition)
				if screenPosition.Z > 0 then
					points[#points + 1] = Vector2.new(screenPosition.X, screenPosition.Y)
				end
			end
		end
	end

	if #points == 0 then
		return
	end

	local minimumX = math.huge
	local minimumY = math.huge
	local maximumX = -math.huge
	local maximumY = -math.huge

	for _, point in ipairs(points) do
		minimumX = math.min(minimumX, point.X)
		minimumY = math.min(minimumY, point.Y)
		maximumX = math.max(maximumX, point.X)
		maximumY = math.max(maximumY, point.Y)
	end

	return Vector2.new(minimumX, minimumY), Vector2.new(maximumX, maximumY)
end

local function UpdateSkeleton(data, character, color)
	for _, line in ipairs(data.Skeleton) do
		line.Visible = false
		line.Thickness = Settings.SkeletonThickness
	end

	if not Settings.Skeleton then
		return
	end

	if data.Character ~= character
		or #data.Bones == 0
		or os.clock() - data.LastBoneScan > 2 then
		BuildBones(data, character)
	end

	local lineIndex = 1

	local function DrawSegment(worldA, worldB)
		if not worldA or not worldB or lineIndex > #data.Skeleton then
			return
		end

		if (worldA - worldB).Magnitude < 0.025 then
			return
		end

		local pointA = Camera:WorldToViewportPoint(worldA)
		local pointB = Camera:WorldToViewportPoint(worldB)

		if pointA.Z > 0 and pointB.Z > 0 then
			local line = data.Skeleton[lineIndex]
			line.From = Vector2.new(pointA.X, pointA.Y)
			line.To = Vector2.new(pointB.X, pointB.Y)
			line.Color = color
			line.Thickness = Settings.SkeletonThickness
			line.Visible = true
			lineIndex += 1
		end
	end

	local function JointPosition(motor)
		if motor and motor.Parent and motor.Part0 then
			local fromPart0 = (motor.Part0.CFrame * motor.C0).Position
			if motor.Part1 then
				local fromPart1 = (motor.Part1.CFrame * motor.C1).Position
				return (fromPart0 + fromPart1) / 2
			end
			return fromPart0
		end
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local isR6 = humanoid and humanoid.RigType == Enum.HumanoidRigType.R6
	isR6 = isR6 or (character:FindFirstChild("Torso") and not character:FindFirstChild("UpperTorso"))

	if isR6 then
		local torso = character:FindFirstChild("Torso")
		local head = character:FindFirstChild("Head")
		local leftArm = character:FindFirstChild("Left Arm")
		local rightArm = character:FindFirstChild("Right Arm")
		local leftLeg = character:FindFirstChild("Left Leg")
		local rightLeg = character:FindFirstChild("Right Leg")

		if torso then
			local neck = JointPosition(data.R6Motors.Neck)
				or torso.CFrame:PointToWorldSpace(Vector3.new(0, torso.Size.Y / 2, 0))
			local leftShoulder = JointPosition(data.R6Motors["Left Shoulder"])
				or torso.CFrame:PointToWorldSpace(Vector3.new(-torso.Size.X / 2, torso.Size.Y * 0.25, 0))
			local rightShoulder = JointPosition(data.R6Motors["Right Shoulder"])
				or torso.CFrame:PointToWorldSpace(Vector3.new(torso.Size.X / 2, torso.Size.Y * 0.25, 0))
			local chest = (leftShoulder + rightShoulder) / 2
			local pelvis = torso.CFrame:PointToWorldSpace(Vector3.new(0, -torso.Size.Y * 0.45, 0))

			if head then
				DrawSegment(head.Position, neck)
			end

			DrawSegment(neck, chest)
			DrawSegment(chest, pelvis)
			DrawSegment(leftShoulder, chest)
			DrawSegment(chest, rightShoulder)

			if leftArm then
				local leftHand = leftArm.CFrame:PointToWorldSpace(Vector3.new(0, -leftArm.Size.Y / 2, 0))
				DrawSegment(leftShoulder, leftHand)
			end

			if rightArm then
				local rightHand = rightArm.CFrame:PointToWorldSpace(Vector3.new(0, -rightArm.Size.Y / 2, 0))
				DrawSegment(rightShoulder, rightHand)
			end

			if leftLeg then
				local leftHip = leftLeg.CFrame:PointToWorldSpace(Vector3.new(0, leftLeg.Size.Y / 2, 0))
				local leftFoot = leftLeg.CFrame:PointToWorldSpace(Vector3.new(0, -leftLeg.Size.Y / 2, 0))
				DrawSegment(pelvis, leftHip)
				DrawSegment(leftHip, leftFoot)
			end

			if rightLeg then
				local rightHip = rightLeg.CFrame:PointToWorldSpace(Vector3.new(0, rightLeg.Size.Y / 2, 0))
				local rightFoot = rightLeg.CFrame:PointToWorldSpace(Vector3.new(0, -rightLeg.Size.Y / 2, 0))
				DrawSegment(pelvis, rightHip)
				DrawSegment(rightHip, rightFoot)
			end

			return
		end
	end

	for _, bone in ipairs(data.Bones) do
		if lineIndex > #data.Skeleton then
			break
		end

		local motor = bone.Motor
		local part0 = bone.Part0
		local part1 = bone.Part1

		if motor
			and motor.Parent
			and part0
			and part1
			and part0.Parent
			and part1.Parent
			and part0:IsDescendantOf(character)
			and part1:IsDescendantOf(character) then
			local joint = JointPosition(motor)
			DrawSegment(part0.Position, joint)
			DrawSegment(joint, part1.Position)
		end
	end
end

local function UpdateHighlight(data, character, color)
	if data.Highlight and data.Highlight.Adornee ~= character then
		data.Highlight:Destroy()
		data.Highlight = nil
	end

	if not Settings.Chams then
		if data.Highlight then
			data.Highlight.Enabled = false
		end
		return
	end

	if not data.Highlight then
		local highlight = Instance.new("Highlight")
		highlight.Name = "ESPHighlight"
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.FillTransparency = 0.65
		highlight.OutlineTransparency = 0.05
		highlight.Adornee = character
		highlight.Parent = HighlightFolder
		data.Highlight = highlight
	end

	data.Highlight.FillColor = color
	data.Highlight.OutlineColor = color
	data.Highlight.Enabled = true
end

local function ShouldDisplay(player)
	if not Settings.Enabled then
		return false
	end

	if player == LocalPlayer and not Settings.SelfESP then
		return false
	end

	if Settings.TeamCheck and player ~= LocalPlayer then
		if LocalPlayer.Team and player.Team == LocalPlayer.Team then
			return false
		end
	end

	return true
end

local function GetTracerStart(rootScreen)
	if Settings.TracerOrigin == "Top" then
		return Vector2.new(Camera.ViewportSize.X / 2, 2)
	elseif Settings.TracerOrigin == "Center" then
		return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
	elseif Settings.TracerOrigin == "Mouse" and UserInputService.MouseEnabled then
		local mouse = UserInputService:GetMouseLocation()
		return Vector2.new(mouse.X, mouse.Y)
	end

	return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y - 2)
end

local function UpdatePlayer(player)
	local data = CreateVisuals(player)
	HideVisuals(data)

	if not ShouldDisplay(player) then
		return
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")

	if not character or not humanoid or not rootPart or humanoid.Health <= 0 then
		return
	end

	local worldDistance = (Camera.CFrame.Position - rootPart.Position).Magnitude
	if Settings.MaxDistance > 0 and worldDistance > Settings.MaxDistance then
		return
	end

	local color = Settings.ESPColor
	UpdateHighlight(data, character, color)

	local rootScreen, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
	if not onScreen or rootScreen.Z <= 0 then
		return
	end

	local minimum, maximum = GetBoundingBox(character)
	if not minimum or not maximum then
		return
	end

	local width = maximum.X - minimum.X
	local height = maximum.Y - minimum.Y
	if width <= 1 or height <= 1 then
		return
	end

	data.Box.Thickness = Settings.BoxThickness
	data.BoxOutline.Thickness = Settings.BoxThickness + 2
	data.Tracer.Thickness = Settings.TracerThickness

	if Settings.Box then
		data.BoxOutline.Position = minimum
		data.BoxOutline.Size = Vector2.new(width, height)
		data.BoxOutline.Visible = true

		data.Box.Position = minimum
		data.Box.Size = Vector2.new(width, height)
		data.Box.Color = color
		data.Box.Visible = true
	end

	if Settings.Tracers then
		data.Tracer.From = GetTracerStart(rootScreen)
		data.Tracer.To = Vector2.new(rootScreen.X, maximum.Y)
		data.Tracer.Color = color
		data.Tracer.Visible = true
	end

	if Settings.Names then
		data.Name.Text = player.DisplayName
		data.Name.Position = Vector2.new(minimum.X + width / 2, minimum.Y - 17)
		data.Name.Color = color
		data.Name.Visible = true
	end

	if Settings.Distance then
		data.Distance.Text = tostring(math.floor(worldDistance)) .. " studs"
		data.Distance.Position = Vector2.new(minimum.X + width / 2, maximum.Y + 2)
		data.Distance.Color = color
		data.Distance.Visible = true
	end

	if Settings.Health then
		local healthPercent = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
		local barX = minimum.X - 6

		data.HealthBack.From = Vector2.new(barX, maximum.Y)
		data.HealthBack.To = Vector2.new(barX, minimum.Y)
		data.HealthBack.Visible = true

		data.HealthFill.From = Vector2.new(barX, maximum.Y)
		data.HealthFill.To = Vector2.new(barX, maximum.Y - height * healthPercent)
		data.HealthFill.Color = Color3.fromRGB(
			math.floor(255 * (1 - healthPercent)),
			math.floor(255 * healthPercent),
			70
		)
		data.HealthFill.Visible = true
	end

	UpdateSkeleton(data, character, color)
end

local Window = UI.new({
	Title = "SIMPLE ESP",
	Keybind = Enum.KeyCode.RightShift,
	Accent = DefaultAccent
})

local Controls = {}

local VisualTab = Window:AddTab("Visuals")
VisualTab:AddSection("Main ESP")

Controls.Enabled = VisualTab:AddToggle("ESP enabled", Settings.Enabled, function(value)
	Settings.Enabled = value
end)

Controls.Box = VisualTab:AddToggle("Boxes", Settings.Box, function(value)
	Settings.Box = value
end)

Controls.Skeleton = VisualTab:AddToggle("Skeleton", Settings.Skeleton, function(value)
	Settings.Skeleton = value
end)

Controls.Tracers = VisualTab:AddToggle("Tracers", Settings.Tracers, function(value)
	Settings.Tracers = value
end)

Controls.Chams = VisualTab:AddToggle("Chams", Settings.Chams, function(value)
	Settings.Chams = value
end)

VisualTab:AddSection("Player details")

Controls.Names = VisualTab:AddToggle("Names", Settings.Names, function(value)
	Settings.Names = value
end)

Controls.Distance = VisualTab:AddToggle("Distance", Settings.Distance, function(value)
	Settings.Distance = value
end)

Controls.Health = VisualTab:AddToggle("Health bar", Settings.Health, function(value)
	Settings.Health = value
end)

local FilterTab = Window:AddTab("Filters")
FilterTab:AddSection("Targets")

Controls.SelfESP = FilterTab:AddToggle("Self ESP", Settings.SelfESP, function(value)
	Settings.SelfESP = value
end)

Controls.TeamCheck = FilterTab:AddToggle("Team check", Settings.TeamCheck, function(value)
	Settings.TeamCheck = value
end)

Controls.MaxDistance = FilterTab:AddSlider("Max distance", {
	Min = 100,
	Max = 5000,
	Default = Settings.MaxDistance,
	Suffix = " studs"
}, function(value)
	Settings.MaxDistance = value
end)

FilterTab:AddSection("Tracer")

Controls.TracerOrigin = FilterTab:AddDropdown(
	"Tracer origin",
	{"Bottom", "Center", "Top", "Mouse"},
	Settings.TracerOrigin,
	function(value)
		Settings.TracerOrigin = value
	end
)

local ColorTab = Window:AddTab("Colors")
ColorTab:AddSection("ESP color")

local RainbowControl
local ESPColorControl = ColorTab:AddColorPicker("ESP color", Settings.ESPColor, function(color)
	Settings.ESPColor = color
	LastManualColor = color

	if Settings.Rainbow then
		Settings.Rainbow = false
		if RainbowControl then
			RainbowControl:Set(false, true)
		end
	end
end)

RainbowControl = ColorTab:AddToggle("Rainbow ESP", Settings.Rainbow, function(value)
	Settings.Rainbow = value
	if not value then
		Settings.ESPColor = LastManualColor
		ESPColorControl:Set(LastManualColor, true)
	end
end)
Controls.Rainbow = RainbowControl

Controls.RainbowSpeed = ColorTab:AddSlider("Rainbow cycle", {
	Min = 1,
	Max = 12,
	Default = Settings.RainbowSpeed,
	Decimals = 1,
	Suffix = "s"
}, function(value)
	Settings.RainbowSpeed = math.max(value, 0.1)
end)

ColorTab:AddSection("Interface")

local UIAccentControl = ColorTab:AddColorPicker("UI accent", DefaultAccent, function(color)
	Window:SetAccent(color)
end)

local StyleTab = Window:AddTab("Style")
StyleTab:AddSection("Line thickness")

Controls.BoxThickness = StyleTab:AddSlider("Box thickness", {
	Min = 1,
	Max = 4,
	Default = Settings.BoxThickness,
	Decimals = 1
}, function(value)
	Settings.BoxThickness = value
end)

Controls.SkeletonThickness = StyleTab:AddSlider("Skeleton thickness", {
	Min = 1,
	Max = 4,
	Default = Settings.SkeletonThickness,
	Decimals = 1
}, function(value)
	Settings.SkeletonThickness = value
end)

Controls.TracerThickness = StyleTab:AddSlider("Tracer thickness", {
	Min = 1,
	Max = 4,
	Default = Settings.TracerThickness,
	Decimals = 1
}, function(value)
	Settings.TracerThickness = value
end)

StyleTab:AddSection("Actions")

StyleTab:AddButton("Reset ESP settings", function()
	Settings.Enabled = true
	Settings.Box = true
	Settings.Skeleton = false
	Settings.Tracers = false
	Settings.Chams = false
	Settings.Names = true
	Settings.Distance = true
	Settings.Health = true
	Settings.SelfESP = false
	Settings.TeamCheck = false
	Settings.Rainbow = false
	Settings.ESPColor = DefaultColor
	Settings.MaxDistance = 2500
	Settings.BoxThickness = 1.5
	Settings.SkeletonThickness = 1.5
	Settings.TracerThickness = 1.5
	Settings.RainbowSpeed = 5
	Settings.TracerOrigin = "Bottom"
	LastManualColor = DefaultColor

	Controls.Enabled:Set(true)
	Controls.Box:Set(true)
	Controls.Skeleton:Set(false)
	Controls.Tracers:Set(false)
	Controls.Chams:Set(false)
	Controls.Names:Set(true)
	Controls.Distance:Set(true)
	Controls.Health:Set(true)
	Controls.SelfESP:Set(false)
	Controls.TeamCheck:Set(false)
	Controls.Rainbow:Set(false)
	Controls.MaxDistance:Set(2500)
	Controls.TracerOrigin:Set("Bottom")
	Controls.RainbowSpeed:Set(5)
	Controls.BoxThickness:Set(1.5)
	Controls.SkeletonThickness:Set(1.5)
	Controls.TracerThickness:Set(1.5)
	ESPColorControl:Set(DefaultColor)
	UIAccentControl:Set(DefaultAccent)
	Window:SetAccent(DefaultAccent)
end)

StyleTab:AddButton("Hide menu", function()
	Window:Hide()
end)

StyleTab:AddButton("Unload ESP", function()
	if Environment.SimpleESPUnload then
		Environment.SimpleESPUnload()
	end
end)

StyleTab:AddSection("Controls")
StyleTab:AddLabel("PC: press Right Shift to hide or restore the menu. Mobile: tap or drag the small restore circle after hiding it.")
StyleTab:AddLabel("R6 uses centered leg-top points instead of the wide hip Motor6D positions, so the legs no longer flare inward like a squat pose.")

EngineConnections[#EngineConnections + 1] = Players.PlayerRemoving:Connect(function(player)
	RemoveVisuals(player)
end)

EngineConnections[#EngineConnections + 1] = RunService.RenderStepped:Connect(function()
	if not Running then
		return
	end

	Camera = workspace.CurrentCamera
	if not Camera then
		return
	end

	if Settings.Rainbow then
		local cycle = math.max(Settings.RainbowSpeed, 0.1)
		Settings.ESPColor = Color3.fromHSV((os.clock() % cycle) / cycle, 1, 1)
	end

	for _, player in ipairs(Players:GetPlayers()) do
		UpdatePlayer(player)
	end
end)

Environment.SimpleESPUnload = function()
	if not Running then
		return
	end

	Running = false

	for _, connection in ipairs(EngineConnections) do
		pcall(function()
			connection:Disconnect()
		end)
	end
	EngineConnections = {}

	local playersToRemove = {}
	for player in pairs(Visuals) do
		playersToRemove[#playersToRemove + 1] = player
	end
	for _, player in ipairs(playersToRemove) do
		RemoveVisuals(player)
	end

	if HighlightFolder then
		pcall(function()
			HighlightFolder:Destroy()
		end)
	end

	if Window then
		pcall(function()
			Window:Destroy()
		end)
	end

	Environment.SimpleESPUnload = nil
end
