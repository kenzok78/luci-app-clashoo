'use strict';
'require rpc';
'require uci';

const callStatus     = rpc.declare({ object: 'luci.clash', method: 'status',        expect: {} });
const callVersion    = rpc.declare({ object: 'luci.clash', method: 'version',       expect: {} });
const callReload     = rpc.declare({ object: 'luci.clash', method: 'reload',        expect: {} });
const callRestart    = rpc.declare({ object: 'luci.clash', method: 'restart',       expect: {} });
const callListProf   = rpc.declare({ object: 'luci.clash', method: 'list_profiles', expect: {} });
const callReadLog    = rpc.declare({ object: 'luci.clash', method: 'read_log',      expect: {} });

return {
    /* 返回 true/false (running) */
    status: function () {
        return L.resolveDefault(callStatus(), false).then(function (res) {
            return res === true || res.running === true;
        });
    },
    /* 返回 { core, binary } */
    version: function () {
        return L.resolveDefault(callVersion(), {});
    },
    /* 热重载 */
    reload: function () {
        return L.resolveDefault(callReload(), {});
    },
    /* 完全重启 */
    restart: function () {
        return L.resolveDefault(callRestart(), {});
    },
    /* 返回 profile 文件名数组 */
    listProfiles: function () {
        return L.resolveDefault(callListProf(), { profiles: [] }).then(function (res) {
            return res.profiles || [];
        });
    },
    /* 返回日志字符串 */
    readLog: function () {
        return L.resolveDefault(callReadLog(), { content: '' }).then(function (res) {
            return res.content || '';
        });
    }
};
