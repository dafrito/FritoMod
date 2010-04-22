if nil ~= require then
    require "FritoMod_Testing/ReflectiveTestSuite";
    require "FritoMod_Testing/Assert";
    require "FritoMod_Testing/Tests";

    require "FritoMod_UI/Metatables-StyleClient";
end;

local Suite = ReflectiveTestSuite:New("FritoMod_UI.Metatables-StyleClient");
local sc = nil;

Suite:AddListener(Metatables.Noop({
	TestStarted = function()
		sc = Metatables.StyleClient();
	end
}));

function Suite:TestStyleClient()
	sc.color = "blue";
	Assert.Equals("blue", sc.color, "Client returns correct color");
end;

function Suite:TestStyleClientIgnoresCapitalization()
	sc.color = 1;
	Assert.Equals(1, sc.COLOR, "Client returns value for color in spite of capital letters");
end;

function Suite:TestStyleClientOnNil()
	Assert.Equals(nil, sc.color, "Client returns nil on missing value");
end;

function Suite:TestStyleClientThrowsOnNilKey()
	Assert.Exception("StyleClient doesn't accept setting nil keys", function()
		sc[nil] = true;
	end);
end;

function Suite:TestStyleClientHandlesRetrievingNilKeys()
	Assert.Equals(nil, sc[nil], "StyleClient returns nil for nil key");
end;

function Suite:TestStyleClientUsesComputedStyle()
	sc.ComputedStyle("color", function(k)
		Assert.Equals("color", k, "StyleClient passes style name to computers");
		return 2;
	end);
	Assert.Equals(2, sc.color, "StyleClient returns computed value");
end;

function Suite:TestStyleClientPrefersExplictOverComputed()
	sc.ComputedStyle("color", Functions.Return, 2);
	sc.color = 3;
	Assert.Equals(3, sc.color);
end;

function Suite:TestStyleClientDoesntSuppressFalseExplicitValues()
	sc.color = false;
	Assert.Equals(false, sc.color, "Explicit style can return false");
end;

function Suite:TestStyleClientDoesntSuppressFalseComputed()
	sc.ComputedStyle("color", Functions.Return, false);
	Assert.Equals(false, sc.color, "Computed style can return false");
end;

function Suite:TestTranslateOverridesStyle()
	sc.TranslatedStyle("color", Functions.Return, 1);
	sc.color = 2;
	Assert.Equals(1, sc.color, "Style is overridden by translator");
end;

function Suite:TestTranslateOverridesMissingStyles()
	sc.TranslatedStyle("color", Functions.Return, 1);
	Assert.Equals(1, sc.color, "Missing styles are always translated");
end;

function Suite:TestProcessedValues()
	sc.ProcessedStyle("color", Functions.Return, 1);
	sc.color = true;
	Assert.Equals(1, sc.color);
end;

function Suite:TestSilentProcessorDoesntModifyStyle()
	sc.ProcessedStyle("color", function(v)
		Assert.Equals(1, v, "Processor receives style");
	end);
	sc.color = 1;
	Assert.Equals(1, sc.color);
end;

function Suite:TestStyleClientInheritors()
	sc.Inherits({
		color = 1
	});
	Assert.Equals(1, sc.color);
end;

function Suite:TestStyleClientInheritsStyleClient()
	local parent = Metatables.StyleClient();
	parent.color = 2;
	sc.Inherits(parent);
	Assert.Equals(2, sc.color);
end;

function Suite:TestStyleClientInheritsDeepStyleClient()
	local p = Metatables.StyleClient();
	local gp = Metatables.StyleClient();
	gp.ComputedStyle("color", Functions.Return, 1);
	p.Inherits(gp);
	sc.Inherits(p);
	Assert.Equals(1, sc.color);
end;

function Suite:TestRemoveInherited()
	local r = sc.Inherits({
		color = 1
	});
	r();
	Assert.Equals(nil, sc.color);
end;