# Hebrew Fix

A lightweight Windows tool for fixing selected text in any application with a single keyboard shortcut:

| Shortcut | What it does |
|---|---|
| `CapsLock+H` | Fixes text typed in the wrong keyboard layout — Hebrew typed while the keyboard was on English (`akuo hjuo` → `שלום רב`), or the reverse. |
| `CapsLock+J` | Restores Hebrew that came out reversed (for example, copied from a terminal), keeping line order and mixed English/numbers readable. |
| `CapsLock+T` | Translates Hebrew → English, or anything else → Hebrew (DeepL, with free Google / MyMemory fallback). |

The direction is detected automatically. Keyboard layout conversion is based on the standard Israeli layout (SI 1452).

## Requirements

- Windows
- [AutoHotkey v2](https://www.autohotkey.com/) (free, open source)

## Installation

1. Download and install **AutoHotkey v2** from the official site: https://www.autohotkey.com/
   (choose the `v2.0` version, not `v1.1`)
2. Download the [`hebrew_fix.ahk`](./hebrew_fix.ahk) file from this repo to your computer.
3. Double-click the file — the tool will start running in the background (a small green icon will appear in the system tray, near the clock).

That's it — the tool is active and ready to use.

## Usage

Select text in any application (Word, browser, Notepad, desktop WhatsApp, any text field), then press one of the shortcuts below: hold `CapsLock` and press the letter. If no text was selected, a brief "No text selected" message appears and nothing else happens.

`CapsLock` pressed by itself still turns capital letters on and off. The switch now happens when you release the key, and only if you didn't press another key while holding it.

### Fix keyboard layout — `CapsLock+H`

The selected text is converted automatically:
- If it contains Hebrew letters → converted to English.
- If it doesn't contain Hebrew (i.e. "leftover English") → converted to Hebrew.

### Reverse character order — `CapsLock+J`

Reverses the character order of the selection — useful for text that displays back-to-front due to an RTL/LTR display bug (for example, Hebrew copied from a terminal).
- Works line by line, so multi-line text keeps its line and paragraph order.
- English words, numbers and list bullets (`-`, `*`, `1.`) inside Hebrew text stay readable instead of being flipped.
- The `│` border of text copied from a terminal box is removed.
- Limitation: a paragraph that wrapped onto several rows in the terminal is copied as one line, with each row reversed separately and no marker where one row ends. The text alone doesn't say where to split it, so such paragraphs come out with their parts in the wrong order. To copy a long answer from Claude Code, use the `/copy` command instead, which copies the original text.

### Translate — `CapsLock+T`

Translates the selection automatically:
- If it contains Hebrew → translated to English.
- Otherwise → translated to Hebrew.

The translated text replaces the selection, just like the other shortcuts. See [Setting up automatic translation](#setting-up-automatic-translation-capslockt) below for how the translation itself works and how to get the best results out of it.

## Setting up automatic translation (CapsLock+T)

`CapsLock+T` tries up to three translation services, in order, and automatically falls back to the next one if a service is unavailable, out of quota, or returns an error:

1. **DeepL API Free** — highest translation quality. Used first, if you've configured a free API key (see below).
2. **Google Translate** — free, no key required. Used automatically whenever DeepL isn't configured or its quota is exhausted.
3. **MyMemory** — free, no key required (an optional email raises its daily quota). Used as a last resort if both services above fail.

If all three fail (e.g. no internet connection), a "Translation failed" message appears and the original text is left untouched.

### Getting a free DeepL API key (optional, recommended)

1. Sign up for a free account at [deepl.com/pro-api](https://www.deepl.com/pro-api) (no credit card required).
2. Create an API key from your DeepL account page. Free-plan keys always end with `:fx`.
3. The free plan includes **500,000 characters per month** at no cost. Once that monthly limit is reached, DeepL is skipped automatically and the tool falls back to Google Translate / MyMemory until the quota resets.

### Setting up the `.env` file

1. Copy [`.env.example`](./.env.example) to a new file named `.env`, in the same folder as `hebrew_fix.ahk`.
2. Open `.env` in a text editor and fill in:
   - `DEEPL_API_KEY` — your DeepL API Free key (leave empty to skip DeepL and start from Google Translate).
   - `MYMEMORY_EMAIL` — optional; your email, to raise MyMemory's free daily quota from 5,000 to 50,000 characters.
3. Save the file. `.env` is listed in `.gitignore` and is never committed to Git — your keys stay private on your own computer.

## Run automatically on startup

To have the tool start automatically every time you boot your computer:

1. Press `Win + R`, type `shell:startup`, and press Enter.
2. In the folder that opens, remove any older copy of `hebrew_fix.ahk`.
3. Right-click `hebrew_fix.ahk` in the project folder → **Show more options** → **Create shortcut**, and move the new shortcut into the Startup folder.

Use a **shortcut, not a copy**: a copy doesn't get later updates, and it can't find your `.env` file (the script looks for it in its own folder), so translation falls back to the free services. Two copies at different paths also run side by side, with conflicting shortcuts.

## Changing the keyboard shortcuts

If a shortcut conflicts with another one you use, open `hebrew_fix.ahk` in a text editor and change its line:

```autohotkey
CapsLock & h::   ; CapsLock+H — fix keyboard layout
CapsLock & j::   ; CapsLock+J — restore reversed text
CapsLock & t::   ; CapsLock+T — translate
```

To use another letter with `CapsLock`, change the letter after `&`. To use regular modifier keys instead, write them in place of `CapsLock &`: `^` = Ctrl, `!` = Alt, `+` = Shift, `#` = Win. For example, to go back to `Ctrl+Alt+H`, change `CapsLock & h::` to `^!h::`. If no shortcut uses `CapsLock` anymore, also delete the `CapsLock::` line above them. Save, then double-click the file again to reload it.

AutoHotkey doesn't warn you if another program already uses the same shortcut; the other program's shortcut just stops working. Try a new combination in the programs you use before you assign it.

## How it works

Each shortcut:
1. Saves your current clipboard content (so it isn't lost).
2. Copies the selected text (`Ctrl+C`).
3. Transforms it:
   - `CapsLock+H` maps each key to the other layout, using a table that matches the standard Israeli layout.
   - `CapsLock+J` processes each line separately. It works out which parts of the line were flipped (Hebrew) and which stayed readable (English, numbers), following the same Unicode bidirectional rules the terminal used to display it, and undoes that reordering.
   - `CapsLock+T` sends the text to the first translation service that answers.
4. Pastes the result over the original selection (`Ctrl+V`).
5. Restores your original clipboard content.

H and J happen in a fraction of a second. T takes as long as the translation service does.

## Known limitations

- Only works well on **uniform text** (entirely mistyped Hebrew, or entirely mistyped English). If the selection mixes in valid text from the other language, that part may get "corrupted" too, since the tool can't distinguish a real typo from correct text.
- Supports the standard Israeli keyboard layout only (not alternative layouts such as the phonetic one).
- Tested on Windows only.
- `CapsLock+T` depends on an internet connection, and by default may fall back to Google Translate's or MyMemory's unofficial/free endpoints, which can be rate-limited or blocked without notice. For more reliable translations, set up a free DeepL API key.
- `CapsLock+J` can't restore a paragraph that wrapped onto several rows in the terminal (see above). It also can't tell apart a Hebrew line that ends in an English word without closing punctuation from a line that starts with that word, since both copy identically; it assumes the latter.

## Project status

The project is complete for now: all three shortcuts work and have been tested in everyday use.

What has been built:
1. `CapsLock+H` — keyboard layout fix (the original tool).
2. `CapsLock+J` — first as a plain character reversal, then rewritten to work line by line and keep English, numbers and bullets readable inside Hebrew.
3. `CapsLock+T` — translation with automatic fallback DeepL → Google → MyMemory, keys kept in a private `.env`.
4. Fixes: Hebrew in translation responses no longer comes out garbled, quoted `.env` values are accepted, and Google Translate uses an endpoint that doesn't return "Too many requests" (429).
5. The shortcuts moved from `Ctrl+Alt` to `CapsLock`, so `Alt` isn't needed.

Possible future work:
- The `CapsLock+J` and `CapsLock+H` limitations listed above.
- No automated tests in the repo yet; the `CapsLock+J` logic was tested with a separate script.

## License

Free to use, modify, and distribute.

---

# Hebrew Fix (עברית)

כלי קטן ל-Windows שמתקן טקסט מסומן בכל אפליקציה, בלחיצת קיצור מקלדת אחת:

| קיצור | מה הוא עושה |
|---|---|
| `CapsLock+H` | מתקן טקסט שהוקלד בפריסת מקלדת לא נכונה: עברית שהוקלדה כשהמקלדת הייתה על אנגלית (`akuo hjuo` → `שלום רב`), או להפך. |
| `CapsLock+J` | משחזר עברית שיצאה הפוכה (למשל כשמעתיקים מטרמינל), תוך שמירה על סדר השורות ועל אנגלית ומספרים קריאים. |
| `CapsLock+T` | מתרגם עברית לאנגלית, וכל דבר אחר לעברית (DeepL, ובגיבוי Google / MyMemory החינמיים). |

הכיוון מזוהה אוטומטית. המרת פריסת המקלדת מבוססת על הפריסה הישראלית הסטנדרטית (SI 1452).

## דרישות

- Windows
- [AutoHotkey v2](https://www.autohotkey.com/) (חינמי, קוד פתוח)

## התקנה

1. הורידו והתקינו את **AutoHotkey v2** מהאתר הרשמי: https://www.autohotkey.com/
   (בחרו בגרסה `v2.0`, לא `v1.1`)
2. הורידו את הקובץ [`hebrew_fix.ahk`](./hebrew_fix.ahk) מהריפו הזה למחשב שלכם.
3. לחצו לחיצה כפולה על הקובץ — הכלי יתחיל לרוץ ברקע (תופיע אייקון ירוק ב-system tray, ליד השעון).

זהו — הכלי פעיל ומוכן לשימוש.

## שימוש

סמנו טקסט בכל אפליקציה (וורד, דפדפן, פתקים, וואטסאפ דסקטופ, כל תיבת טקסט שהיא), ואז לחצו על אחד הקיצורים למטה: החזיקו `CapsLock` ולחצו על האות. אם לא סימנתם טקסט, תופיע הודעה קצרה "No text selected" ולא יקרה דבר.

לחיצה על `CapsLock` לבד עדיין מפעילה ומכבה אותיות גדולות. ההחלפה קורית עכשיו כשמשחררים את המקש, ורק אם לא לחצתם על מקש אחר בזמן שהחזקתם אותו.

### תיקון פריסת מקלדת — `CapsLock+H`

הטקסט המסומן יומר אוטומטית:
- אם הוא מכיל אותיות עבריות → יומר לאנגלית.
- אם הוא לא מכיל עברית (כלומר "אנגלית מיותרת") → יומר לעברית.

### היפוך סדר תווים — `CapsLock+J`

הופך את סדר התווים בבחירה — שימושי לטקסט שמוצג הפוך עקב תקלת תצוגה RTL/LTR (למשל, עברית שהועתקה מטרמינל).
- עובד שורה אחר שורה, כך שטקסט מרובה שורות שומר על סדר השורות והפסקאות.
- מילים באנגלית, מספרים ותבליטים (`-`, `*`, `1.`) בתוך טקסט עברי נשארים קריאים ולא מתהפכים.
- קו המסגרת `│` של טקסט שהועתק מתוך מסגרת בטרמינל מוסר.
- מגבלה: פסקה שנשברה בטרמינל לכמה שורות מסך מועתקת כשורה אחת, כשכל שורת מסך הפוכה בנפרד ואין שום סימן היכן שורה אחת נגמרת. מהטקסט עצמו אי אפשר לדעת היכן לחלק אותה, ולכן חלקי פסקה כזו יוצאים בסדר שגוי. כדי להעתיק תשובה ארוכה מ-Claude Code, השתמשו במקום זה בפקודה `/copy`, שמעתיקה את הטקסט המקורי.

### תרגום — `CapsLock+T`

מתרגם את הבחירה אוטומטית:
- אם היא מכילה עברית → תתורגם לאנגלית.
- אחרת → תתורגם לעברית.

הטקסט המתורגם מחליף את הבחירה, בדיוק כמו בקיצורים האחרים. ראו [הגדרת תרגום אוטומטי](#הגדרת-תרגום-אוטומטי-capslockt) למטה כדי להבין איך התרגום עובד וכיצד לקבל ממנו את התוצאות הטובות ביותר.

## הגדרת תרגום אוטומטי (CapsLock+T)

`CapsLock+T` מנסה עד שלושה שירותי תרגום, לפי סדר, ועובר אוטומטית לשירות הבא אם שירות מסוים לא זמין, המכסה שלו נגמרה, או שהוא מחזיר שגיאה:

1. **DeepL API Free** — איכות התרגום הגבוהה ביותר. משמש ראשון, אם הגדרתם מפתח API חינמי (ראו למטה).
2. **Google Translate** — חינמי, לא דורש מפתח. משמש אוטומטית בכל פעם ש-DeepL לא מוגדר או שהמכסה שלו נגמרה.
3. **MyMemory** — חינמי, לא דורש מפתח (אימייל אופציונלי מעלה את המכסה היומית). משמש כמוצא אחרון אם שני השירותים הקודמים נכשלים.

אם כל השלושה נכשלים (למשל אין חיבור לאינטרנט), תופיע הודעת "Translation failed" והטקסט המקורי נשאר ללא שינוי.

### קבלת מפתח API חינמי מ-DeepL (אופציונלי, מומלץ)

1. הירשמו לחשבון חינמי בכתובת [deepl.com/pro-api](https://www.deepl.com/pro-api) (לא נדרש כרטיס אשראי).
2. צרו מפתח API מעמוד החשבון שלכם ב-DeepL. מפתחות של התוכנית החינמית תמיד מסתיימים ב-`:fx`.
3. התוכנית החינמית כוללת **500,000 תווים בחודש** ללא עלות. לאחר שהמכסה החודשית מתמלאת, DeepL מדולג אוטומטית והכלי עובר ל-Google Translate / MyMemory עד לאיפוס המכסה.

### הגדרת קובץ ה-`.env`

1. העתיקו את [`.env.example`](./.env.example) לקובץ חדש בשם `.env`, באותה תיקייה שבה נמצא `hebrew_fix.ahk`.
2. פתחו את `.env` בעורך טקסט ומלאו:
   - `DEEPL_API_KEY` — מפתח ה-API החינמי שלכם מ-DeepL (השאירו ריק כדי לדלג על DeepL ולהתחיל מ-Google Translate).
   - `MYMEMORY_EMAIL` — אופציונלי; האימייל שלכם, כדי להעלות את המכסה היומית החינמית של MyMemory מ-5,000 ל-50,000 תווים.
3. שמרו את הקובץ. `.env` רשום ב-`.gitignore` ואף פעם לא נשלח ל-Git — המפתחות שלכם נשארים פרטיים על המחשב שלכם בלבד.

## הפעלה אוטומטית עם עליית המחשב

כדי שהכלי ירוץ אוטומטית בכל הפעלה של המחשב:

1. לחצו `Win + R`, הקלידו `shell:startup` ולחצו Enter.
2. בתיקייה שנפתחה, הוציאו משם כל עותק ישן של `hebrew_fix.ahk`.
3. בתיקיית הפרויקט, לחצו קליק ימני על `hebrew_fix.ahk` ← **Show more options** ← **Create shortcut**, והעבירו את קיצור הדרך שנוצר לתיקיית ה-Startup.

השתמשו ב**קיצור דרך ולא בעותק**: עותק לא מקבל עדכונים, והוא גם לא ימצא את קובץ ה-`.env` (הסקריפט מחפש אותו בתיקייה שבה הוא נמצא), ולכן התרגום יעבור לשירותים החינמיים. בנוסף, שני עותקים בנתיבים שונים רצים במקביל, והקיצורים שלהם מתנגשים.

## שינוי קיצורי המקלדת

אם קיצור מתנגש עם קיצור אחר שאתם משתמשים בו, פתחו את `hebrew_fix.ahk` בעורך טקסט ושנו את השורה שלו:

```autohotkey
CapsLock & h::   ; CapsLock+H — תיקון פריסת מקלדת
CapsLock & j::   ; CapsLock+J — שחזור טקסט הפוך
CapsLock & t::   ; CapsLock+T — תרגום
```

כדי להשתמש באות אחרת עם `CapsLock`, שנו את האות שאחרי `&`. כדי להשתמש במקשי עזר רגילים במקום, כתבו אותם במקום `CapsLock &`: ‏`^` = Ctrl, ‏`!` = Alt, ‏`+` = Shift, ‏`#` = Win. לדוגמה, כדי לחזור ל-`Ctrl+Alt+H`, שנו את `CapsLock & h::` ל-`^!h::`. אם אף קיצור כבר לא משתמש ב-`CapsLock`, מחקו גם את השורה `CapsLock::` שמעליהם. שמרו, ואז לחצו שוב לחיצה כפולה על הקובץ כדי לטעון אותו מחדש.

AutoHotkey לא מתריע אם תוכנה אחרת כבר משתמשת באותו קיצור; הקיצור של התוכנה האחרת פשוט מפסיק לעבוד. נסו צירוף חדש בתוכנות שאתם עובדים איתן לפני שאתם מגדירים אותו.

## איך זה עובד (טכני)

כל קיצור:
1. שומר את תוכן הקליפבורד הנוכחי שלכם (כדי לא לאבד אותו).
2. מעתיק את הטקסט המסומן (`Ctrl+C`).
3. ממיר אותו:
   - `CapsLock+H` ממפה כל מקש לפריסה השנייה, לפי טבלה שתואמת לפריסה הישראלית הסטנדרטית.
   - `CapsLock+J` מטפל בכל שורה בנפרד. הוא מזהה אילו חלקים בשורה התהפכו (עברית) ואילו נשארו קריאים (אנגלית, מספרים), לפי אותם כללי כיווניות של Unicode שבהם הטרמינל השתמש כדי להציג אותה, ומבטל את ההיפוך.
   - `CapsLock+T` שולח את הטקסט לשירות התרגום הראשון שעונה.
4. מדביק את התוצאה במקום הבחירה המקורית (`Ctrl+V`).
5. משחזר את תוכן הקליפבורד המקורי שלכם.

H ו-J קורים תוך שבריר שנייה. T לוקח כמה שלוקח לשירות התרגום.

## מגבלות ידועות

- עובד רק על **טקסט אחיד** (כולו עברית שגויה, או כולו אנגלית שגויה). אם הבחירה כוללת גם טקסט תקין מהשפה השנייה, הוא עלול "להתקלקל" גם כן, כי הכלי לא יודע להבחין בין טעות אמיתית לטקסט תקין.
- תומך בפריסת המקלדת הישראלית הסטנדרטית בלבד (לא בפריסות אחרות כמו פריסה פונטית).
- נבדק על Windows בלבד.
- `CapsLock+T` תלוי בחיבור לאינטרנט, וכברירת מחדל עשוי ליפול חזרה לנקודות הקצה הלא-רשמיות והחינמיות של Google Translate או MyMemory, שעלולות להיות מוגבלות בקצב או חסומות ללא התראה. לתרגום אמין יותר, מומלץ להגדיר מפתח API חינמי של DeepL.
- `CapsLock+J` לא יכול לשחזר פסקה שנשברה בטרמינל לכמה שורות מסך (ראו למעלה). הוא גם לא יכול להבחין בין שורה עברית שמסתיימת במילה באנגלית בלי סימן פיסוק בסוף, לבין שורה שמתחילה באותה מילה, כי שתיהן מועתקות באותה צורה. במקרה כזה הוא מניח את האפשרות השנייה.

## מצב הפרויקט

הפרויקט הושלם בשלב זה: שלושת הקיצורים עובדים ונבדקו בשימוש יומיומי.

מה נבנה:
1. `CapsLock+H`: תיקון פריסת מקלדת (הכלי המקורי).
2. `CapsLock+J`: בהתחלה היפוך תווים פשוט, ואחר כך נכתב מחדש כדי לעבוד שורה אחר שורה ולשמור על אנגלית, מספרים ותבליטים קריאים בתוך עברית.
3. `CapsLock+T`: תרגום עם מעבר אוטומטי DeepL ← Google ← MyMemory, כשהמפתחות שמורים בקובץ `.env` פרטי.
4. תיקונים: עברית בתשובות התרגום כבר לא יוצאת משובשת, ערכים עם מירכאות ב-`.env` מתקבלים, ו-Google Translate עובד דרך כתובת שלא מחזירה שגיאת "יותר מדי בקשות" (429).
5. הקיצורים עברו מ-`Ctrl+Alt` ל-`CapsLock`, כך שלא צריך ללחוץ על `Alt`.

אפשר לשפר בעתיד:
- המגבלות של `CapsLock+J` ו-`CapsLock+H` שמפורטות למעלה.
- אין עדיין בדיקות אוטומטיות בריפו. הלוגיקה של `CapsLock+J` נבדקה עם סקריפט נפרד.

## רישיון

חופשי לשימוש, שינוי והפצה.
