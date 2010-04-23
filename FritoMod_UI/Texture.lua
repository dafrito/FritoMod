if nil ~= require then
    require "FritoMod_OOP/OOP-Class";

    require "FritoMod_UI/LayoutUtil";
    require "FritoMod_UI/StyleClient";
    require "FritoMod_UI/InvalidatingProxy";
end;

Texture = OOP.Class(StyleClient, InvalidatingProxy);
local Texture = Texture;

Texture.defaults = {
	BorderSize = 10,
	Inset = 3,
	Background = "Blizzard Tooltip",
	Border = "Blizzard Tooltip",
	BackgroundColor = "Black",
}

Texture.mediaKeyNames = {
	Background = "Background", 
	Border = "Border",
	BackgroundColor = "Color"
};

function Texture:ToString()
	return "Texture";
end;

-------------------------------------------------------------------------------
--
--  Layout Methods
--
-------------------------------------------------------------------------------

function Texture:ApplyTo(frame)
	frame = LayoutUtil:GetFrame(frame);
	local inset = self:GetInset();
	if not frame.SetBackdrop then
		error("Texture: The frame provided does not support textures: " .. tostring(displayObject));
	end;
	frame:SetBackdrop{
		bgFile = self:GetBackground(),
		edgeFile = self:GetBorder(),
		edgeSize = self:GetBorderSize(),
		insets = {
			left = inset, 
			right = inset, 
			top = inset, 
			bottom = inset
		}
	};
	local a,r,g,b=self:GetBackgroundColor();
	frame:SetBackdropColor(r,g,b,a);
end;

-------------------------------------------------------------------------------
--
--  Getters and Setters
--
-------------------------------------------------------------------------------

StyleClient.AddComputedValue(Texture, "Background", StyleClient.CHANGE_LAYOUT);
StyleClient.AddComputedValue(Texture, "Border", StyleClient.CHANGE_LAYOUT);
StyleClient.AddComputedValue(Texture, "BorderSize", StyleClient.CHANGE_SIZE);
StyleClient.AddComputedValue(Texture, "Inset", StyleClient.CHANGE_SIZE);
StyleClient.AddComputedValue(Texture, "BackgroundColor", StyleClient.CHANGE_LAYOUT);

-------------------------------------------------------------------------------
--
--  Overridden Methods: StyleClient
--
-------------------------------------------------------------------------------

function Texture:FetchDefaultFromTable(valueName)
	return Texture.defaults[valueName];
end;

function Texture:GetMediaKeyName(valueName)
	return Texture.mediaKeyNames[valueName];
end;


