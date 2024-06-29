#!/usr/bin/env bash
__main() {
    _nic="eth5"
    _eth_crc_err=$(ethtool -S $_nic | awk '/_crc/{print $NF}')
    if [ "$_eth_crc_err" -ne 0 ]; then
        echo "网卡丢包,请检查网卡"
    fi
    _nets_ovr=$(netstat -i | tail -n +2 | column -t | awk '{if ($10 != 0)print $0}')
    if [ "$(wc -l < <(echo "$_nets_ovr"))" -ne 1 ]; then
        echo -e "RX_OVR一直在增加,Ringbuffer有溢出 \n $_nets_ovr"

    fi
    _ker_lost=$(awk 'BEGIN{err=0}{if ($2 != 00000000)err=1;exit}END{print err}' /proc/net/softnet_stat)
    if [ "$_ker_lost" -ne 0 ]; then
        echo "backlog队列溢出,可设置 sysctl -w net.core.netdev_max_backlog=2000"
    fi
    _buf_err=$(netstat -s | grep -E '(receive|send) buffer errors' | awk 'BEGIN{err=0}{if ($1 != 0) err=1;exit}END{print err}')
    if [ "$_ker_lost" -ne 0 ]; then
        echo "收发队列太小,sysctl -w net.core.rmem_max=26214400 # 设置为 25M,sysctl -w net.core.wmem_max=26214400 # 设置为 25M"
    fi
    echo "详细参考:https://www.yuque.com/wangsendi/linux/packet_lost"
}
__main
