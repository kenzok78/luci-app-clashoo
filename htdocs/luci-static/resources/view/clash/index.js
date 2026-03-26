/* index.js – luci 23.05+ 路由兼容：将 /app 路径做 alias，此文件保留给
   旧 menu.d 路径引用或本地开发使用。
   功能内容已移至 view/clash/app.js，menu.d 中 path 指向 "clash/app"。 */
'use strict';
'require view';
'require tools.clash as clash';

/* 直接 re-export app view */
return (function () {
    'require view';
    return L.require('view.clash.app');
})();
