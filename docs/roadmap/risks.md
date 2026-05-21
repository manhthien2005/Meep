# Meep — Risk Register

Top risks cho 6-tuần capstone. Mỗi risk có likelihood, impact, mitigation, owner.

> **Scoring:** Likelihood × Impact = Risk score. High (red) = action ngay. Med (yellow) = monitor. Low (green) = aware.

## Risk matrix

| ID | Risk | Likelihood | Impact | Score | Owner |
|---|---|---|---|---|---|
| R1 | M3 overflow do quá nhiều task differentiator | High | High | 🔴 Critical | Anh (leader) |
| R2 | Native Kotlin Widget Android phức tạp | Med | High | 🟡 Med | FS-1 (anh) |
| R3 | Design tokens land trễ → module owner UI idle | Med | Med | 🟡 Med | Anh (coordination) |
| R4 | Velocity 4 dev không đều | High | Med | 🟡 Med | Anh (planning) |
| R5 | Camera package compatibility issues trên một số Android | Med | Med | 🟡 Med | FS-1 |
| R6 | AI hallucination tạo bug subtle | High | Med | 🟡 Med | All dev |
| R7 | Firebase quota Spark plan không đủ M3 demo | Low | High | 🟡 Med | Anh |
| R8 | Giảng viên thay đổi yêu cầu / scope | Low | High | 🟡 Med | Anh |
| R9 | Dev vắng mặt / sick leave > 3 ngày | Med | Med | 🟡 Med | Anh |
| R10 | Test coverage không đạt mục tiêu | Med | Low | 🟢 Low | All |

---

## R1 🔴 — M3 overflow do quá nhiều task differentiator

**Mô tả:** M3 12 ngày × 4 dev × 0.7 = 33 dev-days budget. Tasks raw: ~49 dev-days. Over budget ~50%.

**Trigger conditions:**
- Cuối M2 Tier 0 chưa ship complete
- M2 retro velocity boost <1.4x

**Mitigation:**

1. **Pre-build foundation cuối M2 (DAY 13-14):** Move 3-5 days skeleton (data layer + Firestore schema) cho diary/space/rollcall lên M2. M3 chỉ implement controllers + UI.
2. **Cut Tier 1 hoàn toàn:** Bất kể velocity, M3 chỉ Tier 0 + 0+. Tier 1 = post-capstone.
3. **Streamline differentiator nếu cần ở M3 day 6-7:**
   - Diary: chỉ create + list + view → skip edit/delete
   - Space: skip invite friends list → manual add by username
   - RollCall: skip cron → manual trigger admin Cloud Function Console
4. **Accept M3 dài hơn 2-3 ngày** nếu giảng viên cho phép (demo 12-15/6).
5. **Streamline UI:** Re-skin design tokens DEFER nếu không kịp — keep Material 3 baseline cho demo (đẹp đủ rồi).

**Trigger ESCALATION:** M3 day 6 (3/6) chưa ship Diary basic → escalate, cut Tier 1 (đã cut), apply mitigation 3.

**Owner:** Anh (leader). Daily check-in M3 đo velocity vs budget.

---

## R2 🟡 — Native Kotlin Widget Android phức tạp

**Mô tả:** AppWidget API + `home_widget` plugin + FCM data message coordination = territory AI training data ít. Widget phải:
- Render đúng trên 3+ thiết bị Android (size, launcher khác nhau)
- Update qua FCM trong <30s
- Tap deep link mở app vào đúng ảnh

**Trigger conditions:**
- M2 cuối: spike `camera` package fail trên 1/3 thiết bị → widget cũng có khả năng tương tự
- M3 day 1-2: widget setup không pass smoke test

**Mitigation:**

1. **Spike sớm M2 cuối (1 ngày):** FS-1 test `home_widget` plugin + AppWidget basic + render 1 placeholder trên 2 thiết bị.
2. **Code reference:** Karpathy guidelines + context7 MCP cho up-to-date AppWidget API docs (avoid AI hallucination).
3. **Fallback widget simple:** Nếu deep link không work → tap widget chỉ mở app vào /home. Lose deep link feature, keep widget ship.
4. **Manual fallback nếu widget total fail:** Demo M3 với screenshot widget trên slide thay vì live demo widget. Lose điểm, nhưng ship được.

**Owner:** FS-1 (anh).

---

## R3 🟡 — Design tokens land trễ → module owner UI idle

**Mô tả:** HanDHG + NganTNK (kiêm UI/UX) chưa hoàn thiện design pattern (color, typography, spacing, component variants) trong Figma. Module owner phụ thuộc design tokens có thể bị block khi build UI screens.

**Trigger conditions:**
- M1 day 5 (5/5) — design tokens chưa có
- Design team chưa response request priority

**Mitigation:**

1. **Communicate sớm (today):** Anh discuss với HanDHG + NganTNK — request ưu tiên design tokens deliver trong tuần này.
2. **Module owner work với Material 3 baseline:** Dùng `Theme.of(context).colorScheme.primary` + `textTheme.headlineSmall` (rule 24 cấm hardcode hex/font). Re-skin sau khi tokens land = update `core/theme/` only, KHÔNG refactor widget.
3. **Module owner alternative tasks nếu idle:**
   - Viết widget tests cho UI placeholder
   - Learn Riverpod consume pattern
   - Scaffold `shared/widgets/` từ wireframe (placeholder common components)
   - Review Figma vision detail, document edge cases
4. **Re-skin lùi:** Re-skin design tokens defer M2 cuối / M3 đầu. Demo M1 OK với Material 3 baseline.

**Owner:** Anh (coordination với design team).

---

## R4 🟡 — Velocity 4 dev không đều

**Mô tả:** 4 dev student capstone với skill levels khác nhau:
- Anh + 1 dev mạnh (skill backend/native vững)
- 2 dev còn lại skill basic (cần ramp-up Flutter + Firebase)
- AI boost factor: senior 3-4x, junior 1-2x

**Trigger conditions:**
- M1 retro velocity boost <1.2x cho dev junior
- 1 dev không hoàn thành task assigned trong sprint

**Mitigation:**

1. **Pair-programming AI early:** 2 dev junior pair với anh hoặc dev senior tuần 1. Học pattern.
2. **Module assignment theo skill:**
   - Anh + dev senior → module phức tạp (Auth, Post + storage, Widget native)
   - 2 dev junior → module UI-heavy + đã có Figma sẵn (Profile, Diary, Reaction)
   - Pair-programming các module milestone-critical
3. **Code review chặt:** Anh review tất cả PR. Catch bug + teach pattern.
4. **Daily check-in async:** Phát hiện block sớm. Re-allocate module nếu dev stuck.
5. **Cross-module fallback (ADR-0004):** dev nghỉ → leader pickup module hoặc explicit assign cross-module task cho dev khác. Strict gate vẫn áp dụng — không tự ý sửa module owner khác.

**Owner:** Anh (planning + coordination).

---

## R5 🟡 — Camera package compatibility issues

**Mô tả:** Flutter `camera` package có known issues trên một số thiết bị Android (vd Samsung custom ROM, Xiaomi MIUI camera HAL khác).

**Trigger conditions:**
- M2 day 3-4: `camera` plugin không init được trên 1+/3 thiết bị test

**Mitigation:**

1. **Spike sớm M2 day 1:** FS-1 test `camera` plugin trên 3 thiết bị Android khác nhau (Samsung, Xiaomi, Pixel/Oppo).
2. **Pin version:** Pin `camera: ^0.10.x` (latest stable). Tránh major bump giữa sprint.
3. **Fallback `image_picker`:** Nếu `camera` package fail, fallback chỉ dùng `image_picker` (album picker only) — lose live capture, demo bằng pre-captured photos. **NG accept cho MVP** vì capture là core. Phải fix.
4. **Manual capture pattern:** Worst case: dùng `intent` Android native camera app → return URI → upload. Mất control camera UI nhưng work.

**Owner:** FS-1 (anh).

---

## R6 🟡 — AI hallucination tạo bug subtle

**Mô tả:** AI generate code có thể bịa API không tồn tại, viết logic happy-path bỏ sót edge case, tạo bug subtle dev không catch.

**High-risk areas:**
- Firestore rules syntax (DSL specific)
- Cloud Function trigger schemas (event types)
- Native Kotlin AppWidget API
- Niche libraries (`camera`, `home_widget`)

**Mitigation:**

1. **Test-driven với AI:** Dev viết test trước (skill `tdd`), AI implement. Catch hallucination via test failure.
2. **Verification before completion (skill):** Dev chạy test command, đọc output thực, không trust AI "should pass".
3. **Glob-scoped rules active:** `21-flutter-rules.md`, `22-functions-rules.md`, `23-firestore-rules.md`, `24-flutter-ui-patterns.md` auto-load context đúng.
4. **Manual verify niche API:** Khi AI claim "function X exists" → grep/find verify. Use context7 MCP cho up-to-date library docs.
5. **PR review chặt:** Anh review tất cả PR. PR ≤ 200 lines (rule 20 + ADR-0003).
6. **Token discipline:** Caveman lite mode + narrow read/grep + file modular ≤ 200 lines. AI giữ context window cho task work.

**Owner:** All dev. Anh enforce qua code review.

---

## R7 🟡 — Firebase quota Spark plan không đủ M3 demo

**Mô tả:** Spark plan free tier:
- Firestore: 50K reads/day, 20K writes/day
- Storage: 5GB total + 1GB/day download
- Cloud Functions: 125K invocations/month

M3 demo + giảng viên test cùng lúc + 4 dev test = có thể spike traffic.

**Trigger conditions:**
- M3 day 8: Firebase Console quota usage >70% daily limit

**Mitigation:**

1. **Phase 2 split (planned):** Tạo `meep-prod` separately cho demo, dev project `meep-dev` riêng.
2. **Upgrade Blaze plan trước demo:** Anh upgrade Blaze + setup billing alert ($10/month limit). Storage Function (resize) yêu cầu Blaze (Feb 2026 update).
3. **Optimize hot queries:**
   - Feed query indexed
   - Cache local cached_network_image
   - Listener instead of polling
4. **Demo controlled scope:** Demo M3 chỉ 3 user (Aldo+Beatrice+Charlie) — không stress test load.

**Owner:** Anh (Firebase admin).

---

## R8 🟡 — Giảng viên thay đổi yêu cầu / scope

**Mô tả:** Giảng viên có thể request thêm feature mid-sprint (vd "thêm OTP authentication", "video recording", "iOS support"), hoặc thay đổi format submission.

**Trigger conditions:**
- M1 review giảng viên feedback "thiếu X"
- Giảng viên thay đổi acceptance criteria capstone

**Mitigation:**

1. **Communicate sớm:** Anh check syllabus capstone TODAY (deadline check + scope expectation).
2. **Document vision dài hạn:** `docs/product/features.md` show full vision (Tier 1 + Tier 2 future). Giảng viên thấy team aware nhưng intentional cut cho MVP.
3. **Negotiate flexibility:** Nếu giảng viên request feature mới → push back với data (tier MVP + budget). Hoặc trade off (drop Tier 1 để add request).
4. **Buffer in plan:** Tier 1 stretch là buffer cho yêu cầu giảng viên emerging.

**Owner:** Anh (communication với giảng viên).

---

## R9 🟡 — Dev vắng mặt / sick leave > 3 ngày

**Mô tả:** 1 dev đau ốm hoặc gia đình emergency → mất task assigned trong sprint.

**Trigger conditions:**
- 1 dev báo nghỉ >3 ngày trong sprint

**Mitigation:**

1. **Cross-module fallback (ADR-0004):** dev nghỉ → leader pickup module owner hoặc explicit assign cross-module task. Strict gate vẫn áp dụng.
2. **WIP limit ≤ 2 task/dev:** Limit task mỗi dev. Khi 1 dev nghỉ, task của họ 1-2 cái OK pickup.
3. **Documentation:** Mỗi task có `Test plan` + `Files affected` trong issue → dev khác pickup dễ.
4. **Pair-programming:** Pair giảm bus factor. Mỗi feature có 2 người hiểu code.

**Owner:** Anh (re-assignment).

---

## R10 🟢 — Test coverage không đạt mục tiêu

**Mô tả:** Target rule 30: business logic ≥80%, UI ≥50%. Có thể không đạt nếu time áp lực M3.

**Trigger conditions:**
- M2 retro coverage <70%
- M3 day 8 coverage <60% (alert critical)

**Mitigation:**

1. **TDD discipline (skill):** Test trước, implement sau. AI generate test cases tốt (boost 2x).
2. **Test code = production code:** Code review reject PR thiếu test.
3. **Coverage report CI:** GitHub Actions chạy `flutter test --coverage` + report → PR comment.
4. **Trade-off acceptable:** UI coverage có thể <50% — snapshot test fragile. Focus business logic.

**Owner:** All dev. Anh enforce qua code review.

---

## Risk monitoring

### Daily check-in (M3 critical)

```
Hôm qua: <PR/commit/task done>
Hôm nay: <task ID>
Block: <hoặc no block>
Risk: <flag risk nếu thấy trigger condition>
```

### Per-retro review

- M1 retro 13/5: Re-evaluate R1, R2, R3, R4, R6
- M2 retro 27/5: R1 critical assessment, R2 widget go/no-go
- M3 ongoing: Daily R1 monitoring

### Risk re-evaluation

Update file này khi:
- Trigger condition gặp phải
- Mitigation không hiệu quả → escalate
- Risk mới phát hiện

## Liên quan

- **Sprint plan:** [`milestones.md`](milestones.md)
- **Demo backup:** [`demo-script.md`](demo-script.md) §"Backup plan"
- **ADR-0003 task management:** `docs/adr/0003-task-management-process.md`
