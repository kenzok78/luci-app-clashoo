local NXFS = require "nixio.fs"
local SYS  = require "luci.sys"
local uci = require("luci.model.uci").cursor()

m = Map("clash")
s = m:section(TypedSection, "clash", "入站设置")
m.pageaction = false
s.anonymous = true
s.description = "参考 Nikki 入站配置布局，按需修改端口即可。"

o = s:option(Value, "http_port")
o.title = "HTTP 代理端口"
o.default = 8080
o.datatype = "port"
o.rmempty = false

o = s:option(Value, "socks_port")
o.title = "SOCKS 代理端口"
o.default = 1080
o.datatype = "port"
o.rmempty = false

o = s:option(Value, "redir_port")
o.title = "TCP 转发端口"
o.default = 7891
o.datatype = "port"
o.rmempty = false

o = s:option(Value, "mixed_port")
o.title = "混合端口（HTTP(S)/SOCKS5）"
o.default = 7890
o.datatype = "port"
o.rmempty = false

o = s:option(Value, "tproxy_port")
o.title = "UDP 转发端口"
o.default = 7892
o.datatype = "port"
o.rmempty = false

o = s:option(ListValue, "allow_lan")
o.title = "允许局域网访问"
o.default = true
o.rmempty = false
o:value("true", "启用")
o:value("false", "禁用")

o = s:option(ListValue, "enable_ipv6")
o.title = "启用 IPv6"
o.default = false
o.rmempty = false
o:value("true", "启用")
o:value("false", "禁用")

o = s:option(Value, "bind_addr")
o.title = "监听地址"
o:value("*",  "绑定所有 IP 地址")
luci.ip.neighbors({ family = 4 }, function(entry)
       if entry.reachable then
               o:value(entry.dest:string())
       end
end)
luci.ip.neighbors({ family = 6 }, function(entry)
       if entry.reachable then
               o:value(entry.dest:string())
       end
end)
o:depends("allow_lan", "true")


o = s:option(Value, "dash_port")
o.title = "外部控制监听端口"
o.default = 9090
o.datatype = "port"
o.rmempty = false

o = s:option(Value, "dash_pass")
o.title = "外部控制密钥"
o.default = 123456
o.rmempty = false

o = s:option(ListValue, "level", "日志级别")
o.title = "日志级别"
o.description = "选择日志级别"
o:value("info", "信息")
o:value("silent", "静默")
o:value("warning", "警告")
o:value("error", "错误")
o:value("debug", "调试")

o = s:option(Button, "Apply")
o.title = luci.util.pcdata("保存并应用")
o.inputtitle = "保存并应用"
o.inputstyle = "apply"
o.write = function()
m.uci:commit("clash")
if luci.sys.call("pidof clash >/dev/null || pidof mihomo >/dev/null || pidof clash-meta >/dev/null") == 0 then
	SYS.call("/etc/init.d/clash restart >/dev/null 2>&1 &")
        luci.http.redirect(luci.dispatcher.build_url("admin", "services", "clash"))
else
  	luci.http.redirect(luci.dispatcher.build_url("admin", "services", "clash" , "settings", "port"))
end
end

return m
