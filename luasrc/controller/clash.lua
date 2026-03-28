module("luci.controller.clash", package.seeall)
local fs=require"nixio.fs"
local http=require"luci.http"
local uci=require"luci.model.uci".cursor()



function index()

	if not nixio.fs.access("/etc/config/clash") then
		return
	end

	-- luci 24.10+ 通过 menu.d JSON 注册菜单，此处只保留 API 路由
	local has_menu_d = nixio.fs.access("/usr/share/luci/menu.d/luci-app-clash.json")
	if not has_menu_d then
		local page = entry({"admin", "services", "clash"},alias("admin", "services", "clash", "overview"), _("Clash"), 1)
		page.dependent = true
		page.acl_depends = {"luci-app-clash"}

		entry({"admin", "services", "clash", "overview"},cbi("clash/overview"),_("Overview"), 10).leaf = true
		entry({"admin", "services", "clash", "client"},cbi("clash/client/client"),_("Client"), 20).leaf = true

		entry({"admin", "services", "clash", "config"}, firstchild(),_("Config"), 25)
		entry({"admin", "services", "clash", "config", "import"},cbi("clash/config/import"),_("Import Config"), 25).leaf = true
		entry({"admin", "services", "clash", "config", "config"},cbi("clash/config/config"),_("Select Config"), 30).leaf = true
		entry({"admin", "services", "clash", "config", "create"},cbi("clash/config/create"),_("Create Config"), 35).leaf = true
		entry({"admin", "services", "clash", "proxyprovider"},cbi("clash/config/proxy_provider"), nil).leaf = true
		entry({"admin", "services", "clash", "servers"},cbi("clash/config/servers-config"), nil).leaf = true
		entry({"admin", "services", "clash", "ruleprovider"},cbi("clash/config/rule_provider"), nil).leaf = true
		entry({"admin", "services", "clash", "rules"},cbi("clash/config/rules"), nil).leaf = true
		entry({"admin", "services", "clash", "pgroups"},cbi("clash/config/groups"), nil).leaf = true
		entry({"admin", "services", "clash", "rulemanager"},cbi("clash/config/ruleprovider_manager"), nil).leaf = true

		entry({"admin", "services", "clash", "settings"}, firstchild(),_("Settings"), 40)
		entry({"admin", "services", "clash", "settings", "port"},cbi("clash/dns/port"),_("Proxy Ports"), 60).leaf = true
		entry({"admin", "services", "clash", "settings", "geoip"},cbi("clash/geoip/geoip"),_("Update GeoIP"), 80).leaf = true
		entry({"admin", "services", "clash", "settings", "other"},cbi("clash/other"),_("Other Settings"), 92).leaf = true
		entry({"admin", "services", "clash", "ip-rules"},cbi("clash/config/ip-rules"), nil).leaf = true
		entry({"admin", "services", "clash", "settings", "dns"},firstchild(),_("DNS Settings"), 65)
		entry({"admin", "services", "clash", "settings", "dns", "dns"},cbi("clash/dns/dns"),_("Clash DNS"), 70).leaf = true
		entry({"admin", "services", "clash", "settings", "dns", "advance"},cbi("clash/dns/advance"),_("Advance DNS"), 75).leaf = true

		entry({"admin", "services", "clash", "update"},cbi("clash/update/update"),_("Update"), 45).leaf = true
		entry({"admin", "services", "clash", "log"},cbi("clash/logs/log"),_("Log"), 50).leaf = true
	end

	-- API 路由（两版本都需要）
	entry({"admin","services","clash","check_status"},call("check_status")).leaf=true
	entry({"admin", "services", "clash", "ping"}, call("act_ping")).leaf=true
	entry({"admin", "services", "clash", "readlog"},call("action_read")).leaf=true
	entry({"admin","services","clash", "status"},call("action_status")).leaf=true
	entry({"admin", "services", "clash", "check"}, call("check_update_log")).leaf=true
	entry({"admin", "services", "clash", "doupdate"}, call("do_update")).leaf=true
	entry({"admin", "services", "clash", "start"}, call("do_start")).leaf=true
	entry({"admin", "services", "clash", "stop"}, call("do_stop")).leaf=true
	entry({"admin", "services", "clash", "reload"}, call("do_reload")).leaf=true
	entry({"admin", "services", "clash", "set_mode"}, call("do_set_mode")).leaf=true
	entry({"admin", "services", "clash", "list_configs"}, call("action_list_configs")).leaf=true
	entry({"admin", "services", "clash", "set_config"}, call("do_set_config")).leaf=true
	entry({"admin", "services", "clash", "set_panel"}, call("do_set_panel")).leaf=true
	entry({"admin", "services", "clash", "geo"}, call("geoip_check")).leaf=true
	entry({"admin", "services", "clash", "geoipupdate"}, call("geoip_update")).leaf=true
	entry({"admin", "services", "clash", "check_geoip"}, call("check_geoip_log")).leaf=true	
	entry({"admin", "services", "clash", "corelog"},call("down_check")).leaf=true
	entry({"admin", "services", "clash", "logstatus"},call("logstatus_check")).leaf=true
	entry({"admin", "services", "clash", "conf"},call("action_conf")).leaf=true
	entry({"admin", "services", "clash", "update_config"},call("action_update")).leaf=true
	entry({"admin", "services", "clash", "game_rule"},call("action_update_rule")).leaf=true
	entry({"admin", "services", "clash", "ruleproviders"},call("action_update_rule_providers")).leaf=true
	entry({"admin", "services", "clash", "ping_check"},call("action_ping_status")).leaf=true
	
end

local fss = require "luci.clash"

local function download_rule_provider()
	local filename = luci.http.formvalue("filename")
  	local status = luci.sys.call(string.format('/usr/share/clash/create/clash_rule_provider.sh "%s" >/dev/null 2>&1',filename))
  	return status
end


function action_update_rule_providers()
	luci.http.prepare_content("application/json")
	luci.http.write_json({
	rulep = download_rule_provider();
})
end


local function uhttp_port()
	local uhttp_port = luci.sys.exec("uci get uhttpd.main.listen_http |awk -F ':' '{print $NF}'")
	if uhttp_port ~= "80" then
		return ":" .. uhttp_port
	end
end

local function download_rule()
	local filename = luci.http.formvalue("filename")
	local rule_file_dir="/usr/share/clash/rules/g_rules/" .. filename
        luci.sys.call(string.format('sh /usr/share/clash/clash_game_rule.sh "%s" >/dev/null 2>&1',filename))
	if not fss.isfile(rule_file_dir) then
		return "0"
	else
		return "1"
	end
end

function action_update_rule()
	luci.http.prepare_content("application/json")
	luci.http.write_json({
	game_rule = download_rule()
})
end

function action_update()
	luci.sys.exec("kill $(pgrep /usr/share/clash/update.sh) ; (bash /usr/share/clash/update.sh >/usr/share/clash/clash.txt 2>&1) &")
end


local function in_use()
	return luci.sys.exec("uci get clash.config.config_type")
end


local function conf_path()
	if nixio.fs.access(string.sub(luci.sys.exec("uci get clash.config.use_config"), 1, -2)) then
	return fss.basename(string.sub(luci.sys.exec("uci get clash.config.use_config"), 1, -2))
	else
	return ""
	end
end



local function typeconf()
	return luci.sys.exec("uci get clash.config.config_type")
end

local function list_configs()
	local configs = {}
	for path in nixio.fs.glob('/usr/share/clash/config/sub/*.yaml') do
		configs[#configs + 1] = fss.basename(path)
	end
	for path in nixio.fs.glob('/usr/share/clash/config/upload/*.yaml') do
		configs[#configs + 1] = fss.basename(path)
	end
	table.sort(configs)
	return configs
end


function action_conf()
	luci.http.prepare_content("application/json")
	luci.http.write_json({
	conf_path = conf_path(),
	typeconf = typeconf(),
	configs = list_configs()

	})
end

function action_list_configs()
	luci.http.prepare_content("application/json")
	luci.http.write_json({ configs = list_configs(), current = conf_path() })
end


local function dash_port()
	return luci.sys.exec("uci get clash.config.dash_port 2>/dev/null")
end
local function dash_pass()
	return luci.sys.exec("uci get clash.config.dash_pass 2>/dev/null")
end

local function selected_core_bin()
	local core = luci.sys.exec("uci get clash.config.core 2>/dev/null")
	core = core and core:gsub("\n", "") or ""
	if core == "1" then
		if nixio.fs.access("/etc/clash/clash") then return "/etc/clash/clash" end
		if nixio.fs.access("/usr/bin/clash") then return "/usr/bin/clash" end
	elseif core == "2" then
		if nixio.fs.access("/usr/bin/clash-meta") then return "/usr/bin/clash-meta" end
		if nixio.fs.access("/etc/clash/clash-meta") then return "/etc/clash/clash-meta" end
		if nixio.fs.access("/usr/bin/mihomo") then return "/usr/bin/mihomo" end
	else
		if nixio.fs.access("/usr/bin/mihomo") then return "/usr/bin/mihomo" end
		if nixio.fs.access("/etc/clash/clash") then return "/etc/clash/clash" end
	end
	return ""
end

local function dashboard_panel()
	return luci.sys.exec("uci get clash.config.dashboard_panel 2>/dev/null")
end

local function binary_version(path)
	if nixio.fs.access(path) then
		return luci.sys.exec(path .. " -v 2>/dev/null | awk 'NR==1 { if ($1 == \"Mihomo\") print $3; else print $2 }'")
	end
	return "0"
end

local function clash_binary_core()
	return binary_version("/etc/clash/clash")
end

local function clash_meta_core()
	if nixio.fs.access("/usr/bin/clash-meta") then
		return binary_version("/usr/bin/clash-meta")
	end
	return binary_version("/etc/clash/clash-meta")
end

local function mihomo_core()
	return binary_version("/usr/bin/mihomo")
end

local function new_mihomo_version()
	return luci.sys.exec("sed -n 1p /usr/share/clash/new_mihomo_core_version 2>/dev/null")
end

local function new_clash_meta_version()
	return luci.sys.exec("sed -n 1p /usr/share/clash/new_clash_meta_core_version 2>/dev/null")
end

local function is_running()
	return luci.sys.call("pidof clash >/dev/null || pidof mihomo >/dev/null || pidof clash-meta >/dev/null") == 0
end

local function is_web()
	return luci.sys.call("pidof clash >/dev/null || pidof mihomo >/dev/null || pidof clash-meta >/dev/null") == 0
end

local function localip()
	local ip = luci.sys.exec("uci -q get network.lan.ipaddr 2>/dev/null") or ""
	ip = ip:gsub("%s+", ""):gsub("/%d+$", "")
	if ip == "" then
		ip = luci.sys.exec("ip -4 -o addr show dev br-lan 2>/dev/null | awk '{print $4}' | sed -n '1p'") or ""
		ip = ip:gsub("%s+", ""):gsub("/%d+$", "")
	end
	return ip
end

local function check_version()
	return luci.sys.exec("sh /usr/share/clash/check_luci_version.sh")
end

local function check_core()
	return luci.sys.exec("sh /usr/share/clash/check_core_version.sh")
end


local function check_clashtun_core()
	return luci.sys.exec("sh /usr/share/clash/check_clashtun_core_version.sh")
end

local function current_version()
	return luci.sys.exec("sed -n 1p /usr/share/clash/luci_version")
end

local function new_version()
	return luci.sys.exec("sed -n 1p /usr/share/clash/new_luci_version")
end

local function new_core_version()
	return luci.sys.exec("sed -n 1p /usr/share/clash/new_core_version")
end


local function new_clashtun_core_version()
	return luci.sys.exec("sed -n 1p /usr/share/clash/new_clashtun_core_version")
end

local function check_dtun_core()
	return luci.sys.call(string.format("sh /usr/share/clash/check_dtun_core_version.sh"))
end

local function new_dtun_core()
	return luci.sys.exec("sed -n 1p /usr/share/clash/new_clashdtun_core_version")
end

local function e_mode()
	return luci.sys.exec("egrep '^ {0,}enhanced-mode' /etc/clash/config.yaml |grep enhanced-mode: |awk -F ': ' '{print $2}'")
end

local function mode_value()
	local tun = luci.sys.exec("uci get clash.config.tun_mode 2>/dev/null")
	tun = tun and tun:gsub("\n", "") or "0"
	if tun == "1" then
		return "tun"
	end
	return "fake-ip"
end

local function ping_enable()
	local v = luci.sys.exec("uci -q get clash.config.ping_enable 2>/dev/null") or ""
	v = v:gsub("%s+", "")
	if v == "" then
		return "0"
	end
	return v
end


local function clash_core()
	local version = luci.sys.exec([[
		for bin in /usr/bin/mihomo /usr/bin/clash-meta /etc/clash/clash; do
			[ -x "$bin" ] || continue
			ver=$($bin -v 2>/dev/null | awk 'NR==1 { if ($1 == "Mihomo") print $3; else print $2 }')
			[ -n "$ver" ] && { echo "$ver"; exit 0; }
		done
	]])

	if version ~= "" then
		return version
	end

	version = luci.sys.exec("sed -n 1p /usr/share/clash/core_version")
	return version ~= "" and version or "0"
end




local function clashtun_core()
	if nixio.fs.access("/etc/clash/clashtun/clash") then
		local tun=luci.sys.exec("/etc/clash/clashtun/clash -v 2>/dev/null |awk -F ' ' '{print $2}'")
		if tun ~= "" then
			return luci.sys.exec("/etc/clash/clashtun/clash -v 2>/dev/null |awk -F ' ' '{print $2}'")
		else 
			return luci.sys.exec("sed -n 1p /usr/share/clash/tun_version")
		end
	else
		return "0"
	end
end


local function dtun_core()
	if nixio.fs.access("/etc/clash/dtun/clash") then
		local tun=luci.sys.exec("/etc/clash/dtun/clash -v 2>/dev/null |awk -F ' ' '{print $2}'")
		if tun ~= "" then
			return luci.sys.exec("/etc/clash/dtun/clash -v 2>/dev/null |awk -F ' ' '{print $2}'")
		else 
			return luci.sys.exec("sed -n 1p /usr/share/clash/dtun_core_version")
		end		
	else
		return "0"
	end
end


local function readlog()
	return luci.sys.exec("sed -n '$p' /usr/share/clash/clash_real.txt 2>/dev/null")
end

local function geo_data()
	return os.date("%Y-%m-%d %H:%M:%S",fss.mtime("/etc/clash/Country.mmdb"))
end

local function downcheck()
	if nixio.fs.access("/var/run/core_update_error") then
		return "0"
	elseif nixio.fs.access("/var/run/core_update") then
		return "1"
	elseif nixio.fs.access("/usr/share/clash/core_down_complete") then
		return "2"
	end
end

function action_read()
	luci.http.prepare_content("application/json")
	luci.http.write_json({
	readlog = readlog();
	})
end

function down_check()
	luci.http.prepare_content("application/json")
	luci.http.write_json({
	 downcheck = downcheck();
	})
end

local function geoipcheck()
	if nixio.fs.access("/var/run/geoip_update_error") then
		return "0"
	elseif nixio.fs.access("/var/run/geoip_update") then
		return "1"
	elseif nixio.fs.access("/var/run/geoip_down_complete") then
		return "2"
	end
end

function geoip_check()
	luci.http.prepare_content("application/json")
	luci.http.write_json({
	 geoipcheck = geoipcheck();
	})
end




function check_status()
	luci.http.prepare_content("application/json")
	luci.http.write_json({
		check_version = check_version(),
		check_core = check_core(),
		check_mihomo = luci.sys.exec("sh /usr/share/clash/check_mihomo_core_version.sh"),
		check_clash_meta = luci.sys.exec("sh /usr/share/clash/check_clash_meta_version.sh"),
		current_version = current_version(),
		new_version = new_version(),
		clash_core = clash_core(),
		check_dtun_core = check_dtun_core(),
		new_dtun_core = new_dtun_core(),
		clashtun_core = clashtun_core(),
		dtun_core = dtun_core(),
		new_core_version = new_core_version(),
		new_mihomo_version = new_mihomo_version(),
		new_clash_meta_version = new_clash_meta_version(),
		new_clashtun_core_version =new_clashtun_core_version(),
		check_clashtun_core = check_clashtun_core(),
		conf_path = conf_path(),
		typeconf = typeconf()	
	})
end
function action_status()
	luci.http.prepare_content("application/json")
	luci.http.write_json({
		web = is_web(),
		clash = is_running(),
		localip = localip(),
		dash_port = dash_port(),
		dashboard_panel = dashboard_panel(),
		current_version = current_version(),
		new_dtun_core = new_dtun_core(),
		new_core_version = new_core_version(),
		new_clashtun_core_version =new_clashtun_core_version(),
		new_version = new_version(),
		clash_core = clash_binary_core(),
		clash_meta_core = clash_meta_core(),
		mihomo_core = mihomo_core(),
		dtun_core = dtun_core(),
		dash_pass = dash_pass(),
		clashtun_core = clashtun_core(),
		new_clash_meta_version = new_clash_meta_version(),
		new_mihomo_version = new_mihomo_version(),
		e_mode = e_mode(),
		mode_value = mode_value(),
		in_use = in_use(),
		conf_path = conf_path(),
		uhttp_port = uhttp_port(),
		typeconf = typeconf()
	})
end

function action_ping_status()
	luci.http.prepare_content("application/json")
	luci.http.write_json({
		ping_enable = ping_enable()
	})
end

function act_ping()
	local e={}
	e.index=luci.http.formvalue("index")
	e.ping=luci.sys.exec("ping -c 1 -W 1 -w 5 %q 2>&1 | grep -o 'time=[0-9]*.[0-9]' | awk -F '=' '{print$2}'"%luci.http.formvalue("domain"))
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end


function geoip_update()
	fs.writefile("/var/run/geoiplog","0")
	luci.sys.exec("(rm /var/run/geoip_update_error ;  touch /var/run/geoip_update ; sh /usr/share/clash/geoip.sh >/tmp/geoip_update.txt 2>&1  || touch /var/run/geoip_update_error ;rm /var/run/geoip_update) &")
end


function do_update()
	fs.writefile("/var/run/clashlog","0")
	luci.sys.exec("(rm /var/run/core_update_error ;  touch /var/run/core_update ; sh /usr/share/clash/core_download.sh >/tmp/clash_update.txt 2>&1  || touch /var/run/core_update_error ;rm /var/run/core_update) &")
end

function do_start()
	local bin = selected_core_bin()
	if bin == "" then
		return
	end
	luci.sys.exec(string.format([[
		uci set clash.config.enable="1" && uci commit clash;
		CONFIG_PATH=$(uci -q get clash.config.use_config);
		[ -f "$CONFIG_PATH" ] || exit 1;
		cp "$CONFIG_PATH" /etc/clash/config.yaml;
		if grep -q '^dns:' /etc/clash/config.yaml && ! grep -Eq '^ +listen:' /etc/clash/config.yaml; then sed -i '/^dns:/a\    listen: 0.0.0.0:5300' /etc/clash/config.yaml; fi;
		pkill -9 -x mihomo >/dev/null 2>&1 || true;
		pkill -9 -x clash-meta >/dev/null 2>&1 || true;
		pkill -9 -x clash >/dev/null 2>&1 || true;
		nohup %q -d /etc/clash >/usr/share/clash/clash.txt 2>&1 &
		sleep 3;
		uci delete dhcp.@dnsmasq[0].server >/dev/null 2>&1 || true;
		uci add_list dhcp.@dnsmasq[0].server='127.0.0.1#5300';
		uci set dhcp.@dnsmasq[0].noresolv='1';
		uci set dhcp.@dnsmasq[0].cachesize='0';
		uci commit dhcp;
		/etc/init.d/dnsmasq restart >/dev/null 2>&1;
		/usr/share/clash/fw4.sh remove >/dev/null 2>&1 || true;
		/usr/share/clash/fw4.sh apply >/dev/null 2>&1 || true
	]], bin))
end

function do_stop()
	luci.sys.exec([[
		uci set clash.config.enable="0" && uci commit clash;
		pkill -9 -x mihomo >/dev/null 2>&1 || true;
		pkill -9 -x clash-meta >/dev/null 2>&1 || true;
		pkill -9 -x clash >/dev/null 2>&1 || true;
		/usr/share/clash/fw4.sh remove >/dev/null 2>&1 || true;
		uci delete dhcp.@dnsmasq[0].server >/dev/null 2>&1 || true;
		uci set dhcp.@dnsmasq[0].noresolv='0';
		uci add_list dhcp.@dnsmasq[0].server='119.29.29.29';
		uci add_list dhcp.@dnsmasq[0].server='223.5.5.5';
		uci commit dhcp;
		/etc/init.d/dnsmasq restart >/dev/null 2>&1
	]])
end

function do_reload()
	do_start()
end

function do_set_mode()
	local mode = luci.http.formvalue("mode") or "fake-ip"
	if mode == "tun" then
		luci.sys.exec([[uci set clash.config.tun_mode='1'; uci set clash.config.stack='system'; uci set clash.config.enable_udp='1'; uci commit clash]])
	else
		luci.sys.exec([[uci set clash.config.tun_mode='0'; uci set clash.config.enhanced_mode='fake-ip'; uci commit clash]])
	end
	luci.http.status(200, "OK")
end

function do_set_config()
	local name = luci.http.formvalue("name") or ""
	if name == "" then
		luci.http.status(400, "Bad Request")
		return
	end
	local candidate = "/usr/share/clash/config/sub/" .. name
	if not nixio.fs.access(candidate) then
		candidate = "/usr/share/clash/config/upload/" .. name
	end
	if nixio.fs.access(candidate) then
		luci.sys.exec(string.format([[uci set clash.config.use_config=%q; uci set clash.config.config_type='1'; uci commit clash]], candidate))
		if is_running() then
			do_start()
		end
		luci.http.status(200, "OK")
	else
		luci.http.status(404, "Not Found")
	end
end

function do_set_panel()
	local name = luci.http.formvalue("name") or "metacubexd"
	if name ~= "metacubexd" and name ~= "yacd" and name ~= "zashboard" and name ~= "razord" then
		name = "metacubexd"
	end
	luci.sys.exec(string.format([[uci set clash.config.dashboard_panel=%q; uci commit clash]], name))
	luci.http.status(200, "OK")
end

function check_update_log()
	luci.http.prepare_content("text/plain; charset=utf-8")
	local clashlog_pos = fs.readfile("/var/run/clashlog") or "0"
	local fdp=tonumber(clashlog_pos) or 0
	local f=io.open("/tmp/clash_update.txt", "r+")
	if not f then
		luci.http.write("\0")
		return
	end
	f:seek("set",fdp)
	local a=f:read(2048000) or ""
	fdp=f:seek()
	fs.writefile("/var/run/clashlog",tostring(fdp))
	f:close()
if fs.access("/var/run/core_update") then
	luci.http.write(a)
else
	luci.http.write(a.."\0")
end
end

function check_geoip_log()
	luci.http.prepare_content("text/plain; charset=utf-8")
	local geoiplog_pos = fs.readfile("/var/run/geoiplog") or "0"
	local fdp=tonumber(geoiplog_pos) or 0
	local f=io.open("/tmp/geoip_update.txt", "r+")
	if not f then
		luci.http.write("\0")
		return
	end
	f:seek("set",fdp)
	local a=f:read(2048000) or ""
	fdp=f:seek()
	fs.writefile("/var/run/geoiplog",tostring(fdp))
	f:close()
if fs.access("/var/run/geoip_update") then
	luci.http.write(a)
else
	luci.http.write(a.."\0")
end
end


function logstatus_check()
	luci.http.prepare_content("text/plain; charset=utf-8")
	local logstatus_pos = fs.readfile("/usr/share/clash/logstatus_check") or "0"
	local fdp=tonumber(logstatus_pos) or 0
	local f=io.open("/usr/share/clash/clash.txt", "r+")
	f:seek("set",fdp)
	local a=f:read(2048000) or ""
	fdp=f:seek()
	fs.writefile("/usr/share/clash/logstatus_check",tostring(fdp))
	f:close()
if fs.access("/var/run/logstatus") then
	luci.http.write(a)
else
	luci.http.write(a.."\0")
end
end
