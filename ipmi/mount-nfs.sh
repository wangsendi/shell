#!/usr/bin/env bash
##有待完善
_ip=$1
__nfs_install() {
    if [ -n "$(systemctl status nfs | grep "active")" ]; then
        return
    fi
    bash <(curl -fsSL https://raw.githubusercontent.com/wangsendi/shell/main/yum/mirror.sh)
    rpm -q ipmitool >/dev/null 2>&1 || yum -y install ipmitool
    rpm -q aria2 >/dev/null 2>&1 || yum -y install aria2
    rpm -q nfs-utils >/dev/null 2>&1 || yum -y install nfs-utils
    rpm -q rpcbind >/dev/null 2>&1 || yum -y install rpcbind

    ADDRESS=$(ipmitool lan print | grep -v 'IP Address Source' | awk -F '.' '/^IP\sAddress/{print $2}')

    # 下载镜像保存到指定目录
    aria2c -x 8 --conditional-get=true -d /nfs "http://xxxx:56681/iso/centos7-bd_idc-2023-04-06-01.iso"

    echo "/nfs 10.$ADDRESS.0.0/16(ro,sync,all_squash)" >/etc/exports && exportfs -rv
    systemctl restart nfs rpcbind

}
#  __nfs_install

__login() {
    _res=$(curl -sSLi  -w '\n' -k -X post -c .cookie.txt -d 'user=root&password=abcd001002' https://"$1"/data/login 2>&1)
    _ST2="$(echo "$_res" | grep ST2 | awk -F '=|,|<' '{print $(NF-2)}')"

}
__images() {
    _images_res=$(curl -sSL  -w '\n' -k -X post "$_head" -H "ST2:$_ST2" -b .cookie.txt -d "data=remoteFileshrPwd:,remoteFileshrUser:,remoteFileshrImage:$_images,remoteFileshrAction:1" https://"$1"/postset?attachmedia)
    echo "$_images_res"
}

__guide() {
    _guide_res=$(curl -sSL  -w '\n' -k -X post "$_head" -H "ST2:$_ST2" -b .cookie.txt https://"$1"/data?set=vmBootOnce:1,firstBootDevice:8)
}

__cold_guidance() {
    _cold_guidance=$(curl  -sSL -w '\n' -k -X post "$_head" -H "ST2:$_ST2" -b .cookie.txt https://"$1"/data?set=pwState:2)
}
__main() {

    if [ ! -f ipmi.txt ]; then
        touch ipmi.txt
        echo "请忘ipmi.txt里面写ipmi"
    fi
    #有些ssl较老  然后会挂不上镜像啥的问题  加上这个就可以
    # if [ -f /etc/ssl/openssl.cnf ] || [ -f /etc/pki/tls/openssl.cnf ]; then
    #     sed -i 's/CipherString = DEFAULT@SECLEVEL=1/#CipherString = DEFAULT@SECLEVEL=1/g' /etc/ssl/openssl.cnf
    # fi

    _ipmi=$(cat ipmi.txt)
    # _ipmi="10.52.18.1"
    if [ -n "$_ip" ]; then
        _images="$_ip\:/nfs/centos7-bd_idc-2023-04-06-01.iso"
    else
        __nfs_install
        _images="$(ipmitool lan print | awk '/IP Address/{print $NF}' | grep "[0-9]" |sed 's/.1$/.3/')\:/nfs/centos7-bd_idc-2023-04-06-01.iso"

    fi
    echo "$_images"

    _head="-H 'Connection:keep-alive' -H 'Content-Type:application/x-www-form-urlencoded' -H 'Accept:*/*'"
    for item in $_ipmi; do
        echo "$item start"
        __login "$item"
        if [ "$(echo "$_res" | grep "ST2" -c)" -eq 0 ]; then
            echo "$item""login error"
            rm -rf .cookie.txt
            continue
        else
            echo "$item" ok
        fi

        __images "$item"
        if [ "$(echo "$_images_res" | grep "ok" -c)" -eq 0 ]; then
            echo "$item""images error"
            rm -rf .cookie.txt
            continue
        else
            echo "$item" ok
            echo "$_images_res"
        fi

        __guide "$item"
        if [ "$(echo "$_guide_res" | grep "ok" -c)" -eq 0 ]; then
            echo "$item""guide error"
            rm -rf .cookie.txt
            continue
        else
            echo "$item" ok
            echo "$_guide_res"
        fi

        __cold_guidance "$item"
        if [ "$(echo "$_cold_guidance" | grep "ok" -c)" -eq 0 ]; then
            echo "$item""cold error"
            rm -rf .cookie.txt
            continue

        else
            echo "$item" ok
            echo "$_cold_guidance"
        fi
        rm -rf .cookie.txt
    done
}
__main
