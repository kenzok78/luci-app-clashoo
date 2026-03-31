
local NXFS = require "nixio.fs"
local SYS  = require "luci.sys"

local function geoip_update_time()
	if NXFS.access("/etc/clash/Country.mmdb") then
		return SYS.exec("ls -l --full-time /etc/clash/Country.mmdb | awk '{print $6, $7}'")
	end
	return "-"
end

m = Map("clash")
s = m:section(TypedSection, "clash", "在线更新 GeoIP 数据库")
m.pageaction = false
s.anonymous = true
s.addremove = false
s.description = "参考 Nikki 的 GeoX 思路做了简化：默认配置即可，直接点下载就能更新。"

o = s:option(Flag, "auto_update_geoip", "自动更新")
o.description = "默认关闭；开启后按周期自动更新"

o = s:option(ListValue, "auto_update_geoip_time", "自动更新时间（每天）")
for t = 0, 23 do
	o:value(t, t .. ":00")
end
o.default = 3
o:depends("auto_update_geoip", "1")

o = s:option(Value, "geoip_update_interval", "自动更新周期（天）")
o.datatype = "uinteger"
o.default = 7
o.rmempty = false
o.description = "例如 7 表示每 7 天更新一次"
o:depends("auto_update_geoip", "1")

o = s:option(ListValue, "geoip_source", "GeoIP 来源")
o:value("2", "简化默认源（推荐）")
o:value("3", "OpenClash 社区源")
o:value("1", "MaxMind 官方")
o:value("4", "自定义订阅")
o.default = "2"

o = s:option(ListValue, "geoip_format", "GeoIP 格式")
o:value("mmdb", "MMDB（推荐）")
o:value("dat", "DAT")
o.default = "mmdb"
o.description = "默认 MMDB，一般不需要改"

o = s:option(ListValue, "geodata_loader", "GeoData 加载模式")
o:value("standard", "标准")
o:value("memconservative", "节省内存")
o.default = "standard"
o.description = "内存较小设备可选“节省内存”"

o = s:option(Value, "license_key", "MaxMind 授权密钥")
o.description = "仅 MaxMind 来源需要：https://www.maxmind.com/en/geolite2/signup"
o.rmempty = true
o:depends("geoip_source", "1")

o = s:option(Value, "geoip_mmdb_url", "GeoIP（MMDB）订阅")
o.rmempty = true
o.placeholder = "https://raw.githubusercontent.com/alecthw/mmdb_china_ip_list/release/Country.mmdb"
o.description = "默认可不改，建议保留"
o:depends("geoip_source", "2")
o:depends("geoip_source", "4")

o = s:option(Value, "geosite_url", "GeoSite 订阅链接")
o.rmempty = true
o.placeholder = "https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat"
o:depends("geoip_source", "2")
o:depends("geoip_source", "3")
o:depends("geoip_source", "4")

o = s:option(Value, "geoip_dat_url", "GeoIP（DAT）订阅")
o.rmempty = true
o.placeholder = "https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geoip.dat"
o:depends("geoip_source", "2")
o:depends("geoip_source", "3")
o:depends("geoip_source", "4")

o = s:option(Value, "geoip_asn_url", "GeoIP（ASN）订阅")
o.rmempty = true
o.placeholder = "https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/GeoLite2-ASN.mmdb"
o:depends("geoip_source", "2")
o:depends("geoip_source", "4")

o = s:option(DummyValue, "_geoip_last_update", "上次更新时间")
o.rawhtml = true
o.cfgvalue = function()
	local t = geoip_update_time():gsub("\n", "")
	if t == "" then
		t = "-"
	end
	return "<strong>" .. t .. "</strong>"
end

o = s:option(Button, "update_geoip")
o.inputtitle = "保存并应用"
o.title = luci.util.pcdata("保存并应用")
o.inputstyle = "reload"
o.write = function()
	m.uci:commit("clash")
end

o = s:option(Button, "download")
o.title = "下载"
o.template = "clash/geoip"

return m
