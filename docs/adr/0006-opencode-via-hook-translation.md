# ADR 0006: opencode lewat plugin yang menerjemahkan ke payload hook Claude

**Status:** Accepted

**Keputusan:**
- opencode didukung lewat plugin global `~/.config/opencode/plugins/notchy.js`
- Plugin tidak menulis Status File sendiri. Event opencode diterjemahkan jadi payload yang sama dengan hook Claude Code (`PreToolUse`, `Stop`, dst.), lalu di-pipe ke `notchy-hook`
- Nama tool opencode dipetakan ke nama Claude (`bash` → `Bash`, `todowrite` → `TodoWrite`, `question` → `AskUserQuestion`), jadi deskripsi aktivitas & Todo Progress tetap dari satu tempat
- Izin dibaca dari event `permission.asked` (hook plugin `permission.ask` tidak dipanggil opencode 1.2.x)
- Session subagent (`parentID` ada) diabaikan supaya tidak muncul sebagai titik sendiri

**Konsekuensi:** Format Status File, lock, dan pencarian tty/pid tetap cuma ada di `notchy-hook`. Agent lain bisa ditambah dengan cara yang sama.
