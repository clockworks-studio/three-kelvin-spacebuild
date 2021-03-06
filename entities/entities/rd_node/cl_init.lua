include("shared.lua")

local function Add(array, data)
    array[array.idx] = data
    array.idx = array.idx + 1
end

function ENT:MakeText()
    local netdata = self:GetNetTable()
    local owner, uid = self:CPPIGetOwner()
    local name = "World"

    if IsValid(owner) then
        name = owner:Name()
    elseif uid then
        name = "Disconnected"
    end

    local OverlayText = {
        self.PrintName,
        "\nNetwork ",
        self:GetNetID(),
        "\nOwner: ",
        name,
        "\nRange: ",
        self:GetRange(),
        "\n",
        idx = 9
    }

    Add(OverlayText, "\nPower Grid: ")

    if netdata.powergrid > 0 then
        Add(OverlayText, "+")
        Add(OverlayText, netdata.powergrid)
        Add(OverlayText, "kW")
    else
        Add(OverlayText, netdata.powergrid)
        Add(OverlayText, "kW")
    end

    if table.Count(netdata.resources) > 0 then
        Add(OverlayText, "\n\n\nResources:\n\n")

        for k, v in pairs(netdata.resources) do
            Add(OverlayText, TK.RD:GetResourceName(k))
            Add(OverlayText, ": ")
            Add(OverlayText, v.cur)
            Add(OverlayText, "/")
            Add(OverlayText, v.max)
            Add(OverlayText, "\n")
        end
    end

    OverlayText.idx = nil

    return OverlayText
end

function ENT:DrawOverlay()
    if (self:GetPos() - LocalPlayer():GetPos()):LengthSqr() > 262144 then
        local size = self:OBBMaxs() - self:OBBMins()
        local width, height = 0.8 * size.x, 0.7 * size.y
        local pos = self:LocalToWorld(self:OBBCenter() + 0.5 * Vector(-width, height, size.z - 0.75))
        local scale = 10.0
        cam.Start3D2D(pos, self:GetAngles(), 1.0 / scale)
        surface.SetDrawColor(0, 0, 0, 255)
        surface.DrawRect(0, 0, width * scale, height * scale)
        cam.End3D2D()

        return
    end

    local ScreenText = string.Explode("\n", table.concat(self:MakeText()))
    local size = self:OBBMaxs() - self:OBBMins()
    local width, height = 0.8 * size.x, 0.7 * size.y
    local pos = self:LocalToWorld(self:OBBCenter() + 0.5 * Vector(-width, height, size.z - 0.75))
    local scale = 10.0
    local line
    cam.Start3D2D(pos, self:GetAngles(), 1.0 / scale)
    surface.SetDrawColor(0, 0, 0, 255)
    surface.DrawRect(0, 0, width * scale, height * scale)
    surface.SetTextColor(255, 255, 255, 255)
    surface.SetFont("Trebuchet24")
    local xOffset, yOffset = surface.GetTextSize("QWERTYUIOPASDFGHJKLZXCVBNMqwertyuiopasdfghjklzxcvbnm1234567890")

    for i = 1,  #ScreenText do
        line = ScreenText[i]
        surface.SetTextPos(15 + 0.5 * width * scale * ((i + 1) % 2), 15 + math.floor(0.5 * (i - 1)) * yOffset)
        surface.DrawText(line)
    end

    cam.End3D2D()
end

function ENT:DrawBubble()
    if (self:GetPos() - LocalPlayer():GetPos()):LengthSqr() > 262144 then return end
    if LocalPlayer():GetEyeTrace().Entity ~= self then return end
    AddWorldTip(nil, table.concat(self:MakeText(), ""), nil, self:LocalToWorld(self:OBBCenter()))
end

function ENT:Draw()
    self:DrawModel()

    if self:BoundingRadius() < 45 then
        self:DrawBubble()
    else
        self:DrawOverlay()
    end
end

function ENT:DoCommand(cmd, ...)
    RunConsoleCommand("TKRD_EntCmd", self:EntIndex(), cmd, unpack({...}))
end

function ENT:GetNetTable()
    return TK.RD:GetNetTable(self:GetNetID())
end

function ENT:GetResourceAmount(idx)
    return TK.RD:GetNetResourceAmount(self:GetNetID(), idx)
end

function ENT:GetUnitResourceAmount(idx)
    return 0
end

function ENT:GetResourceCapacity(idx)
    return TK.RD:GetNetResourceCapacity(self:GetNetID(), idx)
end

function ENT:GetUnitResourceCapacity(idx)
    return 0
end
