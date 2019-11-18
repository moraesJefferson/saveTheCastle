-- FILE: scene_menu.lua 
-- DESCRIPTION: start the menu and allow sound on/off

local composer = require( "composer" )

local scene = composer.newScene()

local widget = require "widget"
widget.setTheme( "widget_theme_android_holo_light" )

-- -----------------------------------------------------------------------------------------------------------------
-- All code outside of the listener functions will only be executed ONCE unless "composer.removeScene()" is called.
-- -----------------------------------------------------------------------------------------------------------------

-- local forward references should go here
local btn_play

user = loadsave.loadTable("user.json")

local function onPlayTouch(event)
    if(event.phase == "ended") then 
        audio.play(_CLICK)
        composer.gotoScene("cena1", "slideLeft")
    end
end

local function onSoundsTouch(event)
    if(event.phase == "ended") then 
        if(user.playsound == true) then 
            -- mute the game
            audio.setVolume(0)
            btn_sounds.alpha = 0.5
            user.playsound = false
        else 
            -- unmute the game
            audio.setVolume(1)
            btn_sounds.alpha = 1
            user.playsound = true
        end
        loadsave.saveTable(user, "user.json")
    end
end
-- -------------------------------------------------------------------------------

-- "scene:create()"
function scene:create( event )

    local sceneGroup = self.view

    -- Initialize the scene here.
    -- Example: add display objects to "sceneGroup", add touch listeners, etc.
    local background = display.newImageRect(sceneGroup, "image/menu/teste.png", 1920 , 1080)
        background.x = _CX; background.y = _CY;
        background.xScale = 2
        background.yScale = 2

    -- Create some buttons
    btn_play = widget.newButton (
        {
            label = "Play",
            onEvent = onPlayTouch,
            emboss = false,
            -- Properties for a rounded rectangle button
            shape = "roundedRect",
            width = 500,
            height = 240,
            fillColor = { default={0,1,1,0}, over={0,0,0,0} },
            strokeColor = { default={0,0,0,0}, over={0,0,0,0} },
            labelColor = { default={ 1, 1, 1 }, over={ 0, 0, 0, 0 } },
            strokeWidth = 4,
            fontSize = 200,
            font = native.newFont( "Augusta"),
        }
    )
    btn_play.x = _R * 0.23
    btn_play.y = _B * 0.62
   -- btn_play:setLabel( "Play" )
    sceneGroup:insert(btn_play)

end


-- "scene:show()"
function scene:show( event )

    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        -- Called when the scene is still off screen (but is about to come on screen).
    elseif ( phase == "did" ) then
        -- Called when the scene is now on screen.
        -- Insert code here to make the scene come alive.
        -- Example: start timers, begin animation, play audio, etc.

        local cenaAnterior = composer.getSceneName("previous")
        if(cenaAnterior) then
            composer.removeScene(cenaAnterior)
        end
        audio.stop(2)
        audio.rewind()
        audio.rewind(_MENU)
        audio.play(_MENU,{channel = 1,loops=-1, fadein=2500})
    end
end


-- "scene:hide()"
function scene:hide( event )

    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        -- Called when the scene is on screen (but is about to go off screen).
        -- Insert code here to "pause" the scene.
        -- Example: stop timers, stop animation, stop audio, etc.
    elseif ( phase == "did" ) then
        -- Called immediately after scene goes off screen.
    end
end


-- "scene:destroy()"
function scene:destroy( event )

    local sceneGroup = self.view

    -- Called prior to the removal of scene's view ("sceneGroup").
    -- Insert code here to clean up the scene.
    -- Example: remove display objects, save state, etc.
end


-- -------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-- -------------------------------------------------------------------------------

return scene