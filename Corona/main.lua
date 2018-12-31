--[[
-- TODO: Remove this once we this is built into the simulator
local isSimulator = system.getInfo( "environment" ) == "simulator"
if isSimulator then
	local platformName = system.getInfo( "platformName" )
	if platformName == "Mac OS X" then
		local path = system.pathForFile( "network.dylib" )
		path = string.gsub( path, "network.dylib", "" )
		package.cpath = path .. "?.dylib;" .. package.cpath
	elseif platformName == "Win" then
		local path = system.pathForFile( "main.lua" )
		path = string.gsub( path, "main.lua", "" )
		path = path .. '..\\win32\\Release\\'
		package.cpath = path .. "?.dll;" .. package.cpath
		print( "package.cpath", package.cpath )
	end
end

-- TODO: Remove this once we remove the original network implementation
_G.gameNetwork = nil
package.preload.gameNetwork = nil
package.loaded.gameNetwork = nil

--]]
--*********************************************************************************************
-- ====================================================================
-- Corona "GameCenter Tapper" Sample Code
-- ====================================================================
--
-- File: main.lua
--
-- Version 1.0
--
-- Copyright (C) 2011 Corona Labs Inc. All Rights Reserved.
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of 
-- this software and associated documentation files (the "Software"), to deal in the 
-- Software without restriction, including without limitation the rights to use, copy, 
-- modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, 
-- and to permit persons to whom the Software is furnished to do so, subject to the 
-- following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in all copies 
-- or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
-- INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
-- PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE 
-- FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR 
-- OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
-- DEALINGS IN THE SOFTWARE.
--
-- Published changes made to this software and associated documentation and module files (the
-- "Software") may be used and distributed by Corona Labs, Inc. without notification. Modifications
-- made to this software and associated documentation and module files may or may not become
-- part of an official software release. All modifications made to the software will be
-- licensed under these same terms and conditions.
--*********************************************************************************************
display.setStatusBar( display.DarkStatusBar )

-- create app background
local bg = display.newImageRect( "assets/gcbg.jpg", 320, 480 )
bg.x, bg.y = display.contentWidth*0.5, display.contentHeight*0.5

local widget = require "widget"; widget.setTheme( "theme_ios" )
local storyboard = require "storyboard"
local ui = require "userinterface"	-- handles various user-interface related tasks
local gameNetwork = require "gameNetwork"

-- create toolbar to go at the top of the screen
local titleBar = widget.newTabBar{
	top=20, height=44,
	background="assets/woodbg.png"
}

-- create embossed text to go on toolbar
local titleText = display.newEmbossedText( "Corona GCTapper", 0, 0, ui.boldFont, 20 )
titleText:setTextColor( 255 )
titleText.x, titleText.y = 160, titleBar.y

-- create a shadow underneath the titlebar
local shadow = display.newImage( "assets/shadow.png" )
shadow:setReferencePoint( display.TopLeftReferencePoint )
shadow.x, shadow.y = 0, 64
shadow.xScale = 320 / shadow.contentWidth; shadow.yScale = 0.35

-- setup storyboard scenes (non-external module scenes)
local scoreScene = storyboard.newScene( "scoreScene" )
local boardScene = storyboard.newScene( "boardScene" )

-- variables (and forward declarations)
local requestCallback, userScoreText, currentBoardText, userBestText, bestLabel, bestText
local leaderBoards, achievements = {}, {}
	leaderBoards.Easy = "com.appledts.EasyTapList"
	leaderBoards.Hard = "com.appledts.HardTapList"
	leaderBoards.Awesome = "com.appledts.AwesomeTapList"
	achievements.OneTap = "com.appletest.one_tap"
	achievements.TwentyTaps = "com.appledts.twenty_taps"
	achievements.OneHundredTaps = "com.appledts.one_hundred_taps"
local currentBoard = "Easy"
local userScore, userBest, bestTextValue, topScorer = 0, "0 Taps", "0 Taps", "???"

-- private functions --------------------------------------------------------------------

local function setUserScore( value )
	userScore = value
	if userScoreText then
		local scoreTapString = tostring( userScore ) .. " Taps"; if userScore == 1 then scoreTapString = "1 Tap"; end
		ui.updateLabel( userScoreText, scoreTapString, display.contentWidth-25, 270, display.TopRightReferencePoint )
	end
end

local function offlineAlert() 
	native.showAlert( "GameCenter Offline", "Please check your internet connection.", { "OK" } )
end

-- button event handlers ----------------------------------------------------------------

local function onIncrementScore( event )
	setUserScore( userScore+1 )
	
	-- unlock achievements when specific tap requirement is met
	if loggedIntoGC then
		local message
		
		if userScore == 1 then
			gameNetwork.request( "unlockAchievement", {
				achievement = {
					identifier=achievements["OneTap"],
					percentComplete=100,
					showsCompletionBanner=true,
				}
			}); message = "You completed the \"Just One Tap\" achievement!"
		
		elseif userScore == 10 then
			gameNetwork.request( "unlockAchievement", {
				achievement = {
					identifier=achievements["TwentyTaps"],
					percentComplete=50,
					showsCompletionBanner=true,
				}
			}); message = "You achieved 50% of the \"Work the taps\" achievement!"
		
		elseif userScore == 20 then
			gameNetwork.request( "unlockAchievement", {
				achievement = {
					identifier=achievements["TwentyTaps"],
					percentComplete=100,
					showsCompletionBanner=true,
				}
			}); message = "You completed the \"Work the taps\" achievement!"
		
		elseif userScore == 50 then
			gameNetwork.request( "unlockAchievement", {
				achievement = {
					identifier=achievements["OneHundredTaps"],
					percentComplete=50,
					showsCompletionBanner=true,
				}
			}); message = "You completed 50% of the \"One Hundred Taps\" achievement!"
		
		elseif userScore == 75 then
			gameNetwork.request( "unlockAchievement", {
				achievement = {
					identifier=achievements["OneHundredTaps"],
					percentComplete=75,
					showsCompletionBanner=true,
				}
			}); message = "You completed 75% of the \"One Hundred Taps\" achievement!"
		
		elseif userScore == 100 then
			gameNetwork.request( "unlockAchievement", {
				achievement = {
					identifier=achievements["OneHundredTaps"],
					percentComplete=100,
					showsCompletionBanner=true,
				}
			}); message = "You completed the \"One Hundred Taps\" achievement!"
		end
		if message then native.showAlert( "Achievement Unlocked", message, { "OK" } ); end
	end
end

local function onSubmitScore( event )
	if loggedIntoGC then gameNetwork.request( "setHighScore", { localPlayerScore={ category=leaderBoards[currentBoard], value=userScore }, listener=requestCallback } ); else offlineAlert(); end
end

local function onChangeBoard( event )
	local function alertCompletion( event )
		if event.action == "clicked" and event.index ~= 4 then		
			if 		event.index == 1 then currentBoard = "Awesome";
			elseif 	event.index == 2 then currentBoard = "Easy";
			elseif 	event.index == 3 then currentBoard = "Hard"; end
			
			-- reset current score and update current score and board labels
			userScore = 0
			ui.updateLabel( userScoreText, "0 Taps", display.contentWidth-25, 270, display.TopRightReferencePoint )
			ui.updateLabel( currentBoardText, currentBoard, display.contentWidth-25, 142, display.TopRightReferencePoint )
			
			-- reload best score
			if loggedIntoGC then gameNetwork.request( "loadScores", { leaderboard={ category=leaderBoards[currentBoard], playerScope="Global", timeScope="AllTime", range={1,3} }, listener=requestCallback } ); else offlineAlert(); end
		end
	end
	native.showAlert( "Choose Leaderboard:", "", { "Awesome", "Easy", "Hard", "Cancel" }, alertCompletion )
end

local function onShowBoards( event )
	if loggedIntoGC then gameNetwork.show( "leaderboards", { leaderboard={ category=leaderBoards[currentBoard], timeScope="Week" } } ); else offlineAlert(); end
end

local function onShowAchievements( event )
	if loggedIntoGC then gameNetwork.show( "achievements" ); else offlineAlert(); end
end

local function onResetAchievements( event )
	userScore = 0; userScoreText:setText( "0 Taps" )
	userScoreText:setReferencePoint( display.TopRightReferencePoint )
	userScoreText.x = display.contentWidth-25; userScoreText.y = 270
	
	if loggedIntoGC then gameNetwork.request( "resetAchievements" ); else offlineAlert(); end
end

-- scoreScene (first tab) ---------------------------------------------------------------

function scoreScene:createScene( event )
	local logo = display.newImageRect( self.view, "assets/corona_gc_logos.png", 264, 182 )
	logo.x, logo.y = display.contentWidth * 0.5, 175
	
	local currentScoreLabel = ui.createLabel( self.view, "Current Score:", 25, 270, display.TopLeftReferencePoint, true )
	
	display.remove( userScoreText )
	userScoreText = ui.createLabel( self.view, "0 Taps", display.contentWidth-25, 270, display.TopRightReferencePoint )
	
	local incrementScoreBtn = widget.newButton{ label="Increment Score", top=305, left=21, onRelease=onIncrementScore }
	self.view:insert( incrementScoreBtn )
	
	local submitScoreBtn = widget.newButton{ label="Submit High Score", top=360, left=21, onRelease=onSubmitScore }
	self.view:insert( submitScoreBtn )
end
scoreScene:addEventListener( "createScene", scoreScene )

-- boardScene (second tab) --------------------------------------------------------------

function boardScene:createScene( event )
	local changeBoardBtn = widget.newButton{ label="Change Leaderboard", top=80, left=21, style="sheetBlack", onRelease=onChangeBoard }
	self.view:insert( changeBoardBtn )
	
	local boardLabel = ui.createLabel( self.view, "Leaderboard:", 25, 142, display.TopLeftReferencePoint, true )
	
	display.remove( currentBoardText )
	currentBoardText = ui.createLabel( self.view, currentBoard, display.contentWidth-25, 142, display.TopRightReferencePoint )
	
	local yourLabel = ui.createLabel( self.view, "Your Best", 25, 177, display.TopLeftReferencePoint, true )
	
	display.remove( userBestText )
	userBestText = ui.createLabel( self.view, userBest, display.contentWidth-25, 177, display.TopRightReferencePoint )
	
	display.remove( bestLabel )
	bestLabel = ui.createLabel( self.view, topScorer .. " got:", 25, 212, display.TopLeftReferencePoint, true )
	
	display.remove( bestText )
	bestText = ui.createLabel( self.view, bestTextValue, display.contentWidth-25, 212, display.TopRightReferencePoint )
	
	local showBoardsBtn = widget.newButton{ label="Show Leaderboards", top=255, left=21, onRelease=onShowBoards }
	self.view:insert( showBoardsBtn )
	
	local showAchBtn = widget.newButton{ label="Show Achievements", top=310, left=21, onRelease=onShowAchievements }
	self.view:insert( showAchBtn )
	
	local resetBtn = widget.newButton{ label="Reset Score and Achievements", fontSize=15, top=365, left=21, style="sheetRed", onRelease=onResetAchievements }
	self.view:insert( resetBtn )
end
boardScene:addEventListener( "createScene", boardScene )

-- gamenetwork callback listeners -------------------------------------------------------

function requestCallback( event )
	if event.type == "setHighScore" then
		local function alertCompletion() gameNetwork.request( "loadScores", { leaderboard={ category=leaderBoards[currentBoard], playerScope="Global", timeScope="AllTime", range={1,3} }, listener=requestCallback } ); end
		native.showAlert( "High Score Reported!", "", { "OK" }, alertCompletion )
	
	elseif event.type == "loadScores" then
		if event.data then
			local topRankID = event.data[1].playerID
			local topRankScore = event.data[1].formattedValue
			bestTextValue = string.sub( topRankScore, 1, 12 ) .. "..."
			
			if topRankID then gameNetwork.request( "loadPlayers", { playerIDs={ topRankID }, listener=requestCallback} ); end
		end
		
		if event.localPlayerScore then
			userBest = event.localPlayerScore.formattedValue
		else
			userBest = "Not ranked"
		end
		
		if userBestText then ui.updateLabel( userBestText, userBest, display.contentWidth-25, 177, display.TopRightReferencePoint ); end
	
	elseif event.type == "loadPlayers" then
		if event.data then
			local topRankAlias = event.data[1].alias
			
			if topRankAlias then
				topScorer = topRankAlias
				if bestLabel and bestText then
					ui.updateLabel( bestLabel, topScorer .. " got:", 25, 212, display.TopLeftReferencePoint )
					ui.updateLabel( bestText, bestTextValue, display.contentWidth-25, 212, display.TopRightReferencePoint )
				end
			end
		end
	end
end

local function initCallback( event )
	-- "showSignIn" is only available on iOS 6+
	if event.type == "showSignIn" then
		-- This is an opportunity to pause your game or do other things you might need to do while the Game Center Sign-In controller is up.
		-- For the iOS 6.0 landscape orientation bug, this is an opportunity to remove native objects so they won't rotate.
	-- This is type "init" for all versions of Game Center.
	elseif event.data then
		loggedIntoGC = true
		gameNetwork.request( "loadScores", { leaderboard={ category=leaderBoards[currentBoard], playerScope="Global", timeScope="AllTime", range={1,3} }, listener=requestCallback } )
	end

end

-- system event handler -----------------------------------------------------------------

local function onSystemEvent( event ) 
	if "applicationStart" == event.type then
		loggedIntoGC = false
		gameNetwork.init( "gamecenter", { listener=initCallback } )
		return true
	end
end
Runtime:addEventListener( "system", onSystemEvent )
ui.createTabs( widget )
storyboard.gotoScene( "scoreScene" )

