if nil ~= require then
	require "OOP-Class";

	require "wow/Frame";
end;

WoW.Button=OOP.Class(WoW.Frame);
WoW.FrameTypes.button=WoW.Button;

function WoW.Button:SetHighlightTexture()
end;

function WoW.Button:SetPushedTexture()
end;