# SoundBridge — UI 재설계용 제품·기능 명세서

> **문서 목적:** FlutterFlow, Figma, 외주 디자이너 등에게 전달하는 **제품·도메인·API 중심** 명세  
> **작성 기준:** 2026-06-28 백엔드 실구현 기준  
> **의도적으로 제외:** 기존 프론트엔드 구현, 컴포넌트명, 색상·폰트 등 현 UI 디자인 시스템

---

## 1. 한 줄 정의

**「좋아하는 음악을 입력하면, AI가 당신의 언어로 국악을 연결해 주는 플랫폼」**

- 서비스 URL: **soundbridge.site**
- 대상: 국악을 모르는 일반인·외국인 + 국악 샘플이 필요한 DJ·프로듀서
- 핵심 차별점: 장르가 다른 음악 간 **감성 구조**를 분석해 연결하고, **「왜 비슷한가」**를 한국어·영어로 설명

---

## 2. 왜 이 서비스인가

### 2.1 해결하려는 문제

| 대상 | Pain Point |
|------|------------|
| 일반인·MZ | 국악이 낯설고, 내가 쓰는 감성 언어로 설명된 적이 없음 |
| 외국인 | 국악 공공 음원은 많지만 접근·이해 경로가 없음 |
| DJ·프로듀서 | 저작권·BPM·루프 단위 정보가 부족해 DAW·CDJ 활용이 어려움 |
| 공통 | 감성적으로 마음에 든 뒤 **바로 창작으로 이어지는 흐름**이 없음 |

### 2.2 데이터·기회

| 데이터 | 출처 | 규모 | 용도 |
|--------|------|------|------|
| 국악 디지털 음원 | 국립국악원 | 전체 16,721건 (MVP ~500–600건) | 재생·다운로드·검색 |
| 국악 AI 학습데이터 | 한국문화정보원 | 5,729건 | 메타·감성 태그 |
| 디지털국악아카이브 | 국립국악원 | 6,000건+ | 악기·장단 메타 |

모든 음원은 **공공누리 1유형** 등 공개 라이선스. 출처 표시 시 활용 가능.

### 2.3 핵심 인사이트 (제품 스토리)

국악의 **장단**(자진모리·세마치 등)은 일정 박자가 반복되는 구조로, DJ가 CDJ에서 쓰는 **루프** 개념과 같다.  
→ **「국악은 이미 루프 음악」**이라는 관점을 서비스 전반의 언어로 사용할 수 있음.

---

## 3. 서비스 구조 — 두 모드 + 연결

```
┌─────────────────────────────────────────────────────────┐
│                    SoundBridge                           │
│                                                          │
│   DISCOVER                    CREATE                     │
│   (감성 발견)                  (샘플 라이브러리)          │
│        │                            ▲                    │
│        │  감성·악기·BPM 프리셋       │                    │
│        └────────────────────────────┘                    │
│              「이 분위기로 만들기」                       │
└─────────────────────────────────────────────────────────┘
```

| 모드 | 사용자 | 목표 |
|------|--------|------|
| **DISCOVER** | 일반인, 외국인, K-pop·팝 팬 | 익숙한 음악 입력 → 어울리는 국악 3곡 + 이유 설명 |
| **CREATE** | DJ, 프로듀서, 음악 제작자 | 필터로 국악 샘플 탐색 → 파형·CUE 확인 → WAV 다운로드 |
| **연결** | DISCOVER 사용자 | 감동한 트랙의 분위기를 CREATE 필터에 **즉시 이식** |

---

## 4. 페르소나 & 사용자 여정

### 4.1 페르소나 A — 국악 초보 MZ (한국어)

- **입력 예:** `뉴진스`, `아이유`, `재즈`, `비 오는 날 듣는 음악`
- **기대:** 「이 국악이 내가 아는 그 느낌이구나」를 **설명**과 함께 이해
- **여정:** 검색 → 결과 3장 카드 → 미리듣기 → 「이 분위기로 만들기」→ 샘플 탐색

### 4.2 페르소나 B — 외국인 K-culture 팬 (영어)

- **입력 예:** `Billie Eilish`, `lo-fi beats`, `Coldplay`
- **기대:** 영어 설명 + 재생만으로도 국악에 **감정적 다리**가 놓이는 경험
- **여정:** 영어 UI 또는 영어 설명 필드 활용 → 동일 DISCOVER 흐름

### 4.3 페르소나 C — DJ / 프로듀서

- **입력:** CREATE 탭 직접 진입 또는 DISCOVER에서 프리셋 유입
- **기대:** 악기·장단·BPM·루프 박수·저작권을 한눈에 보고 **DAW에 바로 투입**
- **여정:** 필터 → 샘플 리스트 → 파형·CUE·루프 배지 확인 → WAV 다운로드

---

## 5. 화면·기능 요구사항 (UI 구현 자유)

아래는 **반드시 담겨야 할 기능 단위**이다. 레이아웃·비주얼·컴포넌트 구성은 전면 재설계 가능.

### 5.1 글로벌

| ID | 기능 | 설명 |
|----|------|------|
| G-01 | 앱 셸 | DISCOVER / CREATE 모드 전환 (탭, 하단 네비, 사이드 등 자유) |
| G-02 | 언어 | MVP: 한국어 기본. 사용자 요청 `lang=ko\|en`에 따라 설명·요약 언어 분기 (UI 문자열 i18n은 v1.1) |
| G-03 | 오디오 재생 | 트랙 미리듣기. `audio_url`이 https면 그대로, 파일명이면 API 스트리밍 URL 조합 |
| G-04 | 로딩·에러 | DISCOVER AI 호출은 **수 초~최대 ~90초** 가능. 타임아웃·503·네트워크 오류 메시지 필요 |
| G-05 | 법적·출처 | 공공누리·데이터 출처 표기 영역 (푸터 또는 정보 페이지) |

### 5.2 DISCOVER 모드

| ID | 기능 | 설명 |
|----|------|------|
| D-01 | 검색 입력 | 자유 텍스트 (아티스트, 곡, 장르, 감성 문장). 1~200자 |
| D-02 | 발매곡 자동완성 | iTunes Search 기반. **1글자부터** 제안 목록 (곡명·아티스트·앨범아트) |
| D-03 | 감성 매칭 실행 | 입력 제출 → AI 파이프라인 → **국악 Top 3** 반환 |
| D-04 | 입력 요약 | 예: `"Billie Eilish" 와 감성이 닮은 국악` (`input_summary`) |
| D-05 | 결과 카드 (×3) | 제목, 연주자, 악기, 장단, BPM, 감성 태그, 매칭 점수, 설명, 미리듣기 |
| D-06 | 매칭 설명 | `explanation` — 왜 입력과 비슷한지 (KO/EN). `enrich=true` 시 LLM 생성 (느림·고품질) |
| D-07 | 감성 태그 | 태그 탭 시 CREATE로 이동 + 해당 감성 필터 적용 |
| D-08 | 「이 분위기로 만들기」 | `preset_url`로 CREATE 진입. 악기·감성·BPM 범위 자동 세팅 |
| D-09 | 빈 상태 (검색 전) | 인기 국악 트랙 목록 표시 (`/popular`) |
| D-10 | 빈 결과 | 매칭 없음 안내 + 재시도 |

### 5.3 CREATE 모드

| ID | 기능 | 설명 |
|----|------|------|
| C-01 | 필터 패널 | 악기, 장단, 감성, BPM 범위, 루프 박수, 저작권 유형 |
| C-02 | 프리셋 진입 | URL 쿼리로 필터 초기값 수신. 예: `instrument=가야금&emotion=서정&bpm_min=80&bpm_max=110` |
| C-03 | 프리셋 안내 | DISCOVER에서 넘어온 경우 「○○·△△ 분위기로 필터가 설정됐어요」류 안내 (닫기 가능, 필터는 유지) |
| C-04 | 샘플 리스트 | 필터 적용 결과 + 총 개수 `total` |
| C-05 | 샘플 카드 | 제목, 악기, 장단, BPM, 루프 박수, 저작권 배지, 감성 태그 |
| C-06 | 파형·CUE | 에너지 피크·감성 전환·루프 시작 등 **시간 구간 마커** 시각화 (`cue_points`) |
| C-07 | 루프 단위 표시 | 장단별 권장 박수 (예: 자진모리 → 12박) |
| C-08 | 저작권 배지 | `Commercial OK` / `Attribution Only` (영문 라벨) |
| C-09 | WAV 다운로드 | `audio_url`에서 파일 다운로드 |
| C-10 | 페이지네이션 | `limit`·`offset` 기반 (기본 50건, 최대 100건) |

### 5.4 DISCOVER → CREATE 연결 규칙

백엔드가 생성하는 프리셋 URL 형식:

```
/create?instrument={악기}&emotion={첫번째_감성태그}&bpm_min={max(60,bpm-20)}&bpm_max={min(200,bpm+20)}
```

- `instrument`·`emotion`이 없으면 쿼리에서 생략 가능
- BPM 마진: ±20, 하한 60, 상한 200

---

## 6. 도메인 용어집 (UI 카피·툴팁용)

| 용어 | 설명 | UI에 쓸 수 있는 한 줄 |
|------|------|------------------------|
| 국악 | 한국 전통음악 | Korean traditional music |
| 악기 | 가야금, 거문고, 대금, 해금, 피리, 아쟁, 장구, 소고 등 | |
| 장단 | 박자·리듬 틀 (자진모리, 중모리, 굿거리, 휘모리, 세마치, 엇모리) | 반복되는 리듬 패턴 |
| 감성 태그 | 신남·서정·웅장·슬픔·신비·차분 (6종) | 음악의 느낌 라벨 |
| 루프 단위 | 장단별 권장 반복 박수 | DJ 루프 포인트 힌트 |
| CUE | 파형 위 의미 구간 (A=에너지 피크, B=감성 해소, C=루프 시작 등) | |
| 공공누리 | 한국 공공저작물 라이선스 | KOGL_1 / KOGL_2 |

### 장단 ↔ 루프 박수 (백엔드 고정 매핑)

| 장단 | 권장 루프 박수 |
|------|----------------|
| 자진모리 | 12 |
| 중모리 | 12 |
| 굿거리 | 12 |
| 휘모리 | 4 |
| 세마치 | 6 |
| 엇모리 | 10 |

### CREATE 필터 — 악기 목록

`가야금`, `거문고`, `대금`, `해금`, `피리`, `아쟁`, `장구`, `소고`

### CREATE 필터 — 감성 목록

| KO | EN (참고) |
|----|-----------|
| 신남 | Joyful |
| 서정 | Lyrical |
| 웅장 | Grand |
| 슬픔 | Melancholic |
| 신비 | Mystical |
| 차분 | Calm |

### 저작권 표시

| 코드 | 영문 라벨 | 상업 이용 |
|------|-----------|-----------|
| KOGL_1 | CC-BY (Commercial OK) | 가능 |
| KOGL_2 | CC-BY-NC (Attribution Only) | 불가 |

---

## 7. AI·검색 동작 (UI가 알아야 할 것)

사용자에게 **「키워드 검색」이 아니라 「감성 번역」**임을 전달하는 것이 중요.

### 7.1 DISCOVER 파이프라인 (백엔드)

```
사용자 입력 (팝/K-pop/문장)
    → Cohere embed-v4.0 (search_query, 1536차원)
    → pgvector 코사인 유사도 Top 3
    → (옵션) K-EXAONE 매칭 설명 생성 (enrich=true)
    → 결과 + input_summary + preset_url
```

- **Top K = 3** (고정)
- 동일 제목 중복 방지 로직 있음
- Redis 캐시: 동일 입력 재검색 시 빠른 응답 (TTL 1시간)

### 7.2 자동완성 (발매곡)

- iTunes Search API (한국 스토어, API 키 불필요)
- DISCOVER 검색과 별개: **정식 발매곡 제목 선택**을 돕는 UX
- 선택 시 `display` 문자열(예: `아티스트 — 곡명`)을 DISCOVER 입력으로 사용 가능

### 7.3 응답 시간 가이드 (UX 설계용)

| 단계 | 체감 시간 |
|------|-----------|
| 자동완성 | ~0.5–2초 |
| DISCOVER (캐시 히트) | ~1–3초 |
| DISCOVER (캐시 미스, enrich=false) | ~5–30초 |
| DISCOVER (enrich=true, LLM 설명) | ~30–90초 (타임아웃 가능) |

**권장 UX:** 진행 표시, 단계별 메시지(「감성 분석 중…」「국악과 연결 중…」), 취소/재시도.

---

## 8. API 계약 (프론트 연동 SSOT)

Base URL 예: `https://{api-host}/api`  
Health: `GET /health` → `{ "status": "ok" }`

### 8.1 DISCOVER

#### `POST /soundbridge/discover`

**Request**
```json
{
  "input": "Billie Eilish",
  "lang": "ko",
  "enrich": true
}
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| input | string | O | 1–200자 |
| lang | `ko` \| `en` | X | 기본 `ko` |
| enrich | boolean | X | 기본 `false`. `true`면 LLM 매칭 설명 (느림) |

**Response**
```json
{
  "tracks": [ /* Track × 3 */ ],
  "input_summary": "\"Billie Eilish\" 와 감성이 닮은 국악"
}
```

**에러**
| HTTP | 의미 |
|------|------|
| 503 | AI 서비스 일시 오류 (EXAONE/임베딩) |
| 500 | 기타 서버 오류 |

#### `GET /soundbridge/discover/suggest?q={query}&limit=8`

발매곡 자동완성. `q` 1글자 이상.

**Response**
```json
{
  "suggestions": [
    {
      "id": "123456",
      "title": "곡명",
      "artist": "아티스트",
      "album": "앨범",
      "artwork_url": "https://...",
      "display": "아티스트 — 곡명"
    }
  ]
}
```

#### `GET /soundbridge/discover/popular?limit=6`

검색 전 추천 트랙 목록.

#### `GET /soundbridge/discover/{track_id}`

단일 트랙 상세 (향후 상세 페이지용).

---

### 8.2 CREATE

#### `GET /soundbridge/create/samples`

**Query parameters** (배열은 반복 키 또는 `?instruments=가야금&instruments=장구`)

| 파라미터 | 타입 | 설명 |
|----------|------|------|
| instruments | string[] | 악기 |
| genres | string[] | 장르 |
| jangdans | string[] | 장단 |
| emotions | string[] | 감성 |
| bpm_min | int | 40–300 |
| bpm_max | int | 40–300 |
| loop_unit | int | 루프 박수 |
| license | string | KOGL_1 / KOGL_2 |
| limit | int | 기본 50, 최대 100 |
| offset | int | 기본 0 |

**Response**
```json
{
  "tracks": [ /* Track */ ],
  "total": 42
}
```

---

### 8.3 AUDIO

#### `GET /soundbridge/audio/{filename}`

로컬/서버에 마운트된 원천 파일 스트리밍.  
프로덕션에서는 `audio_url`이 **R2 공개 HTTPS URL**일 수 있음 → 그 경우 이 엔드포인트 불필요.

---

### 8.4 Track 객체 (공통 스키마)

DISCOVER·CREATE·popular 공통:

| 필드 | 타입 | 설명 |
|------|------|------|
| id | UUID | 트랙 ID |
| title | string | 곡명 |
| artist | string | 연주자·출처 |
| instrument | string | 악기 |
| jangdan | string | 장단 |
| emotion_tags | string[] | 감성 태그 |
| bpm | int | BPM |
| loop_unit_beats | int | 권장 루프 박수 |
| cue_points | CuePoint[] | `{ time_sec, label, emotion }` |
| audio_url | string | 파일명 또는 https URL |
| license_type | string | KOGL_1 / KOGL_2 |
| license_label_en | string | 영문 저작권 라벨 |
| description_ko | string | 국악 설명 (한국어) |
| description_en | string | 설명 (영어, 있을 경우) |
| score | float? | DISCOVER 매칭 점수 (CREATE에서는 null) |
| explanation | string? | DISCOVER 매칭 이유 |
| preset_url | string? | CREATE 프리셋 경로 (예: `/create?instrument=...`) |

---

## 9. 콘텐츠·카피 방향 (디자인 브리프)

기존 UI와 무관하게, 새 UI에서 권장하는 **톤 & 매너**:

| 축 | 방향 |
|----|------|
| 감정 | 낯선 국악을 **두렵지 않게** — 친근·호기심 유발 |
| 비주얼 | 「귀엽다」= 유아적이 아니라 **따뜻·부드·접근 쉬움** (cute & cozy) |
| 언어 | 학술 용어 대신 **일상 감성어** 우선, 전문 용어는 툴팁 |
| DISCOVER | 마법·번역·연결 메타포 (「당신의 playlist 언어로 국악을 소개합니다」) |
| CREATE | 프로 도구이지만 **깔끔한 샘플 팩** 느낌 — Ableton/ Splice 참고 가능 |
| 브릿지 | DISCOVER→CREATE 버튼은 **행동 유도 최우선** CTA |

**피해야 할 인상:** 박물관 전시 UI, 정부 사이트 느낌, 과한 한옥 클리셰만으로 장식.

---

## 10. 마일스톤 — UI 범위

### MVP (지금 구현해야 할 화면)

- DISCOVER: 검색, 자동완성, 결과, 인기 트랙, 로딩/에러
- CREATE: 필터, 리스트, 샘플 상세(파형·CUE), 다운로드
- DISCOVER→CREATE 프리셋 연결
- 글로벌 오디오 재생
- 반응형 (모바일·데스크톱 — **데스크톱 완성도 우선**)

### v1.1 (와이어에만 표시 가능)

- 회원가입·저장·마이페이지
- UI 전체 KO/EN 토글
- KOPIS 공연 카드, 관광 체험 장소
- 트랙 상세 전용 페이지

### v2.0

- B2G·글로벌 확장

---

## 11. 비기능 요구사항

| 항목 | 요구 |
|------|------|
| 성능 | DISCOVER 로딩 상태 필수. 장시간 블로킹 UI 금지 |
| 접근성 | 키보드 자동완성 탐색, 재생 컨트롤 라벨 |
| SEO | 랜딩·DISCOVER 공유 URL (`?q=`) 고려 |
| 오프라인 | 미지원 |
| 보안 | API 키는 클라이언트에 노출 금지. 백엔드 프록시 |

---

## 부록 A. 와이어프레임 스케치용 화면 목록

Figma/FlutterFlow에서 **프레임 이름**으로 그대로 쓸 수 있도록 정리.  
`[MVP]` = 이번에 스케치 필수 · `[v1.1]` = 와이어에만 표시 가능

### A-1. 글로벌 · 셸

| ID | 프레임명 | 설명 | 주요 요소 |
|----|----------|------|-----------|
| WF-G01 | App Shell — Desktop `[MVP]` | 데스크톱 기본 레이아웃 | 로고, DISCOVER/CREATE 네비, 메인 영역, (하단) 미니 플레이어 슬롯 |
| WF-G02 | App Shell — Mobile `[MVP]` | 모바일 기본 레이아웃 | 상단 로고·탭, 메인, 하단 탭바 또는 FAB |
| WF-G03 | Global Audio Player — Collapsed `[MVP]` | 재생 중 축소 바 | 곡명, 재생/일시정지, 진행바, 닫기 |
| WF-G04 | Global Audio Player — Expanded `[MVP]` | 플레이어 확장 (선택) | 파형 또는 커버, CUE 힌트, 볼륨 |
| WF-G05 | Loading Overlay `[MVP]` | 전역 로딩 | 스피너 + 짧은 메시지 |
| WF-G06 | Error Toast / Banner `[MVP]` | 공통 에러 | 네트워크·503·재시도 버튼 |
| WF-G07 | Footer / About `[MVP]` | 출처·라이선스 | 공공누리, 국악원·문화정보원 크레딧 |

---

### A-2. DISCOVER 모드

| ID | 프레임명 | 진입 | 주요 요소 |
|----|----------|------|-----------|
| WF-D01 | DISCOVER — Home (검색 전) `[MVP]` | `/discover` | 히어로 카피, 검색창, 인기 트랙 그리드(6), 힌트 텍스트 |
| WF-D02 | DISCOVER — Autocomplete Open `[MVP]` | 검색창 포커스·입력 | iTunes 제안 리스트(앨범아트·아티스트·곡명), 키보드 ↑↓ |
| WF-D03 | DISCOVER — Autocomplete Empty `[MVP]` | 1글자+ 무일치 | 「일치하는 발매곡이 없습니다」 |
| WF-D04 | DISCOVER — Searching (Loading) `[MVP]` | 검색 제출 후 | 단계 메시지(감성 분석→연결), 취소(선택), 스켈레톤 카드×3 |
| WF-D05 | DISCOVER — Results `[MVP]` | `?q=` 성공 | 입력 요약, 초기화, 결과 카드×3 |
| WF-D06 | DISCOVER — Result Card (단일 확대) `[MVP]` | 카드 컴포넌트 | 제목·연주자·악기·장단·BPM·매칭%, 설명, 감성 칩, 재생, 「이 분위기로 만들기」 |
| WF-D07 | DISCOVER — Results Empty `[MVP]` | 결과 0건 | 안내 문구, 검색 예시, 다시 검색 |
| WF-D08 | DISCOVER — Error 503 `[MVP]` | AI 장애 | 아이콘, 「AI 일시 오류」, 재시도 |
| WF-D09 | DISCOVER — Error Timeout `[MVP]` | 90s 초과 | 「시간 초과」, 간격 두고 재시도 안내 |
| WF-D10 | DISCOVER — Error Network `[MVP]` | 오프라인 등 | 네트워크 확인 안내 |
| WF-D11 | DISCOVER — Shared Link `[MVP]` | 외부 `?q=` 유입 | WF-D04→D05와 동일 흐름 (딥링크 진입 표기) |

**DISCOVER 플로우 (프로토타입 연결)**

```
WF-D01 → WF-D02 → WF-D04 → WF-D05
                ↘ WF-D03
WF-D05 → WF-D06 내 CTA → WF-C02 (CREATE 프리셋)
WF-D05 → 감성 칩 탭 → WF-C03
```

---

### A-3. CREATE 모드

| ID | 프레임명 | 진입 | 주요 요소 |
|----|----------|------|-----------|
| WF-C01 | CREATE — Default `[MVP]` | `/create` | 필터 패널, 샘플 리스트, total 건수, 빈 필터 상태 |
| WF-C02 | CREATE — Preset Entry `[MVP]` | DISCOVER `preset_url` | WF-C01 + **프리셋 배너**(악기·감성·BPM 적용됨), 필터 pre-filled |
| WF-C03 | CREATE — Emotion Chip Entry `[MVP]` | `/create?emotion=서정` | 감성 필터만 활성 |
| WF-C04 | CREATE — Filters Applied `[MVP]` | 필터 변경 후 | 활성 칩·슬라이더, 결과 수 갱신 |
| WF-C05 | CREATE — Filters Empty Result `[MVP]` | 0건 | 조건 완화 제안, 필터 초기화 |
| WF-C06 | CREATE — Sample List Item `[MVP]` | 리스트 행 | 악기·장단·BPM·루프박수·저작권 배지·재생 버튼 |
| WF-C07 | CREATE — Sample Detail `[MVP]` | 행 탭/클릭 | 파형, CUE A/B/C 마커, 설명, 다운로드, 메타 전체 |
| WF-C08 | CREATE — Sample Detail (No CUE) `[MVP]` | cue 없는 트랙 | 파형만, CUE 영역 placeholder |
| WF-C09 | CREATE — Download Confirm `[MVP]` | 다운로드 탭 | 저작권 재확인, 파일명, 확인 |
| WF-C10 | CREATE — Pagination `[MVP]` | 50건+ | 더 보기 또는 offset 페이지네이션 |

**CREATE 필터 패널 (WF-C01 내 또는 WF-C11 분리 스케치)**

| ID | 프레임명 | 설명 |
|----|----------|------|
| WF-C11 | Filter Panel — Desktop `[MVP]` | 악기·장단·감성 멀티, BPM range, 루프 박수, 라이선스 |
| WF-C12 | Filter Panel — Mobile Sheet `[MVP]` | 바텀시트 또는 풀스크린 필터 |

---

### A-4. DISCOVER ↔ CREATE 브릿지

| ID | 프레임명 | 설명 |
|----|----------|------|
| WF-B01 | CTA — 「이 분위기로 만들기」 `[MVP]` | 결과 카드 내 버튼 강조 상태 (hover/active) |
| WF-B02 | Preset Banner `[MVP]` | CREATE 상단: 「가야금 · 서정 · BPM 80–110」+ 닫기 |
| WF-B03 | Transition (선택) | DISCOVER→CREATE 전환 시 짧은 안내 (스킵 가능) |

---

### A-5. 정적 · 정보 (최소)

| ID | 프레임명 | 설명 |
|----|----------|------|
| WF-S01 | Landing / Intro (선택) `[MVP]` | 첫 방문자용 한 화면 요약 → DISCOVER CTA |
| WF-S02 | Terms `[MVP]` | 이용약관 |
| WF-S03 | Privacy `[MVP]` | 개인정보처리방침 |

---

### A-6. v1.1 — 와이어에만 (점선 프레임)

| ID | 프레임명 | 설명 |
|----|----------|------|
| WF-V01 | Login / Sign Up `[v1.1]` | Google OAuth, 이메일 |
| WF-V02 | My Page `[v1.1]` | 저장 목록, 다운로드 이력 |
| WF-V03 | Track Detail Page `[v1.1]` | `/discover/{id}` 전용 |
| WF-V04 | Locale Toggle `[v1.1]` | KO/EN UI 전환 |
| WF-V05 | Related Performance (KOPIS) `[v1.1]` | DISCOVER 카드 하단 공연 |
| WF-V06 | Experience Place (관광) `[v1.1]` | 체험 장소 카드 |

---

### A-7. 스케치 우선순위 (최소 12프레임)

공모전·MVP 데모용 **꼭 그릴 것**:

1. WF-G01 · WF-G02 (셸)
2. WF-D01 · WF-D02 · WF-D04 · WF-D05 · WF-D06
3. WF-C01 · WF-C02 · WF-C07
4. WF-B01 · WF-B02
5. WF-G03

**데스크톱 먼저 → 모바일은 G02, C12, D02만 추가**해도 됨.

---

### A-8. 화면 ↔ API 매핑 (스케치 시 참고)

| 화면 | API |
|------|-----|
| WF-D01 | `GET /discover/popular` |
| WF-D02 | `GET /discover/suggest?q=` |
| WF-D04~D05 | `POST /discover` |
| WF-C01~C10 | `GET /create/samples?...` |
| WF-G03~G04 | `audio_url` 또는 `GET /audio/{filename}` |
| WF-V03 | `GET /discover/{track_id}` |

---

## 12. Figma / FlutterFlow 체크리스트

디자인·프로토타입 제출 시 포함 권장:

- [ ] DISCOVER — 검색 전 / 자동완성 열림 / 로딩 / 결과 3건 / 빈 결과 / 에러
- [ ] CREATE — 기본 / 필터 적용 / DISCOVER 프리셋 진입
- [ ] 샘플 카드 — CUE 마커 있는 파형 / 없는 경우
- [ ] 저작권 배지 2종
- [ ] 모바일·데스크톱 브레이크포인트 최소 2종
- [ ] 「이 분위기로 만들기」 CTA 강조 상태
- [ ] 인기 트랙 그리드 (검색 전 홈)

---

## 13. 참고 — 백엔드만 해당 (UI 선택 사항)

| 항목 | 비고 |
|------|------|
| 배포 | API: Railway, DB: Neon, 스토리지: Cloudflare R2 |
| LLM | K-EXAONE (Friendli AI) |
| 임베딩 | Cohere embed-v4.0, 1536차원 |
| 프론트 기술 | **본 문서에서 규정하지 않음** (Next.js, Flutter, FlutterFlow 등 자유) |

---

## 14. 문서 변경 이력

| 날짜 | 내용 |
|------|------|
| 2026-06-28 | UI 재설계용 제품 명세 초안. 기존 프론트·와이어프레임 디자인 토큰 제외 |
| 2026-06-28 | 부록 A: 와이어프레임 스케치용 화면 목록 추가 |
