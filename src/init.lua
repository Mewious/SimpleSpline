local Catrom = require(script.CatRom)
local RunService = game:GetService("RunService")

local SimpleSpline = {}

type Options = {
	Uniform: boolean,
	Offset: CFrame,
	Loop: boolean,
	Reverse: boolean,
}

type Path = {
	Completed: RBXScriptSignal,
	PathCompleted: RBXScriptSignal,
	Time: number,
	NodeReached: RBXScriptSignal,
	Stop: () -> nil,
	ChangeSpeed: (Speed: number) -> nil,
	GetElapsed: () -> number,
}

local DefaultOptions: Options = {
	Uniform = false,
	Offset = CFrame.new(),
	Loop = false,
	Reverse = false,
} :: Options

SimpleSpline.__index = SimpleSpline

local Util = require(script.Util)

function SimpleSpline.new(Points: {}, Alpha: number, Tension: number, Options: Options?)
	assert(type(Points) == "table", "Argument 1 must be a table of CFrames, got " .. type(Points))
	assert(type(Alpha) == "number", "Argument 2 must be a number, got " .. type(Alpha))
	assert(type(Tension) == "number", "Argument 3 must be a number, got " .. type(Tension))
	local self = setmetatable({}, SimpleSpline)
	self.Spline = Catrom.new(Points, Alpha, Tension)
	self.Length = self.Spline:SolveLength()
	self.Points = Points
	self.CurrentOptions = Options or DefaultOptions

	return self
end

function SimpleSpline:UpdatePoints(Points)
	self.Spline = Catrom.new(Points)
	self.Length = self.Spline:SolveLength()
end

function SimpleSpline:SetOptions(NewOptions: Options)
	Util.ReconcileTable(NewOptions, DefaultOptions)
	self.CurrentOptions = NewOptions
end

function SimpleSpline:GetSpeedFromTime(Time: number)
	return self.Length / Time
end

function SimpleSpline:FollowPath(Objects: {} | BasePart | Model | Camera, Speed: number, DistanceBetweenObjects: number)
	local Length = self.Length

	local Completed = Instance.new("BindableEvent")
	local PathCompleted = Instance.new("BindableEvent")
	local Time = Length / Speed
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
	local FinishedObjs = {}

	local function Clean()
		NodeReachedEvent:Destroy()
		PathCompleted:Destroy()
		Completed:Destroy()
		Connection:Disconnect()
		Connection = nil
		table.clear(PastWaypoints)
		table.freeze(PastWaypoints)
	end

	if type(Objects) ~= "table" then
		Objects = { Objects }
	end

	local CompletedObjects = 0

	local function GetElapsed(Offset)
		Offset = Offset or 1

		local Result
		if Reverse then
			if Loop then
				Result = (Elasped - (Offset * (DistanceBetweenObjects or 0) / Speed / Time)) % 1
			else
				Result = (Elasped - (Offset * (DistanceBetweenObjects or 0) / Speed / Time))
			end
		else
			if Loop then
				Result = ((Elasped - (Offset * ((DistanceBetweenObjects or 0) / Speed))) / Time) % 1
			else
				Result = ((Elasped - (Offset * ((DistanceBetweenObjects or 0) / Speed))) / Time)
			end
		end
		return math.clamp(Result, 0, 1)
	end

	Connection = Run:Connect(function(dt)
		if Reverse then
			Elasped -= dt / Time
		else
			Elasped += dt
		end

		if type(Objects) == "table" then
			for Index, Object in Objects do
				if CompletedObjects == #Objects then
					PathCompleted:Fire()
					Clean()
					break
				end

				local TimeFrame = GetElapsed(Index - 1)

				if Object == Objects[1] then
					for i, v in self.Spline.domains do
						if Reverse then
							if Prev >= TimeFrame and not PastWaypoints[1] then
								PastWaypoints[1] = true
								NodeReachedEvent:Fire(1)
							end
							if TimeFrame <= v and not PastWaypoints[i] then
								PastWaypoints[i] = true
								NodeReachedEvent:Fire(i)
							end
						else
							if TimeFrame >= v and not PastWaypoints[i] then
								PastWaypoints[i] = true
								NodeReachedEvent:Fire(i)
							end
						end
					end
				end

				local spline, splineT = self.Spline:GetSplineFromT(TimeFrame)

				local cf
				if Uniform then
					cf = spline:SolveUniformCFrame(splineT)
				else
					cf = spline:SolveCFrame(splineT)
				end

				cf *= Offset or CFrame.new()

				if Object:IsA("Model") then
					Object:PivotTo(cf)
				else
					Object.CFrame = cf
				end

				if Reverse then
					if not Loop then
						if TimeFrame <= 0 and not FinishedObjs[Object] then
							FinishedObjs[Object] = true
							CompletedObjects += 1
							Completed:Fire(Object)
						end
					else
						if TimeFrame > Prev and Object == Objects[1] then
							PastWaypoints = {}
						end
					end
				else
					if not Loop then
						if TimeFrame >= 1 and not FinishedObjs[Object] then
							FinishedObjs[Object] = true
							CompletedObjects += 1
							Completed:Fire(Object)
						end
					else
						if Prev > TimeFrame and Object == Objects[1] then
							PastWaypoints = {}
						end
					end
				end

				if Object == Objects[1] then
					Prev = TimeFrame
				end
			end
		end
	end)

	local Path

	Path = {
		Completed = Completed.Event,
		PathCompleted = PathCompleted.Event,
		Time = Time,
		Stop = function()
			Clean()
		end,
		NodeReached = NodeReachedEvent.Event,
		ChangeSpeed = function(NewSpeed)
			Time = Length / NewSpeed
			Path.Time = Time
		end,
		GetElapsed = function()
			return GetElapsed(0)
		end,
	} :: Path

	return Path
end

function SimpleSpline:Visualize()
	if workspace:FindFirstChild("SimpleSplineVisulize") then
		workspace.SimpleSplineVisulize:Destroy()
	end

	local Folder = Instance.new("Folder")
	Folder.Name = "SimpleSplineVisualize"
	Folder.Parent = workspace
	local last = nil

	local function CreatePart()
		local cone = Instance.new("ConeHandleAdornment")
		cone.Transparency = 0.5
		cone.AlwaysOnTop = true
		cone.Radius = 0.35
		cone.Color3 = Color3.new(0, 0, 0)
		cone.Adornee = workspace
		return cone
	end

	for i = 0, 1, 0.005 do
		local Part = CreatePart()
		local CF = self.Spline:SolveUniformCFrame(i)
		Part.CFrame = CF
		if last then
			local Distance = (CF.Position - last.Position).Magnitude
			Part.Height = Distance
		end
		Part.Parent = Folder
		Part.Name = #Folder:GetChildren()
		last = CF
	end
	local obj = Folder[1]
	local obj2 = Folder[2]
	local Distance = (obj.CFrame.Position - obj2.CFrame.Position).Magnitude
	Folder[1].Height = Distance
end

function SimpleSpline:ClearVisualize()
	if workspace:FindFirstChild("SimpleSplineVisualize") then
		workspace.SimpleSplineVisualize:Destroy()
	end
end

return SimpleSpline
