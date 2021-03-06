PLUGIN.Name = "ChatAdmin"
PLUGIN.Prefix = "@"
PLUGIN.Command = nil
PLUGIN.Level = 1

if SERVER then
    function PLUGIN.Call(ply, arg)
        local targets = {}

        for k, v in pairs(player.GetAll()) do
            if v:IsModerator() then
                table.insert(targets, v)
            end
        end

        if #targets == 0 then
            TK.AM:SystemMessage({"No Admins Found"}, {ply}, 2)
        else
            msgdata = {false,  Color(255, 140, 0),  "[Admin] ",  ply}
            table.insert(msgdata, ": " .. table.concat(arg, " "))
            TK.AM:SystemMessage(msgdata, targets)
        end
    end
end
