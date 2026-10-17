-- Anschlussprüfung mit aktuellen Modulen; keine Schriftmessung und kein Renderer.
local function event()
	local listeners = {}
	local signal = { Connect = function(_, fn)
		local active = true
		table.insert(listeners, function(...) if active then fn(...) end end)
		return { Disconnect = function() active = false end }
	end, Fire = function(_, ...) for _, fn in listeners do fn(...) end end }
	signal.Once = signal.Connect
	return signal
end
local Vector2 = {}
local vectorMeta = {
	__mul = function(a, b) return Vector2.new(a.X * b.X, a.Y * b.Y) end,
	__sub = function(a, b) return Vector2.new(a.X - b.X, a.Y - b.Y) end,
	__index = function(v, k) if k == "Magnitude" then return math.sqrt(v.X * v.X + v.Y * v.Y) end end,
}
function Vector2.new(x, y) return setmetatable({ X = x, Y = y }, vectorMeta) end
local Vector3 = { new = function(x, y, z) return { X = x, Y = y, Z = z } end }
local Color3 = {}
function Color3.new(r, g, b)
	return { R = r, G = g, B = b, Lerp = function(self) return self end, ToHex = function() return "ffffff" end }
end
function Color3.fromRGB(r, g, b) return Color3.new(r / 255, g / 255, b / 255) end
local UDim = { new = function(s, o) return { Scale = s, Offset = o } end }
local UDim2 = {}
local dimMeta = {
	__add = function(a, b) return UDim2.new(a.X.Scale + b.X.Scale, a.X.Offset + b.X.Offset, a.Y.Scale + b.Y.Scale, a.Y.Offset + b.Y.Offset) end,
	__sub = function(a, b) return UDim2.new(a.X.Scale - b.X.Scale, a.X.Offset - b.X.Offset, a.Y.Scale - b.Y.Scale, a.Y.Offset - b.Y.Offset) end,
}
function UDim2.new(xs, xo, ys, yo) return setmetatable({ X = UDim.new(xs or 0, xo or 0), Y = UDim.new(ys or 0, yo or 0) }, dimMeta) end
function UDim2.fromScale(x, y) return UDim2.new(x, 0, y, 0) end
function UDim2.fromOffset(x, y) return UDim2.new(0, x, 0, y) end
local Enum = setmetatable({}, { __index = function(t, k)
	local e = setmetatable({}, { __index = function(_, n) return k .. "." .. n end }); t[k] = e; return e
end })
local ColorSequence = { new = function(...) return { ... } end }
local ColorSequenceKeypoint = ColorSequence
local NumberSequence = ColorSequence
local NumberSequenceKeypoint = ColorSequence
local TweenInfo = { new = function(...) return { ... } end }
local CFrame = { new = function() return {} end, lookAt = function() return {} end }
local objects, Instance = {}, {}
local methods = {}
function methods:GetChildren()
	local children = {}; for _, o in objects do if o.Parent == self then table.insert(children, o) end end; return children
end
function methods:GetDescendants()
	local list = {}; for _, c in self:GetChildren() do table.insert(list, c); for _, d in c:GetDescendants() do table.insert(list, d) end end; return list
end
function methods:FindFirstChild(name, recursive)
	for _, c in recursive and self:GetDescendants() or self:GetChildren() do if c.Name == name then return c end end
end
function methods:FindFirstAncestorOfClass(class)
	local p = self.Parent; while p do if p:IsA(class) then return p end; p = p.Parent end
end
function methods:WaitForChild(name) return self:FindFirstChild(name) end
function methods:FindFirstChildOfClass(class) for _, c in self:GetChildren() do if c.ClassName == class then return c end end end
function methods:IsA(class)
	return self.ClassName == class or class == "GuiObject" and (self.ClassName:find("Frame") ~= nil or self.ClassName:find("Text") ~= nil or self.ClassName == "CanvasGroup")
end
function methods:GetPropertyChangedSignal(name)
	if not self._events[name] then self._events[name] = event() end; return self._events[name]
end
function methods:SetAttribute(name, value) self._attrs[name] = value end
function methods:GetAttribute(name) return self._attrs[name] end
function methods:Destroy() for _, c in self:GetChildren() do c:Destroy() end; self.Parent = nil; self.Destroying:Fire() end
function Instance.new(class)
	local o = setmetatable({ _props = {
		ClassName = class, Name = class, Text = "", TextSize = 14, Visible = true, Scale = 1, Value = 0,
		ZIndex = 1, TextTransparency = 0, TextStrokeTransparency = 1, Enabled = true,
		AutomaticSize = Enum.AutomaticSize.None, TextBounds = Vector2.new(0, 0), LineHeight = 1, TextWrapped = false, TextScaled = false,
		Size = UDim2.new(), Position = UDim2.new(), AnchorPoint = Vector2.new(0, 0),
		AbsolutePosition = Vector2.new(0, 0), AbsoluteSize = Vector2.new(1280, 720), AbsoluteWindowSize = Vector2.new(600, 400),
		AbsoluteCanvasSize = Vector2.new(1200, 720), BackgroundTransparency = 0,
	}, _events = {}, _attrs = {} }, {
		__index = function(self, k)
			if k == "Parent" then return self._props.Parent end
			if k == "ContentText" then return (self.Text:gsub("<[^>]+>", "")) end
			if methods[k] then return methods[k] end
			if self._props[k] ~= nil then return self._props[k] end
			if k == "Activated" or k == "InputBegan" or k == "InputEnded" or k == "MouseEnter" or k == "MouseLeave" or k == "Destroying" or k == "Changed" or k == "DescendantAdded" or k == "DescendantRemoving" then
				return methods.GetPropertyChangedSignal(self, k)
			end
			return methods.FindFirstChild(self, k)
		end,
		__newindex = function(self, k, v)
			if k == "Parent" and self.Parent then
				local removed = { self }; for _, child in self:GetDescendants() do table.insert(removed, child) end
				local p = self.Parent
				while p do for _, child in removed do p.DescendantRemoving:Fire(child) end; p = p.Parent end
			end
			self._props[k] = v; if k == "Parent" and v then local p = v; while p do p.DescendantAdded:Fire(self); p = p.Parent end end; if k == "TextScaled" and v then self.TextWrapped = true end
			if self._events[k] then self._events[k]:Fire(v) end
		end,
	})
	table.insert(objects, o); return o
end
local replicated = Instance.new("Folder")
local shared = Instance.new("Folder"); shared.Name = "Shared"; shared.Parent = replicated
local playerGui = Instance.new("PlayerGui")
local player = Instance.new("Player"); player.UserId = 1; playerGui.Name = "PlayerGui"; playerGui.Parent = player
local testTweens = {}
local services = {
	TextService = { calls = 0, GetTextSize = function(self, content, size, _, frame)
		self.calls += 1
		local width = #content * size / 2
		local lines = math.max(1, math.ceil(width / frame.X))
		return Vector2.new(math.min(width, frame.X), size * lines)
	end },
	GuiService = { TopbarInset = { Max = Vector2.new(1280, 58) }, insetChanged = event(), GetPropertyChangedSignal = function(self) return self.insetChanged end, GetGuiInset = function(self) return Vector2.new(0, self.guiTop or 58), Vector2.new(0, 0) end,
		GetInsetArea = function(self, inset) return inset == Enum.ScreenInsets.DeviceSafeInsets and self.device or self.full end,
		device = { Min = Vector2.new(0, -58), Max = Vector2.new(1280, 720) }, full = { Min = Vector2.new(0, -58), Max = Vector2.new(1280, 720), Width = 1280, Height = 778 },
		core = { Min = Vector2.new(0, 0), Width = 1280, Height = 720 },
	},
	ReplicatedStorage = replicated, Players = { LocalPlayer = player }, UserInputService = { TouchEnabled = true, MouseEnabled = false },
	TweenService = { Create = function(_, target, _, goal)
		local animation = { Play = function() for k, v in goal do target[k] = v end end, Cancel = function() end, Completed = event() }
		table.insert(testTweens, animation)
		return animation
	end },
}
local game = { GetService = function(_, name) return services[name] end }
local workspace = Instance.new("Folder"); workspace.CurrentCamera = Instance.new("Camera")
workspace.CurrentCamera.ViewportSize = Vector2.new(1280, 720)
local deferred = {}; local task = { spawn = function() end, delay = function() end, defer = function(fn) table.insert(deferred, fn) end }; local function flushDeferred() while #deferred > 0 do local fn = table.remove(deferred, 1); fn() end end; local diagnosticMessages = {}; local basePrint = print; local function print(message) if message:find("[UI-Diagnose]", 1, true) then table.insert(diagnosticMessages, message) else basePrint(message) end end
local modules = { SoundPlayer = { play = function() end } }
