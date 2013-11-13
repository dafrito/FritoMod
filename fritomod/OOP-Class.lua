if nil ~= require then
	require "fritomod/basic";
	require "fritomod/currying";
	require "fritomod/OOP";
	require "fritomod/Lists";
end;

local function SetDestroyedMetatable(self)
	local id = self:ID();
	local name = self:ToString();
	local DESTROYED_METATABLE = {
		__index = function(self, key)
			if tostring(key):match("^log") then
				return self.class[key];
			end;
			error(name .. " has been destroyed and cannot be reused for getting " .. tostring(key));
		end,
		__newindex = function(self, key)
			error(name .. " has been destroyed and cannot be reused for setting " .. tostring(key));
		end,
		__tostring = function()
			return "destroyed:" .. name;
		end,
	};

	setmetatable(self, nil);
	for key, _ in pairs(self) do
		-- Blow everything away, except the class
		if key ~= "class" and tostring(key):match("^log") then
			self[key] = nil;
		end;
	end;

	-- Allow detection from OOP.IsDestroyed
	self.destroyed = true;

	-- Allow spurious invocations of Destroy
	self.Destroy = Noop;

	-- Allow ToString to be invoked directly
	function self:ToString()
		return tostring(self);
	end;

	function self:ID()
		return id;
	end;
	self.Id = self.ID;

	setmetatable(self, DESTROYED_METATABLE);
end;

local CLASS_METATABLE = {
	-- A default constructor. This is called after all constructors are used,
	-- and will only be called on the immediate class that's being created;
	-- it is each constructor's responsibility to either call their parent's
	-- constructor, or perform any action that the parent constructor is tasked
	-- to do.
	--
	-- This should be overridden in most cases by whatever construction you wish
	-- to do, and the signature used here does not need to be preserved. Any
	-- return value is ignored.
	Constructor = function(self)
		-- noop
	end,

	-- Calls all constructors on the specified object.
	--
	-- object
	--	 the object that is constructed
	-- throws
	--	 if object is falsy
	ConstructObject = function(klass, object, ...)
		assert(object, "Object must not be falsy");
		if klass.__constructors then
			for i=1, #klass.__constructors do
				local constructor = klass.__constructors[i];
				local destructor = constructor(object, ...);
				if IsCallable(destructor) then
					object:AddDestructor(destructor);
				end;
			end;
		end;
	end,

	-- Add a mixin to this class. A mixin is a callable should expect the signature
	-- mixinFunc(class). A mixin is expected to add some functionality to a class.
	--
	-- mixinFunc
	--	 The function that performs the work of the mixin. It is called immediately.
	--
	--	 If the mixinFunc returns a callable, then that callable will be invoked
	--	 for every instance of the class. It should expect the signature
	--	 "callable(object)"
	-- ...
	--	 any arguments that are curried to mixinFunc
	AddMixin = function(self, mixinFunc, ...)
		mixinFunc = Curry(mixinFunc, ...);
		local constructor = mixinFunc(self);
		if constructor then
			self:AddConstructor(constructor);
		end;
	end,

	-- Adds the specified constructor function to this class. The constructor will be called
	-- for all created instances of this class, but before the instance's actual constructor
	-- is invoked.
	--
	-- The return value, if callable, will be treated as a destructor. It will be invoked when
	-- the object's Destroy method is called.
	AddConstructor = function(self, constructorFunc, ...)
		constructorFunc = Curry(constructorFunc, ...);
		-- Use rawget here to ensure we don't get the constructors for this class, instead of
		-- deferring to a super class.
		local constructors = rawget(self, "__constructors");
		if not constructors then
			constructors = {};
			rawset(self, "__constructors", constructors);
		end;
		return Lists.Insert(constructors, constructorFunc);
	end,

	-- Adds the specified destructor function to this class or instance. Instance-specific
	-- destructors will be invoked when Destroy is called.
	--
	-- Note that the instance reference will be provided only to class-specific destructors.
	-- If you need (or do not need) the instance reference, then you should explicitly
	-- Seal or Curry it accordingly.
	AddDestructor = function(self, destructor, ...)
		if not IsCallable(destructor) and select("#", ...) == 0 and type(destructor) == "table" and destructor.Destroy then
			return self:AddDestructor(destructor, "Destroy");
		end;
		destructor = Curry(destructor, ...);

		if OOP.IsClass(self) then
			return self:AddConstructor(function(instance)
				return Seal(destructor, instance);
			end);
		end;
		local destructors = rawget(self, "__destructors");
		if not destructors then
			destructors = {};
			rawset(self, "__destructors", destructors);
		end;
		return Lists.Insert(destructors, destructor);
	end,

	ClassName = function(self)
		return "Object";
	end,

	ID = function(self)
		if self.id then
			if self.idParent then
				return self.numericId .. " - " .. tostring(self.id)  .. " - " .. tostring(self.idParent);
			end;
			return self.numericId .. " - " .. tostring(self.id);
		end;
		return self.numericId;
	end,
	Id = function(...)
		return self:ID(...);
	end,

	SetID = function(self, newId, parent)
		self.id = newId;
		self.idParent = parent;
	end,
	SetId = function(...)
		return self:SetID(...);
	end,

	-- Destroy this object. All instance-specific destructors will be run, then all class-
	-- specific destructors will be run.
	--
	-- Subclasses that override this method should always invoke it once their destruction
	-- has completed.
	Destroy = function(self)
		local function RunDestructors(destructors)
			if not destructors then
				return;
			end;
			while #destructors > 0 do
				local dtor = table.remove(destructors, #destructors);
				dtor();
			end;
		end;

		-- Use rawget so we don't get the class-specific destructors
		RunDestructors(rawget(self, "__destructors"));

		-- Clean up our destructors so they're only invoked once, even if Destroy
		-- is called multiple times.
		rawset(self, "__destructors", nil);

		-- Blow away the class reference, so class-specific destructors are not called.
		SetDestroyedMetatable(self);
	end
}

-- Creates a new instance of this class.
local function New(class, ...)
	local numericId = rawget(class, "__idcount") or 1;
	rawset(class, "__idcount", numericId + 1);
	local instance = {
		__index = class,
		__tostring = function(self)
			return self:ToString();
		end,
		numericId = numericId,
		class=class
	};
	setmetatable(instance, instance);

	function instance:ToString()
		local str;
		if rawget(self, "ClassName") or rawget(self.class, "ClassName") then
			str = self:ClassName() .. " ".. tostring(self:ID());
		else
			str ="subclass:".. self:ClassName() .. " " .. Reference(self);
		end;
		return str;
	end;

	local function Initialize(class, ...)
		if class.super then
			Initialize(class.super, ...);
		end;
		class:ConstructObject(instance, ...);
	end;
	Initialize(class, ...);

	instance:Constructor(...);
	return instance;
end

-- Creates a callable table that creates instances of itself when invoked. This is analogous
-- to classes: a super-class may be provided in the arguments, and that class will act as the
-- default source of methods for the returned class.
--
-- You may also provide other functions in the arguments. These functions act as mixins, and are
-- allowed to add functionality to this class. If they return a callable, that callable will be
-- invoked on every instance of this class.
--
-- ...
--	 Any mixins, and up to one super class, that should be integrated into this class.
-- throws
--	 if any provided argument is not either a mixin or a class
--	 if more than one super-class is provided (multiple inheritance in this manner is not supported)
OOP.Class = function(...)
	local class = {};
	class.__index = CLASS_METATABLE;
	class.New = New;
	class.__tostring = function(self)
		if rawget(self, "ClassName") then
			return "Class "..self:ClassName().."@"..Reference(self);
		end;
		return "Subclass of "..self:ClassName().."@"..Reference(self);
	end
	setmetatable(class, class);

	for n = 1, select('#', ...) do
		local mixinOrClass = select(n, ...);
		if not mixinOrClass then
			error("Mixin or class is falsy. Index " .. n);
		end;
		if OOP.IsClass(mixinOrClass) then
			--  It's a class, so make it our super class.
			if class.super then
				error("Class cannot have more than one super class");
			end;
			class.super = mixinOrClass;
			class.__index = class.super;
		elseif IsCallable(mixinOrClass) then
			local constructor = mixinOrClass(class);
			if IsCallable(constructor) then
				class:AddConstructor(constructor);
			end;
		elseif type(mixinOrClass) == "string" then
			local className = mixinOrClass;
			function class:ClassName()
				return className;
			end;
		else
			error(("Object is not a mixin or super-class: %s"):format(tostring(mixinOrClass)));
		end;
	end

	if not class.super then
		class.super = CLASS_METATABLE;
	end;

	return class;
end;

-- vim: set noet :
