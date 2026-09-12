#!/bin/bash
# Mirrors omarchy-setup-security-fingerprint's setup_pam_config + setup_lock_fingerprint_pam.
set -e
ts=$(date +%s)
gate='auth      [success=1 default=ignore] pam_exec.so quiet /usr/bin/omarchy-hw-laptop-closed'

cp -a /etc/pam.d/sudo "/etc/pam.d/sudo.bak.$ts"
grep -q pam_fprintd.so /etc/pam.d/sudo || sed -i '1i auth      sufficient pam_fprintd.so' /etc/pam.d/sudo
grep -q omarchy-hw-laptop-closed /etc/pam.d/sudo || sed -i "/pam_fprintd\.so/i $gate" /etc/pam.d/sudo

[[ -f /etc/pam.d/polkit-1 ]] && cp -a /etc/pam.d/polkit-1 "/etc/pam.d/polkit-1.bak.$ts"
tee /etc/pam.d/polkit-1 >/dev/null <<EOF
$gate
auth      sufficient pam_fprintd.so
auth      required pam_unix.so

account   required pam_unix.so
password  required pam_unix.so
session   required pam_unix.so
EOF

tee /etc/pam.d/omarchy-lock-fingerprint >/dev/null <<'EOF'
#%PAM-1.0
auth       required                    pam_fprintd.so
account    include                     system-local-login
EOF
echo "backup suffix: .bak.$ts"
