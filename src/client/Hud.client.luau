-- Hud.client.luau (client) — StarterPlayerScripts
-- The SAHUR BASE screen: cash and income across the top centre (clear of Roblox's own top-left
-- menu), Lock and Rebirth buttons down the right side, toast notifications, a CARRYING banner,
-- and the wiring that turns slap-tool taps into server slaps.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local notifyRemote = remotes:WaitForChild("Notify")
local hudStateRemote = remotes:WaitForChild("HudState")
local hudActionRemote = remotes:WaitForChild("HudAction")
local slapRemote = remotes:WaitForChild("Slap")

local function formatCash(amount: number): string
	local digits = tostring(math.floor(math.abs(amount)))
	local grouped = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
	return "$" .. grouped
end

local gui = Instance.new("ScreenGui")
gui.Name = "SahurHud"
gui.ResetOnSpawn = false
gui.DisplayOrder = 5
gui.Parent = player:WaitForChild("PlayerGui")

local function corner(instance, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = instance
end

-- Cash panel, top centre
local cashPanel = Instance.new("Frame")
cashPanel.Name = "CashPanel"
cashPanel.AnchorPoint = Vector2.new(0.5, 0)
cashPanel.Position = UDim2.new(0.5, 0, 0, 10)
cashPanel.Size = UDim2.fromOffset(360, 76)
cashPanel.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
cashPanel.BackgroundTransparency = 0.15
cashPanel.BorderSizePixel = 0
cashPanel.Parent = gui
corner(cashPanel, 14)

local cashLabel = Instance.new("TextLabel")
cashLabel.Name = "Cash"
cashLabel.Size = UDim2.new(1, 0, 0, 42)
cashLabel.Position = UDim2.fromOffset(0, 4)
cashLabel.BackgroundTransparency = 1
cashLabel.Font = Enum.Font.GothamBlack
cashLabel.TextSize = 30
cashLabel.TextColor3 = Color3.fromRGB(255, 224, 92)
cashLabel.Text = "$100"
cashLabel.Parent = cashPanel

local incomeLabel = Instance.new("TextLabel")
incomeLabel.Name = "Income"
incomeLabel.Size = UDim2.new(1, 0, 0, 24)
incomeLabel.Position = UDim2.fromOffset(0, 47)
incomeLabel.BackgroundTransparency = 1
incomeLabel.Font = Enum.Font.GothamBold
incomeLabel.TextSize = 16
incomeLabel.TextColor3 = Color3.fromRGB(150, 255, 160)
incomeLabel.Text = "+$0/s"
incomeLabel.Parent = cashPanel

-- Toast notification under the cash panel
local toast = Instance.new("TextLabel")
toast.Name = "Toast"
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.Position = UDim2.new(0.5, 0, 0, 96)
toast.Size = UDim2.fromOffset(720, 36)
toast.BackgroundTransparency = 1
toast.Font = Enum.Font.GothamBold
toast.TextSize = 21
toast.TextColor3 = Color3.fromRGB(255, 255, 255)
toast.TextStrokeTransparency = 0.25
toast.Text = ""
toast.Parent = gui

local toastToken = 0
local function showToast(text: string)
	toastToken += 1
	local token = toastToken
	toast.Text = text
	toast.TextTransparency = 0
	toast.TextStrokeTransparency = 0.25
	task.delay(3.6, function()
		if token == toastToken then
			TweenService:Create(toast, TweenInfo.new(0.6), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end
notifyRemote.OnClientEvent:Connect(showToast)

-- CARRYING banner
local carryBanner = Instance.new("TextLabel")
carryBanner.Name = "Carrying"
carryBanner.AnchorPoint = Vector2.new(0.5, 0)
carryBanner.Position = UDim2.new(0.5, 0, 0, 134)
carryBanner.Size = UDim2.fromOffset(520, 34)
carryBanner.BackgroundColor3 = Color3.fromRGB(214, 40, 48)
carryBanner.BackgroundTransparency = 0.25
carryBanner.BorderSizePixel = 0
carryBanner.Font = Enum.Font.GothamBlack
carryBanner.TextSize = 20
carryBanner.TextColor3 = Color3.fromRGB(255, 255, 255)
carryBanner.Text = "CARRYING A BRAINROT — RUN HOME!"
carryBanner.Visible = false
carryBanner.Parent = gui
corner(carryBanner, 10)

-- Action buttons down the right side
local function makeButton(name, yOffset, color, text)
	local button = Instance.new("TextButton")
	button.Name = name
	button.AnchorPoint = Vector2.new(1, 0)
	button.Position = UDim2.new(1, -14, 0, yOffset)
	button.Size = UDim2.fromOffset(178, 58)
	button.BackgroundColor3 = color
	button.BackgroundTransparency = 0.1
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.TextSize = 16
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Text = text
	button.AutoButtonColor = true
	button.Parent = gui
	corner(button, 12)
	return button
end

local lockButton = makeButton("LockButton", 120, Color3.fromRGB(24, 130, 150), "LOCK BASE")
local rebirthButton = makeButton("RebirthButton", 188, Color3.fromRGB(176, 44, 110), "REBIRTH")

lockButton.MouseButton1Click:Connect(function()
	hudActionRemote:FireServer("lock")
end)
rebirthButton.MouseButton1Click:Connect(function()
	hudActionRemote:FireServer("rebirth")
end)

-- A one-line reminder of the loop, bottom centre
local hint = Instance.new("TextLabel")
hint.Name = "Hint"
hint.AnchorPoint = Vector2.new(0.5, 1)
hint.Position = UDim2.new(0.5, 0, 1, -8)
hint.Size = UDim2.fromOffset(760, 22)
hint.BackgroundTransparency = 1
hint.Font = Enum.Font.Gotham
hint.TextSize = 14
hint.TextColor3 = Color3.fromRGB(255, 255, 255)
hint.TextTransparency = 0.35
hint.Text = "Buy brainrots from the belt - steal from rival bases - slap thieves who grab yours!"
hint.Parent = gui

-- Live state
local stats = { Multiplier = 1, LockLeft = 0, LockCooldownLeft = 0, Carrying = false, RebirthCost = 0 }
local leaderstats = player:WaitForChild("leaderstats")
local cashValue = leaderstats:WaitForChild("Cash")
local incomeValue = leaderstats:WaitForChild("Income")
local rebirthsValue = leaderstats:WaitForChild("Rebirths")

local function refresh()
	cashLabel.Text = formatCash(cashValue.Value)
	incomeLabel.Text = string.format("+$%s/s   x%.1f multiplier   %d rebirths", tostring(incomeValue.Value), stats.Multiplier, rebirthsValue.Value)
	carryBanner.Visible = stats.Carrying
	if stats.LockLeft > 0 then
		lockButton.Text = string.format("LOCKED %ds", stats.LockLeft)
	elseif stats.LockCooldownLeft > 0 then
		lockButton.Text = string.format("LOCK (%ds)", stats.LockCooldownLeft)
	else
		lockButton.Text = "LOCK BASE"
	end
	rebirthButton.Text = "REBIRTH\n" .. formatCash(stats.RebirthCost)
end

cashValue.Changed:Connect(refresh)
incomeValue.Changed:Connect(refresh)
rebirthsValue.Changed:Connect(refresh)
hudStateRemote.OnClientEvent:Connect(function(state)
	stats = state
	refresh()
end)
refresh()

-- Slap tool: a tap with the glove equipped is a slap, judged on the server
local function watchForSlapHand(container: Instance)
	local function hook(tool: Instance)
		if tool:IsA("Tool") and tool.Name == "SlapHand" then
			tool.Activated:Connect(function()
				slapRemote:FireServer()
			end)
		end
	end
	for _, child in ipairs(container:GetChildren()) do
		hook(child)
	end
	container.ChildAdded:Connect(hook)
end
watchForSlapHand(player:WaitForChild("Backpack"))
player.CharacterAdded:Connect(function(character)
	watchForSlapHand(character)
end)
if player.Character then
	watchForSlapHand(player.Character)
end
