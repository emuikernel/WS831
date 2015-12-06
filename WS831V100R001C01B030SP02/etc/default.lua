local GetParamValues = dm.GetParameterValues
local SetDBParamValues = dm.setdbparavalues
local SetConfigTool  = dm.setconfigtool
local DBRestore      = mic.dbrestore
local DBSave         = dm.dbsave
local ChangeDest     = mic.changemsgdest
local GetValues      = mic.bahlgetvalues
local Detect 	     = mic.detectequipment
local print          = print

function luadbg(str)
	print(str)
end

-- {domain1={param1, parma2, parma3}}, domain2={parma1},...}
function restoreParameters(params)
	local restoreValues = {}
	-- get param values
	for k, v in pairs(params) do
		SetConfigTool(v['cfgtool'])
		local retval, values = GetParamValues(v['domain'], v['params'])
		if values == nil then
			print("get paramvalue err.", v['domain'], v['params'], retval)
		else
			-- print("get paramvalue ok.", v['domain'], values)
			local newValue = {}
			newValue['cfgtool'] = v['cfgtool']
			newValue['value'] = values
			table.insert(restoreValues, newValue)
		end
	end

	-- restore db
	restorecode = DBRestore()
	if 0 ~= restorecode then
		luadbg("restore db error.")
		return
	end
	
	for kv, val in pairs(restoreValues) do
		SetConfigTool(val['cfgtool'])
		for domain, v1 in pairs(val['value']) do
			for param, v2 in pairs(v1) do
				if param ~= 'ObjAcc' then
					retCode = SetDBParamValues(domain..param, v2)
					--luadbg("SetDBParamValues "..domain..param.."=" ..v2)
				end
			end
		end
	end

end

-- define recover params
local recoverParas = {
	{ cfgtool='cms', domain='InternetGatewayDevice.X_Cloud.', params={'UserID','Secret','DeviceToken','UserName'}}
}

ChangeDest('cms')

-- step1 : restore paramters
luadbg("restore paramters")
restoreParameters(recoverParas)

-- step2: invoke mic detect to set param from equipment
luadbg("detect")
Detect()

-- step3: save to flash
luadbg("save db")
DBSave()

