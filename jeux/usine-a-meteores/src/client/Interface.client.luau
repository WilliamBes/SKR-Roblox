-- Interface du joueur : argent, améliorations, rebirth, boutique, annonces et effets.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Commun.Format)
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local T = require(ReplicatedStorage.Shared.T)

local player = Players.LocalPlayer

-- Traduit un texte dans la langue du joueur (détectée automatiquement par Roblox)
local function tr(key: string, args: { any }?): string
	return T:get(player.LocaleId, key, args)
end
local camera = workspace.CurrentCamera

local COLORS = {
	panel = Color3.fromRGB(28, 24, 40),
	panelLight = Color3.fromRGB(48, 42, 66),
	accent = Color3.fromRGB(255, 140, 40),
	green = Color3.fromRGB(70, 200, 110),
	grey = Color3.fromRGB(90, 90, 100),
	gold = Color3.fromRGB(255, 210, 60),
	text = Color3.new(1, 1, 1),
}

local soundCache: { [string]: Sound } = {}
local function playSound(name: string)
	local info = Config.Sounds[name]
	if not info then
		return
	end
	local sound = soundCache[name]
	if not sound then
		sound = Instance.new("Sound")
		sound.SoundId = info.id
		sound.Volume = info.volume or 0.5
		sound.PlaybackSpeed = info.pitch or 1
		sound.Parent = SoundService
		soundCache[name] = sound
	end
	SoundService:PlayLocalSound(sound)
end

local state = {
	cash = 0,
	rebirths = 0,
	upgrades = {},
	boostRemaining = 0,
	multiplier = 1,
	passiveIncome = 0,
	passes = {},
}
local boostEndsAt = 0

------------------------------------------------------------------------------
-- Petites fonctions pour construire l'interface
------------------------------------------------------------------------------
local function make(className: string, props: { [string]: any }, children: { Instance }?): any
	local instance = Instance.new(className)
	for k, v in props do
		if k ~= "Parent" then
			(instance :: any)[k] = v
		end
	end
	for _, child in children or {} do
		child.Parent = instance
	end
	instance.Parent = props.Parent
	return instance
end

local function corner(radius: number?)
	return make("UICorner", { CornerRadius = UDim.new(0, radius or 12) })
end

local function stroke(color: Color3?, thickness: number?)
	return make("UIStroke", {
		Color = color or Color3.new(0, 0, 0),
		Thickness = thickness or 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function label(props)
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.Font = props.Font or Enum.Font.FredokaOne
	props.TextColor3 = props.TextColor3 or COLORS.text
	props.TextScaled = if props.TextScaled == nil then true else props.TextScaled
	return make("TextLabel", props, { make("UIStroke", { Thickness = 1.5, Transparency = 0.3 }) })
end

local function button(props, onClick: () -> ())
	props.Font = props.Font or Enum.Font.FredokaOne
	props.TextColor3 = props.TextColor3 or COLORS.text
	props.TextScaled = true
	props.AutoButtonColor = true
	local b = make("TextButton", props, { corner(10), stroke() })
	b.Activated:Connect(onClick)
	return b
end

local function popIn(frame: GuiObject)
	local scale = frame:FindFirstChildOfClass("UIScale") or make("UIScale", { Parent = frame })
	scale.Scale = 0.8
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

------------------------------------------------------------------------------
-- Écran principal
------------------------------------------------------------------------------
local gui = make("ScreenGui", {
	Name = "Interface",
	ResetOnSpawn = false,
	IgnoreGuiInset = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})

-- Agrandit ou réduit tout selon la taille de l'écran (téléphone, tablette, PC)
local uiScale = make("UIScale", { Parent = gui })
local function rescale()
	local size = camera.ViewportSize
	uiScale.Scale = math.clamp(math.min(size.X / 1100, size.Y / 650), 0.55, 1.2)
end
camera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
rescale()

-- Argent en haut
local top = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 10),
	Size = UDim2.fromOffset(380, 118),
	BackgroundColor3 = COLORS.panel,
	BackgroundTransparency = 0.15,
	Parent = gui,
}, { corner(16), stroke(COLORS.accent, 3) })
local cashLabel = label({
	Position = UDim2.fromOffset(12, 6),
	Size = UDim2.new(1, -24, 0, 48),
	Text = "0 $",
	TextColor3 = COLORS.gold,
	Parent = top,
})
local infoLabel = label({
	Position = UDim2.fromOffset(12, 56),
	Size = UDim2.new(1, -24, 0, 26),
	Text = "",
	Parent = top,
})
local worldLabel = label({
	Position = UDim2.fromOffset(12, 84),
	Size = UDim2.new(1, -24, 0, 24),
	Text = "",
	Font = Enum.Font.Gotham,
	TextColor3 = Color3.fromRGB(190, 200, 255),
	Parent = top,
})
local boostLabel = label({
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 1, 6),
	Size = UDim2.fromOffset(300, 30),
	Text = "",
	TextColor3 = COLORS.accent,
	Visible = false,
	Parent = top,
})

-- Panneau des améliorations à droite
local upgradesPanel = make("Frame", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -10, 0.5, 0),
	Size = UDim2.fromOffset(300, 470),
	BackgroundColor3 = COLORS.panel,
	BackgroundTransparency = 0.15,
	Parent = gui,
}, { corner(16), stroke(COLORS.accent, 3) })
label({ Size = UDim2.new(1, 0, 0, 40), Position = UDim2.fromOffset(0, 6), Text = tr("ui_upgrades"), Parent = upgradesPanel })
local list = make("Frame", {
	Position = UDim2.fromOffset(10, 50),
	Size = UDim2.new(1, -20, 1, -60),
	BackgroundTransparency = 1,
	Parent = upgradesPanel,
}, { make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })

local upgradeButtons = {}
for order, key in Config.UpgradeOrder do
	local card = make("Frame", {
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 74),
		BackgroundColor3 = COLORS.panelLight,
		Parent = list,
	}, { corner(12) })
	local title = label({ Position = UDim2.fromOffset(10, 4), Size = UDim2.new(0.6, -10, 0, 30), Text = tr("upgrade_" .. key), TextXAlignment = Enum.TextXAlignment.Left, Parent = card })
	local desc = label({
		Position = UDim2.fromOffset(10, 36),
		Size = UDim2.new(0.6, -10, 0, 32),
		Text = tr("upgrade_" .. key .. "_desc"),
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Parent = card,
	})
	local buy = button({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.new(0.4, -8, 0, 52),
		BackgroundColor3 = COLORS.green,
		Text = "",
		Parent = card,
	}, function()
		remotes.Action:FireServer("upgrade", key)
		playSound("buy")
	end)
	upgradeButtons[key] = { title = title, desc = desc, buy = buy }
end

local rebirthButton = button({
	LayoutOrder = 99,
	Size = UDim2.new(1, 0, 0, 58),
	BackgroundColor3 = Color3.fromRGB(150, 70, 230),
	Text = "Rebirth",
	Parent = list,
}, function()
	remotes.Action:FireServer("rebirth")
end)

-- Boutique à gauche
local shopFrame
local shopToggle = button({
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 10, 0.5, 0),
	Size = UDim2.fromOffset(130, 60),
	BackgroundColor3 = COLORS.gold,
	TextColor3 = Color3.fromRGB(40, 30, 0),
	Text = tr("ui_shop"),
	Parent = gui,
}, function()
	shopFrame.Visible = not shopFrame.Visible
	if shopFrame.Visible then
		popIn(shopFrame)
	end
end)

shopFrame = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.55),
	Size = UDim2.fromOffset(560, 420),
	BackgroundColor3 = COLORS.panel,
	Visible = false,
	Parent = gui,
}, { corner(18), stroke(COLORS.gold, 3) })
label({ Size = UDim2.new(1, 0, 0, 44), Position = UDim2.fromOffset(0, 8), Text = tr("ui_shop"), TextColor3 = COLORS.gold, Parent = shopFrame })
button({
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -10, 0, 10),
	Size = UDim2.fromOffset(40, 40),
	BackgroundColor3 = Color3.fromRGB(200, 60, 60),
	Text = "X",
	Parent = shopFrame,
}, function()
	shopFrame.Visible = false
end)
local shopList = make("ScrollingFrame", {
	Position = UDim2.fromOffset(14, 60),
	Size = UDim2.new(1, -28, 1, -74),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 6,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
	Parent = shopFrame,
}, {
	make("UIGridLayout", {
		CellSize = UDim2.new(0.5, -6, 0, 150),
		CellPadding = UDim2.fromOffset(10, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})

local passButtons = {}
local function shopItem(order: number, item, isPass: boolean, key: string)
	local card = make("Frame", { LayoutOrder = order, BackgroundColor3 = COLORS.panelLight, Parent = shopList }, { corner(12) })
	label({ Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -20, 0, 30), Text = tr((isPass and "pass_" or "product_") .. key), TextColor3 = isPass and COLORS.gold or COLORS.accent, Parent = card })
	label({
		Position = UDim2.fromOffset(10, 38),
		Size = UDim2.new(1, -20, 0, 50),
		Text = tr((isPass and "pass_" or "product_") .. key .. "_desc"),
		Font = Enum.Font.Gotham,
		TextWrapped = true,
		Parent = card,
	})
	local available = item.id ~= 0
	local price = button({
		Position = UDim2.new(0, 10, 1, -50),
		Size = UDim2.new(1, -20, 0, 40),
		BackgroundColor3 = available and COLORS.green or COLORS.grey,
		Text = available and tr("ui_buy") or tr("ui_soon"),
		Parent = card,
	}, function()
		if not available then
			return
		end
		if isPass then
			if not state.passes[key] then
				MarketplaceService:PromptGamePassPurchase(player, item.id)
			end
		else
			MarketplaceService:PromptProductPurchase(player, item.id)
		end
	end)
	if available then
		-- Affiche le prix réel en Robux
		task.spawn(function()
			local ok, info = pcall(function()
				return MarketplaceService:GetProductInfo(item.id, isPass and Enum.InfoType.GamePass or Enum.InfoType.Product)
			end)
			if ok and info and info.PriceInRobux and not (isPass and state.passes[key]) then
				price.Text = "R$ " .. info.PriceInRobux
			end
		end)
	end
	if isPass then
		passButtons[key] = price
	end
end
for i, key in Config.ProductOrder do
	shopItem(i, Config.Products[key], false, key)
end
for i, key in Config.GamePassOrder do
	shopItem(100 + i, Config.GamePasses[key], true, key)
end

------------------------------------------------------------------------------
-- Mise à jour de l'affichage
------------------------------------------------------------------------------
local function refresh()
	cashLabel.Text = Format.number(state.cash) .. " $"
	local info = tr("ui_multiplier", { string.format("%g", math.floor(state.multiplier * 100) / 100) })
	if state.passiveIncome > 0 then
		info ..= "  ·  " .. tr("ui_income", { Format.number(state.passiveIncome) })
	end
	infoLabel.Text = info

	local worldIndex = Config.worldIndex(state.rebirths)
	local worldName = tr("world_" .. Config.Worlds[worldIndex].key)
	local nextWorld = Config.Worlds[worldIndex + 1]
	if nextWorld then
		worldLabel.Text = tr("ui_world_next", { worldName, nextWorld.rebirths })
	else
		worldLabel.Text = tr("ui_world", { worldName })
	end

	for key, ui in upgradeButtons do
		local upgrade = Config.Upgrades[key]
		local level = state.upgrades[key] or 0
		ui.title.Text = tr("ui_level", { tr("upgrade_" .. key), level })
		if level >= upgrade.max then
			ui.buy.Text = tr("ui_max")
			ui.buy.BackgroundColor3 = COLORS.grey
		else
			local cost = Config.upgradeCost(key, level)
			ui.buy.Text = Format.number(cost) .. " $"
			ui.buy.BackgroundColor3 = state.cash >= cost and COLORS.green or COLORS.grey
		end
	end

	local rebirthCost = Config.rebirthCost(state.rebirths)
	local nextBonus = Config.rebirthMultiplier(state.rebirths + 1)
	rebirthButton.Text = tr("ui_rebirth", { tostring(nextBonus), Format.number(rebirthCost) })
	rebirthButton.BackgroundColor3 = state.cash >= rebirthCost and Color3.fromRGB(150, 70, 230) or COLORS.grey

	for key, b in passButtons do
		if state.passes[key] then
			b.Text = tr("ui_owned")
			b.BackgroundColor3 = COLORS.grey
		end
	end
end

remotes.State.OnClientEvent:Connect(function(newState)
	state = newState
	boostEndsAt = os.clock() + (newState.boostRemaining or 0)
	refresh()
end)

task.spawn(function()
	while true do
		local remaining = boostEndsAt - os.clock()
		boostLabel.Visible = remaining > 0
		if remaining > 0 then
			boostLabel.Text = tr("ui_boost", { Config.Boost.multiplier, Format.time(remaining) })
		end
		task.wait(0.5)
	end
end)

------------------------------------------------------------------------------
-- Effets : « +X $ » flottant, impacts, annonces
------------------------------------------------------------------------------
local RARITY_COLORS = {}
for _, r in Config.Rarities do
	RARITY_COLORS[r.key] = r.color
end

local effectsFolder = make("Folder", { Name = "EffetsLocaux", Parent = workspace })

remotes.Collected.OnClientEvent:Connect(function(amount: number, position: Vector3, rarity: string)
	local anchor = make("Part", {
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		Transparency = 1,
		Size = Vector3.one,
		Position = position,
		Parent = effectsFolder,
	})
	local billboard = make("BillboardGui", {
		Size = UDim2.fromOffset(200, 50),
		AlwaysOnTop = true,
		Parent = anchor,
	})
	local text = label({
		Size = UDim2.fromScale(1, 1),
		Text = "+" .. Format.number(amount) .. " $",
		TextColor3 = RARITY_COLORS[rarity] or COLORS.gold,
		Parent = billboard,
	})
	TweenService:Create(anchor, TweenInfo.new(1), { Position = position + Vector3.new(0, 6, 0) }):Play()
	TweenService:Create(text, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1 }):Play()
	Debris:AddItem(anchor, 1.1)
	playSound("collect")
end)

remotes.Impact.OnClientEvent:Connect(function(position: Vector3, rarity: string)
	local ring = make("Part", {
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.Neon,
		Color = RARITY_COLORS[rarity] or COLORS.accent,
		Size = Vector3.new(0.3, 2, 2),
		CFrame = CFrame.new(position.X, position.Y - 1.5, position.Z) * CFrame.Angles(0, 0, math.rad(90)),
		Parent = effectsFolder,
	})
	local big = rarity == "Légendaire" and 30 or (rarity == "Rare" and 18 or 10)
	TweenService:Create(ring, TweenInfo.new(0.5), { Size = Vector3.new(0.3, big, big), Transparency = 1 }):Play()
	Debris:AddItem(ring, 0.6)
	local character0 = player.Character
	local root0 = character0 and character0:FindFirstChild("HumanoidRootPart")
	if root0 and (root0.Position - position).Magnitude < 60 then
		playSound("impact")
	end

	-- Petite secousse de caméra si l'impact est proche
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and (root.Position - position).Magnitude < 40 and rarity ~= "Commun" then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			task.spawn(function()
				for _ = 1, 6 do
					humanoid.CameraOffset = Vector3.new(math.random() - 0.5, math.random() - 0.5, 0) * 0.8
					task.wait(0.03)
				end
				humanoid.CameraOffset = Vector3.zero
			end)
		end
	end
end)

local banner = label({
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 185),
	Size = UDim2.fromOffset(700, 50),
	Text = "",
	Visible = false,
	Parent = gui,
})
local bannerToken = 0
remotes.Announce.OnClientEvent:Connect(function(key: string, args: { any }, kind: string)
	bannerToken += 1
	local token = bannerToken
	banner.Text = tr(key, args)
	banner.TextColor3 = kind == "legendary" and COLORS.gold or Color3.fromRGB(200, 150, 255)
	banner.Visible = true
	popIn(banner)
	task.delay(4, function()
		if bannerToken == token then
			banner.Visible = false
		end
	end)
end)


------------------------------------------------------------------------------
-- Notifications (en bas de l'écran)
------------------------------------------------------------------------------
local toastHolder = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -90),
	Size = UDim2.fromOffset(600, 200),
	BackgroundTransparency = 1,
	Parent = gui,
}, {
	make("UIListLayout", {
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 6),
	}),
})

local TOAST_COLORS = {
	reward = COLORS.green,
	error = Color3.fromRGB(200, 60, 60),
	info = COLORS.panelLight,
}

local function toast(message: string, kind: string)
	local frame = make("Frame", {
		Size = UDim2.fromOffset(520, 44),
		BackgroundColor3 = TOAST_COLORS[kind] or TOAST_COLORS.info,
		Parent = toastHolder,
	}, { corner(12), stroke() })
	label({ Position = UDim2.fromOffset(10, 4), Size = UDim2.new(1, -20, 1, -8), Text = message, Parent = frame })
	popIn(frame)
	task.delay(3.5, function()
		frame:Destroy()
	end)
	if kind == "reward" then
		playSound("reward")
	end
end
remotes.Notify.OnClientEvent:Connect(function(key: string, args: { any }, kind: string)
	toast(tr(key, args), kind)
end)

------------------------------------------------------------------------------
-- Objectif en cours (en haut à gauche)
------------------------------------------------------------------------------
local function questDescription(quest): string
	if quest.type == "collect" then
		return tr(quest.number == 1 and "quest_walk" or "quest_collect", { quest.target })
	elseif quest.type == "upgrade" then
		local name = tr("upgrade_" .. quest.key)
		if quest.key == "Refinery" and quest.target == 1 then
			return tr("quest_build_refinery")
		elseif quest.target == 1 then
			return tr("quest_upgrade", { name })
		end
		return tr("quest_upgrade_level", { name, quest.target })
	elseif quest.type == "earned" then
		return tr("quest_earned", { Format.number(quest.target) })
	end
	return tr("quest_rebirth")
end

local questFrame = make("Frame", {
	Position = UDim2.fromOffset(10, 10),
	Size = UDim2.fromOffset(320, 96),
	BackgroundColor3 = COLORS.panel,
	BackgroundTransparency = 0.15,
	Visible = false,
	Parent = gui,
}, { corner(14), stroke(COLORS.green, 3) })
local questTitle = label({ Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -24, 0, 22), Text = "", TextColor3 = COLORS.green, TextXAlignment = Enum.TextXAlignment.Left, Parent = questFrame })
local questText = label({ Position = UDim2.fromOffset(12, 30), Size = UDim2.new(1, -24, 0, 30), Text = "", TextXAlignment = Enum.TextXAlignment.Left, Parent = questFrame })
local barBack = make("Frame", { Position = UDim2.fromOffset(12, 66), Size = UDim2.new(1, -24, 0, 20), BackgroundColor3 = COLORS.panelLight, Parent = questFrame }, { corner(10) })
local barFill = make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = COLORS.green, Parent = barBack }, { corner(10) })
local barText = label({ Size = UDim2.fromScale(1, 1), Text = "", ZIndex = 2, Parent = barBack })

-- Flèche lumineuse vers le météore le plus proche pendant le premier objectif
local beam = make("Beam", {
	Color = ColorSequence.new(COLORS.gold),
	Width0 = 0.6,
	Width1 = 0.6,
	FaceCamera = true,
	LightEmission = 1,
	Texture = "rbxasset://textures/particles/sparkles_main.dds",
	TextureMode = Enum.TextureMode.Static,
	TextureSpeed = 2,
	Enabled = false,
	Parent = workspace.Terrain,
})
local beamStart = make("Attachment", { Parent = workspace.Terrain })
local beamEnd = make("Attachment", { Parent = workspace.Terrain })
beam.Attachment0 = beamStart
beam.Attachment1 = beamEnd

local currentQuest = nil
local currentPlot: Model? = nil

task.spawn(function()
	while true do
		task.wait(0.2)
		local active = false
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local meteors = currentPlot and currentPlot:FindFirstChild("Meteores")
		if currentQuest and currentQuest.type == "collect" and currentQuest.number == 1 and root and meteors then
			local best, bestDistance = nil, math.huge
			for _, meteor in meteors:GetChildren() do
				if meteor:IsA("BasePart") and meteor:GetAttribute("Landed") then
					local d = (meteor.Position - root.Position).Magnitude
					if d < bestDistance then
						best, bestDistance = meteor, d
					end
				end
			end
			if best then
				active = true
				beamStart.WorldPosition = root.Position - Vector3.new(0, 2, 0)
				beamEnd.WorldPosition = best.Position
			end
		end
		beam.Enabled = active
	end
end)

-- Fait clignoter le bouton d'amélioration demandé par l'objectif
local pulse = 0
task.spawn(function()
	while true do
		task.wait(0.05)
		pulse += 0.05
		for key, ui in upgradeButtons do
			local s = ui.buy:FindFirstChildOfClass("UIStroke")
			if s then
				local highlighted = currentQuest and currentQuest.type == "upgrade" and currentQuest.key == key
				s.Color = highlighted and COLORS.gold or Color3.new(0, 0, 0)
				s.Thickness = highlighted and (3 + math.sin(pulse * 6) * 1.5) or 2
			end
		end
	end
end)

------------------------------------------------------------------------------
-- Boutons à gauche : Boutique, Cadeaux, Codes
------------------------------------------------------------------------------
shopToggle.Position = UDim2.new(0, 10, 0.5, -75)

local function panel(title: string, width: number, height: number, color: Color3)
	local frame = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.55),
		Size = UDim2.fromOffset(width, height),
		BackgroundColor3 = COLORS.panel,
		Visible = false,
		Parent = gui,
	}, { corner(18), stroke(color, 3) })
	label({ Size = UDim2.new(1, 0, 0, 44), Position = UDim2.fromOffset(0, 8), Text = title, TextColor3 = color, Parent = frame })
	button({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 10),
		Size = UDim2.fromOffset(40, 40),
		BackgroundColor3 = Color3.fromRGB(200, 60, 60),
		Text = "X",
		Parent = frame,
	}, function()
		frame.Visible = false
	end)
	return frame
end

local openPanels = {}
local function toggle(frame: GuiObject)
	local show = not frame.Visible
	for _, other in openPanels do
		other.Visible = false
	end
	shopFrame.Visible = false
	frame.Visible = show
	if show then
		popIn(frame)
	end
end

-- Cadeaux
local giftsFrame = panel(tr("ui_gifts_title"), 560, 260, COLORS.green)
table.insert(openPanels, giftsFrame)
local giftsRow = make("Frame", {
	Position = UDim2.fromOffset(14, 64),
	Size = UDim2.new(1, -28, 1, -78),
	BackgroundTransparency = 1,
	Parent = giftsFrame,
}, { make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center }) })

local giftButton = button({
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 10, 0.5, 0),
	Size = UDim2.fromOffset(130, 60),
	BackgroundColor3 = COLORS.green,
	Text = tr("ui_gifts"),
	Parent = gui,
}, function()
	toggle(giftsFrame)
end)
local giftBadge = label({
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(1, -4, 0, 4),
	Size = UDim2.fromOffset(30, 30),
	BackgroundTransparency = 0,
	BackgroundColor3 = Color3.fromRGB(230, 40, 60),
	Text = "",
	Visible = false,
	Parent = giftButton,
})
make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = giftBadge })

local giftCells = {}
local giftsClaimed = {}
local sessionBase = os.clock()
for i, gift in Config.Gifts do
	local cell = make("Frame", { Size = UDim2.new(0.2, -7, 1, 0), BackgroundColor3 = COLORS.panelLight, Parent = giftsRow }, { corner(12) })
	label({ Position = UDim2.fromOffset(4, 6), Size = UDim2.new(1, -8, 0, 40), Text = "🎁", Parent = cell })
	label({ Position = UDim2.fromOffset(4, 50), Size = UDim2.new(1, -8, 0, 22), Text = tr("ui_minutes", { gift.minutes }), Parent = cell })
	local b = button({
		Position = UDim2.new(0, 6, 1, -50),
		Size = UDim2.new(1, -12, 0, 42),
		BackgroundColor3 = COLORS.grey,
		Text = "",
		Parent = cell,
	}, function()
		remotes.Action:FireServer("claimGift", i)
	end)
	giftCells[i] = b
end

task.spawn(function()
	while true do
		local elapsed = os.clock() - sessionBase
		local ready = 0
		for i, gift in Config.Gifts do
			local b = giftCells[i]
			local remaining = gift.minutes * 60 - elapsed
			if giftsClaimed[i] then
				b.Text = tr("ui_opened")
				b.BackgroundColor3 = COLORS.grey
			elseif remaining <= 0 then
				b.Text = tr("ui_open")
				b.BackgroundColor3 = COLORS.green
				ready += 1
			else
				b.Text = Format.time(remaining)
				b.BackgroundColor3 = COLORS.grey
			end
		end
		giftBadge.Visible = ready > 0
		giftBadge.Text = tostring(ready)
		task.wait(0.5)
	end
end)

-- Codes
local codesFrame = panel(tr("ui_codes"), 420, 200, COLORS.accent)
table.insert(openPanels, codesFrame)
local codeBox = make("TextBox", {
	Position = UDim2.fromOffset(20, 64),
	Size = UDim2.new(1, -40, 0, 50),
	BackgroundColor3 = COLORS.panelLight,
	TextColor3 = COLORS.text,
	PlaceholderText = tr("ui_code_placeholder"),
	Font = Enum.Font.FredokaOne,
	TextScaled = true,
	ClearTextOnFocus = false,
	Text = "",
	Parent = codesFrame,
}, { corner(10) })
button({
	Position = UDim2.new(0, 20, 1, -70),
	Size = UDim2.new(1, -40, 0, 50),
	BackgroundColor3 = COLORS.green,
	Text = tr("ui_redeem"),
	Parent = codesFrame,
}, function()
	if codeBox.Text ~= "" then
		remotes.Action:FireServer("code", codeBox.Text)
		codeBox.Text = ""
	end
end)
button({
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 10, 0.5, 75),
	Size = UDim2.fromOffset(130, 60),
	BackgroundColor3 = COLORS.accent,
	Text = tr("ui_codes"),
	Parent = gui,
}, function()
	toggle(codesFrame)
end)

-- Familiers
local PET_COLOR = Color3.fromRGB(190, 110, 255)
local petsFrame = panel(tr("ui_pets"), 580, 440, PET_COLOR)
table.insert(openPanels, petsFrame)
local petsHint = label({
	Position = UDim2.fromOffset(14, 50),
	Size = UDim2.new(1, -28, 0, 24),
	Text = "",
	Font = Enum.Font.Gotham,
	Parent = petsFrame,
})
local eggRow = make("Frame", {
	Position = UDim2.fromOffset(14, 80),
	Size = UDim2.new(1, -28, 0, 150),
	BackgroundTransparency = 1,
	Parent = petsFrame,
}, { make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10) }) })

local eggButtons = {}
for _, key in Config.EggOrder do
	local egg = Config.Eggs[key]
	local card = make("Frame", { Size = UDim2.new(0.5, -5, 1, 0), BackgroundColor3 = COLORS.panelLight, Parent = eggRow }, { corner(12) })
	label({ Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -20, 0, 30), Text = "🥚 " .. tr("egg_" .. key), TextColor3 = PET_COLOR, Parent = card })
	-- Chances de tirage affichées au joueur
	local total = 0
	for _, weight in egg.weights do
		total += weight
	end
	local odds = {}
	for _, petKey in Config.PetOrder do
		local weight = egg.weights[petKey]
		if weight then
			table.insert(odds, string.format("%s %g%%", tr("pet_" .. petKey), math.floor(weight / total * 1000 + 0.5) / 10))
		end
	end
	label({
		Position = UDim2.fromOffset(10, 40),
		Size = UDim2.new(1, -20, 0, 54),
		Text = table.concat(odds, "\n"),
		Font = Enum.Font.Gotham,
		TextWrapped = true,
		Parent = card,
	})
	eggButtons[key] = button({
		Position = UDim2.new(0, 10, 1, -48),
		Size = UDim2.new(1, -20, 0, 40),
		BackgroundColor3 = COLORS.grey,
		Text = tr("ui_hatch") .. " · " .. Format.number(egg.cost) .. " $",
		Parent = card,
	}, function()
		remotes.Action:FireServer("hatch", key)
	end)
end

local petList = make("ScrollingFrame", {
	Position = UDim2.fromOffset(14, 240),
	Size = UDim2.new(1, -28, 1, -254),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 6,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
	Parent = petsFrame,
}, {
	make("UIGridLayout", {
		CellSize = UDim2.new(0.25, -8, 0, 70),
		CellPadding = UDim2.fromOffset(8, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})
local petCells = {}
for order, key in Config.PetOrder do
	local info = Config.Pets[key]
	local cell = make("Frame", { LayoutOrder = order, BackgroundColor3 = COLORS.panelLight, Visible = false, Parent = petList }, { corner(10), stroke(info.color, 2) })
	label({ Position = UDim2.fromOffset(6, 4), Size = UDim2.new(1, -12, 0, 24), Text = tr("pet_" .. key), TextColor3 = info.color, Parent = cell })
	label({ Position = UDim2.fromOffset(6, 30), Size = UDim2.new(1, -12, 0, 16), Text = "+" .. math.floor(info.bonus * 100 + 0.5) .. "%", Font = Enum.Font.Gotham, Parent = cell })
	petCells[key] = label({ Position = UDim2.fromOffset(6, 48), Size = UDim2.new(1, -12, 0, 18), Text = "", Parent = cell })
end
local noPets = label({
	Position = UDim2.fromOffset(14, 250),
	Size = UDim2.new(1, -28, 0, 30),
	Text = tr("ui_no_pets"),
	Font = Enum.Font.Gotham,
	Parent = petsFrame,
})

button({
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 10, 0.5, 150),
	Size = UDim2.fromOffset(130, 60),
	BackgroundColor3 = PET_COLOR,
	Text = tr("ui_pets"),
	Parent = gui,
}, function()
	toggle(petsFrame)
end)

remotes.WorldUnlocked.OnClientEvent:Connect(function(worldKey: string)
	toast(tr("msg_world_unlocked", { tr("world_" .. worldKey) }), "reward")
end)

remotes.Hatched.OnClientEvent:Connect(function(petKey: string)
	toast(tr("ui_hatched", { tr("pet_" .. petKey) }), "reward")
end)

local function refreshPets(newState)
	local pets = newState.pets or {}
	local any = false
	for key, cellLabel in petCells do
		local count = pets[key] or 0
		cellLabel.Parent.Visible = count > 0
		cellLabel.Text = "x" .. count
		any = any or count > 0
	end
	noPets.Visible = not any
	petsHint.Text = tr("ui_pets_hint", { Config.PetSlots, math.floor((newState.petBonus or 0) * 100 + 0.5) })
	for key, b in eggButtons do
		b.BackgroundColor3 = newState.cash >= Config.Eggs[key].cost and COLORS.green or COLORS.grey
	end
end

-- La boutique ferme les autres fenêtres
shopToggle.Activated:Connect(function()
	for _, other in openPanels do
		other.Visible = false
	end
end)

------------------------------------------------------------------------------
-- Récompense quotidienne (s'ouvre toute seule)
------------------------------------------------------------------------------
local dailyFrame = panel(tr("ui_daily_title"), 420, 240, COLORS.gold)
table.insert(openPanels, dailyFrame)
local dailyText = label({ Position = UDim2.fromOffset(20, 60), Size = UDim2.new(1, -40, 0, 80), Text = "", TextWrapped = true, Parent = dailyFrame })
button({
	Position = UDim2.new(0, 20, 1, -70),
	Size = UDim2.new(1, -40, 0, 54),
	BackgroundColor3 = COLORS.green,
	Text = tr("ui_claim"),
	Parent = dailyFrame,
}, function()
	remotes.Action:FireServer("claimDaily")
	dailyFrame.Visible = false
end)
local dailyShown = false

------------------------------------------------------------------------------
-- Mise à jour avec l'état du serveur
------------------------------------------------------------------------------
remotes.State.OnClientEvent:Connect(function(newState)
	currentPlot = newState.plotModel
	currentQuest = newState.quest
	refreshPets(newState)

	local quest = newState.quest
	questFrame.Visible = quest ~= nil
	if quest then
		questTitle.Text = tr("ui_quest", { quest.number, quest.total, Format.number(quest.reward) })
		questText.Text = questDescription(quest)
		local ratio = math.clamp(quest.progress / quest.target, 0, 1)
		TweenService:Create(barFill, TweenInfo.new(0.2), { Size = UDim2.fromScale(ratio, 1) }):Play()
		barText.Text = Format.number(quest.progress) .. " / " .. Format.number(quest.target)
	end

	giftsClaimed = newState.giftsClaimed or {}
	sessionBase = os.clock() - (newState.sessionElapsed or 0)

	local daily = newState.daily
	if daily and daily.claimable and not dailyShown then
		dailyShown = true
		dailyText.Text = tr("ui_daily_text", { daily.streak, Format.number(daily.reward) })
		toggle(dailyFrame)
	end
end)


------------------------------------------------------------------------------
-- Textes du monde 3D (panneaux des usines, classements) traduits dans ta langue
------------------------------------------------------------------------------
local CollectionService = game:GetService("CollectionService")

local function bindPlotLabel(textLabel: Instance)
	if not textLabel:IsA("TextLabel") then
		return
	end
	local function update()
		local owner = textLabel:GetAttribute("Owner")
		textLabel.Text = if owner and owner ~= "" then tr("world_plot_owner", { owner }) else tr("world_plot_free")
	end
	textLabel:GetAttributeChangedSignal("Owner"):Connect(update)
	update()
end

local function bindTranslatedLabel(textLabel: Instance)
	if not textLabel:IsA("TextLabel") then
		return
	end
	local function update()
		local key = textLabel:GetAttribute("TextKey")
		textLabel.Text = if key and key ~= "" then tr(key) else ""
	end
	textLabel:GetAttributeChangedSignal("TextKey"):Connect(update)
	update()
end

CollectionService:GetInstanceAddedSignal("PlotLabel"):Connect(bindPlotLabel)
for _, instance in CollectionService:GetTagged("PlotLabel") do
	bindPlotLabel(instance)
end
CollectionService:GetInstanceAddedSignal("TranslatedLabel"):Connect(bindTranslatedLabel)
for _, instance in CollectionService:GetTagged("TranslatedLabel") do
	bindTranslatedLabel(instance)
end

refresh()
