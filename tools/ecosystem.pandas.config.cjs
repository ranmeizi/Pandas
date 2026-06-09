/**
 * 熊猫模拟器 - PM2 进程配置 (login / char / map / web)
 *
 * 注意: athena-start 本身不使用 PM2，这是等价的 PM2 启动方案。
 *
 * 用法:
 *   pm2 start tools/ecosystem.pandas.config.cjs
 *   ./tools/athena-pm2.sh start
 *
 * 依赖:
 *   npm install -g pm2
 *   且项目根目录已编译出 login-server / char-server / map-server / web-server
 *
 * 启动顺序:
 *   char/map 会在 login 未就绪时自动重连，一般可直接并行启动。
 */

const path = require('path');

const ROOT = path.join(__dirname, '..');

function serverApp(name, script, extra = {}) {
	return {
		name,
		cwd: ROOT,
		script,
		interpreter: 'none',
		autorestart: true,
		watch: false,
		max_restarts: 20,
		min_uptime: '3s',
		restart_delay: 2000,
		out_file: `log/${name}-pm2-out.log`,
		error_file: `log/${name}-pm2-error.log`,
		merge_logs: true,
		time: true,
		...extra,
	};
}

const apps = [
	serverApp('pandas-login', './login-server'),
	serverApp('pandas-char', './char-server'),
	serverApp('pandas-map', './map-server'),
];

// web-server 在旧 PACKETVER 下可能自动退出，默认不启动
if (process.env.PANDAS_ENABLE_WEB !== '0') {
	apps.push(serverApp('pandas-web', './web-server'));
}

module.exports = { apps };
