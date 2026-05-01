# Firebase backend

Hosts the Firestore + Storage security rules, indexes, and Cloud Functions for Meep.

## First-run setup

```bash
# 1. Install Firebase CLI (one-time)
npm install -g firebase-tools

# 2. Log in
firebase login

# 3. Copy the project alias template and fill in your project IDs
cp .firebaserc.example .firebaserc
# Edit .firebaserc with your actual <project-id> values

# 4. Install function deps
cd functions
npm install
cd ..

# 5. Run the emulator suite locally (Auth + Firestore + Storage + Functions)
firebase emulators:start
```

## Layout

```
firebase/
├── firebase.json              # CLI config (which files to deploy, emulator ports)
├── .firebaserc.example        # Project alias template (do NOT commit .firebaserc)
├── firestore.rules            # Firestore security rules
├── firestore.indexes.json     # Compound query indexes
├── storage.rules              # Cloud Storage security rules
└── functions/                 # Cloud Functions (Node 20 + TypeScript)
    ├── package.json
    ├── tsconfig.json
    ├── eslint.config.mjs
    ├── vitest.config.ts
    └── src/
        ├── index.ts           # Entry point — exports all functions
        └── index.test.ts      # Smoke test
```

## Common commands

```bash
# Deploy rules + indexes only
firebase deploy --only firestore:rules,firestore:indexes,storage --project <alias>

# Deploy functions only
firebase deploy --only functions --project <alias>

# Test rules in the emulator
firebase emulators:exec --only firestore "cd functions && npm run test:rules"

# Tail production function logs
firebase functions:log --project prod --limit 50
```

## Conventions

- See `.windsurf/rules/22-functions-rules.md` for TypeScript / Cloud Functions conventions.
- See `.windsurf/rules/23-firestore-rules.md` for rules / indexes conventions.
- See `.windsurf/rules/40-security-guardrails.md` for the security policy this code enforces.
- Default deploy region: `asia-southeast1` (lower latency for VN users).
