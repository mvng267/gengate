# GenGate Workflow Status

- Batch: 29
- Worker: pikamen
- Scope: khóa contract `/profiles` khi gửi `display_name: null` nhưng omit `bio` + `avatar_url`, hai field omit phải được preserve
- Status: pushed
- Files:
  - apps/backend-python/tests/test_profiles_api.py
  - WORKFLOW_STATUS.md
- Test:
  - `./.venv/bin/pytest -q tests/test_profiles_api.py -k "display_name_to_null_and_preserves_omitted_bio_and_avatar_url"` ✅ (1 passed)
  - `./.venv/bin/pytest -q tests/test_profiles_api.py` ✅ (45 passed)
- Git:
  - latest pushed: `e8e29fa` on `origin/main`
  - working tree: dirty (`TEAM_DISPATCH.md` dispatch update)
- Blocker: none
- Next: chờ scope kế tiếp của batch 29
