'use strict';
'require form';
'require view';
'require uci';
'require poll';
'require tools.clash as clash';

function renderStatus(running) {
    return updateStatus(
        E('input', { id: 'core_status', style: 'border:unset;font-style:italic;font-weight:bold;', readonly: '' }),
        running
    );
}

function updateStatus(element, running) {
    if (element) {
        element.style.color = running ? 'green' : 'red';
        element.value = running ? '运行中' : '未运行';
    }
    return element;
}

return view.extend({
    load: function () {
        return Promise.all([
            uci.load('clash'),
            clash.version(),
            clash.status(),
            clash.listProfiles(),
            clash.capabilities()
        ]);
    },

    render: function (data) {
        const appVersion   = data[1].app   || '';
        const coreVersion = data[1].core  || '';
        const binary      = data[1].binary || '';
        const running     = data[2];
        const profiles    = data[3];
        const caps        = data[4] || {};
        const backend     = caps.backend || '未知';
        const missing     = caps.missing_fw4_tools || [];

        let m, s, o;

        m = new form.Map('clash', 'Clash',
            'OpenWrt 上的 Clash / Clash.Meta / Mihomo 透明代理。');

        if (missing.length) {
            m.description = '当前运行环境缺少 fw4/nft 所需命令：' + missing.join(', ') + '。' +
                '请先补齐防火墙运行依赖，再启用透明代理。';
        }

        /* ── 状态栏 ── */
        s = m.section(form.TableSection, 'status', '状态');
        s.anonymous = true;

        o = s.option(form.Value, '_app_version', '插件版本');
        o.readonly = true;
        o.load = function () { return appVersion || '未知'; };
        o.write = function () { };

        o = s.option(form.Value, '_core_version', '内核版本');
        o.readonly = true;
        o.load = function () { return coreVersion || '未安装'; };
        o.write = function () { };

        o = s.option(form.Value, '_binary', '二进制文件');
        o.readonly = true;
        o.load = function () { return binary || '未找到'; };
        o.write = function () { };

        o = s.option(form.Value, '_backend', '防火墙后端');
        o.readonly = true;
        o.load = function () { return backend; };
        o.write = function () { };

        o = s.option(form.DummyValue, '_core_status', '运行状态');
        o.cfgvalue = function () { return renderStatus(running); };

        poll.add(function () {
            return L.resolveDefault(clash.status()).then(function (r) {
                updateStatus(document.getElementById('core_status'), r);
            });
        });

        o = s.option(form.Button, 'reload');
        o.inputstyle  = 'action';
        o.inputtitle  = '重载服务';
        o.onclick = function () { return clash.reload(); };

        o = s.option(form.Button, 'restart');
        o.inputstyle  = 'negative';
        o.inputtitle  = '重启服务';
        o.onclick = function () { return clash.restart(); };

        /* ── 主配置 ── */
        s = m.section(form.NamedSection, 'config', 'clash', '应用配置');

        o = s.option(form.Flag, 'enable', '启用');
        o.rmempty = false;

        o = s.option(form.ListValue, 'profile', '选择配置文件');
        o.optional = true;
        o.value('', '使用默认 config.yaml');
        for (const name of profiles) {
            o.value('profile:' + name, name);
        }

        o = s.option(form.Value, 'start_delay', '启动延迟（秒）');
        o.datatype    = 'uinteger';
        o.placeholder = '立即启动';

        o = s.option(form.ListValue, 'p_mode', '代理模式');
        o.value('rule',   '规则');
        o.value('global', '全局');
        o.value('direct', '直连');

        o = s.option(form.ListValue, 'level', '日志级别');
        o.value('info',    'info');
        o.value('warning', 'warning');
        o.value('error',   'error');
        o.value('debug',   'debug');
        o.value('silent',  'silent');

        o = s.option(form.Value, 'http_port',  'HTTP 代理端口');
        o.datatype = 'port';

        o = s.option(form.Value, 'socks_port', 'SOCKS5 代理端口');
        o.datatype = 'port';

        o = s.option(form.Value, 'redir_port', 'Redir TCP 端口');
        o.datatype = 'port';

        o = s.option(form.Value, 'dash_port',  '面板端口');
        o.datatype = 'port';

        o = s.option(form.Flag, 'allow_lan', '允许局域网');
        o.rmempty = false;

        return m.render();
    }
});
