'use strict';
'require view';
'require form';
'require uci';
'require tools.clash as clash';

return view.extend({
    load: function () {
        return uci.load('clash');
    },

    render: function () {
        let m, s, o;

        m = new form.Map('clash', _('DNS 设置'), _('配置 Clash DNS 解析规则'));

        /* ─── 基础 DNS ─── */
        s = m.section(form.NamedSection, 'config', 'clash', _('基础 DNS'));
        s.anonymous = false;

        o = s.option(form.Flag, 'enable_dns', _('启用 DNS 模块'));
        o.default = '1';

        o = s.option(form.Value, 'dns_port', _('DNS 监听端口'));
        o.default = '1053';
        o.datatype = 'port';
        o.depends('enable_dns', '1');

        o = s.option(form.ListValue, 'enhanced_mode', _('增强模式'));
        o.value('fake-ip', 'Fake-IP');
        o.value('redir-host', 'Redir-Host');
        o.default = 'fake-ip';
        o.depends('enable_dns', '1');

        o = s.option(form.Value, 'fake_ip_range', _('Fake-IP 网段'));
        o.default = '198.18.0.1/16';
        o.depends({ enable_dns: '1', enhanced_mode: 'fake-ip' });

        o = s.option(form.Value, 'default_nameserver', _('默认 DNS 服务器'), _('引导 DoH/DoT 解析用'));
        o.default = '223.5.5.5';
        o.depends('enable_dns', '1');

        /* ─── 高级设置 ─── */
        s = m.section(form.NamedSection, 'config', 'clash', _('高级设置'));
        s.anonymous = false;

        o = s.option(form.Flag, 'dnsforwader', _('强制转发 DNS'));
        o.default = '0';

        o = s.option(form.Flag, 'dnscache', _('启用 DNS 缓存'));
        o.default = '1';

        o = s.option(form.Value, 'dns_nameserver', _('上游 Nameserver'), _('换行分隔，如 https://dns.alidns.com/dns-query'));
        o.rows = 3;
        o.optional = true;

        o = s.option(form.Value, 'dns_fallback', _('Fallback DNS'));
        o.rows = 3;
        o.optional = true;

        o = s.option(form.Value, 'dns_fake_ip_filter', _('Fake-IP 过滤域名（换行分隔）'));
        o.rows = 4;
        o.optional = true;
        o.depends({ enable_dns: '1', enhanced_mode: 'fake-ip' });

        /* ─── 上游 DNS 服务器 ─── */
        s = m.section(form.TypedSection, 'dnsservers', _('上游 DNS 服务器'));
        s.addremove = true;
        s.anonymous = true;

        o = s.option(form.Value, 'name', _('名称'));
        o = s.option(form.Value, 'url', _('DNS URL'), _('如 https://doh.pub/dns-query'));
        o.optional = false;
        o = s.option(form.Value, 'type', _('类型'));
        o.value('dns', 'DNS');
        o.value('https', 'DoH');
        o.value('tls', 'DoT');
        o.default = 'https';

        /* ─── DNS 劫持 ─── */
        s = m.section(form.TypedSection, 'dnshijack', _('DNS 劫持'));
        s.addremove = true;
        s.anonymous = true;

        o = s.option(form.Value, 'domain', _('域名'));
        o = s.option(form.Value, 'server', _('目标 DNS'));

        /* ─── 代理认证 ─── */
        s = m.section(form.TypedSection, 'authentication', _('代理认证'));
        s.addremove = true;
        s.anonymous = true;

        o = s.option(form.Value, 'user', _('用户名'));
        o = s.option(form.Value, 'pass', _('密码'));
        o.password = true;

        return m.render();
    },

    handleSaveApply: function (ev) {
        return this.handleSave(ev).then(() => clash.restart());
    }
});
