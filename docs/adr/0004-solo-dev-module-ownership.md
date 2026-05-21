# 0004. Solo-dev module ownership — supersede §3, §4, §9 of ADR-0003

**Date:** 2026-05-21
**Status:** Accepted
**Supersedes:** ADR-0003 §3 (Team skill spread), §4 (Task assignment — Hybrid lane), §9 (Task template lane field)

## Context

ADR-0003 (2026-04-30) phân chia team theo "specialty lane": 2 dev full-stack (FS) + 2 dev FE-bridge (Figma → Flutter UI). Backlog có 3 lane: Specialty-BE/Native, Specialty-UI/Design, Open. Phân chia này phản ánh thực tế kỹ năng thời điểm đó.

**Trigger thay đổi (2026-05-21):**

Giảng viên yêu cầu mỗi dev phải tham gia hoàn thiện **một module end-to-end**, không tách FE/BE. Lý do từ giảng viên (capstone evaluation): mỗi sinh viên cần demo được khả năng full-stack ownership, không chỉ "tôi vẽ UI" hoặc "tôi viết Cloud Function".

Hệ quả với ADR-0003:

- §3 (FE-bridge scope giới hạn `presentation/` + `theme/`) → không còn áp dụng. FE-bridge phải implement luôn `data/` + `application/` cho module mình.
- §4 (lane Specialty-BE/Native vs Specialty-UI/Design) → không còn ý nghĩa. Mỗi task thuộc về **module owner**, không phải lane.
- §9 (task template field "Lane") → đổi sang field "Module".

## Decision

Áp dụng **solo-dev module ownership model**:

### 1. Mỗi dev own module end-to-end

Mỗi dev được assign 1 (hoặc vài) module của Meep. Module owner chịu trách nhiệm full-stack:

- `data/` — repository, Firestore mapper.
- `application/` — controller, service, Riverpod provider.
- `presentation/` — widget, page, design token application.
- Cloud Function (nếu module có) — `firebase/functions/src/<module>/`.
- Native code (nếu module có widget Android) — `apps/mobile/android/app/src/main/kotlin/<module>/`.
- Test — unit + widget + integration cho module mình.

**Ưu tiên 1 dev 1 module.** Module phức tạp (vd `feed` cả pagination + cache + UI) có thể assign 2 dev nhưng phải chia sub-task rõ ràng trong issue.

**Phân chia theo độ khó (skill-based):**

| Dev | Module type | Số module ước tính |
|---|---|---|
| `ThienPDM` (Leader) | Module phức tạp: Auth, Widget native (Kotlin), Cloud Functions infra, Post + storage | 3-4 module |
| `KhoaLND` | Module phức tạp/medium: Friend graph, Feed (pagination + cache), Space, Notification, RollCall | 3-4 module |
| `HanDHG` | Module M (medium) hoặc dễ: Profile, Diary, Reaction (UI-leaning) | 2 module |
| `NganTNK` | Module M (medium) hoặc dễ: Camera UI, các UI screen có Figma sẵn | 2 module |

Lý do: HanDHG + NganTNK code skill còn yếu + kiêm Figma cả app → ít module hơn để đổi thời gian Figma. Anh + KhoaLND own nhiều hơn để bù.

### 2. Leader define contract upfront (with KhoaLND pair-contract backup)

Leader (anh) giữ vai trò **architect + gatekeeper**, KhoaLND là **pair-contract backup**:

- Trước khi giao module cho dev, leader merge vào `develop`:
  - Spec đầy đủ tại `docs/specs/<module>.md` với acceptance criteria đo được.
  - Freezed models + abstract interfaces (data layer contract).
  - Stub Riverpod providers (throw `UnimplementedError`).
  - Route stub trong router.
  - TODO marker `// TODO(<task-id>/<DevName>): ...` trên mọi stub.
- Dev pull `develop` → contract đã có sẵn → implement không cần đoán.

**Pair-contract với KhoaLND** (giảm leader bottleneck):

- Leader pair với KhoaLND khi viết contract module phức tạp (Auth, Post + storage, Widget, Cloud Functions infra).
- Sau khi pair, KhoaLND có quyền approve PR contract change cho module đã pair (co-required reviewer cùng leader).
- Khi leader busy/sick: KhoaLND có thể giải block dev khác bằng cách clarify contract đã pair, KHÔNG được tự ý đổi contract chưa pair.

Lý do: 4 dev solo-dev tự define contract → drift, conflict, integration crash. Leader gate giữ team đồng bộ. KhoaLND pair tránh leader thành single point of failure.

### 3. Strict cross-module gate

Module Owner A KHÔNG được tự ý sửa code thuộc module Owner B. Bao gồm cả:

- Bug fix nhỏ trong module B (1 dòng cũng vậy).
- Format / rename "tiện thể".
- Thêm field vào freezed model dùng chung.

**Khoá lại + ping leader** khi cần:

- Đổi field/interface trong contract leader đã chốt.
- Touch shared code: `core/`, `shared/widgets/`, `core/theme/`, `firestore.rules`, `storage.rules`, `firestore.indexes.json`.
- Touch module dev khác.
- Thêm pub/npm package.
- Phát hiện contract không khớp Figma / spec.

**Quy trình unblock:**

1. Dev stop, không tự sửa.
2. Comment trên GitHub issue: `Block: cần đổi <X> trong module <Y>, ping @manhthien2005`.
3. Leader xem xét → cập nhật spec/contract → merge contract change vào `develop` qua PR riêng → ping dev tiếp tục, hoặc tạo task riêng cho owner B.

**Ngoại lệ duy nhất:** leader explicit assign cross-module task (vd "fix #42: Khoa fix bug Auth của Han") → tạo branch + PR review bởi cả Han + leader.

### 4. Designer role (HanDHG + NganTNK)

HanDHG + NganTNK kiêm thêm **UI/UX design (Figma)** cho cả app, song song với role module owner:

- Vẽ Figma frame + design system + theme token cho cả 12 module **trước khi** leader export contract.
- Module Figma do họ design → ưu tiên chính họ implement Flutter để giữ design fidelity.
- Tracking task design qua label `module:<name>` + assignee, không lane riêng.

### 5. Lane labels — drop hết

Bỏ toàn bộ lane labels cũ (`lane:specialty-be-native`, `lane:specialty-ui-design`, `lane:open`). Thay bằng:

- **`module:<name>`** — phân loại task theo module (auth, feed, post, friend, ...).
- **Assignee** — module owner (= dev được leader assign hoặc volunteer rồi leader confirm).

GitHub Projects v2 field `Lane` → đổi thành `Module` (single-select enum).

### 6. CODEOWNERS — leader + module owner co-required

`.github/CODEOWNERS`:

- Default `* @manhthien2005`.
- Mỗi module: `/apps/mobile/lib/features/<module>/   @manhthien2005 @<owner-github>` → cả leader VÀ module owner đều phải approve.
- Shared code (`core/`, `shared/`, `firestore.rules`, infra) → leader-only.

**Hiện tại module list chưa chốt** → CODEOWNERS để placeholder leader-only cho `features/`. Update khi anh finalize module → owner mapping.

### 7. Task template — đổi field "Lane" → "Module"

`.github/ISSUE_TEMPLATE/task.md`: thay section "Lane" bằng "Module ownership":

- `Module:` enum (auth / feed / post / friend / camera / diary / space / rollcall / profile / widget / notification / reaction / core / functions).
- `Module owner (assignee):` @<github-username>.
- Cảnh báo cross-module touch — phải ping leader.

### 8. Module list (initial)

12 module mapping với MVP scope từ `10-project-context.mdc`:

| Module | Type | Scope |
|---|---|---|
| `auth` | Tier 0 | Email + Google sign-in, auto-login |
| `friend` | Tier 0 | Invite + accept + friend list |
| `camera` | Tier 0 | Back/front + capture + caption |
| `post` | Tier 0 | Upload + metadata + push trigger |
| `feed` | Tier 0 | Vertical list + cache + pagination |
| `notification` | Tier 0 | FCM Android |
| `reaction` | Tier 0 | Single emoji react |
| `widget` | Tier 0 | Android AppWidget native (Kotlin) |
| `diary` | Tier 0+ | Text + 1-3 ảnh, no canvas |
| `space` | Tier 0+ | Group + send photo |
| `rollcall` | Tier 0+ | Weekly notif + special post + multi-react |
| `profile` | Tier 0+ | Avatar + bio + grid |

12 module / 4 dev → ~3 module/dev. Anh chia khi finalize spec từng module.

## Alternatives considered

### Option A — Giữ lane FE/BE như ADR-0003

Pros: ổn định, đã setup, AI agent rule đã calibrate cho lane.
Cons: trái yêu cầu giảng viên — không demo được full-stack ownership của từng dev. **Bác bỏ.**

### Option B — Solo-dev hoàn toàn, mỗi dev tự define contract

Pros: maximally autonomous, dev học architect skill.
Cons: 4 contract drift song song → integration nightmare, defense yếu vì tài liệu rời rạc. **Bác bỏ.**

### Option C — Solo-dev + leader-define-contract (chosen)

Pros: dev demo full-stack được; contract centralized → docs nhất quán cho giảng viên; leader gate keep tốc độ team đồng bộ.
Cons: leader trở thành critical path cho contract — nếu leader busy/sick, team block. Mitigation: leader ưu tiên contract work đầu sprint, dev có buffer task không depend contract khi chờ.

### Option D — Pair programming

Pros: knowledge sharing, ít drift.
Cons: 4 dev chia 2 cặp → mỗi cặp 6 module → workload cao. Capstone yêu cầu individual contribution rõ ràng. **Bác bỏ.**

## Consequences

### Positive

- Mỗi dev demo được full-stack module → match yêu cầu giảng viên.
- Contract centralized → docs/specs/ thành tài liệu defense rõ ràng.
- Strict gate giảm drift → CI green stable hơn.
- HanDHG + NganTNK tận dụng skill Figma → design fidelity cao hơn.
- Cross-module conflict giảm vì owner rõ ràng.

### Negative

- Leader workload tăng đầu sprint (define contract cho mọi module trước khi giao).
- Dev chờ contract → có downtime nếu leader chậm. Mitigation: dev có buffer task (test, docs, refactor module mình đã có contract).
- Mỗi dev phải học stack rộng hơn (FE + BE + native nếu module có) → onboarding cost cao hơn ADR-0003.
- Module phức tạp (`feed`, `post` cần fan-out) có thể quá tải 1 dev → cần leader pair hoặc split sub-task.

### Neutral / unknowns

- Module assignment chưa chốt — anh sẽ finalize sau khi viết spec từng module. Có thể phát hiện 1 module nên 2-dev (split sub-task), 1 module nên gộp với module khác.
- Leader bandwidth define contract: chưa có data. Đo sau M1.

## Verification

Re-visit ADR này khi:

- Cuối M1 retro: leader có bottleneck define contract không? Adjust ratio.
- Dev báo block contract > 24h liên tục: review process unblock.
- Module assignment cần đổi (vd dev drop): re-balance.
- Giảng viên feedback đánh giá ownership: confirm process work hay không.

Cho đến khi xảy ra một trong các trigger trên, các quyết định trong ADR này là binding cho cả team. ADR-0003 §1, §2, §5, §6, §7, §8, §10, §11 vẫn áp dụng (sprint cadence, DoD, estimation, review SLA, daily check-in, milestone reporting, GitHub Projects).
