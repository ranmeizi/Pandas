#!/usr/bin/env bash
#--------------------------------------------------------------
# 熊猫模拟器 - PM2 版 athena-start
#--------------------------------------------------------------
# athena-start 使用 pid 文件 + 后台进程，本脚本用 PM2 管理同样四个服务。
#
# 用法:
#   ./tools/athena-pm2.sh start
#   ./tools/athena-pm2.sh stop
#   ./tools/athena-pm2.sh restart
#   ./tools/athena-pm2.sh status
#   ./tools/athena-pm2.sh logs
#   ./tools/athena-pm2.sh delete
#
# 依赖:
#   npm install -g pm2
#   项目根目录存在 login-server / char-server / map-server / web-server
#
# 不启动 web-server:
#   PANDAS_ENABLE_WEB=0 ./tools/athena-pm2.sh start
#--------------------------------------------------------------

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ECOSYSTEM="${ROOT_DIR}/tools/ecosystem.pandas.config.cjs"
SERVERS=(login-server char-server map-server web-server)
PM2_APPS=(pandas-login pandas-char pandas-map pandas-web)

require_cmd() {
	if ! command -v "$1" >/dev/null 2>&1; then
		echo "[athena-pm2] 未找到 $1，请先安装: npm install -g $2" >&2
		exit 1
	fi
}

check_binaries() {
	local missing=0
	local bin

	for bin in login-server char-server map-server; do
		if [[ ! -f "${ROOT_DIR}/${bin}" ]]; then
			echo "[athena-pm2] 缺少可执行文件: ${ROOT_DIR}/${bin}" >&2
			missing=1
		fi
	done

	if [[ "${PANDAS_ENABLE_WEB:-1}" != "0" ]] && [[ ! -f "${ROOT_DIR}/web-server" ]]; then
		echo "[athena-pm2] 缺少可执行文件: ${ROOT_DIR}/web-server" >&2
		echo "[athena-pm2] 可设置 PANDAS_ENABLE_WEB=0 跳过 web-server" >&2
		missing=1
	fi

	if [[ ${missing} -eq 1 ]]; then
		echo "[athena-pm2] 请先编译服务端 (cmake + make)" >&2
		exit 1
	fi
}

start_all() {
	require_cmd pm2 pm2
	check_binaries
	mkdir -p "${ROOT_DIR}/log"

	if pm2 describe pandas-login >/dev/null 2>&1; then
		pm2 restart "${ECOSYSTEM}"
		echo "[athena-pm2] 已重启所有 Pandas 服务"
	else
		pm2 start "${ECOSYSTEM}"
		echo "[athena-pm2] 已启动所有 Pandas 服务"
	fi

	pm2 status pandas-login pandas-char pandas-map pandas-web 2>/dev/null || pm2 status
}

stop_all() {
	require_cmd pm2 pm2
	for app in "${PM2_APPS[@]}"; do
		if pm2 describe "${app}" >/dev/null 2>&1; then
			pm2 stop "${app}"
		fi
	done
	echo "[athena-pm2] 已停止"
}

restart_all() {
	require_cmd pm2 pm2
	if pm2 describe pandas-login >/dev/null 2>&1; then
		pm2 restart "${ECOSYSTEM}"
	else
		start_all
	fi
}

status_all() {
	require_cmd pm2 pm2
	pm2 status "${PM2_APPS[@]}" 2>/dev/null || pm2 status
}

logs_all() {
	require_cmd pm2 pm2
	pm2 logs pandas-login pandas-char pandas-map pandas-web --lines 80
}

delete_all() {
	require_cmd pm2 pm2
	for app in "${PM2_APPS[@]}"; do
		if pm2 describe "${app}" >/dev/null 2>&1; then
			pm2 delete "${app}"
		fi
	done
	echo "[athena-pm2] 已从 PM2 移除"
}

usage() {
	cat <<EOF
用法: $(basename "$0") {start|stop|restart|status|logs|delete}

对比 ./athena-start:
  athena-start  -> pid 文件 + 可选 watch 循环
  athena-pm2.sh -> PM2 守护、日志、重启

环境变量:
  PANDAS_ENABLE_WEB=0   不启动 web-server

示例:
  ./tools/athena-pm2.sh start
  PANDAS_ENABLE_WEB=0 ./tools/athena-pm2.sh start
EOF
}

main() {
	cd "${ROOT_DIR}"
	local action="${1:-start}"
	case "${action}" in
		start) start_all ;;
		stop) stop_all ;;
		restart) restart_all ;;
		status) status_all ;;
		logs) logs_all ;;
		delete) delete_all ;;
		*) usage; exit 1 ;;
	esac
}

main "$@"
