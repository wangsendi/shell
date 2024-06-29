#!/usr/bin/env bash
# shellcheck disable=SC1091

__retransmit_rate() {
    _initial_stats=$(grep -i "tcp:" /proc/net/snmp)
    _init_segments_start=$(awk '{_line=$12}END{print _line}' <<<"$_initial_stats")
    _retran_segments_start=$(awk '{_line=$13}END{print _line}' <<<"$_initial_stats")

    sleep 30s

    _later_stats=$(grep -i "tcp:" /proc/net/snmp)
    _init_segments_end=$(awk '{_line=$12}END{print _line}' <<<"$_later_stats")
    _retran_segments_end=$(awk '{_line=$13}END{print _line}' <<<"$_later_stats")

    _total_segments=$((_init_segments_end - _init_segments_start))
    _total_retrans=$((_retran_segments_end - _retran_segments_start))

    if [[ $_total_segments -ne 0 ]]; then
        _retransmit_rate=$(bc <<<"scale=2; ($_total_retrans/$_total_segments)*100")
    else
        _retransmit_rate=0
    fi
    echo "$_retransmit_rate"
}

__main() {

    _time1=$(date '+%s')
    _time2=$(date -d @"$_time1" +'%Y-%m-%d %T')

    _json=$(jq -c \
        --arg time "$_time2" \
        --arg timestamp "$_time1" \
        --argjson retransmit_rate "$(__retransmit_rate)" \
        '{ time: [$time, $timestamp], data: { rate: $retransmit_rate } }' <<<'{}')

    echo "$_json"

}
__main
