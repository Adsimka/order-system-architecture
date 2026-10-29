# ADR-0007: Cache-Aside для чтения профиля пользователя

- Status: Accepted
- Date: 2026-02-14
- Owners: Backend Team

## Context
API /users/{id} составляет до 35% нагрузки. P95 вырос до 420 мс из-за частых обращений к Postgres.
Требования:
- P95 <= 150 мс при 2k RPS
- данные могут быть нестрого актуальными в течение 30 секунд
  Ограничения:
- одна Postgres-инстанс на старте, без шардинга
- Redis уже используется в проекте

## Decision
Используем Cache-Aside:
- при GET /users/{id}: читаем Redis → при промахе читаем Postgres → пишем в Redis (TTL 30s)
- при UPDATE /users/{id}: обновляем Postgres и инвалидируем ключ в Redis
- ключи: user:{id}:profile
- защита от stampede: single-flight/locking на ключ (TTL lock 2s)

## Alternatives considered
1) Read-Through cache (встроенный провайдер) — сложнее контроль политики инвалидации и метрик.
2) Увеличить пул БД и тюнинг запросов — поможет частично, но не решит пики.
3) Полный отказ от кэша — не проходит по latency/SLO.

## Consequences
Pros:
- снижение нагрузки на БД и улучшение P95
- быстрый откат (можно отключить чтение из Redis флагом)

Cons / Risks:
- возможна устаревшая выдача до 30 секунд
- риск stampede при массовом истечении TTL → mitigations через single-flight
  Observability:
- метрики hit/miss, latency Redis, rate lock acquisitions
- алерт: miss-rate > 40% при росте RPS
  5.2 ADR: Outbox pattern для публикации событий