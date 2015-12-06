local assert, error, loadstring, char, find, format, sub, gsub = assert, error, loadstring, string.char, string.find, string.format,string.sub,string.gsub
local getfenv, loadstring, setfenv = getfenv, loadstring, setfenv
local open = io.open
local print = print
local pairs = pairs
local table = table
local web = require("web")
local utils = require("utils")
local sys = require("sys")
local dm = require("dm")
local tostring = tostring
module (...)

-- support utf-8
local BOM = char(239) .. char(187) .. char(191)

local yield_file= nil
local yield_content = nil
local script_res = {}
local labelMaps  = {}

function render(filename, env)
    local src = web.getfile(filename)

    if src:sub(1,3) == BOM then src = src:sub(4) end
  
    local prog, err = loadstring(src, filename)
    local _env
    if env then
        _env = getfenv (prog)
        setfenv (prog, env)
    end
    if not prog then error (err, 3) end
    
    prog() 
end

function setyieldfile(file)
    yield_file = file
    yield_content = nil
end

function setYieldContent(content)
    yield_content = content
    yield_file = nil
end    

function yield (p)
    local src = ''
    if yield_file ~= nil then
        src = web.getfile(yield_file)
    else
        src = yield_content
    end
    if src:sub(1,3) == BOM then src = src:sub(4) end

    if not p then
        -- find last 'content_end'
        local last = 0
        local i = 0
        local j
        while true do
            i, j = find(src, "--lua_content_end__", i+1)    
            if i == nil then break end
            last = j
        end
        if last ~= 0 then
            src = sub(src, last+1)
        end
    else
        local s,e = find(src, format("--lua_content_for__ %s begin", p))
        if not s then return end 
        local s1, e1 = find(src, format("--lua_content_end__"), e + 1)

        if not s and not s1 then error(err, 4) end
        src = sub(src, e+1, s1-1)
    end
    
    local prog, err = loadstring(src, yield_file)    
    if not prog then error (err, 3) end
    prog()    

end

function resource(res)
	local id = web.getresourceid()
	sys.print(res.."?"..id)
end

function rawscript(res)
	local id = web.getresourceid()
	sys.print('<script type="text/javascript" language="javascript" src="'..res..'?'..id..'"></script>')
end

function gzrawscript(res)
	local id = web.getresourceid()
	sys.print('<script type="text/javascript" language="javascript" src="'..res..'.jgz?'..id..'"></script>')
end

function script(res)
    local id = web.getresourceid()
    local index = find(id, 'atp_virtual_web')
    if nil ~= index then
        sys.print('<script type="text/javascript" language="javascript" src="'..res..'?'..id..'"></script>')
    else
        table.insert(script_res, res)
    end
end

function scriptall()
    local id = web.getresourceid()
    local index = find(id, 'atp_virtual_web')
    if nil ~= index then
        return 
    end

    local allres = "/atpscriptall_"
    for k, v in pairs(script_res) do
        allres = allres..v
    end
    sys.print('<script type="text/javascript" language="javascript" src="'..allres..'?'..id..'"></script>')
    script_res = {}
end

function link(res)
    local id = web.getresourceid()
    local language = web.lang()
    local last = utils.rfind(res, "/")

    local prefix = sub(res, 1, last)
    local filename = sub(res, last + 1)

    if language == "ar" then
        sys.print('<link type="text/css" href="'..prefix..'ar_'..filename..'.cgz?'..id..'" rel="stylesheet">')
    else
        sys.print('<link type="text/css" href="'..prefix..filename..'.cgz?'..id..'" rel="stylesheet">')
    end
end

function csrf_meta_tag()
    local param,token = web.getcsrf()
    local n,e      = web.getrsakey()
    sys.print("<meta name=\"csrf_param\" content=\""..param.."\"/>\r\n")
    sys.print("<meta name=\"csrf_token\" content=\""..token.."\"/>\r\n")
    sys.print("<meta name=\"n\" content=\""..n.."\"/>\r\n")
    sys.print("<meta name=\"e\" content=\""..e.."\"/>")
    labelMaps  = {}
end

function lang(res)
    local lan = '/lang/'..web.lang()..'/'..res
    script(lan)
end

function rawlang(res)
    local lan = '/lang/'..web.lang()..'/'..res
    rawscript(lan)
end

function has_authorization(level)
    local name, user_level = web.getuserinfo()
    if name == nil then
        return false
    end

    if level > user_level then
        return false
    end

    return true
end

function auth(level)
    return has_authorization(level)
end

function label(id, index)
    local safeId = gsub(id, "%.", "_")
    if index then
        safeId = safeId .. index
    end

    local nv = {}
    nv.id = id
    nv.safeId = safeId

    sys.print('<span id="'..safeId..'"></span>')
    table.insert(labelMaps, nv)
end

function setImage(src)
    local imgstring = ""
    if src then
        imgstring=' src="../res/'..src..'.png"'
    end
    sys.print(imgstring)
end

function setlabel()
    local safeId = ""
    for k, nv in pairs(labelMaps) do
        sys.print('$("#'..nv.safeId..'").html(Em.I18n.get("'..nv.id..'"));\r\n')
    end
end

function create_menuitem(id, page, isshow)
    local item = {}
    item["ID"] = id
    item["Page"] = page
    item["show"] = isshow
    return item
end
function create_menu(id, page)
    local menu = {}
    menu["ID"] = id
    menu["Page"] = page
    menu["Children"] = {}
    return menu
end

function append_children(parentMenu, item)
    table.insert(parentMenu["Children"], item)
end

--route menu
local Menus = {}
--about gete
local aboutgate = create_menu("aboutgate", "/html/advance.html")
append_children(aboutgate, create_menuitem("deviceinfo", "/html/deviceinfo_view.js", true))
table.insert(Menus, aboutgate)
--upgrade
local aboutupgrade = create_menu("upgrade", "/html/advance.html")
append_children(aboutupgrade, create_menuitem("upgrade", "/html/upgrade_view.js", true))
table.insert(Menus, aboutupgrade)
--network
local networkset = create_menu("networkset", "/html/advance.html")
append_children(networkset, create_menuitem("smartqos", "/html/smartqos_view.js", true))
append_children(networkset, create_menuitem("lan", "/html/lan_view.js", true))
append_children(networkset, create_menuitem("staticroute", "/html/route_view.js", true))
append_children(networkset, create_menuitem("vpn", "/html/vpn_view.js", true))
append_children(networkset, create_menuitem("upnp", "/html/upnp_view.js", true))
append_children(networkset, create_menuitem("wlanintelligent", "/html/wlanintelligent_view.js", true))
table.insert(Menus, networkset)
--wifi advance
local wifiadvanceset = create_menu("wifiadvanceset", "/html/advance.html")
append_children(wifiadvanceset, create_menuitem("wlanadvance", "/html/wlanadvance_view.js", true))
append_children(wifiadvanceset, create_menuitem("wlanaccess", "/html/wlanaccess_view.js", true))
append_children(wifiadvanceset, create_menuitem("wlanguest", "/html/guestnetwork_view.js", true))
append_children(wifiadvanceset, create_menuitem("repeater", "/html/repeater_view.js", true))
table.insert(Menus, wifiadvanceset)

--remote
local remoteset = create_menu("remoteset", "/html/advance.html")
append_children(remoteset, create_menuitem("ddns", "/html/ddns_view.js", true))
table.insert(Menus, remoteset)

--file share
local share = create_menu("share", "/html/advance.html")
append_children(share, create_menuitem("samba", "/html/samba_view.js", true))
append_children(share, create_menuitem("dlna", "/html/dlna_view.js", true))
table.insert(Menus, share)

--storage
--safe
local safe = create_menu("safe", "/html/advance.html")
append_children(safe, create_menuitem("firewall", "/html/firewall_view.js", true))
append_children(safe, create_menuitem("nat", "/html/nat_view.js", true))
append_children(safe, create_menuitem("dmz", "/html/dmz_view.js", true))
append_children(safe, create_menuitem("parentcontrol", "/html/parentcontrol_view.js", true))

table.insert(Menus, safe)
--system
local system = create_menu("system", "/html/advance.html")
append_children(system, create_menuitem("account", "/html/account_view.js", true))
append_children(system, create_menuitem("sntp", "/html/sntp_view.js", true))
append_children(system, create_menuitem("reset", "/html/device_mngt_view.js", true))
append_children(system, create_menuitem("diagnose", "/html/diagnose_view.js", true))
append_children(system, create_menuitem("mirror", "/html/mirror_view.js", true))
table.insert(Menus, system)

--application
local application = create_menu("application", "/html/advance.html")
append_children(application, create_menuitem("shopassist", "/html/shopassist_view.js", true))
append_children(application, create_menuitem("thunder", "/html/thunder_view.js", true))
table.insert(Menus, application)


--repeater mode
local RepeaterMenus = {}
--about gete
local aboutgate = create_menu("aboutgate", "/html/advance.html")
append_children(aboutgate, create_menuitem("deviceinfo", "/html/deviceinfo_view.js", true))
table.insert(RepeaterMenus, aboutgate)

--upgrade
local aboutupgrade = create_menu("upgrade", "/html/advance.html")
append_children(aboutupgrade, create_menuitem("upgrade", "/html/upgrade_view.js", true))
table.insert(RepeaterMenus, aboutupgrade)

--wifi advance
local wifiadvanceset = create_menu("wifiadvanceset", "/html/advance.html")
append_children(wifiadvanceset, create_menuitem("repeater", "/html/repeater_view.js", true))
table.insert(RepeaterMenus, wifiadvanceset)

--storage

--system
local system = create_menu("system", "/html/advance.html")
append_children(system, create_menuitem("account", "/html/account_view.js", true))
append_children(system, create_menuitem("reset", "/html/device_mngt_view.js", true))

append_children(system, create_menuitem("mirror", "/html/mirror_view.js", true))
table.insert(RepeaterMenus, system)

--application
local application = create_menu("application", "/html/advance.html")
append_children(application, create_menuitem("thunder", "/html/thunder_view.js", true))
table.insert(RepeaterMenus, application)

local RepeaterEnable = false
function getRepeaterMode()
        local errcode, objs = dm.GetParameterValues("InternetGatewayDevice.X_WiFi.Radio.1.",{"WLANMode"})
        local wlanmode = ""
        RepeaterEnable = false
        local obj = objs["InternetGatewayDevice.X_WiFi.Radio.1."]
        if objs ~= nil then 
            if(2 == obj["WLANMode"] or 3 == obj["WLANMode"]) then
                RepeaterEnable = true
                wlanmode = "repleater"
            end    
        end
    sys.print(wlanmode)
end
function gen_all_sub_menus(children)
    local retStr = "["
    local idx = 0
    local len = table.getn(children)
    for k,v in pairs(children) do
        retStr = retStr..'{"ID":"'..v["ID"]..'", "Page":"'..v["Page"]..'", "show":'..tostring(v["show"])..'}'
        idx = idx + 1
        if idx ~= len then
            retStr = retStr..","
        end
    end
    return retStr.."]"
end

function gen_all_menus()
    local retStr = "var g_Menus = ["
    local repeaterStr = "var g_Menus = ["
    local idx = 0
    local len = table.getn(Menus)
    local rlen = table.getn(RepeaterMenus)
    for k,v in pairs(Menus) do
        retStr = retStr..'{"ID":"'..v["ID"]..'", "Page":"'..v["Page"]..'", "Children":'..gen_all_sub_menus(v["Children"])..'}'
        idx = idx + 1
        if idx ~= len then
            retStr = retStr..","
        end
    end
    idx = 0
    for k,v in pairs(RepeaterMenus) do
        repeaterStr = repeaterStr..'{"ID":"'..v["ID"]..'", "Page":"'..v["Page"]..'", "Children":'..gen_all_sub_menus(v["Children"])..'}'
        idx = idx + 1
        if idx ~= rlen then
            repeaterStr = repeaterStr..","
        end
    end
    if RepeaterEnable then
         repeaterStr = repeaterStr.."];"
         sys.print(repeaterStr)
    else
        retStr = retStr.."];"
        sys.print(retStr)
    end
end