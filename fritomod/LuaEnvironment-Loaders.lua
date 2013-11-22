if nil ~= require then
    require "fritomod/basic";
    require "fritomod/LuaEnvironment";
    require "fritomod/Metatables";
end;

LuaEnvironment.Loaders={};
local loaders=LuaEnvironment.Loaders;

function loaders.Filesystem(prefix)
	prefix = prefix or ".";
	return function(name, env)
		if nil ~= require then
			require "lfs";
		end;
		if not lfs or not loadfile then
			return;
		end;
		name = tostring(name);
		local file=name;
		if not file:find("[.]lua$") then
			file=name..".lua";
		end;
		file = prefix .. "/" ..file;
		if not lfs.attributes(file) then
			-- The file was not accessible, so just return.
			return;
		end;
		local runner, err;
		if luaversion() >= luaversion("Lua 5.2") then
			runner, err=loadfile(file, "bt", env);
		else
			runner, err=loadfile(file);
		end;
		if runner then
			return runner;
		end;
		return nil, err;
	end;
end;

function loaders.LocalRequire(path)
	path = path or package.path;
	return function(name, env)
		if package.loaded[name] ~= nil then
			return function()
				return package.loaded[name];
			end;
		end;
		local file = package.searchpath(name, path);
		if not file then
			return nil, "No module found with name: " .. name;
		end;
		local runner, err;
		if luaversion() >= luaversion("Lua 5.2") then
			runner, err=loadfile(file, "bt", env);
		else
			runner, err=loadfile(file);
		end;
		if runner then
			return runner;
		end;
		return nil, err;
	end;
end;

function loaders.NativeRequire(mask)
	path = path or package.path;
	if type(mask) == "string" then
		mask = Headless(Strings.StartsWith, mask);
	elseif not mask then
		mask = Curry(Functions.Return, true);
	end;
	return function(name, env)
		if not mask(name) then
			return nil, "Path is not accepted by this loader";
		end;
		return Curry(require, name);
	end;
end;

function loaders.Ignore(...)
	local ignored;
	if select("#", ...) == 0 then
		ignored = {};
		Metatables.Default(ignored, true);
	elseif select("#", ...) > 1
	or type(...) ~= "table" then
		ignored = {};
		for i=1, select("#", ...) do
			ignored[select(i, ...)] = true;
		end;
	else
		assert(select("#", ...) == 1);
		assert(type(...) == "table");
		if #(...) > 0 then
			for _, name in ipairs(...) do
				ignored[name] = true;
			end;
		else
				ignored = ...;
		end;
	end;
	assert(ignored, "Ignored was not provided");
	return function(package, env)
		if ignored[package] then
			return Noop;
		end;
	end;
end;

-- vim: set noet :
