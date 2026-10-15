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

; ------------------------------------------------------------
;  Ctrl+Alt+J restores text that a terminal displayed in "visual" order:
;  each screen row was reordered with the Unicode bidi algorithm (UBA),
;  so Hebrew is reversed while English words and numbers are not. The
;  reordering used here (UBA rule L2) is its own inverse, so applying it
;  to the visual text with the same embedding levels restores the
;  original. Levels are resolved with a simplified UBA (rules W4-W7, N1-N2,
;  I1-I2), which is what decides where hyphens, colons and spaces between
;  Hebrew and English belong.
;  Ctrl+Alt+J משחזר טקסט שטרמינל הציג ב"סדר חזותי": כל שורת מסך סודרה
;  לפי אלגוריתם הדו-כיווניות של Unicode (UBA), כך שהעברית התהפכה ואילו
;  מילים באנגלית ומספרים לא. הסידור מחדש כאן (כלל L2) הופך את עצמו, ולכן
;  הפעלתו על הטקסט החזותי עם אותן רמות הטבעה משחזרת את המקור. הרמות
;  נקבעות לפי גרסה מפושטת של UBA (כללים W4-W7, N1-N2, I1-I2), והיא שקובעת
;  לאיזה צד שייכים מקפים, נקודתיים ורווחים שבין עברית לאנגלית.
; ------------------------------------------------------------

; --- Splits text into characters, keeping surrogate pairs (emoji) whole ---
; --- מפצלת טקסט לתווים, בלי לשבור זוגות surrogate (אימוג'י) ---
SplitChars(text) {
    chars := []
    Loop Parse, text
    {
        code := Ord(A_LoopField)
        if (code >= 0xDC00 && code <= 0xDFFF && chars.Length)
            chars[-1] .= A_LoopField
        else
            chars.Push(A_LoopField)
    }
    return chars
}

; --- Bidi class of a character: R (Hebrew), L (other letters), EN (digit), ---
; --- ES/CS/ET (number separators and signs) or N (neutral) ---
; --- המחלקה הדו-כיוונית של תו: R (עברית), L (אותיות אחרות), EN (ספרה), ---
; --- ES/CS/ET (מפרידים וסימנים של מספרים) או N (ניטרלי) ---
BidiClass(ch) {
    if RegExMatch(ch, "[\x{0590}-\x{05FF}\x{FB1D}-\x{FB4F}]")
        return "R"
    if RegExMatch(ch, "^[0-9]$")
        return "EN"
    if (ch = "+" || ch = "-")
        return "ES"
    if InStr(",.:/", ch)
        return "CS"
    if InStr("#$%°", ch)
        return "ET"
    if RegExMatch(ch, "^\p{L}")
        return "L"
    return "N"
}

; --- Decides the row's base direction. A left-to-right row always shows ---
; --- its first letter at the far left; a right-to-left row shows its ---
; --- first letter at the far right. When both readings fit (English at ---
; --- the left, Hebrew at the right), sentence punctuation decides: it ---
; --- belongs to the logical end, which a right-to-left row puts on the left. ---
; --- קובעת את כיוון הבסיס של השורה. שורה משמאל לימין תמיד מציגה את ---
; --- האות הראשונה שלה בקצה השמאלי; שורה מימין לשמאל מציגה אותה בקצה ---
; --- הימני. כששתי הקריאות אפשריות (אנגלית משמאל, עברית מימין), סימן ---
; --- הפיסוק מכריע: הוא שייך לסוף הלוגי, ששורה מימין לשמאל מציבה משמאל. ---
IsRtlRow(chars, types) {
    first := 0, last := 0
    for i, t in types
        if (t = "L" || t = "R")
        {
            if !first
                first := i
            last := i
        }
    if !first
        return false
    if (types[first] = "R")
        return true
    if (types[last] = "L")
        return false
    loop first - 1
        if InStr(".!?:;,", chars[A_Index])
            return true
    return false
}

; --- Resolves the embedding level of every character of a visual row ---
; --- קובעת את רמת ההטבעה של כל תו בשורה חזותית ---
BidiLevels(chars, &rtl) {
    n := chars.Length
    t := []
    for ch in chars
        t.Push(BidiClass(ch))
    rtl := IsRtlRow(chars, t)

    ; W4: one separator between two digits is part of the number (1.5, 3-4)
    loop n - 2
    {
        i := A_Index + 1
        if ((t[i] = "ES" || t[i] = "CS") && t[i - 1] = "EN" && t[i + 1] = "EN")
            t[i] := "EN"
    }
    ; W5: signs touching a number are part of it (50%, $5)
    i := 1
    while (i <= n)
    {
        if (t[i] != "ET")
        {
            i += 1
            continue
        }
        j := i
        while (j < n && t[j + 1] = "ET")
            j += 1
        if ((i > 1 && t[i - 1] = "EN") || (j < n && t[j + 1] = "EN"))
            loop j - i + 1
                t[i + A_Index - 1] := "EN"
        i := j + 1
    }
    ; W6: any other separator or sign is neutral
    for i, ty in t
        if (ty = "ES" || ty = "CS" || ty = "ET")
            t[i] := "N"
    ; W7: a number that follows English is treated as English
    prevStrong := ""
    for i, ty in t
    {
        if (ty = "L" || ty = "R")
            prevStrong := ty
        else if (ty = "EN" && (prevStrong = "L" || (prevStrong = "" && !rtl)))
            t[i] := "EN_L"
    }

    ; N1/N2: a neutral takes the direction of its surroundings when both
    ; sides agree (numbers count as R), otherwise the row's direction
    edge := rtl ? "R" : "L"
    strongBefore := [], dir := edge
    for ty in t
    {
        if (ty != "N")
            dir := (ty = "L" || ty = "EN_L") ? "L" : "R"
        strongBefore.Push(dir)
    }
    strongAfter := [], dir := edge
    loop n
    {
        ty := t[n - A_Index + 1]
        if (ty != "N")
            dir := (ty = "L" || ty = "EN_L") ? "L" : "R"
        strongAfter.InsertAt(1, dir)
    }

    ; I1/I2: levels relative to the row's direction
    levels := []
    for i, ty in t
    {
        if (ty = "N")
            ty := (strongBefore[i] = strongAfter[i]) ? strongBefore[i] : edge
        if rtl
            levels.Push(ty = "R" ? 1 : 2)
        else
            levels.Push(ty = "L" || ty = "EN_L" ? 0 : ty = "EN" ? 2 : 1)
    }
    return levels
}

; --- UBA rule L2: from the highest level down to 1, reverse every run ---
; --- of characters at that level or higher ---
; --- כלל L2 של UBA: מהרמה הגבוהה ביותר ועד 1, הופכת כל רצף תווים ---
; --- שנמצא ברמה הזו או מעליה ---
BidiReorder(chars, levels) {
    n := chars.Length
    maxLevel := 0
    for lv in levels
        maxLevel := Max(maxLevel, lv)
    lvl := maxLevel
    while (lvl >= 1)
    {
        i := 1
        while (i <= n)
        {
            if (levels[i] < lvl)
            {
                i += 1
                continue
            }
            j := i
            while (j < n && levels[j + 1] >= lvl)
                j += 1
            a := i, b := j
            while (a < b)
            {
                tmp := chars[a], chars[a] := chars[b], chars[b] := tmp
                tmp := levels[a], levels[a] := levels[b], levels[b] := tmp
                a += 1, b -= 1
            }
            i := j + 1
        }
        lvl -= 1
    }
    result := ""
    for ch in chars
        result .= ch
    return result
}

; --- Restores one back-to-front row, keeping list bullets and edge ---
; --- whitespace in place. Text in a terminal box loses its "│" border. ---
; --- משחזרת שורה הפוכה אחת, ומשאירה תבליטים ורווחים בקצוות במקומם. ---
; --- טקסט מתוך מסגרת של טרמינל מאבד את קו המסגרת "│". ---
FixReversedLine(line) {
    line := RegExReplace(line, "^\s*│ ?|\s*│\s*$")
    RegExMatch(line, "^(\s*(?:(?:[-*•]|\d+[.)])\s+)?)(.*?)(\s*)$", &m)
    chars := SplitChars(m[2])
    levels := BidiLevels(chars, &rtl)
    return m[1] . BidiReorder(chars, levels) . m[3]
}

; --- Fixes back-to-front text line by line, keeping the line order. ---
; --- Text without Hebrew is simply reversed character by character. ---
; --- מתקנת טקסט הפוך שורה אחר שורה, תוך שמירה על סדר השורות. ---
; --- טקסט בלי עברית פשוט מתהפך תו אחר תו. ---
FixReversedText(text) {
    hasHebrew := ContainsHebrew(text)
    lines := StrSplit(text, "`n")
    for i, line in lines
    {
        cr := (SubStr(line, -1) = "`r") ? "`r" : ""
        if cr
            line := SubStr(line, 1, -1)
        lines[i] := (hasHebrew ? FixReversedLine(line) : ReverseText(line)) . cr
    }
    result := ""
    for i, line in lines
        result .= (i > 1 ? "`n" : "") . line
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
        value := Trim(SubStr(line, eqPos + 1))
        if (StrLen(value) >= 2 && ((SubStr(value, 1, 1) = '"' && SubStr(value, -1) = '"') || (SubStr(value, 1, 1) = "'" && SubStr(value, -1) = "'")))
            value := SubStr(value, 2, StrLen(value) - 2)
        env[key] := value
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

; --- Decodes a WinHttpRequest's response body as UTF-8, regardless of ---
; --- what (if anything) the server declared as its charset. This ---
; --- matters because .ResponseText's own charset auto-detection is ---
; --- unreliable - e.g. DeepL's response doesn't spell out "charset=utf-8" ---
; --- in its Content-Type, which makes .ResponseText mis-decode Hebrew as ---
; --- the system codepage. All three translation APIs return UTF-8 JSON ---
; --- (the JSON default per RFC 8259), so forcing UTF-8 here is correct. ---
; --- מפענחת את גוף התגובה של WinHttpRequest כ-UTF-8, בלי קשר למה ---
; --- שהשרת הצהיר (אם בכלל) כ-charset. זה חשוב כי הזיהוי האוטומטי של ---
; --- .ResponseText לא אמין - למשל, בתגובת DeepL אין "charset=utf-8" ---
; --- מפורש ב-Content-Type, מה שגורם ל-.ResponseText לפענח עברית לפי ---
; --- קידוד המערכת ולקבל ג'יבריש. כל שלושת ה-API-ים של תרגום מחזירים ---
; --- JSON ב-UTF-8 (ברירת המחדל של JSON לפי RFC 8259), אז כפיית UTF-8 כאן נכונה. ---
DecodeUtf8Response(req) {
    stream := ComObject("ADODB.Stream")
    stream.Type := 1            ; adTypeBinary
    stream.Open()
    stream.Write(req.ResponseBody)
    stream.Position := 0
    stream.Type := 2            ; adTypeText
    stream.Charset := "utf-8"
    text := stream.ReadText()
    stream.Close()
    return text
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
        responseText := DecodeUtf8Response(req)
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
        responseText := DecodeUtf8Response(req)
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

; --- Priority 2: Google Translate (unofficial, keyless) endpoint. Uses the ---
; --- "dict-chrome-ex" client (from Google's Chrome Dictionary extension), ---
; --- which returns a flat ["translated text"] array - not the split-into- ---
; --- sentence-"chunks" nested array that the translate_a/single?client=gtx ---
; --- endpoint returns. gtx was found to be reliably blocked with HTTP 429 ---
; --- ("unusual traffic from your computer or network") from residential/ ---
; --- home IPs in testing, while dict-chrome-ex responded normally - so ---
; --- dict-chrome-ex is used here as the more reliable of the two. ---
; --- עדיפות 2: נקודת קצה לא-רשמית וללא מפתח של Google Translate. משתמשת ---
; --- ב-client בשם "dict-chrome-ex" (מתוסף המילון של Chrome), שמחזיר מערך ---
; --- שטוח ["טקסט מתורגם"] - לא את המערך המקונן המפוצל ל"נתחי" משפטים ---
; --- שמחזירה נקודת הקצה translate_a/single?client=gtx. בבדיקות, gtx נחסמה ---
; --- באופן עקבי עם HTTP 429 ("unusual traffic from your computer or ---
; --- network") מכתובות IP ביתיות, בעוד ש-dict-chrome-ex הגיבה כרגיל - ---
; --- לכן dict-chrome-ex בשימוש כאן כאמינה יותר מבין השתיים. ---
TranslateGoogle(text, sourceLang, targetLang) {
    url := "https://clients5.google.com/translate_a/t"
        . "?client=dict-chrome-ex&sl=" . sourceLang . "&tl=" . targetLang . "&q=" . UrlEncode(text)
    headers := Map("User-Agent", "Mozilla/5.0")

    ok := HttpGet(url, &status, &responseText, headers)
    if (!ok || status != 200)   ; e.g. 429 = rate limited / temporarily blocked
        return ""

    if !RegExMatch(responseText, '^\[\s*"((?:\\.|[^"\\])*)"', &m)
        return ""
    return JsonUnescape(m[1])
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

    converted := FixReversedText(original)
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
