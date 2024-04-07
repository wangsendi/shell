#!/usr/bin/env bash
##author：wangsendi
##url：https://www.yuque.com/wangsendi
###系统内调整cpu性能模式
__main() {
    
    if ! command -v cpupower &>/dev/null; then
        echo "cpupower 未安装,请先安装 cpupower : apt install -y linux-cpupower"
        exit 1
    fi

    max_freq=$(cpupower -c all frequency-info | awk '/hardware limits:/ {print $(NF-1)$NF}' | sort -n | tail -n 1)

    cpupower frequency-set -g performance
    cpupower frequency-set -f "${max_freq}"
    cpupower frequency-set -u "${max_freq}"
    cpupower frequency-set -d "${max_freq}"


    echo "CPU 频率已设置为最大值: ${max_freq}"
}
__main