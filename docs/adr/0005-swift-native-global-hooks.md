# ADR 0005: Swift/SwiftUI native + hooks global

**Status:** Accepted

**Keputusan:**
- Notchy dibangun dengan Swift + SwiftUI (macOS 14+), sebagai LSUIElement agent (tanpa Dock icon), memakai NSPanel non-activating di level di atas menu bar
- Hooks dipasang global di `~/.claude/settings.json`, supaya semua Session di project mana pun terpantau otomatis
- Diff `settings.json` ditunjukkan ke user sebelum disimpan

**Konsekuensi:** Hook Script harus sangat cepat dan tidak pernah gagal dengan exit code yang mengganggu Claude (selalu exit 0).
