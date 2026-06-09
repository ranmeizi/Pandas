#!/usr/bin/env bash
#--------------------------------------------------------------
# 熊猫模拟器 - wsProxy PM2 启动脚本
#--------------------------------------------------------------
# 用法:
#   ./tools/wsproxy-pm2.sh start
#   ./tools/wsproxy-pm2.sh stop
#   ./tools/wsproxy-pm2.sh restart
#   ./tools/wsproxy-pm2.sh status
#   ./tools/wsproxy-pm2.sh logs
#   ./tools/wsproxy-pm2.sh delete
#
# 依赖:
#   npm install -g wsproxy pm2
#
# 开机自启 (可选):
#   pm2 save
#   pm2 startup
#--------------------------------------------------------------

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ECOSYSTEM="${ROOT_DIR}/tools/ecosystem.wsproxy.config.cjs"
APP_NAME="pandas-wsproxy"
LOG_DIR="${ROOT_DIR}/log"

require_cmd() {
	if ! command -v "$1" >/dev/null 2>&1; then
		echo "[wsproxy-pm2] 未找到 $1，请先安装: npm install -g $2" >&2
		exit 1
	fi
}

start_app() {
	require_cmd pm2 pm2
	require_cmd wsproxy wsproxy

	mkdir -p "${LOG_DIR}"

	if pm2 describe "${APP_NAME}" >/dev/null 2>&1; then
		pm2 restart "${ECOSYSTEM}"
		echo "[wsproxy-pm2] 已重启 ${APP_NAME}"
	else
		pm2 start "${ECOSYSTEM}"
		echo "[wsproxy-pm2] 已启动 ${APP_NAME}"
	fi

	echo "  ws://127.0.0.1:${WSPROXY_PORT:-5999}/"
	echo "  allow: ${WSPROXY_ALLOW:-127.0.0.1:6900,127.0.0.1:6121,127.0.0.1:5121}"
	echo "  logs : pm2 logs ${APP_NAME}"
}

stop_app() {
	require_cmd pm2 pm2
	if pm2 describe "${APP_NAME}" >/dev/null 2>&1; then
		pm2 stop "${APP_NAME}"
		echo "[wsproxy-pm2] 已停止 ${APP_NAME}"
	else
		echo "[wsproxy-pm2] ${APP_NAME} 未在 PM2 中运行"
	fi
}

restart_app() {
	require_cmd pm2 pm2
	if pm2 describe "${APP_NAME}" >/dev/null 2>&1; then
		pm2 restart "${APP_NAME}"
	else
		start_app
	fi
}

status_app() {
	require_cmd pm2 pm2
	pm2 describe "${APP_NAME}" || true
	pm2 status "${APP_NAME}" || true
}

logs_app() {
	require_cmd pm2 pm2
	pm2 logs "${APP_NAME}" --lines 100
}

delete_app() {
	require_cmd pm2 pm2
	if pm2 describe "${APP_NAME}" >/dev/null 2>&1; then
		pm2 delete "${APP_NAME}"
		echo "[wsproxy-pm2] 已从 PM2 移除 ${APP_NAME}"
	else
		echo "[wsproxy-pm2] ${APP_NAME} 不存在"
	fi
}

usage() {
	cat <<EOF
用法: $(basename "$0") {start|stop|restart|status|logs|delete}

环境变量:
  WSPROXY_PORT   默认 5999
  WSPROXY_ALLOW  默认 127.0.0.1:6900,127.0.0.1:6121,127.0.0.1:5121
  WSPROXY_THREADS 默认 1

示例:
  ./tools/wsproxy-pm2.sh start
  WSPROXY_PORT=5999 ./tools/wsproxy-pm2.sh restart
  pm2 start tools/ecosystem.wsproxy.config.cjs
EOF
}

main() {
	local action="${1:-start}"
	case "${action}" in
		start) start_app ;;
		stop) stop_app ;;
		restart) restart_app ;;
		status) status_app ;;
		logs) logs_app ;;
		delete) delete_app ;;
		*) usage; exit 1 ;;
	esac
}

main "$@"
