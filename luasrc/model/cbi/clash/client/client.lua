local NXFS = require "nixio.fs"
local SYS  = require "luci.sys"
local HTTP = require "luci.http"
local DISP = require "luci.dispatcher"
local UTIL = require "luci.util"
local uci = require("luci.model.uci").cursor()
local fs = require "luci.clash"
local clash = "clash"


m = Map("clash")
m.description = [[
<style>
#cbi-clash-config-Apply .cbi-value-field,
#cbi-clash-config-action .cbi-value-field {
	width: 100%;
}

#cbi-clash-config-Apply .cbi-value-field .cbi-button {
	min-width: 180px;
}

@media only screen and (max-width: 900px) {
	#cbi-clash-config-Apply .cbi-value-title,
	#cbi-clash-config-Apply .cbi-value-field,
	#cbi-clash-config-action .cbi-value-title,
	#cbi-clash-config-action .cbi-value-field {
		display: block;
		width: 100% !important;
	}

	#cbi-clash-config-Apply .cbi-value-field .cbi-button {
		width: 100%;
		height: 42px;
		margin: 0;
	}

	#cbi-clash-config-action .cbi-value-field {
		width: 100% !important;
	}
}
</style>
]]
s = m:section(TypedSection, "clash")
s.anonymous = true
m.pageaction = false

o = s:option(ListValue, "core", "内核")
o.default = "3"
o:value("2", "mihomo（稳定版）")
o:value("3", "Alpha（预发布）")




o = s:option(ListValue, "append_rules", "附加自定义规则")
o.default = "0"
o:value("0", translate("Disable"))
o:value("1", translate("Enable"))
o.description = "在“设置 > 其它设置”中配置的自定义规则，在客户端启动时生效"

o = s:option(Button, "Apply")
o.title = luci.util.pcdata("保存并应用")
o.inputtitle = "保存并应用"
o.inputstyle = "apply"
o.write = function()
  m.uci:commit("clash")
end

o = s:option(Button,"action")
o.title = "操作"
o.template = "clash/start_stop"


return m
