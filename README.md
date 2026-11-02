# devops-journey
My personal DevOps homelab: scripts, write-ups, and infrastructure-as-code projects as I go from SysAdmin to DevOps Engineer


   ## 🤖 Автоматизация (Cron)
   Скрипт настроен на автоматический ежедневный запуск в 03:00 ночи.
   
   **Как это работает:**
   Задача добавлена в планировщик `cron` через `crontab -e`:
   ```bash
   0 3 * * * /home/kali/first_script.sh >> /home/kali/logs/cron_run.log 2>&1
