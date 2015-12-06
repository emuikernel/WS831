local print = print
local html = require "html"
local web = require "web"
local utils = require('utils')
local _G = _G
local print = print

local api = _G["FormData"]["API"]

local apicontent = web.getfile(api)
request = utils.getRequest()
if request and request == "error" then	
	local param, token = web.getcsrf()
	utils.appenderror("csrf_param", param)
	utils.appenderror("csrf_token", token)	
	utils.appenderror("errcode", "9007")
	utils.responserror()
	return 
end
csrf = request["csrf"]
data = request["data"]
action = request["action"]

print("\n\n=================", action," for "..api.."=========")

errcode = {}
--err = {}

function checkcsrf()
    if api == "/api/hilink/smartconfig.lua" or api == "/api/device/pipe.lua" then 
        return 0
    end
    local csrf = _G["request"]["csrf"]
    local param = csrf["csrf_param"]
    local token = csrf["csrf_token"]
    return web.checkcsrf(param, token)
end

if apicontent == nil then
	utils.appenderror("errcode", 1)
else
	-- check csrf
	err = checkcsrf()
	--err = 0
	if err ~= 0 then
		utils.appenderror("errcode", 1)
		utils.appenderror('csrf', 'Menu.csrf_err')
		local name, level = web.getuserinfo()
		if level == 0 or api == '/api/system/user_login.lua' or api == '/api/system/user_login_smallsys.lua' then
			local param, token = web.getcsrf()
			utils.appenderror("csrf_param", param)
			utils.appenderror("csrf_token", token)
		end
	else
		prog = loadstring(apicontent)
		if prog then
			prog()
		else
			print(api.." format error.")
		end

		if api == "/api/device/pipe.lua" then 
			return
		end

		-- conflict csrf error
		if _G["errcode"]["errcode"] == 1 then
			_G["errcode"]["errcode"] = 1001
		end
		if _G["errcode"]["errcode"] == 9004 then
			utils.appenderror("", "9004")
		end 
		local param, token = web.getcsrf()
		utils.appenderror("csrf_param", param)
		utils.appenderror("csrf_token", token)
	end
end
utils.responserror()

	



