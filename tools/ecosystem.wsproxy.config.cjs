/**
 * 熊猫模拟器 - Robrowser wsProxy PM2 配置
 *
 * 用法:
 *   pm2 start tools/ecosystem.wsproxy.config.cjs
 *   pm2 stop pandas-wsproxy
 *   pm2 logs pandas-wsproxy
 *   pm2 delete pandas-wsproxy
 *
 * 或使用封装脚本:
 *   ./tools/wsproxy-pm2.sh start
 *
 * 依赖:
 *   npm install -g wsproxy pm2
 *
 * Robrowser:
 *   socketProxy: 'ws://127.0.0.1:5999/'
 */

const path = require('path');

const PORT = process.env.WSPROXY_PORT || 5999;
// 同时允许 127.0.0.1 与本机网卡 IP，避免 char 自动检测 IP 时 wsProxy 拒绝连接
const ALLOW =
	process.env.WSPROXY_ALLOW ||
	'127.0.0.1:6900,127.0.0.1:6121,127.0.0.1:5121,192.168.240.211:6900,192.168.240.211:6121,192.168.240.211:5121';
const THREADS = process.env.WSPROXY_THREADS || 1;

module.exports = {
	apps: [
		{
			name: 'pandas-wsproxy',
			cwd: path.join(__dirname, '..'),
			script: 'wsproxy',
			interpreter: 'none',
			args: `-p ${PORT} -a ${ALLOW} -t ${THREADS}`,
			autorestart: true,
			watch: false,
			max_restarts: 10,
			min_uptime: '3s',
			out_file: 'log/wsproxy-pm2-out.log',
			error_file: 'log/wsproxy-pm2-error.log',
			merge_logs: true,
			time: true,
			env: {
				WSPROXY_PORT: String(PORT),
				WSPROXY_ALLOW: ALLOW,
				WSPROXY_THREADS: String(THREADS),
			},
		},
	],
};
