; ============================================================
;  Hebrew Fix - Converts selected text typed in the wrong
;  keyboard layout (Hebrew <-> English), based on the
;  standard Israeli keyboard layout (SI 1452).
;  Also reverses the character order of selected text, for
;  text that appears back-to-front (e.g. an RTL/LTR display bug).
;
;  Usage: select text in any application and press Ctrl+Alt+H
;         to fix the keyboard layout, or Ctrl+Alt+J to reverse
;         the character order.
;  Requires AutoHotkey v2   https://www.autohotkey.com
;
;  --- בעברית ---
;  Hebrew Fix - ממיר טקסט מסומן שהוקלד בטעות בפריסת מקלדת שגויה
;  (עברית <-> אנגלית), לפי פריסת המקלדת הישראלית הסטנדרטית (SI 1452).
;  כמו כן הופך את סדר התווים בטקסט מסומן, עבור טקסט שמוצג הפוך
;  (למשל עקב תקלת תצוגה RTL/LTR).
;
;  שימוש: סמנו טקסט בכל אפליקציה ולחצו Ctrl+Alt+H
;         לתיקון פריסת המקלדת, או Ctrl+Alt+J להיפוך סדר התווים.
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

; --- Reverses the character order of a string ---
; --- הופכת את סדר התווים במחרוזת ---
ReverseText(text) {
    result := ""
    Loop Parse, text
        result := A_LoopField . result
    return result
}

; --- Shows a short "no selection" tooltip that clears itself ---
; --- מציגה הודעת "לא נבחר טקסט" זמנית שנעלמת מעצמה ---
ShowNoSelectionTooltip() {
    ToolTip("No text selected")
    SetTimer(() => ToolTip(), -1500)
}

; --- Copies the current selection via the clipboard, preserving the ---
; --- previous clipboard contents in the savedClip output parameter. ---
; --- Returns the selected text, or "" if nothing was selected. ---
; --- מעתיקה את הטקסט המסומן דרך הלוח, תוך שמירת תוכן הלוח הקודם ---
; --- בפרמטר הפלט savedClip. מחזירה את הטקסט המסומן, או "" אם לא נבחר טקסט. ---
GetSelectedText(&savedClip) {
    ; Preserve the user's existing clipboard content to restore it later
    savedClip := ClipboardAll()

    A_Clipboard := ""              ; clear clipboard before copying
    Sleep(100)                     ; brief delay to let physical modifier keys release
    Send("^c")                     ; copy the selected text
    if !ClipWait(1.5)              ; wait up to 1.5s for the copy to complete
    {
        ShowNoSelectionTooltip()
        A_Clipboard := savedClip
        return ""
    }

    original := A_Clipboard

    if (original = savedClip)
    {
        ; Clipboard didn't change - the copy likely failed (no real selection)
        ShowNoSelectionTooltip()
        A_Clipboard := savedClip
        return ""
    }

    return original
}

; --- Pastes text over the current selection, then restores the ---
; --- clipboard contents captured earlier by GetSelectedText. ---
; --- מדביקה טקסט על גבי הבחירה הנוכחית, ולאחר מכן משחזרת את ---
; --- תוכן הלוח שנשמר קודם לכן ע"י GetSelectedText. ---
ReplaceSelection(text, savedClip) {
    A_Clipboard := text
    Sleep(100)
    Send("^v")                     ; paste the result over the selection

    Sleep(300)                     ; brief delay before restoring the clipboard
    A_Clipboard := savedClip
}

; --- Hotkey: Ctrl+Alt+H ---
; --- קיצור מקלדת: Ctrl+Alt+H ---
^!h::
{
    savedClip := ""
    original := GetSelectedText(&savedClip)
    if (original = "")
        return

    ; Auto-detect conversion direction based on the selected text
    if ContainsHebrew(original)
        converted := ConvertText(original, HeToEn)   ; Hebrew -> English
    else
        converted := ConvertText(original, EnToHe)   ; English -> Hebrew

    ReplaceSelection(converted, savedClip)
}

; --- Hotkey: Ctrl+Alt+J - reverses the character order of the selection ---
; --- קיצור מקלדת: Ctrl+Alt+J - הופך את סדר התווים בטקסט המסומן ---
^!j::
{
    savedClip := ""
    original := GetSelectedText(&savedClip)
    if (original = "")
        return

    converted := ReverseText(original)
    ReplaceSelection(converted, savedClip)
}
