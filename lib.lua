--[[
    DevK | COMMUNITY
    Author  : DevK
    Version : 1.0.3
    Created : November 1999
    Discord : -
]]
TweenService = game:GetService("TweenService")
UserInputService = game:GetService("UserInputService")
RunService = game:GetService("RunService")
CoreGui = game:GetService("CoreGui")
Players = game:GetService("Players")
HttpService = game:GetService("HttpService")
Lighting = game:GetService("Lighting")
Terrain = workspace:FindFirstChildOfClass("Terrain")
    
local VoraLib = {}
local Connections = {}
-- Hanya satu slot keybind yang boleh "listening" sekaligus; mencegah key satu mengubah slot lain.
local KeybindBindSessionCancel = nil


function MakeDraggable(topbarobject, object)
	local Dragging = nil
	local DragInput = nil
	local DragStart = nil
	local StartPosition = nil

	local function Update(input)
		local Delta = input.Position - DragStart
		local pos = UDim2.new(StartPosition.X.Scale, StartPosition.X.Offset + Delta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + Delta.Y)
		local Tween = TweenService:Create(object, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = pos})
		Tween:Play()
	end

	table.insert(Connections, topbarobject.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			Dragging = true
			DragStart = input.Position
			StartPosition = object.Position

			local connection
			connection = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					Dragging = false
					if connection then connection:Disconnect() end
				end
			end)
		end
	end))

	table.insert(Connections, topbarobject.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			DragInput = input
		end
	end))

	table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
		if input == DragInput and Dragging then
			Update(input)
		end
	end))
end

function Create(className, properties)
	local instance = Instance.new(className)
	for k, v in pairs(properties) do
		instance[k] = v
	end
	return instance
end


local Theme = {
	Background = Color3.fromRGB(10, 12, 25), 
	Sidebar = Color3.fromRGB(15, 18, 32),
	ElementBackground = Color3.fromRGB(25, 30, 50),
	TextColor = Color3.fromRGB(255, 255, 255), 
	TextSecondary = Color3.fromRGB(180, 200, 230), 
	Accent = Color3.fromRGB(0, 140, 210), 
	Hover = Color3.fromRGB(35, 45, 70),
	Outline = Color3.fromRGB(40, 60, 90)
}

local Icons = {
    player    = "rbxassetid://12120698352",
    web       = "rbxassetid://137601480983962",
    bag       = "rbxassetid://8601111810",
    shop      = "rbxassetid://4985385964",
    cart      = "rbxassetid://128874923961846",
    plug      = "rbxassetid://137601480983962",
    settings  = "rbxassetid://70386228443175",
    loop      = "rbxassetid://122032243989747",
    gps       = "rbxassetid://17824309485",
    compas    = "rbxassetid://125300760963399",
    gamepad   = "rbxassetid://84173963561612",
    boss      = "rbxassetid://13132186360",
    scroll    = "rbxassetid://114127804740858",
    menu      = "rbxassetid://6340513838",
    crosshair = "rbxassetid://12614416478",
    user      = "rbxassetid://108483430622128",
    stat      = "rbxassetid://12094445329",
    eyes      = "rbxassetid://14321059114",
    sword     = "rbxassetid://82472368671405",
    discord   = "rbxassetid://94434236999817",
    star      = "rbxassetid://107005941750079",
    skeleton  = "rbxassetid://17313330026",
    payment   = "rbxassetid://18747025078",
    scan      = "rbxassetid://109869955247116",
    alert     = "rbxassetid://73186275216515",
    question  = "rbxassetid://17510196486",
    idea      = "rbxassetid://16833255748",
    strom     = "rbxassetid://13321880293",
    water     = "rbxassetid://13321880293",
    dcs       = "rbxassetid://15310731934",
    start     = "rbxassetid://108886429866687",
    next      = "rbxassetid://12662718374",
    rod       = "rbxassetid://103247953194129",
    fish      = "rbxassetid://97167558235554",
    bell      = "rbxassetid://73186275216515",
}



VoraLib.Icons = Icons

function VoraLib:CreateWindow(options)
    
	options = options or {}
	local TitleName = options.Name or "VoraHub"
	local IntroEnabled = options.Intro or false
	
	
	local function GetParent()
		local Success, Parent = pcall(function()
			return (gethui and gethui()) or game:GetService("CoreGui")
		end)
		
		if not Success or not Parent then
			return game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
		end
		
		return Parent
	end

	local ScreenGui = Create("ScreenGui", {
		Name = "VoraHub",
		Parent = GetParent(),
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn = false
	})
	
	local ViewportSize = workspace.CurrentCamera.ViewportSize
	local IsMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
	local InitialSize = IsMobile and UDim2.new(0, 500, 0, 320) or UDim2.new(0, 700, 0, 450)
	local InitialPosition = IsMobile and UDim2.new(0.5, -250, 0.5, -160) or UDim2.new(0.5, -350, 0.5, -225)
	
	local MainFrame = Create("Frame", {
		Name = "MainFrame",
		Parent = ScreenGui,
		BackgroundColor3 = Theme.Background,
		BackgroundTransparency = 0.05, 
		BorderSizePixel = 0,
		Position = InitialPosition,
		Size = InitialSize,
		ClipsDescendants = false
	})
	
	Create("UICorner", {
		CornerRadius = UDim.new(0, 10), 
		Parent = MainFrame
	})
	
	
	local MainStroke = Create("UIStroke", {
		Transparency = 0,
		Thickness = 1,
		Color = Theme.Outline,
		Parent = MainFrame
	})

	-- Background Pattern (Hexagons/Dots)
	local Pattern = Create("ImageLabel", {
		Name = "Pattern",
		Parent = MainFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
		Image = "rbxassetid://2151741365", -- Subtle texture
		ImageTransparency = 0.95,
		TileSize = UDim2.new(0, 20, 0, 20),
		ScaleType = Enum.ScaleType.Tile,
		ZIndex = 1
	})

	-- Premium Shadow
	local Shadow = Create("ImageLabel", {
		Name = "Shadow",
		Parent = ScreenGui,
		BackgroundTransparency = 1,
		Position = InitialPosition,
		Size = InitialSize,
		Image = "rbxassetid://6015897843",
		ImageColor3 = Color3.new(0,0,0),
		ImageTransparency = 0.5,
		ZIndex = -1,
		SliceCenter = Rect.new(49, 49, 450, 450),
		ScaleType = Enum.ScaleType.Slice,
		SliceScale = 1
	})
	
	-- Sync Shadow Size/Pos
	MainFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		Shadow.Size = UDim2.new(0, MainFrame.AbsoluteSize.X + 34, 0, MainFrame.AbsoluteSize.Y + 34)
	end)
	MainFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
		Shadow.Position = UDim2.new(0, MainFrame.AbsolutePosition.X - 17, 0, MainFrame.AbsolutePosition.Y - 17)
	end)

	-- Resize Handle (Clean Grip Lines)
	local ResizeHandle = Create("TextButton", {
		Name = "ResizeHandle",
		Parent = MainFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -4, 1, -4),
		Size = UDim2.new(0, 16, 0, 16),
		Text = "",
		AutoButtonColor = false,
		ZIndex = 100,
		AnchorPoint = Vector2.new(1, 1)
	})

	local ResizeLines = {}
	for i = 1, 3 do
		-- Line 1 (smallest) -> Line 3 (largest)
		-- Or Line 1 (Largest) -> Line 3 (Smallest) ?
		-- Let's do Standard Grip: Bottom-Right is smallest? No, usually parallel diagonal lines increasing in length.
		-- Line 1: x, y (closest to corner)
		
		local Offset = i * 4
		local Line = Create("Frame", {
			Parent = ResizeHandle,
			BackgroundColor3 = Theme.TextSecondary,
			BorderSizePixel = 0,
			Rotation = -45,
			Size = UDim2.new(0, 2 + (i * 5), 0, 2), -- Increasing size
			Position = UDim2.new(1, 0, 1, -Offset),   -- Moving up/left
			AnchorPoint = Vector2.new(1, 1),
			ZIndex = 101
		})
		
		-- Adjust position to form a triangle shape at the corner
		-- Actually simpler logic:
		-- The lines are usually at 45 deg.
		-- Let's just hardcode 3 nice lines.
		Line:Destroy() 
	end
	
	-- Re-doing loop for perfect placement
	local LineConfigs = {
		{Size = UDim2.new(0, 6,  0, 2), Pos = UDim2.new(1, -2, 1, -2)},
		{Size = UDim2.new(0, 10, 0, 2), Pos = UDim2.new(1, -2, 1, -6)},
		{Size = UDim2.new(0, 14, 0, 2), Pos = UDim2.new(1, -2, 1, -10)},
	}

	for _, cfg in ipairs(LineConfigs) do
		local Line = Create("Frame", {
			Parent = ResizeHandle,
			BackgroundColor3 = Theme.TextSecondary,
			BorderSizePixel = 0,
			Rotation = -45,
			Size = cfg.Size,
			Position = cfg.Pos,
			AnchorPoint = Vector2.new(1, 1),
			ZIndex = 101
		})
		Create("UICorner", {CornerRadius = UDim.new(1,0), Parent = Line})
		table.insert(ResizeLines, Line)
	end

	-- Hover Animation
	ResizeHandle.MouseEnter:Connect(function()
		for _, line in ipairs(ResizeLines) do
			TweenService:Create(line, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Accent}):Play()
		end
	end)
	ResizeHandle.MouseLeave:Connect(function()
		for _, line in ipairs(ResizeLines) do
			TweenService:Create(line, TweenInfo.new(0.2), {BackgroundColor3 = Theme.TextSecondary}):Play()
		end
	end)

	local Resizing = false
	local ResizeStart = Vector2.new()
	local StartSize = Vector2.new()

	ResizeHandle.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			Resizing = true
			ResizeStart = Input.Position
			StartSize = MainFrame.AbsoluteSize
		end
	end)

	UserInputService.InputChanged:Connect(function(Input)
		if Resizing and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
			local Delta = Input.Position - ResizeStart
			local NewWidth = math.max(400, StartSize.X + Delta.X)
			local NewHeight = math.max(300, StartSize.Y + Delta.Y)

			MainFrame.Size = UDim2.new(0, NewWidth, 0, NewHeight)
		end
	end)

	UserInputService.InputEnded:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			Resizing = false
		end
	end)

	local Header = Create("Frame", {
		Name = "Header",
		Parent = MainFrame,
		BackgroundColor3 = Theme.Sidebar,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 38) 
	})
	
	Create("UICorner", {
		CornerRadius = UDim.new(0, 10),
		Parent = Header
	})
	
	
	Create("Frame", {
		Name = "BottomFiller",
		Parent = Header,
		BackgroundColor3 = Theme.Sidebar,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 0.5, 0),
		ZIndex = 1
	})
	
	
	Create("Frame", {
		Parent = Header,
		BackgroundColor3 = Theme.Outline,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, -1),
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 2
	})

	
	local Logo = Create("ImageLabel", {
		Name = "Logo",
		Parent = Header,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 5),
		Size = UDim2.new(0, 25, 0, 25),
		Image = "rbxassetid://112067161065104",
		ImageColor3 = Theme.Accent,
		ZIndex = 2
	})

	
	local TitleLabel = Create("TextLabel", {
		Name = "Title",
		Parent = Header,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 45, 0, 0),
		Size = UDim2.new(1, -160, 1, 0),
		Font = Enum.Font.GothamBold,
		Text = TitleName,
		TextColor3 = Theme.TextColor,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 2
	})
	
	
	if IntroEnabled then
		local StartSize = MainFrame.Size
		MainFrame.Size = UDim2.new(0, 0, 0, 0)
		MainFrame.BackgroundTransparency = 1
		
		TweenService:Create(MainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Size = StartSize,
			BackgroundTransparency = 0.05
		}):Play()
	end
	
	
	local Sidebar = Create("Frame", {
		Name = "Sidebar",
		Parent = MainFrame,
		BackgroundColor3 = Theme.Sidebar,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 38),
		Size = UDim2.new(0, 160, 1, -38)
	})
	
	
	Create("Frame", {
		Name = "Separator",
		Parent = Sidebar,
		BackgroundColor3 = Theme.Outline,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -2, 0, 0),
		Size = UDim2.new(0, 2, 1, 0)
	})

	
	local Controls = Create("Frame", {
		Name = "Controls",
		Parent = Header,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -100, 0, 0),
		Size = UDim2.new(0, 100, 1, 0),
		ZIndex = 2
	})
	
	local UIListLayout = Create("UIListLayout", {
		Parent = Controls,
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8)
	})
	
	Create("UIPadding", {
		Parent = Controls,
		PaddingRight = UDim.new(0, 15)
	})

	local IsMinimized = false
	local ToggleButton = Create("ImageButton", {
		Name = "ToggleUI",
		Parent = ScreenGui,
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		Position = UDim2.new(0.1, 0, 0.1, 0),
		Size = UDim2.new(0, 50, 0, 50),
		Image = "rbxassetid://127876061340518", 
		ImageColor3 = Theme.TextColor,
		Visible = true, 
		Active = true,
		Draggable = true,
		ZIndex = 100
	})
	
	Create("UICorner", {
		CornerRadius = UDim.new(0, 10),
		Parent = ToggleButton
	})
	
	Create("UIStroke", {
		Color = Theme.Outline,
		Thickness = 1,
		Parent = ToggleButton
	})

	local function ToggleUI()
		IsMinimized = not IsMinimized
		
		if IsMinimized then
			-- Close Animation
			local CloseTween = TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
				Size = UDim2.new(0, 0, 0, 0)
			})
			CloseTween:Play()
			
			task.delay(0.3, function()
				if IsMinimized then
					MainFrame.Visible = false
					if Shadow then Shadow.Visible = false end
				end
			end)
		else
			-- Open Animation
			MainFrame.Visible = true
			if Shadow then Shadow.Visible = true end

			local OriginalSize = IsMobile and UDim2.new(0, 500, 0, 320) or UDim2.new(0, 700, 0, 450)
			MainFrame.Size = UDim2.new(0, 0, 0, 0)
			
			TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Size = OriginalSize
			}):Play()
		end
	end
	
	ToggleButton.MouseButton1Click:Connect(ToggleUI)
	
	-- Add keyboard shortcut
	local ToggleKey = Enum.KeyCode.RightControl
	table.insert(Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed and input.KeyCode == ToggleKey then
			ToggleUI()
		end
	end))


	local function CreateControlButton(name, icon, layoutOrder, callback)
		local Button = Create("ImageButton", {
			Name = name,
			Parent = Controls,
			BackgroundTransparency = 1,
			LayoutOrder = layoutOrder,
			Size = UDim2.new(0, 20, 0, 20),
			Image = "rbxassetid://" .. icon,
			ImageColor3 = Theme.TextSecondary,
			AutoButtonColor = false
		})
		
		Button.MouseEnter:Connect(function()
			TweenService:Create(Button, TweenInfo.new(0.2), {ImageColor3 = Theme.TextColor}):Play()
		end)
		
		Button.MouseLeave:Connect(function()
			TweenService:Create(Button, TweenInfo.new(0.2), {ImageColor3 = Theme.TextSecondary}):Play()
		end)
		
		Button.MouseButton1Click:Connect(callback)
		return Button
	end

	CreateControlButton("Minimize", "71686683787518", 1, ToggleUI)

	
	local Window = {
		Tabs = {},
		Elements = {},
		Instance = ScreenGui,
		Flags = {}
	}



	
	local NotificationHolder = Create("Frame", {
		Name = "NotificationHolder",
		Parent = ScreenGui,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -20, 1, -20),
		Size = UDim2.new(0, 300, 1, -20),
		AnchorPoint = Vector2.new(1, 1),
		ZIndex = 100
	})

	Create("UIListLayout", {
		Parent = NotificationHolder,
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 10)
	})

	function Window:Notify(options)
		options = options or {}
		local Title = options.Title or options.Name or "Notification"
		local Content = options.Content or "Message"
		local Duration = options.Duration or 3
		local Image = options.Image or options.Icon or "rbxassetid://112067161065104"
		if Icons[Image] then Image = Icons[Image] end

		local NotifyFrame = Create("Frame", {
			Name = "NotifyFrame",
			Parent = NotificationHolder,
			BackgroundColor3 = Theme.Sidebar,
			BackgroundTransparency = 0.1,
			Size = UDim2.new(1, 0, 0, 0), 
			AutomaticSize = Enum.AutomaticSize.Y,
			ClipsDescendants = true
		})

		Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = NotifyFrame })
		Create("UIStroke", { Color = Theme.Outline, Thickness = 1, Parent = NotifyFrame })

		local ContentFrame = Create("Frame", {
			Parent = NotifyFrame,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 60)
		})

		local Icon = Create("ImageLabel", {
			Parent = ContentFrame,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 12, 0, 12),
			Size = UDim2.new(0, 36, 0, 36),
			Image = Image,
			ImageColor3 = Theme.Accent
		})
		
		Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Icon })

		local TitleLabel = Create("TextLabel", {
			Parent = ContentFrame,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 58, 0, 10),
			Size = UDim2.new(1, -68, 0, 20),
			Font = Enum.Font.GothamBold,
			Text = Title,
			TextColor3 = Theme.TextColor,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left
		})

		local ContentLabel = Create("TextLabel", {
			Parent = ContentFrame,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 58, 0, 30),
			Size = UDim2.new(1, -68, 0, 20),
			Font = Enum.Font.Gotham,
			Text = Content,
			TextColor3 = Theme.TextSecondary,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true
		})
		
		
		NotifyFrame.Position = UDim2.new(1, 320, 0, 0)
		TweenService:Create(NotifyFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = UDim2.new(0, 0, 0, 0)}):Play()
		
		
		local ProgressBar = Create("Frame", {
			Parent = NotifyFrame,
			BackgroundColor3 = Theme.Accent,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, 1, -2),
			Size = UDim2.new(1, 0, 0, 2)
		})
		
		TweenService:Create(ProgressBar, TweenInfo.new(Duration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)}):Play()

		task.delay(Duration, function()
			TweenService:Create(NotifyFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = UDim2.new(1, 320, 0, 0)}):Play()
			task.wait(0.5)
			NotifyFrame:Destroy()
		end)
	end

	
	local Maximized = false
	local DefaultSize = IsMobile and UDim2.new(0, 500, 0, 320) or UDim2.new(0, 700, 0, 450)
	local MaxSize = IsMobile and UDim2.new(0, 600, 0, 350) or UDim2.new(0, 900, 0, 600)
	local DefaultPos = IsMobile and UDim2.new(0.5, -250, 0.5, -160) or UDim2.new(0.5, -350, 0.5, -225)
	local MaxPos = IsMobile and UDim2.new(0.5, -300, 0.5, -175) or UDim2.new(0.5, -450, 0.5, -300)
	
	CreateControlButton("Maximize", "135582116755237", 2, function()
		Maximized = not Maximized
		if Maximized then
			TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Size = MaxSize,
				Position = MaxPos
			}):Play()
		else
			TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Size = DefaultSize,
				Position = DefaultPos
			}):Play()
		end
	end)

	CreateControlButton("Close", "121948938505669", 3, function()
		TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1
		}):Play()
		task.wait(0.3)
		Window:Destroy()
	end)
	
	-- Toggle UI Button & Logic
	local MainFrameVisible = true
	local function ToggleUI()
		MainFrameVisible = not MainFrameVisible
		if MainFrameVisible then
			-- OPEN: Restore to Default Size/Pos (or Max if was Max? simplified to Default for now)
			MainFrame.Visible = true
			if Shadow then Shadow.Visible = true end
			
			TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Size = DefaultSize,
				BackgroundTransparency = 0.05
			}):Play()
			
			if Shadow then
				TweenService:Create(Shadow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					ImageTransparency = 0.5,
					Size = UDim2.new(0, DefaultSize.X.Offset + 34, 0, DefaultSize.Y.Offset + 34)
				}):Play()
			end
		else
			-- CLOSE: Shrink and Fade
			if Shadow then
				TweenService:Create(Shadow, TweenInfo.new(0.4), {ImageTransparency = 1, Size = UDim2.new(0, 0, 0, 0)}):Play()
			end
			
			local tween = TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
				Size = UDim2.new(0, 0, 0, 0),
				BackgroundTransparency = 1
			})
			tween:Play()
			
			task.spawn(function()
				tween.Completed:Wait()
				if not MainFrameVisible then
					MainFrame.Visible = false
					if Shadow then Shadow.Visible = false end
				end
			end)
		end
	end



	
	local TabContainer = Create("ScrollingFrame", {
		Name = "TabContainer",
		Parent = Sidebar,
		Active = true,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 15),
		Size = UDim2.new(1, 0, 1, -25),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.Accent
	})
	
	local ButtonsHolder = Create("Frame", {
		Name = "ButtonsHolder",
		Parent = TabContainer,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.Y
	})
	
	Create("UIListLayout", {
		Parent = ButtonsHolder,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 5)
	})
	
	Create("UIPadding", {
		Parent = ButtonsHolder,
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10)
	})
	
	local SlidingIndicator = Create("Frame", {
		Name = "SlidingIndicator",
		Parent = TabContainer,
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(0, 3, 0, 20),
		Visible = false,
		ZIndex = 2
	})

	Create("UICorner", {
		CornerRadius = UDim.new(1, 0),
		Parent = SlidingIndicator
	})

	
	local ContentContainer = Create("Frame", {
		Name = "ContentContainer",
		Parent = MainFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 160, 0, 45),
		Size = UDim2.new(1, -160, 1, -45)
	})

	MakeDraggable(Header, MainFrame)
	
	-- Shared Dropdown Components (Trix Style Integration)
	local DropdownLayoutOrder = 0
	
	local MoreBlur = Create("Frame", {
		Name = "MoreBlur",
		Parent = MainFrame,
		BackgroundColor3 = Color3.new(0,0,0),
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Visible = false,
		ClipsDescendants = true,
		ZIndex = 2000
	})
	
	local ConnectButton = Create("TextButton", {
		Name = "ConnectButton",
		Parent = MoreBlur,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 2000
	})
	
	local DropdownSelect = Create("Frame", {
		Name = "DropdownSelect",
		Parent = MoreBlur,
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = Theme.Sidebar,
		BorderSizePixel = 0,
		Position = UDim2.new(1, 182, 0.5, 0), -- Start off-screen (right)
		Size = UDim2.new(0, 180, 1, -20),
		ClipsDescendants = false, -- Allow shadow/stroke
		Active = true,
		ZIndex = 2005
	})
	
	Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = DropdownSelect })
	Create("UIStroke", { Color = Theme.Accent, Thickness = 1, Transparency = 0.5, Parent = DropdownSelect })
	
	-- Dropdown Shadow
	Create("ImageLabel", {
		Parent = DropdownSelect,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, -15, 0, -15),
		Size = UDim2.new(1, 30, 1, 30),
		Image = "rbxassetid://6015897843",
		ImageColor3 = Color3.new(0,0,0),
		ImageTransparency = 0.5,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49, 49, 450, 450),
		ZIndex = 2004
	})
	
	local DropdownSelectReal = Create("Frame", {
		Name = "DropdownSelectReal",
		Parent = DropdownSelect,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, -10, 1, -10),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 2005
	})

	local DropdownFolder = Instance.new("Folder", DropdownSelectReal)
	local DropPageLayout = Instance.new("UIPageLayout", DropdownFolder)
	DropPageLayout.SortOrder = Enum.SortOrder.LayoutOrder
	DropPageLayout.EasingStyle = Enum.EasingStyle.Quint
	DropPageLayout.EasingDirection = Enum.EasingDirection.Out
	DropPageLayout.TweenTime = 0.0 -- Instant switch to avoid seeing other dropdowns
	DropPageLayout.FillDirection = Enum.FillDirection.Vertical
    DropPageLayout.ScrollWheelInputEnabled = false -- Disable scrolling pages with wheel
	
	ConnectButton.Activated:Connect(function()
		if MoreBlur.Visible then
			TweenService:Create(MoreBlur, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(DropdownSelect, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { Position = UDim2.new(1, 182, 0.5, 0) }):Play()
			task.wait(0.25)
			MoreBlur.Visible = false
		end
	end)
	


	function Window:CreateTab(options)
		options = options or {}
		local TabName = options.Name or "Tab"
		local TabIcon = Icons[options.Icon] or options.Icon or ""
		
		local Tab = {
			Active = false,
            CurrentSectionContainer = nil
		}
		
		local TabButton = Create("TextButton", {
			Name = TabName .. "Button",
			Parent = ButtonsHolder,
			BackgroundColor3 = Theme.ElementBackground,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 36),
			AutoButtonColor = false,
			ClipsDescendants = true,
			Text = ""
		})
		
		Create("UICorner", {
			CornerRadius = UDim.new(0, 6),
			Parent = TabButton
		})
		
		Create("UIStroke", {
			Color = Theme.Outline,
			Transparency = 0.8,
			Thickness = 1,
			Parent = TabButton
		})
		
		local IconImage
		if TabIcon ~= "" then
			IconImage = Create("ImageLabel", {
				Parent = TabButton,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 10, 0.5, -10),
				Size = UDim2.new(0, 20, 0, 20),
				Image = TabIcon,
				ImageColor3 = Theme.TextSecondary
			})
		end
		
		local TabLabel = Create("TextLabel", {
			Parent = TabButton,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, TabIcon ~= "" and 40 or 15, 0, 0),
			Size = UDim2.new(1, TabIcon ~= "" and -40 or -15, 1, 0),
			Font = Enum.Font.GothamMedium,
			Text = TabName,
			TextColor3 = Theme.TextSecondary,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left
		})
		
		TabButton.MouseEnter:Connect(function()
			if not Tab.Active then
				TweenService:Create(TabButton, TweenInfo.new(0.2), {BackgroundTransparency = 0.9}):Play()
				TweenService:Create(TabLabel, TweenInfo.new(0.2), {TextColor3 = Theme.TextColor}):Play()
				if IconImage then
					TweenService:Create(IconImage, TweenInfo.new(0.2), {ImageColor3 = Theme.TextColor}):Play()
				end
			end
		end)
		
		TabButton.MouseLeave:Connect(function()
			if not Tab.Active then
				TweenService:Create(TabButton, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
				TweenService:Create(TabLabel, TweenInfo.new(0.2), {TextColor3 = Theme.TextSecondary}):Play()
				if IconImage then
					TweenService:Create(IconImage, TweenInfo.new(0.2), {ImageColor3 = Theme.TextSecondary}):Play()
				end
			end
		end)
		
		local TabPage = Create("ScrollingFrame", {
			Name = TabName .. "Page",
			Parent = ContentContainer,
			Active = true,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			CanvasSize = UDim2.new(0, 0, 0, 0),
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = Theme.Accent,
			Visible = false
		})
		
		Create("UIListLayout", {
			Parent = TabPage,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8)
		})
		
		Create("UIPadding", {
			Parent = TabPage,
			PaddingTop = UDim.new(0, 10),
			PaddingBottom = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 15),
			PaddingRight = UDim.new(0, 10)
		})

		-- Tab Title Header inside Page
		Create("TextLabel", {
			Name = "TabTitle",
			Parent = TabPage,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 40),
			Font = Enum.Font.GothamBold,
			Text = TabName,
			TextColor3 = Theme.TextColor,
			TextSize = 26,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = -1
		})

		function Tab:Activate()
			for _, t in pairs(Window.Tabs) do
				if t ~= Tab then
					TweenService:Create(t.Instance, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
					TweenService:Create(t.Label, TweenInfo.new(0.2), {TextColor3 = Theme.TextSecondary}):Play()
					if t.Icon then
						TweenService:Create(t.Icon, TweenInfo.new(0.2), {ImageColor3 = Theme.TextSecondary}):Play()
					end
					t.Page.Visible = false
					t.Active = false
				end
			end
			
			Tab.Active = true
			TweenService:Create(TabButton, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 0.85}):Play()
			TweenService:Create(TabLabel, TweenInfo.new(0.3), {TextColor3 = Theme.Accent}):Play() 
			if IconImage then
				TweenService:Create(IconImage, TweenInfo.new(0.3), {ImageColor3 = Theme.Accent}):Play()
			end
			
			TabPage.Visible = true
			TabPage.Position = UDim2.new(0, 15, 0, 0)
			TweenService:Create(TabPage, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()

			if not SlidingIndicator.Visible then
				SlidingIndicator.Visible = true
				SlidingIndicator.Position = UDim2.new(0, 0, 0, TabButton.AbsolutePosition.Y - ButtonsHolder.AbsolutePosition.Y + 8)
			end
			
			local targetY = TabButton.AbsolutePosition.Y - ButtonsHolder.AbsolutePosition.Y + 8
			
			TweenService:Create(SlidingIndicator, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Position = UDim2.new(0, 0, 0, targetY)
			}):Play()
		end

		TabButton.MouseButton1Click:Connect(function()
			
			task.spawn(function()
				local Mouse = Players.LocalPlayer:GetMouse()
				local Ripple = Create("Frame", {
					Parent = TabButton,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.8,
					BorderSizePixel = 0,
					Position = UDim2.new(0, Mouse.X - TabButton.AbsolutePosition.X, 0, Mouse.Y - TabButton.AbsolutePosition.Y),
					Size = UDim2.new(0, 0, 0, 0),
					ZIndex = 1
				})
				
				Create("UICorner", {
					CornerRadius = UDim.new(1, 0),
					Parent = Ripple
				})

				local Tween = TweenService:Create(Ripple, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = UDim2.new(0, 150, 0, 150),
					Position = UDim2.new(0, Mouse.X - TabButton.AbsolutePosition.X - 75, 0, Mouse.Y - TabButton.AbsolutePosition.Y - 75),
					BackgroundTransparency = 1
				})
				
				Tween:Play()
				Tween.Completed:Wait()
				Ripple:Destroy()
			end)

			Tab:Activate()
		end)
		
		Tab.Instance = TabButton
		Tab.Label = TabLabel
		Tab.Icon = IconImage
		Tab.Page = TabPage
		table.insert(Window.Tabs, Tab)
		
		if #Window.Tabs == 1 then
			Tab:Activate()
		end

		TabPage.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			TabPage.CanvasSize = UDim2.new(0, 0, 0, TabPage.UIListLayout.AbsoluteContentSize.Y + 20)
		end)

		
		
		function Tab:CreateSection(options)
			options = options or {}
			local SectionName = options.Name or "Section"
			
			local SectionContainer = Create("Frame", {
				Name = "SectionContainer",
				Parent = TabPage,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 32), -- Default height matches header only
				-- AutomaticSize = Enum.AutomaticSize.Y -- DISABLED: We will control this manually
			})

			local SectionHeader = Create("TextButton", {
				Name = "SectionHeader",
				Parent = SectionContainer,
				BackgroundColor3 = Theme.ElementBackground, 
				BackgroundTransparency = 0.5,
				Size = UDim2.new(1, 0, 0, 32),
				AutoButtonColor = false,
				Text = ""
			})
			
			Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = SectionHeader })
			
            -- Header Gradient/Stroke (Optional beautification)
			local HeaderStroke = Create("UIStroke", {
				Color = Theme.Outline,
				Transparency = 0.6,
				Thickness = 1,
				Parent = SectionHeader
			})

			local HeaderLabel = Create("TextLabel", {
				Name = "Title",
				Parent = SectionHeader,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 10, 0, 0),
				Size = UDim2.new(1, -40, 1, 0),
				Font = Enum.Font.GothamBold,
				Text = SectionName,
				TextColor3 = Theme.TextColor,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left
			})
			
			local Chevron = Create("ImageLabel", {
				Name = "Chevron",
				Parent = SectionHeader,
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -26, 0.5, -8),
				Size = UDim2.new(0, 16, 0, 16),
				Image = "rbxassetid://6031091004", -- Arrow
				ImageColor3 = Theme.TextSecondary,
				Rotation = -90 -- Closed by default
			})

			local ContentFrame = Create("Frame", {
				Name = "SectionContent",
				Parent = SectionContainer,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 0, 0, 36), -- Below header
				Size = UDim2.new(1, 0, 0, 0),
				-- AutomaticSize = Enum.AutomaticSize.Y, -- DISABLED: Interfere with manual resizing/collapse
				ClipsDescendants = true,
				Visible = true 
			})
			
			Create("UIListLayout", {
				Parent = ContentFrame,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8)
			})
			
			Create("UIPadding", {
				Parent = ContentFrame,
				PaddingTop = UDim.new(0, 5),
				PaddingBottom = UDim.new(0, 5),
				PaddingLeft = UDim.new(0, 5),
				PaddingRight = UDim.new(0, 5)
			})

			-- Toggle Logic
			local Open = false
			local CanvasSizeConnection

			-- Initial State
			ContentFrame.Size = UDim2.new(1, 0, 0, 0)
			
            -- Helper to get real content height
            local function GetContentHeight()
                local layout = ContentFrame:FindFirstChildOfClass("UIListLayout")
                if layout then
                    return layout.AbsoluteContentSize.Y + 10 -- padding
                end
                return 0
            end

			SectionHeader.MouseButton1Click:Connect(function()
				Open = not Open
				if Open then
                     -- Expand
					TweenService:Create(Chevron, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Rotation = 0}):Play()
                    TweenService:Create(SectionHeader, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.8}):Play()
                    
                    local contentHeight = GetContentHeight()
                    local totalHeight = contentHeight + 40 -- Content + Header + Spacing
                    
                    TweenService:Create(ContentFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.new(1, 0, 0, contentHeight)
                    }):Play()
                    
                    -- Also animate the CONTAINER size so the list below moves
                    TweenService:Create(SectionContainer, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.new(1, 0, 0, totalHeight)
                    }):Play()

                    
                    -- Update automatically if content changes size while open
                    if not CanvasSizeConnection then
                         local layout = ContentFrame:FindFirstChildOfClass("UIListLayout")
                         if layout then
                             CanvasSizeConnection = layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                                 if Open then
                                     local newContentHeight = layout.AbsoluteContentSize.Y + 10
                                     local newTotalHeight = newContentHeight + 40
                                     TweenService:Create(ContentFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, newContentHeight)}):Play()
                                     TweenService:Create(SectionContainer, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, newTotalHeight)}):Play()
                                 end
                             end)
                         end
                    end
				else
                    -- Collapse
					TweenService:Create(Chevron, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Rotation = -90}):Play()
                    TweenService:Create(SectionHeader, TweenInfo.new(0.2), {BackgroundColor3 = Theme.ElementBackground, BackgroundTransparency = 0.5}):Play()
                    
                    TweenService:Create(ContentFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.new(1, 0, 0, 0)
                    }):Play()
                    
                    -- Shrink container back to just Header height
                    TweenService:Create(SectionContainer, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.new(1, 0, 0, 32)
                    }):Play()
                    
                    if CanvasSizeConnection then
                        CanvasSizeConnection:Disconnect()
                        CanvasSizeConnection = nil
                    end
				end
			end)
            
            -- Hover Effect
            SectionHeader.MouseEnter:Connect(function()
                if not Open then
                    TweenService:Create(SectionHeader, TweenInfo.new(0.2), {BackgroundTransparency = 0.3}):Play()
                end
            end)
            SectionHeader.MouseLeave:Connect(function()
                if not Open then
                    TweenService:Create(SectionHeader, TweenInfo.new(0.2), {BackgroundTransparency = 0.5}):Play()
                end
            end)
			
			-- Register as current section
			Tab.CurrentSectionContainer = ContentFrame
		end

        function Tab:CreateParagraph(options)
            options = options or {}
            local Title = options.Title or "Paragraph"
            local Content = options.Content or "Lorem ipsum dolor sit amet."
            
            local ParagraphFrame = Create("Frame", {
                Name = "ParagraphFrame",
                Parent = Tab.CurrentSectionContainer or TabPage,
                BackgroundColor3 = Theme.ElementBackground,
                BackgroundTransparency = 0.5,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y
            })
            
            Create("UICorner", {
                CornerRadius = UDim.new(0, 6),
                Parent = ParagraphFrame
            })
            
            Create("UIStroke", {
                Color = Theme.Outline,
                Transparency = 0.6,
                Thickness = 1,
                Parent = ParagraphFrame
            })
            
            local TitleLabel = Create("TextLabel", {
                Parent = ParagraphFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 8),
                Size = UDim2.new(1, -24, 0, 20),
                Font = Enum.Font.GothamBold,
                Text = Title,
                TextColor3 = Theme.TextColor,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            
            local ContentLabel = Create("TextLabel", {
                Parent = ParagraphFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 32),
                Size = UDim2.new(1, -24, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Font = Enum.Font.Gotham,
                Text = Content,
                TextColor3 = Theme.TextSecondary,
                TextSize = 13,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                RichText = true
            })
            
            Create("UIPadding", {
                Parent = ParagraphFrame,
                PaddingBottom = UDim.new(0, 12)
            })
            
            local ParagraphObject = {
                Title = Title,
                Desc = Content
            }
            
            function ParagraphObject:SetTitle(newTitle)
                self.Title = newTitle
                TitleLabel.Text = newTitle
            end
            
            function ParagraphObject:SetDesc(newDesc)
                self.Desc = newDesc
                ContentLabel.Text = newDesc
            end
            
            function ParagraphObject:GetTitle()
                return self.Title
            end
            
            function ParagraphObject:GetDesc()
                return self.Desc
            end
            
            return ParagraphObject
        end

		function Tab:CreateLabel(options)
			options = options or {}
			local Text = options.Text or "Label"
			
			local LabelFrame = Create("Frame", {
				Name = "LabelFrame",
				Parent = Tab.CurrentSectionContainer or TabPage,
				BackgroundColor3 = Theme.ElementBackground,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 26)
			})
			
			local Label = Create("TextLabel", {
				Parent = LabelFrame,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 5, 0, 0),
				Size = UDim2.new(1, -10, 1, 0),
				Font = Enum.Font.GothamMedium,
				Text = Text,
				TextColor3 = Theme.TextColor,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left
			})
			
			return Label
		end

		function Tab:CreateButton(options)
			options = options or {}
			local ButtonName = options.Name or "Button"
			local SubText = options.SubText
			local Icon = options.Icon
			local Callback = options.Callback or function() end
			
			local ButtonFrame = Create("Frame", {
				Name = "ButtonFrame",
				Parent = Tab.CurrentSectionContainer or TabPage,
				BackgroundColor3 = Theme.ElementBackground,
				BackgroundTransparency = 0.2,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, SubText and 50 or 38),
				ClipsDescendants = true
			})
			
			Create("UICorner", {
				CornerRadius = UDim.new(0, 6),
				Parent = ButtonFrame
			})
			
			local ButtonStroke = Create("UIStroke", {
				Color = Theme.Outline,
				Transparency = 0.5,
				Thickness = 1,
				Parent = ButtonFrame
			})
			
			local Button = Create("TextButton", {
				Name = "Button",
				Parent = ButtonFrame,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				Font = Enum.Font.GothamMedium,
				Text = SubText and "" or ButtonName,
				TextColor3 = Theme.TextColor,
				TextSize = 14,
				AutoButtonColor = false,
				ZIndex = 2
			})
			
			if SubText then
				Create("TextLabel", {
					Parent = Button,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 12, 0, 8),
					Size = UDim2.new(1, -50, 0, 20),
					Font = Enum.Font.GothamBold,
					Text = ButtonName,
					TextColor3 = Theme.TextColor,
					TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Left
				})
				
				Create("TextLabel", {
					Parent = Button,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 12, 0, 26),
					Size = UDim2.new(1, -50, 0, 14),
					Font = Enum.Font.Gotham,
					Text = SubText,
					TextColor3 = Theme.TextSecondary,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left
				})
			end
			
			if Icon then
				Create("ImageLabel", {
					Parent = Button,
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -12, 0.5, 0),
					Size = UDim2.new(0, 20, 0, 20),
					Image = Icon,
					ImageColor3 = Theme.TextSecondary
				})
			end
			
			Button.MouseEnter:Connect(function()
				TweenService:Create(ButtonFrame, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Hover, BackgroundTransparency = 0.1}):Play()
				TweenService:Create(ButtonStroke, TweenInfo.new(0.2), {Color = Theme.Accent, Transparency = 0.2}):Play()
			end)
			
			Button.MouseLeave:Connect(function()
				TweenService:Create(ButtonFrame, TweenInfo.new(0.2), {BackgroundColor3 = Theme.ElementBackground, BackgroundTransparency = 0.2}):Play()
				TweenService:Create(ButtonStroke, TweenInfo.new(0.2), {Color = Theme.Outline, Transparency = 0.5}):Play()
			end)
			
			Button.MouseButton1Click:Connect(function()
				
				task.spawn(function()
					local Mouse = Players.LocalPlayer:GetMouse()
					local Ripple = Create("Frame", {
						Parent = ButtonFrame,
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 0.8,
						BorderSizePixel = 0,
						Position = UDim2.new(0, Mouse.X - ButtonFrame.AbsolutePosition.X, 0, Mouse.Y - ButtonFrame.AbsolutePosition.Y),
						Size = UDim2.new(0, 0, 0, 0),
						ZIndex = 1
					})
					
					Create("UICorner", {
						CornerRadius = UDim.new(1, 0),
						Parent = Ripple
					})

					local Tween = TweenService:Create(Ripple, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Size = UDim2.new(0, 200, 0, 200),
						Position = UDim2.new(0, Mouse.X - ButtonFrame.AbsolutePosition.X - 100, 0, Mouse.Y - ButtonFrame.AbsolutePosition.Y - 100),
						BackgroundTransparency = 1
					})
					
					Tween:Play()
					Tween.Completed:Wait()
					Ripple:Destroy()
				end)

				TweenService:Create(ButtonFrame, TweenInfo.new(0.1), {BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0}):Play()
				task.wait(0.1)
				TweenService:Create(ButtonFrame, TweenInfo.new(0.3), {BackgroundColor3 = Theme.Hover, BackgroundTransparency = 0.1}):Play()
				Callback()
			end)
		end
        function Tab:CreateToggle(options)
            options = options or {}
            local ToggleName = options.Name or "Toggle"
            local SubText = options.SubText
            -- Support both 'Default' and 'Value' for backward compatibility
            local Default = options.Default or options.Value or false
            local Values = options.Values or {}
            local Callback = options.Callback or function() end

            
            local Toggled = Default
            
            local ToggleFrame = Create("Frame", {
                Name = "ToggleFrame",
                Parent = Tab.CurrentSectionContainer or TabPage,
                BackgroundColor3 = Theme.ElementBackground,
                BackgroundTransparency = 0.2,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, SubText and 50 or 38)
            })
            
            Create("UICorner", {
                CornerRadius = UDim.new(0, 6),
                Parent = ToggleFrame
            })
            
            Create("UIStroke", {
                Color = Theme.Outline,
                Transparency = 0.5,
                Thickness = 1,
                Parent = ToggleFrame
            })
            
            local Label = Create("TextLabel", {
                Parent = ToggleFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, SubText and 8 or 0),
                Size = UDim2.new(1, -60, 0, SubText and 20 or 38),
                Font = SubText and Enum.Font.GothamBold or Enum.Font.GothamMedium,
                Text = ToggleName,
                TextColor3 = Theme.TextColor,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center
            })
            
            if SubText then
                Create("TextLabel", {
                    Parent = ToggleFrame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 26),
                    Size = UDim2.new(1, -60, 0, 14),
                    Font = Enum.Font.Gotham,
                    Text = SubText,
                    TextColor3 = Theme.TextSecondary,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Center
                })
            end
            
            local SwitchBg = Create("Frame", {
                Parent = ToggleFrame,
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundColor3 = Toggled and Theme.Accent or Color3.fromRGB(45, 45, 50),
                Position = UDim2.new(1, -12, 0.5, 0),
                Size = UDim2.new(0, 42, 0, 22)
            })
            
            Create("UICorner", {
                CornerRadius = UDim.new(1, 0),
                Parent = SwitchBg
            })
            
            local SwitchCircle = Create("Frame", {
                Parent = SwitchBg,
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Position = UDim2.new(0, Toggled and 22 or 2, 0.5, 0),
                Size = UDim2.new(0, 18, 0, 18)
            })
            
            Create("UICorner", {
                CornerRadius = UDim.new(1, 0),
                Parent = SwitchCircle
            })
            
            local Button = Create("TextButton", {
                Parent = ToggleFrame,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Text = ""
            })
            
            -- Create the object to return
            local ToggleObject = {
                Value = Default
            }

            local function UpdateToggleState(newValue)
                Toggled = newValue
                ToggleObject.Value = Toggled
                
                local TargetColor = Toggled and Theme.Accent or Color3.fromRGB(45, 45, 50)
                local TargetPos = UDim2.new(0, Toggled and 22 or 2, 0.5, 0)
                
                TweenService:Create(SwitchBg, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = TargetColor}):Play()
                TweenService:Create(SwitchCircle, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = TargetPos}):Play()
                
                -- Save to config

                
                if #Values > 0 then
                    Callback(Values[Toggled and 2 or 1]) 
                else
                    Callback(Toggled)
                end
            end
            
            function ToggleObject:Set(newValue)
                -- Type validation: ensure boolean
                if type(newValue) ~= "boolean" then
                    newValue = newValue == true or newValue == "true" or newValue == 1
                end
                UpdateToggleState(newValue)
            end
            
            Button.MouseButton1Click:Connect(function()
                UpdateToggleState(not Toggled)
            end)
            
            if Default then
                UpdateToggleState(true)
            end
            


            local Flag = options.Flag or ToggleName
            if Flag then Window.Flags[Flag] = ToggleObject end

            return ToggleObject
        end


		function Tab:CreateSlider(options)
			options = options or {}
			local SliderName = options.Name or "Slider"
			local Min = options.Min or 0
			local Max = options.Max or 100
			-- Support both 'Default' and 'Value' for backward compatibility
			local Default = options.Default or options.Value or Min
			local Callback = options.Callback or function() end

			
			local SliderFrame = Create("Frame", {
				Name = "SliderFrame",
				Parent = Tab.CurrentSectionContainer or TabPage,
				BackgroundColor3 = Theme.ElementBackground,
				BackgroundTransparency = 0.2,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 55)
			})
			
			Create("UICorner", {
				CornerRadius = UDim.new(0, 6),
				Parent = SliderFrame
			})
			
			Create("UIStroke", {
				Color = Theme.Outline,
				Transparency = 0.5,
				Thickness = 1,
				Parent = SliderFrame
			})
			
			local Label = Create("TextLabel", {
				Parent = SliderFrame,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 12, 0, 8),
				Size = UDim2.new(1, -24, 0, 20),
				Font = Enum.Font.GothamMedium,
				Text = SliderName,
				TextColor3 = Theme.TextColor,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left
			})
			
			local ValueLabel = Create("TextLabel", {
				Parent = SliderFrame,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 12, 0, 8),
				Size = UDim2.new(1, -24, 0, 20),
				Font = Enum.Font.Gotham,
				Text = tostring(Default),
				TextColor3 = Theme.TextSecondary,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Right
			})
			
			local SliderBarBg = Create("Frame", {
				Parent = SliderFrame,
				BackgroundColor3 = Color3.fromRGB(50, 50, 55),
				BackgroundTransparency = 0,
				BorderSizePixel = 0,
				Position = UDim2.new(0, 12, 0, 38),
				Size = UDim2.new(1, -24, 0, 5)
			})
			
			Create("UICorner", {
				CornerRadius = UDim.new(1, 0),
				Parent = SliderBarBg
			})
			
			local SliderFill = Create("Frame", {
				Parent = SliderBarBg,
				BackgroundColor3 = Theme.Accent,
				BorderSizePixel = 0,
				Size = UDim2.new((Default - Min) / (Max - Min), 0, 1, 0)
			})
			
			Create("UICorner", {
				CornerRadius = UDim.new(1, 0),
				Parent = SliderFill
			})
			
			local SliderKnob = Create("Frame", {
				Parent = SliderBarBg,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				Position = UDim2.new((Default - Min) / (Max - Min), 0, 0.5, 0),
				Size = UDim2.new(0, 14, 0, 14),
				ZIndex = 2
			})
			
			Create("UICorner", {
				CornerRadius = UDim.new(1, 0),
				Parent = SliderKnob
			})
			
			local SliderButton = Create("TextButton", {
				Parent = SliderBarBg,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				Text = "",
				ZIndex = 3
			})
			
			local Dragging = false
			
			local function UpdateSlider(Input)
				local SizeX = SliderBarBg.AbsoluteSize.X
				local PosX = SliderBarBg.AbsolutePosition.X
				
				local Percent = math.clamp((Input.Position.X - PosX) / SizeX, 0, 1)
				local Value = math.floor(Min + ((Max - Min) * Percent))
				
				TweenService:Create(SliderFill, TweenInfo.new(0.05), {Size = UDim2.new(Percent, 0, 1, 0)}):Play()
				TweenService:Create(SliderKnob, TweenInfo.new(0.05), {Position = UDim2.new(Percent, 0, 0.5, 0)}):Play()
				ValueLabel.Text = tostring(Value)
				

				
				Callback(Value)
			end
			
			SliderButton.InputBegan:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
					Dragging = true
					TweenService:Create(SliderKnob, TweenInfo.new(0.15), {Size = UDim2.new(0, 18, 0, 18)}):Play()
					UpdateSlider(Input)
				end
			end)
			
			table.insert(Connections, UserInputService.InputEnded:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
					Dragging = false
					TweenService:Create(SliderKnob, TweenInfo.new(0.15), {Size = UDim2.new(0, 14, 0, 14)}):Play()
				end
			end))
			
			table.insert(Connections, UserInputService.InputChanged:Connect(function(Input)
				if Dragging and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
					UpdateSlider(Input)
				end
			end))
			
			local SliderObject = {
				Value = Default
			}
			
			function SliderObject:Set(value)
				-- Type validation: ensure number
				if type(value) ~= "number" then
					value = tonumber(value) or Min
				end
				value = math.clamp(value, Min, Max)
				local percent = (value - Min) / (Max - Min)
				TweenService:Create(SliderFill, TweenInfo.new(0.3), {Size = UDim2.new(percent, 0, 1, 0)}):Play()
				TweenService:Create(SliderKnob, TweenInfo.new(0.3), {Position = UDim2.new(percent, 0, 0.5, 0)}):Play()
				ValueLabel.Text = tostring(value)
				self.Value = value
				

				
				Callback(value)
			end
			

			
			local Flag = options.Flag or SliderName
			if Flag then Window.Flags[Flag] = SliderObject end

			return SliderObject
		end
		
        function Tab:CreateInput(options)
            options = options or {}
            local InputName = options.Name or "Input"
            local Placeholder = options.Placeholder or InputName
            local Default = options.Default or ""
            local Callback = options.Callback or function() end
            local MultiLine = options.MultiLine or false
            local SideLabel = options.SideLabel
            local Value = options.Value or Default
            local Values = options.Values or {}

            
            local InputFrame = Create("Frame", {
                Name = "InputFrame",
                Parent = Tab.CurrentSectionContainer or TabPage,
                BackgroundColor3 = Theme.ElementBackground,
                BackgroundTransparency = 0.2,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, MultiLine and 100 or 40)
            })
            
            Create("UICorner", {
                CornerRadius = UDim.new(0, 6),
                Parent = InputFrame
            })
            
            Create("UIStroke", {
                Color = Theme.Outline,
                Transparency = 0.5,
                Thickness = 1,
                Parent = InputFrame
            })
            
            if SideLabel then
                local Label = Create("TextLabel", {
                    Parent = InputFrame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 0),
                    Size = UDim2.new(0, 0, 1, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    Font = Enum.Font.GothamMedium,
                    Text = SideLabel,
                    TextColor3 = Theme.TextColor,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
            end
            
            local InputBoxBg = Create("Frame", {
                Parent = InputFrame,
                BackgroundColor3 = Theme.Sidebar,
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                Position = SideLabel and UDim2.new(1, -160, 0.5, 0) or UDim2.new(0, 6, 0, 6),
                Size = SideLabel and UDim2.new(0, 150, 0, 28) or UDim2.new(1, -12, 1, -12),
                AnchorPoint = SideLabel and Vector2.new(1, 0.5) or Vector2.new(0, 0)
            })
            
            if SideLabel then
                InputBoxBg.Position = UDim2.new(1, -12, 0.5, 0)
                InputBoxBg.AnchorPoint = Vector2.new(1, 0.5)
            end
            
            Create("UICorner", {
                CornerRadius = UDim.new(0, 4),
                Parent = InputBoxBg
            })
            
            local InputStroke = Create("UIStroke", {
                Color = Theme.Outline,
                Transparency = 0.7,
                Thickness = 1,
                Parent = InputBoxBg
            })
            
            local TextBox = Create("TextBox", {
                Parent = InputBoxBg,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 8, 0, MultiLine and 8 or 0),
                Size = UDim2.new(1, -16, 1, MultiLine and -16 or 0),
                Font = Enum.Font.Gotham,
                PlaceholderText = Placeholder,
                Text = Value or Default,
                TextColor3 = Theme.TextColor,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = MultiLine and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
                ClearTextOnFocus = false,
                MultiLine = MultiLine,
                TextWrapped = true
            })
            
            TextBox.Focused:Connect(function()
                TweenService:Create(InputStroke, TweenInfo.new(0.2), {Color = Theme.Accent, Transparency = 0}):Play()
            end)
            
            local InputObject = {
                Value = Value or Default,
                Values = Values
            }

            TextBox.FocusLost:Connect(function(enterPressed)
                TweenService:Create(InputStroke, TweenInfo.new(0.2), {Color = Theme.Outline, Transparency = 0.7}):Play()
                local newValue = TextBox.Text
                InputObject.Value = newValue
                

                
                Callback(newValue)
            end)
            
            function InputObject:Set(value)
                -- Type validation: ensure string
                if value == nil then
                    value = ""
                end
                value = tostring(value)
                self.Value = value
                TextBox.Text = tostring(value)
                

                
                Callback(tostring(value))
            end
            
            function InputObject:Get()
                return self.Value
            end
            
            if (Value or Default) ~= "" then
                Callback(Value or Default)
            end
            


            local Flag = options.Flag or InputName
            if Flag then Window.Flags[Flag] = InputObject end

            return InputObject
        end
		
        function Tab:CreateDropdown(options)
            options = options or {}
            local DropdownName = options.Name or "Dropdown"
            local Items = options.Items or {}
            local Callback = options.Callback or function() end
            local Default = options.Default

            
            -- Fallback defaults
            if not Default then
                if #Items > 0 then Default = Items[1] else Default = "..." end
            end

            local DropdownObject = {
                Value = Default,
                Items = Items
            }
            
            -- 1. Create Dropdown Button in Tab
            local DropdownFrame = Create("Frame", {
                Name = "DropdownFrame",
                Parent = Tab.CurrentSectionContainer or TabPage,
                BackgroundColor3 = Theme.ElementBackground,
                BackgroundTransparency = 0.2,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 38)
            })
            
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = DropdownFrame })
            Create("UIStroke", { Color = Theme.Outline, Transparency = 0.5, Thickness = 1, Parent = DropdownFrame })
            
            local Label = Create("TextLabel", {
                Parent = DropdownFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(1, -60, 1, 0),
                Font = Enum.Font.GothamMedium,
                Text = DropdownName,
                TextColor3 = Theme.TextColor,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            
            local ValueLabel = Create("TextLabel", {
                Parent = DropdownFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(1, -34, 1, 0),
                Font = Enum.Font.Gotham,
                Text = tostring(Default),
                TextColor3 = Theme.TextSecondary,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Right
            })
            
            local Icon = Create("ImageLabel", {
                Parent = DropdownFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -26, 0.5, -8),
                Size = UDim2.new(0, 16, 0, 16),
                Image = "rbxassetid://6031091004",  
                ImageColor3 = Theme.TextSecondary,
                Rotation = -90
            })
            
            local Button = Create("TextButton", {
                Parent = DropdownFrame,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Text = ""
            })

            -- 2. Create Selection Page in DropdownFolder (Shared)
            local SelectOptionsFrame = Create("Frame", {
                Name = "SelectOptionsFrame",
                Parent = DropdownFolder,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                LayoutOrder = DropdownLayoutOrder
            })
            DropdownLayoutOrder = DropdownLayoutOrder + 1
            
            local SearchBox = Create("TextBox", {
                 Parent = SelectOptionsFrame,
                 BackgroundColor3 = Theme.Background, 
                 BackgroundTransparency = 0.5,
                 BorderSizePixel = 0,
                 Size = UDim2.new(1, 0, 0, 28),
                 Font = Enum.Font.Gotham,
                 PlaceholderText = "Search...",
                 Text = "",
                 TextColor3 = Theme.TextColor,
                 PlaceholderColor3 = Theme.TextSecondary,
                 TextSize = 13,
                 TextXAlignment = Enum.TextXAlignment.Left,
                 ClearTextOnFocus = false
            })
            Create("UIPadding", { Parent = SearchBox, PaddingLeft = UDim.new(0, 8)})
            Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = SearchBox })
             
            local ScrollList = Create("ScrollingFrame", {
                 Name = "ScrollList",
                 Parent = SelectOptionsFrame,
                 BackgroundTransparency = 1,
                 Position = UDim2.new(0, 0, 0, 35),
                 Size = UDim2.new(1, 0, 1, -35),
                 CanvasSize = UDim2.new(0, 0, 0, 0),
                 ScrollBarThickness = 2,
                 ScrollBarImageColor3 = Theme.Accent,
                 BorderSizePixel = 0
            })
             
            local UIList = Create("UIListLayout", {
                 Parent = ScrollList,
                 SortOrder = Enum.SortOrder.LayoutOrder,
                 Padding = UDim.new(0, 4)
            })

            local function Populate(filter)
                filter = filter:lower()
                for _, c in pairs(ScrollList:GetChildren()) do
                    if c:IsA("Frame") then c:Destroy() end
                end
                
                for _, item in ipairs(DropdownObject.Items) do
                    if filter == "" or tostring(item):lower():find(filter) then
                        local ItemFrame = Create("Frame", {
                            Name = "ItemFrame",
                            Parent = ScrollList,
                            BackgroundColor3 = Theme.ElementBackground,
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, 26)
                        })
                        
                        local ItemBtn = Create("TextButton", {
                            Parent = ItemFrame,
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 1, 0),
                            Text = "",
                            AutoButtonColor = false
                        })
                        
                        local isSelected = (tostring(item) == tostring(DropdownObject.Value))
                        
                        local ItemTxt = Create("TextLabel", {
                            Parent = ItemBtn,
                            BackgroundTransparency = 1,
                            Position = UDim2.new(0, 8, 0, 0),
                            Size = UDim2.new(1, -16, 1, 0),
                            Font = Enum.Font.GothamBold,
                            Text = tostring(item),
                            TextColor3 = isSelected and Theme.Accent or Theme.TextSecondary,
                            TextSize = 13,
                            TextXAlignment = Enum.TextXAlignment.Left
                        })
                        
                         ItemBtn.MouseEnter:Connect(function()
                             if tostring(item) ~= tostring(DropdownObject.Value) then
                                 ItemTxt.TextColor3 = Theme.TextColor
                             end
                         end)
                         ItemBtn.MouseLeave:Connect(function()
                             if tostring(item) ~= tostring(DropdownObject.Value) then
                                 ItemTxt.TextColor3 = Theme.TextSecondary
                             end
                         end)
                         
                         ItemBtn.MouseButton1Click:Connect(function()
                             DropdownObject:Set(item)
                             -- Close Menu
                             if MoreBlur.Visible then
                                TweenService:Create(MoreBlur, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
                                TweenService:Create(DropdownSelect, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { Position = UDim2.new(1, 182, 0.5, 0) }):Play()
                                task.wait(0.25)
                                MoreBlur.Visible = false
                            end
                         end)
                    end
                end
                ScrollList.CanvasSize = UDim2.fromOffset(0, UIList.AbsoluteContentSize.Y)
            end
            
            SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                Populate(SearchBox.Text)
            end)
            
            UIList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                 ScrollList.CanvasSize = UDim2.fromOffset(0, UIList.AbsoluteContentSize.Y)
            end)

            Populate("") 

            -- Open Logic
            Button.MouseButton1Click:Connect(function()
                if not MoreBlur.Visible then
                    Populate("") 
                    SearchBox.Text = ""
                    DropPageLayout:JumpTo(SelectOptionsFrame)
                    
                    MoreBlur.Visible = true
                    TweenService:Create(MoreBlur, TweenInfo.new(0.25), { BackgroundTransparency = 0.5 }):Play()
                    TweenService:Create(DropdownSelect, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = UDim2.new(1, -16, 0.5, 0) }):Play()
                end
            end)

            function DropdownObject:Set(value)
                self.Value = value
                ValueLabel.Text = tostring(value)
                

                Callback(value)
            end
            
            function DropdownObject:Refresh(newItems)
                 self.Items = newItems
                 if not table.find(self.Items, self.Value) then
                    self.Value = self.Items[1] or "..."
                    ValueLabel.Text = tostring(self.Value)
                 end
                 Populate("")
            end



            local Flag = options.Flag or DropdownName
            if Flag then Window.Flags[Flag] = DropdownObject end

            return DropdownObject
        end


		
      function Tab:CreateMultiDropdown(options)
            options = options or {}
            local DropdownName = options.Name or "Multi Dropdown"
            local Items = options.Items or options.Values or {}
            local Default = options.Default or options.Value or {}
            local Callback = options.Callback or function() end

            
            -- Ensure Default is table
            if type(Default) ~= "table" then Default = {} end

            local Selected = Default
            local MultiDropdownObject = {
                Value = Selected,
                Values = Items
            }

            -- Button Creation
            local DropdownFrame = Create("Frame", {
                Name = "MultiDropdownFrame",
                Parent = Tab.CurrentSectionContainer or TabPage,
                BackgroundColor3 = Theme.ElementBackground,
                BackgroundTransparency = 0.2,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 38)
            })
            
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = DropdownFrame })
            Create("UIStroke", { Color = Theme.Outline, Transparency = 0.5, Thickness = 1, Parent = DropdownFrame })
            
            local Label = Create("TextLabel", {
                Parent = DropdownFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(1, -60, 1, 0),
                Font = Enum.Font.GothamMedium,
                Text = DropdownName,
                TextColor3 = Theme.TextColor,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            
            local function GetSelectedText()
                if #Selected == 0 then return "None" end
                if #Selected == 1 then return tostring(Selected[1]) end
                return #Selected .. " Selected"
            end

            local ValueLabel = Create("TextLabel", {
                Parent = DropdownFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(1, -34, 1, 0),
                Font = Enum.Font.Gotham,
                Text = GetSelectedText(),
                TextColor3 = Theme.TextSecondary,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Right
            })
            
            local Icon = Create("ImageLabel", {
                Parent = DropdownFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -26, 0.5, -8),
                Size = UDim2.new(0, 16, 0, 16),
                Image = "rbxassetid://6031091004",  
                ImageColor3 = Theme.TextSecondary,
                Rotation = -90
            })
            
            local Button = Create("TextButton", {
                Parent = DropdownFrame,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Text = ""
            })

            -- Shared Drawer Page
            local SelectOptionsFrame = Create("Frame", {
                Name = "SelectOptionsFrame_Multi",
                Parent = DropdownFolder,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                LayoutOrder = DropdownLayoutOrder
            })
            DropdownLayoutOrder = DropdownLayoutOrder + 1
            
            local SearchBox = Create("TextBox", {
                 Parent = SelectOptionsFrame,
                 BackgroundColor3 = Theme.Background, 
                 BackgroundTransparency = 0.5,
                 BorderSizePixel = 0,
                 Size = UDim2.new(1, 0, 0, 28),
                 Font = Enum.Font.Gotham,
                 PlaceholderText = "Search...",
                 Text = "",
                 TextColor3 = Theme.TextColor,
                 PlaceholderColor3 = Theme.TextSecondary,
                 TextSize = 13,
                 TextXAlignment = Enum.TextXAlignment.Left,
                 ClearTextOnFocus = false
            })
            Create("UIPadding", { Parent = SearchBox, PaddingLeft = UDim.new(0, 8)})
            Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = SearchBox })
             
            local ScrollList = Create("ScrollingFrame", {
                 Name = "ScrollList",
                 Parent = SelectOptionsFrame,
                 BackgroundTransparency = 1,
                 Position = UDim2.new(0, 0, 0, 35),
                 Size = UDim2.new(1, 0, 1, -35),
                 CanvasSize = UDim2.new(0, 0, 0, 0),
                 ScrollBarThickness = 2,
                 ScrollBarImageColor3 = Theme.Accent,
                 BorderSizePixel = 0
            })
             
            local UIList = Create("UIListLayout", {
                 Parent = ScrollList,
                 SortOrder = Enum.SortOrder.LayoutOrder,
                 Padding = UDim.new(0, 4)
            })

            local function Populate(filter)
                filter = filter:lower()
                for _, c in pairs(ScrollList:GetChildren()) do
                    if c:IsA("Frame") then c:Destroy() end
                end
                
                for _, item in ipairs(Items) do
                    if filter == "" or tostring(item):lower():find(filter) then
                        local ItemFrame = Create("Frame", {
                            Name = "ItemFrame",
                            Parent = ScrollList,
                            BackgroundColor3 = Theme.ElementBackground,
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, 26)
                        })
                        
                        local ItemBtn = Create("TextButton", {
                            Parent = ItemFrame,
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 1, 0),
                            Text = "",
                            AutoButtonColor = false
                        })
                        
                        local isSelected = table.find(Selected, item)
                        
                        local Checkbox = Create("Frame", {
                            Parent = ItemBtn,
                            BackgroundColor3 = isSelected and Theme.Accent or Theme.Background,
                            BorderSizePixel = 0,
                            Position = UDim2.new(0, 8, 0.5, -7),
                            Size = UDim2.new(0, 14, 0, 14),
                        })
                        Create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = Checkbox })
                        
                        local CheckMark = Create("ImageLabel", {
                             Parent = Checkbox,
                             BackgroundTransparency = 1,
                             Image = "rbxassetid://6031094667",
                             Size = UDim2.new(1,2,1,2),
                             Position = UDim2.new(0,-1,0,-1),
                             ImageTransparency = isSelected and 0 or 1
                        })
                        
                        local ItemTxt = Create("TextLabel", {
                            Parent = ItemBtn,
                            BackgroundTransparency = 1,
                            Position = UDim2.new(0, 30, 0, 0),
                            Size = UDim2.new(1, -30, 1, 0),
                            Font = isSelected and Enum.Font.GothamBold or Enum.Font.GothamMedium,
                            Text = tostring(item),
                            TextColor3 = isSelected and Theme.TextColor or Theme.TextSecondary,
                            TextSize = 13,
                            TextXAlignment = Enum.TextXAlignment.Left
                        })
                        
                         ItemBtn.MouseButton1Click:Connect(function()
                             if table.find(Selected, item) then
                                 table.remove(Selected, table.find(Selected, item))
                                 TweenService:Create(Checkbox, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Background}):Play()
                                 TweenService:Create(CheckMark, TweenInfo.new(0.2), {ImageTransparency = 1}):Play()
                                 TweenService:Create(ItemTxt, TweenInfo.new(0.2), {TextColor3 = Theme.TextSecondary}):Play()
                                 ItemTxt.Font = Enum.Font.GothamMedium
                             else
                                 table.insert(Selected, item)
                                 TweenService:Create(Checkbox, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Accent}):Play()
                                 TweenService:Create(CheckMark, TweenInfo.new(0.2), {ImageTransparency = 0}):Play()
                                 TweenService:Create(ItemTxt, TweenInfo.new(0.2), {TextColor3 = Theme.TextColor}):Play()
                                 ItemTxt.Font = Enum.Font.GothamBold
                             end
                             
                             MultiDropdownObject:UpdateLabel()

                             Callback(Selected)
                         end)
                    end
                end
                ScrollList.CanvasSize = UDim2.fromOffset(0, UIList.AbsoluteContentSize.Y)
            end
            
            SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                Populate(SearchBox.Text)
            end)
            
            UIList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                 ScrollList.CanvasSize = UDim2.fromOffset(0, UIList.AbsoluteContentSize.Y)
            end)

            Populate("") 
            
            Button.MouseButton1Click:Connect(function()
                if not MoreBlur.Visible then
                    Populate("") 
                    SearchBox.Text = ""
                    DropPageLayout:JumpTo(SelectOptionsFrame)
                    
                    MoreBlur.Visible = true
                    TweenService:Create(MoreBlur, TweenInfo.new(0.25), { BackgroundTransparency = 0.5 }):Play()
                    TweenService:Create(DropdownSelect, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = UDim2.new(1, -16, 0.5, 0) }):Play()
                end
            end)

            function MultiDropdownObject:UpdateLabel()
                 ValueLabel.Text = GetSelectedText()
            end

            function MultiDropdownObject:Set(values)
                Selected = values
                MultiDropdownObject:UpdateLabel()
                

                Callback(Selected)
                Populate(SearchBox.Text)
            end
            
            function MultiDropdownObject:Refresh(newItems)
                Items = newItems
                local newSel = {}
                for _, s in pairs(Selected) do
                    if table.find(Items, s) then table.insert(newSel, s) end
                end
                Selected = newSel
                
                MultiDropdownObject:Set(Selected)
            end



            local Flag = options.Flag or DropdownName
            if Flag then Window.Flags[Flag] = MultiDropdownObject end

            return MultiDropdownObject
      end

		
		function Tab:CreateColorPicker(options)
			options = options or {}
			local Name = options.Name or "Color Picker"
			local Default = options.Default or Color3.fromRGB(255, 255, 255)
			local Callback = options.Callback or function() end
			
			local ColorH, ColorS, ColorV = Default:ToHSV()
			local ColorVal = Default
			local Open = false
			
			local PickerFrame = Create("Frame", {
				Name = "PickerFrame",
				Parent = Tab.CurrentSectionContainer or TabPage,
				BackgroundColor3 = Theme.ElementBackground,
				BackgroundTransparency = 0.2,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 38),
				ClipsDescendants = true
			})
			
			Create("UICorner", {
				CornerRadius = UDim.new(0, 6),
				Parent = PickerFrame
			})
			
			Create("UIStroke", {
				Color = Theme.Outline,
				Transparency = 0.5,
				Thickness = 1,
				Parent = PickerFrame
			})
			
			local Label = Create("TextLabel", {
				Parent = PickerFrame,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 12, 0, 0),
				Size = UDim2.new(1, -60, 0, 38),
				Font = Enum.Font.GothamMedium,
				Text = Name,
				TextColor3 = Theme.TextColor,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left
			})
			
			local Preview = Create("Frame", {
				Parent = PickerFrame,
				BackgroundColor3 = Default,
				Position = UDim2.new(1, -40, 0, 9),
				Size = UDim2.new(0, 28, 0, 20)
			})
			
			Create("UICorner", {
				CornerRadius = UDim.new(0, 4),
				Parent = Preview
			})
			
			local Button = Create("TextButton", {
				Parent = PickerFrame,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 38),
				Text = ""
			})
			
			local PickerContainer = Create("Frame", {
				Parent = PickerFrame,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 12, 0, 42),
				Size = UDim2.new(1, -24, 0, 160),
				Visible = true
			})
			
			
			local SVBox = Create("ImageButton", {
				Parent = PickerContainer,
				BackgroundColor3 = Color3.fromHSV(ColorH, 1, 1),
				BorderSizePixel = 0,
				Position = UDim2.new(0, 0, 0, 0),
				Size = UDim2.new(1, 0, 0, 120),
				Image = "rbxassetid://4155801252",
				AutoButtonColor = false
			})
			
			Create("UICorner", {
				CornerRadius = UDim.new(0, 4),
				Parent = SVBox
			})
			
			local SVCursor = Create("Frame", {
				Parent = SVBox,
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				Position = UDim2.new(ColorS, -3, 1 - ColorV, -3),
				Size = UDim2.new(0, 6, 0, 6),
				ZIndex = 2
			})
			
			Create("UICorner", {
				CornerRadius = UDim.new(1, 0),
				Parent = SVCursor
			})
			
			Create("UIStroke", {
				Color = Color3.new(0, 0, 0),
				Thickness = 1,
				Parent = SVCursor
			})
			
			
			local HueBar = Create("ImageButton", {
				Parent = PickerContainer,
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				Position = UDim2.new(0, 0, 1, -24),
				Size = UDim2.new(1, 0, 0, 20),
				AutoButtonColor = false
			})
			
			Create("UICorner", {
				CornerRadius = UDim.new(0, 4),
				Parent = HueBar
			})
			
			Create("UIGradient", {
				Parent = HueBar,
				Rotation = 0,
				Color = ColorSequence.new{
					ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
					ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
					ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
					ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
					ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
					ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
					ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0))
				}
			})
			
			local HueCursor = Create("Frame", {
				Parent = HueBar,
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				Position = UDim2.new(ColorH, -3, 0, -2),
				Size = UDim2.new(0, 6, 1, 4),
				ZIndex = 2
			})
			
			Create("UICorner", {
				CornerRadius = UDim.new(0, 2),
				Parent = HueCursor
			})
			
			Create("UIStroke", {
				Color = Color3.new(0, 0, 0),
				Thickness = 1,
				Parent = HueCursor
			})
			
			
			local function UpdateColor()
				ColorVal = Color3.fromHSV(ColorH, ColorS, ColorV)
				Preview.BackgroundColor3 = ColorVal
				SVBox.BackgroundColor3 = Color3.fromHSV(ColorH, 1, 1)
				Callback(ColorVal)
			end
			
			local DraggingSV = false
			local DraggingHue = false
			
			SVBox.MouseButton1Down:Connect(function()
				DraggingSV = true
			end)
			
			HueBar.MouseButton1Down:Connect(function()
				DraggingHue = true
			end)
			
			table.insert(Connections, UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					DraggingSV = false
					DraggingHue = false
				end
			end))
			
			table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseMovement then
					if DraggingSV then
						local rX = math.clamp((input.Position.X - SVBox.AbsolutePosition.X) / SVBox.AbsoluteSize.X, 0, 1)
						local rY = math.clamp((input.Position.Y - SVBox.AbsolutePosition.Y) / SVBox.AbsoluteSize.Y, 0, 1)
						
						ColorS = rX
						ColorV = 1 - rY
						
						SVCursor.Position = UDim2.new(ColorS, -3, 1 - ColorV, -3)
						UpdateColor()
					elseif DraggingHue then
						local rX = math.clamp((input.Position.X - HueBar.AbsolutePosition.X) / HueBar.AbsoluteSize.X, 0, 1)
						
						ColorH = rX
						HueCursor.Position = UDim2.new(ColorH, -3, 0, -2)
						UpdateColor()
					end
				end
			end))
			
			Button.MouseButton1Click:Connect(function()
				Open = not Open
				TweenService:Create(PickerFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Size = UDim2.new(1, 0, 0, Open and 200 or 38)}):Play()
			end)

            local ColorObject = { Value = Default }
            function ColorObject:Set(val)
                self.Value = val
                ColorVal = val
                local h,s,v = val:ToHSV()
                ColorH, ColorS, ColorV = h, s, v
                Preview.BackgroundColor3 = val
				SVBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
				SVCursor.Position = UDim2.new(s, -3, 1 - v, -3)
				HueCursor.Position = UDim2.new(h, -3, 0, -2)
                Callback(val)
            end
            
            local Flag = options.Flag or Name
            if Flag then Window.Flags[Flag] = ColorObject end

            return ColorObject
		end

		function Tab:CreateKeybind(options)
			options = options or {}
			local KeybindName = options.Name or "Keybind"
			local Default = options.Default or Enum.KeyCode.RightControl
			local Callback = options.Callback or function() end
			local function keybindLabel()
				return (Default == Enum.KeyCode.Unknown) and "None" or Default.Name
			end
			
			local KeybindFrame = Create("Frame", {
				Name = "KeybindFrame",
				Parent = Tab.CurrentSectionContainer or TabPage,
				BackgroundColor3 = Theme.ElementBackground,
				BackgroundTransparency = 0.2,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 38)
			})
			
			Create("UICorner", {
				CornerRadius = UDim.new(0, 6),
				Parent = KeybindFrame
			})
			
			Create("UIStroke", {
				Color = Theme.Outline,
				Transparency = 0.5,
				Thickness = 1,
				Parent = KeybindFrame
			})
			
			local Label = Create("TextLabel", {
				Parent = KeybindFrame,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 12, 0, 0),
				Size = UDim2.new(1, -60, 1, 0),
				Font = Enum.Font.GothamMedium,
				Text = KeybindName,
				TextColor3 = Theme.TextColor,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left
			})
			
			local KeybindButton = Create("TextButton", {
				Parent = KeybindFrame,
				BackgroundColor3 = Theme.Background,
				BackgroundTransparency = 0.5,
				BorderSizePixel = 0,
				Position = UDim2.new(1, -95, 0.5, -12),
				Size = UDim2.new(0, 85, 0, 24),
				Font = Enum.Font.Gotham,
				Text = keybindLabel(),
				TextColor3 = Theme.TextSecondary,
				TextSize = 13,
				ClipsDescendants = true
			})
			
			Create("UICorner", {
				CornerRadius = UDim.new(0, 4),
				Parent = KeybindButton
			})
			
			Create("UIStroke", {
				Color = Theme.Outline,
				Transparency = 0.7,
				Thickness = 1,
				Parent = KeybindButton
			})
			
			local Binding = false

			local function endBindSessionIfMine(cancelFn)
				if KeybindBindSessionCancel == cancelFn then
					KeybindBindSessionCancel = nil
				end
			end

			local finishBindingCancel
			finishBindingCancel = function()
				if not Binding then
					endBindSessionIfMine(finishBindingCancel)
					return
				end
				Binding = false
				KeybindButton.Text = keybindLabel()
				TweenService:Create(KeybindButton, TweenInfo.new(0.2), {TextColor3 = Theme.TextSecondary}):Play()
				endBindSessionIfMine(finishBindingCancel)
			end

			local KeybindObject = { Value = Default }
			function KeybindObject:Set(val)
				self.Value = val
				Default = val
				if val == Enum.KeyCode.Unknown then
					KeybindButton.Text = "None"
				else
					KeybindButton.Text = val.Name
				end
			end

			KeybindButton.MouseButton2Click:Connect(function()
				if Binding and KeybindBindSessionCancel == finishBindingCancel then
					finishBindingCancel()
				end
				Default = Enum.KeyCode.Unknown
				KeybindObject.Value = Default
				KeybindButton.Text = "None"
				TweenService:Create(KeybindButton, TweenInfo.new(0.2), {TextColor3 = Theme.TextSecondary}):Play()
			end)
			
			KeybindButton.MouseButton1Click:Connect(function()
				
				task.spawn(function()
					local Mouse = Players.LocalPlayer:GetMouse()
					local Ripple = Create("Frame", {
						Parent = KeybindButton,
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 0.8,
						BorderSizePixel = 0,
						Position = UDim2.new(0, Mouse.X - KeybindButton.AbsolutePosition.X, 0, Mouse.Y - KeybindButton.AbsolutePosition.Y),
						Size = UDim2.new(0, 0, 0, 0),
						ZIndex = 2
					})
					
					Create("UICorner", {
						CornerRadius = UDim.new(1, 0),
						Parent = Ripple
					})

					local Tween = TweenService:Create(Ripple, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Size = UDim2.new(0, 100, 0, 100),
						Position = UDim2.new(0, Mouse.X - KeybindButton.AbsolutePosition.X - 50, 0, Mouse.Y - KeybindButton.AbsolutePosition.Y - 50),
						BackgroundTransparency = 1
					})
					
					Tween:Play()
					Tween.Completed:Wait()
					Ripple:Destroy()
				end)

				if KeybindBindSessionCancel then
					KeybindBindSessionCancel()
				end
				KeybindBindSessionCancel = finishBindingCancel
				Binding = true
				KeybindButton.Text = "..."
				TweenService:Create(KeybindButton, TweenInfo.new(0.2), {TextColor3 = Theme.Accent}):Play()
			end)
			
			table.insert(Connections, UserInputService.InputBegan:Connect(function(Input)
				if Binding then
					if Input.UserInputType == Enum.UserInputType.Keyboard then
						if Input.KeyCode == Enum.KeyCode.Escape or Input.KeyCode == Enum.KeyCode.Backspace then
							Default = Enum.KeyCode.Unknown
							KeybindObject.Value = Default
							KeybindButton.Text = "None"
							Binding = false
							endBindSessionIfMine(finishBindingCancel)
							TweenService:Create(KeybindButton, TweenInfo.new(0.2), {TextColor3 = Theme.TextSecondary}):Play()
						else
							Default = Input.KeyCode
							KeybindObject.Value = Default
							KeybindButton.Text = Default.Name
							Binding = false
							endBindSessionIfMine(finishBindingCancel)
							TweenService:Create(KeybindButton, TweenInfo.new(0.2), {TextColor3 = Theme.TextSecondary}):Play()
							Callback(Default)
						end
					elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
						finishBindingCancel()
					end
				else
					if Default ~= Enum.KeyCode.Unknown and Input.KeyCode == Default then
						Callback(Default)
					end
				end
			end))

            local Flag = options.Flag or KeybindName
            if Flag then Window.Flags[Flag] = KeybindObject end

            return KeybindObject
		end

		return Tab
	end

	function Window:SaveConfig(folderName, fileName)
		if not writefile then
			return false, "writefile unavailable"
		end

		local configVersion = "1.0.3"
		local config = { _version = configVersion }
		for flag, obj in pairs(Window.Flags) do
			local val = obj.Value
			if typeof(val) == "Color3" then
				val = { r = val.R, g = val.G, b = val.B, isColor = true }
			elseif typeof(val) == "EnumItem" then
				val = { name = val.Name, isKeybind = true }
			end
			config[flag] = val
		end

		if isfolder and not isfolder(folderName) and makefolder then
			makefolder(folderName)
		end

		local path = folderName .. "/" .. fileName .. ".json"
		local success, err = pcall(function()
			writefile(path, HttpService:JSONEncode(config))
		end)
		if not success then
			return false, tostring(err)
		end

		return true
	end

	function Window:LoadConfig(folderName, fileName)
		if not (isfile and readfile) then
			return false, "readfile unavailable"
		end

		local path = folderName .. "/" .. fileName .. ".json"
		if not isfile(path) then
			return false, "config not found"
		end

		local success, decoded = pcall(function()
			return HttpService:JSONDecode(readfile(path))
		end)
		if not success or type(decoded) ~= "table" then
			return false, "invalid config"
		end

		if decoded._version and decoded._version ~= "1.0.3" then
			return false, "config version mismatch"
		end

		for flag, val in pairs(decoded) do
			if flag ~= "_version" and Window.Flags[flag] then
				if type(val) == "table" then
					if val.isColor and val.r and val.g and val.b then
						val = Color3.new(val.r, val.g, val.b)
					elseif val.isKeybind and val.name then
						val = Enum.KeyCode[val.name]
					end
				end
				Window.Flags[flag]:Set(val)
			end
		end

		return true
	end

	function Window:Destroy()
		ScreenGui:Destroy()
		for _, connection in pairs(Connections) do
			connection:Disconnect()
		end
		Connections = {}
	end

	return Window
end

function VoraLib:Destroy()
	for _, connection in pairs(Connections) do
		connection:Disconnect()
	end
	Connections = {}
	
	if RunService:IsStudio() then
		local gui = Players.LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("VoraHub")
		if gui then gui:Destroy() end
	else
		local gui = CoreGui:FindFirstChild("VoraHub")
		if gui then gui:Destroy() end
	end
end

return VoraLib
