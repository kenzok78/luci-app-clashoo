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
s = k:section(TypedSection, "clash", "在线下载")
s.anonymous = true
o = s:option(ListValue, "dcore", "下载内核")
o.default = "3"
o:value("2", "mihomo（稳定版）")
o:value("3", "Alpha（预发布）")



local cpu_model=SYS.exec("opkg status libc 2>/dev/null |grep 'Architecture' |awk -F ': ' '{print $2}' 2>/dev/null")
o = s:option(ListValue, "download_core", "架构类型")
o.description = translate("CPU Model")..': '..font_green..bold_on..cpu_model..bold_off..font_off..' '
o.default = "x86_64"
o:value("aarch64_cortex-a53")
o:value("aarch64_generic")
o:value("arm_cortex-a7_neon-vfpv4")
o:value("mipsel_24kc")
o:value("mips_24kc")
o:value("x86_64")
o:value("riscv64")

o = s:option(Value, "core_mirror_prefix", "下载镜像前缀（可选）")
o.rmempty = true
o.placeholder = "https://gh-proxy.com/"
o.description = "留空默认直连 GitHub；可填写镜像前缀提升下载稳定性"


o=s:option(Button,"down_core")
o.inputtitle = "保存并应用"
o.title = luci.util.pcdata("保存并应用")
o.inputstyle = "reload"
o.write = function()
  k.uci:commit("clash")
end

o = s:option(Button,"download")
o.title = "下载"
o.template = "clash/core_check"


return m, k
