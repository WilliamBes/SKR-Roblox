-- Œufs, familiers (bonus de gains) et familiers qui suivent le joueur.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local EconomyService = require(script.Parent.EconomyService)

local PetService = {}

local remotes: Folder
local random = Random.new()
local folder: Folder
local followers: { [Player]: { Part } } = {}

local function rollPet(egg): string
	local total = 0
	for _, weight in egg.weights do
		total += weight
	end
	local roll = random:NextNumber() * total
	-- Parcours dans un ordre fixe pour un tirage reproductible
	for _, key in Config.PetOrder do
		local weight = egg.weights[key]
		if weight then
			if roll < weight then
				return key
			end
			roll -= weight
		end
	end
	return Config.PetOrder[1]
end

local function rebuildFollowers(player: Player)
	for _, part in followers[player] or {} do
		part:Destroy()
	end
	local list = {}
	local data = EconomyService.data(player)
	if data then
		for _, key in Config.equippedPets(data.pets) do
			local info = Config.Pets[key]
			local pet = Instance.new("Part")
			pet.Name = "Familier_" .. key
			pet.Shape = Enum.PartType.Ball
			pet.Size = Vector3.one * info.size
			pet.Color = info.color
			pet.Material = Enum.Material.Neon
			pet.Anchored = true
			pet.CanCollide = false
			pet.CanQuery = false
			pet.CastShadow = false
			local light = Instance.new("PointLight")
			light.Color = info.color
			light.Range = 8
			light.Parent = pet
			local trail = Instance.new("ParticleEmitter")
			trail.Color = ColorSequence.new(info.color)
			trail.Size = NumberSequence.new(0.5, 0)
			trail.Lifetime = NumberRange.new(0.4)
			trail.Rate = 12
			trail.Speed = NumberRange.new(0)
			trail.LightEmission = 1
			trail.Parent = pet
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if root then
				pet.CFrame = root.CFrame
			else
				pet.Position = Vector3.new(0, -500, 0) -- caché sous la carte jusqu'à l'arrivée du personnage
			end
			pet.Parent = folder
			table.insert(list, pet)
		end
	end
	followers[player] = list
end

local function hatch(player: Player, eggKey: any)
	local data = EconomyService.data(player)
	local egg = typeof(eggKey) == "string" and Config.Eggs[eggKey]
	if not data or not egg or data.cash < egg.cost then
		return
	end
	data.cash -= egg.cost
	local petKey = rollPet(egg)
	data.pets[petKey] = (data.pets[petKey] or 0) + 1
	remotes.Hatched:FireClient(player, petKey)
	if petKey == "Phoenix" then
		remotes.Announce:FireAllClients("msg_pet_rare", { player.DisplayName }, "legendary")
	end
	rebuildFollowers(player)
	EconomyService.pushState(player)
end

function PetService.setupPlayer(player: Player, _data)
	rebuildFollowers(player)
end

function PetService.init(remoteFolder: Folder)
	remotes = remoteFolder
	folder = Instance.new("Folder")
	folder.Name = "Familiers"
	folder.Parent = workspace

	EconomyService.registerAction("hatch", hatch)
	EconomyService.registerMultiplier(function(_player, data)
		return 1 + Config.petBonus(data.pets)
	end)
	EconomyService.registerStateExtra(function(_player, data, state)
		state.pets = data.pets
		state.petBonus = Config.petBonus(data.pets)
	end)

	Players.PlayerRemoving:Connect(function(player)
		for _, part in followers[player] or {} do
			part:Destroy()
		end
		followers[player] = nil
	end)

	-- Les familiers flottent derrière leur propriétaire
	RunService.Heartbeat:Connect(function(dt)
		local alpha = math.min(1, dt * 8)
		local t = os.clock()
		for player, list in followers do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if root then
				for i, pet in list do
					local side = (i - (#list + 1) / 2) * 3.2
					local target = root.CFrame * CFrame.new(side, 1.5 + math.sin(t * 2 + i) * 0.4, 3.5)
					pet.CFrame = pet.CFrame:Lerp(target, alpha)
				end
			end
		end
	end)
end

return PetService
