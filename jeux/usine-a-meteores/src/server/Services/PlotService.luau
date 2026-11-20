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
	borders: { BasePart },
	decor: Folder,
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

	-- Bordure lumineuse (sa couleur change avec les rebirths)
	local borders = {}
	for _, offset in { Vector3.new(size / 2, 0, 0), Vector3.new(-size / 2, 0, 0) } do
		table.insert(borders, part({
			Size = Vector3.new(1, 1.4, size),
			CFrame = base.CFrame * CFrame.new(offset),
			Color = Color3.fromRGB(255, 120, 40),
			Material = Enum.Material.Neon,
			Parent = model,
		}))
	end
	for _, offset in { Vector3.new(0, 0, size / 2), Vector3.new(0, 0, -size / 2) } do
		table.insert(borders, part({
			Size = Vector3.new(size, 1.4, 1),
			CFrame = base.CFrame * CFrame.new(offset),
			Color = Color3.fromRGB(255, 120, 40),
			Material = Enum.Material.Neon,
			Parent = model,
		}))
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

	local decor = Instance.new("Folder")
	decor.Name = "Decor"
	decor.Parent = model

	model.PrimaryPart = base
	model.Parent = map

	return {
		index = index,
		model = model,
		base = base,
		meteors = meteors,
		refinery = refinery,
		label = label,
		borders = borders,
		decor = decor,
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
			PlotService.updateVisuals(plot, nil)
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

-- Décors qui apparaissent avec les améliorations : l'usine se construit sous les yeux du joueur
local function addDecor(plot: Plot, props: { [string]: any }): Part
	props.Parent = plot.decor
	props.CanCollide = if props.CanCollide == nil then false else props.CanCollide
	props.CastShadow = false
	return part(props)
end

local function buildCrystals(plot: Plot, count: number)
	local size = Config.Plot.size
	for i = 1, count do
		local z = -size / 2 + 8 + (i - 1) * ((size - 16) / 7)
		local crystal = addDecor(plot, {
			Size = Vector3.new(2.5, 5 + (i % 3) * 1.5, 2.5),
			Color = Color3.fromRGB(255, 170, 60):Lerp(Color3.fromRGB(255, 230, 90), i / 8),
			Material = Enum.Material.Neon,
		})
		crystal.CFrame = plot.base.CFrame * CFrame.new(-size / 2 + 3, 0.5 + crystal.Size.Y / 2, z) * CFrame.Angles(0, math.rad(i * 37), math.rad(12))
	end
end

local function buildRadars(plot: Plot, count: number)
	local size = Config.Plot.size
	for i = 1, count do
		local x = size / 2 - 5
		local z = -size / 2 + 12 + (i - 1) * 11
		local mast = addDecor(plot, {
			Size = Vector3.new(1, 10, 1),
			Color = Color3.fromRGB(70, 70, 80),
			Material = Enum.Material.Metal,
		})
		mast.CFrame = plot.base.CFrame * CFrame.new(x, 5.5, z)
		local dish = addDecor(plot, {
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.6, 6, 6),
			Color = Color3.fromRGB(200, 200, 215),
			Material = Enum.Material.SmoothPlastic,
		})
		dish.CFrame = mast.CFrame * CFrame.new(0, 5, 0) * CFrame.Angles(0, 0, math.rad(60))
		local tip = addDecor(plot, {
			Shape = Enum.PartType.Ball,
			Size = Vector3.one,
			Color = Color3.fromRGB(60, 200, 255),
			Material = Enum.Material.Neon,
		})
		tip.CFrame = dish.CFrame * CFrame.new(1, 0, 0)
	end
end

local function buildMagnets(plot: Plot, count: number)
	local size = Config.Plot.size
	local corners = {
		Vector3.new(-size / 2 + 4, 0, -size / 2 + 4),
		Vector3.new(size / 2 - 4, 0, -size / 2 + 4),
		Vector3.new(-size / 2 + 4, 0, size / 2 - 4),
		Vector3.new(size / 2 - 10, 0, size / 2 - 10),
	}
	for i = 1, math.min(count, #corners) do
		local base = plot.base.CFrame * CFrame.new(corners[i])
		local pillar = addDecor(plot, {
			Size = Vector3.new(2, 7, 2),
			Color = Color3.fromRGB(200, 40, 40),
			Material = Enum.Material.SmoothPlastic,
		})
		pillar.CFrame = base * CFrame.new(0, 4, 0)
		local top = addDecor(plot, {
			Size = Vector3.new(2.2, 1.2, 2.2),
			Color = Color3.fromRGB(220, 220, 230),
			Material = Enum.Material.Metal,
		})
		top.CFrame = base * CFrame.new(0, 8, 0)
		local glow = addDecor(plot, {
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 1.6,
			Color = Color3.fromRGB(120, 180, 255),
			Material = Enum.Material.ForceField,
		})
		glow.CFrame = base * CFrame.new(0, 9.4, 0)
	end
end

local function buildConveyor(plot: Plot, chimneys: number)
	local size = Config.Plot.size
	local belt = addDecor(plot, {
		Size = Vector3.new(5, 0.4, size / 2 - 10),
		Color = Color3.fromRGB(35, 35, 40),
		Material = Enum.Material.Fabric,
	})
	belt.CFrame = plot.base.CFrame * CFrame.new(0, 0.7, size / 4 - 6)
	for _, side in { -1, 1 } do
		local rail = addDecor(plot, {
			Size = Vector3.new(0.5, 1, size / 2 - 10),
			Color = Color3.fromRGB(255, 200, 60),
			Material = Enum.Material.Metal,
		})
		rail.CFrame = belt.CFrame * CFrame.new(side * 2.75, 0.3, 0)
	end
	for i = 1, chimneys do
		local chimney = addDecor(plot, {
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(14 + i * 3, 2.5, 2.5),
			Color = Color3.fromRGB(90, 85, 95),
			Material = Enum.Material.Brick,
		})
		local x = (i % 2 == 0 and 1 or -1) * (8 + i * 2)
		chimney.CFrame = plot.base.CFrame * CFrame.new(x, 0.5 + chimney.Size.X / 2, size / 2 - 6) * CFrame.Angles(0, 0, math.rad(90))
		local smoke = Instance.new("Smoke")
		smoke.Color = Color3.fromRGB(180, 170, 190)
		smoke.RiseVelocity = 6
		smoke.Size = 3
		smoke.Parent = chimney
	end
end

function PlotService.updateVisuals(plot: Plot, data)
	plot.decor:ClearAllChildren()
	local upgrades = data and data.upgrades or {}
	local rebirths = data and data.rebirths or 0

	PlotService.updateRefinery(plot, upgrades.Refinery or 0)
	local borderColor = Config.RebirthColors[(rebirths % #Config.RebirthColors) + 1]
	for _, border in plot.borders do
		border.Color = borderColor
	end

	local value = upgrades.MeteorValue or 0
	if value > 0 then
		buildCrystals(plot, math.min(8, math.ceil(value / 3)))
	end
	local rate = upgrades.SpawnRate or 0
	if rate > 0 then
		buildRadars(plot, math.min(5, math.ceil(rate / 5)))
	end
	local magnet = upgrades.Magnet or 0
	if magnet > 0 then
		buildMagnets(plot, magnet)
	end
	local refinery = upgrades.Refinery or 0
	if refinery > 0 then
		buildConveyor(plot, math.min(4, math.floor(refinery / 10)))
	end
end

return PlotService
