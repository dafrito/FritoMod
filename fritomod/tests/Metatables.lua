local Suite = CreateTestSuite("fritomod.Metatables");

function Suite:TestDefault()
	local t = {};
	Metatables.Default(t, true);
	Assert.Equals(true, t.missing, "t returns the specified default value");
	Metatables.Default(t, false);
	Assert.Equals(false, t.missing, "t returns the new default value");
end;

function Suite:TestDefaultNeverActuallyAssignsTheDefault()
	local t = {};
	Metatables.Default(t, true);
	Assert.Equals(true, t.missing, "t returns the specified default value");
	Assert.Nil(rawget(t, "missing"), "t is never actually assigned the default value");
end;

function Suite:TestDefaultIsPickyAboutNilValues()
	local t = {};
	Assert.Exception("Default throws when given nil table", Metatables.Default, nil, true);
	Assert.Exception("Default throws when given nil defaultValue", Metatables.Default, t, nil);
	Assert.Nil(Metatables.Default(t, 1), "Default does not return anything");
end;

function Suite:TestConstructedValue()
	local t = {};
	Metatables.ConstructedValue(t, function(key)
		return "Value: " .. key;
	end);
	Assert.Equals("Value: 1", t[1], "t returns the constructed default value");
	Assert.Equals("Value: 1", rawget(t, 1), "The constructed default value is actually assigned");
	Metatables.ConstructedValue(t, function(key)
		return "Bar: " .. key;
	end);
	Assert.Equals("Value: 1", t[1], "t retains the default value");
	Assert.Equals("Bar: 2", t[2], "t assigns the new default from the most recent ConstructedValue call");
end;

function Suite:TestConstructedValueIsPickyAboutNilValues()
	local t = {};
	Assert.Exception("ConstructedValue throws when given nil table", Metatables.ConstructedValue, nil, Noop);
	Assert.Exception("ConstructedValue throws when given nil constructor",
		Metatables.ConstructedValue, t, nil);
	Assert.Nil(Metatables.ConstructedValue(t, Tables.New), "ConstructedValue does not return anything");
end;

function Suite:TestDefensive()
	local defensive = Metatables.Defensive();

	Assert.Exception("DefensiveTable throws on missing method calls", function()
		defensive:MissingMethod();
	end);

	Assert.Exception("DefensiveTable throws on missing field accesses", function()
		local _ = defensive.MissingField;
	end);
end;

function Suite:TestForcedFunctions()
	local foo = Metatables.ForceFunctions();
	function foo.Bar(first, ...)
		Assert.Equals(1, first, "Self argument was ignored");
	end;
	foo.Bar(1);
	foo:Bar(1);
end;

function Suite:TestForcedFunctionsCleansPreexistingArguments()
	local foo = {};
	function foo.Bar(first)
		assert(first == 1, "Self argument was ignored");
	end;
	Metatables.ForceFunctions(foo);
	foo:Bar(1);
	foo.Bar(1);
end;

function Suite:TestForcedMetatableReturnsEqualFunctionsForEqualKeys()
	local foo = {};
	function foo.Bar(a, b)
		return a + b;
	end;
	Metatables.ForceFunctions(foo);
	Assert.Equals(foo.Bar, foo.Bar);
end;

function Suite:TestForcedMethods()
	local foo = Metatables.ForceMethods();
	function foo:Bar(first)
		assert(self == foo, "Self argument is included");
		assert(first == 1, "First argument is one");
	end;
	foo:Bar(1);
	foo.Bar(1);
end;

function Suite:TestForcedMethodsCleansPreexistingArguments()
	local foo = {}
	function foo:Bar(first)
		assert(self == foo, "Self argument is included");
		assert(first == 1, "First argument is one");
	end;
	Metatables.ForceMethods(foo);
	foo:Bar(1);
	foo.Bar(1);
end;
