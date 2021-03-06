TOOL.Category = "Constraints"
TOOL.Name = "#Parent"
TOOL.Command = nil
TOOL.ConfigName = ""
TOOL.Parent = nil
TOOL.Selected = {}
TOOL.OldColor = {}
TOOL.ClientConVar["physics"] = "1"
TOOL.ClientConVar["mass"] = "1"
TOOL.ClientConVar["pushaway"] = "1"

function TOOL:CanSelectEnt(trace)
    if not IsValid(trace.Entity) then return false end
    if trace.Entity:IsPlayer() then return false end
    if SERVER and not IsValid(trace.Entity:GetPhysicsObject()) then return false end

    return true
end

function TOOL:IsEntSelected(ent)
    if not IsValid(ent) then return false, false end
    local idx = ent:EntIndex()

    if self.Selected[idx] then
        if self.Parent == ent then
            return true, true
        else
            return true, false
        end
    end

    return false, false
end

function TOOL:SelectEnt(ent, ply)
    if not IsValid(ent) then return end
    local idx = ent:EntIndex()
    local col = ent:GetColor()
    ent:SetColor(IsValid(self.Parent) and Color(0, 200, 0, 100) or Color(200, 0, 0, 100))

    if not IsValid(self.Parent) then
        self.Parent = ent
        ply:SendLua("GAMEMODE:AddNotify('Parent Selected', NOTIFY_HINT, 3)")
    end

    self.Selected[idx] = ent
    self.OldColor[idx] = col
end

function TOOL:UnSelectEnt(ent)
    if not IsValid(ent) then return end
    local idx = ent:EntIndex()
    ent:SetColor(self.OldColor[idx])

    if self.Parent == ent then
        self.Parent = nil
    end

    self.Selected[idx] = nil
    self.OldColor[idx] = nil
end

function TOOL:LeftClick(trace)
    if CLIENT then return self:CanSelectEnt(trace) end
    if not self:CanSelectEnt(trace) then return false end
    local ply = self:GetOwner()
    local ent = trace.Entity
    local sel, par = self:IsEntSelected(ent)

    if par then
        ply:SendLua("GAMEMODE:AddNotify('Can Not Unselect Parent', NOTIFY_ERROR, 3)")
    elseif not sel then
        self:SelectEnt(ent, ply)
    else
        self:UnSelectEnt(ent)
    end
end

function TOOL:RightClick(trace)
    if CLIENT then return true end
    local ply = self:GetOwner()

    if not IsValid(self.Parent) or not IsValid(self.Parent:GetPhysicsObject()) then
        ply:SendLua("GAMEMODE:AddNotify('No Valid Parent Selected', NOTIFY_ERROR, 3)")

        for idx, ent in pairs(self.Selected) do
            self:UnSelectEnt(ent)
        end

        return
    end

    for idx, ent in pairs(self.Selected) do
        if not IsValid(ent) then continue end

        if ent == self.Parent then
            if self:GetClientNumber("mass", 1) == 1 then
                ent:GetPhysicsObject():SetMass(5000)
            end

            if self:GetClientNumber("pushaway", 1) == 1 then
                if not ent:IsVehicle() then
                    ent:SetCollisionGroup(COLLISION_GROUP_PUSHAWAY)
                end
            end

            continue
        end

        if self.Parent:GetParent() == ent then
            self:UnSelectEnt(ent)
            continue
        end

        if ent:IsVehicle() then
            local phys = ent:GetPhysicsObject()

            if IsValid(phys) then
                phys:SetMass(50)
                phys:SetPos(ent:GetPos())
                phys:SetAngles(ent:GetAngles())
            end

            local welds, welds_made = table.Copy(self.Selected), 0
            table.sort(welds, function(a, b) return a:BoundingRadius() > b:BoundingRadius() end)
            constraint.Weld(self.Parent, ent, 0, 0, 0, false)

            for _, acr in ipairs(welds) do
                if welds_made >= 3 then continue end
                if acr == self.Parent then continue end
                constraint.Weld(acr, ent, 0, 0, 0, false)
                welds_made = welds_made + 1
            end

            ent:SetCollisionGroup(COLLISION_GROUP_VEHICLE)
            ent:PhysWake()
            self:UnSelectEnt(ent)
            continue
        end

        ent:SetParent(self.Parent)

        if self:GetClientNumber("physics", 1) == 1 then
            local phys = ent:GetPhysicsObject()

            if IsValid(phys) then
                if self:GetClientNumber("mass", 1) == 1 then
                    phys:SetMass(500)
                else
                    phys:SetMass(phys:GetMass())
                end

                phys:SetPos(ent:GetPos())
                phys:SetAngles(ent:GetAngles())
                constraint.Weld(self.Parent, ent, 0, 0, 0, false)
            end

            if self:GetClientNumber("pushaway", 1) == 1 then
                ent:SetCollisionGroup(COLLISION_GROUP_PUSHAWAY)
            end

            ent:PhysWake()
        else
            ent:SetNotSolid(true)
        end

        self:UnSelectEnt(ent)
    end

    self:UnSelectEnt(self.Parent)
    self.Selected = {}
    self.OldColor = {}
    ply:SendLua("GAMEMODE:AddNotify('Parenting Completed', NOTIFY_HINT, 3)")
end

function TOOL:Reload(trace)
    if CLIENT then return end

    for idx, ent in pairs(self.Selected) do
        self:UnSelectEnt(ent)
    end

    self.Selected = {}
    self.OldColor = {}
end

function TOOL:Think()
end

if SERVER then return end
language.Add("tool.tk_parent.name", "Parent Tool")
language.Add("tool.tk_parent.desc", "Parent Entities To A Central Prop")
language.Add("tool.tk_parent.0", "Primary: Select Entity   Secondary: Parent   Reload: Clear Selection")

function TOOL.BuildCPanel(CPanel)
    CPanel:AddControl("header", {
        description = "#tool.tk_parent.desc"
    })

    CPanel:AddControl("checkbox", {
        label = "Enable Physics",
        command = "tk_parent_physics"
    })

    CPanel:AddControl("checkbox", {
        label = "Mass Balance",
        command = "tk_parent_mass"
    })

    CPanel:AddControl("checkbox", {
        label = "Push Away Collision Mode",
        command = "tk_parent_pushaway"
    })
end
