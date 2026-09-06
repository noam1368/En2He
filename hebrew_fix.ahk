; ============================================================
;  Hebrew Fix - Converts selected text typed in the wrong
;  keyboard layout (Hebrew <-> English), based on the
;  standard Israeli keyboard layout (SI 1452).
;  Also reverses the character order of selected text, for
;  text that appears back-to-front (e.g. an RTL/LTR display bug).
;  Also auto-translates selected text between Hebrew and English,
;  using DeepL / Google Translate / MyMemory as fallbacks.
;
;  Usage: select text in any application and press Ctrl+Alt+H
;         to fix the keyboard layout, Ctrl+Alt+J to reverse
;         the character order, or Ctrl+Alt+T to translate.
;  Requires AutoHotkey v2   https://www.autohotkey.com
;
;  --- בעברית ---
;  Hebrew Fix - ממיר טקסט מסומן שהוקלד בטעות בפריסת מקלדת שגויה
;  (עברית <-> אנגלית), לפי פריסת המקלדת הישראלית הסטנדרטית (SI 1452).
;  כמו כן הופך את סדר התווים בטקסט מסומן, עבור טקסט שמוצג הפוך
;  (למשל עקב תקלת תצוגה RTL/LTR).
;  כמו כן מתרגם אוטומטית טקסט מסומן בין עברית לאנגלית, באמצעות
;  DeepL / Google Translate / MyMemory כגיבוי זה לזה.
;
;  שימוש: סמנו טקסט בכל אפליקציה ולחצו Ctrl+Alt+H
;         לתיקון פריסת המקלדת, Ctrl+Alt+J להיפוך סדר התווים,
;         או Ctrl+Alt+T לתרגום.
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
    return RegExMatch(text, "[\x{0590}-\x{05FF}]") > 0
}

; --- Reverses the character order of a string ---
; --- הופכת את סדר התווים במחרוזת ---
ReverseText(text) {
    result := ""
    Loop Parse, text
        result := A_LoopField . result
    return result
}

; --- Shows a short tooltip near the cursor that clears itself ---
; --- מציגה הודעה זמנית ליד הסמן שנעלמת מעצמה ---
ShowTooltip(message, durationMs := 1500) {
    ToolTip(message)
    SetTimer(() => ToolTip(), -durationMs)
}

; --- Shows a short "no selection" tooltip that clears itself ---
; --- מציגה הודעת "לא נבחר טקסט" זמנית שנעלמת מעצמה ---
ShowNoSelectionTooltip() {
    ShowTooltip("No text selected")
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

; ============================================================
;  Translation (Ctrl+Alt+T) - DeepL / Google / MyMemory fallback chain
;  תרגום (Ctrl+Alt+T) - שרשרת גיבוי DeepL / Google / MyMemory
; ============================================================

; --- Reads KEY=VALUE pairs from a ".env" file next to the script into a ---
; --- Map. Missing file or missing keys simply resolve to "" - callers ---
; --- treat an empty value as "this provider isn't configured". ---
; --- קוראת זוגות KEY=VALUE מקובץ ".env" ליד הסקריפט למפה (Map). קובץ ---
; --- חסר או מפתח חסר פשוט מתפרשים כ-"" - הקוד הקורא מתייחס לערך ריק ---
; --- כאל "הספק הזה לא מוגדר". ---
LoadEnv() {
    env := Map()
    envPath := A_ScriptDir . "\.env"
    if !FileExist(envPath)
        return env

    for line in StrSplit(FileRead(envPath, "UTF-8"), "`n", "`r")
    {
        line := Trim(line)
        if (line = "" || SubStr(line, 1, 1) = "#")
            continue
        eqPos := InStr(line, "=")
        if !eqPos
            continue
        key := Trim(SubStr(line, 1, eqPos - 1))
        env[key] := Trim(SubStr(line, eqPos + 1))
    }
    return env
}

; --- Encodes a string as UTF-8 bytes in a Buffer (byteCount excludes the ---
; --- trailing null terminator StrPut always writes). ---
; --- מקודדת מחרוזת לבתי UTF-8 בתוך Buffer (byteCount לא כולל את תו ה-null ---
; --- שבו StrPut תמיד מסיימת). ---
Utf8Bytes(text, &byteCount) {
    byteCount := StrPut(text, "UTF-8") - 1
    buf := Buffer(byteCount + 1)
    StrPut(text, buf, "UTF-8")
    return buf
}

; --- Percent-encodes a string for use in a URL query, over its UTF-8 bytes ---
; --- מקודדת מחרוזת ל-percent-encoding לשימוש בפרמטרי URL, על בסיס הבתים ב-UTF-8 ---
UrlEncode(text) {
    buf := Utf8Bytes(text, &byteCount)
    result := ""
    loop byteCount
    {
        byte := NumGet(buf, A_Index - 1, "UChar")
        if (byte >= 0x41 && byte <= 0x5A) || (byte >= 0x61 && byte <= 0x7A) || (byte >= 0x30 && byte <= 0x39)
            || byte = 0x2D || byte = 0x5F || byte = 0x2E || byte = 0x7E   ; - _ . ~
            result .= Chr(byte)
        else
            result .= "%" . Format("{:02X}", byte)
    }
    return result
}

; --- Escapes a string so it can be embedded as a JSON string literal ---
; --- עוטפת מחרוזת בבריחות (escaping) כדי לשבץ אותה כמחרוזת JSON תקנית ---
JsonEscape(text) {
    text := StrReplace(text, "\", "\\")
    text := StrReplace(text, '"', '\"')
    text := StrReplace(text, "`r", "\r")
    text := StrReplace(text, "`n", "\n")
    text := StrReplace(text, "`t", "\t")
    return text
}

; --- Reverses JSON string escaping (\", \\, \/, \n, \t, \r, \uXXXX) ---
; --- הופכת בריחות JSON למחרוזת רגילה (\", \\, \/, \n, \t, \r, \uXXXX) ---
JsonUnescape(text) {
    out := ""
    i := 1
    len := StrLen(text)
    while (i <= len)
    {
        ch := SubStr(text, i, 1)
        if (ch = "\" && i < len)
        {
            nextCh := SubStr(text, i + 1, 1)
            switch nextCh
            {
                case '"': out .= '"'
                case "\": out .= "\"
                case "/": out .= "/"
                case "n": out .= "`n"
                case "t": out .= "`t"
                case "r": out .= "`r"
                case "b": out .= "`b"
                case "f": out .= "`f"
                case "u":
                    hex := SubStr(text, i + 2, 4)
                    out .= Chr(("0x" . hex) + 0)
                    i += 4
                default:
                    out .= nextCh
            }
            i += 2
        }
        else
        {
            out .= ch
            i += 1
        }
    }
    return out
}

; --- Extracts the value of a "key":"value" pair from a JSON string, ---
; --- unescaping it. Returns "" if the key isn't found. ---
; --- מחלצת את הערך של זוג "key":"value" ממחרוזת JSON, עם הסרת בריחות. ---
; --- מחזירה "" אם המפתח לא נמצא. ---
JsonExtractString(json, key) {
    if !RegExMatch(json, '"' . key . '"\s*:\s*"((?:\\.|[^"\\])*)"', &m)
        return ""
    return JsonUnescape(m[1])
}

; --- Extracts the numeric value of a "key":number pair from a JSON string ---
; --- מחלצת ערך מספרי של זוג "key":number ממחרוזת JSON ---
JsonExtractNumber(json, key) {
    if !RegExMatch(json, '"' . key . '"\s*:\s*(-?\d+)', &m)
        return 0
    return Integer(m[1])
}

; --- Sends an HTTPS GET request. Returns true on a completed HTTP ---
; --- exchange (any status code); false only on a transport-level ---
; --- failure (no network, DNS, timeout, ...). ---
; --- שולחת בקשת HTTPS GET. מחזירה true על חליפין HTTP שהושלם (כל קוד ---
; --- סטטוס); false רק על כשל ברמת התעבורה (אין רשת, DNS, timeout...). ---
HttpGet(url, &status, &responseText, headers := "") {
    status := 0
    responseText := ""
    try
    {
        req := ComObject("WinHttp.WinHttpRequest.5.1")
        req.SetTimeouts(5000, 5000, 5000, 8000)
        req.Open("GET", url, false)
        if IsObject(headers)
            for name, value in headers
                req.SetRequestHeader(name, value)
        req.Send()
        status := req.Status
        responseText := req.ResponseText
        return true
    }
    catch
        return false
}

; --- Sends an HTTPS POST request with a JSON body. Same return semantics ---
; --- as HttpGet. WinHttpRequest.Send() automatically encodes a string ---
; --- body as UTF-8 whenever it isn't representable as ISO-8859-1 (which ---
; --- covers all our Hebrew text), matching the "charset=utf-8" we ---
; --- declare below - so no manual byte encoding is needed here. ---
; --- שולחת בקשת HTTPS POST עם גוף JSON. סמנטיקת החזרה זהה ל-HttpGet. ---
; --- WinHttpRequest.Send() מקודדת אוטומטית מחרוזת כ-UTF-8 בכל פעם שאי ---
; --- אפשר לייצג אותה ב-ISO-8859-1 (וזה מכסה את כל הטקסט העברי שלנו), ---
; --- בהתאמה ל-"charset=utf-8" שמוצהר למטה - כך שאין צורך בקידוד בתים ידני כאן. ---
HttpPostJson(url, jsonBody, &status, &responseText, headers := "") {
    status := 0
    responseText := ""
    try
    {
        req := ComObject("WinHttp.WinHttpRequest.5.1")
        req.SetTimeouts(5000, 5000, 5000, 8000)
        req.Open("POST", url, false)
        req.SetRequestHeader("Content-Type", "application/json; charset=utf-8")
        if IsObject(headers)
            for name, value in headers
                req.SetRequestHeader(name, value)
        req.Send(jsonBody)
        status := req.Status
        responseText := req.ResponseText
        return true
    }
    catch
        return false
}

; --- Priority 1: DeepL API Free. Requires DEEPL_API_KEY. Returns "" if ---
; --- no key is configured, or on any error/quota-exceeded response, so ---
; --- the caller can fall through to the next provider. ---
; --- עדיפות 1: DeepL API Free. דורש DEEPL_API_KEY. מחזירה "" אם אין ---
; --- מפתח מוגדר, או בכל תגובת שגיאה/חריגת מכסה, כדי שהקוד הקורא ---
; --- יעבור לספק הבא. ---
TranslateDeepL(text, sourceLang, targetLang, apiKey) {
    if (apiKey = "")
        return ""

    body := '{"text":["' . JsonEscape(text) . '"],"source_lang":"' . sourceLang . '","target_lang":"' . targetLang . '"}'
    headers := Map("Authorization", "DeepL-Auth-Key " . apiKey)

    ok := HttpPostJson("https://api-free.deepl.com/v2/translate", body, &status, &responseText, headers)
    if (!ok || status != 200)   ; e.g. 456 = quota exceeded, 403 = bad key, 429 = rate limited
        return ""

    return JsonExtractString(responseText, "text")
}

; --- Priority 2: Google Translate (unofficial, keyless) web endpoint. ---
; --- The response is a nested JSON array split into sentence "chunks" - ---
; --- every chunk's translated segment is concatenated in order. ---
; --- עדיפות 2: נקודת קצה לא-רשמית וללא מפתח של Google Translate. ---
; --- התגובה היא מערך JSON מקונן, מפוצל ל"נתחי" משפטים - קטע התרגום ---
; --- של כל נתח מחובר לפי הסדר. ---
TranslateGoogle(text, sourceLang, targetLang) {
    url := "https://translate.googleapis.com/translate_a/single"
        . "?client=gtx&sl=" . sourceLang . "&tl=" . targetLang . "&dt=t&q=" . UrlEncode(text)
    headers := Map("User-Agent", "Mozilla/5.0")

    ok := HttpGet(url, &status, &responseText, headers)
    if (!ok || status != 200)   ; e.g. 429 = rate limited / temporarily blocked
        return ""

    result := ""
    pos := 1
    while (pos := RegExMatch(responseText, '\[\s*"((?:\\.|[^"\\])*)"\s*,\s*"(?:\\.|[^"\\])*"', &m, pos))
    {
        result .= JsonUnescape(m[1])
        pos += StrLen(m[0])
    }
    return result
}

; --- Priority 3: MyMemory. No key required; an optional MYMEMORY_EMAIL ---
; --- raises the free daily quota. IMPORTANT: MyMemory always answers ---
; --- with HTTP 200, even when its quota is exhausted - failure only ---
; --- shows up as responseStatus != 200 inside the JSON body (with the ---
; --- warning text sitting in translatedText), so that field must be ---
; --- checked explicitly rather than trusting the HTTP status alone. ---
; --- עדיפות 3: MyMemory. לא דורש מפתח; MYMEMORY_EMAIL אופציונלי מעלה ---
; --- את המכסה היומית החינמית. חשוב: MyMemory תמיד מחזירה HTTP 200, ---
; --- גם כשהמכסה נגמרה - הכשל מופיע רק כ-responseStatus שונה מ-200 ---
; --- בתוך גוף ה-JSON (וטקסט האזהרה יושב בתוך translatedText), ולכן יש ---
; --- לבדוק את השדה הזה במפורש ולא לסמוך רק על סטטוס ה-HTTP. ---
TranslateMyMemory(text, sourceLang, targetLang, email) {
    url := "https://api.mymemory.translated.net/get"
        . "?q=" . UrlEncode(text) . "&langpair=" . sourceLang . "|" . targetLang
    if (email != "")
        url .= "&de=" . UrlEncode(email)

    ok := HttpGet(url, &status, &responseText)
    if (!ok || status != 200)
        return ""

    if (JsonExtractNumber(responseText, "responseStatus") != 200)
        return ""

    return JsonExtractString(responseText, "translatedText")
}

; --- Main translation wrapper: tries DeepL, then Google Translate, then ---
; --- MyMemory, returning the first non-empty result. Returns "" only ---
; --- if every provider failed or was unavailable. ---
; --- עוטפת התרגום הראשית: מנסה DeepL, אחר כך Google Translate, ואחר כך ---
; --- MyMemory, ומחזירה את התוצאה הראשונה שאינה ריקה. מחזירה "" רק אם ---
; --- כל הספקים נכשלו או שלא היו זמינים. ---
TranslateText(text, fromHebrew) {
    env := LoadEnv()

    if fromHebrew
        deeplSrc := "HE", deeplTgt := "EN-US", simpleSrc := "he", simpleTgt := "en"
    else
        deeplSrc := "EN", deeplTgt := "HE", simpleSrc := "en", simpleTgt := "he"

    apiKey := env.Has("DEEPL_API_KEY") ? env["DEEPL_API_KEY"] : ""
    if (result := TranslateDeepL(text, deeplSrc, deeplTgt, apiKey)) != ""
        return result

    if (result := TranslateGoogle(text, simpleSrc, simpleTgt)) != ""
        return result

    email := env.Has("MYMEMORY_EMAIL") ? env["MYMEMORY_EMAIL"] : ""
    if (result := TranslateMyMemory(text, simpleSrc, simpleTgt, email)) != ""
        return result

    return ""
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

; --- Hotkey: Ctrl+Alt+T - translates the selection between Hebrew and English ---
; --- קיצור מקלדת: Ctrl+Alt+T - מתרגם את הבחירה בין עברית לאנגלית ---
^!t::
{
    savedClip := ""
    original := GetSelectedText(&savedClip)
    if (original = "")
        return

    ; Auto-detect direction based on the selected text
    fromHebrew := ContainsHebrew(original)

    ShowTooltip("Translating...", 60000)
    translated := TranslateText(original, fromHebrew)
    ToolTip()

    if (translated = "")
    {
        A_Clipboard := savedClip
        ShowTooltip("Translation failed")
        return
    }

    ReplaceSelection(translated, savedClip)
}
