# Notchy — Context & Glossary

Notchy adalah macOS app (menu bar agent, tanpa Dock icon) yang mengubah notch MacBook Pro jadi
"dynamic island" untuk memantau session Claude Code. Tujuannya supaya user bisa tetap di browser
(scroll twitter) dan cek progress Claude cukup dengan lirik/hover ke notch, tanpa pindah ke Terminal.

Target: MacBook Pro M1 Pro (notch internal), macOS 14+, Terminal.app, personal use.

## Glossary

| Istilah | Definisi |
|---|---|
| **Session** | Satu instance Claude Code yang berjalan. Diidentifikasi oleh `session_id` dari payload hook. Satu project bisa punya >1 Session. |
| **Session State** | Salah satu dari: `working` (Claude sedang kerja), `done` (selesai / menunggu prompt berikutnya), `needs_permission` (diblok menunggu user: izin tool, `AskUserQuestion`, atau `ExitPlanMode`). |
| **Status File** | `~/.notchy/sessions/<session_id>.json`, snapshot terbaru sebuah Session yang ditulis oleh Hook Script dan dibaca Notchy. |
| **Hook Script** | `notchy-hook`, script kecil yang dipanggil Claude Code hooks (global). Hanya menulis Status File, non-blocking, harus selesai dalam hitungan ms. |
| **Ambient Indicator** | Titik per Session di "telinga" kiri/kanan notch saat panel tertutup. ● ungu berdenyut = working, ○ hijau = done, ⚠ oranye = needs_permission. Hanya tampil jika ada ≥1 Session. |
| **Expanded Panel** | Panel yang turun dari notch saat cursor hover. Berisi Session Row untuk semua Session. |
| **Session Row** | Satu baris di Expanded Panel: nama project, prompt terakhir, state, Current Activity, durasi, Todo Progress, Last Message. |
| **Current Activity** | Tool + target yang sedang dijalankan (mis. `Edit src/app/page.tsx`), dari `PreToolUse`. |
| **Todo Progress** | `n/total` + item yang sedang aktif, dari `TaskCreate`/`TaskUpdate` (atau `TodoWrite` versi lama) di `PostToolUse`. |
| **Last Message** | Potongan pesan assistant terakhir, dibaca dari `transcript_path` saat `Stop`. |
| **Last Prompt** | Prompt terakhir user di Session tersebut (teks kecil abu-abu), dari `UserPromptSubmit`. |
| **Peek** | Panel auto-expand ±3 detik menampilkan satu Session Row saat Session jadi `done`. |
| **Alert** | Panel/indicator berdenyut terus (+ suara) saat Session jadi `needs_permission`, sampai state berubah. |
| **Jump** | Klik Session Row → fokus tab Terminal.app / iTerm2 yang menjalankan Session itu (dicocokkan lewat `tty`). |

## Session Lifecycle

- Muncul: `SessionStart` / `UserPromptSubmit`
- `UserPromptSubmit` → `working` (reset timer, simpan Last Prompt)
- `PreToolUse` → update Current Activity
- `PostToolUse` (TodoWrite) → update Todo Progress
- `PermissionRequest` / `Notification` (permission) / `PreToolUse` untuk `AskUserQuestion` & `ExitPlanMode` → `needs_permission`
- `Stop` → `done` + Last Message
- Hilang: `SessionEnd`, atau PID Claude sudah mati (fallback kalau tab ditutup paksa)
