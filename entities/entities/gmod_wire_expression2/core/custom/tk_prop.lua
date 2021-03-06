/******************************************************************************\
Prop Core by MrFaul started by ZeikJT
modified for TKSB by making parentTo a superparent
report any wishes, issues to Mr.Faul@gmx.de (GER || ENG pls)
\******************************************************************************/

E2Lib.RegisterExtension("tk_propcore", false)
tk_PropCore = {}
local sbox_E2_maxProps = CreateConVar("sbox_E2_maxProps", "-1", FCVAR_ARCHIVE)
local sbox_E2_maxPropsPerSecond = CreateConVar("sbox_E2_maxPropsPerSecond", "4", FCVAR_ARCHIVE)
-- 2: Players can affect their own props, 1: Only admins, 0: Disabled
local sbox_E2_PropCore = CreateConVar("sbox_E2_PropCore", "2", FCVAR_ARCHIVE)
local E2totalspawnedprops = 0
local E2tempSpawnedProps = 0
local TimeStamp = 0

local function TempReset()
    if (CurTime() >= TimeStamp) then
        E2tempSpawnedProps = 0
        TimeStamp = CurTime() + 1
    end
end
hook.Add("Think", "TempReset", TempReset)

function tk_PropCore.ValidSpawn()
    if E2tempSpawnedProps >= sbox_E2_maxPropsPerSecond:GetInt() then return false end

    if sbox_E2_maxProps:GetInt() <= -1 then
        return true
    elseif E2totalspawnedprops >= sbox_E2_maxProps:GetInt() then
        return false
    end

    return true
end

function tk_PropCore.ValidAction(self, entity, cmd)
    local ply = self.player
    if (cmd == "spawn" or cmd == "Tdelete") then return true end
    if (not validPhysics(entity)) then return false end
    if (not isOwner(self, entity)) then return false end
    if entity:IsPlayer() then return false end
    if (not IsValid(entity)) then return false end

    return sbox_E2_PropCore:GetInt() == 2 or (sbox_E2_PropCore:GetInt() == 1 and ply:IsAdmin())
end

local function MakePropNoEffect(...)
    local backup = DoPropSpawnedEffect
    DoPropSpawnedEffect = function() end
    local ret = MakeProp(...)
    DoPropSpawnedEffect = backup

    return ret
end

function tk_PropCore.CreateProp(self, model, pos, angles, freeze)
    if (not util.IsValidModel(model) or not util.IsValidProp(model) or not tk_PropCore.ValidSpawn()) then return nil end
    pos = E2Lib.clampPos(pos)
    local prop

    if self.data.propSpawnEffect then
        prop = MakeProp(self.player, pos, angles, model, {}, {})
    else
        prop = MakePropNoEffect(self.player, pos, angles, model, {}, {})
    end

    if not prop then return end
    prop:Activate()
    self.player:AddCleanup("props", prop)
    undo.Create("e2_spawned_prop")
    undo.AddEntity(prop)
    undo.SetPlayer(self.player)
    undo.Finish()
    local phys = prop:GetPhysicsObject()

    if (phys:IsValid()) then
        if (angles ~= nil) then
            E2Lib.setAng(phys, angles)
        end

        phys:Wake()

        if (freeze > 0) then
            phys:EnableMotion(false)
        end
    end

    prop:CallOnRemove("wire_expression2_propcore_remove", function(prop)
        E2totalspawnedprops = E2totalspawnedprops - 1
    end)

    E2totalspawnedprops = E2totalspawnedprops + 1
    E2tempSpawnedProps = E2tempSpawnedProps + 1

    return prop
end

function tk_PropCore.PhysManipulate(this, pos, rot, freeze, gravity, notsolid)
    if (notsolid ~= nil) then
        this:SetNotSolid(notsolid ~= 0)
    end

    local phys = this:GetPhysicsObject()

    if (pos ~= nil) then
        E2Lib.setPos(phys, Vector(pos[1], pos[2], pos[3]))
    end

    if (rot ~= nil) then
        E2Lib.setAng(phys, Angle(rot[1], rot[2], rot[3]))
    end

    if (freeze ~= nil) then
        phys:EnableMotion(freeze == 0)
    end

    if (gravity ~= nil) then
        phys:EnableGravity(gravity ~= 0)
    end

    phys:Wake()

    if (not phys:IsMoveable()) then
        phys:EnableMotion(true)
        phys:EnableMotion(false)
    end
end

--------------------------------------------------------------------------------
e2function entity propSpawn(string model, number frozen)
    if not tk_PropCore.ValidAction(self, nil, "spawn") then return nil end

    return tk_PropCore.CreateProp(self, model, self.entity:GetPos() + self.entity:GetUp() * 25, self.entity:GetAngles(), frozen)
end

e2function entity propSpawn(entity template, number frozen)
    if not tk_PropCore.ValidAction(self, nil, "spawn") then return nil end
    if not IsValid(template) then return nil end

    return tk_PropCore.CreateProp(self, template:GetModel(), self.entity:GetPos() + self.entity:GetUp() * 25, self.entity:GetAngles(), frozen)
end

e2function entity propSpawn(string model, vector pos, number frozen)
    if not tk_PropCore.ValidAction(self, nil, "spawn") then return nil end

    return tk_PropCore.CreateProp(self, model, Vector(pos[1], pos[2], pos[3]), self.entity:GetAngles(), frozen)
end

e2function entity propSpawn(entity template, vector pos, number frozen)
    if not tk_PropCore.ValidAction(self, nil, "spawn") then return nil end
    if not IsValid(template) then return nil end

    return tk_PropCore.CreateProp(self, template:GetModel(), Vector(pos[1], pos[2], pos[3]), self.entity:GetAngles(), frozen)
end

e2function entity propSpawn(string model, angle rot, number frozen)
    if not tk_PropCore.ValidAction(self, nil, "spawn") then return nil end

    return tk_PropCore.CreateProp(self, model, self.entity:GetPos() + self.entity:GetUp() * 25, Angle(rot[1], rot[2], rot[3]), frozen)
end

e2function entity propSpawn(entity template, angle rot, number frozen)
    if not tk_PropCore.ValidAction(self, nil, "spawn") then return nil end
    if not IsValid(template) then return nil end

    return tk_PropCore.CreateProp(self, template:GetModel(), self.entity:GetPos() + self.entity:GetUp() * 25, Angle(rot[1], rot[2], rot[3]), frozen)
end

e2function entity propSpawn(string model, vector pos, angle rot, number frozen)
    if not tk_PropCore.ValidAction(self, nil, "spawn") then return nil end

    return tk_PropCore.CreateProp(self, model, Vector(pos[1], pos[2], pos[3]), Angle(rot[1], rot[2], rot[3]), frozen)
end

e2function entity propSpawn(entity template, vector pos, angle rot, number frozen)
    if not tk_PropCore.ValidAction(self, nil, "spawn") then return nil end
    if not IsValid(template) then return nil end

    return tk_PropCore.CreateProp(self, template:GetModel(), Vector(pos[1], pos[2], pos[3]), Angle(rot[1], rot[2], rot[3]), frozen)
end

--------------------------------------------------------------------------------
e2function void entity:propDelete()
    if not tk_PropCore.ValidAction(self, this, "delete") then return end
    this:Remove()
end

e2function void entity:propBreak()
    if not tk_PropCore.ValidAction(self, this, "break") then return end
    this:Fire("break", 1, 0)
end

local function removeAllIn( self, tbl )
    local count = 0

    for k, v in pairs(tbl) do
        if (IsValid(v) and isOwner(self, v) and not v:IsPlayer()) then
            count = count + 1
            v:Remove()
        end
    end

    return count
end

e2function number table:propDelete()
    if not tk_PropCore.ValidAction(self, nil, "Tdelete") then return end
    local count = removeAllIn(self, this.s)
    count = count + removeAllIn(self, this.n)
    self.prf = self.prf + count

    return count
end

e2function number array:propDelete()
    if not tk_PropCore.ValidAction(self, nil, "Tdelete") then return end
    local count = removeAllIn(self, this)
    self.prf = self.prf + count

    return count
end

--------------------------------------------------------------------------------
e2function void entity:propManipulate(vector pos, angle rot, number freeze, number gravity, number notsolid)
    if not tk_PropCore.ValidAction(self, this, "manipulate") then return end
    tk_PropCore.PhysManipulate(this, pos, rot, freeze, gravity, notsolid)
end

e2function void entity:propFreeze(number freeze)
    if not tk_PropCore.ValidAction(self, this, "freeze") then return end
    tk_PropCore.PhysManipulate(this, pos, rot, freeze, gravity, notsolid)
end

e2function void entity:propNotSolid(number notsolid)
    if not tk_PropCore.ValidAction(self, this, "solid") then return end
    tk_PropCore.PhysManipulate(this, pos, rot, freeze, gravity, notsolid)
end

e2function void entity:propGravity(number gravity)
    if not tk_PropCore.ValidAction(self, this, "gravity") then return end
    tk_PropCore.PhysManipulate(this, pos, rot, freeze, gravity, notsolid)
end
--------------------------------------------------------------------------------

e2function void entity:setPos(vector pos)
    if not tk_PropCore.ValidAction(self, this, "pos") then return end
    tk_PropCore.PhysManipulate(this, pos, rot, freeze, gravity, notsolid)
end

e2function void entity:reposition(vector pos) = e2function void entity:setPos(vector pos)

e2function void entity:setAng(angle rot)
    if not tk_PropCore.ValidAction(self, this, "ang") then return end
    tk_PropCore.PhysManipulate(this, pos, rot, freeze, gravity, notsolid)
end

e2function void entity:rerotate(angle rot) = e2function void entity:setAng(angle rot)

--------------------------------------------------------------------------------

local function parent_check(child, parent)
    while IsValid(parent) do
        if (child == parent) then return false end
        parent = parent:GetParent()
    end

    return true
end

local function superparent(child, parent, enablephysics, massbalance, pushaway)
    if massbalance == 1 then
        local phys = parent:GetPhysicsObject()

        if IsValid(phys) then
            parent:GetPhysicsObject():SetMass(5000)
        end
    end

    if pushaway == 1 then
        if not parent:IsVehicle() then
            parent:SetCollisionGroup(COLLISION_GROUP_PUSHAWAY)
        end
    end

    if child:IsVehicle() then
        local phys = child:GetPhysicsObject()

        if IsValid(phys) then
            phys:SetMass(50)
            phys:SetPos(child:GetPos())
            phys:SetAngles(child:GetAngles())
        end

        constraint.Weld(parent, child, 0, 0, 0, false)
        child:SetCollisionGroup(COLLISION_GROUP_VEHICLE)
        child:PhysWake()
    else
        child:SetParent(parent)

        if enablephysics == 1 then
            local phys = child:GetPhysicsObject()

            if IsValid(phys) then
                if massbalance == 1 then
                    phys:SetMass(500)
                else
                    phys:SetMass(phys:GetMass())
                end

                phys:SetPos(child:GetPos())
                phys:SetAngles(child:GetAngles())
                constraint.Weld(parent, child, 0, 0, 0, false)
            end

            if pushaway == 1 then
                child:SetCollisionGroup(COLLISION_GROUP_PUSHAWAY)
            end

            child:PhysWake()
        else
            child:SetNotSolid(true)
        end
    end
end

e2function void entity:parentTo(entity target)
    if not tk_PropCore.ValidAction(self, this, "parent") then return end
    if not IsValid(target) then return nil end
    if (not isOwner(self, target)) then return end
    if this == target then return end
    if (not parent_check(this, target)) then return end
    superparent(this, target, 1, 1, 1)
end

e2function void entity:parentTo(entity target, number enablephysics, number massbalance, number pushaway)
    if not tk_PropCore.ValidAction(self, this, "parent") then return end
    if not IsValid(target) then return nil end
    if (not isOwner(self, target)) then return end
    if this == target then return end
    if (not parent_check(this, target)) then return end
    superparent(this, target, enablephysics, massbalance, pushaway)
end

e2function void entity:deparent()
    if not tk_PropCore.ValidAction(self, this, "deparent") then return end
    this:SetParent(nil)
    constraint.RemoveConstraints(this, "Weld")
end

e2function void propSpawnEffect(number on)
    self.data.propSpawnEffect = on ~= 0
end

registerCallback("construct", function(self)
    self.data.propSpawnEffect = true
end)
