MasterLootLogger = {debugging = false,
                    frame = nil,
                    scrollframe = nil,
                    addeditframe = nil,
					addedittypedropdown = nil,
                    
					--Item link caching data
                    itemLoading = false,
                    itemLoadingLastTime = 0,
                    itemLoadingAccumulator = 0,
                    
                    --loot source discovery data
                    lootIsContainer = false,
                    lootSource = "Unknown",
                    
                    --add and edit data
                    isEdit = false,
                    editData = nil,
					addEditTypeMenuList = nil;
                    
                    --delete data
                    deleteData = nil,
                                       
                    --general data
                    lootTypeTextTable = { 
                        GREEN_FONT_COLOR_CODE..MLM_Local["Mainspec"]..FONT_COLOR_CODE_CLOSE,
                        YELLOW_FONT_COLOR_CODE..MLM_Local["Offspec"]..FONT_COLOR_CODE_CLOSE,
                        NORMAL_FONT_COLOR_CODE..MLM_Local["Other"]..FONT_COLOR_CODE_CLOSE,
                        ORANGE_FONT_COLOR_CODE..MLM_Local["Bank"]..FONT_COLOR_CODE_CLOSE,
                        RED_FONT_COLOR_CODE..MLM_Local["Disenchant"]..FONT_COLOR_CODE_CLOSE,
                        },
                        
                    lootTypePlainTextTable = { 
                        MLM_Local["Mainspec"],
                        MLM_Local["Offspec"],
                        MLM_Local["Other"],
                        MLM_Local["Bank"],
                        MLM_Local["Disenchant"],
                        },
                        
                    LootTypeTable = 
                    {
                        Mainspec = 1,
                        Offspec = 2,
                        Other = 3,
                        Bank = 4,
                        Disenchant = 5,
                    },
					
					currentSortType = nil,
					isSortInverse = false,
					
					sortTypeTable = 
					{
						--{ID = pID, Source = pSource, Winner = pWinner, Type = pType, Value = pValue, Year = pYear, Month = pMonth, Day = pDay, Hour = pHour, Minute = pMinute}
						Item = function(a,b) if MasterLootLogger.isSortInverse then return GetItemInfo(a.ID)>GetItemInfo(b.ID) else return GetItemInfo(a.ID)<GetItemInfo(b.ID) end end,
						Source = function(a,b) if MasterLootLogger.isSortInverse then return a.Source>b.Source else return a.Source<b.Source end end,
						Winner = function(a,b) if MasterLootLogger.isSortInverse then return a.Winner>b.Winner else return a.Winner<b.Winner end end,
						Type = function(a,b) if MasterLootLogger.isSortInverse then return a.Type>b.Type else return a.Type<b.Type end end,
						Value = function(a,b) if MasterLootLogger.isSortInverse then return a.Value>b.Value else return a.Value<b.Value end end,
						Time = function(a,b)
							if(a.Year == b.Year) then
								if(a.Month == b.Month) then
									if(a.Day == b.Day) then
										if(a.Hour == b.Hour) then
											if MasterLootLogger.isSortInverse then return a.Minute>b.Minute else return a.Minute<b.Minute end
										end
										if MasterLootLogger.isSortInverse then return a.Hour>b.Hour else return a.Hour<b.Hour end
									end
									if MasterLootLogger.isSortInverse then return a.Day>b.Day else return a.Day<b.Day end
								end
								if MasterLootLogger.isSortInverse then return a.Month>b.Month else return a.Month<b.Month end
							end
							if MasterLootLogger.isSortInverse then return a.Year>b.Year else return a.Year<b.Year end
						end,
					},	
                    
                    --numLogItems = 0,
                    selectedItem = nil,
                   }

--Saved Variables
MasterLootLogger_Log = {}
MasterLootLogger_LastExport = "$I,$N,$S,$W,$T,$V,$H:$M,$m/$d/$y"

function MasterLootLogger:DebugPrint(str)
	if (MasterLootLogger.debugging) then
		DEFAULT_CHAT_FRAME:AddMessage("|cFF15FF15" .. str .. "|r")
	end
end

function MasterLootLogger:Print(str)
	DEFAULT_CHAT_FRAME:AddMessage(str)
end

function MasterLootLogger:OnLoad(frame)
	self.frame = frame
	self.scrollframe = _G["MasterLootLoggerFrameContentScrollFrame"]
    
	self.frame:RegisterForDrag("LeftButton")
	self.frame:SetClampedToScreen(true)
    tinsert(UISpecialFrames,frame:GetName())
    
    MasterLootLogger:MasterLootLoggerFrame_Update()
    
    self.frame:Show()
    
    self.ItemLoadingLastTime = GetTime();
    
    self.frame:RegisterEvent("ADDON_LOADED")
    self.frame:RegisterEvent("UNIT_SPELLCAST_SENT")
    --self.frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    self.frame:RegisterEvent("UNIT_SPELLCAST_FAILED")
    self.frame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    self.frame:RegisterEvent("UNIT_SPELLCAST_FAILED_QUIET")
    self.frame:RegisterEvent("LOOT_CLOSED")
    self.frame:RegisterEvent("LOOT_OPENED")
    
    frame:SetScript("OnEvent", function(frame, event, ...) MasterLootLogger:OnEvent(frame, event, ...) end)
    
    self:DebugPrint("MLM Logger loaded!")
end

--[[Copied here for reference
function AtlasLoot_QueryLootPage()
    i=1;
    local querytime = 0;
    local now = 0;
    while i<31 do
        now = GetTime();
        if now - querytime > 0.03 then
            querytime = GetTime();        
            button = getglobal("AtlasLootItem_"..i);
            queryitem = button.itemID;
            if (queryitem) and (queryitem ~= nil) and (queryitem ~= "") and (queryitem ~= 0) and (string.sub(queryitem, 1, 1) ~= "s") then
                GameTooltip:SetHyperlink("item:"..queryitem..":0:0:0:0:0:0:0");
            end
            i=i+1;
        end
    end
end
]]

function MasterLootLogger:OnEvent(frame, event, ...)
    if event == "UNIT_SPELLCAST_SENT" then
        local unitID, spell, rank, target = ...;
        if spell == GetSpellInfo(3365) then --if we are "Opening" a container, GetSpellInfo for localization
            MasterLootLogger.lootIsContainer = true;
            MasterLootLogger.lootSource = target;
            MasterLootLogger:DebugPrint((unitID or "") .. " | " .. (spell or "") .. " | " .. (rank or "") .. " | " .. (target or ""))
        end
    elseif event == "UNIT_SPELLCAST_FAILED" or  event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED_QUIET" then
        local unitID = ...;
        if unitID == "player" then
            MasterLootLogger.lootIsContainer = false;
            MasterLootLogger.lootSource = "Unknown";
        end
    elseif event == "LOOT_CLOSED" then
        MasterLootLogger.lootIsContainer = false;
        MasterLootLogger.lootSource = "Unknown";
    elseif event == "LOOT_OPENED" then
        if MasterLootLogger.lootIsContainer == false then
            MasterLootLogger.lootSource = UnitName("target");
        end
    elseif event == "ADDON_LOADED" then
        local addonName = ...;
        if addonName == "MasterLootManagerRemix" then
            --self.numLogItems = #MasterLootLogger_Log
            MasterLootLogger:MasterLootLoggerFrame_Update()
        end
    end
end

function MasterLootLogger:SlashCmdHandler(msg, editBox)
    local command, rest = msg:match("^(%S*)%s*(.-)$");
    
    if (command == MLM_Local["show"]) then
        MasterLootLogger.frame:Show()
    elseif (command == MLM_Local["clear"]) then
        wipe(MasterLootLogger_Log)
    else
        MasterLootLogger:Print(MLM_Local["Log_Help1"]..MLM_Local["Log_Help2"]..MLM_Local["Log_Help3"])
    end
end

function MasterLootLogger:OnUpdate()
    --if an itemID returned NIL, see if it has been cached yet
    if (self.itemLoading == true) then
        local now = GetTime()
        self.itemLoadingAccumulator = self.itemLoadingAccumulator + (now - self.itemLoadingLastTime);
        if(self.itemLoadingAccumulator > 5) then --every five seconds
            self:DebugPrint("Re-updating for item loads..."..now)
            self.itemLoadingAccumulator = mod(self.itemLoadingAccumulator, 5)
            MasterLootLogger:MasterLootLoggerFrame_Update()
        end
        self.itemLoadingLastTime = now;
    end
end

function MasterLootLogger:ScrollFrameUpdate()
end

function MasterLootLogger:SortLoot(sorttype)
	if(sorttype == MasterLootLogger.currentSortType) then
		MasterLootLogger.isSortInverse = not MasterLootLogger.isSortInverse
	else
		MasterLootLogger.isSortInverse = false
	end
	MasterLootLogger.currentSortType = sorttype
	
	sort(MasterLootLogger_Log, MasterLootLogger.sortTypeTable[sorttype])
	MasterLootLogger:MasterLootLoggerFrame_Update()
end

function MasterLootLogger:CheckSortInverse(result)
	if(MasterLootLogger.isSortInverse == true) then
		return not result;
	else
		return result;
	end
end

function MasterLootLogger:FormatMinutes(minutes)
    if(minutes<10) then return "0"..minutes else return minutes end
end

function MasterLootLogger:MasterLootLoggerFrame_Update()
	local button, buttonName, buttonHighlight, r, g, b;
	local offset = FauxScrollFrame_GetOffset(MasterLootLogger.scrollframe);
	local index;
	local isLastSlotEmpty;
    local logEntry;
    
    --TODO: Remove unneccecary locals
    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice;
    --TODO: Disable selection-related buttons
	-- Update sort arrows
	MasterLootLogger:UpdateArrow("MasterLootLoggerFrameContentColumnHeader1", "Item")
	MasterLootLogger:UpdateArrow("MasterLootLoggerFrameContentColumnHeader2", "Source")
	MasterLootLogger:UpdateArrow("MasterLootLoggerFrameContentColumnHeader3", "Winner")
	MasterLootLogger:UpdateArrow("MasterLootLoggerFrameContentColumnHeader4", "Type")
	MasterLootLogger:UpdateArrow("MasterLootLoggerFrameContentColumnHeader5", "Value")
	MasterLootLogger:UpdateArrow("MasterLootLoggerFrameContentColumnHeader6", "Time")
    
    MasterLootLogger.itemLoading = false;
    
	for i=1, 9 do
		index = offset + i;
		button = _G["MasterLootLoggerButton"..i];
		-- Show or hide auction buttons
		if ( index > #MasterLootLogger_Log ) then
			button:Hide();
			-- If the last button is empty then set isLastSlotEmpty var
			--isLastSlotEmpty = (i == 9);
		else
            logEntry = MasterLootLogger_Log[index];
			button:Show();
			buttonName = "MasterLootLoggerButton"..i;
            
            itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(logEntry.ID)
            
            if(itemName == nil) then
                --fill in loading information
                MasterLootLogger.itemLoading = true;
                MasterLootLoggerTooltip:SetHyperlink("item:"..logEntry.ID..":0:0:0:0:0:0:0");
                --Set name and quality color
                r, g, b = GetItemQualityColor(0);
                lootName = _G[buttonName.."ItemName"];
                lootName:SetText("Loading...");
                lootName:SetVertexColor(r, g, b);
                -- Set source
                _G[buttonName.."Source"]:SetText("");
                -- Set Win Value
                _G[buttonName.."WinValue"]:SetText("");
                -- Set winner name
                _G[buttonName.."WinnerName"]:SetText("");
                -- Set item texture
                iconTexture = _G[buttonName.."ItemIconTexture"];
                iconTexture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
                -- Set win time
                _G[buttonName.."Time"]:SetText("");
                -- Set Loot Type
                _G[buttonName.."LootType"]:SetText("");
            else
                -- Set name and quality color
                r, g, b = GetItemQualityColor(itemRarity);
                lootName = _G[buttonName.."ItemName"];
                lootName:SetText(itemName);
                lootName:SetVertexColor(r, g, b);
                -- Set source
                _G[buttonName.."Source"]:SetText(logEntry.Source);
                -- Set Win Value
                _G[buttonName.."WinValue"]:SetText(logEntry.Value);
                -- Set winner name
                _G[buttonName.."WinnerName"]:SetText(logEntry.Winner);
                -- Set item texture
                iconTexture = _G[buttonName.."ItemIconTexture"];
                iconTexture:SetTexture(itemTexture);
                -- Set win time
                _G[buttonName.."Time"]:SetText(logEntry.Month.."/"..logEntry.Day.."/"..logEntry.Year.." "..logEntry.Hour..":"..MasterLootLogger:FormatMinutes(logEntry.Minute));
                -- Set Loot Type
                _G[buttonName.."LootType"]:SetText(MasterLootLogger.lootTypeTextTable[logEntry.Type]);
            end

			-- Set highlight
			if ( MasterLootLogger_Log[index] == MasterLootLogger.selectedItem ) then
				button:LockHighlight();
			else
				button:UnlockHighlight();
			end
		end
	end
	
	--Update scrollFrame
	FauxScrollFrame_Update(MasterLootLogger.scrollframe, #MasterLootLogger_Log, 9, 37)
end

function MasterLootLogger:UpdateArrow(buttonName, sortType)
	if (sortType == MasterLootLogger.currentSortType) then
		if (MasterLootLogger.isSortInverse) then
			_G[buttonName.."Arrow"]:Show();
			_G[buttonName.."Arrow"]:SetTexCoord(0, 0.5625, 1.0, 0);
		else
			_G[buttonName.."Arrow"]:Show();
			_G[buttonName.."Arrow"]:SetTexCoord(0, 0.5625, 0, 1.0);
		end
	else
		_G[buttonName.."Arrow"]:Hide();
	end
end

function MasterLootLoggerFrameContentFrameScrollBar_OnVerticalScroll()
    MasterLootLogger:MasterLootLoggerFrame_Update()
end

function MasterLootLogger:MasterLootLoggerItem_OnEnter(index)
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT");
	GameTooltip:SetHyperlink("item:"..MasterLootLogger_Log[index].ID..":0:0:0:0:0:0:0");
end

--Workhorse to add items to the DB
function MasterLootLogger:AddItem(pID, pSource, pWinner, pType, pValue, pYear, pMonth, pDay, pHour, pMinute)
    tinsert(MasterLootLogger_Log, {ID = pID, Source = pSource, Winner = pWinner, Type = pType, Value = pValue, Year = pYear, Month = pMonth, Day = pDay, Hour = pHour, Minute = pMinute})
    --TODO: Add appropriate Sort call
    MasterLootLogger:MasterLootLoggerFrame_Update()
end

--User friendly version of AddItem()
--Fills in certain fields on its own, such as source and time
--pID can be an itemLink or a numeric ID
function MasterLootLogger:ProcessItem(itemLinkOrID, pWinner, pType, pValue)
    local pID;
    pID = tonumber(itemLinkOrID)
    if(pID == nil) then
        _, _, pID = string.find(itemLinkOrID, "^|c%x+|Hitem:(%d+).+|h%[.*%]")
        if(pID == nil) then
            MasterLootLogger:Print(MLM_Local["Attempt to add invalid item"])
            return;
        end;
    end
    
    pSource = MasterLootLogger.lootSource;
    
    local pHour, pMinute = GetGameTime()
    local pMonth, pDay, pYear; 
    _, pMonth, pDay, pYear = CalendarGetDate();
    MasterLootLogger:AddItem(pID, pSource, pWinner, pType, pValue, pYear, pMonth, pDay, pHour, pMinute)
end

function MasterLootLogger:EditItem(table, pID, pSource, pWinner, pType, pValue, pYear, pMonth, pDay, pHour, pMinute)
    table["ID"] = pID; table["Source"] = pSource; table["Winner"] = pWinner; table["Type"] = pType; table["Value"] = pValue;
    table["Year"] = pYear; table["Month"] = pMonth; table["Day"] = pDay; table["Hour"] = pHour; table["Minute"] = pMinute;
    MasterLootLogger:MasterLootLoggerFrame_Update();
end

function MasterLootLogger:MasterLootLoggerButton_OnClick(ID)
    MasterLootLogger:DebugPrint("Button Clicked, ID: " .. ID)
    local offset = FauxScrollFrame_GetOffset(MasterLootLogger.scrollframe);
    MasterLootLogger.selectedItem = MasterLootLogger_Log[ID + offset];
    MasterLootLogger:MasterLootLoggerFrame_Update()
end

function MasterLootLogger:AddClicked()
    local pHour, pMinute = GetGameTime();
    local pMonth, pDay, pYear;
    _, pMonth, pDay, pYear = CalendarGetDate();
    
    _G[self.addeditframe:GetName().."Item"]:SetText("")
    _G[self.addeditframe:GetName().."Source"]:SetText("")
    _G[self.addeditframe:GetName().."Winner"]:SetText("")
    --_G[self.addeditframe:GetName().."Type"]:SetText("")
	UIDropDownMenu_SetText(self.addedittypedropdown, self.lootTypeTextTable[1])
	self.addedittypedropdown.Value = 1;
    _G[self.addeditframe:GetName().."Value"]:SetText("")
    _G[self.addeditframe:GetName().."Year"]:SetText(pYear)
    _G[self.addeditframe:GetName().."Month"]:SetText(pMonth)
    _G[self.addeditframe:GetName().."Day"]:SetText(pDay)
    _G[self.addeditframe:GetName().."Hour"]:SetText(pHour)
    _G[self.addeditframe:GetName().."Minute"]:SetText(pMinute)
    
    self.addeditframe:Show()
end

function MasterLootLogger:EditClicked()
    if(self.selectedItem == nil) then
        return;
    end
    
    self.editData = self.selectedItem;
    
    local _, itemLink = GetItemInfo(self.editData["ID"]) 

    _G[self.addeditframe:GetName().."Item"]:SetText(itemLink)
    _G[self.addeditframe:GetName().."Source"]:SetText(self.editData["Source"])
    _G[self.addeditframe:GetName().."Winner"]:SetText(self.editData["Winner"])
    --_G[self.addeditframe:GetName().."Type"]:SetText(self.editData["Type"])
	UIDropDownMenu_SetText(self.addedittypedropdown, self.lootTypeTextTable[self.editData["Type"]])
	self.addedittypedropdown.Value = self.editData["Type"];
    _G[self.addeditframe:GetName().."Value"]:SetText(self.editData["Value"])
    _G[self.addeditframe:GetName().."Year"]:SetText(self.editData["Year"])
    _G[self.addeditframe:GetName().."Month"]:SetText(self.editData["Month"])
    _G[self.addeditframe:GetName().."Day"]:SetText(self.editData["Day"])
    _G[self.addeditframe:GetName().."Hour"]:SetText(self.editData["Hour"])
    _G[self.addeditframe:GetName().."Minute"]:SetText(self.editData["Minute"])
    
    self.isEdit = true;
    self.addeditframe:Show()
end

function MasterLootLogger:DeleteClicked()
    if(self.selectedItem) then
        local dialog = StaticPopup_Show("MASTERLOOTLOGGER_DELETE_CONFIRMED");
        if (dialog ~= nil) then self.deleteData = self.selectedItem; end
    end
end

StaticPopupDialogs["MASTERLOOTLOGGER_DELETE_CONFIRMED"] = {
	text = MLM_Local["Are you sure you want to delete this log entry?"],
	button1 = MLM_Local["OK"],
	button2 = MLM_Local["Cancel"],
	OnAccept = function()
		MasterLootLogger:DeleteConfirmed();
	end,
    cancels = "MASTERLOOTLOGGER_DELETE_CONFIRMED",
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1
};

function MasterLootLogger:DeleteConfirmed()
    for i = 1, #MasterLootLogger_Log do
        if (MasterLootLogger_Log[i] and self.deleteData == MasterLootLogger_Log[i]) then
            self:DebugPrint("Deleting item " .. i)
            tremove(MasterLootLogger_Log, i);
        end
    end
    self.selectedItem = nil;
    MasterLootLogger:MasterLootLoggerFrame_Update();
end

function MasterLootLogger:ExportClicked()
    StaticPopup_Show("MASTERLOOTLOGGER_EXPORT_FORMAT");
end

StaticPopupDialogs["MASTERLOOTLOGGER_EXPORT_FORMAT"] = {
	text = MLM_Local["Enter export string, see readme for details:"],
	button1 = MLM_Local["OK"],
	button2 = MLM_Local["Cancel"],
	hasEditBox = 1,
    hasWideEditBox = 1,
	maxLetters = 256,
	OnAccept = function(self)
		MasterLootLogger:ShowExport(self.wideEditBox:GetText());
	end,
	OnShow = function(self)
		self.wideEditBox:SetFocus();
        self.wideEditBox:SetText(MasterLootLogger_LastExport)
	end,
	OnHide = function(self)
		if ( ChatFrameEditBox:IsShown() ) then
			ChatFrameEditBox:SetFocus();
		end
		self.wideEditBox:SetText("");
	end,
	EditBoxOnEnterPressed = function(self)
		local parent = self:GetParent();
		MasterLootLogger:ShowExport(parent.wideEditBox:GetText());
		parent:Hide();
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide();
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1
};

function MasterLootLogger:ShowExport(exportFormatString)
    MasterLootLogger_LastExport = exportFormatString;
    
    local box = _G["MasterLootLoggerExportFrameScrollFrameEditBox"]
    local output = MasterLootLogger:BuildExportOutput(exportFormatString)
        
    box:SetText(output)
    box:HighlightText()
	
	_G["MasterLootLoggerExportFrame"]:Show()
end

--[[
StaticPopupDialogs["MASTERLOOTLOGGER_EXPORT_OUTPUT"] = {
	text = "Press CTRL-C to copy the data:",
	button1 = "Close",
	hasEditBox = 1,
    hasWideEditBox = 1,
	maxLetters = 1,
	OnHide = function(self)
		if ( ChatFrameEditBox:IsShown() ) then
			ChatFrameEditBox:SetFocus();
		end
		self.wideEditBox:SetText("");
        self.wideEditBox:SetMultiLine(false)
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide();
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1
};
]]

function MasterLootLogger:BuildExportOutput(exportFormatString)
    local output = "";
    local outputLine = "";
    local lineData = nil;
    local itemName = nil;
    
    for k, lineData in pairs(MasterLootLogger_Log) do
        outputLine = exportFormatString;
        itemName = GetItemInfo(lineData.ID);
        outputLine = gsub(outputLine, "$$", "<MLMDOLLAR>")
        outputLine = gsub(outputLine, "$I", lineData.ID)
        outputLine = gsub(outputLine, "$N", itemName)
        outputLine = gsub(outputLine, "$S", lineData.Source)
        outputLine = gsub(outputLine, "$W", lineData.Winner)
        outputLine = gsub(outputLine, "$T", MasterLootLogger.lootTypePlainTextTable[lineData.Type])
        outputLine = gsub(outputLine, "$V", lineData.Value)
        outputLine = gsub(outputLine, "$H", lineData.Hour)
        outputLine = gsub(outputLine, "$M", MasterLootLogger:FormatMinutes(lineData.Minute))
        outputLine = gsub(outputLine, "$y", lineData.Year)
        outputLine = gsub(outputLine, "$m", lineData.Month)
        outputLine = gsub(outputLine, "$d", lineData.Day)
        outputLine = gsub(outputLine, "<MLMDOLLAR>", "$")
        
        output = output..outputLine.."\r\n";
    end
    
    return output;
end
    

function MasterLootLogger:ClearClicked()
    StaticPopup_Show("MASTERLOOTLOGGER_CLEAR_CONFIRM");
end

StaticPopupDialogs["MASTERLOOTLOGGER_CLEAR_CONFIRM"] = {
	text = MLM_Local["Are you sure you want to clear all log entries?"],
	button1 = MLM_Local["OK"],
	button2 = MLM_Local["Cancel"],
	OnAccept = function()
		wipe(MasterLootLogger_Log)
		MasterLootLogger:MasterLootLoggerFrame_Update()		
	end,
    cancels = "MASTERLOOTLOGGER_CLEAR_CONFIRM",
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1
};

--------------------ADD/EDIT FRAME-----------------------
function MasterLootLogger:AddEditFrameOnLoad(addeditframe)
    self.addeditframe = addeditframe
    
    self.addeditframe:RegisterForDrag("LeftButton")
	self.addeditframe:SetClampedToScreen(true)
    tinsert(UISpecialFrames,self.addeditframe:GetName())
	
	UIDropDownMenu_Initialize(self.addedittypedropdown, MasterLootLogger.InitializeAddEditTypeMenuList)
end

function MasterLootLogger:InitializeAddEditTypeMenuList()
	for i = 1, #MasterLootLogger.lootTypeTextTable do
        local info = UIDropDownMenu_CreateInfo();
        info.hasArrow = false;
        info.notCheckable = true;
        info.text = MasterLootLogger.lootTypeTextTable[i];
        info.value = i;
        info.owner = UIDROPDOWNMENU_OPEN_MENU;
        info.func = MasterLootLogger.AddEditTypeMenuClicked;
        UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);
    end
end

function MasterLootLogger:AddEditTypeMenuClicked()
	UIDropDownMenu_SetText(MasterLootLogger.addedittypedropdown, MasterLootLogger.lootTypeTextTable[this.value])
	MasterLootLogger.addedittypedropdown.Value = this.value
end

function MasterLootLogger:AddEditFrameConfirmClicked()
    local pID, pSource, pWinner, pType, pValue, pYear, pMonth, pDay, pHour, pMinute;
    
    local found, itemLinkOrID;  
    itemLinkOrID = _G[self.addeditframe:GetName().."Item"]:GetText();
    pID = tonumber(itemLinkOrID)
    if(pID == nil) then
        _, _, pID = string.find(_G[self.addeditframe:GetName().."Item"]:GetText(), "^|c%x+|Hitem:(%d+).+|h%[.*%]")
        if(pID == nil) then
            MasterLootLogger:Print(MLM_Local["Please use a valid item link or item ID"])
            return;
        end;
    end
    
    pSource = _G[self.addeditframe:GetName().."Source"]:GetText()
    pWinner = _G[self.addeditframe:GetName().."Winner"]:GetText()
    pType =  tonumber(_G[self.addeditframe:GetName().."Type"].Value)
    pValue = tonumber(_G[self.addeditframe:GetName().."Value"]:GetText())
    pYear = tonumber(_G[self.addeditframe:GetName().."Year"]:GetText())
    pMonth = tonumber(_G[self.addeditframe:GetName().."Month"]:GetText())
    pDay = tonumber(_G[self.addeditframe:GetName().."Day"]:GetText())
    pHour = tonumber(_G[self.addeditframe:GetName().."Hour"]:GetText())
    pMinute = tonumber(_G[self.addeditframe:GetName().."Minute"]:GetText())
    
    --validation
    --[[temp: remove for final]] if (pType == nil or pType < 1 or pType > 5) then MasterLootLogger:Print("<MLM Logger>Invalid Type: Please enter a loot type [1-5]."); return; end;
    if (pValue == nil) then pValue = 0 end;
    if (pYear == nil or pYear < 1) then MasterLootLogger:Print(MLM_Local["Please enter a valid year"]); return; end;
    if (pMonth == nil or pMonth < 1 or pMonth > 12) then MasterLootLogger:Print(MLM_Local["Please enter a valid month"]); return; end;
    if (pDay == nil or pDay < 1 or pDay > 31) then MasterLootLogger:Print(MLM_Local["Please enter a valid day"]); return; end;
    if (pHour == nil or pHour < 0 or pHour > 23) then MasterLootLogger:Print(MLM_Local["Please enter a valid hour"]); return; end;
    if (pMinute == nil or pMinute < 0 or pMinute > 59) then MasterLootLogger:Print(MLM_Local["Please enter a valid minute"]); return; end;
    
    if(MasterLootLogger.isEdit == true) then
        MasterLootLogger:EditItem(self.editData, pID, pSource, pWinner, pType, pValue, pYear, pMonth, pDay, pHour, pMinute);
        MasterLootLogger:StopEdit()
    else
        MasterLootLogger:AddItem(pID, pSource, pWinner, pType, pValue, pYear, pMonth, pDay, pHour, pMinute);
    end
    
    self.addeditframe:Hide()
end

function MasterLootLogger:StopEdit()
    if(self.isEdit == true) then
        self.addeditframe:Hide()
        self.isEdit = false;
        self.editData = false;
    end
end

--ItemLink Intercept
function MasterLootLogger:AddEditCaptureLink(text)
    local itemField = _G[self.addeditframe:GetName().."Item"]
    
    if (itemField:HasFocus() == true) then
        itemField:Insert(text);
        return true;
    end
    
    return false;
end

local old_ChatEdit_InsertLink = ChatEdit_InsertLink;
ChatEdit_InsertLink = function(text)
    return MasterLootLogger:AddEditCaptureLink(text) or old_ChatEdit_InsertLink(text);
end

--Default MasterLoot Intercept
local old_CONFIRM_LOOT_DISTRIBUTION_OnAccept = StaticPopupDialogs["CONFIRM_LOOT_DISTRIBUTION"].OnAccept;
 
StaticPopupDialogs["CONFIRM_LOOT_DISTRIBUTION"].OnAccept = function(self, data)
    local pID;
    
    _, _, pID = string.find(GetLootSlotLink(LootFrame.selectedSlot), "^|c%x+|Hitem:(%d+).+|h%[.*%]")
    
    MasterLootLogger:ProcessItem(pID, data, 3, 0) --loot type other, loot value 0
     
    old_CONFIRM_LOOT_DISTRIBUTION_OnAccept(self, data);
end

local old_GroupLootDropDown_GiveLoot = GroupLootDropDown_GiveLoot

GroupLootDropDown_GiveLoot = function(self)
    if ( not (LootFrame.selectedQuality >= MASTER_LOOT_THREHOLD) ) then
		MasterLootLogger:ProcessItem(GetLootSlotLink(LootFrame.selectedSlot), GetMasterLootCandidate(self.value), MasterLootLogger.LootTypeTable.Other, 0)
	end
    old_GroupLootDropDown_GiveLoot(self)
end