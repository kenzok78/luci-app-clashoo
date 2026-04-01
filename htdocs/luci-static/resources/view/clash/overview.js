'use strict';
'require view';
'require poll';
'require tools.clash as clash';

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
                E('td', { style: 'width:35%;padding:8px 12px;color:#555;font-size:.95rem;vertical-align:middle;white-space:nowrap' }, label),
                E('td', { id: tdId, style: 'padding:6px 12px;vertical-align:middle' })
            ]);
        }

        let _uiLockUntil = 0;   /* 按钮点击后短暂禁止重渲染 */
        let _isRunning   = false;

        /* ── structure ── */
        let node = E('div', {}, [
            E('div', { class: 'cbi-section' }, [
                E('div', { style: 'text-align:center;padding:18px 0 14px' }, [
                    E('img', {
                        src: '/luci-static/clash/logo.png',
                        style: 'width:56px;height:56px;object-fit:contain;display:block;margin:0 auto 8px',
                        onerror: "this.style.display='none'",
                        alt: 'Clash'
                    }),
                    /* 标题 = 实时日志滚动区，运行时变绿 */
                    E('p', { id: 'ov-title', style: 'margin:2px 0 0;font-weight:700;font-size:1.1rem;color:#aaa;letter-spacing:.02em;transition:color .4s' }, 'Clashoo'),
                    E('p', { style: 'margin:3px 0 0;font-size:.82rem;color:#aaa' }, '基于规则的自定义代理客户端')
                ]),
                E('hr', { style: 'border:none;border-top:1px solid #eee;margin:8px 0 4px' }),
                E('div', { class: 'cbi-section-node' }, [
                    E('table', { style: 'width:100%;border-collapse:collapse' }, [
                        mkRow('Clash 客户端',  'ov-client'),
                        mkRow('Clash 模式',    'ov-mode'),
                        mkRow('Clash 配置',    'ov-config'),
                        mkRow('代理模式',      'ov-proxy'),
                        mkRow('面板类型',      'ov-panel'),
                        mkRow('面板地址',      'ov-panel-addr')
                    ])
                ])
            ])
        ]);

        /* ── 每秒轮询 clash_real.txt → 滚动显示在标题，稳定后变回 "Clash" ── */
        let _lastRealLog  = '';
        let _stableTicks  = 0;

        poll.add(function () {
            return clash.readRealLog().then(function (c) {
                let title = document.getElementById('ov-title');
                if (!title) return;
                let text = (c || '').trim();

                /* 规范化："Clash for OpenWRT" / "Clashoo" / "mihomo" → "Clashoo" */
                text = text.replace(/Clash\s+for\s+OpenWRT/gi, 'Clashoo');
                text = text.replace(/\bmihomo\b/gi, 'Clashoo');
                text = text.replace(/\bClashoo\b/gi, 'Clashoo');
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
            let elClient = document.getElementById('ov-client');
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
            let elMode = document.getElementById('ov-mode');
            if (elMode) {
                elMode.innerHTML = '';
                elMode.appendChild(mkSel('sel-mode', [
                    ['fake-ip', 'Fake-IP'],
                    ['tun',     'TUN 模式'],
                    ['mixed',   '混合模式']
                ], modeValue, v => clash.setMode(v)));
            }

            /* Config */
            let elCfg = document.getElementById('ov-config');
            if (elCfg) {
                elCfg.innerHTML = '';
                let opts = configs.length ? configs.map(c => [c, c]) : [['', '（无配置）']];
                if (curConf && !configs.includes(curConf)) opts.unshift([curConf, curConf]);
                elCfg.appendChild(mkSel('sel-config', opts, curConf,
                    v => v && clash.setConfig(v)));
            }

            /* Proxy mode */
            let elProxy = document.getElementById('ov-proxy');
            if (elProxy) {
                elProxy.innerHTML = '';
                elProxy.appendChild(mkSel('sel-proxy', [
                    ['rule',   '规则模式'],
                    ['global', '全局模式'],
                    ['direct', '直连模式']
                ], proxyMode, v => clash.setProxyMode(v)));
            }

            /* Panel type */
            let elPanel = document.getElementById('ov-panel');
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
            let elAddr = document.getElementById('ov-panel-addr');
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

        return node;
    },

    handleSaveApply: null,
    handleSave: null,
    handleReset: null
});
