-- File: scene_game.lua
-- Description: allow the player to play the game

local composer = require( "composer" )
local scene = composer.newScene()


local widget = require "widget"
widget.setTheme( "widget_theme_android_holo_light" )

local physics = require "physics"
physics.start()
physics.setGravity(0,30)
physics.setDrawMode( "normal" )


local playerSheetData = {width=100, height=74, numFrames=13, sheetContentWidth=1300, sheetContentHeight=74}
local playerSheet = graphics.newImageSheet("image/spriteSheet/naoki_sprite2.png", playerSheetData)
local playerSequenceData = {
    {name="shooting", start=1, count=9, time=700, loopCount=1},
    {name="stop", start=10, count=4, time=1000, loopCount=0}
}

local castleSheetData = {width=1427, height=1129, numFrames=3, sheetContentWidth=4281, sheetContentHeight=1129}
local castleSheet = graphics.newImageSheet("image/spriteSheet/castle1_sprite2.png", castleSheetData)
local castleSequenceData = {
    {name="complete", start=1, count=1, time=100, loopCount=0},
    {name="on_attack", start=2, count=1, time=1000, loopCount=0},
    {name="destroy", start=3, count=1, time=1000, loopCount=0}
}

local orcSheetData = {width=77, height=61, numFrames=14, sheetContentWidth=1078, sheetContentHeight=61}
local orcSheet1 = graphics.newImageSheet("image/spriteSheet/orc1_sprite.png", orcSheetData)
local orcSheet2 = graphics.newImageSheet("image/spriteSheet/orc2_sprite.png", orcSheetData)
local orcSheet3 = graphics.newImageSheet("image/spriteSheet/orc3_sprite.png", orcSheetData)
local orcSequenceData = {
    {name="attack", start=1, count=7, time=575, loopCount=0},
    {name="run", start=8, count=7, time=575, loopCount=0}
}

local poofSheetData = {width=165, height=180, numFrames=5, sheetContentWidth=825, sheetContentHeight=180}
local poofSheet = graphics.newImageSheet("image/spriteSheet/poof.png", poofSheetData)
local poofSequenceData = {
    {name="puff", start=1, count=5, time=1000, loopCount=2}
}

local collisionSheetData = {width=165, height=180, numFrames=6, sheetContentWidth=990, sheetContentHeight=180}
local collisionSheet = graphics.newImageSheet("image/spriteSheet/puff_collision.png", collisionSheetData)
local collisionSequenceData = {
    {name="puff_collision", start=1, count=6, time=1000, loopCount=2}
}
-- -----------------------------------------------------------------------------------------------------------------
-- All code outside of the listener functions will only be executed ONCE unless "composer.removeScene()" is called.
-- -----------------------------------------------------------------------------------------------------------------

-- local forward references should go here

-- Create display group for predicted trajectory
local textP1,textP2,textP3
local evento
local teste = false
local line
local predictedPath = display.newGroup()
predictedPath.alpha = 0.2

local intialForceMultiplier = 1 --MOD
local perFrameDelta = 1.005  --MOD
local forceMultiplier = intialForceMultiplier  --MOD
local lastEvent  --MOD

-- Create function forward references
local getTrajectoryPoint
local launchProjectile

local lane = {}

local player, waiting, castelo,textArrow
local castleLife,healthBar,damageBar,nameBar,lifeBar,myText,life,circle
local enemy = {} -- table to hold enemy objects
local enemyCounter = 0 -- number of enemies sent
local enemySendSpeed = 200 -- how often to send the enemies
local enemyTravelSpeed = 10000 -- how fast enemies travel across the scree
local enemyIncrementSpeed = 1.5 -- how much to increase the enemy speed
local enemyMaxSendSpeed = 20 -- max send speed, if this is not set, the enemies could just be one big flood 

local poof = {}
local poofCounter = 0
local poof_collision = {}

local temp
local timeCounter = 0 -- how much time has passed in the game
local pauseGame = false -- is the game paused?
local pauseBackground, btn_pause, pauseText, pause_returnToMenu, pauseReminder -- forward declares

local bullets = {} -- table that will hold the bullet objects
local bulletCounter = 0 -- number of bullets shot
local bulletTransition = {} -- table to hold bullet transitions
local bulletTransitionCounter = 0 -- number of bullet transitions made

local onGameOver, gameOverBox, gameoverBackground, btn_returnToMenu -- forward declare

-- -------------------------------------------------------------------------------


-- "scene:create()"
function scene:create( event )

    local sceneGroup = self.view

    -- Initialize the scene here.
    -- Example: add display objects to "sceneGroup", add touch listeners, etc.

    local function deleteRanking()
        display.remove(textP1)
        display.remove(textP2)
        display.remove(textP3)
    end

    local function returnToMenu(event)
        if(event.phase == "ended") then 
            audio.play(_CLICK)
            user.arrowQtd = user.arrowDefault * user.arrowQtdLevel
            user.xp = 0
            loadsave.saveTable(user, "user.json")
            deleteRanking()
            composer.removeScene( "cena1",false )
            composer.gotoScene("scene_menu", "slideLeft")
        end 
    end

    local function restartGame(event)
        if(event.phase == "ended") then 
            audio.play(_CLICK)
            user.arrowQtd = user.arrowDefault * user.arrowQtdLevel
            user.xp = 0
            loadsave.saveTable(user, "user.json")
            deleteRanking()
            composer.removeScene( "cena1",false )
            composer.gotoScene("cena1", "slideRight")
        end
    end

    local function atualizaScore()
        local score = 0
        if(user.xp >= user.position1) then
            score = user.position1
            user.position1 = user.xp
            user.position3 = user.position2
            user.position2 = score
        elseif(user.xp < user.position1 and user.xp >= user.position2) then
            score = user.position2
            user.position2 = user.xp
            user.position3 = score
        else
            user.position3 = user.xp
        end
        loadsave.saveTable(user, "user.json")
    end

    local function mostraRanking()

        if(user.position1 == 0)then
            textP1 = display.newText("1) -- : -- ", _CX, _CY*0.7, native.newFont( "Augusta"), 90 )
        else
            textP1 = display.newText("1) "..tostring(user.position1).." XP", _CX, _CY*0.7, native.newFont( "Augusta"), 90 )
        end

        if(user.position2 == 0)then
            textP2 = display.newText("2) -- : -- ", _CX, _CY*0.9, native.newFont( "Augusta"), 90 )
        else
            textP2 = display.newText("2) "..tostring(user.position2).." XP", _CX, _CY*0.9, native.newFont( "Augusta"), 90 )
        end

        if(user.position3 == 0)then
            textP3 = display.newText("3) -- : -- ", _CX, _CY/0.9, native.newFont( "Augusta"), 90 )
        else
            textP3 = display.newText("3) "..tostring(user.position3).." XP", _CX, _CY/0.9, native.newFont( "Augusta"), 90 )
        end

        textP1:setFillColor( 255, 255, 255 )
        textP2:setFillColor( 255, 255, 255 )
        textP3:setFillColor( 255, 255, 255 )
    end

    local function verificaTotalDeFlechas(event)
        if(user.arrowQtd == 0) then
            display.remove(castelo)
            display.remove(player)
            display.remove(healthBar)
            display.remove(damageBar)
            display.remove(life)
            display.remove(lifeBar)
            display.remove(circle)

            onGameOver()
        end
    end
    local background = display.newImageRect(sceneGroup, "image/cenarios/cena1_full.png", 1920, 1080)
    background.x = _CX
    background.y = _CY
    background.xScale = 2
    background.yScale = 2

    local qtdArrow = display.newImageRect(sceneGroup, "image/spriteSheet/arrow_reta.png", 54, 54)
    qtdArrow.x = _L*0.925
    qtdArrow.y = 150
    qtdArrow.xScale = 2
    qtdArrow.yScale = 2

    textArrow = display.newText( " x"..tostring(user.arrowQtd), qtdArrow.x+100, qtdArrow.y, native.newFont( "Augusta"), 90 )
    textArrow:setFillColor( 255, 255, 255 )

    textScore = display.newText( "SCORE  "..tostring(user.xp), _CX-300, _CY * 0.15, native.newFont( "Augusta"), 110 )
    textScore:setFillColor( 255, 255, 255 )

    for i=1,2,1 do 
        lane[i] = display.newImageRect(sceneGroup, "image/cenarios/road.png", 3500, 100)
        lane[i].x = _CX * 0.775
        if(i==1) then
            lane[i].y = _B * 0.85
        else
            lane[i].y = _B - 190
        end
        lane[i].id = i
    end 

    local rect1 = display.newRect( _R * 0.7, _B+75 ,1500,20)
    rect1:setFillColor(0,0,0,0)
    rect1.strokeWidth = 6
    rect1:setStrokeColor(0)
    physics.addBody(rect1,'static',{bounce=0.0,friction=0.0})

    castelo = display.newSprite(castleSheet, castleSequenceData)
    castelo.id = "castelo"
    castelo.name = "castelo"
    castelo.width = 800
    castelo.height = 700
    castelo.x = _R * 0.9
    castelo.y = _B * 0.63
    castelo.xScale = 1.15
    castelo.yScale = 1.2
    sceneGroup:insert(castelo)
    physics.addBody(castelo,'dynamic',{isSensor= false,radius=770,density=500.0,bounce=0.0,friction=0.3})
    castelo:setSequence("complete")
    castelo:play()
    castelo.isVisible = true;

    player = display.newSprite(playerSheet, playerSequenceData)     
    player.x = _CX / 0.4
    player.y = _CY / 0.82
    player.force = 0
    player.id = "player_shoot"
    player.xScale = 3
    player.yScale = 3
    sceneGroup:insert(player)
    player:setSequence("stop")
    player:play()
    player.isVisible = true;


    local function stop()
        player:setSequence("stop")
        player:play() 
    end

    local function countArrowText()
        textArrow.text = " x"..tostring(user.arrowQtd)
    end

    local function countScoreText()
        textScore.text = "SCORE  "..tostring(user.xp)
    end
 
    function castleHealthDemage()
        local maxHealth = 900
        local currentHealth = 900

        healthBar = display.newRect(sceneGroup,_R * 0.595 + 190, 185, user.castleLife, 60)
        healthBar.strokeWidth = 3
        healthBar:setFillColor( 0, 255, 0 )
        healthBar:setStrokeColor( 0, 0, 0 )
        healthBar.path.x1 = 30

        damageBar = display.newRect(sceneGroup,_R * 0.595 + 190 , 185, 0, 60)
        damageBar:setFillColor( 0, 0, 0 )
       
        lifeBar = display.newRect(sceneGroup,_R * 0.8, 245, 349, 45 )
        lifeBar.strokeWidth = 5
        lifeBar:setFillColor( 255,255,255 )
        lifeBar:setStrokeColor( 255,255,255 )
        lifeBar.path.x1 = 30


        life = display.newText("CASTLE", lifeBar.x, lifeBar.y, native.newFont( "Augusta"), 58 )
        life:setFillColor( 0, 0, 0 )

        circle = display.newRect(sceneGroup, _R*0.925, 170, 205, 200 )
        circle.strokeWidth = 10
        circle:setFillColor( 0.5 )
        circle:setStrokeColor( 0, 0, 0 )

        local paint = {
            type = "image",
            filename = "image/cenarios/castle_life.png"
        }

        circle.fill = paint

        local function updateDamageBar()

            if(damageBar.width == 0)then
                damageBar.strokeWidth = 3
                damageBar:setStrokeColor( 0, 0, 0 )
                damageBar.path.x1 = 30
            end

            damageBar.width = maxHealth - currentHealth
            damageBar.x = healthBar.x - (healthBar.width/2 - damageBar.width/2)
            if(currentHealth < 0) then
                currentHealth = 0
            end
        end
    
        local closure = function(damageTaken)
            currentHealth = currentHealth - damageTaken
            if(currentHealth  <= 600 and currentHealth > 0) then
                castelo:setSequence("on_attack")
                castelo:play()
            elseif(currentHealth <= 0) then
                timer.performWithDelay( 300, onGameOver )
            end
            updateDamageBar()
        end
        return closure
    end

    castleLife = castleHealthDemage()


    local function sendEnemies()
        -- timeCounter : keeps track of the time in the game, starts at 0
        -- enemySendSpeed : will tell us how often to send the enemies, starts at 75
        -- enemyCounter : keeps track of the number of enemies on the screen, starts at 0
        -- enemyIncrementSpeed : how much to increase the enemy speed, starts at 1.5
        -- enemyMaxSendSpeed : limit the send speed to 20, starts at 20

        -- In math terms, Modulo (%) will return the remainder of a division. 10%2=0, 11%2=1, 14%5=4, 19%8=3
        timeCounter = timeCounter + 1
        if((timeCounter%enemySendSpeed) == 0) then 
            enemyCounter = enemyCounter + 1
            enemySendSpeed = 1800
            --enemySendSpeed = enemySendSpeed - enemyIncrementSpeed
            if(enemySendSpeed <= enemyMaxSendSpeed) then 
                enemySendSpeed = enemyMaxSendSpeed
            end 
            temp = math.random(1,3)

            temp_lane = math.random(1,2)

            if(temp == 1) then 
                enemy[enemyCounter] = display.newSprite(orcSheet1, orcSequenceData)
            elseif(temp == 2) then 
                enemy[enemyCounter] = display.newSprite(orcSheet2, orcSequenceData)
            else 
                enemy[enemyCounter] = display.newSprite(orcSheet3, orcSequenceData)
            end

            enemy[enemyCounter].x = _L - 50
            enemy[enemyCounter].y = lane[temp_lane].y-75
            enemy[enemyCounter].id = "enemy"
            enemy[enemyCounter].name = "enemy"..temp
            enemy[enemyCounter].xScale = 3
            enemy[enemyCounter].yScale = 3
            physics.addBody(enemy[enemyCounter],'kinematic',{isSensor=true,radius = 80,bounce=0.0,friction=0.0})
            enemy[enemyCounter].isFixedRotation = true 
            sceneGroup:insert(enemy[enemyCounter])

            transition.to(enemy[enemyCounter], {x=_R+50, time=enemyTravelSpeed, onComplete=function(self) 
                if(self~=nil) then 
                    display.remove(self);
                end 
            end})

            enemy[enemyCounter]:setSequence("run")
            enemy[enemyCounter]:play()

        end
    end

    getTrajectoryPoint = function( startingPosition, startingVelocity, n )
 
        -- Velocity and gravity are given per second but we want time step values
        local t = 1/display.fps  -- Seconds per time step at 60 frames-per-second (default)
        local stepVelocity = { x=t*startingVelocity.x, y=t*startingVelocity.y }
        local gx, gy = physics.getGravity()
        local stepGravity = { x=t*0, y=t*gy }
        return {
            x = startingPosition.x  + n * stepVelocity.x + 0.25 * (n*n+n) * stepGravity.x,
            y = startingPosition.y + n * stepVelocity.y + 0.25 * (n*n+n) * stepGravity.y
        }
    end

    local function updatePrediction(event)
        lastEvent = event

        display.remove( predictedPath )
        predictedPath = display.newGroup()
        predictedPath.alpha = 0.2
 
        local startingVelocity = { x=player.x-event.xStart, y=player.y-event.yStart }

        startingVelocity.x = startingVelocity.x * forceMultiplier --MOD
        startingVelocity.y = startingVelocity.y * forceMultiplier --MOD
    end

    local function enemyHit(x,y)
        audio.play(_ENEMYHIT)

        poof = display.newSprite(poofSheet, poofSequenceData)
            poof.x = x
            poof.y = y
            sceneGroup:insert(poof)
        poof:setSequence("puff")
        poof:play()

        local function removePoof()
            if(poof~=nil) then 
                display.remove(poof)
            end
        end
        timer.performWithDelay(255, removePoof, 1)
    end

    local function castleHit(x,y)
        audio.play(_ENEMYHIT)

        poof_collision = display.newSprite(collisionSheet, collisionSequenceData)
        poof_collision.x = x
        poof_collision.y = y
        sceneGroup:insert(poof_collision)
        poof_collision:setSequence("puff_collision")
        poof_collision:play()

        local function removePoofCollision()
            if(poof_collision~=nil) then 
                display.remove(poof_collision)
            end
        end
        timer.performWithDelay(255, removePoofCollision, 1)
    end

    local function onCollision(event)

        local function removeOnEnemyHit(obj1, obj2)
            display.remove(obj1)
            display.remove(obj2)
            teste = true
            user.arrowQtd =  user.arrowQtd + user.arrowRecovered
            if(user.arrowQtd > 30) then
                user.arrowQtd = 30
            end
            loadsave.saveTable(user, "user.json")
            countArrowText()
            if(obj1.id == "enemy") then 
                enemyHit(event.object1.x, event.object1.y)
                if(obj1.name == "enemy1") then
                    user.xp = user.xp + user.orc1Xp
                elseif(obj1.name == "enemy2") then
                    user.xp = user.xp + user.orc2Xp
                else
                    user.xp = user.xp + user.orc3Xp
                end
                loadsave.saveTable(user, "user.json")
                countScoreText()
            else
                enemyHit(event.object2.x, event.object2.y)
                if(obj2.name == "enemy1") then
                    user.xp = user.xp + user.orc1Xp
                elseif(obj2.name == "enemy2") then
                    user.xp = user.xp + user.orc2Xp
                else
                    user.xp = user.xp + user.orc3Xp
                end
                loadsave.saveTable(user, "user.json")
                countScoreText()
            end
        end

        local function removeOnPlayerHit(obj1, obj2)
            if(obj1 ~= nil and obj1.id == "enemy") then
                castleHit(event.object1.x+80, event.object1.y)
                enemyHit(event.object1.x, event.object1.y)
                if(obj1.name == "enemy1") then
                    castleLife(user.orc1Damage)
                elseif(obj1.name == "enemy2") then
                    castleLife(user.orc1Damage)
                else
                    castleLife(user.orc3Damage)
                end
                display.remove(obj1)
            end
            if(obj2 ~= nil and obj2.id == "enemy") then
                castleHit(event.object2.x+80, event.object2.y)
                enemyHit(event.object2.x, event.object2.y)
                if(obj2.name == "enemy1") then
                    castleLife(user.orc1Damage)
                elseif(obj2.name == "enemy2") then
                    castleLife(user.orc1Damage)
                else
                    castleLife(user.orc3Damage)
                end
                display.remove(obj2)
            end
        end

        local function spriteListenerEnemy( event )
            if (event.phase == "loop" and event.target.sequence == "attack" ) then
                removeOnPlayerHit(nil, evento)
            end
        end

        if((event.object1.id == "bullet" and event.object2.id == "enemy") or (event.object1.id == "enemy" and event.object2.id == "bullet")) then 
            enemySendSpeed = 5
            timeCounter = 1
            removeOnEnemyHit(event.object1, event.object2)
        elseif(event.object1.id == "enemy" and event.object2.id == "castelo") then 
            enemySendSpeed = 5
            timeCounter = 1
            evento = event.object1
            enemy[enemyCounter]:addEventListener( "sprite", spriteListenerEnemy )
            transition.cancel()
            enemy[enemyCounter]:setSequence("attack")
            enemy[enemyCounter]:play()
        elseif(event.object1.id == "castelo" and event.object2.id == "enemy") then
            enemySendSpeed = 5
            timeCounter = 1 
            evento = event.object2
            enemy[enemyCounter]:addEventListener( "sprite", spriteListenerEnemy )
            transition.cancel()
            enemy[enemyCounter]:setSequence("attack")
            enemy[enemyCounter]:play()
        end

    end
 
    local function enterFrame( )
        forceMultiplier = forceMultiplier * perFrameDelta
        if(forceMultiplier >=1 and forceMultiplier <=1.25) then
            line:setStrokeColor(0,255,0)
        elseif(forceMultiplier > 1.25 and forceMultiplier <= 1.75) then
            line:setStrokeColor(255,255,0)
        elseif(forceMultiplier > 1.75) then
            line:setStrokeColor(255,0,0)
        end
        if( lastEvent ) then
            updatePrediction(lastEvent)
        end
    end

    local function playerShoot( event )
        evento = event
            local eventX, eventY = event.x, event.y
           
                if ( evento.phase == "began" ) then
                    forceMultiplier = intialForceMultiplier --MOD
                    Runtime:addEventListener( "enterFrame", enterFrame ) --MOD
                    line = display.newLine( eventX, eventY, eventX, eventY )
                    line.strokeWidth = 8
                    line.alpha = 0.6  --MOD 
                elseif(evento.phase == "moved") then
                    display.remove( line )
                    line = display.newLine( evento.xStart, evento.yStart, eventX, eventY )
                    line.strokeWidth = 8  
                    line.alpha = 0.6 --MOD
                    line:setStrokeColor(0,255,0)
                    updatePrediction( evento )
                else 
                    display.remove( line )
                    updatePrediction( evento )
                    player:setSequence("shooting")
                    player:play()
                    Runtime:removeEventListener( "enterFrame", enterFrame )
                    Runtime:removeEventListener( "touch", playerShoot)

                end
        return true
    end

    local function shoot(event)
        if(evento.xStart ~= nil and evento.yStart ~= nil) then
            audio.play(_THROW)

            bulletCounter = bulletCounter + 1
            bullets[bulletCounter] = display.newImageRect(sceneGroup, "image/spriteSheet/Arrow.png", 54, 54)
            bullets[bulletCounter].x = player.x  
            bullets[bulletCounter].y = player.y
            bullets[bulletCounter].xScale = 2
            bullets[bulletCounter].yScale = 2
            bullets[bulletCounter]:setStrokeColor(0,0,0)
            bullets[bulletCounter].id = "bullet"
            physics.addBody(bullets[bulletCounter],'dynamic',{density = 30.0, bounce = 0.2, radius=4})
            bullets[bulletCounter].isSensor = true
            local vx, vy = (evento.x-evento.xStart)*-1, (evento.y-evento.yStart)*-1
            bullets[bulletCounter].rotation = (math.atan2(vy*-1, vx *-1) * 180 / math.pi)
            bullets[bulletCounter].isFixedRotation = true
            bullets[bulletCounter]:setLinearVelocity( vx * forceMultiplier ,vy * forceMultiplier )
            bullets[bulletCounter].angularVelocity = -40
            bullets[bulletCounter].gravityScale = 2
        end

        local function isArrowInScreen(obj)
            if( (obj.x - (obj.width/2)) > _R ) then return false end
            if( (obj.x + (obj.width/2)) < _L) then return false end
            if( (obj.y + (obj.height/2)) < _T ) then return false end
            if( (obj.y - (obj.height/2)) > _B ) then return false end
            return true
        end

        local function verificaTela()
            if(teste == true) then
                Runtime:removeEventListener( "enterFrame", verificaTela)
                Runtime:addEventListener( "touch", playerShoot)
                user.arrowQtd =  user.arrowQtd - 1
                loadsave.saveTable(user, "user.json")
                countArrowText()
                teste = false
            elseif(isArrowInScreen(bullets[bulletCounter]) ~= true) then
                if( bullets[bulletCounter]~=nil) then 
                    display.remove( bullets[bulletCounter])
                    Runtime:removeEventListener( "enterFrame", verificaTela)
                    user.arrowQtd =  user.arrowQtd - 1
                    loadsave.saveTable(user, "user.json")
                    countArrowText()
                    teste = false
                end
                Runtime:addEventListener( "touch", playerShoot)
            end
        end
        Runtime:addEventListener( "enterFrame", verificaTela)
    end
  
    local function spriteListener( event )
        if(event.phase == "ended" and event.target.sequence == "shooting" ) then
            stop()
        elseif (player.frame == 8 and event.target.sequence == "shooting" ) then
            shoot(evento)
        end
    end

    function onGameOver()
        audio.play(_GAMEOVER)
        atualizaScore()

        player:removeEventListener( "sprite", spriteListener )
        Runtime:removeEventListener( "touch", playerShoot)
        Runtime:removeEventListener("enterFrame", sendEnemies)
        Runtime:removeEventListener("collision", onCollision)
        Runtime:removeEventListener( "enterFrame", verificaTotalDeFlechas)

        transition.pause()

        display.remove(player)
        display.remove(healthBar)
        display.remove(damageBar)
        display.remove(life)
        display.remove(lifeBar)
        display.remove(circle)
        display.remove(qtdArrow)
        display.remove(textArrow)
        display.remove(textScore)

        for i=1,#enemy do
            if(enemy[i] ~= nil) then 
                display.remove(enemy[i]) 
            end
        end 

        castelo3 = display.newImageRect(sceneGroup, "image/cenarios/castelo_destroy.png", 800, 555)
        castelo3.x = _R * 0.9
        castelo3.y = _B * 0.728
        castelo3.xScale = 2
        castelo3.yScale = 1.8
        sceneGroup:insert(castelo3)
        castelo3.isVisible = true

        gameoverBackground = display.newRect(sceneGroup, 0, 0, 1920, 1080)
        display.remove(castelo)

        gameoverBackground.x = _CX
        gameoverBackground.y = _CY
        gameoverBackground.xScale = 2
        gameoverBackground.yScale = 2
        gameoverBackground:setFillColor(0)
        gameoverBackground.alpha = 0.6

        gameOverBox = display.newImageRect(sceneGroup, "image/cenarios/game_over.png",1200, 300)
            gameOverBox.x = _CX 
            gameOverBox.y = _CY*0.3
  
        mostraRanking()

        btn_Continue = widget.newButton (
            {
                label = "Continue",
                onEvent = restartGame,
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
        btn_Continue.x = _CX - 400
        btn_Continue.y =  _CY / 0.55
        sceneGroup:insert(btn_Continue)

        btn_returnToMenu = widget.newButton(
            {
                label = "Menu",
                onEvent = returnToMenu,
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
        btn_returnToMenu.x = _CX + 400
        btn_returnToMenu.y =  _CY / 0.55
        sceneGroup:insert(btn_returnToMenu)
    end

    -- Add sprite listener
    player:addEventListener( "sprite", spriteListener )
    Runtime:addEventListener( "touch", playerShoot)
    Runtime:addEventListener( "enterFrame", sendEnemies)
    Runtime:addEventListener( "collision", onCollision )
    Runtime:addEventListener( "enterFrame", verificaTotalDeFlechas)   
end



-- "scene:show()"
function scene:show( event )

    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        -- Called when the scene is still off screen (but is about to come on screen).
    elseif ( phase == "did" ) then
        local cenaAnterior = composer.getSceneName("previous")
        if(cenaAnterior) then
            composer.removeScene(cenaAnterior)
        end
        audio.stop(1)
        audio.rewind(_JOGO)
        audio.play(_JOGO,{channel = 2,loops=-1, fadein=2500})
        -- Called when the scene is now on screen.
        -- Insert code here to make the scene come alive.
        -- Example: start timers, begin animation, play audio, etc.        
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