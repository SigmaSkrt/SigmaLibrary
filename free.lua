local P=game:GetService("Players").LocalPlayer
local U=game:GetService("UserInputService")
local R=game:GetService("RunService")
local G=Instance.new("ScreenGui",P.PlayerGui)
local F=Instance.new("Frame",G)
local loop,fly,ws,fs=false,false,16,70
local BV,BG

G.ResetOnSpawn=false
F.Size=UDim2.fromOffset(230,155)
F.Position=UDim2.new(.5,-115,.5,-77)
F.BackgroundColor3=Color3.fromRGB(20,20,25)
F.Active=true
F.Draggable=true
Instance.new("UICorner",F).CornerRadius=UDim.new(0,10)

local function new(c,t,x,y,w,h)
	local o=Instance.new(c,F)
	o.Text=t
	o.Position=UDim2.fromOffset(x,y)
	o.Size=UDim2.fromOffset(w,h)
	o.BackgroundColor3=Color3.fromRGB(40,40,50)
	o.TextColor3=Color3.new(1,1,1)
	o.Font=Enum.Font.GothamBold
	o.TextSize=13
	Instance.new("UICorner",o).CornerRadius=UDim.new(0,7)
	return o
end

local title=new("TextLabel","MOVEMENT",10,7,210,25)
title.BackgroundTransparency=1

local box=new("TextBox","16",10,38,65,32)
box.ClearTextOnFocus=false

local set=new("TextButton","SET SPEED",82,38,138,32)
local mode=new("TextButton","SPEED: ONCE",10,77,210,30)
local fb=new("TextButton","FLY: OFF",10,114,210,30)

local function char()
	local c=P.Character or P.CharacterAdded:Wait()
	return c,c:WaitForChild("Humanoid"),c:WaitForChild("HumanoidRootPart")
end

set.MouseButton1Click:Connect(function()
	local _,h=char()
	ws=math.clamp(tonumber(box.Text)or 16,0,300)
	box.Text=tostring(ws)
	h.WalkSpeed=ws
end)

mode.MouseButton1Click:Connect(function()
	loop=not loop
	mode.Text=loop and "SPEED: LOOP" or "SPEED: ONCE"
end)

local function toggle()
	local _,h,r=char()
	fly=not fly
	fb.Text=fly and "FLY: ON" or "FLY: OFF"

	if fly then
		h.PlatformStand=true

		BV=Instance.new("BodyVelocity",r)
		BV.MaxForce=Vector3.new(math.huge,math.huge,math.huge)
		BV.P=50000

		BG=Instance.new("BodyGyro",r)
		BG.MaxTorque=Vector3.new(math.huge,math.huge,math.huge)
		BG.P=50000
	else
		if BV then BV:Destroy() end
		if BG then BG:Destroy() end
		BV,BG=nil,nil
		h.PlatformStand=false
		r.AssemblyLinearVelocity=Vector3.zero
	end
end

fb.MouseButton1Click:Connect(toggle)

P.CharacterAdded:Connect(function()
	fly=false
	BV,BG=nil,nil
	fb.Text="FLY: OFF"
end)

U.InputBegan:Connect(function(i,g)
	if not g and i.KeyCode==Enum.KeyCode.F then toggle() end
end)

R.RenderStepped:Connect(function()
	local _,h,r=char()

	if loop then h.WalkSpeed=ws end
	if not fly or not BV or not BG then return end

	local c=workspace.CurrentCamera.CFrame
	local d=Vector3.zero

	if U:IsKeyDown(Enum.KeyCode.W) then d+=c.LookVector end
	if U:IsKeyDown(Enum.KeyCode.S) then d-=c.LookVector end
	if U:IsKeyDown(Enum.KeyCode.A) then d-=c.RightVector end
	if U:IsKeyDown(Enum.KeyCode.D) then d+=c.RightVector end

	BV.Velocity=d.Magnitude>0 and d.Unit*fs or Vector3.zero
	BG.CFrame=CFrame.lookAt(r.Position,r.Position+c.LookVector)
end)
