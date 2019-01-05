--This file uses a replace method for localization as it remains a largely a work in progress
--This method will allow partial localizations to function
MLM_Local = {}
----DEFAULT----
--Roll regex pattern(the most important string in here, must be correct for the mod to function)
--If you are translating the addon, and don't know how to format this, please just include
--the text of a /roll 100 with your submission and I will format it.
MLM_Local["RollPattern"] = "(.+) rolls (%d+) %((%d+)%-(%d+)%)" -- Credits to the creator of LootHog for this pattern
--commands
MLM_Local["show"] = "show"
MLM_Local["hide"] = "hide"
MLM_Local["log"] = "log"
MLM_Local["clear"] = "clear"
--help
MLM_Local["Main_Help1"] = "Acceptable subcommands to /mlm:"
MLM_Local["Main_Help2"] = "\nshow - shows the roll window"
MLM_Local["Main_Help3"] = "\nhide - hides the roll window"
MLM_Local["Main_Help4"] = "\nlog - access logger related commands"
MLM_Local["Log_Help1"] = "Acceptable subcommands to /mlm log:"
MLM_Local["Log_Help2"] = "\nshow - view the logger window"
MLM_Local["Log_Help3"] = "\nclear - delete all log entries"
--errors
MLM_Local["MasterLootManger: Cannot find item - "] = "MasterLootManger: Cannot find item - %s"
MLM_Local["MasterLootManger: Cannot find player - "] = "MasterLootManger: Cannot find player - %s"
MLM_Local["No item selected"] = "No item selected"
MLM_Local["Attempt to add invalid item"] = "<MLM Logger>Attempt to add invalid item. Possible loss of data."
MLM_Local["Please use a valid item link or item ID"] = "<MLM Logger>Invalid Item: Please use a valid item link or item ID."
MLM_Local["Please enter a valid year"] = "<MLM Logger>Invalid Year: Please enter a valid year."
MLM_Local["Please enter a valid month"] = "<MLM Logger>Invalid Month: Please enter a valid month."
MLM_Local["Please enter a valid day"] = "<MLM Logger>Invalid Day: Please enter a valid day."
MLM_Local["Please enter a valid hour"] = "<MLM Logger>Invalid Hour: Please enter a valid hour."
MLM_Local["Please enter a valid minute"] = "<MLM Logger>Invalid Minute: Please enter a valid minute."
--chat output
MLM_Local["Congratutlations to on winning"] = "Congratulations to %s on winning %s"
MLM_Local["Roll on for MAIN spec"] = "Roll on %s for MAIN spec"
MLM_Local["Roll on for OFF spec"] = "Roll on %s for OFF spec"
MLM_Local["Roll on "] = "Roll on %s"
MLM_Local["The boss dropped: "] = "The boss dropped: "
MLM_Local[" will be disenchanted by "] = "%s will be disenchanted by %s."
MLM_Local[" is holding for the bank."] = "%s is holding %s for the bank."
--Settings
MLM_Local["Sort Ascending"] = "Sort Ascending"
MLM_Local["Enforce 1 Roll"] = "Enforce 1 Roll"
MLM_Local["Enforce 100 Roll"] = "Enforce 100 Roll"
MLM_Local["Ignore Fixed Rolls"] = "Ignore Fixed Rolls"
MLM_Local["Use Raid Warning"] = "Use Raid Warning"
MLM_Local["Close"] = "Close"
--Logger
MLM_Local["Mainspec"] = "Mainspec"
MLM_Local["Offspec"] = "Offspec"
MLM_Local["Other"] = "Other"
MLM_Local["Bank"] = "Bank"
MLM_Local["Disenchant"] = "Disenchant"
--Main UI
MLM_Local["Group "] = "Group "
MLM_Local["Countdown"] = "Countdown"
MLM_Local["M"] = "M"
MLM_Local["O"] = "O"
MLM_Local["R"] = "R"
MLM_Local["Spam Loot"] = "Spam Loot"
MLM_Local["Select Item"] = "Select Item"
MLM_Local["Award Loot"] = "Award Loot"
MLM_Local["Settings"] = "Settings"
MLM_Local["DE"] = "DE"
MLM_Local["Bank"] = "Bank"
--Logger UI
MLM_Local["OK"] = "OK"
MLM_Local["Cancel"] = "Cancel"
MLM_Local["Are you sure you want to delete this log entry?"] = "Are you sure you want to delete this log entry?"
MLM_Local["Enter export string, see readme for details:"] = "Enter export string, see readme for details:"
MLM_Local["Are you sure you want to clear all log entries?"] = "Are you sure you want to clear all log entries?"
MLM_Local["Item"] = "Item"
MLM_Local["Source"] = "Source"
MLM_Local["Winner"] = "Winner"
MLM_Local["Type"] = "Type"
MLM_Local["Value"] = "Value"
MLM_Local["Time"] = "Time"
MLM_Local["Delete"] = "Delete"
MLM_Local["Edit"] = "Edit"
MLM_Local["Add"] = "Add"
MLM_Local["Export"] = "Export"
MLM_Local["Clear"] = "Clear"
MLM_Local["Add/Edit Item"] = "Add/Edit Item"
MLM_Local["Month/Day/Year"] = "Month/Day/Year"
MLM_Local["Confirm"] = "Confirm"
MLM_Local["Copy the data below"] = "Copy the data below and paste it to an external location to save it:"

if (GetLocale()=="frFR") then
	--Roll regex pattern(the most important string in here, must be correct for the mod to function)
	--If you are translating the addon, and don't know how to format this, please just include
	--the text of a /roll 100 with your submission and I will format it.
	MLM_Local["RollPattern"] = "(.+) obtient un (%d+) %((%d+)%-(%d+)%)" -- Credits to the creator of LootHog for this pattern
end

if (GetLocale()=="deDE") then
	--Roll regex pattern(the most important string in here, must be correct for the mod to function)
	--If you are translating the addon, and don't know how to format this, please just include
	--the text of a /roll 100 with your submission and I will format it.
	MLM_Local["RollPattern"] = "(.+) würfelt. Ergebnis: (%d+) %((%d+)%-(%d+)%)" -- Credits to the creator of LootHog for this pattern
end

if (GetLocale()=="esES" or GetLocale()=="esMX") then
	--Roll regex pattern(the most important string in here, must be correct for the mod to function)
	--If you are translating the addon, and don't know how to format this, please just include
	--the text of a /roll 100 with your submission and I will format it.
	MLM_Local["RollPattern"] = "(.+) tira los dados y obtiene (%d+) %((%d+)%-(%d+)%)"  -- Credits to the creator of LootHog for this pattern
end
