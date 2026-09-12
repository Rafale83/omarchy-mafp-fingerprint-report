Microarray's MAFP match-on-chip readers (USB vendor `3274`, driven by libfprint's `mafpmoc`) enumerate as "MAFP General Device": no "fingerprint" in the product string, and a vendor missing from `fingerprint_vendors`. `omarchy-hw-fingerprint` therefore returned false and `omarchy-setup-security-fingerprint` refused to run on a reader fprintd handles fine (enroll + verify confirmed on a `3274:8012`).

This adds the vendor to the guess list and an `mafp` token to the product-string match, each with its own case in `test/shell.d/hw-fingerprint-test.sh`. Both new cases fail on `quattro` without the change; the file passes 13/13 with it.

Tested on ASUS ProArt P16 / Omarchy 4.0.2-1 with the reader attached: detection passes, and the wizard's PAM stacks for sudo, polkit and the lock screen work end to end.

Fixes #11426

🤖 Generated with [Claude Code](https://claude.com/claude-code)

https://claude.ai/code/session_01WJZgHbukBfk6NyncUQFYt1
