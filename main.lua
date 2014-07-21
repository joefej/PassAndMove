----------------------------------------------------------------------------------------
--
-- main.lua
--
----------------------------------------------------------------------------------------
STATE = {IDLE="idle",                    -- common state
  STARTED = "started",                   -- match 
  ATTACK="attacking", DEFEND="defending", --team
  GRABBED="grabbed"}                     --ball
HALF = { FIRST = "1st", SECOND = "2nd"}   -- match
local HalfTime = 10 -- 0.5 min half-time
local ballRadius = 8 -- in pixels
local goallineSize = 100 -- in pixels
local fieldNarowness = 30 -- distance from the side of the screen in pixels

local physics = require( "physics" )
local Vector = require("vector")
local PlayersAndTeam = require("team")
local Players = PlayersAndTeam.players
local Team = PlayersAndTeam.team
local ballfactory = require("ball")
local Ball = ballfactory:create(ballRadius)
ballPlayer = Players[Team.ballPlayer]
Ball:grabbedByPlayer(ballPlayer.key)
Ball:setPosToPlayer(ballPlayer.x, ballPlayer.y, ballPlayer.radius)
local Match = { state = STATE.IDLE, half = HALF.FIRST,
  firstHalftimeStartTime=0, firstHalftimeEndTime=0,
  secondHalftimeStartTime=0, secondHalftimeEndTime=0,
  lastFrameTime=0}

function onStartBtnRelease()
  Match.state = STATE.STARTED
  Team.ballPlayer = Ball.playerkey
	for _,player in ipairs( Players ) do
		player:removeEventListener("touch", player.onTouchPlayer)
	end
  local currTime = os.clock()
  if Match.half == HALF.FIRST then
    Match.firstHalftimeStartTime = currTime
  else
    Match.secondHalftimeStartTime = currTime
  end
  Match.lastFrameTime = currTime
  print(Match.half, " Halftime Started: ", currTime)
	return true
end	
	
local Hud = require("hud")
Hud.Field = Hud:createField(Ball.radius, HalfTime, goallineSize, fieldNarowness)

-- Frame Event
local function animate(event)
	-- ball follows player
	if Ball.state == STATE.GRABBED then
		local player = Players[Ball.playerkey]
		Ball:setPosToPlayer(player.x, player.y, player.radius)
	else
	-- ball moves
  end
  
  -- update clock
  local currTime = os.clock()
  if Match.state ~= STATE.IDLE then
    if Match.lastFrameTime ~= 0 then
      incClock(currTime-Match.lastFrameTime)
    end
  end
  Match.lastFrameTime = currTime
end

-- Timer listener
local function makeDecision()
--[[	if Ball.state == "idle" then
		-- get closest player
		local closestPlayer = Players[Players:getClosestPlayerKey(Ball.x, Ball.y, Ball.playerkey)]
		-- closest player should pick up the ball
		if closestPlayer.state ~= "grabbingBall" then
			closestPlayer:setState("grabbingBall")
			closestPlayer:movePlayer(Ball.x, Ball.y)
		end
	end
]]--
	if Match.state ~= STATE.IDLE then
	  for _,player in ipairs( Players ) do
		  -- player having the ball
		  if (Ball.state==STATE.GRABBED and Ball.playerkey==player.key) and Team.state==STATE.ATTACK then
			  -- shoot on goal if close to the goalline
			  local goalDist = Vector:create(player.x-Hud.Field:getGoalLineCenter(Team.attackingDir).x, player.y-Hud.Field:getGoalLineCenter(Team.attackingDir).y)
			  if goalDist:len() < 200 then
				  player:shoot(display.contentWidth*0.5-60, 20, display.contentWidth*0.5+60, 20, Ball)
			  else
				  -- makes pass to the closest teammate to the goal
				  player:passToPlayer(Players[Players:getClosestPlayerKey(display.contentWidth*0.5, 0, -1)], Ball)
			  end
		  else
		  -- player not having the ball
		  end
		
		  -- if player is pushed away from target position, move back
		  if (player.state ~= Team.state) then
			  if (Team.state == STATE.ATTACK) and (((player.x-player.attacktarget.x)^2+(player.y-player.attacktarget.y)^2) > 122) then
				  player:setState(STATE.ATTACK)
				  player:movePlayer(player.attacktarget.x, player.attacktarget.y)
			  elseif (Team.state == STATE.DEFEND) and (((player.x-player.defendtarget.x)^2+(player.y-player.defendtarget.y)^2) > 9) then
				  player:setState(STATE.DEFEND)
				  player:movePlayer(player.defendtarget.x, player.defendtarget.y)
       else
         -- do nothing
			  end
		  end
    end
	end
end

function incClock(elapsedtime) -- in sec
  if Match.state ~= STATE.IDLE then
    if Match.half == HALF.FIRST and Hud.Field:returnMin() >= 45 then
      -- half-time
      halftime()
    elseif Match.half == HALF.SECOND and Hud.Field:returnMin() >= 90 then
      -- end match
      endmatch()
    else
      -- update clock
      Hud.Field:incClock(elapsedtime)
    end
  end
end

-- Touch listener
function onTouchPlayerTargetAttack(event) -- attack target
	onTouchPlayerTarget(event, "attacking")
end

function onTouchPlayerTargetDefend(event) -- defend target
	onTouchPlayerTarget(event, "defending")
end

function onTouchPlayerTarget(event, targettype)
	local t = event.target
	if event.phase == "began" then
		display.getCurrentStage():setFocus( t )
		t.isFocus = true
	elseif t.isFocus then
		if event.phase == "moved" then
			if isOnField(event.x, event.y, Players[t.key].radius) then
				t.x = event.x
				t.y = event.y
			end
		elseif event.phase == "ended" or event.phase == "cancelled" then
			display.getCurrentStage():setFocus( nil )
			t.isFocus = false
			print("Target ", Players[t.key].key, " moved x: ", t.x, " y: ", t.y)
			if Match.state~=STATE.IDLE and Team.state == targettype then
				Players[t.key]:movePlayer(t.x, t.y)
			end
		end
	end
	return true
end

function isOnField(x, y, r)
	return Hud.Field:isOnField(x, y, r)
end
function isOnOwnHalf(x, y, r)
  return Hud.Field:isOnOwnHalf(x, y, r)
end

function goal()
	print("Goal!!!")
  Hud.Field:incScore("home")
  timer.performWithDelay(10, resetPlayersPosition(), 1)
  timer.performWithDelay(2000, continueMatch, 1)
end

function ballout()
  timer.performWithDelay(10, pauseMatch, 1)
  -- stopping the ball
  timer.performWithDelay(10, Ball:setLinearVelocity(0, 0), 1)
  resetPlayersPosition()
  timer.performWithDelay(1000, continueMatch, 1)
end

function halftime()
  Match.firstHalftimeEndTime = os.clock()
  print(Match.half, " halftime ended:", Match.firstHalftimeEndTime)
  resetPlayersPosition()
  timer.performWithDelay(10, pauseMatch, 1)
  Match.half = HALF.SECOND
  Hud.Field:setClock(45, 0)
  Match.lastFrameTime = 0
  for _,player in ipairs( Players ) do
		-- eventlisteners
		player:addEventListener("touch", player.onTouchPlayer)
	end
end

function endmatch()
  Match.secondHalftimeEndTime = os.clock()
  print(Match.half, " halftime ended:", Match.secondHalftimeEndTime)
  pauseMatch()
  for _,player in ipairs( Players ) do
    transition.cancel(player)
	end
  Ball:removeEventListener("collision", Ball)
end

function resetPlayersPosition()
  print("Resetting players position...2s")
  timer.performWithDelay(10, pauseMatch, 1)
  -- Return to original position
  for _,player in ipairs( Players ) do
    timer.performWithDelay(10, player:resetPos(), 1)
    timer.performWithDelay(10, player:fadein(), 1)
	end
  timer.performWithDelay(10, Ball:grabbedByPlayer(ballPlayer.key), 1)
  timer.performWithDelay(10, Ball:setPosToPlayer(ballPlayer.x, ballPlayer.y, ballPlayer.radius), 1)
end

function continueMatch()
  print("Continue with playing")
  Match.state = STATE.STARTED
end

function pauseMatch()
  print("Match is paused")
  Match.state = STATE.IDLE
end

function startMatch()
  print("Match is started")
  Match.state = STATE.STARTED
end
---------------------------------
-- Private functions
---------------------------------
local function setPhysics()
	physics.start()
	physics.setGravity( 0, 0 )
	physics.setScale( 30 )
	physics.setDrawMode( "normal" )
	physics.setPositionIterations( 8 )
	physics.setVelocityIterations( 3 )

	-- Posts
	physics.addBody(Hud.Field.BottomGoal.Posts[1], "static", {radius=Hud.Field.BottomGoal.Posts[1].radius, friction=0.1, bounce=0.8})
	physics.addBody(Hud.Field.BottomGoal.Posts[2], "static", {radius=Hud.Field.BottomGoal.Posts[2].radius, friction=0.1, bounce=0.8})
	physics.addBody(Hud.Field.TopGoal.Posts[1], "static", {radius=Hud.Field.TopGoal.Posts[1].radius, friction=0.1, bounce=0.8})
	physics.addBody(Hud.Field.TopGoal.Posts[2], "static", {radius=Hud.Field.TopGoal.Posts[2].radius, friction=0.1, bounce=0.8})
	-- Nets
	physics.addBody(Hud.Field.BottomGoal.Nets[1], "static")
	physics.addBody(Hud.Field.BottomGoal.Nets[2], "static")
	physics.addBody(Hud.Field.BottomGoal.BackNet, "static")
	physics.addBody(Hud.Field.TopGoal.Nets[1], "static")
	physics.addBody(Hud.Field.TopGoal.Nets[2], "static")
	physics.addBody(Hud.Field.TopGoal.BackNet, "static")
	-- Sensors
	for i=1,8 do
		physics.addBody(Hud.Field.Sensors[i], "static")
		Hud.Field.Sensors[i].isSensor = true
	end
	-- Ball
	physics.addBody(Ball, "dynamic", {radius=Ball.radius, density=0.1, friction=0.1, bounce=0.2})
	-- Players
	for key,player in ipairs( Players ) do
		physics.addBody(player, "dynamic", {radius=player.radius, density=1.0, friction=0.1, bounce=0.2})
	end

end

local function startMatch()
	for _,player in ipairs( Players ) do
		-- fade in
		player:fadein()
		-- eventlisteners
		player.attacktarget:addEventListener("touch", onTouchPlayerTargetAttack)
		player.defendtarget:addEventListener("touch", onTouchPlayerTargetDefend)
		player:addEventListener("touch", player.onTouchPlayer)
	end
  timer.performWithDelay(1000, makeDecision, 0)
	Ball:addEventListener("collision", Ball)
	Runtime:addEventListener( "enterFrame", animate )
end

---------------------------------
-- Start script
---------------------------------
display.setStatusBar( display.HiddenStatusBar )
display.setDefault( "background", 0, 150/255, 0 )
-- Set physics
setPhysics()

startMatch()


