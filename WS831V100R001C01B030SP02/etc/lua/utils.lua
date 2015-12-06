local json = require('json')
local dm   = require('dm')
local sys  = require('sys')
local string  = string
local table = table
local os = os
local io = io
local _G = _G
local print = print
local pairs = pairs
local tostring = tostring
local tonumber = tonumber
local strlen, find, strsub, sort, insert, GetParameterValues = string.len, string.find, string.sub, table.sort, table.insert, dm.GetParameterValues
module (...)
_G["defaultPasswd"] = "********"
_G["wlantimes"] = 0
_G["webtimes"] = 0

function toboolean(val)
    if not val then
        return false
    end
    if "0" == val or 0 == val or "false" == val or false == val then
        return false
    end
    return true
end

function booleantoint(var)
    if false == var then
        return 0
    else
        return 1
    end
end

function opsiteBoolVal(val)
    if 0 == val or "false" == val or false == val then
        return true
    end
    return false
end

function compID(a, b)
    local a_id_table = {}
    local b_id_table = {}
    for i in string.gmatch(a.ID, "%d+") do
        table.insert(a_id_table, tonumber(i))
    end
    for i in string.gmatch(b.ID, "%d+") do
        table.insert(b_id_table, tonumber(i))
    end

    local size = 0
    if table.getn(a_id_table) > table.getn(b_id_table) then
        size = table.getn(b_id_table)
    else
        size = table.getn(a_id_table)
    end

    if size < 1 then
        return false
    end

    for i=1,size do
        if a_id_table[i] > b_id_table[i] then
            return false
        elseif a_id_table[i] < b_id_table[i] then
            return true
        end
    end

    return false
end

function multiObjSortByID(objs)
    sort(objs, compID)
end

function appenderror(id, code)
    _G["errcode"][id] =code
end

function responserror()
    local jsonstr = json.encode(_G["errcode"])
    sys.print(jsonstr)
end

function getRequest()
    --max data len:5k
    if string.len(_G["FormData"]["JSONDATA"]) > (1024 * 5) then
        return "error"
    end
    local request = json.decode(_G["FormData"]["JSONDATA"])
    return request
end
function getRequestFormAction()
    return _G["request"]["action"]
end

function getRequestFormData()
    return _G["request"]["data"]
end

function rfind(str, sub)
    local start = 1 
    local p = nil
    local lastIndex = nil

    while true do
        p, fp = string.find(str, sub, start)
        if not p then
            break
        end
        lastIndex = p
        start = fp + 1
    end

    return lastIndex
end

function findLastPoint(domain)
    local start = 1
    local pos = nil
    local predomain = nil
    local lastdomain = nil

    while true do
        ip,fp = find(domain, "%.", start)
        if not ip then break end
        predomain = strsub(domain, start, ip-1)
        pos = ip
        start = fp + 1
    end
    
    if pos ~= nil then
        lastdomain = strsub(domain, pos + 1)
    end

    return predomain, lastdomain, pos
end

function strip_end_dot(path)
    local len = strlen(path)
    if 0 == len then
        return path
    end

    local endStr = strsub(path, len)
    if "." == endStr then
        return strsub(path, 0, len-1)
    end
    return path
end

function print_paras(parameters)
    if not parameters then
        return
    end
    for k,v in pairs(parameters) do
        print("=============================")
        if v then
            for idx,val in pairs(v) do
                print(val)
            end
        end
    end
end
function appendMultiObjects(obj, appendobj, maps)
    if appendobj == nil or appendobj == nil then
        return obj
    end

    for k, v in pairs(appendobj) do
        local newObj = {}
        newObj["ID"] = k
        for kr, vd in pairs(maps) do
            newObj[kr] = v[vd]
        end 
        insert(obj, newObj)
    end

end

function genMultiObjects(objs, maps)
    local multiObjs = {}

    appendMultiObjects(multiObjs, objs, maps)

    return multiObjs
end

function responseMultiObjects(objs, maps)
    local mulObjs = genMultiObjects(objs, maps)
    multiObjSortByID(mulObjs)
    sys.print(json.encode(mulObjs))
end


function genSingleObject(obj, maps)
    local singleObj = {}
    for kr, vd in pairs(maps) do
        singleObj[kr] = obj[vd]
    end
    return singleObj
end

function appendSingleObj(obj, appendobj, maps)
    for k, v in pairs(maps) do
        obj[k] = appendobj[v]
    end
end

function responseSingleObject(obj, maps)
    return sys.print(json.encode(genSingleObject(obj, maps)))
end

function responseErrorcode(err, paramErr, maps)
    appenderror("errcode", err)

    if paramErr == nil then
        return false
    end

    for k, v in pairs(paramErr) do
        for restf, dmp in pairs(maps) do
            if string.ends(k, "."..dmp) then
                appenderror(restf, v)
                return true
            end
        end
    end
    return false
end

function GenSetObjParamInputs(domain, data, maps)
    local inputs = {}
    for k, v in pairs(maps) do
        local param = {}
        param["key"] = domain..v
        param["value"] = data[k]
        insert(inputs, param)
    end

    return inputs
end

function GenSetObjParamInputsEx(domain, data, maps, para_table)
    for k, v in pairs(maps) do
        local param = {}
        param["key"] = domain..v
        param["value"] = data[k]
        insert(para_table, param)
    end

    return para_table
end

function GenAddObjParamInputs(data, maps)
    local inputs = {}
    for k, v in pairs(maps) do
        local param = {}
        param["key"] = v
        param["value"] = data[k]
        insert(inputs, param)
    end

    return inputs
end

function getEthPortStatus(port)
    local autonegotiation = false
    local duplexmode = nil -- Half, Full, Auto
    local rate  = nil -- 10, 100, 1000, Auto
    local file = "/var/luaweb_diagnose_lan"
    local cmd = "ethcmd eth0 media-type port "..port.." >"..file.." 2>&1"
    sys.exec(cmd)

    local line = ''
    local fh = io.open(file, "r")
    if not fh then
        return false, "Auto", "Auto"
    end
    
    line = fh.read(fh)
    ip = find(line, "enabled")
    if ip ~= nil then
        autonegotiation = true
    else
        autonegotiation = false
    end

    line = fh.read(fh)
    if nil == line then
        os.remove(file)
        return autonegotiation, duplexmode, rate
    end
    if autonegotiation then
        ip = find(line, "FD")
        if ip ~= nil then
            duplexmode = "Full"
        else
            duplexmode = "Half"
        end
    else
        ip = find(line, "full")
        if ip ~= nil then
            duplexmode = "Full"
        else
            duplexmode = "Half"
        end
    end

    ip = find(line, "1000")
    if ip ~= nil then
        rate = "1000"
    else
        ip = find(line, "100")
        if ip ~= nil then
            rate = "100"
        else
            rate = "10"
        end
    end

    os.remove(file)
    return autonegotiation, duplexmode, rate
end

function split(str, sep)
    local start = 1
    local retval = {}

    if nil == str then
        return retval
    end

    while true do
        ip,fp = find(str, sep, start)
        if not ip then 
            if start < strlen(str) then
                insert(retval, strsub(str, start))
            end
            break 
        end

        if start < ip -1 then
            insert(retval, strsub(str, start, ip-1))
        end
        start = fp + 1
    end

    return retval
end

function string.ends(String,End)
   return End=='' or strsub(String,-strlen(End))==End
end

function delete_all_entries(name)
    local err, items = dm.GetParameterNames(name, true)
    if 0 ~= err then
        return
    end

    for k,v in pairs(items) do
        if string.ends(k, ".") then
            dm.DeleteObject(k)
        end
    end
end

function luadbg(str)
    print(str)
end

function validate_ipv4_addr(ip)
    local temp1,temp2,temp3,temp4
    if nil == ip then
        return false
    end
    if "" == ip then
        return false
    end

    if "0.0.0.0" == ip or "255.255.255.255" == ip then
        return false
    end
    temp1,temp2,temp3,temp4 = ip:match("(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)")
    if nil == temp1 or nil == temp2 or nil == temp3 or nil == temp4 then
        return false
    end

    if tonumber(temp1) == 0 then 
        return false
    end

    if tonumber(temp1) == 127 then 
        return false
    end

    if tonumber(temp1) > 224 then 
        return false
    end

    if tonumber(temp4) == 0 then
        return false
    end

    if tonumber(temp4) == 255 then
        return false
    end

    return true
end

function validate_dnsservers_addr(servers, setFlag) 
    local result
    local j
    local dnstemp1, dnstemp2
    if not setFlag then
        if "" ~= servers then
            j = find(servers, ",")
            if nil == j then
                result = validate_ipv4_addr(servers)
                if not result then
                    return 1
                else
                    return 0
                end
            else
                dnstemp1 = strsub(servers, 1, j-1)
                result = validate_ipv4_addr(dnstemp1)
                if not result then
                    return 1
                end
                dnstemp2 = strsub(servers, j+1, strlen(servers))
                if nil == dnstemp2 then
                    return 0
                end
                if "" == dnstemp2 then
                    return 0
                end
                result = validate_ipv4_addr(dnstemp2)
                if not result then
                    return 2
                else
                    return 0
                end
            end
        else
           return 1
        end
    end
    return 0
end

-- Parse wan status from gmsg
function parse_wan_status(StatusCode, result)
    result.ErrReason = "Success"
    if StatusCode == "AccessInternet" then
        result.Status = "Connected"
    elseif StatusCode == "NormalDisconnect" then
        result.Status = "Disconnected"
        result.ErrReason = "NormalDisconnect"
    elseif StatusCode == "Connected" then
        result.Status = "Connected"
    else
        result.Status = "Fault"
        result.ErrReason = StatusCode
    end
end

function has_datacard()
    sys.exec("cat /proc/proc_user_umts >/var/diagnose_umts")
    local fh = io.open("/var/diagnose_umts", "r")
    local line = ''
    if fh then
        line = fh:read("*a")
        fh:close()
    end
    sys.exec("rm /var/diagnose_umts")
    ip = string.find(line, "modem")
    if ip ~= nil then
        return true
    end

    return false
end

local ipmaps = {
    Name="Name",
    Alias="X_WanAlias",
    Enable="Enable",
    AccessType="WANAccessType",
    ConnectionType="ConnectionType",
    ConnectionStatus="ConnectionStatus",
    IPv6ConnectionStatus="X_IPv6ConnectionStatus",
    ServiceList="X_ServiceList",
    MTU="MaxMTUSize",
    MSS="X_TCP_MSS",
    NATType="X_NATType",
    IPv4Enable="X_IPv4Enable",
    IPv4AddrType="AddressingType",
    IPv4Addr="ExternalIPAddress",
    IPv4Mask="SubnetMask",
    IPv4Gateway="DefaultGateway",
    IPv4DnsServers="DNSServers",
    DNSOverrideAllowed="DNSOverrideAllowed",
    IPv6Enable="X_IPv6Enable",
    IPv6AddrType="X_IPv6AddressingType",
    IPv6Addr="X_IPv6Address",
    IPv6Gateway="X_IPv6DefaultGateway",
    IPv6DnsServers="X_IPv6DNSServers",
    IPv6PrefixList="X_IPv6PrefixList",
    WANDHCPOption60="X_WANDHCPOption60",
    BindDhcpsMacAddr="X_BindDhcpsMacAddr",
    IsDefault="X_Default",
    MACColone="MACAddress",
    MACColoneEnable="MACAddressOverride"
}

local pppmaps = {
    Name="Name",
    Alias="X_WanAlias",
    Enable="Enable",
    AccessType="WANAccessType",
    ConnectionType="ConnectionType",
    Username="Username",
    Password = "defaultPasswd",
    ConnectionStatus="ConnectionStatus",
    IPv6ConnectionStatus="X_IPv6ConnectionStatus",
    ServiceList="X_ServiceList",
    MRU="MaxMRUSize",
    MTU="MaxMTUSize",
    MSS="X_TCP_MSS",
    NATType="X_NATType",
    PPPAuthMode="PPPAuthenticationProtocol",
    PPPTrigger="ConnectionTrigger",
    PPPIdletime="IdleDisconnectTime",
    IPv4Enable="X_IPv4Enable",
    IPv4AddrType="AddressingType",
    IPv4Addr="ExternalIPAddress",
    IPv4Mask="SubnetMask",
    IPv4Gateway="DefaultGateway",
    IPv4DnsServers="DNSServers",
    DNSOverrideAllowed="DNSOverrideAllowed",
    IPv6Enable="X_IPv6Enable",
    IPv6AddrType="X_IPv6AddressingType",
    IPv6Addr="X_IPv6Address",
    IPv6Gateway="X_IPv6DefaultGateway",
    IPv6DnsServers="X_IPv6DNSServers",
    IPv6PrefixList="X_IPv6PrefixList",
    WANDHCPOption60="X_WANDHCPOption60",
    BindDhcpsMacAddr="X_BindDhcpsMacAddr",
    IsDefault="X_Default",
    MACColone="MACAddress",
    MACColoneEnable="MACAddressOverride",
    PPPoEServiceName="PPPoEServiceName",
    PPPoEACName="X_ServerACName"
}

function fill_access_info_by_ID(ID, conn, accessdevs)
    local start = find(ID, "WANConnectionDevice")
    local res = strsub(ID, 1, start - 1)
    res = res.."WANCommonInterfaceConfig."
    conn.AccessType = ""
    conn.AccessStatus = "Down"
    for k,v in pairs(accessdevs) do
        if res == k then
            conn.AccessType = v["WANAccessType"]
            conn.AccessStatus = v["PhysicalLinkStatus"]
            break
        end
    end
end

function fill_xdls_linkstatus_by_ID(ID, conn, accessdevs)
    local start = find(ID, "WANPPPConnection")
    if start == nil then
        start = find(ID, "WANIPConnection")
    end
    local res = strsub(ID, 1, start - 1)
    res = res.."WANDSLLinkConfig."

    for k,v in pairs(accessdevs) do
        if res == k then
            if "Down" == v["LinkStatus"] then
                conn.AccessStatus = "Down"
                break
            end
        end
    end
end

function is_wan_connected(con)
    if "Connected" == con.ConnectionStatus then
        return true;
    else
        return false;
    end    
end

function has_default_internet(pppcons, ipconns)
    local has_default = false
    local has_internet = false
    for k, v in pairs(pppcons) do
        local ip = find(v["X_ServiceList"], "INTERNET")
        if ip then
            has_internet = true
        end

        if ip and toboolean(v['X_Default']) then
            has_default = true
        end
    end

    for k, v in pairs(ipconns) do
        local ip = find(v["X_ServiceList"], "INTERNET")
        if ip then
            has_internet = true
        end

        if ip and toboolean(v['X_Default']) then
            has_default = true
        end
    end
    return has_default, has_internet
end

function has_default_internet(pppcons, ipconns)
    local has_default = false
    local has_internet = false
    if nil ~= pppcons then
        for k, v in pairs(pppcons) do
            local ip = find(v["X_ServiceList"], "INTERNET")
            if nil ~= ip then
                has_internet = true
                if toboolean(v['X_Default']) then
                    has_default = true
                end
            end
        end
    end

    if nil ~= ipconns then
        for k, v in pairs(ipconns) do
            local ip = find(v["X_ServiceList"], "INTERNET")
            if nil ~= ip then
                has_internet = true
                if toboolean(v['X_Default']) then
                    has_default = true
                end
            end

        end
    end
    return has_default, has_internet
end

function is_default(data, has_default, has_internet)
    if nil ~= has_default and nil ~= has_internet then
        if has_default then
            local ip = find(data["X_ServiceList"], "INTERNET")
            if nil == ip then
                return false
            end
            if not toboolean(data['X_Default']) then
                return false
            end
        else
            if not has_internet then
                return false
            end

            local ip = find(data['X_ServiceList'], 'INTERNET')
            if nil == ip then
                return false
            end
        end
        return true
    else
        if not toboolean(data['X_Default']) then
            if not pppcons or not ipconns then
                return false
            end
        end
        if not toboolean(data["X_Default"]) and has_default_internet(pppcons, ipcons) then
            return false
        end
        local ip = find(data["X_ServiceList"], "INTERNET")
        if not ip then
            return false
        end
        return true
    end
end

function getUmtsWan(pppCon, accessdevs)
    local connected = {}
    local unconnected = {}
    local errcode = 0
    if not accessdevs then
        errcode,accessdevs= GetParameterValues("InternetGatewayDevice.WANDevice.{i}.WANCommonInterfaceConfig.",
            {"WANAccessType", "PhysicalLinkStatus"})
    end
    if not pppCon then
        errcode, pppCon = GetParameterValues("InternetGatewayDevice.WANDevice.{i}.WANConnectionDevice.{i}.WANPPPConnection.{i}.", 
            {"Enable", 
            "ConnectionStatus", "X_Default", "X_ServiceList"});
    end

    local con = {}
    for k,v in pairs(pppCon) do
        if is_default(v) then
            local con = {}
            con.ID = k
            fill_access_info_by_ID(k, con, accessdevs)
            if "UMTS" == con.AccessType then
                return k
            end
        end
    end
    return ""
end
function getDefaultWan(pppCon, ipCon, accessdevs)
    local connected = {}
    local unconnected = {}
    local errcode = 0

    errcode, atmlink = GetParameterValues("InternetGatewayDevice.WANDevice.1.WANConnectionDevice.{i}.WANDSLLinkConfig.",
            {"LinkStatus"})
    errcode, ptmlink = GetParameterValues("InternetGatewayDevice.WANDevice.2.WANConnectionDevice.{i}.WANDSLLinkConfig.",
            {"LinkStatus"})
    if not accessdevs then
        errcode,accessdevs= GetParameterValues("InternetGatewayDevice.WANDevice.{i}.WANCommonInterfaceConfig.",
            {"WANAccessType", "PhysicalLinkStatus"})
    end
    if not pppCon then
        errcode, pppCon = GetParameterValues("InternetGatewayDevice.WANDevice.{i}.WANConnectionDevice.{i}.WANPPPConnection.{i}.", 
            {"Enable", 
             "ConnectionStatus", "X_Default", "X_ServiceList"});
    end

    if not ipCon then
        errcode,ipCon = GetParameterValues("InternetGatewayDevice.WANDevice.{i}.WANConnectionDevice.{i}.WANIPConnection.{i}.", 
            {"Enable",           
            "ConnectionStatus", "X_Default", "X_ServiceList"});
    end

    local has_default, has_internet = has_default_internet(pppCon, ipCon)
    local CheckSkip = false

    for k,v in pairs(pppCon) do
        if CheckSkip or is_default(v, has_default, has_internet) then
            local con = {}
            con.ID = k
            fill_access_info_by_ID(k, con, accessdevs)
            if con.AccessType == "DSL" then
                fill_xdls_linkstatus_by_ID(k, con, atmlink)
            elseif con.AccessType == "VDSL" then
                fill_xdls_linkstatus_by_ID(k, con, ptmlink)
            end
            con.ConnectionStatus = v["ConnectionStatus"]        
            if is_wan_connected(con) then
                insert(connected, con)
            else
                insert(unconnected, con)
            end
        end
    end

    for k,v in pairs(ipCon) do
        if CheckSkip or is_default(v, has_default, has_internet) then
            local con = {}
            con.ID = k
            fill_access_info_by_ID(k, con, accessdevs)
            if con.AccessType == "DSL" then
                fill_xdls_linkstatus_by_ID(k, con, atmlink)
            elseif con.AccessType == "VDSL" then
                fill_xdls_linkstatus_by_ID(k, con, ptmlink)
            end
            con.ConnectionStatus = v["ConnectionStatus"]            
            if is_wan_connected(con) then
                insert(connected, con)
            else
                insert(unconnected, con)
            end
        end
    end

    local dsl = nil
    local vdsl = nil
    local eth = nil
    local wifiwan = nil
    local lan1wan = nil
    for k,v in pairs(connected) do
        if v.AccessType == "DSL" and dsl == nil then
            dsl = v
        elseif v.AccessType == "VDSL" and vdsl == nil then
            vdsl = v
        elseif v.AccessType == "Ethernet" and eth == nil then
            eth = v
        elseif v.AccessType == "WIFI" and wifiwan == nil then
            wifiwan = v
        elseif v.AccessType == "LAN_WAN" and eth == nil then
            lan1wan = v
        end
    end

    if dsl ~= nil then
        return dsl.ID, has_internet
    end

    if vdsl ~= nil then
        return vdsl.ID, has_internet
    end

    if eth ~= nil then
        return eth.ID, has_internet
    end
    if wifiwan ~= nil then
        return wifiwan.ID, has_internet
    end
    if lan1wan ~= nil then
        return lan1wan.ID, has_internet
    end


    for k,v in pairs(unconnected) do
        if v.AccessType == "DSL" and dsl == nil then
            dsl = v
        elseif v.AccessType == "VDSL" and vdsl == nil then
            vdsl = v
        elseif v.AccessType == "Ethernet" and eth == nil then
            eth = v
        elseif v.AccessType == "WIFI" and wifiwan == nil then
            wifiwan = v
        elseif v.AccessType == "LAN_WAN" and eth == nil then
            lan1wan = v
        end
    end

    -- Return connected cable first
    if dsl and "Down" ~= dsl.AccessStatus  then
        return dsl.ID, has_internet
    end
    if vdsl and "Down" ~= vdsl.AccessStatus  then
        return vdsl.ID, has_internet
    end
    if eth and "Down" ~= eth.AccessStatus then
        return eth.ID, has_internet
    end
    if wifiwan and "Down" ~= wifiwan.AccessStatus then
        return wifiwan.ID, has_internet
    end
    if lan1wan and "Down" ~= lan1wan.AccessStatus then
        return lan1wan.ID, has_internet
    end
    if dsl ~= nil then
        return dsl.ID, has_internet
    end

    if vdsl ~= nil then
        return vdsl.ID, has_internet
    end

    if eth ~= nil then
        return eth.ID, has_internet
    end

    if wifiwan ~= nil then
        return wifiwan.ID, has_internet
    end

    if lan1wan ~= nil then
        return lan1wan.ID, has_internet
    end

    return "InternetGatewayDevice.WANDevice.1.WANConnectionDevice.1.WANPPPConnection.1.", false
end

function getDefaultWanLayer2()
    local defaultwan = getDefaultWan()
    local ip = find(defaultwan, "WANConnectionDevice")

    return strsub(defaultwan, 1, ip-1)
end

-- Translate ConnectionType from datamodel to web ui
function get_ip_conn_type(ID, conntype)
    if "IP_Bridged" == conntype or "PPPoE_Bridged" == conntype then
        return "Bridged"
    end

    if "DHCP_Spoofed" == conntype then
        return conntype
    end

    if find(ID, "WANPPPConnection.") then
        return "PPP_Routed"
    end

    return conntype
end

-- Get WAN connection device from WAN path or WAN conn dev path
function get_wan_conn_dev_of_wan(ID)
    local start = find(ID, ".WANPPPConnection.")
    if not start then
        start = find(ID, ".WANIPConnection.")
        if not start then
            return ID
        end
    end
    local wanconndev = strsub(ID, 0, start)
    return wanconndev
end

-- Get WAN device from WANConnectionDevice or WAN path
function get_wan_dev_of_wan(ID)
    local start = find(ID, ".WANConnectionDevice")
    local wandev = strsub(ID, 1, start)
    return wandev
end

-- Check if vlan path are the same, X_ATP and X_ are ignored
function is_vlan_path_same(vlan1, vlan2)
    if vlan1 == vlan2 then
        return true
    end
    return false
end

-- Get access type of WAN or WAN conn dev
function get_access_type_by_wan(ID)
    local res = get_wan_dev_of_wan(ID)
    res = res.."WANCommonInterfaceConfig."
    local errcode,getValues= GetParameterValues(res, {"WANAccessType"})
    for k,v in pairs(getValues) do
        return v["WANAccessType"]
    end
    return ""
end

-- Get access type of WAN or WAN conn dev
-- No db query needed
function get_access_type_by_wan_ex(ID, wandevs)
    local wanconndev = get_wan_dev_of_wan(ID)
    wanconndev = wanconndev.."WANCommonInterfaceConfig."
    for k,v in pairs(wandevs) do
        if wanconndev == k then
            return v["WANAccessType"]
        end
    end

    return ""
end

-- Get wan conn dev by wanid, current vlans should be input
function get_wanconn_by_wanid(id, vlans)
    if not string.find(id, "VLANTermination.") then
        return id
    end

    if not vlans then
        local errcode = 0
        errcode,vlans = GetParameterValues("InternetGatewayDevice.X_VLANTermination.{i}.", 
                {"LowerLayers", "VLANID", "802-1pMark"});
        if not vlans then
            return ""
        end
    end
    for k,v in pairs(vlans) do
        if is_vlan_path_same(k, id) then
            return v["LowerLayers"].."."
        end
    end
    return ""
end

-- Get wandev by access type
function get_wandev_by_access_type(accesstype, wandevs)
    for k,v in pairs(wandevs) do
        if accesstype == v["WANAccessType"] then
            return strsub(k, 1, string.find(k, ".WANCommonInterfaceConfig"))
        end
    end

    return ""
end

-- Get wan count of a vlan
function get_wancnt_by_vlan(vlan, vlans)
    local wanconndev = ""
    if not vlans then
        local errcode = 0
        errcode, vlans = GetParameterValues("InternetGatewayDevice.X_VLANTermination.{i}.", 
                {"LowerLayers", "VLANID", "802-1pMark"});
    end
    if not vlans then
        return 0
    end
    for k,v in pairs(vlans) do
        if is_vlan_path_same(vlan, k) then
            wanconndev = v["LowerLayers"].."."
        end
    end
    local pppconn = wanconndev.."WANPPPConnection.{i}."
    local errcode,wans = GetParameterValues(pppconn, 
                {"X_LowerLayers"});
    local cnt = 0
    if wans then
        for k,v in pairs(wans) do
            if is_vlan_path_same(vlan, v["X_LowerLayers"]..".") then
                cnt = cnt + 1
            end
        end
    end
    wanconndev = wanconndev.."WANIPConnection.{i}."
    errcode,wans = GetParameterValues(wanconndev, 
                {"X_LowerLayers"});
    if wans then
        for k,v in pairs(wans) do
            if is_vlan_path_same(vlan, v["X_LowerLayers"]..".") then
                cnt = cnt + 1
            end
        end
    end
    return cnt
end

function get_lowerlayer_by_wan(ID)
    local errcode,getValues= GetParameterValues(ID, {"X_LowerLayers"})
    if not getValues then
        return ""
    end
    for k,v in pairs(getValues) do
        if "" ~= v["X_LowerLayers"] then
            return v["X_LowerLayers"].."."
        end
    end
    return ""
end

function safe_delete_wan(wan)
    local prevAccessType = get_access_type_by_wan(wan)
    local lowerlayer = get_lowerlayer_by_wan(wan)
    local errcode, NeedReboot = dm.DeleteObject(wan)
    check_vlan_need_to_be_deleted(lowerlayer, nil, 0)

    if "DSL" == prevAccessType then
        if 0 == get_wancnt_by_wanconndev(wan) then
            -- If the WANConnectionDevice has no other IP or PPP, delete it
            local wanConDev = get_wan_conn_dev_of_wan(wan)
            dm.DeleteObject(wanConDev)
        end
    end
end

-- Check vlan need to be deleted
function check_vlan_need_to_be_deleted(lowerlayer, vlans, max)
    if not lowerlayer then
        return
    end
    if "" == lowerlayer then
        return
    end

    local wanOnCurVlan = get_wancnt_by_vlan(lowerlayer, vlans)
    luadbg(lowerlayer.." has "..tostring(wanOnCurVlan).." wan now")
    luadbg("Delete if more than "..tostring(max))
    if wanOnCurVlan <= max then
        lowerlayer = string.gsub(lowerlayer, "X_ATP_VLANTermination", "X_VLANTermination")
        luadbg("Delete vlan ["..lowerlayer.."] now ...")
        errcode, NeedReboot = dm.DeleteObject(lowerlayer)
    end
end

-- Get wan count of a WAN conn dev or WAN
function get_wancnt_by_wanconndev(path)
    local wanconndev = get_wan_conn_dev_of_wan(path)
    local errcode, res = GetParameterValues(wanconndev,
            {"WANIPConnectionNumberOfEntries", "WANPPPConnectionNumberOfEntries"})
    if not res then
        return 0
    end
    local nums = res[wanconndev]

    return nums["WANIPConnectionNumberOfEntries"] + nums["WANPPPConnectionNumberOfEntries"]
end

function find_wanconndev_by_pvc(PVC, wandev)
    --Check if PVC exists
    errcode, wanconns = GetParameterValues(wandev.."WANConnectionDevice.{i}.WANDSLLinkConfig.", {"DestinationAddress"})
    wanconn = nil
    if not wanconns then
        return wanconn
    end

    for k,v in pairs(wanconns) do
        if PVC == v["DestinationAddress"] then
            local start = find(k, ".WANDSLLinkConfig")
            return strsub(k, 1, start)
        end
    end
    return nil
end

-- Link related utilties

-- Get WANConnectionDevice through input data
-- If the WANConnectionDevice does not exists, create it
-- The WANConnectionDevice domain name is returned.
function add_wan_conn_dev(data, wandev)
    local errcode, wanconns = dm.GetParameterValues(wandev.."WANConnectionDevice.{i}.", {"Name"})
    local wanconn = nil;
    if wanconns then
        for k,v in pairs(wanconns) do
            wanconn = k
            break
        end
    end

    -- DSL can add new ConnectionDevice
    if "DSL" ~= data["AccessType"] then
        if wanconn then
            return wanconn
        end

        local paras = nil
        if "VDSL" == data["AccessType"] then
            paras = {{"WANPTMLinkConfig.X_VLANIDMark", "-1"}, {"WANPTMLinkConfig.X_802-1pMark", "-1"},
                {"WANPTMLinkConfig.Enable", "1"},
                {"WANPTMLinkConfig.X_PortId", "0"},
                {"WANPTMLinkConfig.X_PTMPriorityLow", "1"},
                {"WANPTMLinkConfig.X_PTMPriorityHigh", "0"}}
        elseif "Ethernet" == data["AccessType"] then
            paras = {}
        elseif "LAN_WAN" == data["AccessType"] then
            paras = {}
        elseif "WIFI" == data["AccessType"] then
            paras = {}
        else
            paras = {{"X_WANUMTSLinkConfig.Enable", "1"}}
        end
        local errcode,instId,needreboot = dm.AddObjectWithValues(wandev.."WANConnectionDevice.", paras)
        return wandev.."WANConnectionDevice."..tostring(instId).."."
    end

    --Check if PVC exists
    local existPvc = find_wanconndev_by_pvc(data["PVC"], wandev)
    if existPvc then
        -- Update parameters
        local paras = build_dsl_params(data, existPvc)
        dm.SetParameterValues(paras)
        return existPvc
    end

    local paras = build_dsl_params(data, "")

    local errcode,instId,needreboot = dm.AddObjectWithValues(wandev.."WANConnectionDevice.", paras)
    return wandev.."WANConnectionDevice."..tostring(instId).."."
end

function create_new_link(data, wandevs)
    -- Get WANDevice through AccessType, this must succeed by defaultcfg
    local wandev = get_wandev_by_access_type(data["AccessType"], wandevs)
    if "" == wandev then
        appenderror("AccessType", "9003")
        return ""
    end

    -- Add connection device if not exists
    wanconndev = add_wan_conn_dev(data, wandev)
    local lowerlayer = wanconndev
    if true == toboolean(data["VLANEnable"]) then
        -- Check if already exists
        local errcode,vlans = dm.GetParameterValues("InternetGatewayDevice.X_VLANTermination.{i}.", 
                {"Name", "LowerLayers", "VLANID", "802-1pMark"});
        lowerlayer = find_vlan_by_params(vlans, data, wanconndev)
        if not lowerlayer then
            -- Add vlan termination
            lowerlayer = add_vlan_termination(data, wanconndev)
            if "" == lowerlayer then
                return ""
            end
        else
            -- Update vlan parameters
            data["ID"] = lowerlayer
            local paras = build_vlan_parameters(data, wanconndev)
            local errcode = dm.SetParameterValues(paras)
            if 0 ~= errcode then
                lowerlayer = ""
            end
        end
    end
    return lowerlayer
end

function get_dsl_wan_id()
    local errcode,accessdevs= dm.GetParameterValues("InternetGatewayDevice.WANDevice.{i}.WANCommonInterfaceConfig.", {"WANAccessType"})
    local dslWan = ""
    local vdslWan = ""
    for k,v in pairs(accessdevs) do
        if "DSL" == v["WANAccessType"] then
            dslWan = k
        elseif "VDSL" == v["WANAccessType"] then
            vdslWan = k
        end
    end

    if "" == dslWan then
        dslWan = vdslWan
    end

    local info = {}
    if "" == dslWan then
        return nil
    end

    local start = string.find(dslWan, ".WANCommonInterfaceConfig.")
    if start then
        dslWan = string.sub(dslWan, 0, start)
    end

    dslWan = dslWan.."WANDSLInterfaceConfig."
    return dslWan
end

function get_dsl_qos_peak_rate()
    return 2600
end

-- DSL
function add_one_dsl_parameter(paras, name, value, wanconndev)
    if not value then
        return
    end
    local newName = wanconndev.."WANDSLLinkConfig."..name
    insert(paras, {newName, value})
end

function build_dsl_params(data, wanconndev)
    local paras = {}
    local hasErr = false
    add_one_dsl_parameter(paras, "X_VLANIDMark", "-1", wanconndev)
    add_one_dsl_parameter(paras, "X_802-1pMark", "-1", wanconndev)
    add_one_dsl_parameter(paras, "DestinationAddress", data["PVC"], wanconndev)
    add_one_dsl_parameter(paras, "LinkType", data["LinkType"], wanconndev)
    add_one_dsl_parameter(paras, "ATMEncapsulation", data["EncapMode"], wanconndev)
    add_one_dsl_parameter(paras, "ATMQoS", data["AtmQoS"], wanconndev)
    add_one_dsl_parameter(paras, "Enable", "1", wanconndev)
    if nil ~= data["AtmQoS"] and "UBR" ~= data["AtmQoS"] then
        print("no UBR come in.PeakRate:"..data["PeakRate"])
        local dsl_peak_rate = get_dsl_qos_peak_rate()
            if tonumber(data["PeakRate"]) < 50 or tonumber(data["PeakRate"]) > dsl_peak_rate then
                appenderror('DslPeakRate', 'wan.PeakRate_err'..", 50~"..dsl_peak_rate)
                hasErr = true
                return paras, hasErr
            end
        add_one_dsl_parameter(paras, "ATMPeakCellRate", data["PeakRate"], wanconndev)
        if nil ~= data["AtmQoS"] and "CBR" ~= data["AtmQoS"] and "UBR+" ~= data['AtmQoS'] then
            print("no CBR come in.ATMSustainableCellRate:"..data["SupportRate"]..",ATMMaximumBurstSize:"..data["MaxBurstRate"])
                if tonumber(data["SupportRate"]) < 50 or tonumber(data["SupportRate"]) > dsl_peak_rate then
                    appenderror('DslSupportRate', 'wan.SupportRate_err'..", 50~"..dsl_peak_rate)
                    hasErr = true
                    return paras, hasErr
                end
                if tonumber(data["MaxBurstRate"]) < 1  or tonumber(data["MaxBurstRate"]) > 32767 then
                    appenderror('DslMaxBurstRate', 'wan.MaxBurstRate_err'..", 1~32767")
                    hasErr = true
                    return paras, hasErr
                end
            add_one_dsl_parameter(paras, "ATMSustainableCellRate", data["SupportRate"], wanconndev)
            add_one_dsl_parameter(paras, "ATMMaximumBurstSize", data["MaxBurstRate"], wanconndev)
        end
    end

    return paras, hasErr
end


function add_one_vlan_parameter(paras, name, value, vlandomain)
    local newName = vlandomain..name
    insert(paras, {newName, value})
end

function build_vlan_parameters(data, wanconndev)
    local paras = {}

    -- Remove last '.'
    local lowerlayer = strip_end_dot(wanconndev)

    add_one_vlan_parameter(paras, "VLANID", data["VLANId"], data["ID"])
    add_one_vlan_parameter(paras, "802-1pMark", data["VLAN1p"], data["ID"])
    add_one_vlan_parameter(paras, "LowerLayers", lowerlayer, data["ID"])

    print_paras(paras)
    return paras
end

function add_vlan_termination(data, wanconndev)
    -- Remove last '.'
    local lowerlayer = strip_end_dot(wanconndev)

    local paras = {{"VLANID", data["VLANId"]}, {"802-1pMark", data["VLAN1p"]},
            {"LowerLayers", lowerlayer}}
    print_paras(paras)
    local errcode,instId,needreboot,errs = dm.AddObjectWithValues("InternetGatewayDevice.X_VLANTermination.",
            paras)
    if 0 ~= errcode then
        appenderror("errcode", 9003)
        appenderror("VLANId", "wan.vlan_err")
        return ""
    end
    return "InternetGatewayDevice.X_VLANTermination."..tostring(instId).."."
end

function find_vlan_by_params(vlans, data, wanconndev)
    local vlanObj = nil
    for k,v in pairs(vlans) do
        local lowerlayer = v["LowerLayers"].."."
        if lowerlayer == wanconndev then
            if tostring(data["VLANId"]) == tostring(v["VLANID"]) then
                vlanObj = k
            end
        end
    end
    return vlanObj
end

function update_single_link(wanconndev, data, wandevs, vlans, isDefault)
    local accessType = get_access_type_by_wan_ex(wanconndev, wandevs)

    luadbg("Update link ["..wanconndev.."] with access type ["..accessType.."] now ...")
    local newConnDev = false
    local vlanEnable = toboolean(data["VLANEnable"])
    if "DSL" == accessType then
        luadbg("\nUpdate DSL parameters now ...")
        if isDefault then
            vlanEnable = false
        end
        local curWans = get_wancnt_by_wanconndev(wanconndev)
        local wandev = get_wan_dev_of_wan(wanconndev)
        local existingPVC = find_wanconndev_by_pvc(data["PVC"], wandev)
        if existingPVC then
            luadbg("Conndev "..existingPVC.." already has PVC "..data["PVC"])
        end
        luadbg("Current link ["..wanconndev.."] has "..tostring(curWans).." wans")

        if (not existingPVC and curWans <= 1) or (existingPVC == wanconndev) then
            -- PVC does not changed, just save
            -- Or PVC is used only by this WAN
            luadbg("No need to switch wan conndev for "..wanconndev)
            local paras, hasErr = build_dsl_params(data, wanconndev)
            if hasErr then
                return nil
            end
            err = dm.SetParameterValues(paras)
            if err ~= 0 then
                return nil
            end
        else
            newConnDev = true
            if not existingPVC then
                -- New PVC not exists, need add new WANConnDev
                luadbg("Need to create new wan conndev now ...")
                if data["ID"] ~= wanconndev then
                    -- Previously has a vlan, need to be deleted
                    luadbg("Delete vlan "..data["ID"])
                    check_vlan_need_to_be_deleted(data["ID"], vlans, 1)
                end
                local paras, hasErr = build_dsl_params(data, "")
                if hasErr then
                    return nil
                end
                local errcode,instId,needreboot = dm.AddObjectWithValues(wandev.."WANConnectionDevice.", paras)
                if errcode ~= 0 then                   
                    luadbg("AddObjectWithValues fail"..errcode)
                    return nil
                end  				
                wanconndev = wandev.."WANConnectionDevice."..tostring(instId).."."
                luadbg("Newly created conndev is "..wanconndev)
            else
                luadbg("Switch to another existing wan conndev now ...")
                if curWans <= 1 then
                    luadbg("Need to delete previous WAN first")
                    dm.DeleteObject(wanconndev)
                elseif data["ID"] ~= wanconndev then
                    -- Previously has a vlan, need to be deleted
                    luadbg("Delete vlan first "..data["ID"])
                    check_vlan_need_to_be_deleted(data["ID"], vlans, 1)
                end
                -- Update vlans
                errcode,vlans = dm.GetParameterValues("InternetGatewayDevice.X_VLANTermination.{i}.", 
                {"Name", "LowerLayers", "VLANID", "802-1pMark"});
                wanconndev = existingPVC
            end
        end
    end

    local lowerlayer = ""
    if vlanEnable then
        -- Need to enable VLAN

        -- Find if the same vlan exists.
        data["LowerLayers"] = wanconndev
        local existingVlan = find_vlan_by_params(vlans, data, wanconndev)
        -- VLAN already exists, just return
        if existingVlan then
            lowerlayer = existingVlan
            local paras = build_vlan_parameters(data, wanconndev)
            err = dm.SetParameterValues(paras)
        else
            if data["ID"] ~= wanconndev and (not newConnDev) then
                -- Previously has a vlan
                local wanOnCurVlan = get_wancnt_by_vlan(data["ID"], vlans)
                luadbg("Change existing vlan ["..data["ID"].."] with "..tostring(wanOnCurVlan).." WAN")
                if wanOnCurVlan <= 1 then 
                    local paras = build_vlan_parameters(data, wanconndev)
                    err = dm.SetParameterValues(paras)
                    lowerlayer = data["ID"]
                else
                    -- Add New vlan
                    luadbg("Need to add new vlan paras")
                    lowerlayer = add_vlan_termination(data, wanconndev)
                end
            else
                -- Need to add vlan instances
                luadbg("Add new vlan paras")
                lowerlayer = add_vlan_termination(data, wanconndev)
                if "" == lowerlayer then
                    return ""
                end
            end
        end
    else
        -- Disable VLAN
        if wanconndev ~= data["ID"] then
            -- Previously has vlan
            --dm.DeleteObject(data["ID"])
        end
        lowerlayer = wanconndev
    end
    return lowerlayer
end

function add_one_wan_parameter(paras, name, value, wandomain)
    if nil == value then
        return
    end
    local newName = wandomain..name
    table.insert(paras, {newName, value})
end

function fill_ipv6_addr_paras(data, paras, wan)
    local result = true
    add_one_wan_parameter(paras, "X_IPv6Enable", data["IPv6Enable"], wan)

    if not toboolean(data["IPv6Enable"]) then
        return result
    end

    if not data["IPv6AddrType"] then
        return result
    end

    if "SLAAC" ~= data["IPv6AddrType"] and "DHCP" ~= data["IPv6AddrType"] and "Static" ~= data["IPv6AddrType"] then
        appenderror("IPv6AddrType", "9006")
        result = false
    end
    add_one_wan_parameter(paras, "X_IPv6AddressingType", data["IPv6AddrType"], wan)
    if "Static" == data["IPv6AddrType"] then
        add_one_wan_parameter(paras, "X_IPv6Address", data["IPv6AddrSet"], wan)
        add_one_wan_parameter(paras, "X_IPv6PrefixLength", data["IPv6AddrPrefixLen"], wan)
        add_one_wan_parameter(paras, "X_IPv6DefaultGateway", data["IPv6Gateway"], wan)
        add_one_wan_parameter(paras, "X_IPv6DNSServers", data["IPv6DnsServers"], wan)
    end
    return result
end


function fill_wan_ip_parameters(data, paras, wan)
    local result = true
    local intVal = 0
    if data["MTU"] then
        intVal = tonumber(data["MTU"])
        if not intVal or intVal < 1280 or intVal > 1500 then
            appenderror("MTU", "Menu.range_err,1280~1500")
            result = false
        end
        add_one_wan_parameter(paras, "MaxMTUSize", data["MTU"], wan)
    end

    if data["MSS"] then
        intVal = tonumber(data["MSS"])
        if not intVal or (intVal < 100 and intVal ~= 0) or intVal > 1460 then
            appenderror("MSS", "Menu.range_err,100~1460")
            result = false
        end
        add_one_wan_parameter(paras, "X_TCP_MSS", data["MSS"], wan)
    end

    if data["NATType"] then
        if "0" == tostring(data["NATType"]) then
            add_one_wan_parameter(paras, "NATEnabled", false, wan)
        elseif "2" == tostring(data["NATType"]) then
            add_one_wan_parameter(paras, "NATEnabled", true, wan)
            add_one_wan_parameter(paras, "X_NATType", "full cone", wan)
        else
            add_one_wan_parameter(paras, "NATEnabled", true, wan)
            add_one_wan_parameter(paras, "X_NATType", "symmetric", wan)
        end
        if data["IPv4AddrType"] and "DHCP" ~= data["IPv4AddrType"] and "Static" ~= data["IPv4AddrType"] then
            appenderror("IPv4AddrType", "9006")
            result = false
        end
        add_one_wan_parameter(paras, "AddressingType", data["IPv4AddrType"], wan)
    end

    if data["IPv4AddrType"] then
        if "Static" == data["IPv4AddrType"] then
            add_one_wan_parameter(paras, "ExternalIPAddress", data["IPv4Addr"], wan)
            add_one_wan_parameter(paras, "SubnetMask", data["IPv4Mask"], wan)
            add_one_wan_parameter(paras, "DefaultGateway", data["IPv4Gateway"], wan)
            add_one_wan_parameter(paras, "DNSServers", data["IPv4DnsServers"], wan)
        else
            add_one_wan_parameter(paras, "DNSServers", data["IPv4DnsServers"], wan)
            ret = validate_dnsservers_addr(data["IPv4DnsServers"], data["DNSOverrideAllowed"])
            if 1 == ret then
                appenderror("IPv4PriDns", "wan.IPv4PriDns_err")
                return false
            elseif 2 == ret then
                appenderror("IPv4SecDns", "wan.IPv4SecDns_err")
                return false
            end
        end
    end

    return result
end

function fill_wan_ppp_or_dhcpspoofed_parameters(data, paras, wan, con_type)
    local result = true

    if data["IPv4Enable"] and data["IPv4DnsServers"] then
        add_one_wan_parameter(paras, "DNSServers", data["IPv4DnsServers"], wan)
        ret = validate_dnsservers_addr(data["IPv4DnsServers"], data["DNSOverrideAllowed"])
        if 1 == ret then
            appenderror("IPv4PriDns", "wan.IPv4PriDns_err")
            return false
        elseif 2 == ret then
            appenderror("IPv4SecDns", "wan.IPv4SecDns_err")
            return false
        end
    end

    if data["Username"] and string.len(data["Username"]) > 64 then
        appenderror("Username", "Menu.max_length_err,64")
        result = false
    end
    add_one_wan_parameter(paras, "Username", data["Username"], wan)

    if data["Password"] then
        if _G["defaultPasswd"] ~= data["Password"] then
            if string.len(data["Password"]) > 64 then
                appenderror("Password", "Menu.max_length_err,64")
                result = false
            end
            add_one_wan_parameter(paras, "Password", data["Password"], wan)
        end
    end

    local intVal = 0
    if data["MRU"] and con_type == "PPP_Routed" then
        intVal = tonumber(data["MRU"])
        if not intVal or intVal < 1280 or intVal > 1492 then
            appenderror("MRU", "Menu.range_err,1280~1492")
            result = false
        end
        add_one_wan_parameter(paras, "MaxMRUSize", data["MRU"], wan)
    end
    
    if data["MSS"] and con_type == "PPP_Routed" then
        intVal = tonumber(data["MSS"])
        if not intVal or (intVal < 100 and intVal ~= 0) or intVal > 1452 then
            appenderror("MSS", "Menu.range_err,100~1452")
            result = false
        end
        add_one_wan_parameter(paras, "X_TCP_MSS", data["MSS"], wan)
    end
    if data["NATType"] and con_type == "PPP_Routed"  then
        if "0" == tostring(data["NATType"]) then
            add_one_wan_parameter(paras, "NATEnabled", false, wan)
        elseif "2" == tostring(data["NATType"]) then
            add_one_wan_parameter(paras, "NATEnabled", true, wan)
            add_one_wan_parameter(paras, "X_NATType", "full cone", wan)
        else
            add_one_wan_parameter(paras, "NATEnabled", true, wan)
            add_one_wan_parameter(paras, "X_NATType", "symmetric", wan)
        end
    end
    if data["PPPAuthMode"] then
        if "AUTO" ~= data["PPPAuthMode"] and "PAP" ~= data["PPPAuthMode"] and "CHAP" ~= data["PPPAuthMode"] then
            appenderror("PPPAuthMode", "9006")
            result = false
        end
        add_one_wan_parameter(paras, "PPPAuthenticationProtocol", data["PPPAuthMode"], wan)
    end

    if data["PPPTrigger"] then
        if "AlwaysOn" ~= data["PPPTrigger"] and "Manual" ~= data["PPPTrigger"] and "OnDemand" ~= data["PPPTrigger"] then
            appenderror("PPPTrigger", "9006")
            result = false
        end
        add_one_wan_parameter(paras, "ConnectionTrigger", data["PPPTrigger"], wan)
    end

    if "OnDemand" == data["PPPTrigger"] then
        intVal = tonumber(data["PPPIdletime"])
        if not intVal or intVal < 30 or intVal > 31536000 then
            appenderror("PPPIdletimeOther", "Menu.range_err,30~31536000")
            result = false
        end
        add_one_wan_parameter(paras, "IdleDisconnectTime", data["PPPIdletime"], wan)
    end

    return result
end

function build_mac_colone_parameters(paras, data, wan)
    if nil == data["MACColoneEnable"] then
        return true
    end
    local enabled = false
    if toboolean(data["MACColoneEnable"]) then
        enabled = true
    end
    add_one_wan_parameter(paras, "MACAddressOverride", enabled, wan)
    if enabled then
        add_one_wan_parameter(paras, "MACAddress", data["MACColone"], wan)
    end
    return true
end

function build_wan_parameters(data, wan, wandevs)
    local result = true
    local paras = {}
    local wanconndev = get_wanconn_by_wanid(data["LowerLayer"])
    if "" == wanconndev then
        appenderror("LowerLayer", "9006")
        result = false
    end
    local accessType = get_access_type_by_wan_ex(wanconndev, wandevs)

    if nil ~= data["DNSOverrideAllowed"] then
        add_one_wan_parameter(paras, "DNSOverrideAllowed", data["DNSOverrideAllowed"], wan)
    end


    if string.find(data["LowerLayer"], "VLANTermination.") then
        local lowerlayer = strip_end_dot(data["LowerLayer"])
        add_one_wan_parameter(paras, "X_LowerLayers", lowerlayer, wan)
    else
        add_one_wan_parameter(paras, "X_LowerLayers", "", wan)
    end

    if nil ~= data["X_Default"] then
        add_one_wan_parameter(paras, "X_Default", toboolean(data["IsDefault"]), wan)
    end

    if nil ~= data["Reset"] then
        add_one_wan_parameter(paras, "Reset", toboolean(data["Reset"]), wan)
    end
    
    if toboolean(data["IsDefault"]) then
        data["Alias"] = "Internet_"..accessType
        add_one_wan_parameter(paras, "X_WanAlias", data["Alias"], wan)
    else
        add_one_wan_parameter(paras, "X_WanAlias", data["Alias"], wan)
    end

    if nil ~= data["Enable"] then
        add_one_wan_parameter(paras, "Enable", toboolean(data["Enable"]), wan)
    end
    add_one_wan_parameter(paras, "X_ServiceList", data["ServiceList"], wan)

    if "IP_Routed" == data["ConnectionType"] then
        add_one_wan_parameter(paras, "ConnectionType", "IP_Routed", wan)
        if not build_mac_colone_parameters(paras, data, wan) then
            result = false
        end
        if not fill_wan_ip_parameters(data, paras, wan) then
            result = false
        end
        add_one_wan_parameter(paras, "X_WANDHCPOption60", data["WANDHCPOption60"], wan)
    elseif "PPP_Routed" == data["ConnectionType"] then
        add_one_wan_parameter(paras, "ConnectionType", "IP_Routed", wan)

        if not build_mac_colone_parameters(paras, data, wan) then
            result = false
        end
        if not fill_wan_ppp_or_dhcpspoofed_parameters(data, paras, wan, data["ConnectionType"]) then
            result = false
        end
        if data["PPPoEServiceName"] and string.len(data["PPPoEServiceName"]) > 256 then
            appenderror("PPPoEServiceName", "Menu.max_length_err,256")
            result = false
        end
        add_one_wan_parameter(paras, "PPPoEServiceName", data["PPPoEServiceName"], wan)
    elseif "DHCP_Spoofed" == data["ConnectionType"] then
        add_one_wan_parameter(paras, "ConnectionType", "DHCP_Spoofed", wan)
        if not fill_wan_ppp_or_dhcpspoofed_parameters(data, paras, wan, data["ConnectionType"]) then
            result = false
        end
        if data["PPPoEServiceName"] and string.len(data["PPPoEServiceName"]) > 256 then
            appenderror("PPPoEServiceName", "Menu.max_length_err,256")
            result = false
        end
        add_one_wan_parameter(paras, "PPPoEServiceName", data["PPPoEServiceName"], wan)
    elseif "Bridged" == data["ConnectionType"] then
        add_one_wan_parameter(paras, "ConnectionType", "PPPoE_Bridged", wan)
    else
        appenderror("ConnectionType", "9006")
        result = false
    end

    if not result then
        return nil
    end
    return paras
end

function add_new_wan_to_wan_conn_dev(data, wanconndev, wandevs)
    local wan_name = wanconndev.."WANPPPConnection."
    if "IP_Routed" == data["ConnectionType"] then
        wan_name = wanconndev.."WANIPConnection."
    end

    local paras = build_wan_parameters(data, "", wandevs)
    if not paras then
        return ""
    end
    print("Add for wan ["..wan_name.."] now ...")

    local errcode,instId,needreboot,errs = dm.AddObjectWithValues(wan_name, paras)
    if 0 ~= errcode then
        if "IP_Routed" == data["ConnectionType"] then
            if false == responseErrorcode(errcode,errs,ipmaps) then
                appenderror("con", "wan.too_many_err")
            end
        else
            if false == responseErrorcode(errcode,errs,pppmaps) then
                appenderror("con", "wan.too_many_err")
            end
        end
        
        print("errcode is "..tostring(errcode))
        return ""
    end
    return wan_name..tostring(instId).."."
end

function delete_all_wan_for_link(prevIPType, wanconndev, data)
    local wanPath = wanconndev
    if "IP_Routed" == prevIPType then
        wanPath = wanPath.."WANIPConnection.{i}."
    else
        wanPath = wanPath.."WANPPPConnection.{i}."
    end
    local err, wans = dm.GetParameterValues(wanPath, {"X_LowerLayers"});
    if not wans then
        return
    end
    local lowerlayer = data["LowerLayer"]
    if not string.find(tostring(lowerlayer), "VLANTermination") then
        lowerlayer = ""
    end
    for k,v in pairs(wans) do
        if k ~= data["ID"] then
            local tmpLowerLayer = v["X_LowerLayers"]
            if "" ~= tmpLowerLayer then
                tmpLowerLayer = tmpLowerLayer.."."
            end
            if is_vlan_path_same(tmpLowerLayer, lowerlayer) then
                luadbg("Delete conflicted wan ["..k.."] now ...")
                dm.DeleteObject(k)
            end
        end
    end
end

function delete_all_bridges_for_link(wanconndev, lowerlayer)
    local wanPath = wanconndev
    wanPath = wanPath.."WANPPPConnection.{i}."
    local err, wans = dm.GetParameterValues(wanPath, {"X_LowerLayers", "ConnectionType"});
    if not wans then
        return
    end
    if not string.find(lowerlayer, "VLANTermination") then
        lowerlayer = ""
    end
    for k,v in pairs(wans) do
        local tmpLowerLayer = v["X_LowerLayers"]
        if "" ~= tmpLowerLayer then
            tmpLowerLayer = tmpLowerLayer.."."
        end
        if is_vlan_path_same(tmpLowerLayer, lowerlayer) and
            ("IP_Bridged" == v["ConnectionType"] or "PPPoE_Bridged" == v["ConnectionType"])then
            luadbg("Delete bridge wan ["..k.."] now ...")
            dm.DeleteObject(k)
        end
    end
end

function bridge_auto_fill(data, prevIPType)
    local dhcpsEnable = "0"
    -- Fill NATType
    if "Bridged" == prevIPType then
        dhcpsEnable = "1"
    end

    local errcode = dm.SetParameterValues("InternetGatewayDevice.LANDevice.1.LANHostConfigManagement.DHCPServerEnable", dhcpsEnable)
    local errcode = dm.SetParameterValues("InternetGatewayDevice.LANDevice.1.LANHostConfigManagement.X_DHCPv6.DHCPServerEnable", dhcpsEnable)
    local errcode = dm.SetParameterValues("InternetGatewayDevice.LANDevice.1.LANHostConfigManagement.X_SLAAC.RouterAdvertisementEnable", dhcpsEnable)
end

function default_wan_pre_action(data, wanconndev)
    luadbg("Default wan should delete conflicted wans with lowerlayer ["..data["LowerLayer"].."]")
    if "IP_Routed" == data["ConnectionType"] then
        delete_all_wan_for_link("PPP_Routed", wanconndev, data)
        delete_all_wan_for_link("IP_Routed", wanconndev, data)
    else
        -- Delete conflicted IP_Routed WAN now ...
        delete_all_wan_for_link("IP_Routed", wanconndev, data)
    end
end


function checkPppPassword(data)
    if data["Password"] and "PPP_Routed" == data["ConnectionType"] then
        if _G["defaultPasswd"] == data["Password"] then
            appenderror("Password", "wan.Password_notinit_err")
            return false
        end
    end 
    return true
end

function update_single_wan(data, wanconndev, isDefault, wandevs)
    luadbg("\nUpdate wan connection ["..data["ID"].."] with new conndev ["..wanconndev.."]")
    if "Bridged" == data["ConnectionType"] and "Other" ~= data["ServiceList"] then
        data["ServiceList"] = "INTERNET"
    end

    local paras = build_wan_parameters(data, data["ID"], wandevs)
    if not paras then
        return ""
    end

    if get_wan_conn_dev_of_wan(data["ID"]) ~= wanconndev then		
        -- Delete previous wan first
        luadbg("Wan conn dev changed, previous wan should be deleted.")
		
	-- Let process run to the place of post password
        -- if false == checkPppPassword(data) then
           -- return ""
        -- end
		
        safe_delete_wan(data["ID"])

        if isDefault then
            --default_wan_pre_action(data, wanconndev)
        end

        -- Add a new wan connection for the newly created wan conn dev.
        return add_new_wan_to_wan_conn_dev(data, wanconndev, wandevs)
    end

    luadbg("Wan conn dev does not changed ...")
    -- Get previous wan connection type
    local err, values = dm.GetParameterValues(data["ID"], {"ConnectionType", 
        });
    if 0 ~= err then
        luadbg("Can not get previous wan info")
        return ""
    end
    local prevWan = values[data["ID"]]
    local prevIPType = get_ip_conn_type(data["ID"], prevWan["ConnectionType"])

    if isDefault then
        -- Check tunnel
        --default_wan_pre_action(data, wanconndev)
    end

    -- Connection Type does not change, just set parameters
    if prevIPType == data["ConnectionType"] then
        luadbg("Connection type does not change, just update paramters.")
        local errcode, NeedReboot, paramerr =  dm.SetParameterValues(paras)

        if 0 ~= errcode then
            if "IP_Routed" == data["ConnectionType"] then
                if false == responseErrorcode(errcode,paramerr,ipmaps) then
                    appenderror("con", "wan.too_many_err")
                end
            else
                if false == responseErrorcode(errcode,paramerr,pppmaps) then
                    appenderror("con", "wan.too_many_err")
                end
            end
        
            print("errcode is "..tostring(errcode))
            return ""
        end
        return data["ID"]
    end

    if "Bridged" == prevIPType then
        add_one_wan_parameter(paras, "DNSEnabled", true, data["ID"])
    end

    if isDefault and ("Bridged" == prevIPType or "Bridged" == data["ConnectionType"]) then
        -- From bridge to routed or routed to bridge
        luadbg("Bridge mode changed, do some compensate ...")
        bridge_auto_fill(data, prevIPType)
        if "Bridged" == data["ConnectionType"] then
            -- If it is changing to bridge, other bridges will also be deleted.
            luadbg("Delete existing bridges for ["..wanconndev.."]")
            delete_all_bridges_for_link(wanconndev, data["LowerLayer"])
        end
    end

    if "IP_Routed" == prevIPType or "IP_Routed" == data["ConnectionType"] then
        -- First delete previous wan connection, then add new wan
        luadbg("IPoE mode changed, we should delete then add ...")
        -- if false == checkPppPassword(data) then
        --     return ""
        -- end
        dm.DeleteObject(data["ID"])
        return add_new_wan_to_wan_conn_dev(data, wanconndev, wandevs)
    end

    luadbg("Other connection type changed, update parameters directly ...")  
    local errcode, NeedReboot, paramerr =  dm.SetParameterValues(paras)

    if 0 ~= errcode then
        if "IP_Routed" == data["ConnectionType"] then
            if false == responseErrorcode(errcode,paramerr,ipmaps) then
                appenderror("con", "wan.too_many_err")
            end
        else
            if false == responseErrorcode(errcode,paramerr,pppmaps) then
                appenderror("con", "wan.too_many_err")
            end
        end
        
        print("errcode is "..tostring(errcode))
        return ""
    end
    return data["ID"]
end


----- IPTV bridge related utilities
function get_iptv_bridge(bridges)
    for k,v in pairs(bridges) do
        if "4" == tostring(v["X_Type"]) then
            return v["BridgeKey"],k
        end
    end
    return -1,""
end

function get_intf_by_ref(intfs, intf_ref)
    for k,v in pairs(intfs) do
        if strip_end_dot(intf_ref) == tostring(v["InterfaceReference"]) then
            return v
        end
    end
    return nil
end

function get_intf_by_key(intfs, intf_key)
    for k,v in pairs(intfs) do
        if tostring(intf_key) == tostring(v["AvailableInterfaceKey"]) then
            return v
        end
    end
    return nil
end

function get_intf_key_by_lan_alias(intfs, LANAlias)
    for k,v in pairs(intfs) do
        if strip_end_dot(LANAlias) == v["X_InterfaceAlias"] then
            return v["AvailableInterfaceKey"]
        end
    end
    return -1
end

function get_lan_alias_by_intf_key(intfs, intf_key)
    for k,v in pairs(intfs) do
        if tostring(intf_key) == tostring(v["AvailableInterfaceKey"]) then
            return v["X_InterfaceAlias"]
        end
    end
    return ""
end

function get_filter_by_intf_key(filters, intf_key)
    for k,v in pairs(filters) do
        if tostring(intf_key) == tostring(v["FilterInterface"]) then
            return k
        end
    end
    return ""
end



function is_same_mode(curmode, wanmode)
    return true
end




