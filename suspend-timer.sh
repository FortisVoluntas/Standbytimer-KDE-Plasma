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
