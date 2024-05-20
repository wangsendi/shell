#!/bin/bash

# 检查ipmitool是否安装
if ! command -v ipmitool &> /dev/null
then
    echo "ipmitool could not be found, please install it first."
    exit
fi

# 函数：获取IPMI设备信息
function get_ipmi_device_info() {
    echo "IPMI Device Information:"
    ipmitool mc info | grep -E 'Manufacturer Name|Device ID|Firmware Revision'
}

# 函数：获取传感器列表的关键信息
function get_ipmi_sensors() {
    echo "Critical IPMI Sensors Status:"
    ipmitool sensor list | awk -F'|' '$4 ~ /ok/ && ($2 ~ /degrees C/ || $2 ~ /Volts/ || $2 ~ /Watts/ || $2 ~ /Amps/)' | cut -d'|' -f1,2
}

# 函数：获取系统事件日志的最近5条记录
function get_ipmi_sel() {
    echo "Recent System Event Log (SEL) Entries:"
    ipmitool sel list | head -5
}

# 函数：获取LAN配置的关键信息
function get_ipmi_lan_config() {
    echo "IPMI LAN Configuration:"
    ipmitool lan print | grep -E 'IP Address|Subnet Mask|Default Gateway IP'
}

# 主函数
function main() {
    echo "=========================="
    get_ipmi_device_info
    echo "=========================="
    get_ipmi_sensors
    echo "=========================="
    get_ipmi_sel
    echo "=========================="
    get_ipmi_lan_config
    echo "=========================="
}

main