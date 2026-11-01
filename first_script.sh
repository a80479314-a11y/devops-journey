#!/bin/bash

# Создаём папку для логов, если её нет
LOG_DIR="$HOME/logs"
LOG_FILE="$LOG_DIR/maintenance.log"
mkdir -p "$LOG_DIR"

# Функция для записи в лог и на экран одновременно
log() {
    echo "$1" | tee -a "$LOG_FILE"
}

log "$(date '+%F %T') | === Начало обслуживания ==="
log "$(date '+%F %T') | Привет, $(whoami)! Хост: $(hostname)"

log "$(date '+%F %T') | 📦 Обновляю репозитории..."
sudo apt-get update -y > /dev/null 2>&1
log "$(date '+%F %T') | ✅ Репозитории обновлены"

log "$(date '+%F %T') | 🧹 Чищу систему..."
sudo apt-get autoremove -y > /dev/null 2>&1
sudo apt-get clean
log "$(date '+%F %T') | ✅ Система чиста"

log "$(date '+%F %T') | 💾 Состояние диска:"
df -h / | awk 'NR==2{print "   Корневой раздел: " $2 " занято, " $3 " использовано, " $4 " свободно (" $5 ")"}' >> "$LOG_FILE"
df -h / | awk 'NR==2{print "   Корневой раздел: " $2 " занято, " $3 " использовано, " $4 " свободно (" $5 ")"}'

log "$(date '+%F %T') | 🎉 Обслуживание завершено!"
log "-------------------------------------------"
