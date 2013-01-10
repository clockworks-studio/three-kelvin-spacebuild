
local PANEL = {}

local function MakePanel(item)
    local btn = vgui.Create("DButton")
    btn.item = item
	btn:SetSkin("Terminal")
	btn:SetSize(0, 65)
    btn.Paint = function(btn, w, h)
        derma.SkinHook("Paint", "TKLOButton", btn, w, h)
        return true
    end
    
    return btn
end

local function MakeSlot(panel, slot, id)
    local btn = vgui.Create("DButton", panel)
    btn:SetSkin("Terminal")
    btn.loadout = {}
    btn.slot = slot
    btn.id = id
    btn.item = 0
    
    btn.Entity = nil
    btn.vLookatPos = Vector()
    btn.vCamPos = Vector()
    btn.SetModel = function(btn, strModelName)
        if IsValid(btn.Entity) then
            btn.Entity:Remove()
            btn.Entity = nil		
        end

        if !ClientsideModel then return end
        
        btn.Entity = ClientsideModel(strModelName, RENDER_GROUP_OPAQUE_ENTITY)
        if !IsValid(btn.Entity) then return end
        
        btn.Entity:SetNoDraw(true)
    end
    
    btn.Think = function()
        local itemid = btn.loadout["slot_".. btn.id]
        if !itemid || itemid == btn.item then return end
        btn.item = itemid
        local item = TK.IL:GetItem(itemid)
        
        btn:SetModel(item.mdl)
        btn.vCamPos = Vector(item.r, item.r, item.r)
        btn.vLookatPos = Vector(0 ,0 , item.r / 2)
    end
    btn.Paint = function(btn, w, h)
        derma.SkinHook("Paint", "TKLOButton", btn, w, h)
        return true
    end
    btn.DoClick = function()
        print(btn.loadout["slot_".. btn.id .."_locked"])
        if tobool(btn.loadout["slot_".. btn.id .."_locked"]) then return end
        surface.PlaySound("ui/buttonclickrelease.wav")
        panel.items:Clear(true)
        
        local validitems = {}
        for k,v in pairs(TK.DB:GetPlayerData("player_inventory").inventory) do
            if !TK.IL:IsSlot(btn.slot, v) then continue end
            table.insert(validitems, v)
        end
        
        for k,v in pairs(panel[btn.slot]) do
            if v.item == 0 then continue end
            for _,itm in pairs(validitems) do
                if v.item == item then
                    validitems[_] = nil
                    break
                end
            end
        end
        
        for k,v in pairs(validitems) do
            panel.items:AddItem(MakePanel(TK.IL:GetItem(v)))
        end
    end
    
    return btn
end

function PANEL:Init()
	self:SetSkin("Terminal")
	self.NextThink = 0
    self.loadout = {}
    
    self.items = vgui.Create("DPanelList", self)
    
    self.mining = {}
    self.mining[1] = MakeSlot(self, "mining", "m1")
    self.mining[2] = MakeSlot(self, "mining", "m2")
    self.mining[3] = MakeSlot(self, "mining", "m3")
    self.mining[4] = MakeSlot(self, "mining", "m4")
    self.mining[5] = MakeSlot(self, "mining", "m5")
    self.mining[6] = MakeSlot(self, "mining", "m6")
    
    self.storage = {}
    self.storage[1] = MakeSlot(self, "storage", "s1")
    self.storage[2] = MakeSlot(self, "storage", "s2")
    self.storage[3] = MakeSlot(self, "storage", "s3")
    self.storage[4] = MakeSlot(self, "storage", "s4")
    self.storage[5] = MakeSlot(self, "storage", "s5")
    self.storage[6] = MakeSlot(self, "storage", "s6")
    
    self.weapon = {}
    self.weapon[1] = MakeSlot(self, "weapon", "w1")
    self.weapon[2] = MakeSlot(self, "weapon", "w2")
    self.weapon[3] = MakeSlot(self, "weapon", "w3")
    self.weapon[4] = MakeSlot(self, "weapon", "w4")
    self.weapon[5] = MakeSlot(self, "weapon", "w5")
    self.weapon[6] = MakeSlot(self, "weapon", "w6")
end

function PANEL:PerformLayout()
    for k,v in pairs(self.mining) do
        v:SetPos(10 + ((k - 1) * 80), 160)
        v:SetSize(75, 75)
    end
    
    for k,v in pairs(self.storage) do
        v:SetPos(10 + ((k - 1) * 80), 300)
        v:SetSize(75, 75)
    end
    
    for k,v in pairs(self.weapon) do
        v:SetPos(10 + ((k - 1) * 80), 440)
        v:SetSize(75, 75)
    end
    
    self.items:SetPos(505, 125)
    self.items:SetSize(260, 395)
end

function PANEL:Think()
	if CurTime() < self.NextThink then return end
	self.NextThink = CurTime() + 1
	
	self.score = TK:Format(TK.DB:GetPlayerData("player_info").score)
    self.loadout = TK.DB:GetPlayerData("player_loadout")
    
    for k,v in pairs(self.mining) do
        v.loadout = self.loadout
    end
    
    for k,v in pairs(self.storage) do
        v.loadout = self.loadout
    end
    
    for k,v in pairs(self.weapon) do
        v.loadout = self.loadout
    end
end

function PANEL.Paint(self, w, h)
	derma.SkinHook("Paint", "TKLoadout", self, w, h)
	return true
end

vgui.Register("tk_loadout", PANEL)