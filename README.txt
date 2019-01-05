Master Loot Manager Remix's logger now includes exporting.
This exporting is designed to support custom formats for
any use the user desires, such as tracking websites. To
use the exporter, open the logger, click the export button
and input a formatting string. The default export string
is a simple CSV(comma separated value) format that can be
open by most spreadsheet programs.

Example CSV format: $I,$N,$S,$W,$T,$V,$H:$M,$m/$d/$y

The following export tokens are available:
$$ - a single dollar sign.
$I - The item ID of the item.
$N - The name of the item.
$S - The source of the item.
$W - The winner of the item.
$T - The loot type (main/off/etc).
$V - The value the item was won with.
$H - Hour
$M - Minute
$y - Year
$m - Month
$d - Day

If you could use any other data, feel free to leave me a
note in the addon comments on curse.com.