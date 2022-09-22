local E = unpack(ElvUI)
local M = E:GetModule('Misc')
local S = E:GetModule('Skins')
local EP = LibStub('LibElvUIPlugin-1.0')
local LSM = E.Libs.LSM
local LCS = E.Libs.LCS
local AddOnName, Engine = ...

local module = E:NewModule(AddOnName, 'AceHook-3.0', 'AceEvent-3.0')
print(AddOnName, 'addonname')
_G[AddOnName] = Engine

module.Title = GetAddOnMetadata('ElvUI_WrathArmory', 'Title')
module.CleanTitle = GetAddOnMetadata('ElvUI_WrathArmory', 'X-CleanTitle')
module.Version = GetAddOnMetadata('ElvUI_WrathArmory', 'Version')
module.Configs = {}

-- local texturePath = 'Interface\\Addons\\ElvUI_WrathArmory\\Textures\\'

function module:Print(...)
	(E.db and _G[E.db.general.messageRedirect] or _G.DEFAULT_CHAT_FRAME):AddMessage(strjoin('', E.media.hexvaluecolor or '|cff00b3ff', 'ElvUI-Warth Armory:|r ', ...)) -- I put DEFAULT_CHAT_FRAME as a fail safe.
end

local function GetOptions()
	for _, func in pairs(module.Configs) do
		func()
	end
end

function module:UpdateOptions()
	module:UpdateInspectPageFonts('Character')
	module:UpdateInspectPageFonts('Inspect')
end

local InspectItems = {
	'HeadSlot',			--1L
	'NeckSlot',			--2L
	'ShoulderSlot',		--3L
	'',					--4
	'ChestSlot',		--5L
	'WaistSlot',		--6R
	'LegsSlot',			--7R
	'FeetSlot',			--8R
	'WristSlot',		--9L
	'HandsSlot',		--10R
	'Finger0Slot',		--11R
	'Finger1Slot',		--12R
	'Trinket0Slot',		--13R
	'Trinket1Slot',		--14R
	'BackSlot',			--15L
	'MainHandSlot',		--16
	'SecondaryHandSlot',--17
	'RangedSlot',		--18
}

local whileOpenEvents = {
	UPDATE_INVENTORY_DURABILITY = true,
}

function module:CreateInspectTexture(slot, x, y)
	local texture = slot:CreateTexture()
	texture:Point('BOTTOM', x, y)
	texture:SetTexCoord(unpack(E.TexCoords))
	texture:Size(14)

	local backdrop = CreateFrame('Frame', nil, slot)
	backdrop:SetTemplate(nil, nil, true)
	backdrop:SetBackdropColor(0,0,0,0)
	backdrop:SetOutside(texture)
	backdrop:Hide()

	return texture, backdrop
end

function module:GetInspectPoints(id)
	if not id then return end

	if id <= 5 or (id == 9 or id == 15) then
		return 7, 0, 18, 'BOTTOMLEFT' -- Left side
	elseif (id >= 6 and id <= 8) or (id >= 10 and id <= 14) then
		return -7, 0, 18, 'BOTTOMRIGHT' -- Right side
	-- elseif id == 18 then
	-- 	return 0, 0, 0, 'BOTTOMRIGHT'
	else
		return 0, 45, 60, 'BOTTOM'
	end
end

function module:UpdateInspectInfo(_, arg1)
	E:Delay(0.75, function()
		if _G.InspectFrame:IsVisible() then
			print('Delay Firing!!')
			module:UpdatePageInfo(_G.InspectFrame, 'Inspect', arg1)
		end
	end)
	module:UpdatePageInfo(_G.InspectFrame, 'Inspect', arg1)
	_G.InspectFrame.ItemLevelText:FontTemplate(LSM:Fetch('font', E.db.wratharmory.inspect.avgItemLevel.font), E.db.wratharmory.inspect.avgItemLevel.fontSize, E.db.wratharmory.inspect.avgItemLevel.fontOutline)
end

function module:UpdateCharacterInfo(event)
	if (not E.db.wratharmory.character.enable)
	or (whileOpenEvents[event] and not _G.CharacterFrame:IsShown()) then return end

	module:UpdatePageInfo(_G.CharacterFrame, 'Character', nil, event)
end

function module:UpdateCharacterItemLevel()
	module:UpdateAverageString(_G.CharacterFrame, 'Character')
end

function module:ClearPageInfo(frame, which)
	if not frame or not which then return end
	frame.ItemLevelText:SetText('')

	for i = 1, 18 do
		if i ~= 4 then
			local inspectItem = _G[which..InspectItems[i]]
			inspectItem.enchantText:SetText('')
			inspectItem.iLvlText:SetText('')

			for y = 1, 10 do
				inspectItem['textureSlot'..y]:SetTexture()
				inspectItem['textureSlotBackdrop'..y]:Hide()
			end
		end
	end
end

function module:ToggleItemLevelInfo(setupCharacterPage)
	if setupCharacterPage then
		module:CreateSlotStrings(_G.CharacterFrame, 'Character')
	end

	if E.db.wratharmory.character.enable then
		module:RegisterEvent('PLAYER_EQUIPMENT_CHANGED', 'UpdateCharacterInfo')
		module:RegisterEvent('UPDATE_INVENTORY_DURABILITY', 'UpdateCharacterInfo')
		module:RegisterEvent('PLAYER_AVG_ITEM_LEVEL_UPDATE', 'UpdateCharacterItemLevel')

		if not _G.CharacterFrame.CharacterInfoHooked then
			_G.CharacterFrame:HookScript('OnShow', function()
				module.UpdateCharacterInfo()
			end)

			_G.CharacterFrame.CharacterInfoHooked = true
		end

		if not setupCharacterPage then
			module:UpdateCharacterInfo()
		end
	else
		module:UnregisterEvent('PLAYER_EQUIPMENT_CHANGED')
		module:UnregisterEvent('UPDATE_INVENTORY_DURABILITY')
		module:UnregisterEvent('PLAYER_AVG_ITEM_LEVEL_UPDATE')

		module:ClearPageInfo(_G.CharacterFrame, 'Character')
	end

	if E.db.wratharmory.inspect.enable then
		module:RegisterEvent('INSPECT_READY', 'UpdateInspectInfo')
	else
		module:UnregisterEvent('INSPECT_READY')
		module:ClearPageInfo(_G.InspectFrame, 'Inspect')
	end
end

function module:UpdatePageStrings(i, iLevelDB, inspectItem, slotInfo, which)
	iLevelDB[i] = slotInfo.iLvl
	local x, y, z, justify = module:GetInspectPoints(i) --* Remember to remove the z on this line

	local db = E.db.wratharmory[string.lower(which)]

	if i == 16 then
		inspectItem.enchantText:ClearAllPoints()
		inspectItem.enchantText:Point('TOPRIGHT', slot, 'BOTTOMRIGHT', 0, 3)
	end

	inspectItem.enchantText:FontTemplate(LSM:Fetch('font', db.enchant.font), db.enchant.fontSize, db.enchant.fontOutline)
	inspectItem.enchantText:SetText(slotInfo.enchantTextShort)
	inspectItem.enchantText:SetShown(db.enchant.enable)
	local enchantTextColor = (db.enchant.qualityColor and slotInfo.itemQualityColors) or db.enchant.color
	if enchantTextColor and next(enchantTextColor) then
		inspectItem.enchantText:SetTextColor(enchantTextColor.r, enchantTextColor.g, enchantTextColor.b)
	end

	inspectItem.iLvlText:ClearAllPoints()
	inspectItem.iLvlText:Point('BOTTOM', inspectItem, db.itemLevel.xOffset, db.itemLevel.yOffset)
	inspectItem.iLvlText:FontTemplate(LSM:Fetch('font', db.itemLevel.font), db.itemLevel.fontSize, db.itemLevel.fontOutline)
	inspectItem.iLvlText:SetText(slotInfo.iLvl)
	local iLvlTextColor = (db.itemLevel.qualityColor and slotInfo.itemQualityColors) or db.itemLevel.color
	if iLvlTextColor and next(iLvlTextColor) then
		inspectItem.iLvlText:SetTextColor(iLvlTextColor.r, iLvlTextColor.g, iLvlTextColor.b)
	end
	inspectItem.iLvlText:SetShown(db.itemLevel.enable)

	if which == 'Inspect' then
		local unit = _G.InspectFrame.unit or 'target'
		if unit then
			local quality = GetInventoryItemQuality(unit, i)
			if quality and quality > 1 then
				inspectItem.backdrop:SetBackdropBorderColor(GetItemQualityColor(quality))
			else
				inspectItem.backdrop:SetBackdropBorderColor(unpack(E.media.bordercolor))
			end
		end
	end

	local gemStep = 1
	for index = 1, 10 do
		local offset = 8+(index*16)
		local newX = ((justify == 'BOTTOMLEFT' or i == 17) and x+offset) or x-offset

		local texture = inspectItem['textureSlot'..index]
		texture:ClearAllPoints()
		texture:Point('BOTTOM', newX, y)

		local backdrop = inspectItem['textureSlotBackdrop'..index]
		local gem = slotInfo.gems and slotInfo.gems[gemStep]
		if gem then
			texture:SetTexture(gem)
			backdrop:SetBackdropBorderColor(unpack(E.media.bordercolor))
			backdrop:Show()

			gemStep = gemStep + 1
		else
			texture:SetTexture()
			backdrop:Hide()
		end
	end
end

local ARMOR_SLOTS = {1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15}
function module:CalculateAverageItemLevel(iLevelDB, unit)
	--* From ElvUI, needs some tlc and be adpated a bit better
	local spec = LCS.GetSpecialization()

	local isOK, total, link = true, 0

	if not spec or spec == 0 then
		-- print('1')
		isOK = false
	end

	-- Armor
	for _, id in next, ARMOR_SLOTS do
		link = GetInventoryItemLink(unit, id)
		if link then
			local cur = iLevelDB[id]
			if cur and cur > 0 then
				total = total + cur
			end
		elseif GetInventoryItemTexture(unit, id) then
			-- print('2')
			isOK = false
		end
	end

	-- Main hand
	local mainItemLevel, mainQuality, mainItemSubClass, _ = 0
	link = GetInventoryItemLink(unit, 16)
	if link then
		mainItemLevel = iLevelDB[16]
		_, _, mainQuality, _, _, _, _, _, _, _, _, _, mainItemSubClass = GetItemInfo(link)
	elseif GetInventoryItemTexture(unit, 16) then
		isOK = false
		-- print('3')
	end

	-- Off hand
	local offItemLevel, offEquipLoc = 0
	link = GetInventoryItemLink(unit, 17)
	if link then
		offItemLevel = iLevelDB[17]
		_, _, _, _, _, _, _, _, offEquipLoc = GetItemInfo(link)
	elseif GetInventoryItemTexture(unit, 17) then
		isOK = false
		-- print('4')
	end

	if mainItemLevel and offItemLevel then
		if mainQuality == 6 or (not offEquipLoc ~= mainItemSubClass and spec ~= 72) then
			mainItemLevel = max(mainItemLevel, offItemLevel)
			total = total + mainItemLevel * 2
		else
			total = total + mainItemLevel + offItemLevel
		end
	end

	-- at the beginning of an arena match no info might be available,
	-- so despite having equipped gear a person may appear naked
	if total == 0 then
		isOK = false
	end

	return format('%0.2f', E:Round(total / 16, 2))
end

function module:UpdateAverageString(frame, which, iLevelDB)
	if not iLevelDB then return end

	local db = E.db.wratharmory[string.lower(which)].avgItemLevel
	local isCharPage = which == 'Character'
	local AvgItemLevel = module:CalculateAverageItemLevel(iLevelDB, isCharPage and 'player' or frame.unit)

	if AvgItemLevel then
		if isCharPage then
			frame.ItemLevelText:SetText(AvgItemLevel)
			frame.ItemLevelText:SetTextColor(db.color.r, db.color.g, db.color.b)
		else
			frame.ItemLevelText:SetText(AvgItemLevel)
			frame.ItemLevelText:SetTextColor(db.color.r, db.color.g, db.color.b)
			frame.ItemLevelText:ClearAllPoints()
			frame.ItemLevelText:Point('CENTER', _G['WrathArmory_'..which..'AvgItemLevel'], 0, -2)
			-- WrathArmory_ItemLevelText.ItemLevelText:SetFormattedText(L["Item level: %.2f"], AvgItemLevel) --* Remember to remove this and remove if not needed
		end
	else
		frame.ItemLevelText:SetText('')
	end

	local avgItemLevelFame = _G['WrathArmory_'..which ..'AvgItemLevel']
	avgItemLevelFame:SetHeight(db.fontSize + 6)
	avgItemLevelFame:SetShown(db.enable)
end

function module:TryGearAgain(frame, which, i, iLevelDB, inspectItem)
	E:Delay(0.05, function()
		if which == 'Inspect' and (not frame or not frame.unit) then return end

		local unit = (which == 'Character' and 'player') or frame.unit
		local slotInfo = module:GetGearSlotInfo(unit, i)
		if slotInfo == 'tooSoon' then return end

		module:UpdatePageStrings(i, iLevelDB, inspectItem, slotInfo, which)
	end)
end

do
	local iLevelDB = {}
	function module:UpdatePageInfo(frame, which, guid)
		-- if not (which and frame and frame.ItemLevelText) then return end --for avgilvlstats window
		if not which or not frame then return end
		if which == 'Inspect' and (not frame or not frame.unit or (guid and frame:IsShown() and UnitGUID(frame.unit) ~= guid)) then return end

		wipe(iLevelDB)

		local waitForItems
		for i = 1, 18 do
			if i ~= 4 then
				local inspectItem = _G[which..InspectItems[i]]
				inspectItem.enchantText:SetText('')
				inspectItem.iLvlText:SetText('')

				local unit = (which == 'Character' and 'player') or frame.unit
				local slotInfo = module:GetGearSlotInfo(unit, i)
				if slotInfo == 'tooSoon' then
					if not waitForItems then waitForItems = true end
					module:TryGearAgain(frame, which, i, iLevelDB, inspectItem)
				else
					-- if slotInfo and slotInfo.gems then
					-- 	for d, gem in ipairs(slotInfo.gems) do
					-- 		print(inspectItem:GetName(), d, gem)
					-- 	end
					-- end
					module:UpdatePageStrings(i, iLevelDB, inspectItem, slotInfo, which)
				end
			end
		end

		if waitForItems then
			E:Delay(0.10, module.UpdateAverageString, module, frame, which, iLevelDB)
		else
			module:UpdateAverageString(frame, which, iLevelDB)
		end
	end
end

local function CreateItemLevel(frame, which)
	if not frame or not which then return end

	local db = E.db.wratharmory[string.lower(which)].avgItemLevel
	local isCharPage = which == 'Character'

	local textFrame = CreateFrame('Frame', 'WrathArmory_'..which ..'AvgItemLevel', (isCharPage and module.Stats) or frame)
	textFrame:Size(170, 30)
	textFrame:Point('TOP', db.xOffset, db.yOffset)

	if not textFrame.bg then
		textFrame.bg = textFrame:CreateTexture(nil, 'BACKGROUND')
	end
	textFrame.bg:SetTexture([[Interface\LevelUp\LevelUpTex]])
	textFrame.bg:ClearAllPoints()
	textFrame.bg:SetPoint('CENTER')
	textFrame.bg:Point('TOPLEFT', textFrame)
	textFrame.bg:Point('BOTTOMRIGHT', textFrame)
	textFrame.bg:SetTexCoord(0.00195313, 0.63867188, 0.03710938, 0.23828125)
	textFrame.bg:SetVertexColor(1, 1, 1, 0.7)

	if not textFrame.lineTop then
		textFrame.lineTop = textFrame:CreateTexture(nil, 'BACKGROUND')
	end
	textFrame.lineTop:SetDrawLayer('BACKGROUND', 2)
	textFrame.lineTop:SetTexture([[Interface\LevelUp\LevelUpTex]])
	textFrame.lineTop:ClearAllPoints()
	textFrame.lineTop:SetPoint('TOP', textFrame.bg, 0, 4)
	textFrame.lineTop:SetTexCoord(0.00195313, 0.81835938, 0.01953125, 0.03320313)
	textFrame.lineTop:Size(textFrame:GetWidth(), 7)

	if not textFrame.lineBottom then
		textFrame.lineBottom = textFrame:CreateTexture(nil, 'BACKGROUND')
	end
	textFrame.lineBottom:SetDrawLayer('BACKGROUND', 2)
	textFrame.lineBottom:SetTexture([[Interface\LevelUp\LevelUpTex]])
	textFrame.lineBottom:ClearAllPoints()
	textFrame.lineBottom:SetPoint('BOTTOM', textFrame.bg, 0, 0)
	textFrame.lineBottom:SetTexCoord(0.00195313, 0.81835938, 0.01953125, 0.03320313)
	textFrame.lineBottom:Size(textFrame:GetWidth(), 7)

	local text = textFrame:CreateFontString(nil, 'OVERLAY')
	text:FontTemplate(LSM:Fetch('font', db.font), db.fontSize, db.fontOutline)
	text:SetText('')
	text:SetPoint('CENTER', 0, -2)
	text:SetTextColor(db.color.r, db.color.g, db.color.b)
	frame.ItemLevelText = text

	module[string.lower(which)] = {}
	module[string.lower(which)].ItemLevelText = text
end

function module:CreateStatsPane()
	local isSkinned = E.private.skins.blizzard.enable and E.private.skins.blizzard.character

	--* Move Rotate Buttons
	CharacterModelFrameRotateLeftButton:ClearAllPoints()
	CharacterModelFrameRotateLeftButton:Point('TOPLEFT', isSkinned and CharacterFrame.backdrop.Center or CharacterFrame, 'TOPLEFT', 3, -3)

	--* Create Stats Frame
	local statsFrame = CreateFrame('Frame', 'WrathArmory_StatsPane', _G.PaperDollItemsFrame, not isSkinned and 'BasicFrameTemplateWithInset')
	statsFrame:SetFrameLevel(_G.CharacterFrame:GetFrameLevel()-1)
	statsFrame:Point('TOPLEFT', CharacterFrame.backdrop or CharacterFrameCloseButton, 'TOPRIGHT', -1, isSkinned and 0 or -5)
	statsFrame:Point('BOTTOMRIGHT', CharacterFrame.backdrop or CharacterFrame, 'BOTTOMRIGHT', 180, isSkinned and 0 or 77)
	module.Stats = statsFrame

	local title = CreateFrame('Frame', nil, statsFrame)
	title:SetWidth(isSkinned and 170 or statsFrame.TitleBg:GetWidth())
	title:SetHeight(isSkinned and 20 or statsFrame.TitleBg:GetHeight())

	if isSkinned then
		--* Adjust CharacterFrame backdrop to be further down and adjust the tabs
		S:HandleFrame(CharacterFrame, true, nil, 11, -12, 0, 65)
		CharacterFrameTab1:ClearAllPoints()
		CharacterFrameTab1:Point('CENTER', CharacterFrame, 'BOTTOMLEFT', 60, 51)

		CharacterHandsSlot:ClearAllPoints()
		CharacterHandsSlot:Point('TOPRIGHT', PaperDollItemsFrame, 'TOPRIGHT', -11, -74)
		CharacterModelFrame:ClearAllPoints()
		CharacterModelFrame:Point('TOP', 0, -78)
		CharacterMainHandSlot:ClearAllPoints()
		CharacterMainHandSlot:Point('TOPLEFT', PaperDollItemsFrame, 'BOTTOMLEFT', 139, 127)

		statsFrame:SetTemplate('Transparent')
		title:SetTemplate('NoBackdrop')
		title:Point('TOP', statsFrame, 'TOP', 0, -5)

		--* Move Character Model Down
		CharacterModelFrame:ClearAllPoints()
		CharacterModelFrame:Point('TOPLEFT', PaperDollFrame, 'TOPLEFT', 65, -108)
	else
		title:Point('CENTER', statsFrame.TitleBg, 'CENTER', 0, 0)
	end

	local t = title:CreateFontString(nil, 'OVERLAY', 'GameTooltipText')
	t:SetPoint('CENTER', 0, 0)
	t:SetText('|cFF16C3F2Wrath|rArmory')
	title:SetScript('OnMouseDown', function (self, button)
		-- if button=='LeftButton' then
			-- LoadAddOn('Blizzard_WeeklyRewards');
			-- WeeklyRewardsFrame:Show()
		-- end
		print('Coming Soon™')
	end)
	statsFrame.title = title

	--* Create Avg Item Level
	CreateItemLevel(CharacterFrame, 'Character')

	--* Organize Resistances and anchor below Character AvgItemLevel Text
	MagicResFrame3:ClearAllPoints()
	MagicResFrame3:Point('TOP', 'WrathArmory_CharacterAvgItemLevel', 'BOTTOM', 0, -15)
	MagicResFrame2:ClearAllPoints()
	MagicResFrame2:Point('RIGHT', MagicResFrame3, 'LEFT', -0.83, 0)
	MagicResFrame1:ClearAllPoints()
	MagicResFrame1:Point('RIGHT', MagicResFrame2, 'LEFT', -0.83, 0)
	MagicResFrame4:ClearAllPoints()
	MagicResFrame4:Point('LEFT', MagicResFrame3, 'RIGHT', 0.83, 0)
	MagicResFrame5:ClearAllPoints()
	MagicResFrame5:Point('LEFT', MagicResFrame4, 'RIGHT', 0.83, 0)

	--* Left Stats Group anchors below MagicResFrame3
	PlayerStatFrameLeftDropDown:ClearAllPoints()
	PlayerStatFrameLeftDropDown:Point('TOP', MagicResFrame3, 'BOTTOM', isSkinned and -5 or 0, -15)
	UIDropDownMenu_SetWidth(PlayerStatFrameLeftDropDown, isSkinned and 140 or 170)
	PlayerStatLeftTop:ClearAllPoints()
	PlayerStatLeftTop:Point('TOP', PlayerStatFrameLeftDropDown, 'BOTTOM', 0, 8)
	PlayerStatLeftTop:Width(isSkinned and 150 or 180)
	PlayerStatLeftMiddle:Width(isSkinned and 150 or 180)
	PlayerStatLeftBottom:Width(isSkinned and 150 or 180)
	PlayerStatFrameLeft1:ClearAllPoints()
	PlayerStatFrameLeft1:Point('TOPLEFT', PlayerStatLeftTop, 'TOPLEFT', 6, -3)

	--* Right Stats Group anchors below Left Stats Group
	PlayerStatFrameRightDropDown:ClearAllPoints()
	PlayerStatFrameRightDropDown:Point('CENTER', PlayerStatLeftBottom, 'CENTER', 0, -35)
	UIDropDownMenu_SetWidth(PlayerStatFrameRightDropDown, isSkinned and 140 or 170)
	PlayerStatRightTop:ClearAllPoints()
	PlayerStatRightTop:Point('TOP', PlayerStatFrameRightDropDown, 'BOTTOM', 0, 8)
	PlayerStatRightTop:Width(isSkinned and 150 or 180)
	PlayerStatRightMiddle:Width(isSkinned and 150 or 180)
	PlayerStatRightBottom:Width(isSkinned and 150 or 180)

	for i = 1, 6 do
		_G['PlayerStatFrameLeft'..i]:Width(isSkinned and 150 or 170)
		_G['PlayerStatFrameRight'..i]:Width(isSkinned and 150 or 170)
	end

	-- f.ScrollFrame = CreateFrame('ScrollFrame', nil, f, 'UIPanelScrollFrameTemplate')
	-- f.ScrollFrame:SetPoint('TOPLEFT', f, 'TOPLEFT', -35, -50)
	-- f.ScrollFrame:SetPoint('BOTTOMRIGHT', f, 'BOTTOMRIGHT', -35, 10)

	-- f.ScrollChild = CreateFrame('Frame', nil, f.ScrollFrame)
	-- f.ScrollChild:SetSize(180, 422)
	-- f.ScrollFrame:SetScrollChild(f.ScrollChild)
	-- _Stats.frame = f


	-- local toggleButton = CreateFrame('Button', 'ECS_ToggleButton', CharacterModelFrame, 'GameMenuButtonTemplate')
	-- toggleButton:SetText('< ECS')
	-- toggleButton:SetSize(44, 18)
end

function module:CreateSlotStrings(frame, which)
	if not frame or not which then return end

	local db = E.db.wratharmory[string.lower(which)]
	local itemLevel = db.itemLevel
	local enchant = db.enchant

	if which == 'Inspect' then
		CreateItemLevel(frame, which)
		InspectFrameTab1:ClearAllPoints()
		InspectFrameTab1:Point('CENTER', InspectFrame, 'BOTTOMLEFT', 60, 51)
	else
		module:CreateStatsPane()
	end

	for i, s in pairs(InspectItems) do
		if i ~= 4 then
			local slot = _G[which..s]

			slot.iLvlText = slot:CreateFontString(nil, 'OVERLAY')
			slot.iLvlText:FontTemplate(LSM:Fetch('font', itemLevel.font), itemLevel.fontSize, itemLevel.fontOutline)
			slot.iLvlText:Point('BOTTOM', slot, itemLevel.xOffset, itemLevel.yOffset)

			slot.enchantText = slot:CreateFontString(nil, 'OVERLAY')
			slot.enchantText:FontTemplate(LSM:Fetch('font', enchant.font), enchant.fontSize, enchant.fontOutline)

			--16 mh
			--17 oh
			--18 relic
			local x, y, z, justify = module:GetInspectPoints(i)
			if i == 16 then
				slot.enchantText:Point('TOPRIGHT', slot, 'BOTTOMRIGHT', -35, 3)
			elseif i == 18 then
				slot.enchantText:Point(i==16 and 'BOTTOMRIGHT' or 'BOTTOMLEFT', slot, i==16 and -35 or 40, 3)
			elseif i == 17 then
				slot.enchantText:Point('TOP', slot, 'BOTTOM', 0, -5)
			else
				slot.enchantText:Point(justify, slot, x + (justify == 'BOTTOMLEFT' and 30 or -30), z)
			end

			for u = 1, 10 do
				local offset = 8+(u*16)
				local newX = ((justify == 'BOTTOMLEFT' or i == 17) and x+offset) or x-offset
				slot['textureSlot'..u], slot['textureSlotBackdrop'..u] = M:CreateInspectTexture(slot, newX, --[[newY or]] y)
			end
		end
	end
end

function module:SetupInspectPageInfo()
	module:CreateSlotStrings(_G.InspectFrame, 'Inspect')
end

function module:UpdateInspectPageFonts(which)
	local frame = _G[which..'Frame']
	if not frame then return end

	local unit = (which == 'Character' and 'player') or frame.unit
	local db = E.db.wratharmory[string.lower(which)]
	local itemLevel, enchant, avgItemLevel = db.itemLevel, db.enchant, db.avgItemLevel

	frame.ItemLevelText:FontTemplate(LSM:Fetch('font', avgItemLevel.font), avgItemLevel.fontSize, avgItemLevel.fontOutline)

	local avgItemLevelFame = _G['WrathArmory_'..which ..'AvgItemLevel']
	avgItemLevelFame:SetHeight(avgItemLevel.fontSize + 6)
	avgItemLevelFame:ClearAllPoints()
	avgItemLevelFame:Point('TOP', avgItemLevel.xOffset, avgItemLevel.yOffset)
	avgItemLevelFame:SetShown(avgItemLevel.enable)

	local slot, quality, iLvlTextColor, enchantTextColor
	local qualityColor = {}
	for i, s in pairs(InspectItems) do
		if i ~= 4 then
			slot = _G[which..s]
			if slot then
				quality = GetInventoryItemQuality(unit, i)
				if quality then
					qualityColor.r, qualityColor.g, qualityColor.b = GetItemQualityColor(quality)
				end

				slot.iLvlText:ClearAllPoints()
				slot.iLvlText:Point('BOTTOM', slot, itemLevel.xOffset, itemLevel.yOffset)
				slot.iLvlText:FontTemplate(LSM:Fetch('font', itemLevel.font), itemLevel.fontSize, itemLevel.fontOutline)
				iLvlTextColor = (itemLevel.qualityColor and qualityColor) or itemLevel.color
				if iLvlTextColor and next(iLvlTextColor) then
					slot.iLvlText:SetTextColor(iLvlTextColor.r, iLvlTextColor.g, iLvlTextColor.b)
				end
				slot.iLvlText:SetShown(itemLevel.enable)

				slot.enchantText:FontTemplate(LSM:Fetch('font', enchant.font), enchant.fontSize, enchant.fontOutline)
				enchantTextColor = (enchant.qualityColor and qualityColor) or enchant.color
				if enchantTextColor and next(enchantTextColor) then
					slot.enchantText:SetTextColor(enchantTextColor.r, enchantTextColor.g, enchantTextColor.b)
				end
				slot.enchantText:SetShown(enchant.enable)
			end
		end
	end
end

function module:ScanTooltipTextures()
	local tt = E.ScanTooltip

	if not tt.gems then
		tt.gems = {}
	else
		wipe(tt.gems)
	end

	for i = 1, 10 do
		local tex = _G['ElvUI_ScanTooltipTexture'..i]
		local texture = tex and tex:IsShown() and tex:GetTexture()
		if texture then
			tt.gems[i] = texture
		end
	end

	return tt.gems
end

function module:GetGearSlotInfo(unit, slot)
	local tt = E.ScanTooltip
	tt:SetOwner(_G.UIParent, 'ANCHOR_NONE')
	tt:SetInventoryItem(unit, slot)
	tt:Show()

	if not tt.SlotInfo then tt.SlotInfo = {} else wipe(tt.SlotInfo) end
	local slotInfo = tt.SlotInfo

	slotInfo.gems = module:ScanTooltipTextures()
	-- print('1', tt.itemQualityColors)
	-- if not tt.itemQualityColors then tt.itemQualityColors = {} else wipe(tt.itemQualityColors) end
	-- print('2', tt.itemQualityColors)

	-- slotInfo.itemQualityColors = tt.itemQualityColors
	slotInfo.itemQualityColors = slotInfo.itemQualityColors or {}

	for x = 1, tt:NumLines() do
		local line = _G['ElvUI_ScanTooltipTextLeft'..x]
		if line then
			local lineText = line:GetText()
			if x == 1 and lineText == RETRIEVING_ITEM_INFO then
				return 'tooSoon'
			end
		end
	end

	local itemLink = GetInventoryItemLink(unit, slot)
	if itemLink then
		local quality = GetInventoryItemQuality(unit, slot)
		slotInfo.itemQualityColors.r, slotInfo.itemQualityColors.g, slotInfo.itemQualityColors.b = GetItemQualityColor(quality)

		local itemLevel = GetDetailedItemLevelInfo(itemLink)
		slotInfo.iLvl = tonumber(itemLevel)

		-- local itemString = select(3, string.find(itemLink, "|H(.+)|h"))
		-- local _, itemId, enchantId, jewelId1, jewelId2, jewelId3, jewelId4, suffixId, uniqueId, linkLevel, specializationID, reforgeId, unknown1, unknown2 = string.split(":", itemString)
		-- print(slot, jewelId1, jewelId2, jewelId3, jewelId4)
		local enchantSpellID = E.Libs.ItemEnchants:GetEnchantSpellID(itemLink)
		if enchantSpellID then
			local enchantName = GetSpellInfo(enchantSpellID)
			slotInfo.enchantTextShort = enchantName or ''
		end
	end

	tt:Hide()

	return slotInfo
end

function module:ADDON_LOADED(_, addon)
	if addon == 'Blizzard_InspectUI' then
		if not _G.InspectFrame.InspectInfoHooked then
			_G.InspectFrame:HookScript('OnShow', function()
				--* Move Rotate Buttons on InspectFrame
				S:HandleFrame(InspectFrame, true, nil, 11, -12, -5, 65)
				local isSkinned = E.private.skins.blizzard.enable and E.private.skins.blizzard.character
				InspectModelFrameRotateLeftButton:ClearAllPoints()
				InspectModelFrameRotateLeftButton:Point('TOPLEFT', (isSkinned and InspectFrame.backdrop.Center) or InspectFrame, 'TOPLEFT', 3, -3)

				-- _G.InspectFrame:Width(410)
				InspectHandsSlot:ClearAllPoints()
				InspectHandsSlot:Point('TOPRIGHT', (isSkinned and InspectFrame.backdrop.Center) or InspectPaperDollItemsFrame, 'TOPRIGHT', -10, -56)

				InspectModelFrame:ClearAllPoints()
				InspectModelFrame:Point('TOP', 0, -78)

				InspectSecondaryHandSlot:ClearAllPoints()
				InspectSecondaryHandSlot:Point('BOTTOM', (isSkinned and InspectFrame.backdrop.Center) or InspectPaperDollItemsFrame, 'BOTTOM', 0, 20)
				InspectMainHandSlot:ClearAllPoints()
				InspectMainHandSlot:Point('TOPRIGHT', (isSkinned and InspectSecondaryHandSlot) or InspectPaperDollItemsFrame, 'TOPLEFT', -5, 0)

				_G.InspectFrame.InspectInfoHooked = true
			end)
		end
		module:SetupInspectPageInfo()
	end
end

function module:Initialize()
	EP:RegisterPlugin(AddOnName, GetOptions)
	E:AddLib('ItemEnchants', 'LibItemEnchants-1.0')

	module:ToggleItemLevelInfo(true)

	if IsAddOnLoaded('Blizzard_InspectUI') then
		module:SetupInspectPageInfo()
	else
		module:RegisterEvent('ADDON_LOADED')
	end

	--[[
	module:UpdateOptions()

	if not ELVUIILVL then
		_G.ELVUIILVL = {}
	end
	]]
end

E.Libs.EP:HookInitialize(module, module.Initialize)