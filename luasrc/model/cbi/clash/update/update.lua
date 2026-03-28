local NXFS = require "nixio.fs"
local SYS  = require "luci.sys"
local HTTP = require "luci.http"
local DISP = require "luci.dispatcher"
local UTIL = require "luci.util"
local uci = require("luci.model.uci").cursor()
local m , r, k
local http = luci.http

font_red = [[<font color="red">]]
font_green = [[<font color="green">]]
font_off = [[</font>]]
bold_on  = [[<strong>]]
bold_off = [[</strong>]]



m = Map("clash")
m:section(SimpleSection).template  = "clash/update"
m.pageaction = false

k = Map("clash")
s = k:section(TypedSection, "clash",translate("Download Online"))
s.anonymous = true
o = s:option(ListValue, "dcore", translate("Core Type"))
o.default = "3"
o:value("1", translate("clash"))
o:value("2", translate("clash meta"))
o:value("3", translate("mihomo"))



local cpu_model=SYS.exec("opkg status libc 2>/dev/null |grep 'Architecture' |awk -F ': ' '{print $2}' 2>/dev/null")
o = s:option(ListValue, "download_core", translate("Select Core"))
o.description = translate("CPU Model")..': '..font_green..bold_on..cpu_model..bold_off..font_off..' '
o.default = "x86_64"
o:value("aarch64_cortex-a53")
o:value("aarch64_generic")
o:value("arm_cortex-a7_neon-vfpv4")
o:value("mipsel_24kc")
o:value("mips_24kc")
o:value("x86_64")
o:value("riscv64")


o=s:option(Button,"down_core")
o.inputtitle = translate("Save & Apply")
o.title = luci.util.pcdata(translate("Save & Apply"))
o.inputstyle = "reload"
o.write = function()
  k.uci:commit("clash")
end

o = s:option(Button,"download")
o.title = translate("Download")
o.template = "clash/core_check"


return m, k
