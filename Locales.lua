local _, ns = ...
local L = {
	title = "Forever Drinking",
	drinking = "Drinking",
	optDisplay = "Display",
	optMode = "Show as", optModeTip = "Icon, text or both.",
	modeIcon = "Icon", modeText = "Text", modeBoth = "Icon + text",
	optBlink = "Blink", optBlinkTip = "Lets the indicator fade in and out so it stands out more.",
	optBlinkSpeed = "Blink speed", optBlinkSpeedTip = "Seconds per fade. Smaller = faster blinking.",
	optPosition = "Position",
	optIconAnchor = "Icon position", optTextAnchor = "Text position",
	optAnchor = "Position on the frame", optAnchorTip = "Where on the raid frame the indicator appears. \"Bottom\" centers it in the resource (mana) bar.",
	optOffsetX = "Offset horizontal", optOffsetXTip = "Moves the indicator left/right (pixels).",
	optOffsetY = "Offset vertical", optOffsetYTip = "Moves the indicator up/down (pixels).",
	optIcon = "Icon",
	optIconSize = "Icon size", optIconSizeTip = "Size of the drink icon in pixels.",
	optText = "Text",
	optTextSize = "Text size", optTextSizeTip = "Font size of the text.",
	optOutline = "Text outline", optOutlineTip = "Draws a dark outline around the text for readability.",
	optColor = "Text color", optColorBtn = "Choose color…", optColorTip = "Opens the color picker for the text.",
	optPreview = "Preview on all frames", optPreviewTip = "Shows the indicator on every visible frame so you can adjust it. Turns itself off on reload. Solo: open Edit Mode and tick \"Party Frames\" to see test frames.",
	pageRaid = "Raid frames", pageParty = "Party frames",
	optShowRaid = "On raid frames", optShowRaidTip = "Show on the Blizzard raid frames (and raid-style party frames).",
	optShowParty = "On normal party frames", optShowPartyTip = "Show on the classic Blizzard party frames with portraits.",
	TOPLEFT = "Top left", TOP = "Top", TOPRIGHT = "Top right",
	LEFT = "Left", CENTER = "Center", RIGHT = "Right",
	BOTTOMLEFT = "Bottom left", BOTTOM = "Bottom (resource bar)", BOTTOMRIGHT = "Bottom right",
}
if GetLocale() == "deDE" then
	L.drinking = "Trinkt"
	L.optDisplay = "Anzeige"
	L.optMode = "Anzeigen als"; L.optModeTip = "Symbol, Text oder beides."
	L.modeIcon = "Symbol"; L.modeText = "Text"; L.modeBoth = "Symbol + Text"
	L.optBlink = "Blinken"; L.optBlinkTip = "Lässt die Anzeige ein- und ausblenden, damit sie stärker auffällt."
	L.optBlinkSpeed = "Blinkgeschwindigkeit"; L.optBlinkSpeedTip = "Sekunden pro Ausblenden. Kleiner = schnelleres Blinken."
	L.optPosition = "Position"
	L.optIconAnchor = "Position des Symbols"; L.optTextAnchor = "Position des Textes"
	L.optAnchor = "Position im Feld"; L.optAnchorTip = "Wo im Schlachtzugsfeld die Anzeige erscheint. \"Unten\" setzt sie genau mittig in den Ressourcenbalken (Mana)."
	L.optOffsetX = "Versatz horizontal"; L.optOffsetXTip = "Verschiebt die Anzeige nach links/rechts (Pixel)."
	L.optOffsetY = "Versatz vertikal"; L.optOffsetYTip = "Verschiebt die Anzeige nach oben/unten (Pixel)."
	L.optIcon = "Symbol"
	L.optIconSize = "Symbolgröße"; L.optIconSizeTip = "Größe des Trink-Symbols in Pixeln."
	L.optText = "Text"
	L.optTextSize = "Textgröße"; L.optTextSizeTip = "Schriftgröße des Textes."
	L.optOutline = "Textkontur"; L.optOutlineTip = "Zeichnet eine dunkle Kontur um den Text, damit er besser lesbar ist."
	L.optColor = "Textfarbe"; L.optColorBtn = "Farbe wählen…"; L.optColorTip = "Öffnet die Farbauswahl für den Text."
	L.optPreview = "Vorschau auf allen Feldern"; L.optPreviewTip = "Zeigt die Anzeige auf jedem sichtbaren Feld, damit du sie einstellen kannst. Schaltet sich beim Neuladen wieder aus. Allein: Bearbeitungsmodus öffnen und \"Gruppenfenster\" anhaken, dann erscheinen Testfelder."
	L.pageRaid = "Schlachtzugsfenster"; L.pageParty = "Gruppenfenster"
	L.optShowRaid = "Auf Schlachtzugsfenstern"; L.optShowRaidTip = "Auf den Blizzard-Schlachtzugsfenstern anzeigen (und auf Gruppenfenstern im Schlachtzugsstil). Aussehen einstellbar unter \"Schlachtzugsfenster\"."
	L.optShowParty = "Auf normalen Gruppenfenstern"; L.optShowPartyTip = "Auf den klassischen Blizzard-Gruppenfenstern mit Porträt anzeigen. Aussehen einstellbar unter \"Gruppenfenster\"."
	L.TOPLEFT = "Oben links"; L.TOP = "Oben"; L.TOPRIGHT = "Oben rechts"
	L.LEFT = "Links"; L.CENTER = "Mitte"; L.RIGHT = "Rechts"
	L.BOTTOMLEFT = "Unten links"; L.BOTTOM = "Unten (Ressourcenbalken)"; L.BOTTOMRIGHT = "Unten rechts"
end
ns.L = L
