local html = require "html"
local web = require "web"
local getlayout = web.getlayout

local loadfile  = loadfile

local cache = {}

layout, content = getlayout()
if layout == nil then
	-- no layout , direct to excute content
	prog = loadstring(content)
else
	-- do layout
	--ignor layout self to slove death cycle
	local startl, endl = string.find(content, "html.yield()")
	if startl ~= nil and endl ~= nil then
		return 
	end
	html.setYieldContent(content)
	local f, err = cache[layout]
	if f == nil then 
		f = web.getfile(layout)
		cache[layout] = f
	end
	prog = loadstring(f)
end
prog()