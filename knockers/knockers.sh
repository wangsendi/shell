#!/usr/bin/env bash
##author：wangsendi
##url：https://www.yuque.com/wangsendi
###端口敲门   __help中使用方法 allow 是要访问的端口  knowk 是敲门端口 依次敲门就行

# 默认值
_allow=false
_knowk=false
_allow_values=""
_knowk_values=""

# 解析参数
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
    -allow)
        _allow=true
        shift
        _allow_values="$1"
        shift
        ;;
    -knowk)
        _knowk=true
        shift
        _knowk_values="$1"
        shift
        ;;
    *)
        # 对于未知参数，你可以选择忽略或者给出错误信息
        echo "Unknown option: $1"
        shift
        ;;
    esac
done
__main() {
    # 转换逗号分隔的字符串为数组
    mapfile -d , -t _allow_ports < <(echo -n "$_allow_values" | tr -d '\n')
    mapfile -d , -t _knowk_ports < <(echo -n "$_knowk_values" | tr -d '\n')

    # 打印参数值
    echo "allow_ports: ${_allow_ports[*]}"
    echo "knowk_ports: ${_knowk_ports[*]}"

    {

        #开始执行的通用rule
        nft delete table inet portknock
        nft add table inet portknock
        # 创建链
        nft add chain inet portknock input '{ type filter hook input priority -10 ; policy accept ; }'

        nft add set inet portknock guarded_ports '{ type inet_service; }'
        nft add element inet portknock guarded_ports \{ "${_allow_values}" \}

        # 定义客户端 IPv4 地址集合
        nft add set inet portknock clients_ipv4 '{ type ipv4_addr; flags timeout; }'

        # 定义客户端 IPv6 地址集合
        nft add set inet portknock clients_ipv6 '{ type ipv6_addr; flags timeout; }'

        # 定义 IPv4 候选者集合
        nft add set inet portknock candidates_ipv4 '{ type ipv4_addr . inet_service; flags timeout; }'

        # 定义 IPv6 候选者集合
        nft add set inet portknock candidates_ipv6 '{ type ipv6_addr . inet_service; flags timeout; }'

        # 定义 input 链
        nft add chain inet portknock input '{ type filter hook input priority -10; policy accept; }'

        # 如果是本地回环接口，则返回
        nft add rule inet portknock input iifname "lo" return
    }
    for item in $(seq 0 $((${#_knowk_ports[@]} - 1))); do
        case "${item}" in
        0)
            nft add rule inet portknock input tcp dport "${_knowk_ports[$item]}" add @candidates_ipv4 \{ ip saddr . "${_knowk_ports[item + 1]}" timeout 10s \}
            nft add rule inet portknock input tcp dport "${_knowk_ports[$item]}" add @candidates_ipv6 \{ ip6 saddr . "${_knowk_ports[item + 1]}" timeout 10s \}
            ;;
        "$((${#_knowk_ports[@]} - 1))")
            nft add rule inet portknock input tcp dport "${_knowk_ports[$item]}" ip saddr . tcp dport @candidates_ipv4 add @clients_ipv4 '{ ip saddr timeout 10s }' log prefix '"Successful portknock: "'
            nft add rule inet portknock input tcp dport "${_knowk_ports[$item]}" ip6 saddr . tcp dport @candidates_ipv6 add @clients_ipv6 '{ ip6 saddr timeout 10s }' log prefix '"Successful portknock: "'
            ;;
        *)
            nft add rule inet portknock input tcp dport "${_knowk_ports[$item]}" ip saddr . tcp dport @candidates_ipv4 add @candidates_ipv4 \{ ip saddr . "${_knowk_ports[item + 1]}" timeout 10s \}
            nft add rule inet portknock input tcp dport "${_knowk_ports[$item]}" ip6 saddr . tcp dport @candidates_ipv6 add @candidates_ipv6 \{ ip6 saddr . "${_knowk_ports[item + 1]}" timeout 10s \}
            ;;
        esac

    done
    {
        # 保护规则
        nft add rule inet portknock input tcp dport @guarded_ports ip saddr @clients_ipv4 counter accept
        nft add rule inet portknock input tcp dport @guarded_ports ip6 saddr @clients_ipv6 counter accept
        nft add rule inet portknock input tcp dport @guarded_ports ct state established,related counter accept
        nft add rule inet portknock input tcp dport @guarded_ports counter reject with tcp reset
    }
}
__main

__help() {
    bash /apps/data/workspace/default/shell/knockers/knockers.sh -allow 22 -knowk 88,99,33,44
}
