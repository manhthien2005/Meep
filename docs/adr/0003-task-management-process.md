# 0003. Task management process — sprint cadence + hybrid assignment

**Date:** 2026-04-30
**Status:** Accepted

## Context

Meep là dự án capstone 4 dev student với deadline cứng **9/6/2026** (6 tuần kể từ 30/4). Giảng viên đánh giá theo milestone-based approach — mong đợi:

- Traceability rõ ràng: ai làm phần nào, link với commit/PR/issue.
- Process chuẩn để defend lúc demo (không "vibe code").
- Deliverable concrete mỗi mốc.

Trước ADR này:

- Branch / commit / PR / CI workflow đã thiết lập (xem `docs/team-workflow.md` §3-§6).
- Nhưng **chưa có quy tắc chính thức** về:
  - Sprint cadence + milestone mapping.
  - Cách tạo + phân chia task.
  - Definition of Done.
  - Estimation method.
  - Code review SLA.
  - Daily check-in cadence.
  - Format milestone reporting cho giảng viên.

Thiếu các quy tắc này dẫn đến rủi ro: task overlap, scope drift, leader bottleneck, không có data trình bày giảng viên giữa kỳ.

Team profile:

- 4 dev (anh là leader). Mix:
  - **2 dev full-stack** (anh + 1): cover Flutter + Cloud Functions + Firestore rules + Android native widget Kotlin.
  - **2 dev FE-bridge** (FE thuần): focus chuyển Figma design → Flutter UI. Skill: widgets, theme system, animation, design system extraction. Có Figma file sẵn + design pattern + màn hình mẫu.
- Capstone là cơ hội học → process phải dạy được self-organization, không micromanage.
- Anh đảm nhiệm: leader, default reviewer (CODEOWNERS), sprint planner, giảng viên contact. Process phải để anh thở được.
- BE Functions + native widget Kotlin **không có specialty owner riêng** — 2 FS owns hoàn toàn. Đây là bối cảnh quan trọng cho lane assignment (§4) và milestone scope (§1).

## Decision

Áp dụng quy trình task management gồm 11 quyết định:

### 1. Timeline + milestones

- **Tổng thời gian:** 6 tuần (30/4/2026 → 9/6/2026).
- **3 milestones**, mỗi milestone = 1 sprint (2 tuần).
  - **M1 (30/4 → 13/5):** Setup CI/Firebase + auth (email + Google) + skeleton features folder.
  - **M2 (14/5 → 27/5):** Friend graph + post photo + friend feed.
  - **M3 (28/5 → 9/6):** FCM notification + Android widget + polish + demo prep.
  Note: M3 ngắn hơn ~2 ngày do 9/6 rơi Thứ Ba — scope nhẹ hơn để buffer demo prep.
- **Mỗi milestone end:** giảng viên review (xem §10 Reporting).

### 2. Sprint cadence

- **Sprint = 2 tuần.**
- **Sprint planning:** Thứ 2 sáng tuần 1 của sprint (1-2h, async OK với leader chốt).
- **Sprint review + retro:** Thứ 6 chiều tuần 2 (sync 30-60ph, online OK).
- **Daily check-in:** async (xem §8).

### 3. Team skill spread

**2 dev full-stack** (anh + 1):

- Cover: Flutter (full layer), Cloud Functions, Firestore rules + indexes, Storage rules, Android widget Kotlin.
- Pickup mọi loại task. **Là default safety net** khi specialty task FE-bridge stuck hoặc task BE/native không có ai khác làm.

**2 dev FE-bridge** (FE thuần, Figma → Flutter):

- Focus chuyển Figma design → Flutter UI đúng chuẩn design system + clean code + reusable.
- **Scope code:**
  - ✅ `apps/mobile/lib/features/<feature>/presentation/` (widgets, screens, pages).
  - ✅ `apps/mobile/lib/core/theme/` (design tokens, theme system).
  - ✅ `apps/mobile/lib/shared/widgets/` (reusable widgets cross-feature).
  - ⚠️ `apps/mobile/lib/features/<feature>/application/` — chỉ **consume** controller có sẵn. KHÔNG tự viết Riverpod controller mới (nhờ FS dev).
  - ❌ `apps/mobile/lib/features/<feature>/data/` (repositories) — FS dev làm.
  - ❌ `firebase/functions/`, `apps/mobile/android/app/src/main/kotlin/` — FS dev làm.
- **AI agent guard:** glob-scoped rule `.windsurf/rules/24-flutter-ui-patterns.md` tự động load khi FE-bridge edit `presentation/` hoặc `theme/`. Rule định nghĩa design tokens, widget patterns, accessibility, Figma mapping convention.

### 4. Task assignment — Hybrid (specialty + open lane)

Backlog có 3 lane:

| Lane | Cách phân | Ai dùng |
|---|---|---|
| **Specialty — BE/Native** | Anh assign cho 2 FS | Cloud Functions phức tạp, Firestore rules, Android widget Kotlin, native integration, data layer (repositories, mappers) |
| **Specialty — UI/Design** | Anh assign cho 2 FE-bridge | Screen từ Figma, design system extraction, theme tokens, reusable widget, animation phức tạp |
| **Open** | Backlog có priority order. Dev pull theo thứ tự khi rảnh (theo skill match) | Docs, simple test, config tweak, small refactor, ADR draft |

Rules:

- **WIP limit:** mỗi dev tối đa 2 task `In Progress`. Đủ rồi không pull thêm.
- **Pull workflow:** dev comment trong issue "lấy task này" → tự assign → move card sang `In Progress` → tạo branch.
- **Specialty fallback:** task specialty không có owner kịp →
  - **BE/Native:** anh hoặc FS dev thứ 2 pickup. Nếu cả 2 FS đã đầy WIP → task đó trở về Backlog, anh re-prioritize sprint. Cắt scope nếu cần.
  - **UI/Design:** FE-bridge dev kia pickup, hoặc anh pickup nếu cả 2 FE-bridge đầy WIP.
- **Anh là default safety net:** task quá khó cho dev student → anh pickup hoặc pair.
- **Cross-lane PR review:** FE-bridge PR → anh review (default) hoặc FS dev review nếu có câu hỏi về data integration. BE/Native PR → anh review.

### 5. Definition of Done (DoD)

Một task được mark `Done` chỉ khi đầy đủ 7 mục:

- [ ] Code committed theo Conventional Commits + tiếng Việt.
- [ ] Tests added (unit cho logic; widget cho UI critical path; theo `30-testing-and-verification.md`).
- [ ] `flutter analyze` + `dart format` clean (auto via husky pre-commit).
- [ ] PR mở, description theo `.github/pull_request_template.md`.
- [ ] ≥ 1 reviewer approve (anh là default CODEOWNERS).
- [ ] CI pass: `pr-check.yml` (lint + test + branch name + commit format).
- [ ] Merged vào `develop`.

Coverage không ép cứng threshold per task — theo guideline ranges trong `30-testing-and-verification.md`: logic ≥80%, repo ≥70%, UI ≥50%.

### 6. Estimation — T-shirt size

| Size | Effort tương đương | Khi nào dùng |
|---|---|---|
| **XS** | ≤ 2h | Bug fix nhỏ, config tweak, doc update |
| **S** | Nửa ngày (≈ 4h) | 1 widget UI đơn giản, 1 unit test file, 1 helper function |
| **M** | 1 ngày (≈ 8h) | 1 feature screen với state management, 1 Cloud Function với tests |
| **L** | 2-3 ngày | 1 module phức tạp: friend graph, post + storage upload, widget + glance update |

**Rule:** Task > L bắt buộc break thành nhiều task nhỏ hơn. GitHub Projects custom field `Effort` enforce.

### 7. Code review SLA

- Reviewer (anh là default) phải comment hoặc approve trong **≤ 24h working day** kể từ PR open.
- Lâu hơn 24h: dev ping trong daily check-in hoặc Discord/Zalo channel.
- PR > 500 lines diff: anh có thể request break thành nhỏ hơn (≤ 200 lines/PR ideal).
- "Request changes" cần block-level reason — comment cụ thể trên dòng.

### 8. Daily check-in — async

**Không sync meeting hàng ngày.** Mỗi sáng dev post 3-5 dòng vào channel team (Discord/Zalo, chọn 1):

```
Hôm qua: <PR/commit link hoặc task đã done>
Hôm nay: <task ID đang làm>
Block: <nếu có, hoặc "no block">
```

Sync session chỉ **1 lần/sprint** = Thứ 6 tuần 2 (sprint review + retro 30-60ph).

### 9. Task template

Tạo `.github/ISSUE_TEMPLATE/task.md` (sibling với `bug.md`, `feature.md`). Bắt buộc fields:

- Mô tả (1-2 câu việc cần làm).
- Acceptance criteria (≥ 3 bullet).
- Estimate (T-shirt size XS/S/M/L).
- Lane (Specialty BE/Native, Specialty UI/Design, hoặc Open).
- Files có thể chạm (preview scope cho reviewer).
- Dependencies / blockers (link issue khác nếu có).
- Test plan (test file path + manual repro).

### 10. Milestone reporting cho giảng viên

Mỗi milestone end (M1: 13/5, M2: 27/5, M3: 9/6), anh deliver 3 thứ:

**A. Milestone summary doc** — `docs/milestones/M<N>-<topic>.md`. Bao gồm:

- Mục tiêu milestone (đã set đầu sprint).
- Deliverable shipped (feature list + screenshot/video).
- Velocity: task closed / total + sum T-shirt sizes.
- Per-dev contribution: snapshot từ GitHub Projects "Group by Assignee" view.
- Blocker + retrospective lessons.
- Spec + plan + ADR đã add trong milestone.

**B. Live links** giảng viên browse được:

- GitHub Projects board (public repo nên giảng viên truy cập trực tiếp).
- Latest staging APK (CI artifact từ `develop-staging.yml`).
- ADR mới trong milestone.

**C. Demo session 30-60ph** với giảng viên:

- Live demo trên device/emulator Android.
- Walk through 5-10 commit highlight (anh prepare slide / git log filter).
- Q&A.

### 11. Task tracking tool

GitHub Projects v2 với fields:

- `Status`: Backlog → In Progress → Review → Done.
- `Sprint`: Sprint 1 / 2 / 3.
- `Type`: feature / fix / chore / refactor / docs / test.
- `Lane`: Specialty-BE-Native / Specialty-UI-Design / Open.
- `Effort`: XS / S / M / L.
- `Assignee`: GitHub user.

Auto-add: mọi issue + PR → board. Linkage qua `Refs #N` / `Closes #N` trong commit/PR.

## Alternatives considered

### Option A — Scrum đầy đủ (sprint planning poker, story points Fibonacci)

Pros:
- Standard industry process.
- Velocity tracking precise.

Cons:
- Overhead học cho dev student lớn (poker planning, retrospective format chuẩn).
- Cần Scrum Master role → anh thêm 1 vai → quá tải.
- Không thêm value đáng kể cho capstone scale 4 dev × 6 tuần.

### Option B — Hybrid lite (chosen)

Pros:
- Cấu trúc đủ để giảng viên thấy process chuyên nghiệp.
- Async stand-up + minimal ceremony → dev student không bị overhead.
- T-shirt size dễ học, dễ explain với giảng viên.
- Hybrid assignment match team skill mix.

Cons:
- Anh vẫn là single point of contact cho specialty assignment + review — risk burnout nếu không control.
- Async check-in phụ thuộc dev tự discipline post mỗi ngày.

### Option C — Pure kanban (no sprint, continuous flow)

Pros:
- Lightest ceremony possible.
- Phù hợp throughput cao, ít coordination.

Cons:
- Khó báo cáo giữa kỳ — không có natural breakpoint.
- Giảng viên milestone-based → cần boundary rõ.

### Option D — Leader push toàn quyền

Pros:
- Control chặt, traceability ngay đầu sprint.

Cons:
- Anh becomes daily bottleneck (~30-60ph/ngày assign).
- Dev student không học self-organization (mất bài học capstone).
- Capstone defense yếu — giảng viên có thể nhận xét "anh làm hết, team thi hành".

## Consequences

### Positive

- Sprint+milestone sync clean → process+timeline+reporting tự align.
- Anh không bottleneck (chỉ assign ~30% specialty + review PR).
- Dev student có autonomy với open lane → học self-organization.
- Traceability tự đến: issue → branch → commit → PR → merge → release notes.
- Giảng viên có 3 milestone checkpoints (14/5, 28/5, 9/6) — đủ data trình bày tiến độ.
- Format docs (`docs/milestones/`) chuẩn → giảng viên dễ review giữa kỳ.

### Negative

- Async daily check-in phụ thuộc dev tự discipline — nếu dev skip, anh khó catch sớm.
- M3 ngắn hơn 2 ngày (12 ngày thay vì 14) → scope phải nhẹ. Demo prep + polish phải gọn.
- Nếu mid-sprint scope explode (vd feature lớn hơn dự kiến), không có buffer sprint thứ 4 → cắt scope là cách duy nhất.
- Anh phải maintain backlog priority cẩn thận đầu sprint — sai priority thì dev pull trật target.

### Neutral / unknowns

- Specialty vs Open lane phân chia phụ thuộc subjective leader judgement — có thể adjust sau retro M1.
- Velocity sprint đầu sẽ chưa accurate (team chưa biết throughput thực) — sprint 2-3 calibrate dần.
- WIP limit 2 task có thể cần adjust (lên 3 nếu task XS nhiều, hoặc xuống 1 nếu task L thường xuyên).

## Verification

Re-visit ADR này khi:

- Cuối M1 retro (13/5): có process nào không work? Adjust trước M2.
- Velocity sprint 1 lệch >50% so với ước tính → re-estimate scope M2/M3.
- Giảng viên feedback yêu cầu format reporting khác → update §10.
- Team size thay đổi (vd 1 dev drop) → re-balance lane assignment.

Cho đến khi xảy ra một trong những trigger trên, các quyết định trong ADR này là binding cho cả team.
