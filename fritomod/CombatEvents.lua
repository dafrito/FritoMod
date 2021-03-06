-- Allows access to combat log events in a style similar to Events.

if nil ~= require then
	require "fritomod/Functions";
	require "fritomod/Lists";
	require "fritomod/Events";
end;

CombatEvents = {};
local eventListeners = {};
CombatEvents._eventListeners = eventListeners;

CombatEvents._call = function(timestamp, event, ...)
	local listeners = eventListeners[event];
	if listeners then
		Lists.CallEach(listeners, timestamp, ...);
	end;
end;
local setUp = Functions.Install(Events.COMBAT_LOG_EVENT_UNFILTERED, CombatEvents._call);

setmetatable(CombatEvents, {
	__index = function(self, key)
		if type(key) == "table" then
			return function(func, ...)
				func=Curry(func, ...);
				local removers = {};
				for i=1, #key do
					table.insert(removers, CombatEvents[key[i]](func))
				end;
				return Functions.OnlyOnce(Lists.CallEach, removers);
			end;
		end;
		eventListeners[key] = {};
		self[key] = Functions.Spy(
			function(func, ...)
				return Lists.Insert(eventListeners[key], Curry(func, ...));
			end,
			setUp
		);
		return rawget(self, key);
	end,
	__call = function(self, ...)
		return Events.COMBAT_LOG_EVENT_UNFILTERED(...);
	end
});
