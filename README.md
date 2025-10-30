## Inhalt
- [Features](#features)
- [Voraussetzungen](#voraussetzungen)
- [Installation](#installation)
  - [1) Skript anlegen (`~/.local/bin/suspend-timer.sh`)](#1-skript-anlegen-localbinsuspend-timersh)
  - [2) Desktop-Starter erstellen (`~/Desktop/Suspend-Timer.desktop`)](#2-desktop-starter-erstellen-desktopsuspend-timerdesktop)
- [Nutzung](#nutzung)
- [Timer prüfen & abbrechen](#timer-prüfen--abbrechen)
- [Deinstallation](#deinstallation)
- [Technische Details](#technische-details)
- [Hinweise für Windows-Umsteiger](#hinweise-für-windows-umsteiger)

## Features
- GUI-Eingabedialog via **`kdialog`** (KDE)
- Läuft **im User-Kontext** (systemd **user timer**) → **keine Administratorrechte nötig**
- Setzt vorhandene Timer sauber zurück
- Einfache Deaktivierung mit einem Befehl

## Voraussetzungen
- Linux mit **systemd** (User-Services aktiviert)
- **KDE/Plasma** oder installiertes **`kdialog`**

**Paketinstallation `kdialog` (Beispiele):**

```bash
# Debian/Ubuntu
sudo apt install kdialog

# Fedora/Nobara/RHEL
sudo dnf install kdialog

# Arch/Manjaro
sudo pacman -S kdialog
```
## Installation

## 1) Skript anlegen (`~/.local/bin/suspend-timer.sh`)
```bash
mkdir -p ~/.local/bin
cat > ~/.local/bin/suspend-timer.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

# Eingabe (Minuten)
MINUTES=$(kdialog --title "Suspend-Timer" --inputbox "Nach wie vielen Minuten in Standby wechseln?" "30") || exit 0
MINUTES=$(echo "$MINUTES" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

# Validierung
if [[ ! "$MINUTES" =~ ^[0-9]+$ ]] || [[ "$MINUTES" -le 0 ]]; then
  kdialog --error "Bitte eine positive ganze Zahl in Minuten angeben."
  exit 1
fi

# Evtl. vorhandenen Timer stoppen
systemctl --user stop suspend-in.timer suspend-in.service >/dev/null 2>&1 || true

# Timer setzen (user scope)
systemd-run --user --unit=suspend-in --on-active="${MINUTES}m" /usr/bin/systemctl suspend >/dev/null

kdialog --msgbox "Suspend in ${MINUTES} Minute(n) geplant.
Abbrechen (falls nötig):  systemctl --user stop suspend-in.timer"
EOF
chmod +x ~/.local/bin/suspend-timer.sh
```
## 2) Desktop-Starter erstellen (~/Desktop/Suspend-Timer.desktop)

Wichtig: Der Exec=-Pfad muss auf dein Skript zeigen.
Standard im Beispiel: ~/.local/bin/suspend-timer.sh. Wenn du einen anderen Ort verwendest, Exec= anpassen.

```bash
# Desktop-Ordner ermitteln (de/en)
DESK="$HOME/Desktop"; [ -d "$HOME/Schreibtisch" ] && DESK="$HOME/Schreibtisch"
mkdir -p "$DESK"

cat > "$DESK/Suspend-Timer.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Suspend-Timer
Comment=Frage nach Minuten und plane Standby
# ACHTUNG: Pfad anpassen, falls dein Skript anders liegt!
Exec=/bin/bash -lc '~/.local/bin/suspend-timer.sh'
Icon=system-suspend
Terminal=false
Categories=Utility;
EOF

chmod +x "$DESK/Suspend-Timer.desktop"
```
## Nutzung

- Desktop-Datei Suspend-Timer doppelklicken.

- Minuten eingeben (z. B. 30) → OK.

- System wechselt nach Ablauf in Standby (Suspend).

## Timer prüfen und abbrechen

- Prüfen, ob Timer aktiv ist:
 ```bash
 systemctl --user list-timers | grep suspend-in || true
```
- Geplanten Timer abbrechen:
```bash
systemctl --user stop suspend-in.timer
```

## Deinstallation
```bash
systemctl --user stop suspend-in.timer 2>/dev/null || true
rm -f ~/.local/bin/suspend-timer.sh
rm -f ~/Desktop/Suspend-Timer.desktop ~/Schreibtisch/Suspend-Timer.desktop 2>/dev/null || true
```

## Technische Details
- Nutzt systemd-run --user --on-active=<Nm> → erstellt transiente User-Unit (suspend-in.timer / suspend-in.service).

- Nach Ablauf wird /usr/bin/systemctl suspend ausgeführt.

- Läuft vollständig im Benutzerkontext (keine Root-Rechte nötig).

## Hinweise für Windows-Umsteiger

- Entspricht einem Sleep-Timer: Zeit eingeben → automatischer Standby nach Ablauf.

- Ein Klick vom Desktop, keine zusätzlichen Berechtigungen.

- Schnörkellos: nur das Nötige, zuverlässig.
