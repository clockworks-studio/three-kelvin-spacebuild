TOOL.Category = "Connection"
TOOL.Name = "Network Link Tool"
TOOL.Command = nil
TOOL.ConfigName = nil
TOOL.Tab = "3K Spacebuild"
TOOL.Selected = {}
TOOL.OldColor = {}

if CLIENT then
    language.Add("tool.rd_link.name", "Network Link Tool")
    language.Add("tool.rd_link.desc", "Use to Link Life Support To A Node")
    language.Add("tool.rd_link.0", "Left Click: Select / Unselect Entity    Right Click: Link To Node    Reload: Unlink Entity")
else
    function TOOL:SelectEnt(ent)
        if not IsValid(ent) then return end
        local entid = ent:EntIndex()
        self.Selected[entid] = ent
        self.OldColor[entid] = ent:GetColor()
        ent:SetColor(Color(0, 0, 200, 200))
    end

    function TOOL:UnSelectEnt(ent)
        if not IsValid(ent) then return end
        local entid = ent:EntIndex()
        self.Selected[entid] = nil
        local col = self.OldColor[entid]
        ent:SetColor(col)
        self.OldColor[entid] = nil
    end

    function TOOL:IsEntSelected(ent)
        if not IsValid(ent) then return false end
        if not self.Selected[ent:EntIndex()] then return false end

        return true
    end

    function TOOL:CanSelect(ent)
        if not IsValid(ent) then return false end
        if not ent.IsTKRD or ent.IsNode then return false end

        return true
    end
end

function TOOL:LeftClick(trace)
    if not IsValid(trace.Entity) then return end
    if CLIENT then return true end
    local ply = self:GetOwner()
    local ent = trace.Entity

    if not self:CanSelect(ent) then
        ply:SendLua("GAMEMODE:AddNotify('Can Not Select Entity', NOTIFY_ERROR, 3)")

        return
    end

    if self:IsEntSelected(ent) then
        self:UnSelectEnt(ent)
    else
        self:SelectEnt(ent)
    end

    return true
end

function TOOL:RightClick(trace)
    if not IsValid(trace.Entity) then return end
    if CLIENT then return true end
    local ply = self:GetOwner()
    local ent = trace.Entity

    if not ent.IsTKRD or not ent.IsNode then
        ply:SendLua("GAMEMODE:AddNotify('Not A Valid Node', NOTIFY_ERROR, 3)")

        return
    end

    for k, v in pairs(self.Selected) do
        if not IsValid(v) then continue end
        self:UnSelectEnt(v)
        v:Link(ent.netid)
    end

    self.Selected = {}
    self.OldColor = {}

    return true
end

function TOOL:Reload(trace)
    if not IsValid(trace.Entity) then return end
    if CLIENT then return true end
    local ent = trace.Entity
    if not ent.IsTKRD then return end
    ent:Unlink()

    return true
end

function TOOL:Think()
end

function TOOL.BuildCPanel(CPanel)
    CPanel:AddControl("header", {
        description = "#tool.rd_link.desc"
    })
end
