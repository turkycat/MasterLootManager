MasterLootManager = {frame = nil, 
					 debugging = false, 
					 countdownRange = 5, 
					 countdownRunning = false,
                     disenchant = nil,
                     bank = nil,
                     dropdownData = {}, --TODO: change all instanaces of dropdown/Dropdown to dropDown/DropDown to match conventions
                     dropdownGroupData = {};
                     deDropdownFrame = nil, 
                     bankDropdownFrame = nil,
                     settingsDropDownFrame = nil,
                     settingsMenuList = nil,
                     lastRollType = 3,--MasterLootLogger.LootTypeTable.Other;
                     }
                     
MasterLootManagerSettings = {ascending = false,
	                         enforcelow = true,
	                         enforcehigh = true,
                             ignorefixed = true,
							 raidwarning = true,
	                        }

MasterLootTable = {lootCount = 0, loot = {}}

MasterLootRolls = {rollCount = 0, rolls = {}}

function MasterLootManager:Print(str)
	DEFAULT_CHAT_FRAME:AddMessage(str)
end

function MasterLootManager:DebugPrint(str)
	if (MasterLootManager.debugging) then
		DEFAULT_CHAT_FRAME:AddMessage("|cFF15FF15" .. str .. "|r")
	end
end

function MasterLootManager:SelectionButtonClicked(buttonFrame)
	self.selectionFrame:Hide()
	self.currentItemIndex = buttonFrame:GetID()
	self:UpdateCurrentItem()
end

function MasterLootManager:GetClassColor(className)
	if (className == "DEATH KNIGHT") then
		className = "DEATHKNIGHT"
	end
	if (RAID_CLASS_COLORS[className] == nil) then
		self:Print("No such class: " .. className)
		return 0, 0, 0
	end
	return RAID_CLASS_COLORS[className].r, RAID_CLASS_COLORS[className].g, RAID_CLASS_COLORS[className].b
	--[[
	if (className == "DEATHKNIGHT") then
		return 0.77, 0.12, 0.23
	end
	
	if (className == "DRUID") then
		return 1.00, 0.49, 0.04
	end
	
	if (className == "HUNTER") then
		return 0.67, 0.83, 0.45
	end
	
	if (className == "MAGE") then
		return 0.41, 0.80, 0.94
	end
	
	if (className == "PALADIN") then
		return 0.96, 0.55, 0.73
	end
	
	if (className == "PRIEST") then
		return 1.00, 1.00, 1.00
	end
	
	if (className == "ROGUE") then
		return 1.00, 0.96, 0.41
	end
	
	if (className == "SHAMAN") then
		return 0.14, 0.35, 1.00
	end
	
	if (className == "WARLOCK") then
		return 0.58, 0.51, 0.79
	end
	
	if (className == "WARRIOR") then
		return 0.78, 0.61, 0.43
	end
	--]]
end

function MasterLootManager:OnLoad(frame)
	self.frame = frame
	
	self.frame:RegisterEvent("LOOT_OPENED")
	self.frame:RegisterEvent("LOOT_CLOSED")
	self.frame:RegisterEvent("CHAT_MSG_SYSTEM")
	self.frame:RegisterEvent("LOOT_SLOT_CLEARED")
    self.frame:RegisterEvent("RAID_ROSTER_UPDATE")
    self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	 
	self.frame:SetScript("OnEvent", 
			function(frame, event, ...)
				self:OnEvent(self, event, ...)
			end)
			
	self.frame:RegisterForDrag("LeftButton")
	self.frame:SetClampedToScreen(true)
    
    self.settingsDropDownFrame = CreateFrame("Frame", "MasterLootManager_SettingsDropDownFrame", nil, "UIDropDownMenuTemplate")
    
    self:InitializeSettingsMenuList()
    
    for index = 1, 8 do
        self.dropdownData[index] = {};
    end
    
    self:UpdateDropdowns()
    
    UIDropDownMenu_Initialize(self.deDropdownFrame, MasterLootManager.InitializeDropdown);
    UIDropDownMenu_Initialize(self.bankDropdownFrame, MasterLootManager.InitializeDropdown);
	
	self:DebugPrint("MasterLootManager loaded")
end

SLASH_MLM1 = "/mlm"
SlashCmdList["MLM"] = function(msg, editBox)
    local command, rest = msg:match("^(%S*)%s*(.-)$");
    
    MasterLootManager:DebugPrint("Command = " .. command or "")

    if (command == MLM_Local["show"] or command == "") then
        MasterLootManager.frame:Show()
    elseif (command == MLM_Local["hide"]) then
        MasterLootManager.frame:Hide()
    elseif (command == MLM_Local["log"]) then
        MasterLootLogger:SlashCmdHandler(rest, editBox)
    else
        MasterLootManager:Print(MLM_Local["Main_Help1"]..MLM_Local["Main_Help2"]..MLM_Local["Main_Help3"]..MLM_Local["Main_Help4"])
    end
    
end


function MasterLootManager:AwardLootClicked(buttonFrame)
	for winningPlayerIndex = 1, 40 do
		if (GetMasterLootCandidate(winningPlayerIndex)) then
			if (GetMasterLootCandidate(winningPlayerIndex) == MasterLootRolls.winningPlayer) then
				for itemIndex = 1, GetNumLootItems() do
					local itemLink = GetLootSlotLink(itemIndex)
					if (itemLink == MasterLootTable:GetItemLink(self.currentItemIndex)) then
                        MasterLootLogger:ProcessItem(itemLink, MasterLootRolls.winningPlayer, self.lastRollType, MasterLootRolls:GetWinningValue());
						GiveMasterLoot(itemIndex, winningPlayerIndex)
						self:Speak(string.format(MLM_Local["Congratutlations to on winning"], MasterLootRolls.winningPlayer, itemLink))
						return
					end
				end
				self:Print(string.format(MLM_Local["MasterLootManger: Cannot find item - "],MasterLootTable:GetItemLink(self.currentItemIndex)))
			end
		end
	end
	self:Print(string.format(MLM_Local["MasterLootManger: Cannot find player - "],MasterLootRolls.winningPlayer))
end

function MasterLootManager:OnEvent(self, event, ...)
	if (event == "LOOT_OPENED") then
		if (self:PlayerIsMasterLooter()) then
			self:DebugPrint("Loot was opened and the player is the master looter.")
			self:FillLootTable()
			self:UpdateSelectionFrame()
			if (MasterLootTable.lootCount > 0) then
				self.frame:Show()
			end
		else
			self:DebugPrint("Loot was opened, but the player is not the master looter.")
		end
	elseif (event == "LOOT_CLOSED") then
		self.frame:Hide()
	elseif (event == "LOOT_SLOT_CLEARED") then
		if(self:PlayerIsMasterLooter()) then
			self:FillLootTable()
			self:UpdateSelectionFrame()
			if (MasterLootTable.lootCount > 0) then
				self.frame:Show()
			else
				self.frame:Hide()
			end
		end
	elseif (event == "CHAT_MSG_SYSTEM") then
		local message = ...
		self:HandlePossibleRoll(message)   
    elseif (event == "RAID_ROSTER_UPDATE") then
        self:UpdateDropdowns()
    elseif (event == "PLAYER_ENTERING_WORLD") then
        self:UpdateDropdowns()
    end
end

function MasterLootManager:HandlePossibleRoll(message)
	self:DebugPrint(message)
	local rollPattern = MLM_Local["RollPattern"]
	local player, roll, minRoll, maxRoll
	if (self:PlayerIsMasterLooter() and string.find(message, rollPattern)) then
		_, _, player, roll, minRoll, maxRoll = string.find(message, rollPattern)

		self:DebugPrint(player .. " rolled a " .. roll .. " from " .. minRoll .. " to " .. maxRoll)
		if ((minRoll == "1" or not MasterLootManagerSettings.enforcelow) and
            (maxRoll == "100" or not MasterLootManagerSettings.enforcehigh) and
            (minRoll ~= maxRoll or not MasterLootManagerSettings.ignorefixed)) then
		self:DebugPrint(player .. " rolled a " .. roll .. " from " .. minRoll .. " to " .. maxRoll)
			MasterLootRolls:AddRoll(player, tonumber(roll))
		end
	end
end

function MasterLootRolls:AddRoll(player, roll)
	MasterLootManager:DebugPrint("Adding roll for " .. player)
	for rollIndex = 1, self.rollCount do
		if (self.rolls[rollIndex].player == player) then
			-- ignore the roll
			return
		end
	end
	self.rollCount = self.rollCount + 1
	self.rolls[self.rollCount] = {}
	self.rolls[self.rollCount].player = player
	self.rolls[self.rollCount].roll = roll
	
	MasterLootManager:DebugPrint("Added roll for " .. player)
	
	self:UpdateTopRoll()
	
	MasterLootManager:DebugPrint("Winner: " .. self.winningPlayer)
	self:UpdateRollList()
end

function MasterLootRolls:UpdateTopRoll()
    local highestRoll
    if (not MasterLootManagerSettings.ascending) then
	    highestRoll = 0
    else
        highestRoll = 1000001 --max /roll is 1,000,000
    end
    MasterLootManager:DebugPrint("highestRoll: " .. highestRoll);
	for rollIndex = 1, self.rollCount do
		if ((self.rolls[rollIndex].roll > highestRoll and not MasterLootManagerSettings.ascending) or
            (self.rolls[rollIndex].roll < highestRoll and MasterLootManagerSettings.ascending)) then
			highestRoll = self.rolls[rollIndex].roll
			self.winningPlayer = self.rolls[rollIndex].player
		end
	end
end

function MasterLootRolls:GetWinningValue()
    for rollIndex = 1, self.rollCount do
        if(self.rolls[rollIndex].player == self.winningPlayer) then
            return self.rolls[rollIndex].roll;
        end
    end
end

function MasterLootManager:PlayerSelectionButtonClicked(buttonFrame)
	local buttonName = buttonFrame:GetName()
	local playerNameLabel = getglobal(buttonName .. "_PlayerName")
	MasterLootRolls.winningPlayer = playerNameLabel:GetText()
	MasterLootRolls:UpdateRollList()
end

function MasterLootRolls:GetPlayerName(rollIndex)
	return self.rolls[rollIndex].player
end

function MasterLootRolls:GetPlayerRoll(rollIndex)
	return self.rolls[rollIndex].roll
end

function MasterLootRolls:LessThan(i1, v1, i2, v2)
	if (v1 > v2) then
		return false
	elseif (v1 == v2) then
		return i1 < i2
	end
	return true
end

function MasterLootRolls:GreaterThan(i1, v1, i2, v2)
	if (v1 < v2) then
		return false
	elseif (v1 == v2) then
		return i1 > i2
	end
	return true
end

function MasterLootRolls:ClearRolls()
	self.rollCount = 0
	self.rolls = {}
	self:ClearRollList()
end

function MasterLootRolls:ClearRollList()
	local rollIndex = 1
	local rollFrame = getglobal("PlayerSelectionButton" .. rollIndex)
	while (rollFrame ~= nil) do
		rollFrame:Hide()
		rollIndex = rollIndex + 1
		rollFrame = getglobal("PlayerSelectionButton" .. rollIndex)
	end
end


--TODO: fix this to use tsort()
function MasterLootRolls:UpdateRollList()
	local totalHeight = 0
	local scrollFrame = getglobal("MasterLootManagerMain_ScrollFrame")	
	local scrollChild = getglobal("MasterLootManagerMain_ScrollFrame_ScrollChildFrame")
	
	scrollChild:SetHeight(scrollFrame:GetHeight())
	scrollChild:SetWidth(scrollFrame:GetWidth())
	
	local lastRollIndex = 0
    local lastRollValue
    if (not MasterLootManagerSettings.ascending) then
	    lastRollValue = 1000001 --max /roll is 1,000,000
    else
        lastRollValue = 0
    end
	-- Sort on the fly-ish
	for i = 1, self.rollCount do
		local highestRollIndex = 0
		local highestRollValue
        if (not MasterLootManagerSettings.ascending) then
            highestRollValue = 0
        else
            highestRollValue = 1000001 --max /roll is 1,000,000
        end
		-- Find the highest roll that is also less than the previously show roll
        -- Reverse for ascending
		for rollIndex = 1, self.rollCount do
			local rollValue = self:GetPlayerRoll(rollIndex)
			if ((self:LessThan(rollIndex, rollValue, lastRollIndex, lastRollValue) and not MasterLootManagerSettings.ascending) or
                (self:GreaterThan(rollIndex, rollValue, lastRollIndex, lastRollValue) and MasterLootManagerSettings.ascending)) then
				if ((self:GreaterThan(rollIndex, rollValue, highestRollIndex, highestRollValue) and not MasterLootManagerSettings.ascending) or
                    (self:LessThan(rollIndex, rollValue, highestRollIndex, highestRollValue) and MasterLootManagerSettings.ascending)) then
					highestRollIndex = rollIndex
					highestRollValue = rollValue
				end
			end
		end
		lastRollIndex = highestRollIndex
		lastRollValue = highestRollValue
		
		local buttonName = "PlayerSelectionButton" .. lastRollIndex
		local rollFrame = getglobal(buttonName) or CreateFrame("Button", buttonName, scrollChild, "PlayerSelectionButtonTemplate")
		rollFrame:Show()
		
		local playerName = self:GetPlayerName(lastRollIndex)
		local playerNameLabel = getglobal(buttonName .. "_PlayerName")
		local r, g, b = MasterLootManager:GetClassColor(string.upper(UnitClass(playerName)))
		playerNameLabel:SetText(playerName)
		playerNameLabel:SetTextColor(r, g, b)
		
		local starTexture = getglobal(buttonName .. "_StarTexture")
		if (playerName == self.winningPlayer) then
			starTexture:Show()
		else
			starTexture:Hide()
		end
		
		local playerRoll = lastRollValue
		local playerRollLabel = getglobal(buttonName .. "_PlayerRoll")
		playerRollLabel:SetText(playerRoll)
		
		rollFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -totalHeight)
		rollFrame:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)
		totalHeight = totalHeight + rollFrame:GetHeight()
	end
	local slider = getglobal("MasterLootManagerMain_ScrollFrame_Slider")
	local maxValue = totalHeight - scrollChild:GetHeight()
	if (maxValue < 0) then
		maxValue = 0
	end
	slider:SetMinMaxValues(0, maxValue)
	slider:SetValue(0)
end

function MasterLootManager:FillLootTable()
	local oldLootItem
	if (MasterLootTable.lootCount > 0) then
		oldLootItem = MasterLootTable:GetItemLink(self.currentItemIndex)
	end
	MasterLootTable:Clear()
	for lootIndex = 1, GetNumLootItems() do
		if (LootSlotIsItem(lootIndex)) then
			local itemLink = GetLootSlotLink(lootIndex)
			self:DebugPrint("Adding " .. itemLink .. " to loot table")
			MasterLootTable:AddItem(itemLink)
		end
	end
	self.currentItemIndex = 1
	if (oldLootItem ~= nil) then
		for itemIndex = 1, MasterLootTable:GetItemCount() do
			if (oldLootItem == MasterLootTable:GetItemLink(itemIndex)) then
				self.currentItemIndex = itemIndex
			end
		end
	end
	self:UpdateCurrentItem()
end

function MasterLootManager:UpdateSelectionFrame()
	self:CreateBasicSelectionFrame()
	local frameHeight = 5
	for itemIndex = 1, MasterLootTable:GetItemCount() do
		local buttonName = "SelectionButton" .. itemIndex
		local buttonFrame = getglobal(buttonName) or CreateFrame("Button", buttonName, self.selectionFrame, "SelectionButtonTemplate")
		buttonFrame:Show()
		buttonFrame:SetID(itemIndex)
		local itemLink = MasterLootTable:GetItemLink(itemIndex)
		local buttonItemLink = getglobal(buttonName .. "_ItemLink")
		buttonItemLink:SetText(itemLink)
		
		local itemTexture = MasterLootTable:GetItemTexture(itemIndex)
		local buttonItemTexture = getglobal(buttonName .. "_ItemTexture")
		buttonItemTexture:SetTexture(itemTexture)
		
		buttonFrame:SetPoint("TOPLEFT", self.selectionFrame, "TOPLEFT", 0, -frameHeight)
		frameHeight = frameHeight + 37
	end
	self.selectionFrame:SetHeight(frameHeight)
end

function MasterLootTable:GetItemCount()
	return self.lootCount
end

function MasterLootManager:CreateBasicSelectionFrame()
	if (self.selectionFrame == nil) then
		self.selectionFrame = CreateFrame("Frame", nil, UIParent)
		self.selectionFrame:SetBackdrop( {
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true,
			tileSize = 10,
			edgeSize = 10,
			insets = {
				left = 3,
				right = 3,
				top = 3,
				bottom = 3 }})
		self.selectionFrame:SetAlpha(1)
		self.selectionFrame:SetBackdropColor(0, 0, 0, 1)
		
		self.selectionFrame.texture = self.selectionFrame:CreateTexture()
		self.selectionFrame.texture:SetTexture(0, 0, 0, 1)
		self.selectionFrame.texture:SetPoint("TOPLEFT", self.selectionFrame, "TOPLEFT", 3, -3)
		self.selectionFrame.texture:SetPoint("BOTTOMRIGHT", self.selectionFrame, "BOTTOMRIGHT", -3, 3)
		
		self.selectionFrame:SetWidth(200)
		self.selectionFrame:SetHeight(100)
		self.selectionFrame:SetFrameStrata("DIALOG")
		self.selectionFrame:Hide()
	end
	local index = 1
	local buttonName = "SelectionButton" .. index
	local buttonHandle = getglobal(buttonName)
	while (buttonHandle ~= nil) do
		buttonHandle:Hide()
		index = index + 1
		buttonName = "SelectionButton" .. index
		buttonHandle = getglobal(buttonName)
	end
end

function MasterLootManager:UpdateCurrentItem()

	if (MasterLootTable:ItemExists(self.currentItemIndex)) then
		local itemLink = MasterLootTable:GetItemLink(self.currentItemIndex)
		local itemLinkLabel = getglobal("MasterLootManagerMain_CurrentItemLink")
		itemLinkLabel:SetText(itemLink)
		
		local itemTexture = MasterLootTable:GetItemTexture(self.currentItemIndex)
		local currentItemTexture = getglobal("MasterLootManagerMain_CurrentItemTexture")
		currentItemTexture:SetTexture(itemTexture)
		self:DebugPrint("Changed item link")
	else
		self:DebugPrint("Item doesn't exist")	
	end
	
end

function MasterLootTable:ItemExists(index)
	return self.loot[index] ~= nil
end

function MasterLootTable:GetItemLink(index)
	return self.loot[index].itemLink
end

function MasterLootTable:GetItemTexture(index)
	return self.loot[index].itemTexture
end

function MasterLootTable:Clear()
	self.lootCount = 0
	self.loot = {}
end

function MasterLootTable:AddItem(itemLink)
	local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture = GetItemInfo(itemLink)
	local lootThreshold = GetLootThreshold()
	if (itemRarity < lootThreshold) then
		return
	end
	self.lootCount = self.lootCount + 1
	self.loot[self.lootCount] = {}
	self.loot[self.lootCount].itemLink = itemLink
	self.loot[self.lootCount].itemTexture = itemTexture
	MasterLootManager:DebugPrint("New loot count: " .. self.lootCount)
end

function MasterLootManager:SelectItemClicked(buttonFrame)
	if (self.selectionFrame:IsShown()) then
		self.selectionFrame:Hide()
	else
		self.selectionFrame:SetPoint("TOP", buttonFrame, "BOTTOM")
		self.selectionFrame:Show()
	end
end

function MasterLootManager:AnnounceMainSpecClicked(buttonFrame)
	local itemLink = MasterLootTable:GetItemLink(self.currentItemIndex)
	MasterLootRolls:ClearRolls()
	self:Speak(string.format(MLM_Local["Roll on for MAIN spec"], itemLink))
    
    self.lastRollType = MasterLootLogger.LootTypeTable.Mainspec;
end

function MasterLootManager:AnnounceOffSpecClicked(buttonFrame)
	local itemLink = MasterLootTable:GetItemLink(self.currentItemIndex)
	MasterLootRolls:ClearRolls()
	self:Speak(string.format(MLM_Local["Roll on for OFF spec"], itemLink))
    
    self.lastRollType = MasterLootLogger.LootTypeTable.Offspec;
end

function MasterLootManager:AnnounceNoSpecClicked(buttonFrame)
	local itemLink = MasterLootTable:GetItemLink(self.currentItemIndex)
	MasterLootRolls:ClearRolls()
	self:Speak(string.format(MLM_Local["Roll on "], itemLink))
    
    self.lastRollType = MasterLootLogger.LootTypeTable.Other;
end

function MasterLootManager:AnnounceLootClicked(buttonFrame)
	local output = MLM_Local["The boss dropped: "]
	for itemIndex = 1, MasterLootTable:GetItemCount() do
		local itemLink = MasterLootTable:GetItemLink(itemIndex)
        if(strlen(itemLink) + strlen(output) > 255) then
            self:Speak(output)
            output = MLM_Local["The boss dropped: "] .. itemLink
        else
		    output = output .. itemLink
        end
	end
	self:Speak(output)
end

function MasterLootManager:CountdownClicked(buttonFrame)
	self.countdownRunning = true
	self.countdownStartTime = GetTime()
	self.countdownLastDisplayed = self.countdownRange + 1
end

function MasterLootManager:OnUpdate()
	if (self.countdownRunning) then
		local currentCountdownPosition = math.ceil(self.countdownRange - GetTime() + self.countdownStartTime)
		if (currentCountdownPosition < 1) then
			currentCountdownPosition = 1
		end
		local i = self.countdownLastDisplayed - 1
		while (i >= currentCountdownPosition) do
			self:Speak(i)
			i = i - 1
		end
		
		self.countdownLastDisplayed = currentCountdownPosition
		if (currentCountdownPosition <= 1) then
			self.countdownRunning = false
		end
	end
end

function MasterLootManager:Speak(str)
	local chatType = "SAY";
	
	if (self:PlayerIsInAParty()) then
		chatType = "PARTY";
	end
	
	if (self:PlayerIsInARaid()) then
		if(MasterLootManagerSettings.raidwarning) then
			chatType = "RAID_WARNING";
		else
			chatType = "RAID"
		end
	end
	
	SendChatMessage(str, chatType)
end

function MasterLootManager:PlayerIsInAParty()
	return GetNumPartyMembers() ~= 0
end

function MasterLootManager:PlayerIsInARaid()
	return GetNumRaidMembers() ~= 0
end

function MasterLootManager:PlayerIsMasterLooter()
		
	local lootMethod, masterLooterPartyID, masterLooterRaidID = GetLootMethod()
	
	if (masterLooterPartyID and masterLooterPartyID == 0) then
		return true
	end
	
	return false
end

function MasterLootManager:UpdateDropdowns()
    for index = 1, 8 do
        self.dropdownData[index] = wipe(self.dropdownData[index])
        --self.dropdownGroupData[subgroup] = false;
    end
        
    self.dropdownGroupData = wipe(self.dropdownGroupData)
        
    local numRaidMembers = GetNumRaidMembers();
    
    for x = 1, numRaidMembers do
        local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(x);
        --sets the group member key to the players name. Also stores thier raid index. 
        --TODO: figure out why I set the value and key as name, instead of one as x
        self.dropdownData[subgroup][name] = name;
        --TODO: confirm current DE/Bank char is still in raid
        self.dropdownGroupData[subgroup] = true;
    end
end

function MasterLootManager:InitializeDropdown()
    --MasterLootManager:DebugPrint("Dropdown Init Level: " .. UIDROPDOWNMENU_MENU_LEVEL);
    if (UIDROPDOWNMENU_MENU_LEVEL == 2) then
        local groupnumber = UIDROPDOWNMENU_MENU_VALUE;
        groupmembers = MasterLootManager.dropdownData[groupnumber];
        for key, value in pairs(groupmembers) do
            local info = UIDropDownMenu_CreateInfo();
            info.hasArrow = false;
            info.notCheckable = true;
            info.text = key;
            info.value = key;
            info.owner = UIDROPDOWNMENU_OPEN_MENU;
            info.func = MasterLootManager.DropClicked;
            UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);
        end
    end
    
    if (UIDROPDOWNMENU_MENU_LEVEL == 1) then
        for key, value in pairs(MasterLootManager.dropdownData) do
            if (MasterLootManager.dropdownGroupData[key] == true) then
                local info = UIDropDownMenu_CreateInfo();
                info.hasArrow = true;
                info.notCheckable = true;
                info.text = MLM_Local["Group "] .. key;
                info.value = key;
                info.owner = UIDROPDOWNMENU_OPEN_MENU;
                UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL );
            end
        end
   end    
   MasterLootManager:DebugPrint("Dropdown initialized!");
end

function MasterLootManager:DropClicked()
    MasterLootManager:DebugPrint("DropClicked(): this.owner == " .. this.owner:GetName());
    UIDropDownMenu_SetText(this.owner, this.value);
end

function MasterLootManager:AssignDEClicked(buttonFrame)
    local disenchanter = UIDropDownMenu_GetText(MasterLootManager.deDropdownFrame)
    for winningPlayerIndex = 1, 40 do
		if (GetMasterLootCandidate(winningPlayerIndex)) then
			if (GetMasterLootCandidate(winningPlayerIndex) == disenchanter) then
				for itemIndex = 1, GetNumLootItems() do
					local itemLink = GetLootSlotLink(itemIndex)
					if (itemLink == MasterLootTable:GetItemLink(self.currentItemIndex)) then
                        MasterLootLogger:ProcessItem(itemLink, disenchanter, MasterLootLogger.LootTypeTable.Disenchant, 0);
						GiveMasterLoot(itemIndex, winningPlayerIndex)
						self:Speak(string.format(MLM_Local[" will be disenchanted by "],itemLink,disenchanter))
						return
					end
				end
				self:Print(string.format(MLM_Local["MasterLootManger: Cannot find item - "],MasterLootTable:GetItemLink(self.currentItemIndex)))
			end
		end
	end
	self:Print(string.format(MLM_Local["MasterLootManger: Cannot find player - "],disenchanter))
end

function MasterLootManager:AssignBankClicked(buttonFrame)
    local banker = UIDropDownMenu_GetText(MasterLootManager.bankDropdownFrame)
    for winningPlayerIndex = 1, 40 do
		if (GetMasterLootCandidate(winningPlayerIndex)) then
			if (GetMasterLootCandidate(winningPlayerIndex) == banker) then
				for itemIndex = 1, GetNumLootItems() do
					local itemLink = GetLootSlotLink(itemIndex)
					if (itemLink == MasterLootTable:GetItemLink(self.currentItemIndex)) then
                        MasterLootLogger:ProcessItem(itemLink, banker, MasterLootLogger.LootTypeTable.Bank, 0);
						GiveMasterLoot(itemIndex, winningPlayerIndex)
						self:Speak(banker .. " is holding " .. itemLink .. " for the bank.")
						return
					end
				end
				self:Print(string.format(MLM_Local["MasterLootManger: Cannot find item - "],MasterLootTable:GetItemLink(self.currentItemIndex)))
			end
		end
	end
	self:Print(string.format(MLM_Local["MasterLootManger: Cannot find player - "],banker))
end

function MasterLootManager:SettingsClicked(buttonFrame)
    EasyMenu(MasterLootManager.settingsMenuList, MasterLootManager.settingsDropDownFrame, buttonFrame:GetName(), 0, 0, "MENU")
end

function MasterLootManager:InitializeSettingsMenuList()
    self.settingsMenuList = {
        {
            text = MLM_Local["Sort Ascending"],
            func = function() MasterLootManagerSettings.ascending = not MasterLootManagerSettings.ascending end,
            checked = function() return MasterLootManagerSettings.ascending end,
            keepShownOnClick = 1,
        },
        {
            text = MLM_Local["Enforce 1 Roll"],
            func = function() MasterLootManagerSettings.enforcelow = not MasterLootManagerSettings.enforcelow end,
            checked = function() return MasterLootManagerSettings.enforcelow end,
            keepShownOnClick = 1,
        },
        {
            text = MLM_Local["Enforce 100 Roll"],
            func = function() MasterLootManagerSettings.enforcehigh = not MasterLootManagerSettings.enforcehigh end,
            checked = function() return MasterLootManagerSettings.enforcehigh end,
            keepShownOnClick = 1,
        },
        {
            text = MLM_Local["Ignore Fixed Rolls"],
            func = function() MasterLootManagerSettings.ignorefixed = not MasterLootManagerSettings.ignorefixed end,
            checked = function() return MasterLootManagerSettings.ignorefixed end,
            keepShownOnClick = 1,
        },
		{
			text = MLM_Local["Use Raid Warning"],
			func = function() MasterLootManagerSettings.raidwarning = not MasterLootManagerSettings.raidwarning end,
            checked = function() return MasterLootManagerSettings.raidwarning end,
            keepShownOnClick = 1, 
		},
        {
            text = MLM_Local["Close"],
            func = function() CloseDropDownMenus() end,
            notCheckable = 1,
        },
    }
end