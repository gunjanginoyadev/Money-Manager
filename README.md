# Money Manager

**Money Manager** is a cross-platform **Flutter** app (Android & web) for personal budgeting: track income and spending, see safe-to-spend at a glance, and get clear guidance before discretionary purchases.

It is built as a **local-first** experience with **optional Firebase** (Firestore + Auth) for sync and backup when configured.

---

## At a glance (for recruiters)

| Area | Details |
|------|---------|
| **Platform** | Flutter 3.x · Dart 3.x · Material 3 dark UI |
| **State** | `provider` · `ChangeNotifier` view models |
| **Persistence** | `shared_preferences` (JSON) · optional Firestore sync |
| **Backend** | Firebase Auth (email/password) · Cloud Firestore · security rules in-repo |
| **Notable libs** | `intl`, `google_fonts`, `uuid`, `pdf` / `printing` (reports) |

The codebase is organized by **feature** (`lib/features/budget/`) with separation between **presentation**, **domain** models, and **data** (local + remote).

---

## What it does

- **Onboarding & profile** — Monthly income, fixed costs (EMI, rent, bills), essentials, safety buffer; editable profile with avatar options.
- **Home** — Net balance, month income/expense summary, **50 / 30 / 20** breakdown vs targets, recent transactions, quick add.
- **Report** — Filterable activity by month or custom range, categories, **PDF export**.
- **Spend (Plan)** — “Can I spend?” hero, obligations snapshot, afford-a-purchase flow, monthly outlook; **effective income** respects profile + tracked credits, spending reduces availability.
- **Transactions** — Debits/credits, categories, spending kinds (needs/wants/savings), payment method, optional sync to Firestore.
- **Account** — Email sign-in, optional cloud restore, **log out**, **delete account** (re-authenticates then removes Firestore data + Auth user + local storage).

Offline usage works without Firebase; cloud features activate when `.env` is filled and rules are deployed.

---

## Tech stack

- **Flutter** — UI, routing, responsive layouts (e.g. shell + bottom navigation).
- **Provider** — App-wide `BudgetViewModel` + repository injection.
- **SharedPreferences** — Profile, expenses, transactions, auth mode.
- **Firebase** (optional) — `firebase_core`, `cloud_firestore`, `firebase_auth`; init via `flutter_dotenv` + `FirebaseOptions` (no `google-services.json` required for the current Dart init path).
- **Other** — `intl` (currency / dates), `google_fonts`, `pdf` + `printing` for exports.

---

## Project layout (high level)

```text
lib/
  app.dart                 # MaterialApp, providers
  core/                    # Theme, layout, toasts, PDF helpers, config
  features/budget/
    data/                  # Local datasource, repository, Firebase sync
    domain/                # Models, decision engine (safe / okay / not safe)
    presentation/          # Screens, widgets, view models
```

---

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable), Dart SDK as pinned in `pubspec.yaml`
- For Android: Android Studio / SDK; for web: Chrome

---

## Quick start

```bash
git clone <your-fork-or-repo-url>
cd money_manager
flutter pub get
```

### Environment (optional Firebase)

1. Copy `.env.example` to `.env`.
2. Add your Firebase web app keys from the Firebase console (Project settings → Your apps).

```env
FIREBASE_API_KEY=
FIREBASE_APP_ID=
FIREBASE_MESSAGING_SENDER_ID=
FIREBASE_PROJECT_ID=
FIREBASE_AUTH_DOMAIN=
FIREBASE_STORAGE_BUCKET=
FIREBASE_MEASUREMENT_ID=
```

3. Enable **Authentication → Email/Password** (and any providers you use).
4. Create **Cloud Firestore** and deploy rules from `firestore.rules`.

Without a valid `.env`, the app still runs in **local-only** mode.

### Run

```bash
# Web
flutter run -d chrome

# Android (device or emulator)
flutter run -d android
```

### Tests & analysis

```bash
flutter test
dart analyze lib
```

### Release APK

```bash
flutter build apk --release
```

---

## Deploy on Vercel

The repo includes **`vercel.json`** and **`build.sh`** so you can host the Flutter **web** build as static files.

1. Import the Git repo in [Vercel](https://vercel.com) (or use the CLI).
2. **Framework preset**: Other (or leave auto-detect off).
3. **Build command**: `bash build.sh` (already set in `vercel.json`).
4. **Output directory**: `build/web` (already set in `vercel.json`).
5. **Install command**: leave empty (no `package.json`); Flutter is installed inside `build.sh` via a shallow `stable` SDK clone into `.flutter_sdk/` (gitignored).

`build.sh` ensures a **`.env` file exists** (required by `pubspec.yaml` assets). If you add Firebase variables in **Vercel → Project → Settings → Environment Variables** using the same names as `.env.example`, the script writes a real `.env` at build time so the web bundle can talk to Firebase.

`vercel.json` **rewrites** unknown paths to `index.html` so Flutter’s client-side routing works after refresh.

**Note:** First builds clone Flutter and can take several minutes. If a build hits the time limit, upgrade the Vercel plan or add a [remote build cache](https://vercel.com/docs/deployments/troubleshoot-a-build) strategy for `.flutter_sdk` (advanced).

---

## Budget decision logic (summary)

Disposable headroom is derived from **effective monthly income** (profile baseline vs tracked credits, without double-counting salary), minus **obligations**, minus **spending already recorded this month**, then compared to the **safety buffer** for SAFE / OKAY / NOT SAFE outcomes. See `DecisionEngine` and `BudgetViewModel` in `lib/features/budget/`.

---

## Firebase & cost notes

- Uses **Firestore** and **Firebase Auth** only (no Cloud Functions required for core flows).
- Fits typical **Spark (free)** usage for personal / demo workloads; monitor quotas in production.

---

## License

This repository is private / unpublished (`publish_to: 'none'` in `pubspec.yaml`). Add a `LICENSE` file if you open-source the project.

---

## Contact

For collaboration or hiring context, link your portfolio, LinkedIn, or email in your fork’s **About** section or this README as appropriate.
