
local NXFS = require "nixio.fs"
local SYS  = require "luci.sys"
local HTTP = require "luci.http"
local DISP = require "luci.dispatcher"
local UTIL = require "luci.util"
local uci = luci.model.uci.cursor()
local fs = require "luci.clash"
local http = luci.http
local clash = "clash"

kk = Map(clash)
s = kk:section(TypedSection, "clash", translate("Auto Update Config"))
s.anonymous = true
kk.pageaction = false

o = s:option(Flag, "auto_update", translate("Auto Update"))
o.description = translate("Auto Update Server subscription")

o = s:option(ListValue, "auto_update_time", "更新时间")
o:value("1", "每小时")
o:value("6", "每6小时")
o:value("12", "每12小时")
o:value("24", "每24小时")
o.description = translate("Daily Server subscription update time. Only update config in use")

o = s:option(Button, "Apply")
o.title = luci.util.pcdata(translate("Save & Apply"))
o.inputtitle = translate("Save & Apply")
o.inputstyle = "apply"
o.write = function()
  kk.uci:commit("clash")
end




m = Map("clash")
s = m:section(TypedSection, "clash" , translate("Clear Clash Log"))
s.anonymous = true

o = s:option(Flag, "auto_clear_log", translate("Auto Clear Log"))
o.description = translate("Auto Clear Log")


o = s:option(ListValue, "clear_time", "清除时间")
o:value("1", "每小时")
o:value("6", "每6小时")
o:value("12", "每12小时")
o:value("24", "每24小时")
o.description = translate("Clear Log Time")

o=s:option(Button,"clear_clear")
o.inputtitle = translate("Save & Apply")
o.title = luci.util.pcdata(translate("Save & Apply"))
o.inputstyle = "reload"
o.write = function()
  m.uci:commit("clash")
end




w = Map("clash")
s = w:section(TypedSection, "clash" , translate("Load Groups"))
s.anonymous = true


o = s:option(Button, "Load") 
o.inputtitle = translate("Load Groups")
o.title = translate("Load Groups")
o.inputstyle = "apply"
o.write = function()
  w.uci:commit("clash")
  luci.sys.call("bash /usr/share/clash/load_groups.sh >/dev/null 2>&1 &")
  luci.sys.call("sleep 4")
  HTTP.redirect(luci.dispatcher.build_url("admin", "services", "clash", "settings", "other"))   
end


r = w:section(TypedSection, "conf_groups", translate("Policy Groups"))
r.anonymous = true
r.addremove = false
r.sortable = false
r.template = "cbi/tblsection"
function r.create(...)
	local sid = TypedSection.create(...)
	if sid then
		luci.http.redirect(r.extedit % sid)
		return
	end
end

o = r:option(DummyValue, "type", translate("Group Type"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or translate("None")
end


o = r:option(DummyValue, "name", translate("Group Name"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or translate("None")
end



y = Map("clash")
x = y:section(TypedSection, "addtype", translate("Custom Rules"))
x.anonymous = true
x.addremove = true
x.sortable = false
x.template = "cbi/tblsection"
x.extedit = luci.dispatcher.build_url("admin/services/clash/ip-rules/%s")
function x.create(...)
	local sid = TypedSection.create(...)
	if sid then
		luci.http.redirect(x.extedit % sid)
		return
	end
end

o = x:option(DummyValue, "type", translate("Rule Type"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or translate("None")
end

o = x:option(DummyValue, "ipaaddr", translate("IP/Domain/Address/Keyword/Port"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or translate("None")
end


o = x:option(DummyValue, "pgroup", translate("Policy Groups"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or translate("None")
end




return kk, m,w,y
