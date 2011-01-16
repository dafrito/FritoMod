-- Callbacks that deal with UI events, like clicking and key presses.
--
-- These callbacks follow this general pattern:
--
-- Callbacks.MouseDown(frame, callbackFunc, ...)

if nil ~= require then
    require "wow/Frame-Events";

    require "currying";
    require "Lists";
    require "Timing";
    require "ToggleDispatcher";
end;

Callbacks=Callbacks or {};

-- This helper function provides the backbone of our event listeners. It uses a
-- ToggleDispatcher to handle event dispatching whenver the onEvent or offEvent are
-- called.
local function ToggledEvent(onEvent, offEvent, installer)
    local uninstaller;
    local eventListenerName=onEvent.."Listeners";
    return function(frame, func, ...)
        func=Curry(func, ...);
        if frame:GetScript(onEvent) then
            assert(frame[eventListenerName],
            "Callbacks refuses to overwrite an existing "..onEvent.." listener");
        end;
        local dispatcher;
        if frame[eventListenerName] then
            dispatcher=frame[eventListenerName];
        else
            dispatcher=ToggleDispatcher:New();
            function dispatcher:Install()
                frame:SetScript(onEvent, function(_, ...)
                    dispatcher:Fire(...);
                end);
                frame:SetScript(offEvent, function(_, ...)
                    dispatcher:Reset(...);
                end);
                frame[eventListenerName]=dispatcher;
                if installer then
                    uninstaller=installer(frame);
                end;
            end;
            function dispatcher:Uninstall()
                if uninstaller then
                    uninstaller();
                    uninstaller=nil
                end;
                frame:SetScript(onEvent, nil);
                frame:SetScript(offEvent, nil);
                frame[eventListenerName]=nil;
            end;
        end;
        return dispatcher:Add(func);
    end;
end;

-- A helper function that ensures we only enable the mouse on a frame when
-- necessary. This coordination is necessary since different callbacks all 
-- require an enabled mouse.
local function enableMouse(f)
    f.mouseListenerTypes=f.mouseListenerTypes or 0;
    f.mouseListenerTypes=f.mouseListenerTypes+1;
    f:EnableMouse(true);
    return Functions.OnlyOnce(function()
        f.mouseListenerTypes=f.mouseListenerTypes-1;
        if f.mouseListenerTypes <= 0 then
            f:EnableMouse(false);
        end;
    end)
end;

-- Calls the specified callback whenever dragging starts. You'll
-- need to manually call Frame:RegisterForDrag along with this method in order to 
-- receive drag events. Frames.Draggable helps with this.
Callbacks.DragFrame=ToggledEvent("OnDragStart", "OnDragStop", enableMouse);

-- Calls the specified callback whenever a click begins on a frame.
Callbacks.MouseDown=ToggledEvent("OnMouseDown", "OnMouseUp", enableMouse);

-- Calls the specified callback whenever the mouse enters and leaves the specified frame.
Callbacks.EnterFrame=ToggledEvent("OnEnter", "OnLeave", enableMouse);
Callbacks.MouseEnter=Callbacks.EnterFrame;
Callbacks.FrameEnter=Callbacks.EnterFrame;

-- Calls the specified callback whenever the specified frame is shown.
Callbacks.ShowFrame=ToggledEvent("OnShow", "OnHide");

local CLICK_TOLERANCE=.5;
function Callbacks.Click(f, func, ...)
    func=Curry(func, ...);
    if f:HasScript("OnClick") then
        if not f.doClick then
            local listeners={};
            f.doClick=Functions.Spy(
                Curry(Lists.Insert, listeners),
                Functions.Install(function()
                    return Curry(Lists.CallEach, {
                        enableMouse(f),
                        Callbacks.HookScript(f, "OnClick", Lists.CallEach, listeners)
                    });
                end)
            );
        end;
        return f.doClick(func);
    end;
    return Callbacks.MouseDown(f, function(btn)
        local downTime=GetTime();
        return function()
            local upTime=GetTime();
            if upTime-downTime < CLICK_TOLERANCE then
                func(btn);
            end;
        end;
    end);
end;

-- Returns the cursor's distance from the time this function was invoked.
--
-- The specified frame's scale will be used to adjust the distance. If no frame
-- is provided, UIParent is used. If you're using this function for frame
-- movement, you should provide the frame that is being moved.
function Callbacks.CursorOffset(frame, func, ...)
    frame=frame or UIParent;
    func=Curry(func, ...);
    local origX, origY=GetCursorPosition();
    local lastX, lastY=origX, origY;
    return Timing.OnUpdate(function()
        local x, y=GetCursorPosition();
        if lastX~=x or lastY~=y then
            lastX, lastY=x,y;
            func(
                (x-origX)/frame:GetEffectiveScale(),
                (y-origY)/frame:GetEffectiveScale()
            );
        end;
    end);
end;
Callbacks.MouseOffset=Callbacks.CursorOffset;

local function enableKeyboard(f)
    f.keyListenerTypes=f.keyListenerTypes or 0;
    f.keyListenerTypes=f.keyListenerTypes+1;
    f:EnableKeyboard(true);
    return Functions.OnlyOnce(function()
        f.keyListenerTypes=f.keyListenerTypes-1;
        if f.keyListenerTypes <= 0 then
            f:EnableKeyboard(false);
        end;
    end)
end;

local function KeyListener(event)
    local frameEvent="_"..event;
    Callbacks[event]=function(f, func, ...)
        func=Curry(func, ...);
        if not f[frameEvent] then
            local listeners={};
            f[frameEvent]=Functions.Spy(
                Curry(Lists.Insert, listeners),
                Functions.Install(function()
                    return Curry(Lists.CallEach, {
                        enableKeyboard(f),
                        Callbacks.Script(f, "On"..event, Lists.CallEach, listeners)
                    });
                end)
            );
        end;
        return f[frameEvent](func);
    end;
end;

KeyListener("Char");
KeyListener("KeyUp");
KeyListener("KeyDown");
