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

o = s:option(ListValue, "core", translate("Core"))
o.default = "3"
o:value("1", translate("clash"))
o:value("2", translate("clash meta"))
o:value("3", translate("mihomo"))




o = s:option(ListValue, "append_rules", translate("Append Customs Rules"))
o.default = "0"
o:value("0", translate("Disable"))
o:value("1", translate("Enable"))
o.description = translate("Set custom rules under Setting=>Others , will take effect when client start")

o = s:option(Button, "Apply")
o.title = luci.util.pcdata(translate("Save & Apply"))
o.inputtitle = translate("Save & Apply")
o.inputstyle = "apply"
o.write = function()
  m.uci:commit("clash")
end

o = s:option(Button,"action")
o.title = translate("Operation")
o.template = "clash/start_stop"


return m
