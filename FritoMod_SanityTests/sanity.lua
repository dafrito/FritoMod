-- Tests that assert some non-intuitive or plain ambiguous behavior. These tests only assert
-- lua-specific functionality, so test failures indicate an incompatible lua version.

if nil ~= require then
    require "FritoMod_Testing/ReflectiveTestSuite";
    require "FritoMod_Testing/Assert";
    require "FritoMod_Testing/Tests";
end;

local Suite = ReflectiveTestSuite:New("FritoMod_SanityTests.sanity");

local function Count(...)
    return select("#", ...);
end;

function Suite:TestSparseArray()
    local list = {nil, nil, nil};
    list[3] = true;
    Assert.Equals(3, #list, "Sparse array retains size");
end;

function Suite:TestSparseArrayIsWipedOutDuringRemoval()
    local list = {nil, nil, nil};
    list[3] = true;
    list[2] = true;
    table.remove(list, 3);
    Assert.Equals(0, #list, "Sparse array's size is lost due to table.remove");
end;

function Suite:TestVarargsSizeIsConstant()
    Assert.Equals(2, Count(nil, nil), "Varargs retains size in spite of nil values");
end;