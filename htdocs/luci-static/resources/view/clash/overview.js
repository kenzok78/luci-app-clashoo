'use strict';
'require view';
'require poll';
'require tools.clash as clash';

const PROBE_SITES = [
    { id: 'bilibili',  label: 'Bilibili', type: '国内',
      url: 'https://www.bilibili.com/favicon.ico',
      icon: 'https://www.bilibili.com/favicon.ico' },
    { id: 'wechat',    label: '微信',     type: '国内',
      url: 'https://res.wx.qq.com/a/wx_fed/assets/res/NTI4MWU5.ico',
      icon: 'https://res.wx.qq.com/a/wx_fed/assets/res/NTI4MWU5.ico' },
    { id: 'youtube',   label: 'YouTube',  type: '国外',
      url: 'https://www.youtube.com/favicon.ico',
      icon: 'https://www.youtube.com/favicon.ico' },
    { id: 'github',    label: 'GitHub',   type: '国外',
      url: 'https://github.com/favicon.ico',
      icon: 'https://github.com/favicon.ico' },
];

return view.extend({
    load: function () {
        return Promise.all([
            clash.status(),
            clash.listConfigs()
        ]);
    },

    render: function (data) {
        const cfgData = data[1] || {};

        /* ── helpers ── */
        function mkSel(id, opts, cur, onChange) {
            let sel = E('select', {
                id: id,
                class: 'cbi-input-select',
                style: 'width:100%;max-width:360px;box-sizing:border-box'
            });
            for (let [v, label] of opts) {
                let o = E('option', { value: v }, label);
                if (v === cur) o.selected = true;
                sel.appendChild(o);
            }
            sel.addEventListener('change', () => onChange(sel.value));
            return sel;
        }

        const BTN_STYLE = [
            'display:inline-block',
            'width:90px',
            'height:36px',
            'line-height:36px',
            'padding:0 6px',
            'border:none',
            'border-radius:.375rem',
            'font-size:.9rem',
            'cursor:pointer',
            'color:#fff',
            'text-align:center',
            'white-space:nowrap',
            'box-sizing:border-box'
        ].join(';');

        function mkBtn(label, bg, onClick) {
            let b = E('button', {
                type: 'button',
                style: BTN_STYLE + ';background:' + bg
            }, label);
            if (onClick) b.addEventListener('click', onClick);
            return b;
        }

        function mkBtnGroup() {
            return E('div', {
                style: 'display:inline-flex;gap:6px;align-items:center'
            });
        }

        function mkRow(label, tdId) {
            return E('tr', {}, [
                E('td', { style: 'width:35%;padding:8px 12px;color:#555;font-size:14px;vertical-align:middle;white-space:nowrap' }, label),
                E('td', { id: tdId, style: 'padding:6px 12px;vertical-align:middle' })
            ]);
        }

        let _uiLockUntil = 0;   /* 按钮点击后短暂禁止重渲染 */
        let _isRunning   = false;

        /* ── structure ── */
        let node = E('div', {}, [
            E('div', { class: 'cbi-section' }, [
                E('div', { style: 'text-align:center;padding:10px 0 4px' }, [
                    E('img', {
                        src: '/luci-static/clash/logo.png',
                        style: 'width:48px;height:48px;object-fit:contain;display:block;margin:0 auto 4px',
                        onerror: "this.style.display='none'",
                        alt: 'Clash'
                    }),
                    /* 标题 = 实时日志滚动区，运行时变绿 */
                    E('p', { id: 'ov-title', style: 'margin:0;font-weight:700;font-size:1.1rem;color:#aaa;letter-spacing:.02em;transition:color .4s' }, 'Clashoo'),
                    E('p', { style: 'margin:2px 0 0;font-size:.82rem;color:#aaa' }, '基于规则的自定义代理客户端')
                ]),
                /* 连接测试 — 紧跟副标题 */
                E('div', {
                    id: 'probe-grid',
                    style: 'display:grid;grid-template-columns:repeat(auto-fill,minmax(240px,1fr));gap:10px;padding:8px 12px 4px'
                }),
                E('hr', { style: 'border:none;border-top:1px solid #eee;margin:8px 0 4px' }),
                E('div', { class: 'cbi-section-node' }, [
                    E('table', { style: 'width:100%;border-collapse:collapse' }, [
                        mkRow('客户端',    'ov-client'),
                        mkRow('运行模式',  'ov-mode'),
                        mkRow('配置文件',  'ov-config'),
                        mkRow('代理模式',  'ov-proxy'),
                        mkRow('面板类型',  'ov-panel'),
                        mkRow('面板控制',  'ov-panel-addr')
                    ])
                ])
            ])
        ]);

        /* ── 每秒轮询 clash_real.txt → 滚动显示在标题，稳定后变回 "Clashoo" ── */
        let _lastRealLog  = '';
        let _stableTicks  = 0;

        function $id(id) { return document.getElementById(id) || node.querySelector('#' + id); }

        poll.add(function () {
            return clash.readRealLog().then(function (c) {
                let title = $id('ov-title');
                if (!title) return;
                let text = (c || '').trim();

                /* 规范化：只把最终稳定值替换为 "Clashoo" */
                if (/Clash\s+for\s+OpenWRT/i.test(text)) text = 'Clashoo';
                if (text === 'mihomo' || text === 'Clashoo') text = 'Clashoo';
                if (!text) text = 'Clashoo';

                if (text === _lastRealLog) {
                    _stableTicks++;
                } else {
                    _lastRealLog = text;
                    _stableTicks = 0;
                }

                /* 文字是 "Clashoo" 或稳定3秒 → 显示 "Clashoo"，颜色跟运行状态 */
                if (text === 'Clashoo' || _stableTicks >= 3) {
                    title.textContent = 'Clashoo';
                    title.style.color = _isRunning ? '#1f8b4c' : '#aaa';
                } else {
                    title.textContent = text;
                    title.style.color = '#777';
                }
            });
        }, 1);

        /* ── render dynamic ── */
        function update(s) {
            const running   = !!s.running;
            _isRunning = running;
            const locked    = Date.now() < _uiLockUntil;
            const configs   = cfgData.configs || [];
            const curConf   = cfgData.current || s.conf_path || '';
            const modeValue = s.mode_value  || 'fake-ip';
            const proxyMode = s.proxy_mode  || 'rule';
            const panelType = s.panel_type  || 'metacubexd';
            const dashPort  = s.dash_port   || '9090';
            const dashPass  = s.dash_pass   || '';
            const localIp   = s.local_ip    || location.hostname;
            const dashOk    = !!s.dashboard_installed || !!s.yacd_installed;

            /* Client */
            let elClient = $id('ov-client');
            if (elClient && !locked) {
                elClient.innerHTML = '';
                let grp = mkBtnGroup();
                grp.appendChild(mkBtn(running ? '运行中' : '已停止',
                    running ? '#1f8b4c' : '#b58900', null));
                grp.appendChild(running
                    ? mkBtn('停止客户端', '#6c757d', () => {
                        _uiLockUntil = Date.now() + 3000;
                        clash.stop();
                      })
                    : mkBtn('启用客户端', '#4a76d4', () => {
                        _uiLockUntil = Date.now() + 3000;
                        clash.start();
                      }));
                elClient.appendChild(grp);
            }

            /* Mode */
            let elMode = $id('ov-mode');
            if (elMode) {
                elMode.innerHTML = '';
                elMode.appendChild(mkSel('sel-mode', [
                    ['fake-ip', 'Fake-IP'],
                    ['tun',     'TUN 模式'],
                    ['mixed',   '混合模式']
                ], modeValue, v => clash.setMode(v)));
            }

            /* Config */
            let elCfg = $id('ov-config');
            if (elCfg) {
                elCfg.innerHTML = '';
                let opts = configs.length ? configs.map(c => [c, c]) : [['', '（无配置）']];
                if (curConf && !configs.includes(curConf)) opts.unshift([curConf, curConf]);
                elCfg.appendChild(mkSel('sel-config', opts, curConf,
                    v => v && clash.setConfig(v)));
            }

            /* Proxy mode */
            let elProxy = $id('ov-proxy');
            if (elProxy) {
                elProxy.innerHTML = '';
                elProxy.appendChild(mkSel('sel-proxy', [
                    ['rule',   '规则模式'],
                    ['global', '全局模式'],
                    ['direct', '直连模式']
                ], proxyMode, v => clash.setProxyMode(v)));
            }

            /* Panel type */
            let elPanel = $id('ov-panel');
            if (elPanel) {
                elPanel.innerHTML = '';
                elPanel.appendChild(mkSel('sel-panel', [
                    ['metacubexd', 'MetaCubeXD Panel'],
                    ['yacd',       'YACD Panel'],
                    ['zashboard',  'Zashboard'],
                    ['razord',     'Razord']
                ], panelType, v => clash.setPanel(v)));
            }

            /* Panel address */
            let elAddr = $id('ov-panel-addr');
            if (elAddr) {
                elAddr.innerHTML = '';
                let authSuffix = dashPass ? '?secret=' + encodeURIComponent(dashPass) : '';
                let panelUrl   = 'http://' + localIp + ':' + dashPort + '/ui' + authSuffix;
                let grp = mkBtnGroup();
                grp.appendChild(mkBtn('更新面板', '#0d8f5b', () => clash.updatePanel(panelType)));
                if (dashOk) {
                    let a = E('a', {
                        href: panelUrl, target: '_blank', rel: 'noopener',
                        style: BTN_STYLE + ';background:#adb5bd;text-decoration:none'
                    }, '打开面板');
                    grp.appendChild(a);
                } else {
                    grp.appendChild(mkBtn('打开面板', '#adb5bd', null));
                }
                elAddr.appendChild(grp);
            }
        }

        update(data[0] || {});
        poll.add(() => clash.status().then(s => update(s)), 3);

        /* ── 访问检查 ── */
        let _probeHistory = {};

        function renderProbeCard(site) {
            let history = _probeHistory[site.id] || [];
            let latest  = history[history.length - 1];

            let isIntl      = site.type === '国外';
            let badgeStyle  = 'font-size:.72rem;padding:2px 8px;border-radius:999px;border:1.5px solid;font-weight:600;' +
                (isIntl ? 'color:#20c997;border-color:#20c997' : 'color:#17a2b8;border-color:#17a2b8');
            let latencyColor = !latest ? '#999'
                : !latest.ok           ? '#dc3545'
                : latest.ms < 300      ? '#28a745' : '#ffc107';
            let latencyText  = !latest ? '--' : !latest.ok ? 'timeout' : latest.ms + 'ms';

            return E('div', {
                id: 'probe-card-' + site.id,
                style: 'border-radius:8px;padding:10px 14px;background:#fff;min-width:0'
            }, [
                E('div', { style: 'display:flex;align-items:center;gap:8px' }, [
                    E('img', {
                        src: site.icon,
                        style: 'width:18px;height:18px;object-fit:contain;flex-shrink:0;border-radius:3px',
                        onerror: "this.style.display='none'"
                    }),
                    E('span', { style: 'font-weight:600;font-size:14px;flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap' }, site.label),
                    E('span', { style: badgeStyle }, site.type),
                    E('span', { style: 'font-weight:700;font-size:14px;min-width:56px;text-align:right;color:' + latencyColor }, latencyText)
                ])
            ]);
        }

        async function probeSite(site) {
            let ctrl  = new AbortController();
            let timer = setTimeout(() => ctrl.abort(), 5000);
            let t0    = performance.now();
            try {
                await fetch(site.url, { mode: 'no-cors', cache: 'no-store', signal: ctrl.signal });
                clearTimeout(timer);
                return { ms: Math.round(performance.now() - t0), ok: true };
            } catch(e) {
                clearTimeout(timer);
                return { ms: 5000, ok: false };
            }
        }

        async function probeAll() {
            let grid = $id('probe-grid');
            if (!grid) return;
            let results = await Promise.all(PROBE_SITES.map(s => probeSite(s)));
            for (let i = 0; i < PROBE_SITES.length; i++) {
                let site = PROBE_SITES[i];
                if (!_probeHistory[site.id]) _probeHistory[site.id] = [];
                _probeHistory[site.id].push(results[i]);
                if (_probeHistory[site.id].length > 15) _probeHistory[site.id].shift();
                let old = $id('probe-card-' + site.id);
                if (old) old.replaceWith(renderProbeCard(site));
            }
        }

        /* 先渲染占位卡片（显示 --），不阻塞页面 */
        for (let site of PROBE_SITES) {
            let grid = $id('probe-grid');
            if (grid) grid.appendChild(renderProbeCard(site));
        }
        /* 异步探测，完成后更新卡片 */
        setTimeout(function() { probeAll(); }, 100);
        poll.add(function() { return probeAll(); }, 30);

        return node;
    },

    handleSaveApply: null,
    handleSave: null,
    handleReset: null
});
