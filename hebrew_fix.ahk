; ============================================================
;  Hebrew Fix - Converts selected text typed in the wrong
;  keyboard layout (Hebrew <-> English), based on the
;  standard Israeli keyboard layout (SI 1452).
;
;  Usage: select text in any application and press Ctrl+Alt+H
;  Requires AutoHotkey v2   https://www.autohotkey.com
;
;  --- בעברית ---
;  Hebrew Fix - ממיר טקסט מסומן שהוקלד בטעות בפריסת מקלדת שגויה
;  (עברית <-> אנגלית), לפי פריסת המקלדת הישראלית הסטנדרטית (SI 1452).
;
;  שימוש: סמנו טקסט בכל אפליקציה ולחצו Ctrl+Alt+H
;  דורש AutoHotkey v2   https://www.autohotkey.com
; ============================================================

#Requires AutoHotkey v2.0
#SingleInstance Force

; --- Base mapping: English key -> Hebrew letter (single source of truth) ---
; --- מיפוי בסיסי: מקש אנגלי -> אות עברית (מקור אמת יחיד) ---
EnToHe := Map(
    "q", "/", "w", "'", "e", "ק", "r", "ר", "t", "א",
    "y", "ט", "u", "ו", "i", "ן", "o", "ם", "p", "פ",
    "[", "]", "]", "[",
    "a", "ש", "s", "ד", "d", "ג", "f", "כ", "g", "ע",
    "h", "י", "j", "ח", "k", "ל", "l", "ך", ";", "ף", "'", ",",
    "z", "ז", "x", "ס", "c", "ב", "v", "ה", "b", "נ",
    "n", "מ", "m", "צ", ",", "ת", ".", "ץ", "/", "."
)

; --- Reverse mapping: Hebrew letter -> English key, auto-derived from EnToHe ---
; --- מיפוי הפוך: אות עברית -> מקש אנגלי, נגזר אוטומטית מ-EnToHe ---
HeToEn := Map()
for enKey, heVal in EnToHe
    HeToEn[heVal] := enKey

; --- Generic conversion function, reused for both directions ---
; --- פונקציית המרה גנרית, בשימוש חוזר לשני הכיוונים ---
ConvertText(text, map) {
    result := ""
    Loop Parse, text
    {
        ch := A_LoopField
        lowerCh := StrLower(ch)
        if map.Has(lowerCh)
            result .= map[lowerCh]
        else
            result .= ch   ; character not in the map (space, digit, symbol) stays as-is
    }
    return result
}

; --- Detects whether the string contains Hebrew letters ---
; --- מזהה האם המחרוזת מכילה אותיות עבריות ---
ContainsHebrew(text) {
    return RegExMatch(text, "[\x{05D0}-\x{05EA}]") > 0
}

; --- Hotkey: Ctrl+Alt+H ---
; --- קיצור מקלדת: Ctrl+Alt+H ---
^!h::
{
    ; Preserve the user's existing clipboard content to restore it later
    savedClip := ClipboardAll()

    A_Clipboard := ""              ; clear clipboard before copying
    Sleep(100)                     ; brief delay to let physical modifier keys release
    Send("^c")                     ; copy the selected text
    if !ClipWait(1.5)              ; wait up to 1.5s for the copy to complete
    {
        ToolTip("No text selected")
        SetTimer(() => ToolTip(), -1500)
        A_Clipboard := savedClip
        return
    }

    original := A_Clipboard

    if (original = savedClip)
    {
        ; Clipboard didn't change - the copy likely failed (no real selection)
        ToolTip("No text selected")
        SetTimer(() => ToolTip(), -1500)
        A_Clipboard := savedClip
        return
    }

    ; Auto-detect conversion direction based on the selected text
    if ContainsHebrew(original)
        converted := ConvertText(original, HeToEn)   ; Hebrew -> English
    else
        converted := ConvertText(original, EnToHe)   ; English -> Hebrew

    A_Clipboard := converted
    Sleep(100)
    Send("^v")                     ; paste the converted text over the selection

    Sleep(300)                     ; brief delay before restoring the clipboard
    A_Clipboard := savedClip
}
