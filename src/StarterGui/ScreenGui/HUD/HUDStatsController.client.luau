local Players = game:GetService("Players")

local player = Players.LocalPlayer
local hud = script.Parent


-- =========================================================
-- NUMBER FORMAT
-- =========================================================

local function formatNumber(number)
	number = math.floor(tonumber(number) or 0)

	local formatted = tostring(number)

	while true do
		local newFormatted, replacements = formatted:gsub(
			"^(-?%d+)(%d%d%d)",
			"%1,%2"
		)

		formatted = newFormatted

		if replacements == 0 then
			break
		end
	end

	return formatted
end


-- =========================================================
-- XP WIDGET
-- =========================================================

local xpWidget = hud:WaitForChild("XPWidget")
local xpMain = xpWidget:WaitForChild("Main")

local levelLabel = xpMain:WaitForChild("LevelLabel")
local xpText = xpMain:WaitForChild("XPText")

local xpBarBackground = xpMain:WaitForChild("XPBarBackground")
local xpFill = xpBarBackground:WaitForChild("Fill")


local function updateXP()
	local level = player:GetAttribute("Level") or 1
	local xp = player:GetAttribute("XP") or 0
	local xpRequired = player:GetAttribute("XPRequired") or 1

	-- Не даём делить на 0
	if xpRequired <= 0 then
		xpRequired = 1
	end

	levelLabel.Text = "LV. " .. tostring(level)

	xpText.Text =
		formatNumber(xp)
		.. " / "
		.. formatNumber(xpRequired)
		.. " XP"

	local progress = math.clamp(xp / xpRequired, 0, 1)

	xpFill.Size = UDim2.new(
		progress,
		0,
		1,
		0
	)
end


-- =========================================================
-- GLOBAL DIG WIDGET
-- =========================================================

local globalDigWidget = hud:WaitForChild("GlobalDigWidget")
local globalMain = globalDigWidget:WaitForChild("Main")

local globalProgressText = globalMain:WaitForChild("ProgressText")

local globalBarBackground =
	globalMain:WaitForChild("ProgressBarBackground")

local globalFill =
	globalBarBackground:WaitForChild("Fill")


local GLOBAL_MILESTONES = {
	500,
	2500,
	10000,
	50000,
	200000
}


local function getNextGlobalMilestone(total)
	for _, milestone in ipairs(GLOBAL_MILESTONES) do
		if total < milestone then
			return milestone
		end
	end

	return nil
end


local function updateGlobalDig()
	local total =
		player:GetAttribute("GlobalDigTotal") or 0

	local nextMilestone =
		getNextGlobalMilestone(total)

	if nextMilestone then

		globalProgressText.Text =
			formatNumber(total)
			.. " / "
			.. formatNumber(nextMilestone)

		local progress =
			math.clamp(
				total / nextMilestone,
				0,
				1
			)

		globalFill.Size = UDim2.new(
			progress,
			0,
			1,
			0
		)

	else

		globalProgressText.Text =
			formatNumber(total)
			.. " COMPLETE"

		globalFill.Size = UDim2.new(
			1,
			0,
			1,
			0
		)

	end
end


-- =========================================================
-- INITIAL UPDATE
-- =========================================================

updateXP()
updateGlobalDig()


-- =========================================================
-- ATTRIBUTE LISTENERS
-- =========================================================

player:GetAttributeChangedSignal("Level"):Connect(updateXP)

player:GetAttributeChangedSignal("XP"):Connect(updateXP)

player:GetAttributeChangedSignal("XPRequired"):Connect(updateXP)

player:GetAttributeChangedSignal("GlobalDigTotal"):Connect(
	updateGlobalDig
)