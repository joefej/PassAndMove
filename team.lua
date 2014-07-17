local Vector = require "vector"

local screenHeight = display.contentHeight
local screenWidth = display.contentWidth

local team = {
	color = { r=50/255, g=50/255, b=200/255 },
	state = STATE.IDLE,
	attackingDir = ATTACKINGDIR.TOP,
  ballPlayer = 1
}

local playersParam = {
	{ radius=20, speed=50, --speed = pixel/sec
	  initpos = Vector:create(100, 560),
	  attackinitpos = Vector:create(100, 290),
	  definitpos = Vector:create(100, 690),
	  state=STATE.IDLE
	},
	{ radius=20, speed=45,
	  initpos = Vector:create(250, 500),
	  attackinitpos = Vector:create(250, 230),
	  definitpos = Vector:create(250, 640),
	  state=STATE.IDLE
	},
	{ radius=20, speed=48,
	  initpos = Vector:create(400, 560),
	  attackinitpos = Vector:create(400, 300),
	  definitpos = Vector:create(390, 690),
	  state=STATE.IDLE
	}
}

local players = {}
local Player = {}

---------------------------------
-- Public functions
---------------------------------
function team:setState(newstate)
  print("Team state changed: ", self.state, "->", newstate)
  self.state = newstate
end

function Player:create(key, team, playerParam)
	local attacktarg = display.newCircle( playerParam.attackinitpos.x, playerParam.attackinitpos.y, playerParam.radius)
	attacktarg:setFillColor(255/255,255/255,255/255, 1.0 )
	attacktarg.key = key
	local defendtarg = display.newCircle( playerParam.definitpos.x, playerParam.definitpos.y, playerParam.radius)
	defendtarg:setFillColor(100/255,100/255,100/255, 1.0 )
	defendtarg.key = key
	local player = display.newCircle( playerParam.initpos.x, playerParam.initpos.y, playerParam.radius )
	player.attacktarget = attacktarg
	player.defendtarget = defendtarg
	player:setFillColor( team.color.r, team.color.g, team.color.b, 1.0 )
	player.radius = playerParam.radius
	player.key = key
	player.speed = playerParam.speed
	player.state = playerParam.state
  player.initpos = playerParam.initpos
  player.label = "player"

	function player:setState(newstate)
		print("Player ", self.key, " state: ", self.state, " -> ", newstate)
		self.state = newstate
	end
	
	function listenerAfterMove(obj)
		obj:setState(STATE.IDLE)
		obj:setLinearVelocity(0, 0)
	end

	function player:movePlayer(x, y)
		local target = Vector:create(x-self.x, y-self.y)
		local s = target:len()
		local t = s / self.speed * 1000
		transition.cancel(self)
		transition.to(self, { time=t, x=x, y=y, transition=easing.inOutQuadr, onComplete=listenerAfterMove})
		-- transition=easing.inOutQuad, easing.linear
	end
	
	function player.onTouchPlayer(event)
		local t = event.target
		if event.phase == "began" then
			display.getCurrentStage():setFocus( t )
			t.isFocus = true
		elseif t.isFocus then
			if event.phase == "moved" then
				if isOnField(event.x, event.y, t.radius) then
					t.x = event.x
					t.y = event.y
				end
			elseif event.phase == "ended" or event.phase == "cancelled" then
				display.getCurrentStage():setFocus( nil )
				t.isFocus = false
				print("x: ", t.x, " y: ", t.y)
			end
		end
		return true
	end

	function player:passToPlayer(targetPlayer, ball)
		if self == targetPlayer then
			return
		end
		local s = ball.speed
		local pA = Vector:create(self.x, self.y)
		local pB = Vector:create(targetPlayer.x, targetPlayer.y)
		local pT = Vector:create(targetPlayer.attacktarget.x, targetPlayer.attacktarget.y)
		local vp = pB:sub(pA)
		local vv = pT:sub(pB)
		if not vv:isZero() then
			vv:inorm();vv:imult(targetPlayer.speed)
		end
		local a = vv:dot(vv) - s*s
		local b = 2*vp:dot(vv)
		local c = vp:dot(vp)
		local d = (b*b)-(4*a*c)
		if d >= 0 then
			local p = (-1)*b/(2*a)
			local q = math.sqrt(d)/(2*a)
			local t1 = p-q
			local t2 = p+q
			local t
			if t1 > t2 and t2 > 0 then
    		t = t2
			else
    			t = t1
    	end
    	local pH = pB:add(vv:mult(t))
    	if pB:distance(pH) > pB:distance(pT) then
    		pH = pT
    	end
    	local pBall = Vector:create(ball.x, ball.y)
    	ball.v=pH:sub(pBall)
    	ball.v:inorm(); ball.v:imult(ball.speed)
    	ball:setLinearVelocity(ball.v.x, ball.v.y)
			ball:setState(STATE.IDLE)
		else
			print("nincs megoldas, d<0, d=", d)
		end
	end
	
	function player:shoot(x1, y1, x2, y2, ball)
		math.randomseed( os.time() )
		local offset = (math.abs(x2-x1)*1.25)-math.random(math.abs(x2-x1)*1.5)
		local pA = Vector:create(self.x, self.y)
		local pB = Vector:create((x1+offset), (y1+y2)/2) -- shoot on target
		--local pB = Vector:create((x1), (y1+y2)/2) -- shoot to the post
		--local pB = Vector:create(-100, 100) -- shoot left
		--local pB = Vector:create(800, 100) -- shoot right
		--local pB = Vector:create(150, 0) -- shoot up
		ball.v= pB:sub(pA)
		ball.v:inorm(); ball.v:imult(ball.speed)
		ball:setLinearVelocity(ball.v.x, ball.v.y)
		ball:setState(STATE.IDLE)
	end
	
  function player:resetPos()
    transition.cancel(self)
    self.x = self.initpos.x
    self.y = self.initpos.y
    self.state = STATE.IDLE
  end
  
  function player:fadein()
    print("Player ", self.key, " fadeIn x:", self.x, " y:", self.y)
    self.xScale=0.1
		self.yScale=0.1
		transition.to(self, {time=2000, alpha=1.0})
		transition.to(self, { time=2000, xScale=1.0, 
								yScale=1.0, transition=easing.outElastic})
		self.attacktarget.alpha=0
		self.attacktarget.xScale=0.1
		self.attacktarget.yScale=0.1
		transition.to(self.attacktarget, {time=2000, alpha=0.5})
		transition.to(self.attacktarget, { time=2000, xScale=1.0, yScale=1.0, transition=easing.outElastic})
		self.defendtarget.alpha=0
		self.defendtarget.xScale=0.1
		self.defendtarget.yScale=0.1
		transition.to(self.defendtarget, {time=2000, alpha=0.5})
		transition.to(self.defendtarget, { time=2000, xScale=1.0, yScale=1.0, transition=easing.outElastic})
  end
  
	return player
end

function players:getClosestPlayerKey(x, y, exemption)
	local closestPlayerkey = -1
	local closestDistance = -1
	for key,player in ipairs( self ) do
		if key ~= exemption then
			local dist = Vector:create(x-player.x, y-player.y)
			local newDistance = dist:len()
			if newDistance < closestDistance or closestDistance < 0 then
				closestDistance = newDistance
				closestPlayerKey = player.key
			end
		end
	end
	return closestPlayerKey
end

-- Iterate through players array and add new player body into an array
for key,param in ipairs( playersParam ) do
	players[key] = Player:create(key, team, param)
end

---------------------------------
-- Start script
---------------------------------
local playersandteam = {players = players, team = team}
return playersandteam