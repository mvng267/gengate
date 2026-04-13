#!/usr/bin/env sh
set -eu

cd /app/apps/backend-python

if [ ! -d .venv ]; then
  python -m venv .venv
fi

. .venv/bin/activate
pip install --upgrade pip >/tmp/backend-pip-upgrade.log 2>&1 || cat /tmp/backend-pip-upgrade.log
pip install -e .[dev] >/tmp/backend-pip-install.log 2>&1 || (cat /tmp/backend-pip-install.log && exit 1)

python - <<'PY'
from app.models.base import Base
from app.core.db import get_database_engine
engine = get_database_engine()
Base.metadata.create_all(bind=engine)
print('database schema ensured')
PY

exec uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
