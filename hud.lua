local widget = require "widget"
local Vector = require "vector"
local Hud = {}

function Hud:createField(BallRadius)
	local Field = display.newGroup()
	-- Hud pixel from bottom
	local HudYPosOffset = 30
	-- Field constants
	Field.FieldYPosOffsetBottom = HudYPosOffset + 60
	Field.FieldYPosOffsetTop = 40
	Field.FieldXPosOffset = 30
	Field.GoalLineSize = 100
	-- Ball diameter
	local BallDia = BallRadius * 2
	-- Play Button
	local playBtn
	playBtn = widget.newButton{
		label="Start",
		labelColor = { default={255}, over={128} },
		default="button.png",
		over="button-over.png",
		width=154, height=40,
		onRelease = onPlayBtnRelease	-- event listener function
	}
	playBtn.x = display.contentWidth*0.5
	playBtn.y = display.contentHeight - HudYPosOffset
	Field:insert(playBtn)
	-- Score board
	Field.homeScore = display.newText({parent=Field, text="0", 
		x=display.contentWidth*0.25, y=display.contentHeight - HudYPosOffset, 
		font=native.systemFont, fontSize=26})
	Field.awayScore = display.newText({parent=Field, text="0", 
		x=display.contentWidth*0.75, y=display.contentHeight - HudYPosOffset, 
		font=native.systemFont, fontSize=26})
	-- Sideline
	local Sideline = display.newLine(Field, Field.FieldXPosOffset, Field.FieldYPosOffsetTop, display.contentWidth-Field.FieldXPosOffset, Field.FieldYPosOffsetTop)
	Sideline:append(display.contentWidth-Field.FieldXPosOffset, display.contentHeight-Field.FieldYPosOffsetBottom, Field.FieldXPosOffset,  display.contentHeight-Field.FieldYPosOffsetBottom, Field.FieldXPosOffset, Field.FieldYPosOffsetTop)
	Sideline.strokeWidth = 5
	-- Bottom goal
	local barRadius = 10
	local netWidth = 8
	local netDepth = 35
	local leftpostx = display.contentWidth*0.5-Field.GoalLineSize/2
	Field.BottomGoal = {}
	Field.BottomGoal.Posts = {}
	Field.BottomGoal.Nets = {}
	-- bottomLeftPost
	Field.BottomGoal.Posts[1] = display.newCircle(leftpostx, display.contentHeight-Field.FieldYPosOffsetBottom, barRadius)
	-- bottomRightPost
	Field.BottomGoal.Posts[2] = display.newCircle(leftpostx+Field.GoalLineSize, display.contentHeight-Field.FieldYPosOffsetBottom, barRadius)
	-- Sides of goal
	Field.BottomGoal.Nets[1] = display.newRect(leftpostx, display.contentHeight-Field.FieldYPosOffsetBottom+netDepth/2, netWidth, netDepth)
	Field.BottomGoal.Nets[2] = display.newRect(leftpostx+Field.GoalLineSize, display.contentHeight-Field.FieldYPosOffsetBottom+netDepth/2, netWidth, netDepth)
	-- Back of the goal
	Field.BottomGoal.BackNet = display.newRect(display.contentWidth*0.5, display.contentHeight-Field.FieldYPosOffsetBottom+netDepth, Field.GoalLineSize, netWidth)
	Field.BottomGoal.BackNet.label = "goalnet"
	-- Top goal
	Field.TopGoal = {}
	Field.TopGoal.Posts = {}
	Field.TopGoal.Nets = {}
	-- topLeftPost
	Field.TopGoal.Posts[1] = display.newCircle(leftpostx, Field.FieldYPosOffsetTop, barRadius)
	-- topRightPost
	Field.TopGoal.Posts[2] = display.newCircle(leftpostx+Field.GoalLineSize, Field.FieldYPosOffsetTop, barRadius)
	-- Sides of goal
	Field.TopGoal.Nets[1] = display.newRect(leftpostx, Field.FieldYPosOffsetTop-netDepth/2, netWidth, netDepth)
	Field.TopGoal.Nets[2] = display.newRect(leftpostx+Field.GoalLineSize, Field.FieldYPosOffsetTop-netDepth/2, netWidth, netDepth)
	-- Back of goal
	Field.TopGoal.BackNet = display.newRect(display.contentWidth*0.5, Field.FieldYPosOffsetTop-netDepth, Field.GoalLineSize, netWidth)
	Field.TopGoal.BackNet.label = "goalnet"
	-- Sensors
	Field.Sensors = {}
	local sensorWidth = 10
	local sensorHeight = display.contentHeight-Field.FieldYPosOffsetBottom-Field.FieldYPosOffsetTop+2*BallDia
	local greyColor = 0.85
	-- SideLineSensors
	Field.Sensors[1] = display.newRect(Field.FieldXPosOffset-BallDia-sensorWidth/2, Field.FieldYPosOffsetTop-BallDia+sensorHeight/2, sensorWidth, sensorHeight)
	Field.Sensors[1].label = "touch"
	Field.Sensors[1]:setFillColor(greyColor)
	Field.Sensors[2] = display.newRect(display.contentWidth-Field.FieldXPosOffset+BallDia+sensorWidth/2, Field.FieldYPosOffsetTop-BallDia+sensorHeight/2, sensorWidth, sensorHeight)
	Field.Sensors[2].label = "touch"
	Field.Sensors[2]:setFillColor(greyColor)
	-- CornerLineSensors
	sensorHeight = sensorWidth
	sensorWidth = leftpostx-Field.FieldXPosOffset+BallDia-netWidth/2
	Field.Sensors[3] = display.newRect(Field.FieldXPosOffset+sensorWidth/2-BallDia, Field.FieldYPosOffsetTop-BallDia-sensorHeight/2, sensorWidth, sensorHeight)
	Field.Sensors[3].label = "corner"
	Field.Sensors[3]:setFillColor(greyColor)
	Field.Sensors[4] = display.newRect(display.contentWidth-Field.FieldXPosOffset-sensorWidth/2+BallDia, Field.FieldYPosOffsetTop-BallDia-sensorHeight/2, sensorWidth, sensorHeight)
	Field.Sensors[4].label = "corner"
	Field.Sensors[4]:setFillColor(greyColor)
	Field.Sensors[5] = display.newRect(Field.FieldXPosOffset+sensorWidth/2-BallDia, display.contentHeight-Field.FieldYPosOffsetBottom+BallDia+sensorHeight/2, sensorWidth, sensorHeight)
	Field.Sensors[5].label = "corner"
	Field.Sensors[5]:setFillColor(greyColor)
	Field.Sensors[6] = display.newRect(display.contentWidth-Field.FieldXPosOffset-sensorWidth/2+BallDia, display.contentHeight-Field.FieldYPosOffsetBottom+BallDia+sensorHeight/2, sensorWidth, sensorHeight)
	Field.Sensors[6].label = "corner"
	Field.Sensors[6]:setFillColor(greyColor)
	-- GoalLineSensors
	local goalGreyColor = 0.7
	sensorWidth = Field.GoalLineSize - netWidth
	Field.Sensors[7] = display.newRect(display.contentWidth*0.5, Field.FieldYPosOffsetTop-sensorHeight/2-BallDia, sensorWidth, sensorHeight)
	Field.Sensors[7].label = "goalline"
	Field.Sensors[7]:setFillColor(goalGreyColor)
	Field.Sensors[8] = display.newRect(display.contentWidth*0.5, display.contentHeight-Field.FieldYPosOffsetBottom+BallDia+sensorHeight/2, sensorWidth, sensorHeight)
	Field.Sensors[8].label = "goalline"
	Field.Sensors[8]:setFillColor(goalGreyColor)
	
	function Field:getGoalLineCenter(attackingDir)
		if (attackingDir == "top") then
			return Vector:create(display.contentWidth*0.5, self.FieldYPosOffsetTop)
		else
			return Vector:create(display.contentWidth*0.5, self.FieldYPosOffsetBottom)
		end
	end
	
	function Field:getLeftPost()
		return Vector:create(display.contentWidth*0.5-self.GoalLineSize/2, display.contentHeight-self.FieldYPosOffsetBottom)
	end
	
	function Field:isOnField(x, y, r)
		if (x > self.FieldXPosOffset+r and x < display.contentWidth-self.FieldXPosOffset-r and y > self.FieldYPosOffsetTop+r and y <  display.contentHeight-self.FieldYPosOffsetBottom-r) then
			return true
		else
			return false
		end
	end
	
	function Field:incScore(score)
		if (score == "home") then
			Field.homeScore.text = Field.homeScore.text + 1
		elseif (score == "away") then
			Field.awayScore.text = Field.awayScore.text + 1
		end
	end
	
	return Field
end

return Hud