# Team Workflow — Meep

> **Ai cũng phải đọc file này trước khi viết commit đầu tiên.**
>
> File này là single source of truth cho cách team Meep làm việc với Git, GitHub, CI/CD, và task tracking.

## Mục lục

- [1. Tổng quan](#1-tổng-quan)
- [2. Setup lần đầu sau khi clone](#2-setup-lần-đầu-sau-khi-clone)
- [3. Branching](#3-branching)
- [4. Quy tắc commit](#4-quy-tắc-commit)
- [5. Pull Request](#5-pull-request)
- [6. CI/CD](#6-cicd)
- [7. Task tracking](#7-task-tracking-github-projects)
- [8. Sprint workflow](#8-sprint-workflow)
- [9. Tình huống hay gặp](#9-tình-huống-hay-gặp)
- [10. FAQ](#10-faq)

---

## 1. Tổng quan

| Thứ | Tool / quy ước |
|---|---|
| Source control | Git + GitHub (public repo) |
| Branch chính | `develop` (integration) |
| Branch product | `deploy` (release) |
| Commit format | Conventional Commits + **mô tả tiếng Việt** |
| PR review | ≥ 1 reviewer (anh là default CODEOWNERS) |
| CI | GitHub Actions |
| Local enforcement | husky + commitlint |
| Task tracking | GitHub Projects v2 |
| Task linking | Commit/PR ghi `Refs #N` hoặc `Closes #N` |

## 2. Setup lần đầu sau khi clone

> **Note (anh leader):** `<org>` trong URL dưới là placeholder. Thay bằng GitHub org/user thật khi tạo repo (cũng nhớ cập nhật `README.md` + `.github/ISSUE_TEMPLATE/config.yml`).

```bash
# 1. Clone repo
git clone https://github.com/<org>/meep.git  # TODO(setup): replace <org>
cd meep

# 2. Cài dependencies root (commitlint + husky)
npm install
# → Tự động bind .husky/commit-msg, pre-commit, pre-push

# 3. Cài Flutter app deps
cd apps/mobile
flutter pub get
flutterfire configure --project=<firebase-project-id>
dart run build_runner build --delete-conflicting-outputs
cd ../..

# 4. Cài Functions deps
cd firebase/functions
npm install
cd ../..

# 5. Setup git commit template (tiếng Việt)
git config commit.template .gitmessage

# 6. Setup local env
cp .env.example .env
cp firebase/.firebaserc.example firebase/.firebaserc
# Sửa 2 file trên với project ID thật

# 7. Test setup
git checkout -b chore/<DevName>/test-setup develop
echo "test" > test-setup.txt
git add test-setup.txt
git commit -m "chore: kiểm tra hooks local"
# → Phải PASS lint + commitlint
git rm test-setup.txt
git commit -m "chore: xóa file test"
git checkout develop
git branch -D chore/<DevName>/test-setup
```

**Nếu hook không chạy:** chạy `npx husky` lại trong root repo.

## 3. Branching

### Diagram

```
deploy ─────────●─────────────●─────  PRODUCTION (tag v0.1.0, v0.2.0)
                ↑              ↑      Merge từ develop sau khi QA pass
                │              │
develop ──●──●──●──●──●──●──●──●─────  INTEGRATION (default branch)
          ↑   ↑     ↑        ↑
       PR từ feature branches của các dev
```

### Quy tắc

| Branch | Quy tắc |
|---|---|
| `develop` | Default branch. **Không** push thẳng. Chỉ qua PR. CI chạy trên mọi PR. |
| `deploy` | Production. Chỉ merge từ `develop` qua PR. CI deploy prod (manual approval). |
| `<type>/<DevName>/<desc>` | Feature branch của dev. Tự do push. **Phải checkout từ `develop`**. |

### Format branch name

```
<type>/<DevName>/<short-description>
```

| Phần | Quy tắc | Ví dụ |
|---|---|---|
| `<type>` | lowercase English, từ enum | `feature`, `fix`, `chore`, `refactor`, `docs`, `test`, `style`, `perf`, `build`, `ci`, `revert` |
| `<DevName>` | PascalCase + 3 chữ viết tắt cuối | `ThienPDM`, `KhoaLND`, `HoaiNT` |
| `<short-description>` | lowercase, kebab-case, English | `auth-google-signin`, `feed-empty-state` |

**Ví dụ tốt:**
- `feature/ThienPDM/auth-google-signin`
- `fix/KhoaLND/feed-empty-state`
- `chore/HoaiNT/bump-firebase-deps`
- `refactor/MinhTV/extract-post-mapper`
- `docs/ThienPDM/add-team-workflow`

**Ví dụ xấu (`pre-push` hook + CI sẽ block):**
- `feat/ThienPDM/...` (phải `feature`, không `feat`)
- `feature/thien/...` (DevName phải PascalCase)
- `feature/ThienPDM-auth` (dùng `-` thay `/` giữa DevName và desc)
- `feature/ThienPDM` (thiếu short-desc)
- `Feature/ThienPDM/auth` (type phải lowercase)

### Quy trình tạo feature branch

```bash
# 1. Update develop về mới nhất
git checkout develop
git pull --ff-only

# 2. Tạo feature branch
git checkout -b feature/<DevName>/<desc> develop

# 3. Code → commit → push
# Repeat...
git push -u origin feature/<DevName>/<desc>

# 4. Mở PR vào develop trên GitHub
```

## 4. Quy tắc commit

### Format (Conventional Commits + tiếng Việt)

```
<type>(<scope>): <mô tả ngắn tiếng Việt>

<body tùy chọn — tiếng Việt, giải thích TẠI SAO>

<footer tùy chọn — Refs #N hoặc Closes #N>
```

### Quy tắc subject

- **≤ 72 ký tự**, không dấu chấm cuối.
- **Type:** lowercase English, từ enum (`feat`, `fix`, `chore`, ...).
- **Scope:** lowercase, optional, là module — `auth`, `feed`, `post`, `friend`, `widget`, `deps`...
- **Mô tả:** tiếng Việt, viết thường, hành động cụ thể.

### Quy tắc body

- Tiếng Việt.
- Giải thích **TẠI SAO** thay đổi này (motivation), không phải làm gì (diff đã cho biết).
- Mỗi dòng ≤ 100 ký tự.
- Bullet list được, dùng `-` đầu dòng.

### Quy tắc footer

- `Refs #12` — commit liên quan đến issue #12 nhưng chưa close.
- `Closes #12` — commit này close issue #12 khi merge vào `develop`.
- `BREAKING CHANGE: <mô tả>` — thay đổi không tương thích ngược (hiếm dùng cho MVP).

### Ví dụ tốt

```
feat(auth): thêm đăng nhập Google qua Firebase Auth

Trước đây chỉ có email/password. Giờ user có thể chọn Google trên màn
hình splash để onboard nhanh hơn.

- Bổ sung GoogleSignInButton trên SplashPage
- Wire AuthRepository.signInWithGoogle qua Riverpod provider
- Cập nhật auth_controller xử lý success/failure state
- Thêm widget test cho luồng đăng nhập

Closes #12
```

```
fix(feed): xử lý feed rỗng khi user chưa có bạn

Trước đây feed crash với NPE khi authorIds = []. Giờ trả về list rỗng
và hiển thị empty state với CTA "Mời bạn bè".

Closes #34
```

```
chore(deps): cập nhật firebase_core lên 3.10.0
```

### Ví dụ xấu (commitlint sẽ reject)

| Commit | Vấn đề |
|---|---|
| `Update auth.dart` | Thiếu type, mô tả vague |
| `feat: add google login` | Mô tả English, không tiếng Việt |
| `fix bug` | Vague, thiếu scope, không rõ bug nào |
| `WIP` | Thiếu nội dung |
| `feat(auth): thêm đăng nhập Google qua Firebase Auth.` | Có dấu chấm cuối |
| `Feat(auth): thêm...` | Type phải lowercase |
| `fix(Auth): ...` | Scope phải lowercase |

### Workflow viết commit

**Cách 1 — git commit -m (commit ngắn):**

```bash
git add <files>
git commit -m "fix(feed): xử lý feed rỗng khi chưa có bạn"
```

**Cách 2 — Mở editor với template (commit có body):**

```bash
git config commit.template .gitmessage  # 1 lần sau khi clone
git add <files>
git commit  # → mở editor với template tiếng Việt
```

Editor mở ra với template, em xóa phần hướng dẫn (sau dòng `------`), điền subject + body + footer.

## 5. Pull Request

### Khi nào mở PR

- Code xong feature/fix → push branch → mở PR ngay.
- Nếu còn WIP nhưng cần feedback sớm → mở PR draft (`Draft pull request` trên GitHub).

### PR title

= subject của commit chính, tiếng Việt.

```
feat(auth): thêm đăng nhập Google qua Firebase Auth
```

### PR body

Theo template `.github/pull_request_template.md`. Phần bắt buộc:

- **Mô tả** (2-3 câu)
- **Refs** (`Closes #N` để auto-close issue)
- **Thay đổi chính** (list file/module)
- **Test** (checklist + cách test thủ công)
- **Screenshot/video** (nếu có UI thay đổi)

### Review

- ≥ 1 reviewer approve (anh là default CODEOWNERS).
- CI phải PASS hoàn toàn (commitlint + lint + test).
- Reviewer comment trên dòng cụ thể, dùng "Request changes" nếu blocker.

### Merge

- **Cách merge:** Squash and merge (default) — combine tất cả commit của PR thành 1 commit trên `develop`. Giữ history sạch.
- **Trừ trường hợp:** PR có > 5 commit logic riêng biệt → dùng "Rebase and merge" để giữ từng commit.
- **Không bao giờ:** "Create a merge commit" (gây dirty history).
- Sau merge: GitHub tự delete branch.

## 6. CI/CD

### `pr-check.yml` — chạy trên mọi PR vào `develop`/`deploy`

| Job | Kiểm tra | Block merge nếu fail? |
|---|---|---|
| `validate-branch-name` | Format `<type>/<DevName>/<desc>` | ✅ |
| `validate-commits` | Commitlint trên tất cả commit của PR | ✅ |
| `flutter` | `pub get` + format + analyze + test + coverage | ✅ |
| `functions` | `npm ci` + lint + typecheck + test | ✅ |
| `firestore-rules` | Rules tests qua emulator | ⚠️ (warn, chưa block đến khi có rules tests đầu tiên) |

### `develop-staging.yml` — push vào `develop`

- Build APK debug → upload artifact (team tải về test).
- Deploy Functions + rules lên `meep-staging` (chưa kích hoạt — cần GitHub Secrets).

### `deploy-production.yml` — push vào `deploy`

- **Manual approval gate** (anh approve qua GitHub Environments → "production").
- Build APK + AAB release (signed).
- Deploy Functions + rules lên `meep-prod`.
- Tag git release `v0.X.Y`.
- Generate changelog từ Conventional Commits.

### Secrets cần fill (khi sẵn sàng deploy)

GitHub repo → Settings → Secrets and variables → Actions:

**Cho staging:**
- `FIREBASE_PROJECT_STAGING` — vd `meep-dev-abc123`
- `FIREBASE_SERVICE_ACCOUNT_STAGING` — JSON service account key

**Cho production (Phase 2):**
- `FIREBASE_PROJECT_PROD` — vd `meep-prod-xyz456`
- `FIREBASE_SERVICE_ACCOUNT_PROD` — JSON key
- `ANDROID_KEYSTORE_BASE64` — keystore release encode base64
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

Anh hỏi em khi tới lúc setup, em hướng dẫn chi tiết.

## 7. Task tracking — GitHub Projects

### Setup (anh làm 1 lần)

1. GitHub repo → tab `Projects` → New project → Board template.
2. Đổi tên project: `Meep MVP`.
3. Custom fields:
   - `Status`: Backlog / In Progress / Review / Done (single-select)
   - `Sprint`: Sprint 1 / Sprint 2 / Sprint 3 (single-select)
   - `Type`: feature / fix / chore / refactor / docs / test (single-select)
   - `Module`: auth / feed / post / friend / camera / diary / space / rollcall / profile / widget / notification / reaction / core / functions (single-select) — xem §8.4
   - `Assignee`: link với GitHub user (= module owner)
   - `Effort`: XS / S / M / L (single-select) — task > L phải break nhỏ hơn
4. Auto-add: mọi issue mới + PR mới của repo → tự thêm vào board.

### Workflow

```
Issue mới (Backlog)
    ↓
Dev pick task → assign mình → move sang "In Progress"
    ↓
Code → commit có "Refs #N"
    ↓
Mở PR có "Closes #N" → move card sang "Review"
    ↓
PR merge → issue auto-close → card auto-move sang "Done"
```

### Format issue

Dùng template phù hợp với loại issue:

- **`.github/ISSUE_TEMPLATE/task.md`** — task execution unit trong sprint (đã được break-down từ feature/spec). Đây là template dùng nhiều nhất.
- **`.github/ISSUE_TEMPLATE/feature.md`** — yêu cầu tính năng mới (chưa break-down, cần spec).
- **`.github/ISSUE_TEMPLATE/bug.md`** — báo cáo bug.

Issue title cũng theo Conventional Commits format: `feat(auth): tạo màn hình đăng nhập Google` — để consistency với commit/PR.

## 8. Sprint workflow

> **Rationale + decisions đầy đủ:** xem [`docs/adr/0003-task-management-process.md`](adr/0003-task-management-process.md). Section này tóm tắt operational.

### 8.1 Cadence

| Mốc | Cadence |
|---|---|
| Project window | 30/4/2026 → 9/6/2026 (6 tuần) |
| Sprint length | 2 tuần |
| Number of sprints | 3 (Sprint 1, 2, 3) |
| Milestones | 3, mỗi milestone = 1 sprint cuối |
| Sprint planning | Thứ 2 sáng tuần 1 (1-2h, async OK) |
| Sprint review + retro | Thứ 6 chiều tuần 2 (sync 30-60ph) |
| Daily check-in | Async (xem §8.7) |

**Milestone scope đề xuất:**

| Milestone | Window | Scope |
|---|---|---|
| M1 | 30/4 → 13/5 | Setup CI/Firebase + Auth (email + Google) + skeleton features folder |
| M2 | 14/5 → 27/5 | Friend graph + Post photo + Friend feed |
| M3 | 28/5 → 9/6 | FCM notification + Android widget + polish + demo prep |

### 8.2 Task lifecycle

```
Backlog ──→ In Progress ──→ Review ──→ Done
   ↑           ↑              ↑          ↑
   anh tạo    dev pull/      PR open    PR merged
   (issue)    leader assign  (Closes #) (auto)
```

### 8.3 Tạo task

Task phải dùng template `.github/ISSUE_TEMPLATE/task.md`. Bắt buộc fields:

- **Mô tả** (1-2 câu).
- **Acceptance criteria** ≥ 3 bullet, đo được.
- **Estimate** T-shirt size (XS/S/M/L).
- **Module** (auth / feed / post / ... — xem §8.4 module list) + **assignee** (= module owner).
- **Files có thể chạm** (preview scope).
- **Test plan** (test file + manual repro).

Thiếu các field này → task chưa ready để pull. Anh sẽ flag trong sprint planning.

### 8.4 Phân chia task — Solo-dev module ownership

Team **solo-dev model**: 4 dev, mỗi người own 1+ module **end-to-end** (data + logic + UI + test). Không tách FE/BE. Module phức tạp có thể nhiều người làm chung, nhưng **ưu tiên 1 người 1 module** để rõ ownership. Detail role: [ADR-0004](adr/0004-solo-dev-module-ownership.md) (sẽ thêm) + `.cursor/rules/25-dev-code-standards.mdc`.

**Module list** (chưa pre-assign — anh chốt khi finalize spec):

| Module | Type | Ghi chú |
|---|---|---|
| `auth` | Tier 0 | Email + Google sign-in |
| `friend` | Tier 0 | Invite + accept + friend list |
| `camera` | Tier 0 | Back/front + capture + caption |
| `post` | Tier 0 | Upload + metadata + push trigger |
| `feed` | Tier 0 | Vertical list + cache + pagination |
| `notification` | Tier 0 | FCM Android |
| `reaction` | Tier 0 | Single emoji react |
| `widget` | Tier 0 | Android AppWidget native |
| `diary` | Tier 0+ | Text + 1-3 ảnh, no canvas |
| `space` | Tier 0+ | Group + send photo |
| `rollcall` | Tier 0+ | Weekly notif + special post |
| `profile` | Tier 0+ | Avatar + bio + grid |

**Designer role** (HanDHG + NganTNK kiêm):

- Vẽ Figma frame + design system + theme token cho **cả app** trước khi anh export contract.
- Module nào do họ design → ưu tiên họ implement Flutter để giữ design fidelity.
- Tracking task design qua label `module:<name>` + assignee.

**Rules:**

- **WIP limit:** mỗi dev tối đa **2 task** `In Progress`.
- **Assignment:** anh assign trực tiếp module owner cho từng task qua issue → owner = assignee.
- **Cross-module strict:** dev A cần đụng module B → khoá lại, ping leader, leader xem xét + cập nhật contract → mở task riêng cho owner B (hoặc explicit assign cross-module task). Detail: `25-dev-code-standards.mdc` §Cross-module touch.
- **Spec-driven:** mọi module phải có `docs/specs/<module>.md` + freezed models + abstract interfaces merged vào `develop` TRƯỚC khi giao dev. Dev không tự đoán contract.
- **Multi-owner module phức tạp:** nếu module quá lớn (vd `feed` cả pagination + cache + UI), anh có thể assign 2 dev — chia sub-task rõ ràng (vd dev A: data + controller, dev B: UI + widget test) trong issue.
- **Anh là safety net:** task quá khó cho dev student → anh pickup hoặc pair-program.
- **AI agent guard:** Cursor tự load `.cursor/rules/24-flutter-ui-patterns.mdc` khi edit `presentation/` / `core/theme/` / `shared/widgets/`. Tự load `.cursor/rules/25-dev-code-standards.mdc` mọi message (`alwaysApply: true`) để remind solo-dev contract.

### 8.5 Definition of Done

Một task được mark `Done` chỉ khi đầy đủ 7 mục:

- [ ] Code committed theo Conventional Commits + tiếng Việt.
- [ ] Tests added (unit cho logic; widget cho UI critical path; theo `.cursor/rules/30-testing-and-verification.mdc`).
- [ ] `flutter analyze` + `dart format` clean (auto via husky pre-commit).
- [ ] PR mở, description theo `.github/pull_request_template.md`.
- [ ] ≥ 1 reviewer approve (anh là default CODEOWNERS).
- [ ] CI pass: `pr-check.yml` (lint + test + branch name + commit format).
- [ ] Merged vào `develop`.

**Coverage** không ép cứng threshold per task — theo guideline trong `30-testing-and-verification.md`: logic ≥80%, repo ≥70%, UI ≥50%.

### 8.6 Estimation — T-shirt size

| Size | Effort | Khi nào dùng |
|---|---|---|
| **XS** | ≤ 2h | Bug nhỏ, config tweak, doc update |
| **S** | ~4h (nửa ngày) | 1 widget UI đơn giản, 1 unit test file, 1 helper function |
| **M** | ~8h (1 ngày) | 1 feature screen với state, 1 Cloud Function với tests |
| **L** | 2-3 ngày | 1 module phức tạp: friend graph, post + storage, widget + glance update |

**Rule:** Task > L bắt buộc break thành nhiều task nhỏ hơn.

### 8.7 Daily check-in (async)

**Không sync meeting hàng ngày.** Mỗi sáng dev post 3-5 dòng vào channel team (Discord / Zalo, chọn 1):

```
Hôm qua: <PR/commit link hoặc task đã done>
Hôm nay: <task ID đang làm>
Block: <nếu có, hoặc "no block">
```

Sync session chỉ **1 lần/sprint** = Thứ 6 tuần 2 (sprint review + retro 30-60ph).

### 8.8 Code review SLA

- Reviewer (anh là default) phải comment / approve trong **≤ 24h working day** kể từ PR open.
- Lâu hơn 24h: dev ping trong daily check-in.
- PR > 500 lines diff: anh có thể request break thành nhỏ hơn (≤ 200 lines/PR ideal).
- "Request changes" cần block-level reason — comment cụ thể trên dòng.

### 8.9 Milestone reporting cho giảng viên

Mỗi milestone end (M1: 13/5, M2: 27/5, M3: 9/6), anh deliver 3 thứ:

**A. Milestone summary doc** — `docs/milestones/M<N>-<topic>.md`. Format đầy đủ trong [`docs/milestones/README.md`](milestones/README.md). Tóm tắt 6 section bắt buộc:

1. Mục tiêu (đã set đầu sprint).
2. Deliverable shipped + screenshot/video + APK link.
3. Velocity + task breakdown.
4. Per-dev contribution.
5. Spec / plan / ADR đã add.
6. Retrospective (đã work, chưa work, action items).

**B. Live links** giảng viên browse:

- GitHub Projects board.
- Latest staging APK (CI artifact).
- ADR mới trong milestone.

**C. Demo session 30-60ph** với giảng viên:

- Live demo trên device/emulator Android.
- Walk through 5-10 commit highlight.
- Q&A.

## 9. Tình huống hay gặp

### Tôi quên checkout từ `develop`, branch base đang là `main` (cũ)

```bash
git fetch origin develop
git rebase origin/develop
# Resolve conflict nếu có, rồi:
git push --force-with-lease
```

### Tôi đặt sai tên branch (vd `feat/...` thay vì `feature/...`)

```bash
git branch -m feature/ThienPDM/auth-google
git push origin --delete feat/ThienPDM/auth-google  # Nếu đã push
git push -u origin feature/ThienPDM/auth-google
```

### Commit message bị commitlint reject

```bash
# Sửa commit cuối:
git commit --amend
# Editor mở → sửa lại message → save.

# Sửa nhiều commit (rebase interactive):
git rebase -i develop
# Đổi `pick` thành `reword` cho commit cần sửa.
```

### Tôi cần update branch của mình với `develop` mới nhất

```bash
git checkout develop
git pull --ff-only
git checkout feature/<DevName>/<desc>
git rebase develop
# Resolve conflict nếu có:
git add <conflicted-files>
git rebase --continue
git push --force-with-lease
```

**Khuyến cáo:** dùng `rebase` thay vì `merge develop` để giữ history sạch.

### Hook husky không chạy

```bash
# Bind lại:
npx husky

# Verify hooks tồn tại:
ls -la .husky/
# Phải thấy: commit-msg, pre-commit, pre-push (executable)

# Bypass khẩn cấp (KHÔNG khuyến khích):
git commit --no-verify -m "..."
git push --no-verify
```

### Test regex branch name local bằng PowerShell

**Caveat (Windows dev):** PowerShell `-match` operator mặc định **case-INSENSITIVE**. Hook chạy bash `grep -qE` (POSIX, case-SENSITIVE). Nếu test regex local bằng pwsh `-match`, kết quả sẽ false positive.

**Sai (pwsh `-match` cho qua name lowercase DevName):**

```pwsh
"feature/thien/auth" -match '^[A-Z][a-zA-Z]+[A-Z]+/...'
# True — false positive
```

**Đúng (pwsh `-cmatch` case-sensitive, mirror bash):**

```pwsh
"feature/thien/auth" -cmatch '^[A-Z][a-zA-Z]+[A-Z]+/...'
# False — match hook behavior
```

**Cách an toàn nhất:** test bằng bash trực tiếp (Git Bash trên Windows ship sẵn):

```bash
bash -c 'echo "feature/ThienPDM/auth" | grep -qE "^(feature|fix)/[A-Z][a-zA-Z]+[A-Z]+/[a-z][a-z0-9-]*$" && echo PASS || echo FAIL'
```

### CI fail nhưng chạy local OK

- Check log CI cẩn thận — thường là version Flutter/Node khác.
- CI dùng Flutter 3.41.4, Node 20. Local cũng nên cùng version.
- Nếu vẫn fail: comment trong PR `@<leader>` để debug cùng.

## 10. FAQ

**Q: Tại sao commit message tiếng Việt mà type prefix tiếng Anh?**

A: Conventional Commits là spec — tools (changelog generator, semantic-release, GitHub Projects auto-label) parse type prefix English. Mô tả thì là natural language → tiếng Việt cho team Việt đọc dễ hơn.

**Q: Có thể skip commitlint không?**

A: `git commit --no-verify` skip local hook, nhưng CI vẫn check trên PR. PR sẽ fail. Đừng skip.

**Q: Tôi chưa có Firebase project, deploy CI có chạy không?**

A: `pr-check.yml` chạy bình thường (test + lint không cần Firebase). `develop-staging.yml` + `deploy-production.yml` có `if: false` ở các job deploy → skip. Anh remove `if: false` khi đã setup Firebase.

**Q: Có thể commit vào `develop` trực tiếp khi gấp không?**

A: Không. Branch protection rule sẽ block. Cách hợp lệ duy nhất là PR (có thể tự approve nếu emergency, nhưng phải qua PR).

**Q: Nếu giảng viên hỏi tiến độ, anh show gì?**

A:
1. **Milestone summary doc** trong `docs/milestones/M<N>-*.md` — báo cáo formal mỗi milestone (xem §8.9).
2. GitHub Projects board (`Meep MVP`) — visual, tasks per dev, filter theo Sprint/Milestone.
3. GitHub Insights → Contributors — số commit per dev cho cross-check.
4. `develop` branch CI status — green = team đang ổn.
5. Tag releases — Phase 2 sẽ có v0.1.0, v0.2.0 từ `deploy`.

**Q: 4 dev cùng code 1 file → conflict liên tục?**

A: Tránh bằng cách:
1. Phân chia ownership theo feature module (feature-first folder structure đã giúp).
2. CODEOWNERS chia per module → dev khác không tự ý sửa module của em khác.
3. Daily sync (10 phút mỗi sáng) — biết ai đang làm gì.
4. Sprint planning chia task không overlap.

---

## Câu hỏi thêm?

Hỏi anh trong Discord/Slack channel của team. File này là live doc — phát hiện lỗi/lỗ hổng → mở PR sửa, không cần xin phép.
