# ADR 0003: Jump ke Terminal.app via tty

**Status:** Accepted

**Konteks:** User memakai Terminal.app bawaan dan sering menjalankan >3 Session sekaligus.

**Keputusan:** Hook Script mencatat tty proses Claude (`ps -o tty= -p $PPID`). Saat Jump, Notchy menjalankan
AppleScript yang mencari tab Terminal.app dengan `tty` yang cocok, memilih tab itu, dan membawa window-nya ke depan.

**Konsekuensi:**
- (+) Jump presisi ke tab yang tepat
- (−) Butuh izin Automation (Notchy → Terminal) saat pertama kali
- (−) Terikat ke Terminal.app. Terminal lain butuh adapter terpisah

**Update:** iTerm2 didukung dengan adapter AppleScript kedua (`tty of session`). Hook Script juga mencatat
`TERM_PROGRAM`, jadi Jump langsung memilih terminal yang benar. AppleScript dijalankan via `osascript` di background
agar notch tidak freeze saat terminal lambat atau prompt izin Automation muncul.
