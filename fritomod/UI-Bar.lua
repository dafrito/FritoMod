if nil ~= require then
	require "wow/Frame-Container";
	require "fritomod/Frames";
	require "fritomod/UI-Icon";
	require "fritomod/OOP-Class";
	require "fritomod/Metatables-StyleClient";
end;

UI = UI or {};

local Bar = OOP.Class();
UI.Bar = Bar;

local DEFAULT_STYLE = {
	-- Which direction is the "minimum"
	barAnchor = "left",

	-- The size of a full bar. This will be used even if the bar is "vertical"
	width = 100,

	-- The static height of the bar. This will be used even if the bar is "vertical"
	height = 30,

	-- Optional texture. This will override the bar color if provided.
	barTexture = "bar",

	-- Color for the bar. This will modify the bar texture if provided.
	barColor = "green",

	-- Background texture, visible when the bar is depleted. Overrides background color
	backgroundTexture = nil,

	-- Background color. This will be the background's vertex color if provided.
	backgroundColor = nil,

	invert = false
};

function Bar:Constructor(parent, style)
	parent = Frames.AsRegion(parent);
	assert(Frames.IsRegion(parent), "Parent frame must be provided. Got: "..tostring(parent));

	self.style = Metatables.StyleClient(style);
	self.style:Inherits(DEFAULT_STYLE);

	self.frame = CreateFrame("Frame", nil, parent);
	self.frame:Lower();

	-- Here's the intended frame/texture configuration, for future reference.
	-- self.frame (f)   - background
	-- self.bar (f)
	--   +-- color      - background
	--   +-- barTexture - artwork
	--   +-- self.spark - overlay

	-- I use a frame here to ensure the bar appears above the background
	-- and any backdrop I use.
	self.bar = CreateFrame("Frame", nil, self.frame);
	self.bar:Hide();

	Frames.WH(self.frame, self.style.width, self.style.height);

	self.barTexture = Frames.Texture(self.bar, self.style.barTexture);
	self.barTexture:SetDrawLayer("ARTWORK");

	local color = self.bar:CreateTexture();
	color:SetDrawLayer("BACKGROUND");
	Frames.Color(color, self.style.barColor);
	Anchors.ShareAll(color, self.bar);

	if self.style.backgroundTexture then
		Frames.Texture(self.frame, self.style.backgroundTexture);
		if self.style.backgroundColor then
			self.bar:SetVertexColor(Media.color[self.style.backgroundColor]);
		end;
	else
		Frames.Color(self.frame, self.style.backgroundColor or "black");
	end;

	self.spark = self.bar:CreateTexture(nil, "OVERLAY");
	self.spark:SetTexture("Interface/CastingBar/UI-CastingBar-Spark");
	self.spark:SetBlendMode("ADD");
	self.spark:SetWidth(32);
	self.spark:SetPoint("CENTER", self.bar, "RIGHT", -1, 0);

	Anchors.Share(self.bar, self.frame, self.style.barAnchor);
	Anchors.ShareVerticals(self.bar);
end;

function Bar:SetMonitor(monitor, frequency)
	if self.callback then
		self.callback();
	end;
	self.callback = Functions.OnlyOnce(Lists.CallEach, {
		monitor:OnState("Active", Timing.Every, frequency, function()
			self:SetPercent(monitor:PercentCompleted());
		end),
		monitor:OnState("Completed", self, "SetPercent", 1),
		monitor:OnState("Inactive", self, "SetPercent", 0)
	});
end;

function Bar:SetAmount(amount)
	if self.callback then
		self.callback();
	end;
	self.callback = amount:OnChange(function(min, value, max)
		self:SetPercent(amount:Percent());
	end);
end;

function Bar:SetPercentCallback(callback, ...)
	callback=Curry(callback, ...);
	if self.callback then
		self.callback();
	end;
	self.callback = callback(self, "SetPercent");
end;

function Bar:SetPercent(percent)
	percent = Math.Clamp(0, percent, 1);
	if not Math.IsReal(percent) or percent == 0 then
		self.spark:SetAlpha(0);
		self.bar:Hide();
		return;
	end;

	self.bar:Show();

	self.bar:SetWidth(Frames.IWidth(self) * percent);
	self.barTexture:SetTexCoord(0, percent, 0, 1);

	-- Set the height again.
	self.spark:SetHeight(self.style.height * (32 / 18));

	-- Set the spark opacity
	if percent >= 1 then
		self.spark:SetAlpha(0);
	elseif percent > .9 then
		self.spark:SetAlpha(Math.Interpolate(1, 10 * (percent - .9), 0));
	elseif percent < .1 then
		self.spark:SetAlpha(Math.Interpolate(0, 10 * percent, 1));
	else
		self.spark:SetAlpha(1);
	end;
end;

function Bar:Destroy()
	if self.callback then
		self.callback();
		self.callback = nil;
	end;
	Frames.Destroy(self.bar, self.frame);
end;
