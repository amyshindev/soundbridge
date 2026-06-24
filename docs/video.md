# SoundBridge 인트로 영상 — Higgsfield 프롬프트 가이드

5초짜리 브랜드 인트로 영상을 Higgsfield로 제작한 뒤, **영상 종료 시 랜딩 페이지(`/#` 또는 `/`)가 자연스럽게 이어지도록** 하는 용도의 문서입니다.

---

## 1. 영상 목적

| 항목 | 내용 |
|------|------|
| 길이 | **5초** (Higgsfield Duration: 5s) |
| 역할 | 사이트 첫 진입 시 브랜드 무드 전달 → 랜딩 히어로로 핸드오프 |
| 핵심 메시지 | *좋아하는 음악의 감성이 국악으로 이어진다* — “다리(Bridge)” |
| 톤 | 미니멀, 고급스럽고 차분함. 과장된 K-드라마 느낌·네온·사이버펑크 지양 |

**랜딩 히어로 카피 (참고용, 영상에 넣지 않아도 됨)**

- KO: `내 플리에 국악 한 스푼.`
- EN: `That song's vibe, carried into gugak.`

---

## 2. 브랜드 비주얼 스펙 (랜딩과 맞출 것)

랜딩 페이지 마지막 프레임이 아래 색·무드와 **거의 동일**해야 전환이 매끄럽습니다.

| 토큰 | HEX | 용도 |
|------|-----|------|
| 배경 | `#FAFAF8` | 히어로 전체 배경 (크림 화이트) |
| 포인트 골드 | `#C8A96E` | 웨이브 라인, 악센트 |
| CTA 골드 | `#B8985E` | 버튼 (영상에는 생략 가능) |
| 텍스트 | `#1A1A1A` | 다크 그레이 (로고·타이포) |
| 서브 텍스트 | `#8A8680` | muted |

**랜딩 히어로 시각 요소:** 중앙의 은은한 **골드 곡선 웨이브**(SVG), 여백이 넉넉한 센터 정렬 레이아웃.

→ **5초 끝(4.5~5.0s)** 에는 화면이 `#FAFAF8` 단색 또는 아주 옅은 골드 웨이브만 남은 상태로 **페이드 아웃**하는 것이 이상적입니다.

---

## 3. Higgsfield 권장 설정

| 설정 | 권장값 | 이유 |
|------|--------|------|
| Duration | **5s** | 인트로 길이 |
| Aspect ratio | **16:9** | 데스크톱 랜딩 기준 (모바일 전용이면 9:16 별도 제작) |
| Resolution | 720p로 시안 → 확정 후 **1080p** | 크레딧·반복 생성 효율 |
| Preset | **General** (프롬프트 직접 제어) | 브랜드 맞춤 연출 |
| Multi-Shot | Off (단일 샷) | 5초 단일 흐름 유지 |
| Prompt enhancer | 첫 시도 Off → 결과 부족 시 On | 의도 희석 방지 |

---

## 4. 추천 컨셉 (3안)

### Option A — **골드 브릿지** (가장 추천, 랜딩 SVG 웨이브와 연결 쉬움)

서양 음악 파형(디지털 웨이브)이 중앙에서 국악 현악 실루엣(가야금 줄)으로 변환되고, 마지막에 크림 배경만 남음.

### Option B — **국악 클로즈업**

가야금 줄을 뜯는 손가락 클로즈업 → 황금빛 먼지/빛 입자 → 화면이 밝은 크림색으로 dissolve.

### Option C — **추상 잉크 + 사운드**

한국 전통 먹물 번짐이 골드 라인 웨이브로 변하며 화면 전체가 `#FAFAF8`로 페이드.

---

## 5. 메인 프롬프트 (Option A — 복사용)

Higgsfield에 **아래 영문 블록을 그대로** 붙여 넣으세요. (영상 모델은 영문 지시에 더 안정적으로 반응합니다.)

### 5-1. 단일 통합 프롬프트 (Text-to-Video)

```
Composition: wide cinematic 16:9, centered subject, vast negative space, clean minimal frame matching off-white cream background #FAFAF8.

Main subject: an elegant abstract bridge made of thin luminous gold lines (#C8A96E) connecting a soft digital audio waveform on the left to a subtle silhouette of Korean gayageum strings on the right. No text, no logo, no UI.

Action (5 seconds): 0.0–1.5s the gold bridge gently draws itself across the frame; 1.5–3.5s the waveform ripples and morphs into flowing string vibrations; 3.5–5.0s all elements softly dissolve into a calm empty cream-white screen (#FAFAF8), ending on a nearly blank bright background ready for a website hero.

Camera: slow dolly-in, eye level, minimal movement, stable horizon, shallow depth of field on gold lines only.

Mood: premium, serene, modern-meets-traditional, editorial, high-end music platform intro. Soft natural lighting, subtle film grain, muted warm palette, no neon, no cyberpunk, no crowded elements.

End frame: last 0.5 second must be predominantly solid cream white #FAFAF8 for seamless transition to a web landing page.
```

### 5-2. Negative prompt (있으면 입력)

```
text, logo, watermark, subtitle, UI, buttons, neon colors, cyberpunk, sci-fi HUD, fast cuts, shaky camera, horror, violence, crowded scene, dark black background, purple gradient, lens flare overload, distorted hands, extra fingers, low resolution, compression artifacts
```

---

## 6. 대안 프롬프트

### Option B — 가야금 클로즈업

```
Extreme close-up of gayageum silk strings being plucked by a graceful hand, warm soft side light, shallow depth of field, background blurred into warm cream tones #FAFAF8. Slow motion string vibration, tiny golden dust particles floating. Camera: gentle push-in, locked focus on strings. 0–3s intimate pluck and resonance; 3–5s image brightens and dissolves to empty off-white cream screen #FAFAF8. Cinematic, calm, premium Korean traditional music aesthetic. No text, no logo. End on blank cream background for website handoff.
```

### Option C — 먹물 → 골드 웨이브

```
Top-down abstract shot on textured cream paper #FAFAF8. Black ink wash spreads slowly, then transforms into thin elegant gold wave lines (#C8A96E) resembling sound waves and a bridge. Minimal composition, lots of whitespace. 0–2s ink bloom; 2–4s gold lines flow horizontally; 4–5s fade to pure cream white #FAFAF8. Slow camera drift, museum-quality lighting, serene and modern. No text, no characters. Final frame nearly empty for landing page transition.
```

---

## 7. 5초 타임라인 (Option A 기준)

| 시간 | 화면 | 연출 의도 |
|------|------|-----------|
| 0.0–1.5s | 좌: 은은한 디지털 웨이브 / 우: 가야금 실루엣 | “두 세계” 소개 |
| 1.5–3.5s | 중앙 골드 브릿지 완성, 웨이브가 현악 진동으로 morph | Sound**Bridge** |
| 3.5–4.5s | 요소들이 서서히 희미해짐 | 랜딩 등장 예고 |
| 4.5–5.0s | `#FAFAF8` 단색에 가깝게 | **랜딩 히어로와 동일 배경** |

---

## 8. Image-to-Video (선택)

랜딩 히어로 스크린샷 또는 아래 키워드로 **정지 이미지를 먼저 생성**한 뒤, Higgsfield Image-to-Video에 넣으면 마지막 프레임 일치율이 올라갑니다.

**이미지 생성용 프롬프트 (Midjourney / Higgsfield Image 등):**

```
Minimal website hero background, off-white cream #FAFAF8, single thin elegant gold curved line #C8A96E like a sound wave bridge, vast empty space center, no text, no UI, soft ambient light, editorial music platform aesthetic, 16:9
```

→ 생성 이미지를 Input Image로 두고, Video 프롬프트는 짧게:

```
The gold wave line gently animates and pulses like audio, then slowly fades out leaving only blank cream background #FAFAF8 by second 5. Slow dolly-in, serene, no text, no logo.
```

---

## 9. 랜딩 페이지 연결 체크리스트

영상을 웹에 붙일 때 아래를 확인하세요.

- [ ] **마지막 프레임** 배경색이 `#FAFAF8`에 가깝다
- [ ] 영상 끝에 **검은 화면·하드 컷** 없음 (페이드 아웃 또는 crossfade)
- [ ] 영상 위에 텍스트 없음 → 히어로 카피는 **랜딩에서만** 표시
- [ ] 오버레이 재생 시 랜딩 배경도 `#FAFAF8` (깜빡임 방지)
- [ ] `prefers-reduced-motion` 사용자에게는 영상 스킵 옵션 고려
- [ ] 모바일 9:16 별도 제작 시, 마지막 프레임 동일하게 크림 단색 유지

**권장 전환 방식 (구현 참고):**

1. 풀스크린 `<video>` 재생 (muted, `playsInline`)
2. `ended` 이벤트 또는 마지막 0.3s crossfade
3. 랜딩 히어로 표시 (이미 DOM에 있으면 opacity 전환만)

---

## 10. 사운드 (선택)

Higgsfield 모델에 오디오가 포함되면:

- **0–5s:** 가야금 단음 1~2회 + 아주 옅은 room tone
- 볼륨 낮게, 랜딩 BGM과 겹치지 않게 **영상만 muted**로 쓰는 것도 무방

사운드 프롬프트 예시:

```
Soft single gayageum pluck, warm reverb tail fading by 4s, no vocals, no drums, gentle and minimal
```

---

## 11. 빠른 복사 — 최소 프롬프트

시간이 없을 때는 이 한 줄만으로도 시안 가능합니다.

```
5-second minimal intro: gold sound-wave bridge #C8A96E connects digital waveform to gayageum strings on cream background #FAFAF8, slow dolly-in, serene premium mood, dissolves to empty cream screen at end, no text, no logo, 16:9 cinematic.
```

---

## 12. 제작 후 파일 권장 사양

| 항목 | 권장 |
|------|------|
| 포맷 | MP4 (H.264) |
| 길이 | 정확히 5.0s (필요 시 편집에서 tail 홀드) |
| 해상도 | 1920×1080 |
| 마지막 10프레임 | 크림 단색에 가깝게 보정 (FFmpeg / Premiere) |

마지막 프레임을 `#FAFAF8`로 0.2초 홀드하면 랜딩과 이어 붙이기가 더 쉽습니다.
