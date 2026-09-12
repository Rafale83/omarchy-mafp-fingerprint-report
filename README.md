# Omarchy: Microarray MAFP fingerprint reader not detected

Supporting material for a bug report against [basecamp/omarchy](https://github.com/basecamp/omarchy): `omarchy-hw-fingerprint` misses Microarray "MAFP" USB readers (`3274:8012`), so the fingerprint setup wizard refuses to run on a reader that libfprint/fprintd support out of the box.

*Dossier de support pour un rapport de bug Omarchy : le détecteur `omarchy-hw-fingerprint` ignore les lecteurs Microarray MAFP (`3274:8012`), donc l'assistant d'empreintes refuse de se lancer alors que libfprint/fprintd gèrent ce capteur nativement.*

## Layout

| Path | What |
|---|---|
| `ISSUE.md` | Ready-to-post issue body (follows Omarchy's bug template) |
| `PR.md` | Ready-to-post pull-request body |
| `fix/0001-*.patch` | The fix + tests, as a `git format-patch` against `quattro` |
| `evidence/evidence.txt` | Terminal transcript on the affected machine |
| `evidence/omarchy-debug.log` | `omarchy-debug --no-sudo --print`, hostname and user anonymised |
| `evidence/hw-fingerprint-test.log` | `test/shell.d/hw-fingerprint-test.sh` run with the fix (13/13) |
| `evidence/libfprint-1.94.100-supported-ids.txt` | All 258 `vendor:product` IDs from libfprint's metainfo — `3274:8012` is there |
| `tools/usbwatch.sh` | USB hotplug watcher that flags any device against that ID list |
| `workaround/pam-fprint.sh` | What the wizard would have done: the exact PAM stanzas for sudo, polkit and the lock screen, applied by hand after `fprintd-enroll` / `fprintd-verify` |

## Filing it

```bash
# 1. Issue
gh issue create --repo basecamp/omarchy \
  --title 'omarchy-hw-fingerprint misses Microarray MAFP readers (3274:8012), fingerprint setup refuses to run' \
  --body-file ISSUE.md

# 2. PR (after the issue number is known — fill "Fixes #…" in PR.md)
gh repo fork basecamp/omarchy --clone && cd omarchy
git am ../omarchy-mafp-fingerprint-report/fix/0001-*.patch
bash test/shell.d/hw-fingerprint-test.sh
git push -u origin HEAD:fix/hw-fingerprint-microarray
gh pr create --base quattro --title 'Detect Microarray MAFP fingerprint readers' --body-file ../omarchy-mafp-fingerprint-report/PR.md
```

## The fix in one screen

```diff
-fingerprint_vendors=" 27c6 138a 06cb 08ff 1c7a 147e "
+fingerprint_vendors=" 27c6 138a 06cb 08ff 1c7a 147e 3274 "
…
-    [[ $product == *fingerprint* || … || $product == "fpc "* ]] && exit 0
+    [[ $product == *fingerprint* || … || $product == "fpc "* || $product == *mafp* ]] && exit 0
```

No credentials, tokens or serial numbers are stored here; the debug log is anonymised and USB serials are redacted.
