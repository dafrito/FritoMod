if nil ~= require then
    require "fritomod/currying";
    require "fritomod/OOP-Class";
    require "fritomod/ListenerList";
    require "fritomod/Lists";
    require "hack/Assets";
    require "hack/Connectors";
end;

Hack = Hack or {};
Hack.Script = OOP.Class("Hack.Script");
local Script = Hack.Script;
local Assets = Hack.Assets;
local Connectors = Hack.Connectors;

function Script:Constructor()
    self.connectors = {};
    self.content = "";
    self.listeners = ListenerList:New();
    self.compileListeners = ListenerList:New();
end;

function Script:SetContent(content)
    if self.content == content then
        return;
    end;
    self.content = content;
    self.compiles = self.content ~= nil;
    if self.compiles then
        if self.workingEnvironment then
            self.compiles = Bool(
                self.workingEnvironment:LoadString(self.content)
            );
        else
            self.compiles = false;
        end;
    end;
    self:FireUpdate();
end;

function Script:GetContent()
    return self.content;
end;

function Script:Compiles()
    return self.compiles;
end;

function Script:AddConnector(connector, ...)
    connector = Curry(connector, ...);
    local rv = Lists.Insert(self.connectors, connector);
    self:FireUpdate();
    return rv;
end;

function Script:Execute(env, ...)
    assert(env, "Environment must not be falsy");
    Lists.CallEach(self.connectors, env);
    self.workingEnvironment = env;
    self:AddDestructor(self.workingEnvironment:AddDestructor(function()
        if self.workingEnvironment == env then
            self.workingEnvironment = nil;
        end;
    end));
    return env:Run(self.content, ...);
end;

function Script:OnUpdate(func, ...)
    return self.listeners:Add(func, ...);
end;

function Script:OnCompilingUpdate(func, ...)
    return self.compileListeners:Add(func, ...);
end;

function Script:FireUpdate()
    if not self.listeners:IsFiring() then
        self.listeners:Fire();
    end;
    if self:Compiles() and not self.compileListeners:IsFiring() then
        self.compileListeners:Fire();
    end;
end;
