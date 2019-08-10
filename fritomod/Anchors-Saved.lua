-- Anchors.Named provides a way to align UI elements to a saved location. Here's
-- my typical workflow:
--
-- local frame=CreateFrame("Frame", nil, UIParent);
-- ... -- create your frame
-- Anchors.Center(frame, Anchors.Named("FritoMod.MagicalStuff"));
--
-- Now our frame is aligned to the named anchor "FritoMod.MagicalStuff". Initially,
-- an anchor appears in the center of the screen. You can move the anchor by
-- calling:
--
-- Anchors.Unlock();
--
-- which will show the anchor as a small white box. Drag it to where you want, then
-- call Anchors.Lock() to hide it. The location will be saved between sessions.
--
-- Don't use named anchors as parents, as they will be hidden when Anchors.Lock() is
-- called. You also shouldn't modify an anchor, as these changes won't be persisted.
--
-- See also:
-- PersistentAnchor.lua
-- Frames-Mouse.lua

if nil ~= require then
	require "wow/Frame-Layout";
	require "wow/FontString";

	require "fritomod/PersistentAnchor";
	require "fritomod/Anchors";
	require "fritomod/Callbacks-Mouse";
	require "fritomod/Frames-Position";
end;

-- A mapping of anchor names to PersistentAnchor objects.
local anchors={};
Anchors.anchors=anchors;

local anchorFrame;
local anchorNameFrame;
function CreateAnchorFrame()
    -- anchorFrame is the parent for every anchor we create here.
    anchorFrame=CreateFrame("Frame", nil, UIParent);
    anchorFrame:SetAllPoints();
    anchorFrame:SetFrameStrata("HIGH");

    anchorNameFrame=anchorFrame:CreateFontString();
    anchorNameFrame:SetFont("Fonts\\FRIZQT__.TTF", 11);
end;

local removers={};
local showing=false;
local function ShowAnchor(name, anchor)
	if not showing then
		return;
	end;
	Log.Entercf("Saved Anchors", "Anchor Shows", "Showing anchor", name);
	local dragging = false;
	Lists.InsertAll(removers,
		anchor:Show(),
		Callbacks.EnterFrame(anchor.frame, function()
			if not dragging then
				anchorNameFrame:Show();
				anchorNameFrame:ClearAllPoints();
				Anchors.Flip(anchorNameFrame, anchor.frame, "top", 4);
				anchorNameFrame:SetText(name);
			end;
			return Curry(anchorNameFrame, "Hide");
		end),
		Callbacks.MouseDown(anchor.frame, function()
			dragging = true;
			anchorNameFrame:Hide();
			return function()
				dragging = false;
				anchorNameFrame:Show();
			end;
		end),
		Callbacks.Click(anchor.frame, function(b)
			if b~="MiddleButton" then
				return;
			end;
			-- Remove our frame.
			Frames.Position(nil, name);
			anchors[name]:Hide();
			anchors[name]=nil;
		end)
	);
	Log.Leave();
end;

function Anchors.Named(name)
    CreateAnchorFrame();
	local anchor;
	if anchors[name] then
        Log.Entercf("Saved Anchors", "Named anchor retrievals", "Retrieving existing anchor for", name);
		anchor=anchors[name];
	else
        Log.Entercf("Saved Anchors", "Named anchor retrievals", "Creating new anchor for", name);
		anchor=PersistentAnchor:New(anchorFrame);
		Frames.Position(anchor.frame, name);
		anchors[name]=anchor;
		ShowAnchor(name, anchor)
	end;
    Log.Leave();
	return anchor.frame;
end;
Anchors.Saved=Anchors.Named;
Anchors.Save=Anchors.Named;
Anchors.Name=Anchors.Named;
Anchors.Persistent=Anchors.Named;
Anchors.Persistant=Anchors.Named;
Anchors.Persisting=Anchors.Named;
Anchors.Persisted=Anchors.Named;
Anchors.Persist=Anchors.Named;

function Anchors.Show()
	if showing then
		return;
	end;
	Log.Entercf("Saved Anchors", "Changing named anchor visibility", "Showing all named anchors.");
	showing=true;
	Tables.EachPair(anchors, ShowAnchor);
	Log.Leave();
	return Anchors.Hide;
end;
Anchors.Unlock=Anchors.Show;

function Anchors.Hide()
	if not showing then
		return;
	end;
	showing=false;
	Log.Entercf("Saved Anchors", "Changing named anchor visibility", "Hiding all named anchors.");
	Lists.CallEach(removers);
	Log.Leave();
end;
Anchors.Lock=Anchors.Hide;

function Anchors.Toggle()
	if showing then
		Anchors.Hide();
	else
		Anchors.Show();
	end;
end;

function Anchors.Names()
	return Tables.Keys(anchors);
end;

function Anchors.Reset(name)
	if not anchors[name] then
		return;
	end
	anchors[name]:Reset();
end;
