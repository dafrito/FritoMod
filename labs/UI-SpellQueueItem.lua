if nil ~= require then
	require "fritomod/OOP-Class";
	require "fritomod/StateDispatcher";
	require "fritomod/Monitor";
	require "fritomod/Metatables-StyleClient";
	require "fritomod/currying";
	require "fritomod/Callbacks";
	require "fritomod/CombatObjects-Spell";
	require "fritomod/Lists";
	require "fritomod/UI-Icon";
end;

local SpellQueueItem = OOP.Class("UI.SpellQueueItem", StateDispatcher);
UI.SpellQueueItem = SpellQueueItem;

local DEFAULT_STYLE = {

	-- How long it takes to hide the icon once it's fired.
	hideDuration = ".5s",

	-- The icon alpha when the action is on cooldown
	pendingAlpha = .4,

	-- The icon size
	size = 50,

	-- The icon backdrop and border
	backdrop = "default"
};

function SpellQueueItem:Constructor(parent, style)
	SpellQueueItem.super.Constructor(self, "Inactive");
	self.frame = UI.Icon:New(parent);

	self.style = Metatables.StyleClient(style);
	self.style:Inherits(DEFAULT_STYLE);

	-- Make ourselves transparent while the spell is on cooldown. I could use interpolate to animate this
	-- but I'd prefer us to "pop" when it's ready.
	self:OnState("Cooldown", function(self)
		Frames.Alpha(self, self.style.pendingAlpha);
		return Seal(Frames.Alpha, self, 1);
	end, self);

	-- Fade out when we've fired our action, and transition to Inactive when the fade is complete.
	self:OnState("Fired", function()
		Animations.Hide(self, self.style.hideDuration);
		Timing.After(self.style.hideDuration, self, "Fire", "Inactive");
	end);

	self:OnState("Inactive", Frames.Hide, self);
end;

function SpellQueueItem:SetPending(monitor)
	self.frame:SetTexture(monitor);
end;


function SpellQueueItem:SetCurrent(monitor)
	if self.monitoring then
		self.monitoring();
		self.monitoring=nil;
	end;
	if monitor == nil then
		self:Fire("Inactive");
		return;
	end;
	self.frame:SetTexture(monitor);
	self.monitor = monitor;

	trace("Setting SpellQueueItem to monitor: "..monitor.name);

	local cooldownWatcher = monitor:OnState("Active", function(self)
		self:Fire("Cooldown");
	end, self);

	local completedWatcher = monitor:OnState("Completed", function(self)
		cooldownWatcher();
		self:SafeFire("Ready");
	end, self);

	-- When we're ready to cast, watch to see if we actually do. This event will only fire once since
	-- we call our remover when we first see our action.
	local castWatcher;
	castWatcher = self:OnState("Ready", Callbacks.MySpellCasts, function(self, spell)
		if spell:Is(monitor) then
			completedWatcher();
			self:Fire("Fired");
			castWatcher();
		end;
	end, self);

	local removers = {
		cooldownWatcher,
		completedWatcher,
		castWatcher
	};

	local destructor = Curry(Lists.CallEach, removers);

	-- Once we've fired, listen for our "Inactive" event. Destroy all our listeners when this event
	-- is fired.
	local destroyOnceFired = self:OnState("Fired", Callbacks.OnlyOnce,
		Curry(self, "OnState", "Inactive"), destructor);
	table.insert(removers, destroyOnceFired);

	self.monitoring = destructor;
end;

function SpellQueueItem:Destroy()
	if self.monitoring then
		self.monitoring();
		self.monitoring=nil;
		self.monitor=nil;
	end;
	Frames.Destroy(self.frame);
	SpellQueueItem.super.Destroy(self);
end;
