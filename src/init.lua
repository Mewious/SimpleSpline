local Catrom = require(script.CatRom)
local RunService = game:GetService("RunService")

local SimpleSpline = {}

type Options = {
	Uniform : boolean,
	Offset : CFrame,
	Loop : boolean,
	Reverse : boolean
}

type Path = {
	Completed : RBXScriptSignal,
	Time : number,
	NodeReached : RBXScriptSignal,
	Stop : ()->nil
	
}

local DefaultOptions : Options = {
	Uniform = false,
	Offset = CFrame.new(),
	Loop = false,
	Reverse = false,

}::Options


SimpleSpline.__index = SimpleSpline

local Util = require(script.Util)

function SimpleSpline.new(Points:{},Alpha : number,Tension : number,Options : Options?)
	assert(type(Points) == "table", "Argument 1 must be a table of CFrames, got " .. type(Points))
	assert(type(Alpha) == "number", "Argument 2 must be a number, got " .. type(Alpha))
	assert(type(Tension) == "number", "Argument 3 must be a number, got " .. type(Tension))
	local self = setmetatable({},SimpleSpline)
	self.Spline = Catrom.new(Points,Alpha,Tension)
	self.Length = self.Spline:SolveLength()
	self.Points = Points
	self.CurrentOptions = Options or DefaultOptions
	
	return self
end

function SimpleSpline:UpdatePoints(Points)
	self.Spline = Catrom.new(Points)
	self.Length = self.Spline:SolveLength()
end

function SimpleSpline:SetOptions(NewOptions:Options)
	Util.ReconcileTable(NewOptions,DefaultOptions)
	self.CurrentOptions = NewOptions
end

function SimpleSpline:FollowPath(Object:BasePart | Model,Speed:number)
	local Completed = Instance.new("BindableEvent")
	local Time = self.Length / Speed
	local Run
	local Connection
	local Elasped = 0
	local Prev = 0
	Run = RunService:IsClient() and RunService.RenderStepped or RunService.Heartbeat
	local Finished = false
	
	local Loop = self.CurrentOptions.Loop
	local Uniform = self.CurrentOptions.Uniform
	local Offset = self.CurrentOptions.Offset
	local Reverse = self.CurrentOptions.Reverse
	
	local NodeReachedEvent = Instance.new("BindableEvent")
	
	if Reverse then
		Elasped = 1
		Prev = 1
	end
	
	local PastWaypoints = {}
	
	local function Clean()
		NodeReachedEvent:Destroy()
		Completed:Destroy()
		Connection:Disconnect()
		Connection=nil
		table.clear(PastWaypoints)
		table.freeze(PastWaypoints)
	end
	
	Connection = Run:Connect(function(dt)
		
		if Reverse then
			if Loop then
				Elasped = (Elasped - dt/Time) % 1
				if Elasped > Prev then
					PastWaypoints = {}
				end
			else
				Elasped = (Elasped - dt/Time)
				if Elasped <= 0 then
					if not Loop then
						Finished = true
						Completed:Fire()
						Clean()
					end
					return
				end
			end
		else
			if Loop then
				Elasped = (Elasped + dt/Time) % 1
				if Elasped < Prev then
					PastWaypoints = {}
				end
			else
				Elasped = (Elasped + dt/Time)
				if Elasped >= 1 then
					if not Loop then
						Finished = true
						Completed:Fire()
						Clean()
					end
					return
				end
			end
		end
		
		
		local spline, splineT = self.Spline:GetSplineFromT(Elasped)
		
		local cf
		if Uniform then
			cf = spline:SolveUniformCFrame(splineT)
		else
			cf = spline:SolveCFrame(splineT)
		end
		
		for i ,v in self.Spline.domains do
			if Elasped >= v and not PastWaypoints[i] then
				PastWaypoints[i]=true
				NodeReachedEvent:Fire(i)
			end
		end
		
		
		cf *= Offset or CFrame.new()
		
		if Object:IsA("Model") then
			Object:PivotTo(cf)
		else
			Object.CFrame = cf
		end
		
		Prev = Elasped
		
	end)
	
	return {
		Completed = Completed.Event,
		Time = Time,
		Stop = function()
			Clean()
		end,
		NodeReached =  NodeReachedEvent.Event
	}::Path
end


function SimpleSpline:Visualize()
	if workspace:FindFirstChild("SimpleSplineVisulize") then
		workspace.SimpleSplineVisulize:Destroy()
	end
	
	local Folder = Instance.new("Folder")
	Folder.Name = "SimpleSplineVisulize"
	Folder.Parent = workspace
	local last=nil
	
	local function CreatePart()
		local cone = Instance.new("ConeHandleAdornment")
		cone.Transparency=0.5
		cone.AlwaysOnTop=true
		cone.Radius=0.2
		cone.Color3 = Color3.new(0,0,0)
		cone.Adornee=workspace
		return cone
	end

	for i = 0 , 1 , .01 do
		local Part = CreatePart()
		local CF = self.Spline:SolveUniformCFrame(i)
		Part.CFrame = CF
		if last then
			local Distance = (CF.Position-last.Position).Magnitude
			Part.Height = Distance
		end
		Part.Parent = Folder
		Part.Name = #Folder:GetChildren()
		last=CF
	end
	local obj = Folder[1]
	local obj2 = Folder[2]
	local Distance = (obj.CFrame.Position-obj2.CFrame.Position).Magnitude
	Folder[1].Height = Distance
end

function SimpleSpline:ClearVisualize()
	if workspace:FindFirstChild("SimpleSplineVisulize") then
		workspace.SimpleSplineVisulize:Destroy()
	end
end


return SimpleSpline