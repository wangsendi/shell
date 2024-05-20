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

# 函数：获取所有温度传感器的信息
function get_ipmi_temperature_sensors() {
    echo "IPMI Temperature Sensors:"
    ipmitool sensor list | awk -F'|' '$3 ~ /degrees C/ {print $1, $2, $4}'
}

function get_fan_speed(){
    echo "IPMI Fan speed"
    ipmitool sensor list  |grep -E 'Fan[0-9]{1,2}\sRPM' | awk -F'|' '{print $1,$2,$4}'
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
    get_ipmi_temperature_sensors
    echo "=========================="
    get_fan_speed
    echo "=========================="
    get_ipmi_sel
    echo "=========================="
    get_ipmi_lan_config
    echo "=========================="
}

# 执行主函数
main