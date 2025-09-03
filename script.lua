
--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Backpack = LocalPlayer.Backpack
local PlayerGui = LocalPlayer.PlayerGui
local Leaderstats = LocalPlayer:WaitForChild("leaderstats")
local Coins = Leaderstats:WaitForChild("Sheckles")

--// Game Info
local GameInfo = MarketplaceService:GetProductInfo(game.PlaceId)

--// UI Library
local ReGui = loadstring(game:HttpGet("https://raw.githubusercontent.com/depthso/Dear-ReGui/refs/heads/main/ReGui.lua"))()
local PrefabsId = "rbxassetid://" .. ReGui.PrefabsId

--// Theme (blue focused)
local ThemeColors = {
    DarkBlue  = Color3.fromRGB(20, 40, 70),
    MidBlue   = Color3.fromRGB(45, 90, 160),
    LightBlue = Color3.fromRGB(100, 160, 230),
}

ReGui:Init({
	Prefabs = InsertService:LoadLocalAsset(PrefabsId)
})
ReGui:DefineTheme("BlueFarmTheme", {
	WindowBg = ThemeColors.DarkBlue,
	TitleBarBg = ThemeColors.MidBlue,
	TitleBarBgActive = ThemeColors.LightBlue,
    ResizeGrab = ThemeColors.LightBlue,
    FrameBg = ThemeColors.MidBlue,
    FrameBgActive = ThemeColors.LightBlue,
	CollapsingHeaderBg = ThemeColors.MidBlue,
    ButtonsBg = ThemeColors.LightBlue,
    CheckMark = ThemeColors.LightBlue,
    SliderGrab = ThemeColors.LightBlue,
})

--// References
local GameEvents = ReplicatedStorage.GameEvents
local Farms = workspace.Farm
local MyFarm = Farms:FindFirstChild(LocalPlayer.Name)

--// Globals
local AutoPlant, AutoHarvest, AutoSell, AutoWalk, NoClip
local SellThreshold, SelectedSeed

--// Utility
local function Plant(Position: Vector3, Seed: string)
	GameEvents.Plant_RE:FireServer(Position, Seed)
	task.wait(.25)
end

local function HarvestPlant(Plant: Model)
	local Prompt = Plant:FindFirstChild("ProximityPrompt", true)
	if Prompt and Prompt.Enabled then
		fireproximityprompt(Prompt)
	end
end

local function SellInventory()
	local Character = LocalPlayer.Character
	local Prev = Character:GetPivot()
	local Before = Coins.Value

	Character:PivotTo(CFrame.new(62, 4, -26))
	repeat 
		GameEvents.Sell_Inventory:FireServer()
		task.wait()
	until Coins.Value ~= Before

	Character:PivotTo(Prev)
end

--// Main Loops
local function PlantLoop()
	local Seeds = Backpack:GetChildren()
	for _, Tool in ipairs(Seeds) do
		if Tool:IsA("Tool") and Tool.Name == SelectedSeed.Selected then
			for i = 1, 10 do
				local x, z = math.random(-15, 15), math.random(-15, 15)
				Plant(Vector3.new(x, 0.2, z), Tool.Name)
			end
		end
	end
end

local function HarvestLoop()
	for _, Plant in ipairs(MyFarm.Important.Plants_Physical:GetChildren()) do
		HarvestPlant(Plant)
	end
end

local function SellCheck()
	if #Backpack:GetChildren() >= SellThreshold.Value then
		SellInventory()
	end
end

local function WalkLoop()
	local Humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if not Humanoid then return end

	local Plants = MyFarm.Important.Plants_Physical:GetChildren()
	if #Plants > 0 then
		local Plant = Plants[math.random(1, #Plants)]
		Humanoid:MoveTo(Plant:GetPivot().Position)
	else
		local randomPos = Vector3.new(math.random(-15,15), 0.2, math.random(-15,15))
		Humanoid:MoveTo(randomPos)
	end
end

local function NoclipLoop()
	if not NoClip.Value then return end
	local Character = LocalPlayer.Character
	if not Character then return end
	for _, Part in ipairs(Character:GetDescendants()) do
		if Part:IsA("BasePart") then
			Part.CanCollide = false
		end
	end
end

--// Loop Helper
local function MakeLoop(Toggle, Func, Delay)
	coroutine.wrap(function()
		while task.wait(Delay or .2) do
			if Toggle.Value then Func() end
		end
	end)()
end

--// UI
local Window = ReGui:Window({
	Title = "Grow A Garden | Glacier",
    Theme = "BlueFarmTheme",
	Size = UDim2.fromOffset(300, 180)
})

-- Plant
local PlantNode = Window:TreeNode({Title="Planting 🌱"})
SelectedSeed = PlantNode:Combo({
	Label = "Choose Seed",
	Selected = "",
	GetItems = function()
		local items = {}
		for _, v in ipairs(Backpack:GetChildren()) do
			if v:IsA("Tool") then items[v.Name] = 1 end
		end
		return items
	end
})
AutoPlant = PlantNode:Checkbox({Label="Auto-Plant", Value=false})

-- Harvest
local HarvestNode = Window:TreeNode({Title="Harvesting 🌾"})
AutoHarvest = HarvestNode:Checkbox({Label="Auto-Harvest", Value=false})

-- Sell
local SellNode = Window:TreeNode({Title="Selling 💰"})
AutoSell = SellNode:Checkbox({Label="Auto-Sell", Value=false})
SellThreshold = SellNode:SliderInt({
	Label="Crop Limit",
	Value=10,
	Minimum=1,
	Maximum=100,
})

-- Walk
local WalkNode = Window:TreeNode({Title="Movement 🚶"})
AutoWalk = WalkNode:Checkbox({Label="Auto-Walk", Value=false})
NoClip = WalkNode:Checkbox({Label="No Clip", Value=false})

-- Connections
RunService.Stepped:Connect(NoclipLoop)

-- Start Loops
MakeLoop(AutoPlant, PlantLoop, 1)
MakeLoop(AutoHarvest, HarvestLoop, .5)
MakeLoop(AutoSell, SellCheck, 2)
MakeLoop(AutoWalk, WalkLoop, 3)
