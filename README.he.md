# gh dashboard — מדריך בעברית

[English](README.md)

## מה זה?

‏`gh dashboard` הוא תוסף ל-GitHub CLI שמציג בטרמינל את כל ה-Pull Requests הפתוחים של ריפו בטבלה אחת.

הוא מראה יותר ממה שרואים ברשימת ה-PRs באתר של GitHub, ובמבט אחד אפשר לדעת:

- **מי כל אחד מהסוקרים** ומה המצב שלו: אישר, ביקש שינויים, השאיר הערה או עוד לא סקר.
- **מה מצב ה-CI**: עבר, נכשל, רץ או לא מוגדר.
- **כמה אישורים יש** מתוך כמה סוקרים.
- **אפשר למזג או לא**, ואם לא, מה עוצר: טיוטה, קונפליקט, CI שנכשל, בקשת שינויים, חסרה סקירה או חסימה אחרת.

בטרמינל הסטטוסים צבעוניים, ולחיצה על כותרת של PR פותחת אותו בדפדפן.

```
#      PR                                 AUTHOR         REVIEWERS                      CI         APPROVALS   MERGE
───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
#101   Add login page                     alice          —                              ✓ PASS     0/0         ✓ READY
#102   Fix flaky test                     bob            ◷ carol ✓ dave                 ✓ PASS     1/2         ◷ REVIEW
#103   Refactor API client                carol          ✗ alice 💬 bob                 ✓ PASS     0/2         ✗ CHANGES
#105   Rename config keys                 dave           —                              ✗ FAIL     0/0         ✗ CONFLICT
```

## התקנה

צריך את [GitHub CLI](https://cli.github.com) (מחובר לחשבון) ואת [jq](https://jqlang.org).

### Mac

```bash
brew install gh jq
gh auth login
gh extension install BenSagir/gh-dashboard
```

### Windows

ב-PowerShell:

```powershell
winget install Git.Git GitHub.cli jqlang.jq
```

אחרי ההתקנה צריך לסגור ולפתוח מחדש את הטרמינל, ואז:

```powershell
gh auth login
gh extension install BenSagir/gh-dashboard
```

כדאי להשתמש ב-**Windows Terminal** (ברירת המחדל ב-Windows 11). חלון ה-Console הישן לא מציג את הצבעים, הסימנים והקישורים.

### Linux

מתקינים את `gh` ואת `jq` דרך מנהל החבילות, ואז:

```bash
gh auth login
gh extension install BenSagir/gh-dashboard
```

הוראות מלאות (כולל WSL, הסרה ונעילת גרסה) נמצאות ב-[docs/installation.md](docs/installation.md) (באנגלית).

## שימוש

נכנסים לתיקייה של ריפו מ-GitHub ומריצים:

```bash
gh dashboard            # כל ה-PRs הפתוחים
gh dashboard --mine     # רק PRs שאני פתחתי
gh dashboard --review   # רק PRs שמחכים לסקירה שלי
```

עדכון לגרסה החדשה:

```bash
gh extension upgrade dashboard
```

## מה רואים בטבלה

| עמודה | משמעות |
|---|---|
| `#` | מספר ה-PR |
| `PR` | הכותרת (לחיצה פותחת את ה-PR). טיוטה מסומנת ב-`[DRAFT]` |
| `AUTHOR` | מי פתח את ה-PR |
| `REVIEWERS` | כל סוקר והמצב שלו |
| `CI` | התוצאה הכוללת של הבדיקות על ה-commit האחרון |
| `APPROVALS` | כמה אישרו מתוך כמה סוקרים, למשל `1/2` |
| `MERGE` | האם אפשר למזג, ואם לא, למה |

### סימנים

| סימן | צבע | משמעות |
|---|---|---|
| ✓ | ירוק | אושר / עבר / מוכן |
| ◷ | צהוב | ממתין: לסקירה, ל-CI או טיוטה |
| ✗ | אדום | בעיה: בקשת שינויים, CI נכשל או קונפליקט |
| 💬 | כתום | הסוקר השאיר הערות בלי לאשר ובלי לבקש שינויים |
| — | אפור | אין סוקרים / אין CI |

### עמודת MERGE

כשכמה דברים עוצרים את ה-PR, מוצג הראשון ברשימה:

| מוצג | משמעות |
|---|---|
| `DRAFT` | ה-PR הוא טיוטה |
| `CONFLICT` | יש קונפליקט מול ה-branch הראשי |
| `CI FAIL` | הבדיקות נכשלו |
| `CHANGES` | סוקר ביקש שינויים |
| `REVIEW` | חסרה סקירה נדרשת |
| `CI RUN` | הבדיקות עדיין רצות |
| `BLOCKED` | חסום מסיבה אחרת (למשל כללי הגנה על ה-branch) |
| `READY` | אפשר למזג |

## הגדרות

אפשר לשנות דרך משתני סביבה:

| משתנה | ברירת מחדל | משמעות |
|---|---|---|
| `GH_DASHBOARD_LIMIT` | `200` | מספר ה-PRs המקסימלי שמוצג |
| `GH_DASHBOARD_BATCH` | `20` | כמה PRs מושכים בכל בקשה. אם מקבלים שגיאת `504`, מקטינים |
| `NO_COLOR` | | מבטל צבעים וקישורים |
| `CLICOLOR_FORCE` | | שומר על הצבעים גם כשמעבירים את הפלט הלאה (pipe) |

למשל, רק 30 ה-PRs האחרונים (מהיר יותר בריפו גדול):

```bash
GH_DASHBOARD_LIMIT=30 gh dashboard
```

## חשבון עבודה וחשבון פרטי

אם יש לכם שני חשבונות GitHub, מתחברים לשניהם (מריצים `gh auth login` פעמיים).

אין צורך לעבור ביניהם: אם החשבון הפעיל לא רואה את הריפו, הכלי משתמש אוטומטית בחשבון השני שיש לו גישה. החשבון הפעיל שלכם לא משתנה.

## בעיות נפוצות

- ‏**`Not inside a git repository`**: צריך להריץ מתוך תיקייה של ריפו.
- ‏**`Could not open this repository on GitHub`**: אף אחד מהחשבונות המחוברים לא רואה את הריפו. בודקים עם `gh auth status`.
- ‏**`HTTP 504` או `Fetching PRs failed`**: GitHub איטי כרגע. נסו שוב, או הקטינו את גודל הבקשה: `GH_DASHBOARD_BATCH=5 gh dashboard`.
- ‏**PR שנפתח הרגע לא מופיע**: לוקח ל-GitHub עד דקה להוסיף אותו לחיפוש. נסו שוב בעוד רגע.
- ‏**`? UNKNOWN` בעמודת MERGE**: ‏GitHub עוד מחשב אם אפשר למזג. מריצים שוב בעוד כמה שניות.
- **סימנים משובשים ב-Windows**: משתמשים ב-Windows Terminal.

עוד פתרונות: [docs/troubleshooting.md](docs/troubleshooting.md) (באנגלית).
