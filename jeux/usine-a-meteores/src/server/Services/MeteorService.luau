-- Fait tomber les météores sur chaque usine et gère leur ramassage.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage.Shared.Config)
local EconomyService = require(script.Parent.EconomyService)
local PassService = require(script.Parent.PassService)
local PlotService = require(script.Parent.PlotService)

local MeteorService = {}

local remotes: Folder
local timers: { [number]: number } = {}
local random = Random.new()

local function rollRarity(player: Player, forceLegendary: boolean?)
	if forceLegendary then
		return Config.Rarities[#Config.Rarities]
	end
	local luck = PassService.owns(player, "LuckyMeteors") and Config.LuckyMultiplier or 1
	local roll = random:NextNumber()
	-- On parcourt du plus rare au plus commun
	for i = #Config.Rarities, 2, -1 do
		local rarity = Config.Rarities[i]
		local chance = rarity.chance * luck
		if roll < chance then
			return rarity
		end
		roll -= chance
	end
	return Config.Rarities[1]
end

local function collect(player: Player, meteor: BasePart)
	if meteor:GetAttribute("Collected") then
		return
	end
	meteor:SetAttribute("Collected", true)
	local data = EconomyService.data(player)
	if data then
		data.meteorsCollected += 1
	end
	local earned = EconomyService.earn(player, meteor:GetAttribute("Value") or 0)
	remotes.Collected:FireClient(player, earned, meteor.Position, meteor:GetAttribute("Rarity"))
	meteor:Destroy()
end

function MeteorService.spawn(plot, forceLegendary: boolean?)
	local player = plot.owner
	if not player then
		return
	end
	if #plot.meteors:GetChildren() >= Config.Meteor.maxOnPlot and not forceLegendary then
		return
	end
	local data = EconomyService.data(player)
	if not data then
		return
	end

	local rarity = rollRarity(player, forceLegendary)
	local half = Config.Plot.size / 2 - 6
	local landing = (plot.base.CFrame * CFrame.new(random:NextNumber(-half, half), 0, random:NextNumber(-half, half))).Position
	landing += Vector3.new(0, 0.5 + rarity.size / 2, 0)

	local meteor = Instance.new("Part")
	meteor.Name = "Meteore"
	meteor.Shape = Enum.PartType.Ball
	meteor.Size = Vector3.one * rarity.size
	meteor.Color = rarity.color
	meteor.Material = Enum.Material.Neon
	meteor.Anchored = true
	meteor.CanCollide = false
	meteor.CanQuery = false
	meteor.CastShadow = false
	meteor.Position = landing + Vector3.new(random:NextNumber(-30, 30), Config.Meteor.fallHeight, random:NextNumber(-30, 30))
	meteor:SetAttribute("Value", Config.meteorValue(data.upgrades.MeteorValue) * rarity.multiplier)
	meteor:SetAttribute("Rarity", rarity.key)
	meteor:SetAttribute("Landed", false)

	local fire = Instance.new("Fire")
	fire.Color = rarity.color
	fire.SecondaryColor = Color3.new(1, 1, 1)
	fire.Size = rarity.size * 2
	fire.Heat = 15
	fire.Parent = meteor

	local light = Instance.new("PointLight")
	light.Color = rarity.color
	light.Range = rarity.size * 4
	light.Brightness = 2
	light.Parent = meteor

	meteor.Parent = plot.meteors

	local tween = TweenService:Create(meteor, TweenInfo.new(Config.Meteor.fallTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = landing,
	})
	tween.Completed:Connect(function()
		if meteor.Parent == nil then
			return
		end
		fire.Enabled = false
		meteor:SetAttribute("Landed", true)
		remotes.Impact:FireAllClients(landing, rarity.key)
		if rarity.key == "Légendaire" then
			remotes.Announce:FireAllClients("msg_legendary", { player.DisplayName }, "legendary")
		end
		if PassService.owns(player, "AutoCollect") then
			task.delay(0.4, function()
				if meteor.Parent and plot.owner == player then
					collect(player, meteor)
				end
			end)
		end
	end)
	tween:Play()
	Debris:AddItem(meteor, Config.Meteor.fallTime + Config.Meteor.lifetime)
end

-- Pluie de météores (produit Robux)
function MeteorService.shower(player: Player, count: number, legendaries: number)
	local plot = PlotService.get(player)
	if not plot then
		return
	end
	task.spawn(function()
		for i = 1, count do
			MeteorService.spawn(plot, i <= legendaries)
			task.wait(0.12)
		end
	end)
end

function MeteorService.init(remoteFolder: Folder)
	remotes = remoteFolder

	-- Apparition des météores
	RunService.Heartbeat:Connect(function(dt)
		for _, plot in PlotService.all() do
			local player = plot.owner
			local data = player and EconomyService.data(player)
			if data then
				timers[plot.index] = (timers[plot.index] or 0) + dt
				local interval = Config.meteorInterval(data.upgrades.SpawnRate)
				if timers[plot.index] >= interval then
					timers[plot.index] = 0
					MeteorService.spawn(plot)
				end
			else
				timers[plot.index] = 0
			end
		end
	end)

	-- Ramassage : il suffit de passer à côté d'un météore posé
	task.spawn(function()
		while true do
			task.wait(0.15)
			for _, plot in PlotService.all() do
				local player = plot.owner
				local character = player and player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				local data = player and EconomyService.data(player)
				if root and data then
					local radius = Config.magnetRadius(data.upgrades.Magnet)
					for _, meteor in plot.meteors:GetChildren() do
						if meteor:GetAttribute("Landed") and (meteor.Position - root.Position).Magnitude <= radius then
							collect(player :: Player, meteor)
						end
					end
				end
			end
		end
	end)
end

return MeteorService
