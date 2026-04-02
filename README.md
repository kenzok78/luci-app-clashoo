<p align="center">
  <img src="logo.png" alt="Clashoo" width="160" />
</p>

<h1 align="center">luci-app-clashoo</h1>

<p align="center">
  基于 <a href="https://github.com/MetaCubeX/mihomo">mihomo</a> 内核的 OpenWrt LuCI 代理管理界面
</p>

## 功能特性

- **概览面板** — 一键启停、实时状态滚动、连接测试（Bilibili / 微信 / YouTube / GitHub）
- **代理配置** — 多配置文件管理、运行模式切换（Fake-IP / TUN / 混合）
- **DNS 设置** — 自定义上游 DNS、Fake-IP 过滤、DNS 劫持规则
- **配置管理** — YAML 配置在线编辑与上传
- **系统设置** — GeoIP 更新、大陆白名单、日志查看

## 依赖

| 包名 | 说明 |
|------|------|
| `mihomo` | Clash Meta 内核 |
| `luci` | OpenWrt Web 界面框架 |
| `curl` | 下载 GeoIP / 面板 / 订阅 |

## 安装

```bash
# 从源码编译
git clone https://github.com/kenzok78/luci-app-clashoo.git package/luci-app-clashoo
make package/luci-app-clashoo/compile V=s

# 或直接安装 ipk
opkg install luci-app-clashoo_*.ipk
```

## 截图

概览页面包含：
- 🐱 Clashoo 品牌标识 + 启停状态动画
- 📊 连接测试（国内/国外延迟检测）
- ⚙️ 快捷配置（运行模式、代理模式、面板控制）

## 致谢

- [mihomo](https://github.com/MetaCubeX/mihomo) — Clash Meta 内核
- [luci-app-clash](https://github.com/kenzok78/luci-app-clash) — 原始项目
- [nikki](https://github.com/nikki-enrich/openwrt-nikki) — 参考实现

## 许可证

GPL-3.0
