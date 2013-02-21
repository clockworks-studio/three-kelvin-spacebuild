
TOOL = nil

for k,v in pairs(file.Find("rd_tools/*.lua", "LUA")) do
    local class = string.match(v, "[%w_]+")
    TOOL             = ToolObj:Create()
    TOOL.Name         = class
    TOOL.Mode       = class
    TOOL.Category    = "Other"
    TOOL.Limit         = 6
    TOOL.Data     = {}
    
    TOOL.ClientConVar["weld"] = 0
    TOOL.ClientConVar["weldingtoworld"] = 0
    TOOL.ClientConVar["makefrozen"] = 1
    TOOL.ClientConVar["model"] = ""
    
    function TOOL:SelectModel()
        local str = self:GetClientInfo("model")
        if !TK.RD.EntityData[self.Mode][str] then
            return table.GetFirstKey(TK.RD.EntityData[self.Mode])
        end
        return str
    end

    function TOOL:LeftClick(trace)
        if !trace.Hit then return end
        if CLIENT then return true end
        
        local ply = self:GetOwner()
        if !ply:CheckLimit(self.Mode) then return false end
        local ent = ents.Create(self.Mode)
        ent:SetModel(self:SelectModel())
        ent:SetPos(trace.HitPos)
        local angles = trace.HitNormal:Angle() + Angle(90,0,0)
        ent:SetAngles(angles)
        ent:Spawn()
        ent:SetPos(trace.HitPos + trace.HitNormal * ((ent:OBBMaxs().z - ent:OBBMins().z) / 2 - ent:OBBCenter().z))
        
        if self:GetClientNumber("weld", 0) == 1 then
            local hit = trace.Entity
            if hit then
                if hit:IsWorld() then
                    if self:GetClientNumber("weldingtoworld", 0) == 1 then
                        constraint.Weld(ent, hit, 0, 0, 0, true)
                    end
                else
                    constraint.Weld(ent, hit, 0, 0, 0, true)
                end
            end
        end
        
        
        local phys = ent:GetPhysicsObject()
        if phys:IsValid() then
            if angles != nil  then phys:SetAngles(angles) end
            phys:Wake()
            if self:GetClientNumber("makefrozen", 1) == 1 then
                phys:EnableMotion(false)
            end
        end
        
        ply:AddCount(self.Mode, ent)
        
        undo.Create(self.Mode)
            undo.AddEntity(ent)
            undo.SetPlayer(ply)
        undo.Finish()

        ply:AddCleanup(self.Mode, ent)
        return true
    end
    
    function TOOL:RightClick(trace)
    
    end
    
    function TOOL:Reload(trace)

    end

    function TOOL:Think()
        if !IsValid(self.GhostEntity) || self.GhostEntity:GetModel() != self:SelectModel() then
            self:MakeGhostEntity(self:SelectModel(), Vector(0,0,0), Angle(0,0,0))
        else
            local trace = self:GetOwner():GetEyeTrace()
            if !trace.Hit then return end
            self.GhostEntity:SetAngles(trace.HitNormal:Angle() + Angle(90,0,0))
            self.GhostEntity:SetPos(trace.HitPos + trace.HitNormal * ((self.GhostEntity:OBBMaxs().z - self.GhostEntity:OBBMins().z) / 2 - self.GhostEntity:OBBCenter().z))
        end    
    end

    if CLIENT then
        function TOOL.BuildCPanel(CPanel)
            local Weld = vgui.Create("DCheckBoxLabel")
            Weld:SetText("Weld")
            Weld:SetConVar(class.."_weld")
            Weld:SetValue(0)
            Weld:SizeToContents()
            CPanel:AddItem(Weld)
            
            local AllowWeldingToWorld = vgui.Create("DCheckBoxLabel")
            AllowWeldingToWorld:SetText("Weld To World")
            AllowWeldingToWorld:SetConVar(class.."_weldingtoworld")
            AllowWeldingToWorld:SetValue(0)
            AllowWeldingToWorld:SizeToContents()
            CPanel:AddItem(AllowWeldingToWorld)
            
            local MakeFrozen = vgui.Create("DCheckBoxLabel")
            MakeFrozen:SetText("Make Frozen")
            MakeFrozen:SetConVar(class.."_makefrozen")
            MakeFrozen:SetValue(1)
            MakeFrozen:SizeToContents()
            CPanel:AddItem(MakeFrozen)
            
            local List = vgui.Create("DPanelSelect")
            List:SetSize(0, 200)
            List:EnableVerticalScrollbar(true)
            CPanel:AddItem(List)
            
            for k,v in pairs(TK.RD.EntityData[class]) do
                local icon = vgui.Create("SpawnIcon")
                icon.DoRightClick = function()
                    RunConsoleCommand( "playgamesound", "ui/buttonclickrelease.wav" )
                    SetClipboardText(k)
                    GAMEMODE:AddNotify("Model path copied to clipboard.", NOTIFY_HINT, 5)
                end
                icon.idx = k
                icon:SetModel(k)
                icon:SetSize(64, 64)
                List:AddPanel(icon, {[class.."_model"] = k, playgamesound = "ui/buttonclickrelease.wav"})
            end
            List:SortByMember("idx")
        end
    end
    
    AddCSLuaFile("rd_tools/"..v)
    include("rd_tools/"..v)
    
    if SERVER then 
        TK.RD.EntityData[class] = {}
        for k,v in pairs(TOOL.Data) do
            if util.IsValidModel(k) then
                util.PrecacheModel(k)
                TK.RD.EntityData[class][k] = v
            end
        end
        
        CreateConVar("sbox_max"..class, TOOL.Limit)
    else
        TK.RD.EntityData[class] = {}
        for k,v in pairs(TOOL.Data) do
            TK.RD.EntityData[class][k] = true
        end
        
        language.Add("tool."..class..".name", TOOL.Name)
        language.Add("tool."..class..".desc", "Use to Spawn a "..TOOL.Name)
        language.Add("tool."..class..".0", "Left Click: Spawn a "..TOOL.Name)
        language.Add("sboxlimit_"..class, "You Have Hit the "..TOOL.Name.." Limit!")
    end
    
    cleanup.Register(TOOL.Name)

    TOOL.Command        = nil
    TOOL.ConfigName        = nil
    TOOL.Tab             = "3K Spacebuild"
    TOOL.Data            = nil
    
    TOOL:CreateConVars()
    SWEP.Tool[class] = TOOL
    TOOL = nil
end

TOOL                = ToolObj:Create()
TOOL.Category        = "3K Spacebuild"
TOOL.Mode            = "tk_tools"
TOOL.Name             = "3K Tools"
TOOL.Command        = nil
TOOL.ConfigName        = nil
TOOL.AddToMenu         = false