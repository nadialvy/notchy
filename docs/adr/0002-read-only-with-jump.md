# ADR 0002: v1 read-only + Jump, tanpa approve dari notch

**Status:** Accepted

**Konteks:** Permission bisa dijawab langsung dari notch dengan hook yang memblokir dan menunggu jawaban lewat socket.

**Keputusan:** v1 hanya menampilkan status. Untuk merespon, user klik → Jump ke tab Terminal.app.

**Konsekuensi:**
- (+) Hook Script tidak pernah memblokir Claude. Kalau Notchy mati, Claude tidak terpengaruh
- (+) Tidak ada risiko approve command tanpa konteks
- Format Status File dan Hook Script dirancang supaya bisa di-upgrade ke approve/deny (blocking `PermissionRequest`) nanti
