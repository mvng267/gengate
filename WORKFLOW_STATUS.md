# GenGate Workflow Status

- Batch: 28
- Worker: team
- Scope: profiles contract locking — upsert create path + invalid UUID 422 + long display_name validation
- Status: pushed_partial_sync
- Files:
  - apps/backend-python/app/schemas/profiles.py
  - apps/backend-python/tests/test_profiles_api.py
  - WORKFLOW_STATUS.md
- Test:
  - `./.venv/bin/pytest -q tests/test_profiles_api.py -k "display_name_exceeds_max_length or accepts_very_long_bio"` ✅ (2 passed)
  - `./.venv/bin/pytest -q tests/test_profiles_api.py` ✅ (43 passed)
- Git:
  - latest pushed before this sync: `d8f79e3`
  - repo code currently prepared for next commit/push
- Blocker: none
- Next: chốt lane `pikachu` (display_name max_length), push sync, rồi quyết định có khép batch 28 hay mở scope kế tiếp
