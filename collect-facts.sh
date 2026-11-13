#!/bin/bash
# collect-facts.sh — сбор фактов о тормозящем MacBook Pro 2019.
# Уровень R0: ТОЛЬКО ЧТЕНИЕ, ничего в системе не меняет.
# Запуск:          bash collect-facts.sh            (без sudo, базовый отчёт)
#                  sudo bash collect-facts.sh       (+ температуры, частоты, мощность)
# Результат: reports/<дата>-<battery|ac>.txt (имя пользователя замаскировано).

DIR="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$DIR/reports"
OUT="$DIR/reports/$(date +%Y-%m-%d-%H%M)-$( [ "$(pmset -g batt | head -1 | grep -c Battery)" = 1 ] && echo battery || echo ac).txt"

section() { printf '\n===== %s =====\n' "$1"; }
run()     { printf '$ %s\n' "$*"; eval "$@" 2>&1; }

{
section "Система и модель"
run sw_vers
run uptime
run "sysctl -n kern.boottime"
run "system_profiler SPHardwareDataType | grep -E 'Model|Processor|Cores|Memory|Chip'"
run "system_profiler SPDisplaysDataType | grep -E 'Chipset|VRAM|Resolution|Display Type|Connection|Online|Main Display|Looks like'"
run "pmset -g | grep -i gpuswitch"   # 0 = только Intel, 1 = только AMD, 2 = авто (значения сверить)

section "Тепло и троттлинг"
run pmset -g therm            # CPU_Speed_Limit < 100 = троттлинг
run "pmset -g | grep -Ei 'gpuswitch|lowpowermode|powernap|sleep'"

section "Питание и аккумулятор"
run pmset -g batt
run "system_profiler SPPowerDataType | grep -E 'Cycle Count|Condition|Maximum Capacity|Wattage|Connected'"

section "Память"
run "memory_pressure | tail -n 3"
run sysctl vm.swapusage
run "vm_stat | head -n 12"

section "Диск"
run "df -h / /System/Volumes/Data"   # свободное место смотреть по Data
run "tmutil listlocalsnapshots / | wc -l"

section "Spotlight"
run "mdutil -sa"

section "Топ процессов по CPU (2 замера, берётся второй)"
run "top -l 2 -o cpu -n 15 -stats pid,command,cpu,mem,threads | tail -n 17"

section "Топ процессов по памяти"
run "top -l 1 -o mem -n 12 -stats pid,command,mem,cpu | tail -n 13"

section "Фоновые ML/индексация — запущены ли сейчас"
run "ps -axo pid,%cpu,%mem,etime,comm | grep -Ei 'mediaanalysisd|photoanalysisd|photolibraryd|mds|mdworker|corespotlight|knowledge|suggestd|WindowServer|kernel_task' | grep -v grep"

section "Визуальные настройки"
run "defaults read com.apple.universalaccess reduceTransparency"
run "defaults read com.apple.universalaccess reduceMotion"

section "Сторонние расширения"
run "kextstat 2>/dev/null | grep -v com.apple | tail -n +2"
run "systemextensionsctl list"

section "Автозагрузка (сторонние агенты)"
run "ls /Library/LaunchAgents /Library/LaunchDaemons ~/Library/LaunchAgents"

if [ "$(id -u)" -eq 0 ]; then
  section "powermetrics: частоты, температура, вентилятор (5 с)"
  run "powermetrics --samplers smc,cpu_power,gpu_power -i 1000 -n 5 | grep -Ei 'CPU die temperature|GPU die temperature|Fan|CPU Average frequency|Package Power|GPU Active|frequency as fraction'"

  section "Кто грузит GPU: время GPU по процессам (5 с; на Intel может быть пусто — это тоже ответ)"
  run "powermetrics --samplers tasks --show-process-coalition --show-process-gpu -n 1 -i 5000 | head -n 60"
else
  section "powermetrics пропущен (нужен sudo)"
fi
} | sed "s#/Users/[^/]*/#/Users/<user>/#g" > "$OUT"   # имя пользователя маскируется

[ -n "$SUDO_USER" ] && chown -R "$SUDO_USER" "$DIR/reports"   # чтобы отчёт не принадлежал root
echo "Готово: $OUT"
