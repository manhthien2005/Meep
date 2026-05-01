# Milestones

Folder này chứa các báo cáo milestone — mỗi cuối milestone (2 tuần / 1 sprint) anh deliver 1 file để giảng viên review. Quy ước được định nghĩa trong [`docs/adr/0003-task-management-process.md`](../adr/0003-task-management-process.md) §10.

## Tổng quan

Meep có **3 milestones** trong 6 tuần (30/4 → 9/6/2026):

| Milestone | Window | Sprint | Scope |
|---|---|---|---|
| **M1** | 30/4 → 13/5 | Sprint 1 | Setup CI/Firebase + Auth (email + Google) + skeleton features folder |
| **M2** | 14/5 → 27/5 | Sprint 2 | Friend graph + Post photo + Friend feed |
| **M3** | 28/5 → 9/6 | Sprint 3 | FCM notification + Android widget + polish + demo prep |

## Naming convention

```
M<N>-<topic-slug>.md
```

Ví dụ:
- `M1-auth-and-setup.md`
- `M2-social-core.md`
- `M3-widget-and-demo.md`

Topic slug: kebab-case English, mô tả ngắn nội dung milestone (≤ 4 từ).

## Required sections

Mỗi milestone summary doc phải có 6 section sau:

### 1. Mục tiêu (đã set đầu sprint)

- Liệt kê 3-5 deliverable cốt lõi đã chốt khi sprint planning đầu milestone.
- Reference: link tới spec/plan trong `docs/specs/` và `docs/plans/`.

### 2. Deliverable shipped

- Feature list đã hoàn thành (đã merge vào `develop`).
- Screenshot / video demo (drag-drop trực tiếp vào markdown).
- Link tới staging APK build (CI artifact từ `develop-staging.yml`).

### 3. Velocity + task breakdown

| Metric | Value |
|---|---|
| Total task | <số> |
| Closed | <số> |
| Carry-over sang milestone sau | <số> |
| Velocity (sum T-shirt sizes) | <số XS + S + M + L> |
| Tỷ lệ hoàn thành | <%> |

### 4. Per-dev contribution

Snapshot từ GitHub Projects "Group by Assignee" view. Bao gồm:

| Dev | Task closed | Velocity (size sum) | Highlight contribution |
|---|---|---|---|
| ThienPDM | <số> | <size sum> | <vd: feature auth Google, ADR-0003> |
| <Dev2> | ... | ... | ... |
| <Dev3> | ... | ... | ... |
| <Dev4> | ... | ... | ... |

Bonus: link tới GitHub Insights → Contributors snapshot (số commit per dev) cho cross-check.

### 5. Spec / plan / ADR đã add

Liệt kê documents mới trong milestone:

- Specs: `docs/specs/YYYY-MM-DD-<topic>.md`
- Plans: `docs/plans/<topic>.md`
- ADRs: `docs/adr/NNNN-<title>.md`

### 6. Retrospective

3 phần ngắn (mỗi 3-5 bullet):

- **Đã work tốt** (giữ tiếp).
- **Chưa work tốt** (adjust ở milestone sau).
- **Action items** (concrete, có owner + deadline).

## Template starter

Khi bắt đầu viết milestone summary, copy template này:

```markdown
# Milestone <N>: <Topic>

**Window:** <start-date> → <end-date>
**Sprint:** Sprint <N>
**Status:** [ ] In progress  [ ] Closed
**Demo session:** <date + time>

## 1. Mục tiêu

- 
- 
- 

## 2. Deliverable shipped

<!-- List feature + screenshot/video + APK link. -->

## 3. Velocity + task breakdown

| Metric | Value |
|---|---|
| Total task | |
| Closed | |
| Carry-over | |
| Velocity (XS + S + M + L) | |
| % hoàn thành | |

## 4. Per-dev contribution

| Dev | Task closed | Velocity | Highlight |
|---|---|---|---|
| | | | |

## 5. Documents thêm

- Specs: 
- Plans: 
- ADRs: 

## 6. Retrospective

### Đã work tốt
- 

### Chưa work tốt
- 

### Action items
- [ ] 
```

## Lifecycle

- Doc viết khi sprint review cuối milestone (Thứ 6 tuần 2 của sprint).
- Anh commit doc vào `develop` qua PR (`docs/<DevName>/M<N>-summary`).
- Demo session với giảng viên tham chiếu doc này.
- Sau demo: nếu giảng viên có feedback adjust scope/process → cập nhật ADR-0003 và milestone tiếp.

## Live links cho giảng viên

Anh share với giảng viên 4 link mỗi milestone:

1. **GitHub Projects board:** `https://github.com/<org>/meep/projects/1` <!-- TODO(setup): fill org khi tạo repo -->
2. **Milestone summary doc:** file trong folder này.
3. **Latest staging APK:** từ tab Actions → workflow run mới nhất → artifact `meep-staging-apk-*`.
4. **GitHub Insights → Contributors:** `https://github.com/<org>/meep/graphs/contributors` <!-- TODO(setup): fill org -->
