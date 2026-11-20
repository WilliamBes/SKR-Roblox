-- Construit la carte (sol, spawn, parcelles) et attribue une usine à chaque joueur.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

export type Plot = {
	index: number,
	model: Model,
	base: BasePart,
	meteors: Folder,
	refinery: BasePart,
	label: TextLabel,
	owner: Player?,
}

local PlotService = {}
local plots: { Plot } = {}

local function part(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(p :: any)[k] = v
	end
	return p
end

local function buildPlot(map: Folder, index: number, center: Vector3): Plot
	local model = Instance.new("Model")
	model.Name = "Usine" .. index

	local size = Config.Plot.size
	local base = part({
		Name = "Base",
		Size = Vector3.new(size, 1, size),
		CFrame = CFrame.lookAt(center, Vector3.new(0, center.Y, 0)),
		Color = Color3.fromRGB(45, 42, 58),
		Material = Enum.Material.Slate,
		Parent = model,
	})

	-- Bordure lumineuse
	for _, offset in { Vector3.new(size / 2, 0, 0), Vector3.new(-size / 2, 0, 0) } do
		part({
			Size = Vector3.new(1, 1.4, size),
			CFrame = base.CFrame * CFrame.new(offset),
			Color = Color3.fromRGB(255, 120, 40),
			Material = Enum.Material.Neon,
			Parent = model,
		})
	end
	for _, offset in { Vector3.new(0, 0, size / 2), Vector3.new(0, 0, -size / 2) } do
		part({
			Size = Vector3.new(size, 1.4, 1),
			CFrame = base.CFrame * CFrame.new(offset),
			Color = Color3.fromRGB(255, 120, 40),
			Material = Enum.Material.Neon,
			Parent = model,
		})
	end

	-- Raffinerie : grandit avec son niveau
	local refinery = part({
		Name = "Raffinerie",
		Size = Vector3.new(8, 6, 8),
		CFrame = base.CFrame * CFrame.new(0, 3.5, size / 2 - 8),
		Color = Color3.fromRGB(110, 110, 130),
		Material = Enum.Material.DiamondPlate,
		Parent = model,
	})
	local smoke = Instance.new("Smoke")
	smoke.Color = Color3.fromRGB(200, 120, 60)
	smoke.RiseVelocity = 4
	smoke.Size = 2
	smoke.Enabled = false
	smoke.Parent = refinery

	-- Panneau avec le nom du propriétaire
	local pole = part({
		Name = "Panneau",
		Size = Vector3.new(1, 12, 1),
		CFrame = base.CFrame * CFrame.new(size / 2 - 4, 6.5, size / 2 - 4),
		Color = Color3.fromRGB(30, 30, 30),
		Parent = model,
	})
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(260, 60)
	billboard.StudsOffset = Vector3.new(0, 8, 0)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 250
	billboard.Parent = pole
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.2
	label.Text = "Usine libre"
	label.Parent = billboard

	local meteors = Instance.new("Folder")
	meteors.Name = "Meteores"
	meteors.Parent = model

	model.PrimaryPart = base
	model.Parent = map

	return {
		index = index,
		model = model,
		base = base,
		meteors = meteors,
		refinery = refinery,
		label = label,
		owner = nil,
	}
end

function PlotService.init()
	local old = workspace:FindFirstChild("Baseplate")
	if old then
		old:Destroy()
	end

	local map = Instance.new("Folder")
	map.Name = "Carte"
	map.Parent = workspace

	part({
		Name = "Sol",
		Size = Vector3.new(700, 2, 700),
		Position = Vector3.new(0, -1, 0),
		Color = Color3.fromRGB(58, 50, 70),
		Material = Enum.Material.Basalt,
		Parent = map,
	})

	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Size = Vector3.new(14, 1, 14)
	spawn.Position = Vector3.new(0, 0.5, 0)
	spawn.Color = Color3.fromRGB(255, 200, 60)
	spawn.Material = Enum.Material.Neon
	spawn.Duration = 0
	spawn.Parent = map

	local count = Config.Plot.count
	for i = 1, count do
		local angle = (i - 1) / count * math.pi * 2
		local center = Vector3.new(math.cos(angle) * Config.Plot.ringRadius, 0.5, math.sin(angle) * Config.Plot.ringRadius)
		table.insert(plots, buildPlot(map, i, center))
	end

	-- Ambiance : ciel nocturne pour que les météores brillent
	local Lighting = game:GetService("Lighting")
	Lighting.ClockTime = 20.5
	Lighting.Brightness = 1.5
	Lighting.Ambient = Color3.fromRGB(90, 80, 120)
	Lighting.OutdoorAmbient = Color3.fromRGB(110, 100, 140)

	Players.PlayerRemoving:Connect(PlotService.release)
end

function PlotService.assign(player: Player): Plot?
	for _, plot in plots do
		if plot.owner == nil then
			plot.owner = player
			plot.label.Text = "Usine de " .. player.DisplayName
			return plot
		end
	end
	return nil
end

function PlotService.release(player: Player)
	for _, plot in plots do
		if plot.owner == player then
			plot.owner = nil
			plot.label.Text = "Usine libre"
			plot.meteors:ClearAllChildren()
			PlotService.updateRefinery(plot, 0)
		end
	end
end

function PlotService.get(player: Player): Plot?
	for _, plot in plots do
		if plot.owner == player then
			return plot
		end
	end
	return nil
end

function PlotService.all(): { Plot }
	return plots
end

function PlotService.spawnCFrame(plot: Plot): CFrame
	return plot.base.CFrame * CFrame.new(0, 4, -Config.Plot.size / 2 + 8)
end

function PlotService.updateRefinery(plot: Plot, level: number)
	local scale = 1 + math.min(level, 60) * 0.06
	local height = 6 * scale
	plot.refinery.Size = Vector3.new(8 * scale, height, 8 * scale)
	plot.refinery.CFrame = plot.base.CFrame * CFrame.new(0, 0.5 + height / 2, Config.Plot.size / 2 - 4 - 4 * scale)
	local smoke = plot.refinery:FindFirstChildOfClass("Smoke")
	if smoke then
		smoke.Enabled = level > 0
	end
end

return PlotService
