@echo off
rem --------------------------------------------------------------
rem 熊猫模拟器 - Robrowser WebSocket 代理启动脚本 (Windows)
rem --------------------------------------------------------------
rem 首次使用: npm install -g wsproxy
rem 用法: tools\wsproxy.bat start|stop|restart|status
rem --------------------------------------------------------------

setlocal EnableExtensions

set "ROOT_DIR=%~dp0.."
set "LOG_DIR=%ROOT_DIR%\log"
set "PID_FILE=%ROOT_DIR%\.wsproxy.pid"
set "LOG_FILE=%LOG_DIR%\wsproxy.log"

if not defined WSPROXY_PORT set "WSPROXY_PORT=5999"
if not defined WSPROXY_ALLOW set "WSPROXY_ALLOW=127.0.0.1:6900,127.0.0.1:6121,127.0.0.1:5121"
if not defined WSPROXY_THREADS set "WSPROXY_THREADS=1"

set "ACTION=%~1"
if "%ACTION%"=="" set "ACTION=start"

if /I "%ACTION%"=="start" goto :start
if /I "%ACTION%"=="stop" goto :stop
if /I "%ACTION%"=="restart" goto :restart
if /I "%ACTION%"=="status" goto :status
goto :usage

:start
if exist "%PID_FILE%" (
    for /f "usebackq delims=" %%p in ("%PID_FILE%") do (
        tasklist /FI "PID eq %%p" 2>nul | find "%%p" >nul
        if not errorlevel 1 (
            echo [wsproxy] 已在运行 (pid: %%p)
            exit /b 0
        )
    )
)

where wsproxy >nul 2>&1
if errorlevel 1 (
    echo [wsproxy] 未找到 wsproxy。请先执行: npm install -g wsproxy
    exit /b 1
)

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

start "wsproxy" /B wsproxy -p %WSPROXY_PORT% -a %WSPROXY_ALLOW% -t %WSPROXY_THREADS% >> "%LOG_FILE%" 2>&1

for /f "tokens=2" %%p in ('tasklist /FI "IMAGENAME eq node.exe" /FO LIST ^| find "PID:"') do (
    echo %%p> "%PID_FILE%"
    goto :started
)
for /f "tokens=2" %%p in ('tasklist /FI "IMAGENAME eq wsproxy.exe" /FO LIST ^| find "PID:"') do (
    echo %%p> "%PID_FILE%"
    goto :started
)

:started
echo [wsproxy] 已启动
echo   listen   : ws://127.0.0.1:%WSPROXY_PORT%/
echo   allow    : %WSPROXY_ALLOW%
echo   log file : %LOG_FILE%
exit /b 0

:stop
if not exist "%PID_FILE%" (
    echo [wsproxy] 未在运行
    exit /b 0
)
for /f "usebackq delims=" %%p in ("%PID_FILE%") do (
    taskkill /PID %%p /F >nul 2>&1
)
del /f /q "%PID_FILE%" >nul 2>&1
echo [wsproxy] 已停止
exit /b 0

:restart
call "%~f0" stop
call "%~f0" start
exit /b %ERRORLEVEL%

:status
if not exist "%PID_FILE%" (
    echo [wsproxy] 未运行
    exit /b 1
)
for /f "usebackq delims=" %%p in ("%PID_FILE%") do (
    tasklist /FI "PID eq %%p" 2>nul | find "%%p" >nul
    if errorlevel 1 (
        echo [wsproxy] 未运行
        exit /b 1
    )
    echo [wsproxy] 运行中 (pid: %%p)
    echo   ws://127.0.0.1:%WSPROXY_PORT%/
    echo   allow: %WSPROXY_ALLOW%
    exit /b 0
)
exit /b 1

:usage
echo 用法: %~nx0 {start^|stop^|restart^|status}
exit /b 1
