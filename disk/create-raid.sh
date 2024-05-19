#!/usr/bin/env bash
##author：wangsendi
##url：https://www.yuque.com/wangsendi
###重组阵列
__disk_raid_create() {
    echo "重组阵列"
    perccli64CmdOutput=$(perccli64 /c0/eall/sall show J)
    ugoodDisks=$(echo "$perccli64CmdOutput" | jq -r '.Controllers[0]."Response Data"."Drive Information"[] | select(.State == "UGood" and .Med == "HDD") | .["EID:Slt"]')
    # 检查是否有 UGood 状态的磁盘
    if [ -n "$ugoodDisks" ]; then
        # 删除所有现有的虚拟磁盘
        perccli64 /c0/fall del &>/dev/null

        # 为每个 UGood 状态的磁盘创建 RAID 0
        for disk in $ugoodDisks; do
            eid=${disk%:*}
            slot=${disk#*:}
            echo "正在为 EID ${eid}, Slot ${slot} 的磁盘创建 RAID 0..."
            perccli64 /c0 add vd r0 drives="${eid}":"${slot}" wb ra &>/dev/null
        done
    else
        echo "没有找到任何 UGood 状态的磁盘。"
    fi
}
__disk_raid_create