# GenGate Docker Dev

## Start
```bash
docker compose -f docker-compose.dev.yml up --build
```

## Stop
```bash
docker compose -f docker-compose.dev.yml down
```

## URLs
- Web: http://localhost:3000
- Backend: http://localhost:8000
- Health: http://localhost:8000/health

## Notes
- This is a dev scaffold created for local MVP testing.
- Postgres/Redis are included.
- Backend schema is ensured at container boot using SQLAlchemy metadata `create_all()` for dev convenience.
- Storage env uses safe dummy values unless real object storage testing is needed.
