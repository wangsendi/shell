#!/bin/bash

function state_flow() {
    local update_interval=${1:-1}  # 默认更新间隔为1秒
    local unit_scale=${2:-131072}  # 默认单位为Mbps (131072 = 1024 * 1024 / 8)
    local unit_name="Mbps"
    declare -A tx_stats rx_stats

    local nic_list=$(grep -v -f <(ls -1 /sys/devices/virtual/net/) <(ls -1 /sys/class/net/))

    echo -e "\033[36m=== STATE flow ===\033[32m\nUpdate Time: $(date "+%Y-%m-%d %H:%M:%S")\033[0m"

    function get_flow() {
        for item in $nic_list; do
            tx_stats[$item]=$(cat /sys/class/net/${item}/statistics/tx_bytes 2>/dev/null)
            rx_stats[$item]=$(cat /sys/class/net/${item}/statistics/rx_bytes 2>/dev/null)
        done
    }

    function calculate_and_print() {
        local total_tx=0 total_rx=0
        for item in $nic_list; do
            local current_tx=$(cat /sys/class/net/${item}/statistics/tx_bytes 2>/dev/null)
            local current_rx=$(cat /sys/class/net/${item}/statistics/rx_bytes 2>/dev/null)
            local tx_diff=$(( (current_tx - tx_stats[$item]) / unit_scale ))
            local rx_diff=$(( (current_rx - rx_stats[$item]) / unit_scale ))
            total_tx=$((total_tx + tx_diff))
            total_rx=$((total_rx + rx_diff))
            tx_stats[$item]=$current_tx
            rx_stats[$item]=$current_rx
        done
        printf "Total TX: %04d $unit_name   Total RX: %04d $unit_name\n" "$total_tx" "$total_rx"
    }

    get_flow  # 初始化统计数据
    while true; do
        sleep "$update_interval"
        calculate_and_print
    done
}

state_flow "$@"