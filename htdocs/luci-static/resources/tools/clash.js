'use strict';
'require baseclass';
'require rpc';
'require uci';

const callRCList      = rpc.declare({ object: 'rc',         method: 'list',          params: ['name'],          expect: { '': {} } });
const callRCInit      = rpc.declare({ object: 'rc',         method: 'init',          params: ['name', 'action'], expect: { '': {} } });
const callVersion     = rpc.declare({ object: 'luci.clash', method: 'version',       expect: {} });
const callListProf    = rpc.declare({ object: 'luci.clash', method: 'list_profiles', expect: {} });
const callReadLog     = rpc.declare({ object: 'luci.clash', method: 'read_log',      expect: {} });
const callCaps        = rpc.declare({ object: 'luci.clash', method: 'capabilities',  expect: {} });
const callListConfigs = rpc.declare({ object: 'luci.clash', method: 'list_configs',  expect: {} });
const callSetConfig   = rpc.declare({ object: 'luci.clash', method: 'set_config',    params: ['name'], expect: {} });
const callStart       = rpc.declare({ object: 'luci.clash', method: 'start',         expect: {} });
const callStop        = rpc.declare({ object: 'luci.clash', method: 'stop',          expect: {} });

return baseclass.extend({
    status: function () {
        return L.resolveDefault(callRCList('clash'), {}).then(function (res) {
            return !!res?.clash?.running;
        });
    },

    reload: function () {
        return L.resolveDefault(callRCInit('clash', 'reload'), {});
    },

    restart: function () {
        return L.resolveDefault(callRCInit('clash', 'restart'), {});
    },

    start: function () {
        return L.resolveDefault(callStart(), {});
    },

    stop: function () {
        return L.resolveDefault(callStop(), {});
    },

    version: function () {
        return L.resolveDefault(callVersion(), {});
    },

    listProfiles: function () {
        return L.resolveDefault(callListProf(), { profiles: [] }).then(function (res) {
            return res.profiles || [];
        });
    },

    listConfigs: function () {
        return L.resolveDefault(callListConfigs(), { configs: [], current: '' });
    },

    setConfig: function (name) {
        return L.resolveDefault(callSetConfig(name), {});
    },

    readLog: function () {
        return L.resolveDefault(callReadLog(), { content: '' }).then(function (res) {
            return res.content || '';
        });
    },

    capabilities: function () {
        return L.resolveDefault(callCaps(), {});
    }
});
