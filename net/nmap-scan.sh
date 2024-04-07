#!/usr/bin/env bash
##author：wangsendi
##url：https://www.yuque.com/wangsendi
###用于网段扫描，局域网端口扫描
function scan_subnet() {
    local subnet=$1

    nmap -sS -Pn -n --open --min-hostgroup 4 --min-parallelism 1024 --host-timeout 30 -T4 "$subnet" 2>/dev/null | awk '
                                                                                                                       /Nmap scan report for/{
                                                                                                                           if (ip) print "";  
                                                                                                                           ip=$NF; printf "%s\nPORT        STATE        SERVICE\n", ip; next
                                                                                                                       }
                                                                                                                       /[0-9]+\/tcp +open +/{printf "%-11s %-12s %s\n", $1, $2, $3}
                                                                                                                       END{
                                                                                                                           if (ip) print "";  
                                                                                                                       }'
}

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <subnet>"
    exit 1
fi

scan_subnet "$1"
