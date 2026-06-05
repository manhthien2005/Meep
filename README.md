<div align="center">

<img src="apps/mobile/assets/icons/ic_logo_full.svg" width="120" alt="Meep logo" />

# Meep

**A private photo-sharing app for close friends.**
Capture moments. Share with your circle. Glance at them right from your home screen.

<sub><i>The name <b>Meep</b> stands for <b>Memory Keep</b> — because the moments worth sharing are the ones worth keeping.</i></sub>

[![Platform](https://img.shields.io/badge/platform-Android-3DDC84?logo=android&logoColor=white)](https://developer.android.com/)
[![Flutter](https://img.shields.io/badge/Flutter-3.5%2B-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore%20%7C%20FCM-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Node](https://img.shields.io/badge/Node-20-339933?logo=node.js&logoColor=white)](https://nodejs.org)
[![Status](https://img.shields.io/badge/status-Production-success)](#)
[![License](https://img.shields.io/badge/license-Proprietary-blue)](#-license)

</div>

---

## 📑 Table of Contents

- [Overview](#-overview)
- [Highlights](#-highlights)
- [Showcase](#-showcase)
- [Tech Stack](#-tech-stack)
- [Getting Started](#-getting-started)
- [Project Structure](#-project-structure)
- [Documentation](#-documentation)
- [Team](#-team)
- [License](#-license)
- [Acknowledgements](#-acknowledgements)

---

## ✨ Overview

**Meep** is an intimate photo-sharing app designed for the people who actually matter — your closest friends. No public feed, no followers, no algorithmic suggestions. Just a closed circle, a camera, and moments worth keeping.

Its headline feature: a **home-screen widget** on Android that shows your friends' latest photos at a glance — no need to open the app.

> **MVP target: Android only.** iOS is deferred post-MVP per [ADR-0002](docs/adr/0002-android-first-defer-ios.md). The Flutter codebase remains cross-platform-ready — iOS can be added later without a rewrite.

---

## 🎯 Highlights

- 📸 **Capture & Share** — one-tap camera, friends-only delivery.
- 👥 **Closed friend graph** — bidirectional friendships only. No public discovery.
- 🏠 **Home-screen widget** (Android) — your friends' latest moments, always visible.
- 📓 **Diary** — private daily entries with rich formatting and mood backgrounds.
- 🌌 **Space** — shared timelines between close friends.
- 🔔 **Push notifications** — instant FCM delivery when a friend posts.
- 💛 **Streak & Memories** — celebrate the days you keep showing up.
- 🔒 **Privacy by default** — Firestore rules deny everything that isn't explicitly allowed.

---

## 📸 Showcase

> _Screenshots coming soon — designs in progress on Figma. Check back as we ship toward M3._

<!-- TODO(readme): replace với 4 screenshot thật khi designer finalize: Camera | Feed | Home-screen Widget | Diary/Profile -->

<div align="center">
  <table>
    <tr>
      <td align="center"><sub>Camera</sub><br/><em>coming soon</em></td>
      <td align="center"><sub>Feed</sub><br/><em>coming soon</em></td>
      <td align="center"><sub>Widget</sub><br/><em>coming soon</em></td>
      <td align="center"><sub>Diary</sub><br/><em>coming soon</em></td>
    </tr>
  </table>
</div>

---

## 🛠 Tech Stack

<div align="center">

[![Skills](https://skillicons.dev/icons?i=flutter,dart,firebase,ts,nodejs,kotlin,gradle,githubactions,figma,vscode)](https://skillicons.dev)

</div>

| Layer | Technology |
|---|---|
| 📱 **Mobile** | Flutter (stable) · Riverpod 2 · Freezed · json_serializable |
| ☁️ **Backend** | Firebase — Auth, Firestore, Cloud Storage, Cloud Functions, FCM |
| ⚙️ **Functions runtime** | Node 20 · TypeScript (strict) · Vitest |
| 🏠 **Native widget** | Android AppWidget (Kotlin) · _iOS WidgetKit deferred_ |
| 🚀 **CI/CD** | GitHub Actions |
| 📊 **Task tracking** | GitHub Projects v2 + Issues |
| 🎨 **Design** | Figma (design system + theme tokens) |

Architecture decisions: [`docs/adr/`](docs/adr/).

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** ≥ 3.5 ([install](https://docs.flutter.dev/get-started/install))
- **Node.js** 20 ([install](https://nodejs.org/))
- **Firebase CLI** (`npm i -g firebase-tools`)
- **FlutterFire CLI** (`dart pub global activate flutterfire_cli`)
- **Android Studio** + Android SDK (for emulator / device debugging)

### Quick install

```bash
# 1. Clone
git clone https://github.com/manhthien2005/Meep.git
cd Meep

# 2. Root tooling (husky + commitlint)
npm install
git config commit.template .gitmessage

# 3. Flutter app
cd apps/mobile
flutter pub get
flutterfire configure --project=<your-firebase-project-id>
dart run build_runner build --delete-conflicting-outputs
cd ../..

# 4. Cloud Functions
cd firebase/functions && npm install && cd ../..

# 5. Env files
cp .env.example .env
cp firebase/.firebaserc.example firebase/.firebaserc
# → edit cả 2 file với Firebase project ID thật

# 6. Run!
cd apps/mobile && flutter run -d android
```

Setup chi tiết (Firebase project, FCM keys, signing config): [`docs/team-workflow.md §2`](docs/team-workflow.md).

### Run Cloud Functions emulator

```bash
cd firebase && firebase emulators:start
# Emulator UI → http://localhost:4000
```

### Test & lint

```bash
# Flutter
cd apps/mobile
flutter test
flutter test --coverage
flutter analyze
dart format --set-exit-if-changed lib test

# TypeScript / Functions
cd firebase/functions
npm test
npm run lint
npm run typecheck

# Firestore rules
cd firebase && firebase emulators:exec --only firestore "cd functions && npm run test:rules"
```

---

## 📂 Project Structure

```
Meep/
├── apps/
│   ├── mobile/                # Flutter app (primary client)
│   └── widget/                # Native home-screen widget (Android AppWidget)
├── firebase/
│   ├── functions/             # Cloud Functions (TypeScript)
│   ├── firestore.rules        # Security rules
│   ├── firestore.indexes.json
│   └── storage.rules
├── services/
│   └── api/                   # OPTIONAL standalone Node BE (chưa cần)
├── docs/
│   ├── specs/                 # Feature specs (/spec workflow)
│   ├── plans/                 # Implementation plans (/plan workflow)
│   ├── adr/                   # Architectural Decision Records
│   └── team-workflow.md       # ← đọc trước khi commit lần đầu
├── tasks/                     # Short-lived TODO checklists
├── .github/
│   ├── workflows/             # GitHub Actions CI/CD
│   ├── ISSUE_TEMPLATE/        # Issue templates tiếng Việt
│   ├── CODEOWNERS
│   └── pull_request_template.md
├── .husky/                    # Local git hooks
├── AGENTS.md                  # AI agent operating manual
├── CONTEXT.md                 # Domain language reference
├── commitlint.config.js
└── .gitmessage                # Commit message template tiếng Việt
```

---

## 📚 Documentation

| Doc | Mô tả |
|---|---|
| [`docs/team-workflow.md`](docs/team-workflow.md) | Branching, commit convention, PR, CI/CD chi tiết |
| [`docs/adr/`](docs/adr/) | Architectural Decision Records |
| [`docs/specs/`](docs/specs/) | Feature specs |
| [`docs/plans/`](docs/plans/) | Implementation plans |

---

## 👥 Team

<p align="center"><i>— The minds behind Meep —</i></p>

<br/>

<table align="center">
  <tr>
    <td align="center" width="25%">
      <a href="https://github.com/manhthien2005">
        <img src="https://github.com/manhthien2005.png" width="160" height="160" style="border-radius:50%" alt="Phan Điền Mạnh Thiên" />
      </a>
      <br/><br/>
      👑
      <br/>
      <b>Phan Điền Mạnh Thiên</b>
      <br/>
      <a href="https://github.com/manhthien2005"><sub>@manhthien2005</sub></a>
    </td>
    <td align="center" width="25%">
      <a href="https://github.com/katheramp">
        <img src="https://github.com/katheramp.png" width="160" height="160" style="border-radius:50%" alt="Đào Huỳnh Gia Hân" />
      </a>
      <br/><br/>
      💪
      <br/>
      <b>Đào Huỳnh Gia Hân</b>
      <br/>
      <a href="https://github.com/katheramp"><sub>@katheramp</sub></a>
    </td>
    <td align="center" width="25%">
      <a href="https://github.com/CatS1mp">
        <img src="https://github.com/CatS1mp.png" width="160" height="160" style="border-radius:50%" alt="Lê Ngọc Đăng Khoa" />
      </a>
      <br/><br/>
      💪
      <br/>
      <b>Lê Ngọc Đăng Khoa</b>
      <br/>
      <a href="https://github.com/CatS1mp"><sub>@CatS1mp</sub></a>
    </td>
    <td align="center" width="25%">
      <a href="https://github.com/JanaKimmm">
        <img src="https://github.com/JanaKimmm.png" width="160" height="160" style="border-radius:50%" alt="Trần Nguyễn Kim Ngân" />
      </a>
      <br/><br/>
      💪
      <br/>
      <b>Trần Nguyễn Kim Ngân</b>
      <br/>
      <a href="https://github.com/JanaKimmm"><sub>@JanaKimmm</sub></a>
    </td>
  </tr>
</table>

---

## 📄 License

Capstone project — no public license. Reach out to the leader if you want to fork or reuse.

---

## 🙏 Acknowledgements

- Methodology skills (TDD, systematic debugging) — adapted from [obra/superpowers](https://github.com/obra/superpowers).
- Coding guidelines — based on [Andrej Karpathy's coding guidelines](https://karpathy.bearblog.dev/).
- Inspiration — [Locket](https://locket.camera/) for the widget-first close-friends format, and [BeReal](https://bereal.com/) for the no-public-feed ethos.

---

<div align="center">

**Built with ☕, late nights, and love of coding · 2026 · 💙**

</div>
