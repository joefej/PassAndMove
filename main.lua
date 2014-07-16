----------------------------------------------------------------------------------------
--
-- main.lua
--
----------------------------------------------------------------------------------------
local physics = require( "physics" )
local Vector = require("vector")
local PlayersAndTeam = require("team")
local Players = PlayersAndTeam.players
local Team = PlayersAndTeam.team
local ballfactory = require("ball")
local Ball = ballfactory:create()
Ball:setToPlayer(Players[1].x, Players[1].y, Players[1].radius, Players[1].key)
function onPlayBtnRelease()
	if Team.state ~= "attacking" then
		Team.state = "attacking"
	else
		Team.state = "defending"
	end
	for _,player in ipairs( Players ) do
		player:removeEventListener("touch", player.onTouchPlayer)
	end
	print("Game Started: ", Team.state)
	return true
end	
	
local Hud = require("hud")
Hud.Field = Hud:createField(Ball.radius)

-- Frame Event
local function animate(event)
	-- ball follows player
	if Ball.state == "grabbed" then
		local player = Players[Ball.playerkey]
		Ball:setToPlayer(player.x, player.y, player.radius, player.key)
	else
	-- ball moves
	--	Ball:translate(Ball.v.x/30, Ball.v.y/30)
		-- ball collided with player
	--	for key,player in ipairs( Players ) do
	--		if (Ball.playerkey ~= key and Ball:hasCollided(player)) then
	--			Ball.playerkey = player.key
	--			Ball:setState("grabbed")
	--		end
	--	end
	end
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
	
	for _,player in ipairs( Players ) do
		-- player having the ball
		if (Ball.state=="grabbed" and Ball.playerkey==player.key) and Team.state=="attacking" then
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
			if (Team.state == "attacking") and (((player.x-player.attacktarget.x)^2+(player.y-player.attacktarget.y)^2) > 122) then
				player:setState("attacking")
				player:movePlayer(player.attacktarget.x, player.attacktarget.y)
			elseif (Team.state == "defending") and (((player.x-player.defendtarget.x)^2+(player.y-player.defendtarget.y)^2) > 9) then
				player:setState("defending")
				player:movePlayer(player.defendtarget.x, player.defendtarget.y)
			end
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
			if Team.state == targettype then
				Players[t.key]:movePlayer(t.x, t.y)
			end
		end
	end
	return true
end

function isOnField(x, y, r)
	return Hud.Field:isOnField(x, y, r)
end

function goal()
	print("goal")
	Hud.Field:incScore("home")
  --Team.state = "idle"
  -- Return to original position
  for _,player in ipairs( Players ) do
    player:resetPos()
    player:fadein()
	end
  Ball:setToPlayer(Players[1].x, Players[1].y, Players[1].radius, Players[1].key)
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

local function startGame()
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

startGame()


