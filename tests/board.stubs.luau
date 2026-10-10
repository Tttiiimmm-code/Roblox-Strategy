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
local function signal()
	local listeners = {}
	return { Connect = function(_, fn)
		local connected = true
		table.insert(listeners, function(...) if connected then fn(...) end end)
		return { Disconnect = function() connected = false end }
	end, Fire = function(_, ...) for _, fn in table.clone(listeners) do fn(...) end end }
end
local mt={__index=function(o,k) if k=='Position' then return o._cf.Position elseif k=='CFrame' then return o._cf elseif k=='Parent' then return o._parent end return methods[k] or o._props[k] end,__newindex=function(o,k,v)
 if k=='Parent' then if o._parent then local p=o._parent;while p do p.DescendantRemoving:Fire(o);p=p.Parent end;for i,c in o._parent._children do if c==o then table.remove(o._parent._children,i);break end end end rawset(o,'_parent',v);if v then table.insert(v._children,o);local p=v;while p do p.DescendantAdded:Fire(o);p=p.Parent end end
 elseif k=='Position' then o._cf=CFrame.new(v) elseif k=='CFrame' then o._cf=v else if k=='Color' and o:GetAttribute('RejectColor') then error('Color nicht verfügbar') end;o._props[k]=v end end}
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
function methods:FindFirstChildOfClass(class)
	for _, child in self:GetChildren() do if child:IsA(class) then return child end end
end
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
local bridgeRayMiss = false
local bridgeSamples = {}
function workspace:Raycast(v, _, params)
	local model = params and params.FilterDescendantsInstances and params.FilterDescendantsInstances[1]
	if model and model:GetAttribute("BridgeLength") then
		if bridgeRayMiss then return nil end
		local box, size = model:GetBoundingBox()
		local delta = model:GetAttribute("BridgeAlongX") and v.X - box.Position.X or v.Z - box.Position.Z
		local half = model:GetAttribute("BridgeLength") / 2
		if math.abs(delta) > half then return nil end
		local height = box.Position.Y - size.Y / 2 + size.Y * (1 - (delta / half) ^ 2)
		table.insert(bridgeSamples, { x = v.X, z = v.Z, height = height })
		return { Position = Vector3.new(v.X, height, v.Z) }
	end
	return { Position = Vector3.new(v.X, 0, v.Z) }
end
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
-- Erneutes PivotTo benötigt auch die inverse vollständige Rotation.
function cm:Inverse()
	local r = rotation(self)
	local result = CFrame.new()
	result.rotation = { r[1], r[4], r[7], r[2], r[5], r[8], r[3], r[6], r[9] }
	result.Position = result:PointToWorldSpace(self.Position * -1)
	return result
end
local originalIsA = methods.IsA
function methods:IsA(class)
	return (class == 'BasePart' and (self.ClassName == 'WedgePart' or self.ClassName == 'UnionOperation')) or originalIsA(self, class)
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
workspace.CurrentCamera = { FieldOfView = 70, ViewportSize = { X = 1280, Y = 720 } }
local terrainClears, terrainBlocks, terrainColumns = {}, {}, {}
local terrainSerial = 0
local terrainVoxelWrites = 0
local Region3 = { new = function(lo, hi) return { lo = lo, hi = hi } end }
local function terrainHeightAt(x, z)
	local column = terrainColumns[math.floor(x / 4) .. ":" .. math.floor(z / 4)]
	local serial = column and column.serial or -1
	local height, material = column and column.height, column and column.material
	for index = #terrainBlocks, 1, -1 do
		local block = terrainBlocks[index]
		if block.serial <= serial then break end
		if x >= block.lo.X and x < block.hi.X and z >= block.lo.Z and z < block.hi.Z then
			height = block.material ~= Enum.Material.Air and block.hi.Y or nil
			material = block.material
			break
		end
	end
	return height, material
end
local previousRaycast = workspace.Raycast
function workspace:Raycast(origin, direction, params)
	if params and params.FilterDescendantsInstances and params.FilterDescendantsInstances[1] == self.Terrain then
		local height = terrainHeightAt(origin.X, origin.Z)
		if height and height <= origin.Y and height >= origin.Y + direction.Y then return { Position = Vector3.new(origin.X, height, origin.Z) } end
		return nil
	end
	return previousRaycast(self, origin, direction, params)
end
workspace.Terrain.FillBlock = function(_, cf, size, material)
	terrainSerial += 1
	local lo, hi = cf.Position - size * 0.5, cf.Position + size * 0.5
	table.insert(terrainBlocks, { lo = lo, hi = hi, material = material, serial = terrainSerial })
	if material == Enum.Material.Air then
		table.insert(terrainClears, { cf = cf, size = size, material = material })
		for key, column in terrainColumns do
			if column.x >= lo.X and column.x < hi.X and column.z >= lo.Z and column.z < hi.Z then terrainColumns[key] = nil end
		end
	end
end
workspace.Terrain.WriteVoxels = function(_, region, resolution, materials, occupancies)
	terrainVoxelWrites += 1
	assert(resolution == 4, "Terrainauflösung muss 4 sein")
	local lo, hi = region.lo, region.hi
	local settings, hub = modules.Config.LANDSCAPE, modules.Config.HUB_ORIGIN
	assert(hi.X <= hub.X - settings.hubHalfWidth or lo.X >= hub.X + settings.hubHalfWidth
		or hi.Z <= hub.Z - settings.hubHalfDepth or lo.Z >= hub.Z + settings.hubHalfDepth, "Voxelregion berührt Hub-Schutzbereich")
	local nx, ny, nz = (hi.X - lo.X) / 4, (hi.Y - lo.Y) / 4, (hi.Z - lo.Z) / 4
	assert(nx * ny * nz <= 4194304, "Schreibblock zu groß")
	for _, value in { lo.X, lo.Y, lo.Z, hi.X, hi.Y, hi.Z } do assert(value % 4 == 0, "Region nicht ausgerichtet") end
	assert(#materials == nx and #occupancies == nx, "Falsche X-Dimension")
	terrainSerial += 1
	for ix = 1, nx do
		assert(#materials[ix] == ny and #occupancies[ix] == ny, "Falsche Y-Dimension")
		for iy = 1, ny do assert(#materials[ix][iy] == nz and #occupancies[ix][iy] == nz, "Falsche Z-Dimension") end
		for iz = 1, nz do
			local height, material
			for iy = 1, ny do
				local occupancy, kind = occupancies[ix][iy][iz], materials[ix][iy][iz]
				assert(occupancy >= 0 and occupancy <= 1 and ((occupancy == 0) == (kind == Enum.Material.Air)), "Ungültige Terrainbelegung")
				if occupancy > 0 then height, material = lo.Y + (iy - 1 + occupancy) * 4, kind end
			end
			local x, z = lo.X + (ix - 0.5) * 4, lo.Z + (iz - 0.5) * 4
			terrainColumns[math.floor(x / 4) .. ":" .. math.floor(z / 4)] = { x = x, z = z, height = height, material = material, serial = terrainSerial }
		end
	end
end

local cameraMultiply = cm.__mul
cm.__mul = function(a, b)
	local result = cameraMultiply(a, b)
	if a.target then result.target = a.target end
	return result
end

-- Facetten verwenden echte Vektorprodukte und eine vollstaendige Basis.
function vm:Dot(other) return self.X * other.X + self.Y * other.Y + self.Z * other.Z end
function vm:Cross(other) return Vector3.new(self.Y * other.Z - self.Z * other.Y, self.Z * other.X - self.X * other.Z, self.X * other.Y - self.Y * other.X) end
function CFrame.fromMatrix(position, right, up, back)
	local cf = CFrame.new(position)
	cf.rotation = { right.X, up.X, back.X, right.Y, up.Y, back.Y, right.Z, up.Z, back.Z }
	return cf
end
