
local PLUGIN = {}
PLUGIN.Name       = "Addons"
PLUGIN.Prefix     = "!"
PLUGIN.Command    = "Addons"
PLUGIN.Auto       = {}
PLUGIN.Level      = 1

if SERVER then
	function PLUGIN.Call(ply,arg)
		ply:ConCommand("3k_addon_check")
	end
else

end

TK.AM:RegisterPlugin(PLUGIN)