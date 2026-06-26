# SoundBridge Backend 구조

`backend/` 는 **헥사고날(포트·어댑터) 아키텍처**를 따릅니다.  
진입점은 `main.py`이고, 비즈니스 패키지는 `soundbridge/` 아래에 있습니다.

```
backend/
├── main.py                 # FastAPI 앱, lifespan, /health
├── requirements.txt
├── Dockerfile
├── alembic.ini
├── alembic/                # DB 마이그레이션 (Alembic)
│   ├── env.py
│   └── versions/
│       └── 001_init_soundbridge_tables.py
├── scripts/                # 운영·데이터 적재 CLI (API와 분리)
└── soundbridge/            # 애플리케이션 본체
    ├── adapter/            # Inbound / Outbound 어댑터
    ├── app/                # 유스케이스, DTO, 포트
    ├── dependencies/       # FastAPI DI (provider)
    ├── domain/             # 엔티티, 값 객체
    └── infrastructure/     # DB, Redis, 설정, 시크릿
```

---

## 레이어 개요

| 레이어 | 경로 | 역할 |
|--------|------|------|
| **Inbound** | `adapter/inbound/` | HTTP API, (예약) gRPC·WebSocket |
| **Application** | `app/` | 유스케이스, DTO, 입·출력 포트 인터페이스 |
| **Domain** | `domain/` | `GugakTrack` 등 도메인 모델·VO |
| **Outbound** | `adapter/outbound/` | PostgreSQL, Ollama, iTunes 등 외부 연동 |
| **Infrastructure** | `infrastructure/` | SQLAlchemy 엔진, 설정, 오디오 인덱스 |
| **DI** | `dependencies/` | 라우터 → 유스케이스 → 리포지토리 조립 |

의존 방향: **Inbound → App → Domain ← Outbound**, Infrastructure는 횡단 관심사.

---

## `soundbridge/` 상세

### `adapter/inbound/` — 외부 → 앱

```
adapter/inbound/
├── api/
│   ├── router_registry.py          # /discover, /create, /audio 라우터 mount
│   ├── schemas/                    # Pydantic 요청·응답 스키마
│   │   ├── track_discover_schema.py
│   │   ├── track_suggest_schema.py
│   │   ├── sample_create_schema.py
│   │   ├── create_preset_schema.py
│   │   └── track_response_schema.py
│   ├── v1/
│   │   ├── track_discover_router.py   # DISCOVER API
│   │   ├── sample_create_router.py    # CREATE API
│   │   └── audio_router.py            # 오디오 스트리밍
│   └── mappers/                       # HTTP 스키마 ↔ DTO
│       ├── track_discover_mapper.py
│       └── sample_create_mapper.py
├── grpc/v1/          # 스텁 (미구현)
└── websocket/v1/     # 스텁 (미구현)
```

### `app/` — 애플리케이션 코어

```
app/
├── constants/
│   ├── embedding_constants.py    # 임베딩 차원 등
│   ├── filter_constants.py
│   └── preset_constants.py
├── dtos/
│   ├── track_discover_dto.py
│   ├── sample_create_dto.py
│   └── create_preset_dto.py
├── ports/
│   ├── input/                      # 유스케이스 인터페이스
│   │   ├── track_discover_use_case.py
│   │   ├── sample_create_use_case.py
│   │   └── create_preset_use_case.py
│   └── output/                     # 리포지토리·외부 서비스 포트
│       ├── track_repository.py
│       ├── sample_repository.py
│       ├── embedding_port.py
│       └── gemini_port.py
└── use_cases/                      # 인터랙터 (비즈니스 흐름)
    ├── track_discover_interactor.py
    ├── sample_create_interactor.py
    └── create_preset_interactor.py
```

### `domain/` — 도메인 모델

```
domain/
├── entities/
│   ├── track_entity.py
│   ├── sample_entity.py
│   ├── cue_point_entity.py
│   └── match_log_entity.py
└── value_objects/
    ├── track_id_vo.py
    ├── instrument_vo.py
    ├── jangdan_vo.py
    ├── emotion_vo.py
    ├── bpm_vo.py
    └── license_vo.py
```

### `adapter/outbound/` — 앱 → 외부

```
adapter/outbound/
├── external/
│   ├── embedding_adapter.py      # Ollama nomic-embed-text (pgvector 검색)
│   ├── ollama_llm_adapter.py     # EXAONE 매칭 설명
│   ├── itunes_search_adapter.py  # DISCOVER 자동완성
│   └── gemini_adapter.py         # (레거시/보조)
├── orm/                          # SQLAlchemy 모델
│   ├── base_orm.py
│   ├── track_orm.py              # gugak_tracks (+ TM 메타 컬럼)
│   ├── jangdan_orm.py
│   ├── track_emotion_tag_orm.py
│   └── match_log_orm.py
├── pg/                           # PostgreSQL 리포지토리
│   ├── db_init.py                # 테이블 생성·시드
│   ├── tm_schema_ddl.py          # TM 컬럼 DDL
│   ├── schema_migrate.py
│   ├── track_discover_pg_repository.py
│   └── sample_create_pg_repository.py
├── mappers/
│   ├── track_orm_mapper.py       # ORM ↔ Entity
│   └── track_result_mapper.py    # Entity ↔ DTO
└── memory/
    └── in_memory_track_repository.py   # 테스트·폴백
```

### `infrastructure/` — 공통 인프라

```
infrastructure/
├── settings.py           # 환경 변수 (pydantic-settings)
├── config.py
├── database.py           # async SQLAlchemy 엔진
├── redis_client.py
├── secret_manager.py     # API 키·시크릿 로드
├── audio_file_resolver.py  # TM WAV 파일 인덱스·URL 해석
├── exceptions.py
└── base.py
```

### `dependencies/` — FastAPI Depends

```
dependencies/
├── track_discover_provider.py
├── sample_create_provider.py
└── create_preset_provider.py
```

---

## HTTP API (`/api` prefix)

`main.py` → `soundbridge_router` (`router_registry.py`)

| Prefix | 라우터 | 주요 엔드포인트 |
|--------|--------|-----------------|
| `/api/soundbridge/discover` | `track_discover_router` | `POST /` 감성 매칭, `GET /popular`, `GET /suggest` |
| `/api/soundbridge/create` | `sample_create_router` | `GET /samples` 필터·목록 |
| `/api/soundbridge/audio` | `audio_router` | 오디오 파일 서빙 |
| `/health`, `/health/db` | `main.py` | 헬스체크 |

---

## `scripts/` — 데이터·운영 CLI

API 서버와 별도로 `python scripts/<name>.py` 로 실행합니다.

| 스크립트 | 용도 |
|----------|------|
| `load_tm_tracks.py` | 국악음원(TM) JSON → `gugak_tracks` upsert |
| `embed_gugak_tracks.py` | 메타데이터 텍스트 → Ollama 임베딩 배치 |
| `tm_cue_points.py` | TM 라벨링 → A/B/C `cue_points` 변환 |
| `backfill_tm_cue_points.py` | `cue_points`만 DB 반영 |
| `purge_legacy_tracks.py` | `source_identifier IS NULL` 구 데이터 삭제 |
| `migrate_tm_schema.py` | TM 스키마 컬럼 마이그레이션 |
| `load_ai_data.py` | (레거시) AI/구 데이터 로드 |
| `check_schema.py` | 스키마 점검 |
| `check_models.py` | 모델·연결 점검 |
| `reset_neon_schema.py` | Neon DB 스키마 리셋 (개발용) |

---

## 주요 DB 테이블 (ORM 기준)

| 테이블 | ORM | 설명 |
|--------|-----|------|
| `gugak_tracks` | `GugakTrackOrm` | TM 573곡, `embedding`(768d), `cue_points`, `source_identifier` |
| `jangdan` | `JangdanOrm` | 장단명 · `loop_unit_beats` |
| `track_emotion_tags` | `TrackEmotionTagOrm` | 트랙별 감성 태그 |
| `match_logs` | `MatchLogOrm` | DISCOVER 검색 로그 |

TM 전용 컬럼(`genre_*`, `whole_emotions`, `jangdan_raw` 등)은 `tm_schema_ddl.py` 및 `load_tm_tracks.py`에서 관리합니다.

---

## 실행

```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

Docker: 프로젝트 루트 `docker compose up` (api + db + redis + frontend).

환경 변수는 `backend/.env` — `DATABASE_URL`, `OLLAMA_*`, `AUDIO_FILES_ROOT` 등 (`infrastructure/settings.py` 참고).

---

## 테스트 (`tests/`)

`docs/test_structure.md` 구조를 따릅니다.

```bash
cd backend
pip install -r requirements.txt
pytest
```

| 경로 | 대상 |
|------|------|
| `tests/conftest.py` | 공통 픽스처 (`sample_gugak_track`, mock repo 등) |
| `tests/domain/` | `GugakTrack` 엔티티 |
| `tests/app/` | `TrackDiscoverInteractor` |
| `tests/adapter/inbound/` | DISCOVER API 라우터 (의존성 override) |

설정: `pytest.ini` (`asyncio_mode = auto`, `pythonpath = .`).
