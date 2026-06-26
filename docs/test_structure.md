backend/
├── main.py
├── requirements.txt
├── soundbridge/            # 애플리케이션 본체
│   ├── adapter/
│   ├── app/
│   └── ...
└── tests/                  # 👈 여기에 위치!
    ├── conftest.py         # pytest 공통 설정 및 피스처(Fixture)
    ├── domain/             # domain 레이어 테스트
    │   └── test_track_entity.py
    ├── app/                # use_cases(비즈니스 로직) 테스트
    │   └── test_track_discover_interactor.py
    └── adapter/            # inbound(API)/outbound(인프라) 테스트
        └── inbound/
            └── test_track_discover_router.py