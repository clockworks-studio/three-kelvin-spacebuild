TK.RD = TK.RD or {}
local sync_data = {}
local ent_table = {}
local net_table = {}
local res_table = {}

net.Receive("TKRD_DNet", function()
    local netid = net.ReadInt(16)
    local netdata = net.ReadTable()
    net_table[netid] = netdata
    net_table[netid].powergrid = math.Round(net_table[netid].powergrid, 2)
end)

net.Receive("TKRD_KNet", function()
    local id = net.ReadInt(16)
    net_table[id] = nil
    sync_data["Net" .. id] = nil
end)

net.Receive("TKRD_DEnt", function()
    local entid = net.ReadInt(16)
    local entdata = net.ReadTable()
    ent_table[entid] = entdata
    ent_table[entid].powergrid = math.Round(ent_table[entid].powergrid, 2)
end)

net.Receive("TKRD_KEnt", function()
    local id = net.ReadInt(16)
    ent_table[id] = nil
    sync_data["Ent" .. id] = nil
end)

net.Receive("TKRD_MEnt", function()
    local ent = net.ReadEntity()
    if not IsValid(ent) then return end
    ent:DoMenu()
end)

local function RequestData(typ, id)
    local idx, time = typ .. id, CurTime()
    if sync_data[idx] and sync_data[idx] > time then return end
    sync_data[idx] = time + 1
    RunConsoleCommand("TKRD_RequestData", typ, id)
end

function TK.RD:AddResource(idx, name)
    idx = tostring(idx)
    name = tostring(name) or idx
    res_table[idx] = name
end

function TK.RD:GetNetTable(netid)
    local netdata = net_table[netid]
    RequestData("Net", netid)

    return netdata or {
        resources = {},
        powergrid = 0
    }
end

function TK.RD:GetEntTable(entid)
    local entdata = ent_table[entid]
    RequestData("Ent", entid)

    return entdata or {
        netid = 0,
        resources = {},
        data = {},
        powergrid = 0
    }
end

function TK.RD:IsLinked(ent)
    if not IsValid(ent) then return false end
    local entdata = ent_table[ent:EntIndex()]

    return entdata.netid > 0
end

function TK.RD:GetNetPowerGrid(netid)
    local netdata = TK.RD:GetNetTable(netid)
    if not netdata then return 0 end

    return netdata.powergrid or 0
end

function TK.RD:GetNetResourceAmount(netid, idx)
    local netdata = TK.RD:GetNetTable(netid)
    if not netdata then return 0 end
    if not netdata.resources[idx] then return 0 end

    return netdata.resources[idx].cur
end

function TK.RD:GetEntPowerGrid(ent)
    if not IsValid(ent) then return 0 end
    local entdata = TK.RD:GetEntTable(ent:EntIndex())

    if entdata.netid ~= 0 then
        local netdata = TK.RD:GetNetTable(entdata.netid)

        return netdata.powergrid or 0
    else
        return entdata.powergrid or 0
    end
end

function TK.RD:GetEntResourceAmount(ent, idx)
    if not IsValid(ent) then return 0 end
    local entdata = TK.RD:GetEntTable(ent:EntIndex())

    if entdata.netid ~= 0 then
        local netdata = TK.RD:GetNetTable(entdata.netid)
        if not netdata.resources[idx] then return 0 end

        return netdata.resources[idx].cur
    else
        if not entdata.resources[idx] then return 0 end

        return entdata.resources[idx].cur
    end
end

function TK.RD:GetUnitPowerGrid(ent)
    if not IsValid(ent) then return 0 end
    local entdata = TK.RD:GetEntTable(ent:EntIndex())

    return entdata.powergrid or 0
end

function TK.RD:GetUnitResourceAmount(ent, idx)
    if not IsValid(ent) then return 0 end
    local entdata = TK.RD:GetEntTable(ent:EntIndex())
    if not entdata.resources[idx] then return 0 end

    return entdata.resources[idx].cur
end

function TK.RD:GetNetResourceCapacity(netid, idx)
    local netdata = TK.RD:GetNetTable(netid)
    if not netdata then return 0 end
    if not netdata.resources[idx] then return 0 end

    return netdata.resources[idx].max
end

function TK.RD:GetEntResourceCapacity(ent, idx)
    if not IsValid(ent) then return 0 end
    local entdata = TK.RD:GetEntTable(ent:EntIndex())

    if entdata.netid ~= 0 then
        local netdata = TK.RD:GetNetTable(entdata.netid)
        if not netdata.resources[idx] then return 0 end

        return netdata.resources[idx].max
    else
        if not entdata.resources[idx] then return 0 end

        return entdata.resources[idx].max
    end
end

function TK.RD:GetUnitResourceCapacity(ent, idx)
    if not IsValid(ent) then return 0 end
    local entdata = TK.RD:GetEntTable(ent:EntIndex())
    if not entdata.resources[idx] then return 0 end

    return entdata.resources[idx].max
end

function TK.RD:GetResources()
    local resources = {}

    for k, v in pairs(res_table) do
        table.insert(resources, k)
    end

    return resources
end

function TK.RD:IsResource(str)
    return tobool(res_table[str])
end

function TK.RD:GetResourceName(idx)
    return res_table[idx] or idx
end
