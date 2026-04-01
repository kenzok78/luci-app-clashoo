'use strict';
'require view';
'require poll';
'require rpc';
'require uci';
'require tools.clash as clash';

return view.extend({
    load: function () {
        return Promise.all([
            clash.status(),
            clash.listConfigs()
        ]);
    },

    render: function (data) {
        const st      = data[0] || {};
        const cfgData = data[1] || {};

        const view = this;
        let node = E('div', { class: 'cbi-map' }, [
            /* ── Hero ── */
            E('div', { style: 'text-align:center;padding:18px 0 10px' }, [
                E('img', {
                    src: '/luci-static/clash/logo.png',
                    style: 'width:60px;height:60px;object-fit:contain;border-radius:8px',
                    onerror: "this.style.display='none'",
                    alt: 'Clash'
                }),
                E('div', { style: 'font-size:1.1em;font-weight:bold;color:#336;margin-top:6px' }, 'Clash'),
                E('div', { style: 'color:#666;font-size:.9em' }, '基于规则的自定义代理客户端')
            ]),

            E('hr', { style: 'margin:0 0 12px' }),

            /* ── Status table ── */
            E('div', { class: 'cbi-section' }, [
                E('div', { class: 'cbi-section-node' }, [
                    E('table', { class: 'cbi-tblsection', style: 'width:100%' }, [
                        E('thead', {}, E('tr', {}, [
                            E('th', {}, '客户端'),
                            E('th', {}, 'Clash 模式'),
                            E('th', {}, 'Clash 配置'),
                            E('th', {}, '代理模式'),
                            E('th', {}, '面板类型')
                        ])),
                        E('tbody', { id: 'clash-status-row' }, [
                            E('tr', {}, [
                                E('td', { id: 'td-client' }),
                                E('td', { id: 'td-mode' }),
                                E('td', { id: 'td-config' }),
                                E('td', { id: 'td-proxy' }),
                                E('td', { id: 'td-panel' })
                            ])
                        ])
                    ])
                ])
            ]),

            E('hr', { style: 'margin:4px 0 12px' }),

            /* ── Panel row ── */
            E('div', { class: 'cbi-section' }, [
                E('div', { class: 'cbi-section-node' }, [
                    E('table', { class: 'cbi-tblsection', style: 'width:100%' }, [
                        E('thead', {}, E('tr', {}, [E('th', {}, '面板地址')])),
                        E('tbody', {}, E('tr', {}, [E('td', { id: 'td-panel-row' })]))
                    ])
                ])
            ])
        ]);

        /* Build selects */
        function mkSelect(id, opts, cur, onChange) {
            let sel = E('select', { class: 'cbi-input-select', id: id });
            for (let [v, label] of opts) {
                let o = E('option', { value: v }, label);
                if (v === cur) o.selected = true;
                sel.appendChild(o);
            }
            sel.addEventListener('change', () => onChange(sel.value));
            return E('div', { class: 'clash-center-box' }, sel);
        }

        function mkBtn(label, style, onClick) {
            let b = E('button', {
                class: 'btn cbi-button',
                style: 'background:' + style + ';color:#fff;padding:5px 14px;margin:2px'
            }, label);
            b.addEventListener('click', onClick);
            return b;
        }

        function renderAll(s) {
            const running    = !!s.running;
            const configs    = cfgData.configs || [];
            const curConf    = s.conf_path || '';
            const modeValue  = s.mode_value  || 'fake-ip';
            const proxyMode  = s.proxy_mode  || 'rule';
            const panelType  = s.panel_type  || 'metacubexd';
            const dashPort   = s.dash_port   || '9090';
            const dashPass   = s.dash_pass   || '';
            const localIp    = s.local_ip    || location.hostname;
            const dashInstalled = !!s.dashboard_installed;
            const yacdInstalled = !!s.yacd_installed;

            /* Client buttons */
            let tdClient = document.getElementById('td-client');
            if (tdClient) {
                tdClient.innerHTML = '';
                tdClient.appendChild(E('div', { class: 'clash-center-box' }, [
                    E('div', { class: 'clash-panel-actions' }, running
                        ? [
                            E('span', { class: 'btn cbi-button', style: 'background:#1f8b4c;color:#fff;cursor:default' }, '运行中'),
                            mkBtn('停止客户端', '#6c757d', () => clash.stop().then(() => poll.restarted = true))
                          ]
                        : [
                            E('span', { class: 'btn cbi-button', style: 'background:#b58900;color:#fff;cursor:default' }, '已停止'),
                            mkBtn('启用客户端', '#9ca3af', () => clash.start().then(() => poll.restarted = true))
                          ]
                    )
                ]));
            }

            /* Mode select */
            let tdMode = document.getElementById('td-mode');
            if (tdMode) {
                tdMode.innerHTML = '';
                tdMode.appendChild(mkSelect('sel-mode', [
                    ['fake-ip', 'Fake-IP'],
                    ['tun',     'TUN 模式'],
                    ['mixed',   '混合模式']
                ], modeValue, v => clash.setMode(v)));
            }

            /* Config select */
            let tdConfig = document.getElementById('td-config');
            if (tdConfig) {
                tdConfig.innerHTML = '';
                let opts = [['', '（未设置）']].concat(configs.map(c => [c, c]));
                tdConfig.appendChild(mkSelect('sel-config', opts, curConf,
                    v => v && clash.setConfig(v).then(() => L.ui.showModal(null, [
                        E('p', {}, '配置已切换，正在重启…'),
                    ]) && setTimeout(() => location.reload(), 2500)
                )));
            }

            /* Proxy mode */
            let tdProxy = document.getElementById('td-proxy');
            if (tdProxy) {
                tdProxy.innerHTML = '';
                tdProxy.appendChild(mkSelect('sel-proxy', [
                    ['rule',   '规则模式'],
                    ['global', '全局模式'],
                    ['direct', '直连模式']
                ], proxyMode, v => clash.setProxyMode(v)));
            }

            /* Panel type */
            let tdPanel = document.getElementById('td-panel');
            if (tdPanel) {
                tdPanel.innerHTML = '';
                tdPanel.appendChild(mkSelect('sel-panel', [
                    ['metacubexd', 'MetaCubeXD Panel'],
                    ['yacd',       'YACD Panel'],
                    ['zashboard',  'Zashboard'],
                    ['razord',     'Razord']
                ], panelType, v => clash.setPanel(v)));
            }

            /* Panel address row */
            let tdPanelRow = document.getElementById('td-panel-row');
            if (tdPanelRow) {
                let panelUrls = {
                    metacubexd: 'http://' + localIp + ':' + dashPort + '/ui',
                    yacd:       'http://' + localIp + ':' + dashPort + '/ui',
                    zashboard:  'http://' + localIp + ':' + dashPort + '/ui',
                    razord:     'http://' + localIp + ':' + dashPort + '/ui'
                };
                let authSuffix = dashPass ? '?secret=' + encodeURIComponent(dashPass) : '';
                let panelUrl   = (panelUrls[panelType] || '') + authSuffix;
                let canOpen    = dashInstalled || (panelType === 'yacd' && yacdInstalled);

                tdPanelRow.innerHTML = '';
                tdPanelRow.appendChild(E('div', { class: 'clash-center-box' }, [
                    E('div', { class: 'clash-panel-actions' }, [
                        mkBtn('更新面板', '#0d8f5b', () => clash.updatePanel(panelType)),
                        canOpen
                            ? Object.assign(E('a', {
                                href: panelUrl,
                                target: '_blank',
                                class: 'btn cbi-button',
                                style: 'background:#6c757d;color:#fff;padding:5px 14px;margin:2px;text-decoration:none'
                              }, '打开面板'), {})
                            : E('button', {
                                class: 'btn cbi-button',
                                style: 'background:#aaa;color:#fff;padding:5px 14px;margin:2px',
                                disabled: ''
                              }, '打开面板')
                    ])
                ]));
            }
        }

        /* Initial render */
        renderAll(st);

        /* Poll */
        poll.add(function () {
            return clash.status().then(s => renderAll(s));
        }, 3);

        return node;
    },

    handleSaveApply: null,
    handleSave: null,
    handleReset: null
});
