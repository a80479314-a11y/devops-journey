#!/bin/bash

# ============================================
# system_info.sh — сбор информации о системе
# Автор: amal-devops
# ============================================

# Создаём папку для отчётов, если её нет
LOG_DIR="$HOME/logs"
REPORT_FILE="$LOG_DIR/system_report.txt"
mkdir -p "$LOG_DIR"

# Очищаем старый отчёт перед новым запуском
> "$REPORT_FILE"

# Функция для записи в файл И вывода на экран одновременно
report() {
    echo "$1" | tee -a "$REPORT_FILE"
}

report "============================================"
report "📊 ОТЧЁТ О СИСТЕМЕ"
report "📅 Дата: $(date '+%Y-%m-%d %H:%M:%S')"
report "============================================"
report ""

# 1. Кто я и где я
report "👤 ПОЛЬЗОВАТЕЛЬ И ХОСТ:"
report "   Пользователь: $(whoami)"
report "   Хост: $(hostname)"
report ""

# 2. Версия ОС (берём только первую строку с именем)
report "🐧 ВЕРСИЯ ОС:"
report "   $(cat /etc/os-release | grep PRETTY_NAME | cut -d '=' -f2 | tr -d '"')"
report ""

# 3. Ядро системы
report "⚙️ ЯДРО СИСТЕМЫ:"
report "   $(uname -r)"
report ""

# 4. Сколько работает система
report "⏱ ВРЕМЯ РАБОТЫ (UPTIME):"
report "   $(uptime -p)"  # -p делает вывод красивым (например: "up 3 hours, 15 minutes")
report ""

# 5. Оперативная память
report "🧠 ОПЕРАТИВНАЯ ПАМЯТЬ:"
free -h >> "$REPORT_FILE"
free -h
report ""

# 6. Состояние диска
report "💾 СОСТОЯНИЕ ДИСКА:"
df -h / >> "$REPORT_FILE"
df -h /
report ""

# 7. Сетевые интерфейсы (IP-адрес)
report "🌐 СЕТЕВЫЕ ИНТЕРФЕЙСЫ:"
hostname -I >> "$REPORT_FILE"
hostname -I
report ""

report "============================================"
report "✅ Отчёт сохранён в: $REPORT_FILE"
report "============================================"
