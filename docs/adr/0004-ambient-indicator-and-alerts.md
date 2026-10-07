# ADR 0004: Ambient Indicator, Peek, dan Alert

**Status:** Accepted

**Keputusan:**
- Panel tertutup: Ambient Indicator (titik per Session) di samping notch, hanya muncul kalau ada Session
- Hover di area notch → Expanded Panel
- `done` → Peek ±3 detik (tetap terbuka kalau cursor ada di sana)
- `needs_permission` → Alert berdenyut terus sampai state berubah, plus suara
- Suara bisa di-toggle dari menu bar, default: hanya untuk permission

**Alasan:** User sedang di app lain. Status harus bisa terbaca dari ujung mata tanpa hover, dan
permission adalah satu-satunya state yang memblokir Claude, jadi paling urgent.
