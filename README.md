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

1. Select text in any application (Word, browser, Notepad, desktop WhatsApp, any text field).
2. Press **`Ctrl+Alt+H`**.
3. The selected text is converted automatically:
   - If it contains Hebrew letters → converted to English.
   - If it doesn't contain Hebrew (i.e. "leftover English") → converted to Hebrew.

If no text was selected before pressing the shortcut, a brief "No text selected" message will appear and nothing else happens.

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

1. סמנו טקסט בכל אפליקציה (וורד, דפדפן, פתקים, וואטסאפ דסקטופ, כל תיבת טקסט שהיא).
2. לחצו על **`Ctrl+Alt+H`**.
3. הטקסט המסומן יומר אוטומטית:
   - אם הוא מכיל אותיות עבריות → יומר לאנגלית.
   - אם הוא לא מכיל עברית (כלומר "אנגלית מיותרת") → יומר לעברית.

אם לא סימנתם טקסט לפני הלחיצה, תופיע הודעה קצרה "No text selected" ולא יקרה דבר.

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

## רישיון

חופשי לשימוש, שינוי והפצה.
