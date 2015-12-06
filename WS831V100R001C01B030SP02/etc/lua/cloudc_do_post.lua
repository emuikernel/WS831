local print = print
local utils = require('utils')
local cloudc = require('cloudc')
local _G = _G
local api = _G["FormData"]["API"]

errcode = {}
--err = {}
local apicontent = cloudc.getapicontent(api)
local proxyresponse = utils.getRequest()
request = proxyresponse["body"]
csrf = request["csrf"]
data = request["data"]
action = request["action"]
cfgtool = "cloudc"


if apicontent == nil then
	utils.appenderror("errcode", 1)
else
	prog = loadstring(apicontent);
	if prog then
		prog()
	else
		print(api.." format error.")
	end

	if api == "/html/api/device/pipe.lua" then 
		return
	end

	-- conflict csrf error
	if _G["errcode"]["errcode"] == 1 then
		_G["errcode"]["errcode"] = 1001
	end
	if _G["errcode"]["errcode"] == 9004 then
		utils.appenderror("", "9004")
	end 
end

cfgtool = ""

utils.appenderror("csrf_param", "cloudc_test_csrf_param")
utils.appenderror("csrf_token", "cloudc_test_csrf_token")
utils.responserror()
