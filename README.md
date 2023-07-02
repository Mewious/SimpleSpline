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
Spline:FollowPath(Object,Speed)
```
Description: Moves a object along the spline with a given speed
<br>Param: Object - BasePart or Model
<br>Param: Speed - number
<br>Returns: Path

### Path

```lua
{
    Completed : RBXScriptSignal,
    Time : number,
    NodeReached : RBXScriptSignal,
    Stop : Function
}
```
Description: A object that is returned by Spline:FollowPath

```lua
Path.Stop()
```
Description: Stops the path
