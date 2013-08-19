if nil ~= require then
	require "fritomod/OOP-Class";
	require "fritomod/CombatObjects";
	require "fritomod/Callbacks-CombatObjects";
end;

CombatObjects=CombatObjects or {};

local SpellEvent = OOP.Class("CombatObjects.SpellEvent");
CombatObjects.Spell = SpellEvent;

function SpellEvent:Constructor(...)
	self:Set(...);
end;

function SpellEvent:Set(id, name, school)
	self.id = id;
	self.name = name;
	self.school = school;
end;

function SpellEvent:Clone()
	return SpellEvent:New(
		self:Id(),
		self:Name(),
		self:School());
end;

function SpellEvent:Id()
	return self.id or 0;
end;
SpellEvent.ID = SpellEvent.Id;

function SpellEvent:Name()
	if not self.name then
		self.name = GetSpellInfo(self:Id()) or "Unknown";
	end;
	return self.name;
end;

function SpellEvent:School()
	return self.school or 0;
end;

function SpellEvent:SchoolName()
	return CombatLog_String_SchoolString(self:School());
end;

function SpellEvent:SchoolColor()
	return Media.color[self:SchoolName()];
end;

function SpellEvent:Icon()
	return Media.texture[
		select(3, GetSpellInfo(self:Id())) or
		self:Name()];
end;
SpellEvent.Texture = SpellEvent.Icon;

function SpellEvent:Link()
	local link = GetSpellLink(self:Id());
	return link or self:Name();
end;

function SpellEvent:IsFunnel()
	local isFunnel = select(5, GetSpellInfo(self:Id()));
	return isFunnel or false;
end;

function SpellEvent:Cost()
	local cost = select(4, GetSpellInfo(self:Id()));
	return cost or 0;
end;

function SpellEvent:CostType()
	local costType = select(4, GetSpellInfo(self:Id()));
	return costType;
end;

function SpellEvent:CostTypeName()
	local costType = self:CostType();
	if costType == -2 then
		return "Health";
	else
		return CombatLog_String_PowerType(costType);
	end;
end;

function SpellEvent:Is(what)
	if tonumber(what) then
		-- It's an ID;
		return self:ID() == tonumber(what);
	end;
	if type(what) == "string" then
		return self:Name():lower() == what:lower();
	end;
	if type(what) == "table" then
		if IsCallable(what.ID) then
			return self:Is(what:ID());
		end;
		if IsCallable(what.Name) then
			return self:Is(what:Name());
		end;
		if IsCallable(what.Value) then
			return self:Is(what:Value());
		end;
	end;
	if IsCallable(what) then
		return self:Is(what());
	end;
	return false;
end;

CombatObjects.AddSharedEvent("SourceSpell", "Spell");
CombatObjects.AddSharedEvent("VictimSpell", "Spell");

CombatObjects.SimpleSuffixHandler("INTERRUPT", "VictimSpell");

Callbacks.InterruptObjects = Curry(
	Callbacks.SuffixedCombatObjects,
	"INTERRUPT");

function Callbacks.MySpellCasts(listener, ...)
	listener = Curry(listener, ...);
	local spell = CombatObjects.Spell:New();
	return Events.UNIT_SPELLCAST_SUCCEEDED(function(who, name, rank, _, id)
		if who ~= "player" then
			return;
		end;
		spell:Set(id, name);
		listener(spell);
	end);
end;
