local print = print
local html = require "html"
local web = require "web"
local utils = require('utils')
local _G = _G
local print = print

local api = _G["FormData"]["API"]

local apicontent = web.getrawfile(api)
request = utils.getRequest()

data = request["data"]
action = request["action"]

print("\n\n=================", action," for "..api.."=========")

errcode = {}
--err = {}


if apicontent == nil then
	utils.appenderror("errcode", 1)
else
	prog = loadstring(apicontent)
	if prog then
		prog()
	else
		print(api.." format error.")
	end
	-- conflict csrf error
	if _G["errcode"]["errcode"] == 1 then
		_G["errcode"]["errcode"] = 1001
	end
	if _G["errcode"]["errcode"] == 9004 then
		utils.appenderror("", "9004")
	end 
end
utils.responserror()

	



