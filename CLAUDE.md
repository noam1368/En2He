# Hebrew Fix (En2He)

A single AutoHotkey v2 script for Windows that fixes selected text in any application through global hotkeys. The user writes in Hebrew; reply in Hebrew unless asked otherwise.

- Repo: `git@github.com:noam1368/En2He.git`, branch `master`
- Project path: `C:\Projects\zero2claude\En2He` (`C:\Users\Noam\zero2claude` is a junction to `C:\Projects\zero2claude`, so both paths are the same files)
- AutoHotkey: `C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe`

## Files

- `hebrew_fix.ahk` — the whole tool (one file, ~750 lines).
- `README.md` — user docs, in English and then Hebrew. Keep both halves in sync.
- `.env.example` — template for `.env`.
- `.env` — real secrets (`DEEPL_API_KEY`, `MYMEMORY_EMAIL`). Gitignored.

## Security rules

- Never commit or push `.env`, and never print its values in chat or logs.
- Before any push, check that no key or email is in a tracked file or in the commit.
- The script reads `.env` from `A_ScriptDir`, so the script must run from this folder (a copy elsewhere loses translation keys).

## Hotkeys

All three copy the selection, transform it, paste it back and restore the clipboard (`GetSelectedText` / `ReplaceSelection`).

They are AHK custom combinations (`CapsLock & h::` etc.), so CapsLock is a prefix key and loses its own function. A separate `CapsLock::` hotkey gives it back: tapping CapsLock alone toggles Caps Lock on release, only if no other key was pressed while it was held. Until 2026-10-20 the hotkeys were `Ctrl+Alt+H/J/T`; the user wanted to stop pressing Alt.

| Hotkey | What it does | Main code |
|---|---|---|
| `CapsLock+H` | Fix wrong keyboard layout (Hebrew ↔ English, SI 1452). Direction: Hebrew present → to English | `EnToHe`/`HeToEn`, `ConvertText` |
| `CapsLock+J` | Restore Hebrew copied reversed from a terminal, line by line | `FixReversedText` and the `Bidi*` functions |
| `CapsLock+T` | Translate (Hebrew → English, otherwise → Hebrew) | `TranslateText` → DeepL → Google → MyMemory |

### CapsLock+J design

The terminal (Claude Code) word-wraps a paragraph, then reorders each screen row on its own with the Unicode Bidi Algorithm. Copying gives the visual order. The L2 reorder is its own inverse, so applying the same levels to the copied row restores the logical text.

- `FixReversedText` splits on `` `n `` (keeps `` `r ``). Text with Hebrew goes through `FixReversedLine`; text without Hebrew is reversed per line with `ReverseText`.
- `FixReversedLine` strips the `│` box border, keeps the leading bullet (`-`, `*`, `•`, `1.`) and edge whitespace, and reorders the body.
- `BidiClass` → classes R / L / EN / ES / CS / ET / N. `BidiLevels` applies a simplified W4–W7, N1/N2 and I1/I2. `BidiReorder` is L2.
- `IsRtlRow` picks row direction: leftmost strong R → RTL; rightmost strong L → LTR; sentence punctuation before the first strong char → RTL; else LTR.
- `SplitChars` keeps surrogate pairs (emoji) intact.

### CapsLock+T design

- DeepL API Free (only when `DEEPL_API_KEY` is set) → Google (`clients5.google.com` `dict-chrome-ex` endpoint; the old `translate_a/single` endpoint returned 429) → MyMemory (checks `responseStatus`).
- Responses are decoded as UTF-8 via `ADODB.Stream` (`DecodeUtf8Response`) to avoid Hebrew mojibake.
- `LoadEnv` strips surrounding quotes from values.

## Running

- Run: double-click `hebrew_fix.ahk`, or `& "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" hebrew_fix.ahk`. `#SingleInstance Force` reloads it if this same path is already running.
- After editing the script, rerun it so the running instance picks up the change.
- Autostart: a **shortcut** (not a copy) to this file in `shell:startup`.
- `#SingleInstance` is per path: a copy at another path runs alongside and its hotkeys conflict.

## Testing

There is no test suite in the repo. The J logic was tested with a throwaway AHK script that `#Include`s `hebrew_fix.ahk` and compares `FixReversedText` / `FixReversedLine` output to expected strings (real terminal copies, round trips `FixReversedLine(FixReversedLine(s)) == s` for single rows, CRLF, blank lines, emoji). It passed 36/36. The hotkeys themselves are tested by hand.

## History

1. `23e4077` — initial project: `Ctrl+Alt+H` layout fix.
2. `1e80e6a` — `Ctrl+Alt+J` simple character reversal.
3. `761be7d` — `Ctrl+Alt+T` translation with DeepL / Google / MyMemory fallback and `.env`.
4. `6cda28d` — fix Hebrew mojibake in responses; tolerate quoted `.env` values.
5. `7ee1efd` — fix Google 429 by switching to the `dict-chrome-ex` endpoint.
6. `300e1c5` — `Ctrl+Alt+J` rewritten: per-line, Bidi-based restore of mixed Hebrew/English.
7. `dc86e8a` — hotkeys moved from `Ctrl+Alt+H/J/T` to `CapsLock+H/J/T`.

## Status

Complete for now (2026-10-15). All three hotkeys were tested by the user and work. On the user's machine, autostart is a shortcut to this file in `shell:startup` (the old standalone copy that used to be there was removed).

2026-10-20: hotkeys moved from `Ctrl+Alt` to `CapsLock`. This was written in a cloud session without AutoHotkey, so the CapsLock version has not been run or tested by the user yet.

## Open items (known limitations, nothing in progress)

- **J: wrapped paragraphs** can't be restored: soft-wrapped rows are joined on copy with no separator, so the split point is lost. Workaround: Claude Code's `/copy`. Documented in README.
- **J: ambiguity** — a Hebrew row ending in an English word with no closing punctuation looks the same, once copied, as a row starting with that word. It is restored as the latter.
- **H:** mixed text (valid text from the other language inside the selection) gets converted too.
- **T:** Google and MyMemory endpoints are unofficial/free and can be rate-limited or blocked.
- **Tests:** consider adding the J test script to the repo (e.g. `tests/`), with fixtures that contain no personal data.
