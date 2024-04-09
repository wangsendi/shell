#!/usr/bin/env bash
##author：wangsendi
##url：https://www.yuque.com/wangsendi
###安装perccli
__dl() {
    mkdir -p /tmp/perccli
    curl -o - 'https://dl.dell.com/FOLDER09770976M/1/PERCCLI_7.2313.0_A14_Linux.tar.gz' \
        -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36' | tar zxvf - --strip-components=1 -C /tmp/perccli

}

__main() {
    __dl
    if ! command -v perccli64 &>/dev/null; then
        _os=$(grep -E 'debian|centos' -o /etc/os-release | uniq)
        case "${_os}" in
        centos)
            rpm -qa | grep perccli | xargs rpm -e
            rpm --import /tmp/perccli/pubKey.asc
            rpm -i /tmp/perccli/*.rpm
            ln -s /opt/MegaRAID/perccli/perccli64 /usr/local/bin/
            ;;
        debian)
            dpkg -i /tmp/perccli/*.deb
            ;;
        *)
            echo "not found os "
            ;;
        esac
        rm -rf /tmp/perccli
    fi
}
__main
