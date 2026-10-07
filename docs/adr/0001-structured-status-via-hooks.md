# ADR 0001: Status terstruktur via Claude Code hooks, bukan mirror terminal

**Status:** Accepted

**Konteks:** User ingin cek progress Claude Code tanpa pindah dari browser. Ada dua opsi: mirror isi terminal
mentah (tmux capture-pane / Accessibility API), atau status terstruktur dari Claude Code hooks.

**Keputusan:** Pakai hooks. Hook Script menulis Status File JSON per Session, lalu Notchy membacanya.

**Konsekuensi:**
- (+) Ringan, mudah dibaca sekilas, mendukung banyak Session, tidak bergantung pada terminal app
- (+) Tidak perlu tmux
- (−) Tidak menampilkan output terminal secara persis. Live tail sengaja ditolak
