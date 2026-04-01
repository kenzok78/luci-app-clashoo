'use strict';
'require view';
'require poll';
'require tools.clash as clash';

return view.extend({
    load: function () {
        return clash.readLog();
    },

    render: function (content) {
        const textarea = E('textarea', {
            id: 'clash_log',
            style: 'width:100%;height:60vh;background:#1e1e1e;color:#d4d4d4;font-family:monospace;font-size:13px;padding:8px;border:none;resize:vertical;',
            readonly: ''
        }, [ content ]);

        const refreshBtn = E('button', {
            class: 'btn cbi-button cbi-button-action',
            click: function () {
                clash.readLog().then(function (log) {
                    const el = document.getElementById('clash_log');
                    if (el) {
                        el.value = log;
                        el.scrollTop = el.scrollHeight;
                    }
                });
            }
        }, [ _('Refresh') ]);

        const clearBtn = E('button', {
            class: 'btn cbi-button cbi-button-negative',
            style: 'margin-left:8px;',
            click: function () {
                const el = document.getElementById('clash_log');
                if (el) el.value = '';
            }
        }, [ _('Clear') ]);

        /* 自动滚动到底部 */
        textarea.addEventListener('DOMNodeInserted', function () {
            textarea.scrollTop = textarea.scrollHeight;
        });
        setTimeout(function () {
            textarea.scrollTop = textarea.scrollHeight;
        }, 100);

        poll.add(function () {
            return clash.readLog().then(function (log) {
                const el = document.getElementById('clash_log');
                if (el) {
                    el.value = log;
                    el.scrollTop = el.scrollHeight;
                }
            });
        }, 5);

        return E([
            E('h2', {}, [ _('Clash Log') ]),
            E('div', { style: 'margin-bottom:8px;' }, [ refreshBtn, clearBtn ]),
            textarea
        ]);
    },

    handleSaveApply: null,
    handleSave: null,
    handleReset: null
});
