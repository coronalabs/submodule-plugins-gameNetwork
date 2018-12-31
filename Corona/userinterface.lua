local ui = {}
ui.boldFont = "HelveticaNeue-Bold"

local storyboard = require "storyboard"

function ui.createLabel( parentGroup, labelText, x, y, referencePoint, isYellow )
	local text = display.newEmbossedText( parentGroup, labelText, 0, 0, ui.boldFont, 18 )
	text:setReferencePoint( referencePoint )
	if isYellow then text:setTextColor( 255, 255, 0 ); else text:setTextColor( 255 ); end
	text.x, text.y = x, y
	return text
end

function ui.updateLabel( textObj, labelText, x, y, referencePoint )
	textObj:setText( labelText )
	textObj:setReferencePoint( referencePoint )
	textObj.x, textObj.y = x, y
end

function ui.createTabs( widget )
	-- create buttons table for the tab bar
	local tabButtons = {
		{
			label="Score",
			default="assets/tabIcon.png",
			down="assets/tabIcon-down.png",
			width=32, height=32,
			onPress=function() storyboard.gotoScene( "scoreScene" ); end,
			selected=true
		},
		{
			label="Boards",
			default="assets/tabIcon.png",
			down="assets/tabIcon-down.png",
			width=32, height=32,
			onPress=function() storyboard.gotoScene( "boardScene" ); end,
		},
	}
	
	-- create a tab-bar and place it at the bottom of the screen
	local tabs = widget.newTabBar{
		top=display.contentHeight-50,
		maxTabWidth = 155,
		buttons=tabButtons
	}
end

return ui