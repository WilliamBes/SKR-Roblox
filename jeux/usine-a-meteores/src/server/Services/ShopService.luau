-- Traite les achats Robux des developer products (ProcessReceipt).
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local EconomyService = require(script.Parent.EconomyService)
local MeteorService = require(script.Parent.MeteorService)

local ShopService = {}

local handlers: { [string]: (Player, any) -> () } = {
	Boost = function(player)
		EconomyService.addBoost(player, Config.Boost.duration)
	end,
	CashPack = function(player, data)
		local perSecond = Config.estimatedIncome(data.upgrades) * Config.rebirthMultiplier(data.rebirths)
		EconomyService.grant(player, math.max(1000, perSecond * 60 * Config.CashPackMinutes))
	end,
	MeteorShower = function(player)
		MeteorService.shower(player, 30, 3)
	end,
}

function ShopService.init(store)
	local byId: { [number]: string } = {}
	for key, product in Config.Products do
		if product.id ~= 0 then
			byId[product.id] = key
		end
	end

	MarketplaceService.ProcessReceipt = function(receipt)
		local player = Players:GetPlayerByUserId(receipt.PlayerId)
		local data = player and store:get(player)
		if not player or not data then
			-- Le joueur est parti ou n'est pas chargé : Roblox réessaiera plus tard
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		-- Évite de donner deux fois le même achat
		if data.purchases[receipt.PurchaseId] then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		local key = byId[receipt.ProductId]
		local handler = key and handlers[key]
		if not handler then
			warn("[Shop] Produit inconnu : " .. tostring(receipt.ProductId))
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local ok, err = pcall(handler, player, data)
		if not ok then
			warn("[Shop] Erreur en donnant " .. key .. " : " .. tostring(err))
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		data.purchases[receipt.PurchaseId] = os.time()
		data.robuxSpent = (data.robuxSpent or 0) + (receipt.CurrencySpent or 0)
		store:saveNow(player)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end

return ShopService
