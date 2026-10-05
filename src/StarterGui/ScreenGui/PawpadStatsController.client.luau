local Players = game:GetService("Players")

local player = Players.LocalPlayer
local gui = script.Parent


-- =========================================================
-- PAWPAD LABELS
-- =========================================================

local mainWindow = gui:WaitForChild("MainWindow")
local header = mainWindow:WaitForChild("Header")
local statsPanel = header:WaitForChild("StatsPanel")
local statsContent = statsPanel:WaitForChild("StatsContent")

local cashLabel = statsContent:WaitForChild("CashLabel")
local bonesLabel = statsContent:WaitForChild("BonesLabel")
local levelLabel = statsContent:WaitForChild("LevelLabel")


-- =========================================================
-- NUMBER FORMAT
-- =========================================================

local function formatNumber(number)
	number = math.floor(tonumber(number) or 0)

	local formatted = tostring(number)

	while true do
		local newFormatted, replacements =
			formatted:gsub("^(-?%d+)(%d%d%d)", "%1,%2")

		formatted = newFormatted

		if replacements == 0 then
			break
		end
	end

	return formatted
end


-- =========================================================
-- CASH
-- =========================================================

local leaderstats = player:WaitForChild("leaderstats")
local coins = leaderstats:WaitForChild("Coins")

local function updateCash()
	cashLabel.Text = "Cash: " .. formatNumber(coins.Value)
end


-- =========================================================
-- BONES
-- =========================================================

local bonesValue = player:WaitForChild("Bones")

local function updateBones()
	bonesLabel.Text = "Bones: " .. formatNumber(bonesValue.Value)
end


-- =========================================================
-- LEVEL
-- =========================================================

local function updateLevel()
	local level = player:GetAttribute("Level") or 1

	levelLabel.Text = "Lv. " .. tostring(level)
end


-- =========================================================
-- FIRST UPDATE
-- =========================================================

updateCash()
updateBones()
updateLevel()


-- =========================================================
-- LIVE UPDATES
-- =========================================================

coins:GetPropertyChangedSignal("Value"):Connect(updateCash)

bonesValue:GetPropertyChangedSignal("Value"):Connect(updateBones)

player:GetAttributeChangedSignal("Level"):Connect(updateLevel)