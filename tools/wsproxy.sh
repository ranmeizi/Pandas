#!/usr/bin/env bash
#--------------------------------------------------------------
# 熊猫模拟器 - Robrowser WebSocket 代理启动脚本
#--------------------------------------------------------------
# 浏览器无法直连 TCP，Robrowser 需要 wsProxy 将 WebSocket 转发到:
#   login-server :6900
#   char-server  :6121
#   map-server   :5121
#
# 用法 (在项目根目录或任意位置):
#   ./tools/wsproxy.sh start
#   ./tools/wsproxy.sh stop
#   ./tools/wsproxy.sh restart
#   ./tools/wsproxy.sh status
#
# PM2 方式 (推荐生产/后台常驻):
#   ./tools/wsproxy-pm2.sh start
#   或: pm2 start tools/ecosystem.wsproxy.config.cjs
#
# 首次使用请先安装 wsProxy:
#   npm install -g wsproxy
#
# Robrowser 配置示例:
#   socketProxy: 'ws://127.0.0.1:5999/'
#   address:     '127.0.0.1'
#   port:        6900
#
# 建议同时在 conf/import/char_conf.txt 中设置:
#   char_ip: 127.0.0.1
# 并在 conf/import/map_conf.txt 中设置:
#   map_ip: 127.0.0.1
#--------------------------------------------------------------

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="${ROOT_DIR}/log"
PID_FILE="${ROOT_DIR}/.wsproxy.pid"
LOG_FILE="${LOG_DIR}/wsproxy.log"

# 可通过环境变量覆盖
WSPROXY_PORT="${WSPROXY_PORT:-5999}"
WSPROXY_ALLOW="${WSPROXY_ALLOW:-127.0.0.1:6900,127.0.0.1:6121,127.0.0.1:5121}"
WSPROXY_THREADS="${WSPROXY_THREADS:-1}"

resolve_wsproxy_cmd() {
	if command -v wsproxy >/dev/null 2>&1; then
		echo "wsproxy"
		return 0
	fi
	if command -v npx >/dev/null 2>&1; then
		echo "npx --yes wsproxy"
		return 0
	fi
	return 1
}

is_running() {
	if [[ -f "${PID_FILE}" ]]; then
		local pid
		pid="$(cat "${PID_FILE}")"
		if kill -0 "${pid}" 2>/dev/null; then
			return 0
		fi
	fi
	return 1
}

start_wsproxy() {
	if is_running; then
		echo "[wsproxy] 已在运行 (pid: $(cat "${PID_FILE}"))"
		return 0
	fi

	local cmd
	if ! cmd="$(resolve_wsproxy_cmd)"; then
		echo "[wsproxy] 未找到 wsproxy。请先执行: npm install -g wsproxy" >&2
		exit 1
	fi

	mkdir -p "${LOG_DIR}"

	# shellcheck disable=SC2086
	nohup ${cmd} \
		-p "${WSPROXY_PORT}" \
		-a "${WSPROXY_ALLOW}" \
		-t "${WSPROXY_THREADS}" \
		>> "${LOG_FILE}" 2>&1 &

	local pid=$!
	echo "${pid}" > "${PID_FILE}"
	sleep 1

	if ! kill -0 "${pid}" 2>/dev/null; then
		echo "[wsproxy] 启动失败，请查看日志: ${LOG_FILE}" >&2
		rm -f "${PID_FILE}"
		exit 1
	fi

	echo "[wsproxy] 已启动"
	echo "  pid      : ${pid}"
	echo "  listen   : ws://127.0.0.1:${WSPROXY_PORT}/"
	echo "  allow    : ${WSPROXY_ALLOW}"
	echo "  log file : ${LOG_FILE}"
}

stop_wsproxy() {
	if ! is_running; then
		echo "[wsproxy] 未在运行"
		rm -f "${PID_FILE}"
		return 0
	fi

	local pid
	pid="$(cat "${PID_FILE}")"
	kill "${pid}" 2>/dev/null || true

	for _ in $(seq 1 10); do
		if ! kill -0 "${pid}" 2>/dev/null; then
			rm -f "${PID_FILE}"
			echo "[wsproxy] 已停止"
			return 0
		fi
		sleep 0.2
	done

	kill -9 "${pid}" 2>/dev/null || true
	rm -f "${PID_FILE}"
	echo "[wsproxy] 已强制停止"
}

status_wsproxy() {
	if is_running; then
		echo "[wsproxy] 运行中 (pid: $(cat "${PID_FILE}"))"
		echo "  ws://127.0.0.1:${WSPROXY_PORT}/"
		echo "  allow: ${WSPROXY_ALLOW}"
	else
		echo "[wsproxy] 未运行"
		return 1
	fi
}

usage() {
	cat <<EOF
用法: $(basename "$0") {start|stop|restart|status}

环境变量:
  WSPROXY_PORT   监听端口 (默认: 5999)
  WSPROXY_ALLOW  允许转发的目标列表 (默认: 127.0.0.1:6900,6121,5121)
  WSPROXY_THREADS 工作线程数 (默认: 1)

示例:
  WSPROXY_PORT=5999 ./tools/wsproxy.sh start
EOF
}

main() {
	local action="${1:-start}"
	case "${action}" in
		start) start_wsproxy ;;
		stop) stop_wsproxy ;;
		restart) stop_wsproxy; start_wsproxy ;;
		status) status_wsproxy ;;
		*) usage; exit 1 ;;
	esac
}

main "$@"
