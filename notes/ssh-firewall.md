# 🔐 SSH и Firewall — практическое руководство

*Автор: amal-devops | Обновлено: 2026-11-13*

---

## 1. Что такое SSH

**SSH (Secure Shell)** — сетевой протокол прикладного уровня для удалённого управления ОС и туннелирования TCP-соединений.

**Порт по умолчанию:** `22/tcp`

### Зачем нужен
- Вход на удалённые серверы (текстовый терминал)
- Передача файлов (`scp`, `sftp`, `rsync`)
- Туннелирование трафика (проброс портов)
- Запуск графических приложений удалённо (X11 forwarding)
- Автоматизация: скрипты, Ansible, CI/CD — всё работает через SSH

**Главное отличие от Telnet:** весь трафик зашифрован. Пароль нельзя перехватить в сети.

---

## 2. Подключение по паролю

```bash
ssh user@192.168.1.100          # подключиться к серверу по IP
ssh user@server.com             # по доменному имени
ssh -p 2222 user@server         # нестандартный порт
ssh amal@localhost              # подключиться к своей же машине (для тренировки)
```

При первом подключении появится вопрос:
```
The authenticity of host '...' can't be established.
ED25519 key fingerprint is SHA256:...
Are you sure you want to continue connecting (yes/no)?
```
Отвечай `yes` — это нормально. Отпечаток сервера сохранится в `~/.ssh/known_hosts`.

**Выход из сессии:**
```bash
exit        # или Ctrl+D
```

---

## 3. SSH-ключи (вход без пароля)

Вместо пароля используется **пара криптографических ключей**:

| Ключ | Файл | Где хранится | Права | Кому показывать |
|---|---|---|---|---|
| Приватный | `id_ed25519` | только у тебя | `600` | ❌ НИКОМУ |
| Публичный | `id_ed25519.pub` | на серверах | `644` | ✅ всем серверам |

### Как работает
1. Ты генерируешь пару ключей на своей машине
2. Публичный ключ кладёшь на сервер в `~/.ssh/authorized_keys`
3. При подключении сервер проверяет: есть ли у клиента приватный ключ, соответствующий публичному
4. Если да — пускает без пароля

### Генерация ключей
```bash
ssh-keygen -t ed25519 -C "amal-devops"
```
- `-t ed25519` — современный алгоритм (быстрый, безопасный, короткий ключ)
- `-C "комментарий"` — метка, чтобы помнить, для чего ключ

Альтернатива для старых систем:
```bash
ssh-keygen -t rsa -b 4096 -C "amal-devops"
```

**Вопросы при генерации:**
- `Enter file in which to save the key` → Enter (путь по умолчанию `~/.ssh/id_ed25519`)
- `Enter passphrase` → можно оставить пустым для тренировки, но **в реальной работе ставь пароль на ключ!**

### Копирование ключа на сервер
```bash
ssh-copy-id amal@192.168.1.100
ssh-copy-id -p 2222 amal@server      # с нестандартным портом
```
*(Введёшь пароль пользователя один раз — последний раз!)*

### Проверка
```bash
ssh amal@192.168.1.100
```
Если пароль не спросил — всё работает. 🎉

### Что лежит в ~/.ssh/
```bash
ls -la ~/.ssh/
```
```
id_ed25519          ← приватный ключ (600)
id_ed25519.pub      ← публичный ключ (644)
known_hosts         ← отпечатки серверов, к которым подключался
authorized_keys     ← публичные ключи тех, кто может входить НА эту машину
config              ← настройки подключений (создаётся вручную)
```

---

## 4. Файл конфигурации SSH (~/.ssh/config)

Чтобы не писать длинные команды каждый раз, создай алиасы:

```bash
nano ~/.ssh/config
```

```
Host myserver
    HostName 192.168.1.100
    User amal
    Port 22
    IdentityFile ~/.ssh/id_ed25519

Host github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
```

Теперь вместо `ssh amal@192.168.1.100` достаточно:
```bash
ssh myserver
```

Права на файл:
```bash
chmod 600 ~/.ssh/config
```

---

## 5. Передача файлов: SCP и RSYNC

### SCP (Secure Copy) — как `cp`, но между машинами

```bash
# С сервера к себе
scp amal@server:/tmp/file.txt /home/amal/

# С себя на сервер
scp /home/amal/file.txt amal@server:/tmp/

# Папку целиком (флаг -r)
scp -r /home/amal/folder/ amal@server:/tmp/

# С нестандартным портом (флаг -P заглавная!)
scp -P 2222 file.txt amal@server:/tmp/
```

**Синтаксис:** `scp <откуда> <куда>`  
Удалённый путь всегда пишется как `user@host:/путь`

### RSYNC — умнее и быстрее
Копирует только изменившиеся части файлов. Идеально для бэкапов.

```bash
rsync -avz /home/amal/folder/ amal@server:/backup/
```
- `-a` — архивный режим (сохраняет права, даты, симлинки)
- `-v` — подробный вывод
- `-z` — сжатие при передаче

---

## 6. Что такое Firewall

**Firewall (брандмауэр)** — фильтр, который проверяет каждый сетевой пакет, входящий в систему или выходящий из неё, и решает: пропустить или заблокировать.

### Виды
- **По расположению:** на базе сети (аппаратный) или на базе хоста (программный)
- **По уровню:** фильтрация сетевого уровня (IP/порты) или прикладного (HTTP-запросы)

### Основные инструменты в Linux
| Инструмент | Дистрибутив | Сложность |
|---|---|---|
| **UFW** | Ubuntu, Debian | простая обёртка |
| **Firewalld** | CentOS, RHEL, Fedora | зоны, средняя |
| **iptables / nftables** | любой | низкий уровень, сложная |

---

## 7. UFW — Uncomplicated FireWall (Ubuntu)

### ⚠️ ГЛАВНОЕ ПРАВИЛО
**Сначала разреши SSH, потом включай firewall!**  
Иначе заблокируешь сам себя и потеряешь доступ к серверу.

### Правильная последовательность настройки
```bash
# 1. Разрешаем SSH ДО включения
sudo ufw allow OpenSSH
# или
sudo ufw allow 22/tcp

# 2. Политика по умолчанию: всё входящее запрещаем
sudo ufw default deny incoming

# 3. Исходящее разрешаем (чтобы работал apt, curl и т.д.)
sudo ufw default allow outgoing

# 4. Включаем
sudo ufw enable

# 5. Проверяем
sudo ufw status verbose
```

### Полный список команд UFW

| Команда | Что делает |
|---|---|
| `enable` | включить firewall + добавить в автозагрузку |
| `disable` | отключить firewall + убрать из автозагрузки |
| `reload` | перезагрузить правила |
| `default` | политика по умолчанию (`allow`/`deny`/`reject` + `incoming`/`outgoing`/`routed`) |
| `logging` | включить журналирование или изменить уровень |
| `reset` | сбросить все настройки до состояния по умолчанию |
| `status` | посмотреть состояние и правила |
| `show` | посмотреть один из отчётов о работе |
| `allow` | добавить разрешающее правило |
| `deny` | добавить запрещающее правило (молча отбросить) |
| `reject` | добавить отбрасывающее правило (с ответом отправителю) |
| `limit` | лимитирующее правило (защита от брутфорса) |
| `delete` | удалить правило |
| `insert` | вставить правило в определённую позицию |

### Примеры правил
```bash
sudo ufw allow 80/tcp              # HTTP
sudo ufw allow 443/tcp             # HTTPS
sudo ufw allow 8080/tcp            # своё приложение
sudo ufw allow 3000:3010/tcp       # диапазон портов
sudo ufw deny 3306/tcp             # закрыть MySQL от внешнего мира
sudo ufw allow from 192.168.1.50   # разрешить всё с конкретного IP
sudo ufw allow from 192.168.1.0/24 to any port 22   # SSH только из локальной сети
sudo ufw limit ssh                 # не более 6 подключений за 30 сек с одного IP
```

### Просмотр и удаление правил
```bash
sudo ufw status                    # краткий список
sudo ufw status verbose            # с политикой по умолчанию
sudo ufw status numbered           # с номерами правил

sudo ufw delete 3                  # удалить правило №3
sudo ufw delete allow 8080/tcp     # удалить по описанию
```

### Разница deny vs reject
- **deny** — молча выбросить пакет. Отправитель ждёт таймаут. Сканер не понимает, есть ли там хост.
- **reject** — отправить в ответ «соединение отклонено». Отправитель сразу знает, что порт закрыт.

Для защиты от сканирования обычно используют `deny`.

---

## 8. Firewalld (CentOS / RHEL / Fedora)

Работает через **зоны** — наборы правил для разных уровней доверия к сети.

### Синтаксис
```bash
firewall-cmd <опции> <зона> <правило>
```

### Открыть порты
```bash
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --zone=external --add-port=443/tcp
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --reload            # применить изменения
sudo firewall-cmd --list-all          # посмотреть правила
```

**Важно:** флаг `--permanent` сохраняет правило навсегда, но применяет только после `--reload`.

### Предустановленные зоны

| Зона | Что разрешено |
|---|---|
| `drop` | всё входящее блокируется молча, только исходящее |
| `block` | как drop, но отправителю приходит сообщение о блокировке |
| `public` | только ssh и dhclient (зона по умолчанию) |
| `external` | NAT для сокрытия внутренней сети |
| `internal` | ssh, samba, mdns, dhcp |
| `dmz` | для изолированных серверов, только SSH |
| `work` | ssh и dhcp |
| `home` | аналогично internal |
| `trusted` | всё разрешено |

---

## 9. Безопасность SSH — best practices

После того как ключи работают, можно усилить защиту сервера.

```bash
sudo nano /etc/ssh/sshd_config
```

Рекомендуемые настройки:
```
Port 2222                      # сменить порт (не панацея, но убирает 90% ботов)
PermitRootLogin no             # запретить вход под root
PasswordAuthentication no      # только по ключам, пароли отключить
PubkeyAuthentication yes       # разрешить ключи
MaxAuthTries 3                 # максимум 3 попытки
```

Применить:
```bash
sudo systemctl restart ssh
```

⚠️ **Перед отключением паролей обязательно проверь, что вход по ключу работает!**  
Держи открытой вторую SSH-сессию на случай ошибки.

### Дополнительно
```bash
sudo apt install fail2ban -y   # автоматическая блокировка брутфорса
sudo ufw limit ssh             # лимит подключений через UFW
```

---

## 10. Диагностика проблем

```bash
# Работает ли SSH-сервер?
sudo systemctl status ssh

# Слушает ли порт 22?
ss -tlnp | grep 22

# Подробный лог подключения (что именно не так)
ssh -v amal@server
ssh -vvv amal@server           # ещё подробнее

# Проверить доступность порта
nc -zv 192.168.1.100 22

# Логи SSH-сервера
sudo journalctl -u ssh -n 50
sudo tail -f /var/log/auth.log
```

### Частые ошибки

| Ошибка | Причина | Решение |
|---|---|---|
| `Connection refused` | SSH-сервер не запущен | `sudo systemctl start ssh` |
| `Connection timed out` | Firewall блокирует порт | `sudo ufw allow 22/tcp` |
| `Permission denied (publickey)` | Ключ не скопирован или неверные права | `ssh-copy-id`, `chmod 600 ~/.ssh/id_ed25519` |
| `Host key verification failed` | Сервер переустановили, отпечаток изменился | `ssh-keygen -R server` |
| `Too many authentication failures` | Много ключей в агенте | `ssh -o IdentitiesOnly=yes -i ~/.ssh/id_ed25519 user@host` |

---

## 11. Практическая лабораторная работа

Выполнить на своей Ubuntu-виртуалке:

```bash
# 1. Установить SSH-сервер
sudo apt install openssh-server -y
sudo systemctl status ssh

# 2. Сгенерировать ключи
ssh-keygen -t ed25519 -C "amal-devops-lab"

# 3. Посмотреть, что создалось
ls -la ~/.ssh/

# 4. Скопировать ключ на себя
ssh-copy-id amal@localhost

# 5. Проверить вход без пароля
ssh amal@localhost
whoami
exit

# 6. Настроить firewall
sudo ufw allow OpenSSH
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable
sudo ufw status verbose

# 7. Проверить, что SSH всё ещё работает
ssh amal@localhost
exit

# 8. Потренироваться с scp
echo "тест передачи" > ~/test_scp.txt
scp ~/test_scp.txt amal@localhost:/tmp/
ssh amal@localhost "cat /tmp/test_scp.txt"
exit
```

---

## 12. Мои скриншоты

### Генерация SSH-ключей

Вывод`ssh-keygen`

<img width="684" height="435" alt="Screenshot From 2026-11-13 19-10-25 (Edited) (Edited)" src="https://github.com/user-attachments/assets/53d7c131-d935-4702-b3e6-c7b4f6babbdc" />

Вывод`ls -la ~/.ssh/`

<img width="528" height="185" alt="Screenshot From 2026-11-13 19-14-11 (Edited) (Edited)" src="https://github.com/user-attachments/assets/fc0ae9d7-345e-4f61-9fca-1842810bb12b" />


### Вход без пароля

<img width="597" height="311" alt="Screenshot From 2026-11-13 19-24-03 (Edited) (Edited)" src="https://github.com/user-attachments/assets/46378e52-1399-477e-b58e-3f941d409f9f" />


*(вставить скриншот успешного `ssh amal@localhost`)*

### Статус Firewall

<img width="542" height="239" alt="Screenshot From 2026-11-13 19-25-43 (Edited) (Edited)" src="https://github.com/user-attachments/assets/4769809e-3275-44ee-a14a-9209bedaa18a" />


*(вставить скриншот `sudo ufw status verbose`)*

---

## 📌 Шпаргалка на каждый день

```bash
ssh user@host                      # подключиться
ssh-keygen -t ed25519              # создать ключи
ssh-copy-id user@host              # закинуть ключ на сервер
scp file.txt user@host:/path/      # отправить файл
scp user@host:/path/file.txt .     # забрать файл
rsync -avz folder/ user@host:/path/ # синхронизировать папку

sudo ufw allow 22/tcp              # разрешить SSH
sudo ufw enable                    # включить firewall
sudo ufw status numbered           # посмотреть правила с номерами
sudo ufw delete 3                  # удалить правило №3
```

---

*Следующая тема: сетевые протоколы, Nginx, мониторинг.*
