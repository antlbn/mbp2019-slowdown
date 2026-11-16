#!/bin/bash
# disk-hogs.sh — кто раздул «Системные данные». ТОЛЬКО ЧТЕНИЕ, ничего не удаляет.
# Запуск: sudo bash disk-hogs.sh     (полный обход диска может занять несколько минут)
# Совет: дай Терминалу «Полный доступ к диску» (Настройки → Конфиденциальность и безопасность),
#        иначе часть папок в ~/Library ответит «Operation not permitted».
# Результат: reports/<дата>-disk.txt (имя пользователя замаскировано).

DIR="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$DIR/reports"
OUT="$DIR/reports/$(date +%Y-%m-%d-%H%M)-disk.txt"
U="${SUDO_USER:-$USER}"
H="$(eval echo "~$U")"

section() { printf '\n===== %s =====\n' "$1"; }
run()     { printf '$ %s\n' "$*"; eval "$@" 2>&1; }

{
section "Общая картина"
run "df -h /System/Volumes/Data"
run "diskutil apfs list | grep -E 'Name:|Capacity Consumed|Role'"

section "Топ-15 папок верхнего уровня тома Data"
run "du -xhd1 /System/Volumes/Data 2>/dev/null | sort -h | tail -n 15"

section "Пользовательская Library: топ-15"
run "du -hd1 '$H/Library' 2>/dev/null | sort -h | tail -n 15"
run "du -hd1 '$H/Library/Containers' '$H/Library/Group Containers' 2>/dev/null | sort -h | tail -n 15"
run "du -hd1 '$H/Library/Application Support' 2>/dev/null | sort -h | tail -n 15"
run "du -hd1 '$H/Library/Caches' 2>/dev/null | sort -h | tail -n 10"

section "Xcode и симуляторы (частый виновник)"
run "du -sh '$H/Library/Developer'/* 2>/dev/null"
run "du -sh /Library/Developer/CoreSimulator/* 2>/dev/null"
run "sudo -u '$U' xcrun simctl runtime list 2>/dev/null || echo 'simctl runtime: недоступно'"
run "sudo -u '$U' xcrun simctl list devices 2>/dev/null | grep -c -E '\\(([0-9A-F-]{36})\\)' | sed 's/^/устройств симулятора: /'"
run "df -h | grep -i -E 'simulator|CoreSimulator' || echo 'смонтированных образов симулятора нет'"

section "Виртуальные машины и контейнеры"
run "du -sh '$H/Library/Containers/com.docker.docker' 2>/dev/null"
run "find '$H/Library' -maxdepth 6 \\( -name '*.raw' -o -name '*.img' -o -name '*.qcow2' -o -name '*.vmdk' -o -name 'disk.img' \\) -size +1G -exec ls -lh {} \\; 2>/dev/null"

section "Своп, снимки, логи, бэкапы iPhone"
run "ls -lh /System/Volumes/VM"
run "tmutil listlocalsnapshots /"
run "du -sh /private/var/log /private/var/folders /Library/Logs '$H/Library/Logs' 2>/dev/null"
run "du -sh '$H/Library/Application Support/MobileSync/Backup' 2>/dev/null"
run "du -sh '$H/Library/Containers/com.apple.mediaanalysisd' 2>/dev/null"

section "Файлы крупнее 5 ГБ на томе Data"
run "find /System/Volumes/Data -xdev -type f -size +5G -exec ls -lh {} \\; 2>/dev/null | awk '{print \$5, \$9, \$10, \$11}'"
} | sed "s#/Users/[^/]*/#/Users/<user>/#g" > "$OUT"

[ -n "$SUDO_USER" ] && chown -R "$SUDO_USER" "$DIR/reports"
echo "Готово: $OUT"
