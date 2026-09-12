#!/bin/bash
# Emit one line per USB device appearing/disappearing, flagging fingerprint candidates.
IDS="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/supported_ids.txt"

snapshot() {
  local dev vid pid product serial
  for dev in /sys/bus/usb/devices/*; do
    [[ -r $dev/idVendor && -r $dev/idProduct ]] || continue
    vid=$(<"$dev/idVendor"); pid=$(<"$dev/idProduct")
    product="?"; [[ -r $dev/product ]] && product=$(<"$dev/product")
    manuf="";  [[ -r $dev/manufacturer ]] && manuf=$(<"$dev/manufacturer")
    # root hubs are noise
    [[ $vid == 1d6b ]] && continue
    echo "${vid}:${pid} ${manuf} ${product}"
  done | sort
}

flag() {
  # Exact match against libfprint 1.94.100's supported-device list (258 IDs
  # extracted from its metainfo), then a looser vendor/product-string hint.
  local id=${1%% *}; id=${id,,}
  if grep -qx "$id" "$IDS"; then
    echo " <<< SUPPORTÉ PAR libfprint"
    return
  fi
  local line=${1,,}
  if [[ $line == *fingerprint* || $line == *biometric* || $line == *mafp* \
     || $line == *elan:arm-m4* || $line == *digitalpersona* || $line == *goodix* \
     || $line == *synaptics* || $line == *"fpc "* || $line == *validity* ]]; then
    echo " <<< capteur d'empreinte probable, MAIS ID absent de libfprint"
  elif grep -q "^${id%%:*}:" "$IDS"; then
    echo " <<< vendor connu de libfprint, mais ce modèle précis n'y est pas"
  fi
}

prev=$(snapshot)
echo "Surveillance armée — référence :"; while IFS= read -r l; do echo "    $l$(flag "$l")"; done <<<"$prev"

while true; do
  sleep 2
  cur=$(snapshot)
  if [[ $cur != "$prev" ]]; then
    while IFS= read -r l; do
      [[ -n $l ]] && echo "[+ BRANCHÉ]  $l$(flag "$l")"
    done < <(comm -13 <(echo "$prev") <(echo "$cur"))
    while IFS= read -r l; do
      [[ -n $l ]] && echo "[- RETIRÉ ]  $l"
    done < <(comm -23 <(echo "$prev") <(echo "$cur"))
    if omarchy-hw-fingerprint 2>/dev/null; then
      echo "           -> omarchy-hw-fingerprint: un lecteur est détecté sur le système"
    else
      echo "           -> omarchy-hw-fingerprint: aucun lecteur détecté"
    fi
    prev=$cur
  fi
done
