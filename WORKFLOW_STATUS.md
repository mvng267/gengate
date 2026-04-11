# GenGate Workflow Status

- Batch: 29
- Worker: pikamen
- Scope: khóa contract `/profiles` khi gửi `avatar_url: null` để clear avatar nhưng vẫn preserve `display_name` + `bio`
- Status: dispatched
- Files:
  - apps/backend-python/tests/test_profiles_api.py
  - WORKFLOW_STATUS.md
- Test:
  - baseline trước khi mở batch 29: `./.venv/bin/pytest -q tests/test_profiles_api.py` ✅ (43 passed)
- Git:
  - latest pushed: `09e365f` on `origin/main`
- Blocker: none
- Next: chờ run batch 29 scope đầu tiên từ `pikamen`
