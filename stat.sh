#!/bin/bash

# Debian 11 已测试通过
# 配置参数
TELEGRAM_TOKEN="YOUR_BOT_TOKEN" # 如 123456:ABCDEFG
CHAT_ID="YOUR_CHAT_ID" # 如 114514
INTERFACE="eth0"  # 网卡名称

# 单位转换函数
format_units() {
    local value=$1
    local units=("B" "KB" "MB" "GB" "TB")
    local unit=0
    
    # 需要 安装 bc
    while (( $(echo "$value >= 1024" | bc -l) )) && [ $unit -lt 4 ]; do
        value=$(echo "scale=2; $value / 1024" | bc)
        ((unit++))
    done
    
    printf "%.2f %s" $value "${units[$unit]}"
}

# 获取总流量（接收和发送）
get_total_traffic() {
    local interface=$1
    local stats
    
    # 使用 ip -s link 获取流量统计
    stats=$(ip -s link show dev "$interface" 2>/dev/null)
    if [ -z "$stats" ]; then
        echo "网卡 $interface 未找到或未启用"
        return
    fi
    
    # 提取接收和发送的字节数
    rx_bytes=$(echo "$stats" | awk '/RX: bytes/ {getline a;print a}' | awk '{ print $1 }')
    tx_bytes=$(echo "$stats" | awk '/TX: bytes/ {getline a;print a}' | awk '{ print $1 }')
    
    # 转换为可读格式
    rx_converted=$(format_units "$rx_bytes")
    tx_converted=$(format_units "$tx_bytes")
    
    echo -e "📊 总流量统计 ($interface)：\n接收: $rx_converted\n发送: $tx_converted"
}

# 生成系统信息
generate_report() {
    echo "🖥️ 服务器状态报告 - $(TZ=Asia/Shanghai date '+%Y-%m-%d %H:%M:%S')"
    
    # CPU使用率
    # 需要安装 sysstat 
    echo -e "\n🔧 CPU使用率: "
    mpstat 1 1 | awk '/Average:/ {printf "User: %.2f%%\nSystem: %.2f%%\nIdle: %.2f%%\n", $3, $5, $NF}'
    
    # 内存使用
    echo -e "\n💾 内存使用: "
    free -m | awk '/Mem:/ {printf "Used: %dMB (%.2f%%)\nAvailable: %dMB\n", $3, ($3/$2)*100, $7}'
    
    # 磁盘空间
    echo -e "\n💽 磁盘使用: "
    df -h | awk '/^\/dev/ {printf "%s: %s/%s (%s used)\n", $1, $3, $2, $5}'
    
    # 网络流量
    # 需要安装 sysstat 
    echo -e "\n🌐 网络统计: "
    sar -h -n DEV 1 1 | awk -v intf="$INTERFACE" '$0 ~ intf && $1 ~ /Average/ {printf "下载: %s KB/s\n上传: %s KB/s\n", $4, $5}'
    
    # 总流量统计
    echo -e "\n$(get_total_traffic "$INTERFACE")"

    # 系统负载（详细版）
    echo -e "\n⚖️ 系统负载 (1/5/15分钟) : "
    uptime | awk -F 'load average: ' '{split($2, arr, ", "); printf "1分钟: %s\n5分钟: %s\n15分钟: %s\n", arr[1], arr[2], arr[3]}'
}

# 发送到 Telegram Bot
send_message() {
    message="$1"
    payload=$(jq -n --arg text "$message" --arg chat_id "$CHAT_ID" '{chat_id: $chat_id, text: $text}')
    curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$payload" \
        "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" > /dev/null
}

# 主程序
report=$(generate_report)
send_message "$report"