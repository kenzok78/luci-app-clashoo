# 252 修复记录（首页概览 / 网络恢复）

## 1. 首页概览报错修复

- 现象：`/cgi-bin/luci/admin/status/overview` 打开时报 `SyntaxError: Invalid or unexpected token`
- 根因：`/www/luci-static/resources/view/status/include/10_system.js` 被注入成了带转义单引号的非法 JS，例如 `\'use strict\';`
- 修复：
  - 本地源文件修正：
    - `workspace/small-package-clean/.github/diy/10_system.js`
    - `workspace/small-package/.github/diy/10_system.js`
  - 去掉错误转义，恢复为标准 JS 单引号
  - 同步正确文件到 `192.168.3.252:/www/luci-static/resources/view/status/include/10_system.js`
  - 清理 LuCI 缓存并重启 `uhttpd`
- 验证：
  - `10_system.js` 头部已恢复为 `'use strict';`
  - `http://127.0.0.1/cgi-bin/luci/admin/status/overview` 可正常返回

## 2. Clash 概览页源码恢复

- 由于路由器重装，重新将本地最新源码直接覆盖到 252：
  - `luasrc/view/clash/status.htm`
  - `luasrc/controller/clash.lua`
  - `luasrc/model/cbi/clash/dns/port.lua`
- 已在 252 上完成 Lua 语法校验、清缓存、重启 `uhttpd`

## 3. 当前网络恢复状态

### 3.1 昨天的旧问题（Clash 代理规则）

- 当时是 **Clash/fake-ip 透明代理规则问题**：
  - `fw4.sh` 中存在 `ip daddr @clash_china return`
  - 导致国内域名（如百度）被提前放行，不走代理链
  - 这会表现成“Google 可走代理，百度反而失败/直连异常”
- 已修复：删除 `@clash_china return` 提前放行

### 3.2 今天重装后的新问题（系统 DNS）

- 本次重装后，不是 Clash 在拦截，而是 **系统 DNS 服务 dnsmasq 自身崩溃**
- 现象：
  - 本机 DNS 查询失败 / 概览页能开但网络访问异常
  - `logread` 出现 `dnsmasq ... crash loop`
  - 同时有 `apparmor DENIED`、`/tmp/ujail-*/dev/log` 挂载失败
- 根因：
  - 252 当前运行在 LXC 环境下
  - `dnsmasq` 的 `procd_add_jail ...` 沙箱在该环境里触发 AppArmor 拒绝
  - 导致 `dnsmasq` 无法稳定启动，DNS 服务异常
- 临时修复（252 实机已执行）：
  - 备份 `/etc/init.d/dnsmasq`
  - 注释 `procd_add_jail` / `procd_add_jail_mount*` 相关行
  - 重启 `dnsmasq`
- 修复结果：
  - `dnsmasq` 已正常常驻
  - `127.0.0.1:53` 已监听
  - `https://www.baidu.com/favicon.ico` 直连恢复 `200`

### 3.3 仍待继续恢复的部分

- 路由器重装后，`luci-app-clash` 初始配置已恢复到默认值
- 当前阻塞点：
  - `/etc/config/clash` 存在，但 `use_config` 尚未恢复
  - `/usr/share/clash/config/sub/` 为空
  - 因此当前无法完成“订阅 -> 启动 -> 代理连通”的完整恢复
- 已确认：
  - `nikki` 订阅 URL 也是默认占位值：`http://example.com/default.yaml`
  - 不可直接复用为真实网络配置

## 4. 后续恢复顺序

1. 恢复真实订阅 URL 或真实配置文件
2. 下载/校验 core2 与 core3
3. 启动后跑门禁测试：
   - 订阅是否正常
   - fake-ip / tun 切换
   - 百度 / Google 可访问
   - fw4/nft 规则是否正常
