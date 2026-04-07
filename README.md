# Money Manager

A **Flutter** personal finance app for **Android** and **web**: track income and expenses, follow a **50 / 30 / 20** view, and get plain-language guidance on **how much you can safely spend** on wants—especially before discretionary purchases.

Optional **Firebase** (Auth + Firestore) backs sign-in and cloud data when configured.

---

## Current features

Below is what the app implements today (main user-visible behavior).

### App entry, connectivity, and shell

- **Network gate** — On launch, the app checks connectivity; if there is no usable connection, a **no internet** screen is shown until the network returns, then data loading continues (`connectivity_plus`).
- **Bootstrap loading** — A loading state runs while budget data and session state initialize.
- **Authentication (optional)** — If Firebase is configured and the user has not chosen local-only mode, an **email + password** sign-in / registration screen is shown (branded “Kharcha” on that screen; the app title elsewhere is **Money Manager**).
- **First-time onboarding** — New users without a profile complete a short setup (monthly income, EMI). **Wide layouts** (e.g. web) use a **split view** with a sidebar; narrow layouts use a single scrolling form.
- **Main navigation** — Four tabs: **Home**, **Report**, **Spend**, **Profile** (bottom bar). Some actions jump to another tab (e.g. “View all in Report” from Home).
- **Feedback** — Success and error messages from the budget layer surface as **toasts** (`BudgetMessageToastListener`).

### Home

- **Month context** — Banner showing which calendar month is in scope; figures are **this month only**.
- **This month liquidity** — Card summarizing money in, money out, and net-style breakdown for the current month (`LiquidityBreakdownCard`).
- **Lifetime net** — Single line for **all-time** credits minus debits across every month.
- **50 / 30 / 20** — Visual breakdown of **Needs**, **Wants**, and **Savings** vs targets, with a **baseline mode** you can switch:
  - **Profile salary** — from your saved monthly income,
  - **Month income entries** — sum of income transactions logged this month (default),
  - **Spend pool** — 20% of profile salary (aligned with optional “spend pool” thinking).
- **Recent activity** — Up to **five** recent transactions for the current month.
- **Quick add** — **+** opens a bottom sheet to add a transaction (see **Transactions** below).
- **Deep link to Report** — Button to open the **Report** tab for full history.

### Transactions (add / edit flow)

- Opened from Home **+** (and from Report where applicable).
- **Type** — **Expense** or **Income**.
- **Date** — Transaction date (not only “today”).
- **Expenses** — **Spending kind**: Need, Want, Saving, or Other; **subcategory** lists depend on the kind chosen. **Want**-tagged spending feeds the same **Wants** bucket used on Home and Spend.
- **Income** — **Income category** (e.g. salary, freelance).
- **Payment method** — **Online** vs **cash**.
- **Note** — Optional text.
- Amounts and dates use **Indian Rupees** and **en_IN**-style formatting in the UI.

### Report

- **Period** — View by **single month** (previous/next month; cannot go past the current month) **or** a **custom start–end date range**.
- **Filters** — Narrow by **Needs / Wants / Savings** (for expenses) and by **Income** vs **Expense**; optional **full filter** sheet.
- **List** — Chronological transaction list for the selected period (with empty/loading states).
- **Liquidity-style summary** — Same family of month summary UI as Home where applicable.
- **Export** — **Download as PDF** for the current report selection (`pdf` + `printing`).

### Spend (“Can I spend?”)

- **Monthly Wants summary** — **This month’s Wants budget**, **spent so far** (want-tagged), **remaining**, and a short **status** (on track / low / over / needs baseline).
- **Outing planning** — Optional **how many outings you still plan** this month; **Save** persists it on your profile. Shows **comfortable per outing** and a **safer target**; if you don’t enter a count, the app **paces** against roughly **one slot per week** left in the month.
- **Check a price** — On the **same tab**: enter a rupee amount, optional label, quick category chips, **Check now** — result states such as **safe**, **review** (tight or above comfortable single-outing amount), or **not safe**, with **suggested spend** when relevant and a short breakdown (left before expense, expense, remaining after).

### Profile & account

- **Avatar** — Pick from a grid of preset icons/colors; saves to profile.
- **Account** — Shows **signed-in email** when using Firebase, or a not-signed-in hint.
- **Log out** — Signs out of Firebase (with confirmation where used).
- **Delete account** — Destructive flow with confirmation (re-auth + cloud/local cleanup per implementation).
- **Reference numbers** — Edit **monthly salary** and **EMI / loans**; a read-only line shows **Wants budget from salary (30%)** as a reference. Other profile fields (e.g. rent, bills) exist in the **data model** and onboarding defaults for future use.
- **Save changes** — Persists profile updates.

### Budget logic (what powers “Spend” and Home Wants)

- **Decision engine** — Evaluates hypothetical spends against remaining **Wants** (30% of the active baseline minus **want**-tagged debits this month).
- **Suggested single purchase** — Combines remaining Wants, your **saved outing count**, and **calendar pacing** when the count is not set—see `DecisionEngine` / `BudgetViewModel` for details.

### Cloud (when Firebase is configured)

- **Firebase Auth** — Email/password.
- **Cloud Firestore** — Sync for profile/transactions per your rules (`firestore.rules`).
- Config is supplied through **`lib/core/config/app_env.dart`** (`AppEnv`), not only `.env` files.

---

## Tech stack

| Layer | Choice |
|--------|--------|
| **Framework** | Flutter (Material 3, dark theme by default) |
| **Language** | Dart 3 (`sdk: ^3.10` in `pubspec.yaml`) |
| **State** | `provider` + `ChangeNotifier` (`BudgetViewModel`) |
| **Local** | `shared_preferences` for session/auth mode and lightweight local needs |
| **Cloud (optional)** | `firebase_core`, `firebase_auth`, `cloud_firestore` |
| **Other** | `intl` (₹ / dates), `google_fonts`, `uuid`, `pdf` / `printing`, `connectivity_plus` |

---

## Project structure

```text
lib/
  app.dart                    # MaterialApp, Provider tree, connectivity gate
  main.dart                   # Entry, date formatting (en_IN)
  core/
    config/                   # App branding, environment / Firebase config (see below)
    theme/, layout/, widgets/  # Shared UI and shell helpers
  features/budget/
    data/                     # Repository, local datasource, Firebase sync
    domain/                   # Models, decision engine, expense decisions
    presentation/             # Screens, widgets, view models
```

Firebase options are wired in code via **`lib/core/config/app_env.dart`** (`AppEnv`). Adjust keys there for your own Firebase project (or keep defaults only for local development—use your own project in production).

---

## Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) (stable), matching the SDK constraint in `pubspec.yaml`
- For Android: Android SDK / emulator or device
- For web: Chrome (or another supported browser)

---

## Quick start

```bash
git clone <repository-url>
cd Money-Manager
flutter pub get
flutter run -d chrome          # web
flutter run -d android         # Android
```

### Firebase (optional)

1. Create a Firebase project and enable **Authentication → Email/Password** (and any providers you need).
2. Create **Cloud Firestore** and deploy security rules (see `firestore.rules` in this repo).
3. Put your web/Android app credentials into **`lib/core/config/app_env.dart`** so `AppEnv.isFirebaseConfigured` is true, or replace values with your project’s keys.

Without valid Firebase config, sign-in and cloud sync paths stay disabled; the UI still loads for local exploration depending on implementation.

### Analysis & tests

```bash
dart analyze lib
flutter test
```

### Release APK

```bash
flutter build apk --release
```

---

## Deploying the web build (e.g. Vercel)

The repo includes **`vercel.json`** and **`build.sh`** for static hosting of `build/web`.

- **Build command:** `bash build.sh` (installs a shallow Flutter stable SDK under `.flutter_sdk/` if needed, then `flutter build web --release`).
- **Output directory:** `build/web`
- **`build.sh`** can create a minimal `.env` from Vercel environment variables when deploying (see script comments).

---

## Budget & spend logic (reference)

The **Current features** section above summarizes behavior. Implementation: `lib/features/budget/domain/services/decision_engine.dart` and `lib/features/budget/presentation/viewmodels/budget_view_model.dart`.

---

## License

`publish_to: 'none'` in `pubspec.yaml` — not published to pub.dev. Add a `LICENSE` file if you open-source the project.

---

## Contributing / contact

Use issues and pull requests on your hosting platform; add portfolio or contact links in the repository **About** section as needed.
