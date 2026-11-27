# Сборка форка

Этот форк собирается вручную. GitHub Actions выключены в настройках репозитория, а файлы workflow апстрима остаются в дереве, чтобы мерж апстрима не давал конфликтов на них. Desktop-сборки проверяют фид обновлений форка; образ Docker и standalone-сервер нет. Имя продукта, `appId`, базовая версия и ссылки совпадают с апстримом, но каждый установщик и образ собираются из этого репозитория.

Версия имеет вид `X.Y.Z-fork.N`, её ставит `deploy/desktop-updates.sh`. Когда апстрим выпускает новую версию, влейте её, добавьте новые ключи перевода и выпустите релиз.

Английская версия: [README.md](./README.md).

## Требования

Сборочный хост Linux:

- x86_64 Linux с Docker
- Node.js 24 на хосте для `deploy/desktop-updates.sh`, он пишет манифесты обновлений
- рекомендуется 4 vCPU, 8 ГБ RAM и не менее 4 ГБ swap для сборки Vite
- около 20 ГБ свободного места под кэши, загрузки Electron и артефакты

Windows собирается на Linux через wine. Если сборка через wine не проходит, запустите `deploy/windows.sh` на Windows с Git Bash. macOS собирается на Mac или, без оформления окна DMG и нотаризации, на Linux через `deploy/macos-cross.sh`.

Сертификаты подписи не настроены. Кросс-сборка macOS подписывает приложение ad-hoc, остальные артефакты macOS и Windows не подписаны.

## Команды

Образ Docker:

```bash
./deploy/docker.sh
```

Linux AppImage, deb и rpm:

```bash
./deploy/linux.sh
```

Установщик Windows NSIS:

```bash
./deploy/windows.sh
```

DMG и ZIP для macOS, на Mac:

```bash
./deploy/macos.sh          # arm64
./deploy/macos.sh x64
```

DMG и ZIP для macOS, кросс-сборка на Linux:

```bash
./deploy/macos-cross.sh          # arm64
./deploy/macos-cross.sh x64
```

Все скрипты пишут в `dist/`. Каталог и имя образа меняются переменными `DIST` и `IMAGE`.

## Артефакты

Имена совпадают с апстримом:

- `OpenChamber-<версия>-linux-x86_64.AppImage`
- `OpenChamber-<версия>-linux-amd64.deb`
- `OpenChamber-<версия>-linux-x86_64.rpm`
- `OpenChamber-<версия>-win-x64.exe`
- `OpenChamber-<версия>-mac-arm64.dmg`
- `OpenChamber-<версия>-mac-arm64.zip`
- `OpenChamber-<версия>-mac-x64.dmg`
- `OpenChamber-<версия>-mac-x64.zip`
- `openchamber-<версия>-docker.tar.gz`

`dist/BUILD.txt` содержит версию, коммит и время сборки. В `dist/SHA256SUMS` хеши всех артефактов.

## Установка образа Docker

На сборочном хосте нет registry. Загрузите архив на целевой машине:

```bash
docker load < openchamber-<версия>-docker.tar.gz
```

Затем укажите в `docker-compose.yml` образ `openchamber:<версия>` или `openchamber:latest`.

## Неподписанные установщики

macOS блокирует ненотаризованное приложение при первом запуске. Откройте его через контекстное меню и выберите «Открыть» либо снимите карантин:

```bash
xattr -d com.apple.quarantine /Applications/OpenChamber.app
```

Windows SmartScreen показывает предупреждение. Выберите «Подробнее» и «Выполнить всё равно».

## Обновления

Desktop-сборки проверяют `https://openchamber.update.indi.one/desktop/stable/`. На GitHub и `downloads.openchamber.dev` они не переключаются, поэтому установку форка может заменить только другой релиз форка. Переменная `OPENCHAMBER_UPDATES_DISABLED=1` во время запуска выключает проверку в конкретной сборке.

Версия имеет вид `X.Y.Z-fork.N`: `X.Y.Z` это версия апстрима, от которой собран форк, `N` считает сборки форка на этой базе. Пересборка на той же базе поднимает `N`. Никогда не публикуйте версию без суффикса `-fork.N`: следующая `X.Y.Z-fork.N+1` окажется для клиентов старее и не прилетит. Первую сборку форка поставьте вручную, потому что апстримная `X.Y.Z` старше `X.Y.Z-fork.1`.

Релиз целиком:

```bash
./deploy/desktop-updates.sh
./deploy/desktop-updates.sh --version 2.8.2-fork.1
```

Скрипт ставит версию во все воркспейсы, собирает Linux, Windows и обе архитектуры macOS, пишет `latest.yml`, `latest-linux.yml` и `latest-mac.yml` рядом с артефактами и копирует всё в `/srv/openchamber/updates/desktop/stable/`. Каталог меняется через `OPENCHAMBER_UPDATE_ROOT`, адрес фида через `OPENCHAMBER_UPDATER_URL`, путь в адресе должен совпадать. `deploy/Caddyfile.example` отдаёт этот каталог: манифесты без кеша, артефакты с долгим кешем.

`electron-updater` проверяет у каждого скачанного файла `sha512` и размер из манифеста. В каталоге релиза также лежит `SHA256SUMS` для ручной проверки.

Автообновление macOS опирается на ad-hoc подпись кросс-сборки. Проверьте одно реальное обновление на Mac: Squirrel может отказаться ставить бандл с такой подписью. Если откажется, macOS остаётся на ручном обновлении через DMG.

Образ Docker и standalone-сервер остаются с выключенными обновлениями через `OPENCHAMBER_UPDATES_DISABLED=1`. Проверяют обновления только desktop-сборки.

## Кросс-сборка Windows

Путь через wine сначала ставит обычные Linux-зависимости для сборки web, затем переустанавливает win32-пакеты, чтобы встроенный сервер, ripgrep и модули терминала соответствовали Windows. Проверить упакованный сервер Windows на Linux нельзя. Один раз запустите скрипт на Windows, чтобы подтвердить установщик и встроенный сервер, затем используйте любой путь.

## Кросс-сборка macOS

`./deploy/macos-cross.sh` собирает артефакты macOS на хосте Linux. Упаковка отличается от `deploy/macos.sh`: `after-pack` пропускает `codesign`, приложение подписывается ad-hoc через `rcodesign`, а DMG пишет `libdmg-hfsplus` вместо `dmgbuild`.

- Подпись ad-hoc позволяет Apple Silicon запустить приложение. Gatekeeper всё равно предупреждает, потому что сборка не нотаризована.
- DMG содержит приложение и ссылку на `/Applications`. Фон окна и расположение иконок из сборки на Mac не применяются.
- Упакованный сервер на Linux не запускается. Проверьте приложение и встроенный сервер на Mac перед публикацией.

Любая архитектура собирается через `./deploy/macos-cross.sh arm64` или `./deploy/macos-cross.sh x64`; у артефактов x64 в имени `mac-x64`.
