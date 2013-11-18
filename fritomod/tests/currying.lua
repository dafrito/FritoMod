local Suite = CreateTestSuite("fritomod.currying");

local function Sum(...)
	local sum = 0;
	for i=1, select("#", ...) do
		sum = sum + (select(i, ...) or 0);
	end;
	return sum;
end;

function Suite:TestCurryFunction()
	Assert.Equals(3, CurryFunction(Sum, 1, 2)(), "Curry adds both arguments to the function");
	Assert.Equals(3, CurryFunction(Sum)(1, 2), "Curry handles no arguments properly");
	Assert.Equals(3, CurryFunction(Sum, 1)(2), "Curry handles split arguments properly");
end;

function Suite:TestCurry()
	local function Do(x, y)
		return x + y;
	end;
	Assert.Equals(3, Curry(Do, 1, 2)(), "Curry adds both arguments to the function");
	Assert.Equals(3, Curry(Do)(1, 2), "Curry handles no arguments properly");
	Assert.Equals(3, Curry(Do, 1)(2), "Curry handles split arguments properly");
end;

function Suite:TestCurryMethod()
	local t = {};
	local flag = Tests.Flag();
	function t:hello(arg)
		assert(self == t);
		assert(arg == "No time");
		flag.Raise();
	end;
	local f = CurryMethod(t, "hello")
	f("No time");
	flag.Assert();
end;

function Suite:TestCurryDoesntCurryPlainFunctions()
	local function Do(x, y)
		return x + y;
	end;
	Assert.Equals(Do, Curry(Do), "Curry doesn't needlessly curry functions");
end;

function Suite:TestCurryHandlesCurriedNilValuesInNormalSituations()
	local c = Curry(Sum, 1, nil, 2);
	Assert.Equals(6, c(3));
	local c = Curry(Sum, nil, 1, 2);
	Assert.Equals(6, c(3));
	local c = Curry(Sum, nil, 1, 2);
	Assert.Equals(6, c(3));
end;

function Suite:TestCurryAcceptsPassedNilValues()
	local c = Curry(Sum, 1, 2);
	Assert.Equals(15, c(3,4,5));
	Assert.Equals(12, c(nil,4,5));
	Assert.Equals(11, c(3,nil,5));
	Assert.Equals(10, c(3,4,nil));
end;

do
    local g1, g2, g3;
    Suite:AddListener(Metatables.Noop({
        TestStarted = function(self, suite)
            g1 = __g1;
            g2 = __g2;
            g3 = __g3;
        end,
        TestFinished = function(self, suite)
            __g1 = g1;
            __g2 = g2;
            __g3 = g3;
        end
    }));
end;

function Suite:TestGlobalEnvironmentIsClean()
    Assert.Nil(__g1);
    Assert.Nil(__g2);
    Assert.Nil(__g3);
end;

function Suite:TestCurryPreservesSetfenvWithCurryFunction()
    if luaversion() >= luaversion("Lua 5.2") then
        -- setfenv was removed in Lua 5.2
        return;
    end;
    local globals = {};
    local function Foo(a, b)
        __g1 = a + b;
    end;
    setfenv(Foo, globals);

    local curried = Curry(Foo, 3);
    curried(4);
    Assert.Nil(__g1);
    Assert.Equals(7, globals.__g1);
end;

function Suite:TestForcedSeal()
	local function Sniff(value, ...)
		Assert.Equals(true, value, "ForcedSeal passes curried arguments");
		Assert.Equals(0, select("#", ...), "ForcedSeal suppresses additional arguments");
		return 2;
	end;
	local sealed = ForcedSeal(Sniff, true);
	Assert.Equals(2, sealed(), "ForcedSeal returns sealed function's returned value");

	Assert.Exception("Sealed function rejects nil arguments", sealed, nil);
	Assert.Exception("Sealed function rejects intermediate nil arguments", sealed, 1, nil, 3);
end;

function Suite:TestForcedFunctionOnNoop()
	local foo = {};
	foo.bar = ForcedFunction(foo, function(value)
		Assert.Equals(1, value, "Value was passed appropriately");
	end);
	foo.bar(1);
end;

function Suite:TestForcedFunction()
	local foo = {};
	foo.bar = ForcedFunction(foo, function(value)
		Assert.Equals(1, value, "Value was passed appropriately");
	end);
	foo:bar(1);
end;

function Suite:TestForcedMethodOnNoop()
	local foo = {};
	foo.bar = ForcedMethod(foo, function(self, value)
		Assert.Equals(foo, self, "Self argument was passed appropriately");
		Assert.Equals(1, value, "Value was passed appropriately");
	end);
	foo:bar(1);
end;

function Suite:TestForcedMethod()
	local foo = {};
	foo.bar = ForcedMethod(foo, function(self, value)
		Assert.Equals(foo, self, "Self argument was passed appropriately");
		Assert.Equals(1, value, "Value was passed appropriately");
	end);
	foo.bar(1);
end;
