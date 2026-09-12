### System details

AMD Ryzen AI 9 HX 370, NVIDIA RTX 5090 Mobile + Radeon 890M, ASUS ProArt P16 (H7606WX), Omarchy 4.0.2-1, kernel 7.1.9-arch1-2, libfprint 1.94.100-1, fprintd 1.94.5-2

### What's wrong?

`omarchy-hw-fingerprint` returns false for a Microarray Technology "MAFP" USB fingerprint reader (`3274:8012`), so `omarchy setup security fingerprint` refuses to run ("No fingerprint sensor detected") and the first-run hook and the menu entry (`when: omarchy-hw-fingerprint`) never offer it — even though libfprint drives this reader out of the box (`mafpmoc` driver, "MAFP MOC Fingerprint Sensor") and fprintd enrolls and verifies on it fine.

**Why it is missed.** The detector trusts a device that names itself (`*fingerprint*`, `*biometric*`, …) or falls back to a fixed vendor list (`27c6 138a 06cb 08ff 1c7a 147e`). This reader enumerates as:

```
idVendor=3274  idProduct=8012
manufacturer=[MicroarrayTechnology]
product=[MAFP General Device ]
```

No "fingerprint" in the string and `3274` is not in the list, so neither branch fires. (`MAFP` = MicroArray FingerPrint.)

**Steps to reproduce** — no hardware needed, the detector already takes a fake sysfs:

```bash
d=$(mktemp -d); mkdir "$d/1-0"
printf '3274\n' > "$d/1-0/idVendor"; printf '8012\n' > "$d/1-0/idProduct"
printf 'MAFP General Device \n' > "$d/1-0/product"
OMARCHY_USB_DEVICES_PATH="$d" omarchy-hw-fingerprint; echo $?   # 1 — expected 0
```

On the real machine:

```
$ lsusb | grep 3274
Bus 003 Device 008: ID 3274:8012 MicroarrayTechnology MAFP General Device
$ omarchy-hw-fingerprint; echo $?
1
$ omarchy-setup-security-fingerprint
Setting up fingerprint scanner for authentication.
No fingerprint sensor detected.
$ fprintd-list $USER          # after installing libfprint/fprintd by hand
Fingerprints for user USER on MAFP MOC Fingerprint Sensor (press):
 - #0: right-index-finger
$ fprintd-verify -f right-index-finger $USER
Verify result: verify-match (done)
```

**Expected.** Detection succeeds; the wizard runs. libfprint's own metainfo lists `usb:v3274p8012*` as supported.

**Fix.** Add `3274` to `fingerprint_vendors` and `*mafp*` to the product-string match, with a test for each path in `test/shell.d/hw-fingerprint-test.sh`. Patch and evidence: https://github.com/Rafale83/omarchy-mafp-fingerprint-report — `hw-fingerprint-test.sh` passes 13/13 with the change, and each new case fails without it. Verified on the hardware: with the patched detector, the wizard's PAM setup for sudo, polkit and the lock screen works end to end (applied by hand here, mirroring the wizard).

`omarchy-debug --no-sudo --print` output (hostname/user anonymised): see `evidence/omarchy-debug.log` in the repo above.
