# SimpleSpline

## How to use

Create a new spline:
```lua
local Points = {}
local Spline = SimpleSpline.new(Points,Alpha,Tension)
```
Set Options
```lua
Spline:SetOptions({
    Uniform = true,
    Offset = CFrame.new(),
    Loop = true,
    Reverse = false
})
```
Visualize the spline:
```lua
Spline:Visualize()
```
Destroy the Visualization:
```lua
Spline:ClearVisualize()
```

Moving a object along the spline:
```lua
local Path = Spline:FollowPath(Obj,Speed)
```
## Documentation:

### SimpleSpline

```lua
SimpleSpline.new(Points,Alpha,Tension)
```
Description: Creates a new Spline Object
<br>Param: Points - table of CFrames
<br>Param: Alpha - number from 0 - 1
<br>Param: Tension - number from 0 - 1
<br>Returns: Spline

### Spline

```lua
Spline:GetSpeedFromTime(Time)
```
Description: Gets the speed from a given time
<br>Param: Time
<br>Returns: Speed

```lua
Spline:UpdatePoints(Points)
```
Description: Updates the points of the spline
<br>Param: Points - table of CFrames

```lua
Spline:SetOptions({
    Uniform : boolean,
    Offset : CFrame,
    Loop : boolean,
    Reverse : boolean
})
```
Description: Sets the options of the spline
<br>Param: Options - a table of options

```lua
Spline:FollowPath(Objects,Speed,Distance)
```
Description: Moves a object or a list of objects along the spline with a given speed
<br>Param: Objects - BasePart or Model or table of BaseParts or Models
<br>Param: Speed - number
<br>Param: Distance - number
<br>Returns: Path

### Path

```lua
{
    Completed : RBXScriptSignal,
    PathCompleted : RBXScriptSignal,
    Time : number,
    NodeReached : RBXScriptSignal,
    Stop : Function
    ChangeSpeed : Function,
    GetElapsed : Function,

}
```
Description: A object that is returned by Spline:FollowPath

```lua
Path.Stop()
```
Description: Stops the path

```lua
Path.ChangeSpeed(Speed)
```
Description: Changes the speed of the path

```lua
Path.GetElapsed()
```
Description: Gets the elapsed time of the path

```lua
Path.Completed
```
Description: A signal that fires when a object finishes the path

```lua
Path.PathCompleted
```
Description: A signal that fires when the entire path is completed

```lua