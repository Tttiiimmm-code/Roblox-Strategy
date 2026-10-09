local Vector3 = {}
local vm = {}
vm.__tostring=function(v)return v.X..", "..v.Y..", "..v.Z end
vm.__index = function(v,k) if k=='Magnitude' then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z) end return vm[k] end
vm.__add = function(a,b) return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
vm.__sub = function(a,b) return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
vm.__mul = function(a,b) if type(a)=='number' then a,b=b,a end return Vector3.new(a.X*b,a.Y*b,a.Z*b) end
function Vector3.new(x,y,z) return setmetatable({X=x,Y=y,Z=z},vm) end
local CFrame = {}
local cm = {}; cm.__index=cm
function CFrame.new(x,y,z) if type(x)=='table' then x,y,z=x.X,x.Y,x.Z end return setmetatable({Position=Vector3.new(x or 0,y or 0,z or 0), angle=0},cm) end
function CFrame.Angles(_,y,_) local c=CFrame.new();c.angle=y;return c end
function cm:PointToWorldSpace(v) local c,s=math.cos(self.angle),math.sin(self.angle);return self.Position+Vector3.new(c*v.X+s*v.Z,v.Y,-s*v.X+c*v.Z) end
cm.__mul=function(a,b) if b.X then return a:PointToWorldSpace(b) end local r=CFrame.new(a:PointToWorldSpace(b.Position));r.angle=a.angle+b.angle;return r end
function cm:Inverse() local r=CFrame.Angles(0,-self.angle,0);r.Position=r:PointToWorldSpace(self.Position*-1);return r end
local Color3={fromRGB=function(r,g,b)return {R=r/255,G=g/255,B=b/255} end}
local colors={}; function colors:Lerp(b,t) return Color3.fromRGB((self.R+(b.R-self.R)*t)*255,(self.G+(b.G-self.G)*t)*255,(self.B+(b.B-self.B)*t)*255) end
local rgb=Color3.fromRGB;Color3.fromRGB=function(...)return setmetatable(rgb(...),{__index=colors}) end
local Vector2={new=function(...)return {...} end}
local Enum=setmetatable({},{__index=function(t,k)local e=setmetatable({},{__index=function(_,v)return v end});rawset(t,k,e);return e end})
local Random={new=function(seed)local state=seed or 1;return {NextNumber=function(_,a,b)state=(state*16807+1)%2147483647;return a+(b-a)*state/2147483647 end, NextInteger=function(self,a,b)return math.floor(self:NextNumber(a,b+1)) end} end}
local warningCount=0
local function warn(_)warningCount+=1 end
local methods={}
local Instance={}
local function signal()return {Connect=function()return {Disconnect=function()end} end}end
local mt={__index=function(o,k) if k=='Position' then return o._cf.Position elseif k=='CFrame' then return o._cf elseif k=='Parent' then return o._parent end return methods[k] or o._props[k] end,__newindex=function(o,k,v)
 if k=='Parent' then if o._parent then for i,c in o._parent._children do if c==o then table.remove(o._parent._children,i);break end end end rawset(o,'_parent',v);if v then table.insert(v._children,o)end
 elseif k=='Position' then o._cf=CFrame.new(v) elseif k=='CFrame' then o._cf=v else o._props[k]=v end end}
function Instance.new(class)return setmetatable({_props={ClassName=class,Name=class,Size=Vector3.new(1,1,1),Archivable=true,Color=Color3.fromRGB(163,162,165),Transparency=0,Material=Enum.Material.Plastic,DescendantAdded=signal(),DescendantRemoving=signal()},_children={},_cf=CFrame.new(),_pivot=CFrame.new(),_attrs={}},mt)end
function methods:IsA(c)return self.ClassName==c or (c=='BasePart' and (self.ClassName=='Part' or self.ClassName=='MeshPart')) or (c=='BaseScript' and (self.ClassName=='Script' or self.ClassName=='LocalScript')) end
function methods:GetChildren()return table.clone(self._children)end
function methods:GetDescendants()local result={};local function walk(o)for _,c in o._children do table.insert(result,c);walk(c)end end;walk(self);return result end
function methods:FindFirstChild(name)for _,c in self._children do if c.Name==name then return c end end end
methods.WaitForChild=methods.FindFirstChild
function methods:Destroy()self.Parent=nil;self._children={}end
function methods:SetAttribute(k,v)self._attrs[k]=v end
function methods:GetAttribute(k)return self._attrs[k]end
function methods:Clone()if not self.Archivable then return nil end local c=Instance.new(self.ClassName);for k,v in self._props do c[k]=v end;c.CFrame=self.CFrame;c._pivot=self._pivot;c._attrs=table.clone(self._attrs);for _,ch in self._children do local cp=ch:Clone();if cp then cp.Parent=c end end;return c end
function methods:GetPivot()return self._pivot end
function methods:GetBoundingBox()
 local lo=Vector3.new(math.huge,math.huge,math.huge);local hi=Vector3.new(-math.huge,-math.huge,-math.huge)
 for _,p in self:GetDescendants()do if p:IsA('BasePart')then for _,x in {-1,1}do for _,y in {-1,1}do for _,z in {-1,1}do local pt=p.CFrame*Vector3.new(x*p.Size.X/2,y*p.Size.Y/2,z*p.Size.Z/2);lo=Vector3.new(math.min(lo.X,pt.X),math.min(lo.Y,pt.Y),math.min(lo.Z,pt.Z));hi=Vector3.new(math.max(hi.X,pt.X),math.max(hi.Y,pt.Y),math.max(hi.Z,pt.Z))end end end end end
 return CFrame.new((lo+hi)*0.5),hi-lo
end
function methods:ScaleTo(scale)for _,p in self:GetDescendants()do if p:IsA('BasePart')then p.Size=p.Size*scale;p.Position=p.Position*scale end end end
function methods:PivotTo(cf)local delta=cf*self._pivot:Inverse();for _,p in self:GetDescendants()do if p:IsA('BasePart')then p.CFrame=delta*p.CFrame end end;self._pivot=cf end
local services={ReplicatedStorage=Instance.new('Folder'),ServerStorage=Instance.new('Folder'),MaterialService=Instance.new('Folder')}
local shared=Instance.new('Folder');shared.Name='Shared';shared.Parent=services.ReplicatedStorage
local models=Instance.new('Folder');models.Name='EnvironmentModels';models.Parent=services.ServerStorage
local game={GetService=function(_,k)return services[k]end}
local workspace=Instance.new('Folder');workspace.Terrain={FillBlock=function()end,FillBall=function()end,SetMaterialColor=function()end}
local RaycastParams={new=function()return {} end}
function workspace:Raycast(v)return {Position=Vector3.new(v.X,0,v.Z)}end
local modules={}
local function require(m)return modules[m]end

-- Vollständige Rotationen für flach gedrehte WedgeParts.
local function rotation(cf)
	return cf.rotation or { math.cos(cf.angle), 0, math.sin(cf.angle), 0, 1, 0, -math.sin(cf.angle), 0, math.cos(cf.angle) }
end
function cm:PointToWorldSpace(v)
	local r = rotation(self)
	return self.Position + Vector3.new(r[1]*v.X+r[2]*v.Y+r[3]*v.Z, r[4]*v.X+r[5]*v.Y+r[6]*v.Z, r[7]*v.X+r[8]*v.Y+r[9]*v.Z)
end
function CFrame.Angles(x, y, z)
	local a,b,c,d,e,f = math.cos(x),math.sin(x),math.cos(y),math.sin(y),math.cos(z),math.sin(z)
	local cf = CFrame.new()
	cf.rotation = { c*e,-c*f,d, a*f+b*d*e,a*e-b*d*f,-b*c, b*f-a*d*e,b*e+a*d*f,a*c }
	return cf
end
cm.__mul = function(a, b)
	if b.X then return a:PointToWorldSpace(b) end
	local result = CFrame.new(a:PointToWorldSpace(b.Position))
	local ar, br, rr = rotation(a), rotation(b), {}
	for row = 0, 2 do for col = 0, 2 do
		rr[row*3+col+1] = ar[row*3+1]*br[col+1]+ar[row*3+2]*br[col+4]+ar[row*3+3]*br[col+7]
	end end
	result.rotation = rr
	return result
end
local originalIsA = methods.IsA
function methods:IsA(class)
	return (class == 'BasePart' and self.ClassName == 'WedgePart') or originalIsA(self, class)
end

-- Kamera-Ereignisse und Vektorrechnung; kein Rendering oder echter Eingaberouter.
vm.__div = function(v, n) return Vector3.new(v.X / n, v.Y / n, v.Z / n) end
local vectorIndex = vm.__index
vm.__index = function(v, key)
	if key == "Unit" then return v / v.Magnitude end
	return vectorIndex(v, key)
end
function vm:Lerp(other, alpha) return self + (other - self) * alpha end
Vector3.zero = Vector3.new(0, 0, 0)
function cm:VectorToWorldSpace(v) return self:PointToWorldSpace(v) - self.Position end
function CFrame.lookAt(position, target)
	local cf = CFrame.new(position)
	cf.target = target
	return cf
end
local render, wheel
services.RunService = { RenderStepped = { Connect = function(_, fn) render = fn end } }
services.UserInputService = {
	InputChanged = { Connect = function(_, fn) wheel = fn end },
	GetFocusedTextBox = function() return nil end,
	IsKeyDown = function() return false end,
}
services.GuiService = {}
modules.PlayerModule = { GetControls = function() return { Disable = function() end, Enable = function() end } end }
services.Players = { LocalPlayer = { PlayerScripts = { WaitForChild = function() return "PlayerModule" end } } }
local task = { spawn = function(fn) fn() end }
workspace.CurrentCamera = {}
local terrainClears = {}
workspace.Terrain.FillBlock = function(_, cf, size, material)
	table.insert(terrainClears, { cf = cf, size = size, material = material })
end

local cameraMultiply = cm.__mul
cm.__mul = function(a, b)
	local result = cameraMultiply(a, b)
	if a.target then result.target = a.target end
	return result
end
