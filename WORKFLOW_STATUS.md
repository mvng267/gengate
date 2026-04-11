# GenGate Workflow Status

- Batch: 29
- Worker: pikamen
- Scope: khóa contract `/profiles` khi gửi `avatar_url: null` để clear avatar nhưng vẫn preserve `display_name` + `bio` khi omit
- Status: pushed
- Files:
  - apps/backend-python/tests/test_profiles_api.py
  - WORKFLOW_STATUS.md
- Test:
  - `./.venv/bin/pytest -q tests/test_profiles_api.py -k "clears_avatar_with_null_and_preserves_omitted_text_fields"` ✅ (1 passed)
  - `./.venv/bin/pytest -q tests/test_profiles_api.py` ✅ (44 passed)
- Git:
  - latest pushed: `09e365f` on `origin/main`
  - working tree: dirty (ready to commit)
- Blocker: none
- Next: commit + push scope batch 29 đầu tiên
