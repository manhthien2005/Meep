# /deploy — Deploy Workflow

> "Pre-deploy verification > rollback firefighting."

## Pre-flight

1. **Branch must be `deploy`** (production) or `develop` (staging). DON'T deploy from a feature branch.
2. Working tree clean: `git status --short` empty.
3. Up-to-date: `git pull origin deploy` (or `develop` for staging).

## Pre-deploy checklist

### Universal
- [ ] All tests pass:
  ```bash
  flutter test
  npm test --prefix firebase/functions
  ```
- [ ] Lint clean:
  ```bash
  flutter analyze
  npm run lint --prefix firebase/functions
  ```
- [ ] No debug logs left (`console.log` / `print(` in lib/ and functions/src/).
- [ ] No TODO without linked issue.
- [ ] Version bump correct (if release): `pubspec.yaml` `version: x.y.z+build`.

### Security
- [ ] No hardcoded secrets (`api[_-]?key|secret|password|token` in lib/ and functions/src/).
- [ ] `.env*` not staged: `git ls-files | grep -E "\.env($|\.)"`  → expect empty.
- [ ] Service account JSON, keystore not staged.

## Path A: Flutter mobile app (Android)

```bash
flutter build appbundle --release   # Play Store
# or
flutter build apk --release         # APK
```

Verify:
- [ ] Exit 0.
- [ ] Smoke test: login, post, feed, push notification.

Upload: Internal testing track on Play Console before production.

**iOS — DEFERRED per ADR-0002.** Skip for MVP.

## Path B: Firebase Cloud Functions

```bash
cd firebase/functions
npm install && npm run build && npm test
```

Pre-deploy:
- [ ] TypeScript compiles clean (`npm run build` exit 0).
- [ ] Region `asia-southeast1` in code.
- [ ] Secrets exist: `gcloud secrets list --project=meep-prod`

```bash
# Deploy staging first
firebase deploy --only functions --project meep-staging
```

Verify staging:
- [ ] Deploy log: no errors.
- [ ] Smoke test: trigger a real function from staging app.

```bash
# Deploy production — confirm with user first
firebase deploy --only functions --project meep-prod
```

Post-deploy: monitor logs 15-30 minutes.

## Path C: Firestore / Storage rules

⚠️ **Rules deploy = immediate production impact.**

```bash
# Test in emulator first
firebase emulators:exec --only firestore "npm run test:rules"

# Deploy staging
firebase deploy --only firestore:rules,storage --project meep-staging

# Deploy production — confirm with user first
firebase deploy --only firestore:rules,storage --project meep-prod
```

Rollback:
```bash
git revert <bad-sha>
firebase deploy --only firestore:rules,storage --project meep-prod
```

## Path D: Firestore indexes

```bash
firebase deploy --only firestore:indexes --project meep-prod
```

Index build can take minutes to hours. Monitor:
```bash
firebase firestore:indexes --project meep-prod
```

## Post-deploy monitoring (first 24 hours)

- [ ] Crashlytics: no error spike.
- [ ] Firebase Analytics: new feature getting hits?
- [ ] Firestore reads/writes: no abnormal spikes.
- [ ] Function invocations: success rate, p99 latency.

## Rollback plan

```bash
# Functions
git checkout <previous-good-sha> -- firebase/functions
cd firebase/functions && npm install && npm run build
firebase deploy --only functions --project meep-prod
```

## Tag the release (after 24h stable)

```bash
git tag -a v1.2.0 -m "Release: feature X, fix Y"
git push origin v1.2.0
```

## Anti-patterns

| Anti-pattern | Problem |
|---|---|
| Deploy direct to prod, skip staging | Bugs land in users' hands |
| Deploy on Friday afternoon | No one to monitor |
| Skip post-deploy monitoring | Latent bugs go undetected |
| `firebase deploy` without `--project` | Might deploy to wrong project |
