local Vector = require("vector")
local screenHeight = display.contentHeight
local screenWidth = display.contentWidth

local BallFactory = {}

function BallFactory:create(ballRadius)
  local radius = ballRadius
  local ball = display.newCircle( 0, 0, radius )
  ball.color = {r=255/255, g=255/255, b=255/255}
  ball.radius=radius
  ball.state=STATE.IDLE
  ball.playerkey=0
  ball.v=Vector:create(0, 0)
  -- pixel/sec
  ball.speed=100
  ball.linearDamping = 100

  ---------------------------------
  -- Public functions
  ---------------------------------
  function ball:grabbedByPlayer(playerkey)
    ball.state = STATE.GRABBED
    ball.playerkey = playerkey
  end
  function ball:setPosToPlayer(playerx, playery, playerradius)
    self:setPos(playerx, playery-playerradius-self.radius)
  end
  function ball:setPos(x, y)
    self.x = x; self.y = y
  end
    
  function ball:setState(newstate)
	  print("Ball state: ", ball.state, " -> ", newstate)
	  ball.state = newstate
  end

  function ball:hasCollided(obj1)
    if ( obj1 == nil ) then  --make sure the first object exists
    	return false
    end
    local dx = obj1.x - self.x
    local dy = obj1.y - self.y
    local distance = math.sqrt( dx*dx + dy*dy )
    local objectSize = (self.contentWidth/2) + (obj1.contentWidth/2)

    if ( distance < objectSize ) then
    	return true
    end
    return false
  end
  
  ---------------------------------
  -- Private functions
  ---------------------------------
  local function onCollision(self, event)
	  if (event.phase == "began") then
		  if (event.other.label == "player") then
			  local player = event.other
        print("Ball collided with Player ", player.key)
        timer.performWithDelay(10, self:grabbedByPlayer(player.key))
		  elseif (event.other.label == "corner") or (event.other.label == "goalnet") or (event.other.label == "touch") then
			  print("Ball collided with sensor: ", event.other.label)
			  timer.performWithDelay(10, ballout())
		  elseif (event.other.label == "goalline") then
			  print("Ball collided with sensor: ", event.other.label)
			  timer.performWithDelay(50, goal())
      else
        print("Error: Collision with unknown object")
		  end
	  end
  end
  ball.collision = onCollision
  
  return ball
end

return BallFactory