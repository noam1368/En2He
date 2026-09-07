# Hebrew Fix

A lightweight Windows tool that converts selected text typed in the wrong keyboard layout — whether you typed Hebrew while your keyboard was set to English (`akuo hjuo` → `שלום רב`), or the reverse. The conversion direction is detected automatically, triggered by a single keyboard shortcut, and works in any application on your computer.

Based on the standard Israeli keyboard layout (SI 1452).

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

Select text in any application (Word, browser, Notepad, desktop WhatsApp, any text field), then press one of the shortcuts below. If no text was selected, a brief "No text selected" message appears and nothing else happens.

### Fix keyboard layout — `Ctrl+Alt+H`

The selected text is converted automatically:
- If it contains Hebrew letters → converted to English.
- If it doesn't contain Hebrew (i.e. "leftover English") → converted to Hebrew.

### Reverse character order — `Ctrl+Alt+J`

Reverses the character order of the selection — useful for text that displays back-to-front due to an RTL/LTR display bug.

### Translate — `Ctrl+Alt+T`

Translates the selection automatically:
- If it contains Hebrew → translated to English.
- Otherwise → translated to Hebrew.

The translated text replaces the selection, just like the other shortcuts. See [Setting up automatic translation](#setting-up-automatic-translation-ctrlaltt) below for how the translation itself works and how to get the best results out of it.

## Setting up automatic translation (Ctrl+Alt+T)

`Ctrl+Alt+T` tries up to three translation services, in order, and automatically falls back to the next one if a service is unavailable, out of quota, or returns an error:

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
2. Copy `hebrew_fix.ahk` (or a shortcut to it) into the folder that opens.

## Changing the keyboard shortcut

The default shortcut is `Ctrl+Alt+H`. If it conflicts with another shortcut you use, you can easily change it: open `hebrew_fix.ahk` in a text editor and find the line

```autohotkey
^!h::
```

`^` = Ctrl, `!` = Alt, `+` = Shift. For example, to switch to `Ctrl+Shift+H`, change the line to `^+h::`.

## How it works

The script:
1. Saves your current clipboard content (so it isn't lost).
2. Copies the selected text (`Ctrl+C`).
3. Checks whether the text contains Hebrew letters, and converts it using a key-mapping table that matches the standard Israeli layout.
4. Pastes the converted text over the original selection (`Ctrl+V`).
5. Restores your original clipboard content.

All of this happens in a fraction of a second.

## Known limitations

- Only works well on **uniform text** (entirely mistyped Hebrew, or entirely mistyped English). If the selection mixes in valid text from the other language, that part may get "corrupted" too, since the tool can't distinguish a real typo from correct text.
- Supports the standard Israeli keyboard layout only (not alternative layouts such as the phonetic one).
- Tested on Windows only.
- `Ctrl+Alt+T` depends on an internet connection, and by default may fall back to Google Translate's or MyMemory's unofficial/free endpoints, which can be rate-limited or blocked without notice. For more reliable translations, set up a free DeepL API key.

## License

Free to use, modify, and distribute.

---

# Hebrew Fix (עברית)

תוסף קטן ל-Windows שממיר טקסט מסומן שהוקלד בטעות בפריסת מקלדת לא נכונה — בין אם הקלדת עברית כשהמקלדת הייתה על אנגלית (`akuo hjuo` → `שלום רב`), או להפך (עברית כשהתכוונת לאנגלית). ההמרה מתבצעת אוטומטית לפי כיוון הטקסט, בלחיצת קיצור מקלדת אחת, בכל אפליקציה במחשב.

מבוסס על פריסת המקלדת הישראלית הסטנדרטית (SI 1452).

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

סמנו טקסט בכל אפליקציה (וורד, דפדפן, פתקים, וואטסאפ דסקטופ, כל תיבת טקסט שהיא), ואז לחצו על אחד הקיצורים למטה. אם לא סימנתם טקסט, תופיע הודעה קצרה "No text selected" ולא יקרה דבר.

### תיקון פריסת מקלדת — `Ctrl+Alt+H`

הטקסט המסומן יומר אוטומטית:
- אם הוא מכיל אותיות עבריות → יומר לאנגלית.
- אם הוא לא מכיל עברית (כלומר "אנגלית מיותרת") → יומר לעברית.

### היפוך סדר תווים — `Ctrl+Alt+J`

הופך את סדר התווים בבחירה — שימושי לטקסט שמוצג הפוך עקב תקלת תצוגה RTL/LTR.

### תרגום — `Ctrl+Alt+T`

מתרגם את הבחירה אוטומטית:
- אם היא מכילה עברית → תתורגם לאנגלית.
- אחרת → תתורגם לעברית.

הטקסט המתורגם מחליף את הבחירה, בדיוק כמו בקיצורים האחרים. ראו [הגדרת תרגום אוטומטי](#הגדרת-תרגום-אוטומטי-ctrlaltt) למטה כדי להבין איך התרגום עובד וכיצד לקבל ממנו את התוצאות הטובות ביותר.

## הגדרת תרגום אוטומטי (Ctrl+Alt+T)

`Ctrl+Alt+T` מנסה עד שלושה שירותי תרגום, לפי סדר, ועובר אוטומטית לשירות הבא אם שירות מסוים לא זמין, המכסה שלו נגמרה, או שהוא מחזיר שגיאה:

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
2. העתיקו את קובץ `hebrew_fix.ahk` (או קיצור דרך אליו) לתוך התיקייה שנפתחה.

## שינוי קיצור המקלדת

הקיצור המוגדר כברירת מחדל הוא `Ctrl+Alt+H`. אם הוא מתנגש עם קיצור אחר שאתם משתמשים בו, אפשר לשנות אותו בקלות: פתחו את `hebrew_fix.ahk` בעורך טקסט וחפשו את השורה

```autohotkey
^!h::
```

`^` = Ctrl, `!` = Alt, `+` = Shift. לדוגמה, כדי לעבור ל-`Ctrl+Shift+H` שנו את השורה ל-`^+h::`.

## איך זה עובד (טכני)

הסקריפט:
1. שומר את תוכן הקליפבורד הנוכחי שלכם (כדי לא לאבד אותו).
2. מעתיק את הטקסט המסומן (`Ctrl+C`).
3. בודק אם הטקסט מכיל אותיות עבריות, וממיר אותו לפי טבלת מיפוי מקשים תואמת לפריסה הישראלית הסטנדרטית.
4. מדביק את הטקסט המומר במקום המקורי (`Ctrl+V`).
5. משחזר את תוכן הקליפבורד המקורי שלכם.

כל זה קורה תוך שבריר שנייה.

## מגבלות ידועות

- עובד רק על **טקסט אחיד** (כולו עברית שגויה, או כולו אנגלית שגויה). אם הבחירה כוללת גם טקסט תקין מהשפה השנייה, הוא עלול "להתקלקל" גם כן, כי הכלי לא יודע להבחין בין טעות אמיתית לטקסט תקין.
- תומך בפריסת המקלדת הישראלית הסטנדרטית בלבד (לא בפריסות אחרות כמו פריסה פונטית).
- נבדק על Windows בלבד.
- `Ctrl+Alt+T` תלוי בחיבור לאינטרנט, וכברירת מחדל עשוי ליפול חזרה לנקודות הקצה הלא-רשמיות והחינמיות של Google Translate או MyMemory, שעלולות להיות מוגבלות בקצב או חסומות ללא התראה. לתרגום אמין יותר, מומלץ להגדיר מפתח API חינמי של DeepL.

## רישיון

חופשי לשימוש, שינוי והפצה.
