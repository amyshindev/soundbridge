# SoundBridge — 백엔드 개발 명세서

> 버전: v5.0
> 작성일: 2026.06.12
> 목적: Cursor / AI 작업 지시용
> 아키텍처: Hexagonal + Clean Architecture + DDD (Titanic 패턴 준용)
> 런타임: Python 3.12 / FastAPI / AsyncIO
> DB: NeonDB (PostgreSQL + pgvector) / Redis
> ORM: SQLAlchemy 2.0 async + psycopg3
> AI: Gemini API (gemini-1.5-flash + text-embedding-004, 768차원)
> 변경 이력:
>   v5.0 — asyncpg 직접 연결 → SQLAlchemy + psycopg3 복구
>           channel_binding=disable 로 NeonDB SCRAM 이슈 해결
>           Claude API → Gemini API 유지
>           임베딩 차원 768 유지

---

## 0. AI 작업 원칙

```
1. 이 문서는 작업 단위(Task)로 구성된다.
   각 Task는 독립적으로 실행 가능하며, 순서대로 진행한다.

2. Titanic 패턴을 그대로 따른다:
   - 프랙탈 네이밍: {domain}_{character}_{layer_suffix}
   - 레이어 의존 방향: Router → UseCase(Port) → Interactor → Repository(Port) → PgRepository
   - Domain은 FastAPI·SQLAlchemy·외부 API를 절대 import하지 않는다
   - Router는 PgRepository를 직접 import하지 않는다
   - Interactor는 ORM·HTTPException을 import하지 않는다

3. 코드 생성 규칙:
   - Python type hint 100% 적용
   - async/await 일관 사용 (sync 함수 금지)
   - Pydantic v2 사용
   - SQLAlchemy 2.0 async 스타일
   - 모든 ID는 UUID (str 아님)
   - 에러는 도메인 예외(DomainException) → HTTPException 변환은 Router에서만

4. 파일 생성 시:
   - 경로를 정확히 명시한다
   - TODO 주석으로 미구현 부분 명시
   - 각 파일 상단에 레이어·책임 주석 1줄 필수
   - 마일스톤 주석 표시: # [MVP] / # [v1.1] / # [v1.2]

5. 금지 사항:
   - Domain 레이어에서 외부 패키지 import
   - Router에서 직접 DB 쿼리
   - Interactor에서 HTTP 상태코드 처리
   - any 타입 사용 (Dict[str, Any] 최소화)
   - MVP에서 v1.1 이후 기능 구현 (TODO 주석으로 위치만 표시)
```

---

## 1. 프로젝트 구조

### Task 1-1. 디렉터리 생성

```
backend/
├── main.py
├── Dockerfile
├── requirements.txt
│
├── domain/
│   ├── __init__.py
│   ├── entities/
│   │   ├── __init__.py
│   │   ├── track_entity.py          GugakTrack 엔티티              [MVP]
│   │   ├── cue_point_entity.py      CuePoint 엔티티                [MVP]
│   │   ├── match_log_entity.py      MatchLog 엔티티                [MVP]
│   │   ├── sample_entity.py         Sample 엔티티                  [MVP]
│   │   ├── user_entity.py           User 엔티티                    [v1.1]
│   │   └── saved_track_entity.py    SavedTrack 엔티티              [v1.1]
│   └── value_objects/
│       ├── __init__.py
│       ├── track_id_vo.py           TrackId (UUID 래퍼)            [MVP]
│       ├── emotion_vo.py            EmotionTag (enum)              [MVP]
│       ├── jangdan_vo.py            Jangdan (enum + loop_unit 매핑)[MVP]
│       ├── instrument_vo.py         Instrument (enum)              [MVP]
│       ├── license_vo.py            PublicLicense (enum)           [MVP]
│       ├── bpm_vo.py                BpmRange (min/max 검증)        [MVP]
│       └── auth_provider_vo.py      AuthProvider (enum)            [v1.1]
│
├── app/
│   ├── __init__.py
│   ├── ports/
│   │   ├── __init__.py
│   │   ├── input/
│   │   │   ├── __init__.py
│   │   │   ├── track_discover_use_case.py                          [MVP]
│   │   │   ├── sample_create_use_case.py                           [MVP]
│   │   │   ├── create_preset_use_case.py   DISCOVER→CREATE 변환   [MVP]
│   │   │   ├── user_auth_use_case.py                               [v1.1]
│   │   │   └── event_kopis_use_case.py                             [v1.1]
│   │   └── output/
│   │       ├── __init__.py
│   │       ├── track_repository.py                                 [MVP]
│   │       ├── sample_repository.py                                [MVP]
│   │       ├── gemini_port.py                                      [MVP]
│   │       ├── embedding_port.py                                   [MVP]
│   │       ├── kopis_port.py                                       [v1.1]
│   │       └── email_port.py                                       [v1.1]
│   ├── use_cases/
│   │   ├── __init__.py
│   │   ├── track_discover_interactor.py                            [MVP]
│   │   ├── sample_create_interactor.py                             [MVP]
│   │   ├── create_preset_interactor.py                             [MVP]
│   │   ├── user_auth_interactor.py                                 [v1.1]
│   │   └── event_kopis_interactor.py                               [v1.1]
│   └── dtos/
│       ├── __init__.py
│       ├── track_discover_dto.py                                   [MVP]
│       ├── sample_create_dto.py                                    [MVP]
│       ├── create_preset_dto.py                                    [MVP]
│       └── user_auth_dto.py                                        [v1.1]
│
├── adapter/
│   ├── __init__.py
│   ├── inbound/
│   │   ├── __init__.py
│   │   └── api/
│   │       ├── __init__.py          soundbridge_router 집계        [MVP]
│   │       ├── v1/
│   │       │   ├── __init__.py
│   │       │   ├── track_discover_router.py                        [MVP]
│   │       │   ├── sample_create_router.py                         [MVP]
│   │       │   ├── user_auth_router.py                             [v1.1]
│   │       │   └── event_kopis_router.py                           [v1.1]
│   │       └── schemas/
│   │           ├── __init__.py
│   │           ├── track_discover_schema.py                        [MVP]
│   │           ├── sample_create_schema.py                         [MVP]
│   │           └── create_preset_schema.py                         [MVP]
│   └── outbound/
│       ├── __init__.py
│       ├── orm/
│       │   ├── __init__.py
│       │   ├── base_orm.py                                         [MVP]
│       │   ├── track_orm.py             gugak_tracks + embeddings  [MVP]
│       │   └── match_log_orm.py         match_logs                 [MVP]
│       ├── pg/
│       │   ├── __init__.py
│       │   ├── db_init.py                                          [MVP]
│       │   ├── track_discover_pg_repository.py                     [MVP]
│       │   └── sample_create_pg_repository.py                      [MVP]
│       ├── external/
│       │   ├── __init__.py
│       │   ├── gemini_adapter.py    감성 분석 + 설명 생성           [MVP]
│       │   └── embedding_adapter.py Gemini 임베딩 (768차원)        [MVP]
│       └── mappers/
│           ├── __init__.py
│           └── track_orm_mapper.py                                 [MVP]
│
├── dependencies/
│   ├── __init__.py
│   ├── track_discover_provider.py                                  [MVP]
│   └── sample_create_provider.py                                   [MVP]
│
└── infrastructure/
    ├── __init__.py
    ├── database.py          SQLAlchemy async engine + session      [MVP]
    ├── redis_client.py                                             [MVP]
    ├── settings.py                                                 [MVP]
    └── exceptions.py                                              [MVP]
```

**PowerShell 폴더 + `__init__.py` 일괄 생성:**

```powershell
# backend/ 안에서 실행
$dirs = @(
  "domain", "domain/entities", "domain/value_objects",
  "app", "app/ports", "app/ports/input", "app/ports/output",
  "app/use_cases", "app/dtos",
  "adapter", "adapter/inbound", "adapter/inbound/api",
  "adapter/inbound/api/v1", "adapter/inbound/api/schemas",
  "adapter/outbound", "adapter/outbound/orm",
  "adapter/outbound/pg", "adapter/outbound/external",
  "adapter/outbound/mappers",
  "dependencies", "infrastructure"
)
foreach ($d in $dirs) {
  New-Item -ItemType Directory -Force -Path $d | Out-Null
  New-Item -ItemType File -Force -Path "$d/__init__.py" | Out-Null
}
Write-Host "완료"
```

---

## 2. 공유 인프라

### Task 2-1. 환경변수 설정 [MVP]

**`infrastructure/settings.py`**

```python
# 레이어: Infrastructure — 환경변수 SSOT
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # Database [MVP]
    # 형식: postgresql+psycopg://user:pw@host/db?channel_binding=disable
    database_url: str
    redis_url: str = "redis://localhost:6379"

    # Gemini API [MVP]
    gemini_api_key: str
    gemini_model: str = "gemini-1.5-flash"
    gemini_embed_model: str = "models/text-embedding-004"

    # App [MVP]
    app_env: str = "development"
    frontend_url: str = "http://localhost:3000"

    # Auth [v1.1]
    secret_key: str = ""
    access_token_expire_minutes: int = 60 * 24
    email_verify_token_expire_hours: int = 24
    google_client_id: str = ""
    google_client_secret: str = ""

    # KOPIS [v1.1]
    kopis_api_key: str = ""

settings = Settings()
```

### Task 2-2. DB 연결 [MVP]

**`infrastructure/database.py`**

```python
# 레이어: Infrastructure — SQLAlchemy async engine + session (psycopg3)
from typing import AsyncGenerator
from sqlalchemy.ext.asyncio import (
    create_async_engine, AsyncSession, async_sessionmaker
)
from infrastructure.settings import settings

engine = create_async_engine(
    settings.database_url,
    pool_size=5,
    max_overflow=10,
    pool_pre_ping=True,    # NeonDB 슬립 대응
    echo=settings.app_env == "development",
)

AsyncSessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False,
)

async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
```

> **DATABASE_URL 형식 (psycopg3):**
> `postgresql+psycopg://user:pw@ep-xxx.neon.tech/soundbridge_db?channel_binding=disable`
>
> channel_binding=disable 이 NeonDB SCRAM-SHA-256 이슈 해결 핵심.
> asyncpg URL(`postgresql+asyncpg://`) 사용 금지.

### Task 2-3. Redis 연결 [MVP]

**`infrastructure/redis_client.py`**

```python
# 레이어: Infrastructure — Redis 캐시 클라이언트
import redis.asyncio as aioredis
from infrastructure.settings import settings

redis_client: aioredis.Redis = aioredis.from_url(
    settings.redis_url,
    encoding="utf-8",
    decode_responses=True,
)

CACHE_TTL = {
    "discover_result": 3600,   # 1시간
    "popular_tracks":  600,    # 10분
    "track_detail":    3600,   # 1시간
}
```

### Task 2-4. 공통 예외 [MVP]

**`infrastructure/exceptions.py`**

```python
# 레이어: Infrastructure — 도메인 공통 예외 (HTTP 무관)

class SoundBridgeException(Exception):
    """SoundBridge 도메인 기본 예외"""

# [MVP]
class TrackNotFoundException(SoundBridgeException): ...
class GeminiApiException(SoundBridgeException): ...
class EmbeddingException(SoundBridgeException): ...

# [v1.1]
class UserNotFoundException(SoundBridgeException): ...
class UserAlreadyExistsException(SoundBridgeException): ...
class InvalidCredentialsException(SoundBridgeException): ...
class EmailNotVerifiedException(SoundBridgeException): ...
class TokenExpiredException(SoundBridgeException): ...
class TokenInvalidException(SoundBridgeException): ...
class SavedTrackNotFoundException(SoundBridgeException): ...
class EmailSendException(SoundBridgeException): ...
```

### Task 2-5. ORM Base + db_init [MVP]

**`adapter/outbound/orm/base_orm.py`**

```python
# 레이어: Outbound — SQLAlchemy DeclarativeBase
from sqlalchemy.orm import DeclarativeBase

class Base(DeclarativeBase):
    pass
```

**`adapter/outbound/pg/db_init.py`**

```python
# 레이어: Outbound — startup 시 테이블 + pgvector 확장 생성
from sqlalchemy import text
from adapter.outbound.orm.base_orm import Base
from infrastructure.database import engine
from adapter.outbound.orm import track_orm, match_log_orm
# [v1.1] user_orm, saved_track_orm, download_log_orm

async def create_soundbridge_tables() -> None:
    async with engine.begin() as conn:
        await conn.execute(text("CREATE EXTENSION IF NOT EXISTS vector"))
        await conn.run_sync(Base.metadata.create_all)
    print("✅ SoundBridge 테이블 초기화 완료")
```

---

## 3. Domain 레이어

### Task 3-1. Value Objects [MVP]

**`domain/value_objects/jangdan_vo.py`**

```python
# 레이어: Domain — 장단 VO (loop_unit_beats 매핑 포함)
from enum import Enum
from dataclasses import dataclass

class JangdanType(str, Enum):
    JAJINMORI = "자진모리"   # 12박
    JUNGMORI  = "중모리"     # 12박
    GUTGEORI  = "굿거리"     # 12박
    HWIMORI   = "휘모리"     # 4박
    SEMACHI   = "세마치"     # 6박
    EOTMORI   = "엇모리"     # 10박

JANGDAN_LOOP_UNITS: dict[JangdanType, int] = {
    JangdanType.JAJINMORI: 12,
    JangdanType.JUNGMORI:  12,
    JangdanType.GUTGEORI:  12,
    JangdanType.HWIMORI:    4,
    JangdanType.SEMACHI:    6,
    JangdanType.EOTMORI:   10,
}

@dataclass(frozen=True)
class Jangdan:
    type: JangdanType

    @property
    def loop_unit_beats(self) -> int:
        return JANGDAN_LOOP_UNITS[self.type]
```

**`domain/value_objects/emotion_vo.py`**

```python
# 레이어: Domain — 감성 태그 VO
from enum import Enum

class EmotionTag(str, Enum):
    JOYFUL   = "신남"
    LYRICAL  = "서정"
    GRAND    = "웅장"
    SAD      = "슬픔"
    MYSTICAL = "신비"
    CALM     = "차분"

EMOTION_TAG_EN: dict[EmotionTag, str] = {
    EmotionTag.JOYFUL:   "Joyful",
    EmotionTag.LYRICAL:  "Lyrical",
    EmotionTag.GRAND:    "Grand",
    EmotionTag.SAD:      "Melancholic",
    EmotionTag.MYSTICAL: "Mystical",
    EmotionTag.CALM:     "Calm",
}
```

**`domain/value_objects/instrument_vo.py`**

```python
# 레이어: Domain — 악기 VO
from enum import Enum

class Instrument(str, Enum):
    GAYAGEUM = "가야금"
    JANGGU   = "장구"
    DAEGEUM  = "대금"
    HAEGEUM  = "해금"
    GEOMUNGO = "거문고"
    PIRI     = "피리"
    AJAENG   = "아쟁"
    SOGEUM   = "소금"
    PANSORI  = "판소리"
    OTHER    = "기타"
```

**`domain/value_objects/license_vo.py`**

```python
# 레이어: Domain — 공공누리 라이선스 VO
from enum import Enum

class PublicLicense(str, Enum):
    KOGL_1 = "KOGL_1"   # 출처표시 (상업 가능)
    KOGL_2 = "KOGL_2"   # 출처표시+상업금지

LICENSE_EN_LABEL: dict[PublicLicense, str] = {
    PublicLicense.KOGL_1: "CC-BY (Commercial OK)",
    PublicLicense.KOGL_2: "CC-BY-NC (Attribution Only)",
}
LICENSE_IS_COMMERCIAL: dict[PublicLicense, bool] = {
    PublicLicense.KOGL_1: True,
    PublicLicense.KOGL_2: False,
}
```

### Task 3-2. GugakTrack 엔티티 [MVP]

**`domain/entities/track_entity.py`**

```python
# 레이어: Domain — GugakTrack 핵심 엔티티 (프레임워크 무관)
from dataclasses import dataclass
from uuid import UUID
from domain.value_objects.emotion_vo import EmotionTag
from domain.value_objects.jangdan_vo import Jangdan
from domain.value_objects.instrument_vo import Instrument
from domain.value_objects.license_vo import PublicLicense, LICENSE_IS_COMMERCIAL, LICENSE_EN_LABEL

@dataclass
class CuePoint:
    time_sec: float
    label: str       # "A" | "B" | "C"
    emotion: str

@dataclass
class GugakTrack:
    id: UUID
    title: str
    artist: str
    instrument: Instrument
    jangdan: Jangdan
    emotion_tags: list[EmotionTag]
    bpm: int
    cue_points: list[CuePoint]
    audio_url: str
    public_license: PublicLicense
    description_ko: str
    description_en: str

    @property
    def loop_unit_beats(self) -> int:
        return self.jangdan.loop_unit_beats

    @property
    def is_commercial(self) -> bool:
        return LICENSE_IS_COMMERCIAL[self.public_license]

    @property
    def license_label_en(self) -> str:
        return LICENSE_EN_LABEL[self.public_license]

    @property
    def primary_emotion(self) -> EmotionTag | None:
        return self.emotion_tags[0] if self.emotion_tags else None
```

---

## 4. Application 레이어

### Task 4-1. Output Ports

**`app/ports/output/gemini_port.py`** [MVP]

```python
# 레이어: Application — Gemini API 아웃바운드 포트
from abc import ABC, abstractmethod
from app.dtos.track_discover_dto import EmotionAnalysisResult, MatchExplanation
from domain.entities.track_entity import GugakTrack

class GeminiPort(ABC):

    @abstractmethod
    async def analyze_emotion(
        self, user_input: str, lang: str
    ) -> EmotionAnalysisResult: ...

    @abstractmethod
    async def explain_match(
        self, user_input: str, tracks: list[GugakTrack], lang: str
    ) -> list[MatchExplanation]: ...
```

**`app/ports/output/embedding_port.py`** [MVP]

```python
# 레이어: Application — 임베딩 아웃바운드 포트
from abc import ABC, abstractmethod
from uuid import UUID

class EmbeddingPort(ABC):

    @abstractmethod
    async def embed_text(self, text: str) -> list[float]:
        """텍스트 → 768차원 벡터 (Gemini text-embedding-004)"""
        ...

    @abstractmethod
    async def find_similar_tracks(
        self,
        query_vector: list[float],
        top_k: int = 3,
        filters: dict | None = None,
    ) -> list[UUID]: ...
```

**`app/ports/output/track_repository.py`** [MVP]

```python
# 레이어: Application — TrackRepository 아웃바운드 포트
from abc import ABC, abstractmethod
from uuid import UUID
from domain.entities.track_entity import GugakTrack

class TrackRepository(ABC):

    @abstractmethod
    async def find_by_id(self, track_id: UUID) -> GugakTrack | None: ...

    @abstractmethod
    async def find_by_ids(self, track_ids: list[UUID]) -> list[GugakTrack]: ...

    @abstractmethod
    async def find_popular(self, limit: int = 6) -> list[GugakTrack]: ...

    @abstractmethod
    async def find_with_filters(
        self,
        instruments: list[str] | None,
        jangdans: list[str] | None,
        emotions: list[str] | None,
        bpm_min: int | None,
        bpm_max: int | None,
        loop_unit: int | None,
        license_type: str | None,
        limit: int = 50,
        offset: int = 0,
    ) -> tuple[list[GugakTrack], int]: ...

    @abstractmethod
    async def save_match_log(
        self, input_text: str, matched_track_id: UUID, similarity_score: float
    ) -> None: ...
```

### Task 4-2. Input Ports

**`app/ports/input/track_discover_use_case.py`** [MVP]

```python
from abc import ABC, abstractmethod
from app.dtos.track_discover_dto import DiscoverCommand, DiscoverResult

class TrackDiscoverUseCase(ABC):

    @abstractmethod
    async def discover(self, command: DiscoverCommand) -> DiscoverResult: ...

    @abstractmethod
    async def get_popular_tracks(self, limit: int = 6) -> list: ...

    @abstractmethod
    async def get_track_detail(self, track_id: str) -> DiscoverResult: ...  # [v1.2]
```

**`app/ports/input/create_preset_use_case.py`** [MVP]

```python
# 레이어: Application — DISCOVER→CREATE 프리셋 URL 변환 포트
from abc import ABC, abstractmethod
from app.dtos.create_preset_dto import CreatePresetCommand, CreatePresetResult

class CreatePresetUseCase(ABC):

    @abstractmethod
    def build_preset_url(self, command: CreatePresetCommand) -> CreatePresetResult: ...
```

### Task 4-3. DTOs

**`app/dtos/track_discover_dto.py`** [MVP]

```python
# 레이어: Application — DISCOVER 유스케이스 DTO
from dataclasses import dataclass, field
from uuid import UUID

@dataclass
class DiscoverCommand:
    input_text: str
    lang: str = "ko"

@dataclass
class EmotionAnalysisResult:
    emotions: list[str]
    mood: str
    instrument_hints: list[str]
    embed_text: str

@dataclass
class MatchExplanation:
    track_id: UUID
    score: float
    explanation_ko: str
    explanation_en: str

@dataclass
class TrackResult:
    track_id: UUID
    title: str
    artist: str
    instrument: str
    jangdan: str
    emotion_tags: list[str]
    bpm: int
    loop_unit_beats: int
    cue_points: list[dict]
    audio_url: str
    license_type: str
    license_label_en: str
    description_ko: str
    description_en: str
    score: float | None = None
    explanation_ko: str | None = None
    explanation_en: str | None = None
    preset_url: str | None = None   # DISCOVER→CREATE 연결

@dataclass
class DiscoverResult:
    tracks: list[TrackResult]
    input_summary: str
```

**`app/dtos/create_preset_dto.py`** [MVP]

```python
# 레이어: Application — DISCOVER→CREATE 프리셋 변환 DTO
from dataclasses import dataclass
from uuid import UUID

@dataclass
class CreatePresetCommand:
    track_id: UUID
    instrument: str
    emotion: str
    bpm: int

@dataclass
class CreatePresetResult:
    instrument: str
    emotion: str
    bpm_min: int
    bpm_max: int
    query_string: str
    full_url: str
```

### Task 4-4. Interactors

**`app/use_cases/create_preset_interactor.py`** [MVP]

```python
# 레이어: Application — DISCOVER→CREATE 프리셋 URL 변환 (순수 로직)
from app.ports.input.create_preset_use_case import CreatePresetUseCase
from app.dtos.create_preset_dto import CreatePresetCommand, CreatePresetResult

class CreatePresetInteractor(CreatePresetUseCase):

    BPM_MARGIN    = 20
    BPM_MIN_FLOOR = 60
    BPM_MAX_CEIL  = 200

    def build_preset_url(self, command: CreatePresetCommand) -> CreatePresetResult:
        bpm_min = max(self.BPM_MIN_FLOOR, command.bpm - self.BPM_MARGIN)
        bpm_max = min(self.BPM_MAX_CEIL,  command.bpm + self.BPM_MARGIN)

        params: dict[str, str] = {}
        if command.instrument:
            params["instrument"] = command.instrument
        if command.emotion:
            params["emotion"] = command.emotion
        params["bpm_min"] = str(bpm_min)
        params["bpm_max"] = str(bpm_max)

        query_string = "&".join(f"{k}={v}" for k, v in params.items())
        return CreatePresetResult(
            instrument=command.instrument,
            emotion=command.emotion,
            bpm_min=bpm_min,
            bpm_max=bpm_max,
            query_string=query_string,
            full_url=f"/create?{query_string}",
        )
```

**`app/use_cases/track_discover_interactor.py`** [MVP]

```python
# 레이어: Application — DISCOVER 유스케이스 오케스트레이션
import hashlib, json
from app.ports.input.track_discover_use_case import TrackDiscoverUseCase
from app.ports.output.track_repository import TrackRepository
from app.ports.output.gemini_port import GeminiPort
from app.ports.output.embedding_port import EmbeddingPort
from app.dtos.track_discover_dto import DiscoverCommand, DiscoverResult, TrackResult
from app.dtos.create_preset_dto import CreatePresetCommand
from app.use_cases.create_preset_interactor import CreatePresetInteractor
from infrastructure.exceptions import TrackNotFoundException

class TrackDiscoverInteractor(TrackDiscoverUseCase):

    def __init__(
        self,
        track_repo: TrackRepository,
        gemini: GeminiPort,
        embedding: EmbeddingPort,
        redis=None,
    ):
        self._track_repo = track_repo
        self._gemini     = gemini
        self._embedding  = embedding
        self._redis      = redis
        self._preset     = CreatePresetInteractor()

    async def discover(self, command: DiscoverCommand) -> DiscoverResult:
        # 1. 캐시 확인
        cache_key = f"sb:discover:{hashlib.md5(f'{command.input_text}:{command.lang}'.encode()).hexdigest()}"
        if self._redis:
            cached = await self._redis.get(cache_key)
            if cached:
                return DiscoverResult(**json.loads(cached))

        # 2. Gemini 감성 분석
        emotion = await self._gemini.analyze_emotion(command.input_text, command.lang)

        # 3. 임베딩 → pgvector 유사도 검색
        query_vec = await self._embedding.embed_text(emotion.embed_text)
        track_ids = await self._embedding.find_similar_tracks(query_vec, top_k=3)

        # 4. 트랙 상세 조회
        tracks = await self._track_repo.find_by_ids(track_ids)

        # 5. 매칭 설명 생성
        explanations = await self._gemini.explain_match(command.input_text, tracks, command.lang)

        # 6. 매칭 로그 저장 (실패 무시)
        for track, exp in zip(tracks, explanations):
            try:
                await self._track_repo.save_match_log(command.input_text, track.id, exp.score)
            except Exception:
                pass

        # 7. 결과 조립 (preset_url 포함)
        track_results = []
        for track, exp in zip(tracks, explanations):
            preset = self._preset.build_preset_url(CreatePresetCommand(
                track_id=track.id,
                instrument=track.instrument.value,
                emotion=track.primary_emotion.value if track.primary_emotion else "",
                bpm=track.bpm,
            ))
            track_results.append(TrackResult(
                track_id=track.id,
                title=track.title,
                artist=track.artist,
                instrument=track.instrument.value,
                jangdan=track.jangdan.type.value,
                emotion_tags=[e.value for e in track.emotion_tags],
                bpm=track.bpm,
                loop_unit_beats=track.loop_unit_beats,
                cue_points=[{"time_sec": c.time_sec, "label": c.label, "emotion": c.emotion}
                             for c in track.cue_points],
                audio_url=track.audio_url,
                license_type=track.public_license.value,
                license_label_en=track.license_label_en,
                description_ko=track.description_ko,
                description_en=track.description_en,
                score=exp.score,
                explanation_ko=exp.explanation_ko,
                explanation_en=exp.explanation_en,
                preset_url=preset.full_url,
            ))

        result = DiscoverResult(
            tracks=track_results,
            input_summary=f'"{command.input_text}" 와 감성이 닮은 국악',
        )

        # 8. 캐시 저장 (1시간)
        if self._redis:
            await self._redis.setex(cache_key, 3600, json.dumps(result.__dict__, default=str))

        return result

    async def get_popular_tracks(self, limit: int = 6) -> list:
        return await self._track_repo.find_popular(limit)

    async def get_track_detail(self, track_id: str) -> DiscoverResult:
        # [v1.2]
        from uuid import UUID
        track = await self._track_repo.find_by_id(UUID(track_id))
        if not track:
            raise TrackNotFoundException(track_id)
        return DiscoverResult(tracks=[], input_summary="")
```

---

## 5. Outbound Adapter

### Task 5-1. ORM 모델 [MVP]

**`adapter/outbound/orm/track_orm.py`**

```python
# 레이어: Outbound — gugak_tracks + track_embeddings + match_logs ORM
from sqlalchemy import Column, String, Integer, Text, TIMESTAMP, ARRAY
from sqlalchemy.dialects.postgresql import UUID, JSONB
from pgvector.sqlalchemy import Vector
from adapter.outbound.orm.base_orm import Base
import uuid

class GugakTrackOrm(Base):
    __tablename__ = "gugak_tracks"

    id                  = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    title               = Column(String(200), nullable=False)
    artist              = Column(String(100), default="")
    instrument          = Column(String(50), default="")
    jangdan             = Column(String(50), default="")
    emotion_tags        = Column(ARRAY(Text), default=[])
    bpm                 = Column(Integer, default=0)
    loop_unit_beats     = Column(Integer, default=0)
    cue_points          = Column(JSONB, default=[])
    audio_url           = Column(Text, default="")
    public_license_type = Column(String(20), default="KOGL_1")
    description_ko      = Column(Text, default="")
    description_en      = Column(Text, default="")
    created_at          = Column(TIMESTAMP(timezone=True))

class TrackEmbeddingOrm(Base):
    __tablename__ = "track_embeddings"

    track_id         = Column(UUID(as_uuid=True), primary_key=True)
    embedding_vector = Column(Vector(768))      # Gemini text-embedding-004 = 768차원
    created_at       = Column(TIMESTAMP(timezone=True))

class MatchLogOrm(Base):
    __tablename__ = "match_logs"

    id               = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    input_text       = Column(Text)
    matched_track_id = Column(UUID(as_uuid=True))
    similarity_score = Column(String(20))
    created_at       = Column(TIMESTAMP(timezone=True))
```

### Task 5-2. ORM Mapper [MVP]

**`adapter/outbound/mappers/track_orm_mapper.py`**

```python
# 레이어: Outbound — ORM Record → Domain Entity 변환
from adapter.outbound.orm.track_orm import GugakTrackOrm
from domain.entities.track_entity import GugakTrack, CuePoint
from domain.value_objects.emotion_vo import EmotionTag
from domain.value_objects.jangdan_vo import Jangdan, JangdanType
from domain.value_objects.instrument_vo import Instrument
from domain.value_objects.license_vo import PublicLicense

class TrackOrmMapper:

    def to_entity(self, orm: GugakTrackOrm) -> GugakTrack:
        try:
            instrument = Instrument(orm.instrument)
        except ValueError:
            instrument = Instrument.OTHER

        try:
            jangdan_type = JangdanType(orm.jangdan)
        except ValueError:
            jangdan_type = JangdanType.JAJINMORI

        try:
            license_type = PublicLicense(orm.public_license_type)
        except ValueError:
            license_type = PublicLicense.KOGL_1

        emotion_tags = []
        for tag in (orm.emotion_tags or []):
            try:
                emotion_tags.append(EmotionTag(tag))
            except ValueError:
                pass

        cue_points = [
            CuePoint(
                time_sec=c["time_sec"],
                label=c["label"],
                emotion=c["emotion"],
            )
            for c in (orm.cue_points or [])
        ]

        return GugakTrack(
            id=orm.id,
            title=orm.title or "",
            artist=orm.artist or "",
            instrument=instrument,
            jangdan=Jangdan(type=jangdan_type),
            emotion_tags=emotion_tags,
            bpm=orm.bpm or 0,
            cue_points=cue_points,
            audio_url=orm.audio_url or "",
            public_license=license_type,
            description_ko=orm.description_ko or "",
            description_en=orm.description_en or "",
        )
```

### Task 5-3. PgRepository [MVP]

**`adapter/outbound/pg/track_discover_pg_repository.py`**

```python
# 레이어: Outbound — TrackRepository + EmbeddingPort SQLAlchemy 구현
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, text
from uuid import UUID
from datetime import datetime, timezone
from app.ports.output.track_repository import TrackRepository
from app.ports.output.embedding_port import EmbeddingPort
from adapter.outbound.orm.track_orm import GugakTrackOrm, MatchLogOrm, TrackEmbeddingOrm
from adapter.outbound.mappers.track_orm_mapper import TrackOrmMapper
from domain.entities.track_entity import GugakTrack

class TrackDiscoverPgRepository(TrackRepository, EmbeddingPort):

    def __init__(self, session: AsyncSession):
        self._session = session
        self._mapper  = TrackOrmMapper()

    async def find_by_id(self, track_id: UUID) -> GugakTrack | None:
        result = await self._session.execute(
            select(GugakTrackOrm).where(GugakTrackOrm.id == track_id)
        )
        row = result.scalar_one_or_none()
        return self._mapper.to_entity(row) if row else None

    async def find_by_ids(self, track_ids: list[UUID]) -> list[GugakTrack]:
        result = await self._session.execute(
            select(GugakTrackOrm).where(GugakTrackOrm.id.in_(track_ids))
        )
        rows = result.scalars().all()
        id_order = {tid: i for i, tid in enumerate(track_ids)}
        return sorted(
            [self._mapper.to_entity(r) for r in rows],
            key=lambda t: id_order.get(t.id, 999)
        )

    async def find_popular(self, limit: int = 6) -> list[GugakTrack]:
        result = await self._session.execute(
            select(GugakTrackOrm).order_by(GugakTrackOrm.created_at.desc()).limit(limit)
        )
        return [self._mapper.to_entity(r) for r in result.scalars().all()]

    async def find_with_filters(
        self,
        instruments: list[str] | None = None,
        jangdans: list[str] | None = None,
        emotions: list[str] | None = None,
        bpm_min: int | None = None,
        bpm_max: int | None = None,
        loop_unit: int | None = None,
        license_type: str | None = None,
        limit: int = 50,
        offset: int = 0,
    ) -> tuple[list[GugakTrack], int]:
        query = select(GugakTrackOrm)
        if instruments:
            query = query.where(GugakTrackOrm.instrument.in_(instruments))
        if jangdans:
            query = query.where(GugakTrackOrm.jangdan.in_(jangdans))
        if emotions:
            query = query.where(GugakTrackOrm.emotion_tags.overlap(emotions))
        if bpm_min is not None:
            query = query.where(GugakTrackOrm.bpm >= bpm_min)
        if bpm_max is not None:
            query = query.where(GugakTrackOrm.bpm <= bpm_max)
        if loop_unit is not None:
            query = query.where(GugakTrackOrm.loop_unit_beats == loop_unit)
        if license_type:
            query = query.where(GugakTrackOrm.public_license_type == license_type)

        total = await self._session.scalar(
            select(text("count(*)")).select_from(query.subquery())
        )
        result = await self._session.execute(query.limit(limit).offset(offset))
        return [self._mapper.to_entity(r) for r in result.scalars().all()], total or 0

    async def save_match_log(
        self, input_text: str, matched_track_id: UUID, similarity_score: float
    ) -> None:
        log = MatchLogOrm(
            input_text=input_text,
            matched_track_id=matched_track_id,
            similarity_score=str(similarity_score),
            created_at=datetime.now(timezone.utc),
        )
        self._session.add(log)

    # EmbeddingPort 구현
    async def embed_text(self, text: str) -> list[float]:
        # GeminiEmbeddingAdapter에서 처리 — 여기서는 호출 안 됨
        raise NotImplementedError

    async def find_similar_tracks(
        self, query_vector: list[float], top_k: int = 3, filters: dict | None = None
    ) -> list[UUID]:
        vector_str = "[" + ",".join(map(str, query_vector)) + "]"
        result = await self._session.execute(
            text("""
                SELECT track_id
                FROM track_embeddings
                ORDER BY embedding_vector <=> CAST(:vec AS vector)
                LIMIT :k
            """),
            {"vec": vector_str, "k": top_k}
        )
        return [row[0] for row in result.fetchall()]
```

### Task 5-4. Gemini 어댑터 [MVP]

**`adapter/outbound/external/gemini_adapter.py`**

```python
# 레이어: Outbound — Gemini API GeminiPort 구현
import json
import google.generativeai as genai
from app.ports.output.gemini_port import GeminiPort
from app.dtos.track_discover_dto import EmotionAnalysisResult, MatchExplanation
from domain.entities.track_entity import GugakTrack
from infrastructure.settings import settings
from infrastructure.exceptions import GeminiApiException

genai.configure(api_key=settings.gemini_api_key)

EMOTION_ANALYSIS_PROMPT = """
당신은 음악 감성 분석 전문가입니다.
사용자가 좋아하는 음악 정보를 분석해 국악 매칭에 필요한 감성 키워드를 추출하세요.

입력: {user_input}

다음 JSON 형식으로만 응답하세요 (마크다운 코드블록 없이 JSON만):
{{
  "emotions": ["감성1", "감성2"],
  "mood": "전반적 분위기",
  "instrument_hints": ["악기1"],
  "embed_text": "임베딩 생성용 정제 텍스트 (한국어, 2-3문장)"
}}
"""

MATCH_EXPLANATION_PROMPT = """
사용자가 '{user_input}'을(를) 좋아한다고 했습니다.
아래 국악 트랙이 왜 감성적으로 비슷한지 한국어와 영어로 각각 1-2문장 설명하세요.

트랙: {track_title} ({instrument}, {jangdan})
감성: {emotion_tags}

JSON 형식으로만 응답 (마크다운 없이):
{{"ko": "한국어 설명", "en": "English explanation", "score": 0.95}}
"""

def _parse_json(text: str) -> dict:
    """마크다운 코드블록 제거 후 JSON 파싱"""
    t = text.strip()
    if t.startswith("```"):
        t = t.split("```")[1]
        if t.startswith("json"):
            t = t[4:]
    return json.loads(t.strip())

class GeminiAdapter(GeminiPort):

    def __init__(self):
        self._model = genai.GenerativeModel(settings.gemini_model)

    async def analyze_emotion(self, user_input: str, lang: str) -> EmotionAnalysisResult:
        try:
            response = self._model.generate_content(
                EMOTION_ANALYSIS_PROMPT.format(user_input=user_input)
            )
            data = _parse_json(response.text)
            return EmotionAnalysisResult(
                emotions=data["emotions"],
                mood=data["mood"],
                instrument_hints=data["instrument_hints"],
                embed_text=data["embed_text"],
            )
        except Exception as e:
            raise GeminiApiException(f"감성 분석 실패: {e}")

    async def explain_match(
        self, user_input: str, tracks: list[GugakTrack], lang: str
    ) -> list[MatchExplanation]:
        explanations = []
        for track in tracks:
            try:
                response = self._model.generate_content(
                    MATCH_EXPLANATION_PROMPT.format(
                        user_input=user_input,
                        track_title=track.title,
                        instrument=track.instrument.value,
                        jangdan=track.jangdan.type.value,
                        emotion_tags=", ".join(e.value for e in track.emotion_tags),
                    )
                )
                data = _parse_json(response.text)
                explanations.append(MatchExplanation(
                    track_id=track.id,
                    score=float(data.get("score", 0.9)),
                    explanation_ko=data["ko"],
                    explanation_en=data["en"],
                ))
            except Exception:
                explanations.append(MatchExplanation(
                    track_id=track.id, score=0.0,
                    explanation_ko="", explanation_en="",
                ))
        return explanations
```

### Task 5-5. Gemini 임베딩 어댑터 [MVP]

**`adapter/outbound/external/embedding_adapter.py`**

```python
# 레이어: Outbound — Gemini 임베딩 EmbeddingPort 구현 (768차원)
import google.generativeai as genai
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from uuid import UUID
from app.ports.output.embedding_port import EmbeddingPort
from infrastructure.settings import settings

genai.configure(api_key=settings.gemini_api_key)

class GeminiEmbeddingAdapter(EmbeddingPort):

    def __init__(self, session: AsyncSession):
        self._session = session

    async def embed_text(self, text: str) -> list[float]:
        result = genai.embed_content(
            model=settings.gemini_embed_model,
            content=text,
        )
        return result["embedding"]  # 768차원

    async def find_similar_tracks(
        self,
        query_vector: list[float],
        top_k: int = 3,
        filters: dict | None = None,
    ) -> list[UUID]:
        vector_str = "[" + ",".join(map(str, query_vector)) + "]"
        result = await self._session.execute(
            text("""
                SELECT track_id
                FROM track_embeddings
                ORDER BY embedding_vector <=> CAST(:vec AS vector)
                LIMIT :k
            """),
            {"vec": vector_str, "k": top_k}
        )
        return [row[0] for row in result.fetchall()]
```

---

## 6. Inbound Adapter

### Task 6-1. Router 집계 [MVP]

**`adapter/inbound/api/__init__.py`**

```python
# 레이어: Inbound — 라우터 집계
from fastapi import APIRouter
from adapter.inbound.api.v1 import track_discover_router, sample_create_router
# [v1.1] user_auth_router, event_kopis_router

soundbridge_router = APIRouter()

soundbridge_router.include_router(
    track_discover_router.router,
    prefix="/soundbridge/discover",
    tags=["DISCOVER"],
)
soundbridge_router.include_router(
    sample_create_router.router,
    prefix="/soundbridge/create",
    tags=["CREATE"],
)
```

### Task 6-2. Schemas [MVP]

**`adapter/inbound/api/schemas/track_discover_schema.py`**

```python
from pydantic import BaseModel, Field
from uuid import UUID

class DiscoverRequestSchema(BaseModel):
    input: str = Field(..., min_length=1, max_length=200)
    lang: str = Field(default="ko", pattern="^(ko|en)$")

class CuePointSchema(BaseModel):
    time_sec: float
    label: str
    emotion: str

class TrackResponseSchema(BaseModel):
    id: UUID
    title: str
    artist: str
    instrument: str
    jangdan: str
    emotion_tags: list[str]
    bpm: int
    loop_unit_beats: int
    cue_points: list[CuePointSchema]
    audio_url: str
    license_type: str
    license_label_en: str
    description_ko: str
    description_en: str
    score: float | None = None
    explanation_ko: str | None = None
    explanation_en: str | None = None
    preset_url: str | None = None

class DiscoverResponseSchema(BaseModel):
    tracks: list[TrackResponseSchema]
    input_summary: str

class SampleFilterSchema(BaseModel):
    instruments: list[str] | None = None
    jangdans: list[str] | None = None
    emotions: list[str] | None = None
    bpm_min: int | None = Field(None, ge=40, le=300)
    bpm_max: int | None = Field(None, ge=40, le=300)
    loop_unit: int | None = None
    license: str | None = None
    limit: int = Field(default=50, le=100)
    offset: int = Field(default=0, ge=0)
```

### Task 6-3. Routers [MVP]

**`adapter/inbound/api/v1/track_discover_router.py`**

```python
# 레이어: Inbound — DISCOVER HTTP 엔드포인트
from fastapi import APIRouter, Depends, HTTPException
from adapter.inbound.api.schemas.track_discover_schema import (
    DiscoverRequestSchema, DiscoverResponseSchema, TrackResponseSchema,
)
from app.ports.input.track_discover_use_case import TrackDiscoverUseCase
from app.dtos.track_discover_dto import DiscoverCommand
from dependencies.track_discover_provider import get_track_discover_use_case
from infrastructure.exceptions import TrackNotFoundException, GeminiApiException

router = APIRouter()

@router.post("", response_model=DiscoverResponseSchema)
async def discover_gugak(
    body: DiscoverRequestSchema,
    use_case: TrackDiscoverUseCase = Depends(get_track_discover_use_case),
) -> DiscoverResponseSchema:
    try:
        result = await use_case.discover(
            DiscoverCommand(input_text=body.input, lang=body.lang)
        )
        return DiscoverResponseSchema(
            tracks=[
                TrackResponseSchema(
                    id=t.track_id,
                    title=t.title,
                    artist=t.artist,
                    instrument=t.instrument,
                    jangdan=t.jangdan,
                    emotion_tags=t.emotion_tags,
                    bpm=t.bpm,
                    loop_unit_beats=t.loop_unit_beats,
                    cue_points=t.cue_points,
                    audio_url=t.audio_url,
                    license_type=t.license_type,
                    license_label_en=t.license_label_en,
                    description_ko=t.description_ko,
                    description_en=t.description_en,
                    score=t.score,
                    explanation_ko=t.explanation_ko,
                    explanation_en=t.explanation_en,
                    preset_url=t.preset_url,
                )
                for t in result.tracks
            ],
            input_summary=result.input_summary,
        )
    except GeminiApiException:
        raise HTTPException(status_code=503, detail="AI 서비스 일시 오류")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/popular", response_model=list[TrackResponseSchema])
async def get_popular_tracks(
    limit: int = 6,
    use_case: TrackDiscoverUseCase = Depends(get_track_discover_use_case),
):
    return await use_case.get_popular_tracks(limit)
```

---

## 7. Dependencies (Composition Root)

### Task 7-1. Provider 패턴 [MVP]

**`dependencies/track_discover_provider.py`**

```python
# 레이어: Dependencies — 유일한 DI 조립 지점
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession
from infrastructure.database import get_db
from infrastructure.redis_client import redis_client
from adapter.outbound.pg.track_discover_pg_repository import TrackDiscoverPgRepository
from adapter.outbound.external.gemini_adapter import GeminiAdapter
from adapter.outbound.external.embedding_adapter import GeminiEmbeddingAdapter
from app.use_cases.track_discover_interactor import TrackDiscoverInteractor
from app.use_cases.create_preset_interactor import CreatePresetInteractor
from app.ports.input.track_discover_use_case import TrackDiscoverUseCase
from app.ports.input.create_preset_use_case import CreatePresetUseCase

async def get_track_discover_use_case(
    db: AsyncSession = Depends(get_db),
) -> TrackDiscoverUseCase:
    return TrackDiscoverInteractor(
        track_repo=TrackDiscoverPgRepository(session=db),
        gemini=GeminiAdapter(),
        embedding=GeminiEmbeddingAdapter(session=db),
        redis=redis_client,
    )

def get_create_preset_use_case() -> CreatePresetUseCase:
    return CreatePresetInteractor()
```

---

## 8. main.py [MVP]

```python
# FastAPI 진입점
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from adapter.inbound.api import soundbridge_router
from adapter.outbound.pg.db_init import create_soundbridge_tables
from infrastructure.settings import settings

@asynccontextmanager
async def lifespan(app: FastAPI):
    await create_soundbridge_tables()
    yield

app = FastAPI(
    title="SoundBridge API",
    version="5.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[settings.frontend_url, "http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(soundbridge_router, prefix="/api")

@app.get("/health")
async def health():
    return {"status": "ok"}

@app.get("/health/db")
async def health_db():
    from infrastructure.database import engine
    from sqlalchemy import text
    async with engine.connect() as conn:
        await conn.execute(text("SELECT 1"))
    return {"status": "db connected"}
```

---

## 9. requirements.txt

```
# [MVP]
fastapi==0.111.0
uvicorn[standard]==0.29.0
sqlalchemy[asyncio]==2.0.23
psycopg[asyncio]==3.1.19
alembic==1.13.1
pgvector==0.2.5
pydantic==2.7.1
pydantic-settings==2.2.1
google-generativeai==0.7.0
redis==5.0.4
python-dotenv==1.0.1
httpx==0.27.0

# [v1.1]
python-jose[cryptography]>=3.3.0
bcrypt>=4.1.0
```

---

## 10. 환경변수 (.env)

```bash
# DB — psycopg3 + channel_binding=disable (NeonDB SCRAM 이슈 해결)
DATABASE_URL=postgresql+psycopg://user:pw@ep-xxx.neon.tech/soundbridge_db?channel_binding=disable

# Redis
REDIS_URL=redis://redis:6379

# AI
GEMINI_API_KEY=
GUGAK_API_KEY=

# App
APP_ENV=development
FRONTEND_URL=http://localhost:3000

# [v1.1]
SECRET_KEY=
KOPIS_API_KEY=
```

> **핵심**: `postgresql+psycopg://` + `?channel_binding=disable`
> asyncpg URL(`postgresql+asyncpg://`) 절대 사용 금지

---

## 11. Dockerfile

```dockerfile
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
```

---

## 12. API 엔드포인트

```
[DISCOVER]  /api/soundbridge/discover
  POST   /          감성 매칭 검색 (preset_url 포함)          [MVP]
  GET    /popular   인기 트랙 목록                            [MVP]
  GET    /{id}      트랙 상세                                 [v1.2]

[CREATE]    /api/soundbridge/create
  GET    /samples   샘플 목록 (악기·장단·감성·BPM·루프 필터) [MVP]

[AUTH]      /api/soundbridge/auth                             [v1.1]
[SAVED]     /api/soundbridge/saved                           [v1.1]
[EVENTS]    /api/soundbridge/events                          [v1.1]
```

---

## 13. 구현 순서 (Phase별)

### MVP

```
Phase 1 — 기반
  Task 1-1  폴더 + __init__.py 생성 (PowerShell 스크립트)
  Task 2-1  infrastructure/settings.py
  Task 2-2  infrastructure/database.py
  Task 2-3  infrastructure/redis_client.py
  Task 2-4  infrastructure/exceptions.py
  Task 2-5  adapter/outbound/orm/base_orm.py
            adapter/outbound/pg/db_init.py
  → docker compose up → /health/db 확인

Phase 2 — Domain
  Task 3-1  Value Objects (4개)
  Task 3-2  GugakTrack Entity
  → python -c "from domain.entities.track_entity import GugakTrack; print('OK')"

Phase 3 — Application Core
  Task 4-1  Output Ports (gemini_port, embedding_port, track_repository)
  Task 4-2  Input Ports (track_discover_use_case, create_preset_use_case)
  Task 4-3  DTOs
  Task 4-4  Interactors (create_preset 먼저, 그 다음 track_discover)

Phase 4 — DISCOVER 핵심
  Task 5-1  ORM 모델 (track_orm.py)
  Task 5-2  ORM Mapper
  Task 5-3  TrackDiscoverPgRepository
  Task 5-4  GeminiAdapter
  Task 5-5  GeminiEmbeddingAdapter
  Task 6-1  Router 집계
  Task 6-2  Schemas
  Task 6-3  track_discover_router
  Task 7-1  Provider
  → POST /api/soundbridge/discover 동작 확인

Phase 5 — CREATE 샘플 필터
  SampleCreatePgRepository + sample_create_router
  → GET /api/soundbridge/create/samples 동작 확인
```

---

## 14. MVP 체크리스트

```
아키텍처
  □ Domain 레이어에 SQLAlchemy·외부 패키지 import 없음
  □ Router가 PgRepository 직접 import 없음
  □ Interactor가 ORM·HTTPException import 없음

DB
  □ DATABASE_URL에 postgresql+psycopg:// + ?channel_binding=disable 확인
  □ /health/db 정상 응답
  □ db_init 실행 후 NeonDB에 테이블 3개 생성 확인
  □ pgvector 768차원 임베딩 저장 확인

DISCOVER→CREATE 연결
  □ POST /discover 응답에 preset_url 포함 확인
  □ CreatePresetInteractor bpm_min/bpm_max 계산 확인

배포
  □ .env .gitignore 등록
  □ requirements.txt에 asyncpg 없음 확인
  □ CORS 설정 확인
```
