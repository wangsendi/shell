#!/usr/bin/env bash

__cpu() {
    local interval=${1:-3} # 采样间隔，可以作为参数传递，默认3秒

    old=$(awk '/cpu[0-9]/{for(i=2;i<=NF;i++){sum+=$i;if(i!=6&&i!=7)user+=$i};print $1,sum,user}' /proc/stat)
    sleep "$interval"
    new=$(awk '/cpu[0-9]/{for(i=2;i<=NF;i++){sum+=$i;if(i!=6&&i!=7)user+=$i};print $1,sum,user}' /proc/stat)

    # 计算每个核心的使用率
    usage=$(echo "$old" "$new" | xargs -n3 | awk '{sum[$1,++t[$1]]=$2;user[$1,++p[$1]]=$3;}END{for(i in t)print i,(user[i,2]-user[i,1])/(sum[i,2]-sum[i,1])*100}')

    # 使用jq构造JSON输出
    json="{}"
    while read -r line; do
        key=$(echo "$line" | awk '{print $1}')
        value=$(echo "$line" | awk '{print $2}')
        json=$(echo "$json" | jq --arg k "$key" --argjson v "$value" '.[$k]=$v')
    done <<<"$usage"

    # 输出json
    echo "$json"
}

# 调用函数，第一个参数为采样间隔
__main() {

    _Json=$(
        _time1=$(date '+%s')
        _time2=$(date -d @"$_time1" +'%Y-%m-%d %T')
        echo "{}" |
            jq --arg v "$_time1" '.time[1]=$v' |
            jq --arg v "$_time2" '.time[0]=$v' |
            jq --argjson v "$(__cpu 3)" '.data=$v' |
            jq -c
    )
    echo "$_Json"
}
__main
