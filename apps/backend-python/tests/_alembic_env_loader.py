import importlib.util
from pathlib import Path
import sys
import types
from types import ModuleType


def load_alembic_env_module(module_name: str = "test_alembic_env_module") -> ModuleType:
    project_root = Path(__file__).resolve().parents[1]
    env_path = project_root / "alembic" / "env.py"

    class _DummyContext:
        config = types.SimpleNamespace(
            config_file_name=None,
            get_main_option=lambda *_args, **_kwargs: "sqlite+pysqlite:///:memory:",
            set_main_option=lambda *_args, **_kwargs: None,
            config_ini_section="alembic",
            get_section=lambda *_args, **_kwargs: {},
        )

        def is_offline_mode(self) -> bool:
            return True

        def configure(self, *args, **kwargs) -> None:
            return None

        class _Txn:
            def __enter__(self):
                return self

            def __exit__(self, exc_type, exc, tb):
                return False

        def begin_transaction(self):
            return self._Txn()

        def run_migrations(self) -> None:
            return None

    alembic_stub = types.ModuleType("alembic")
    alembic_stub.context = _DummyContext()

    old_alembic = sys.modules.get("alembic")
    old_app_models = sys.modules.get("app.models")
    old_app_models_base = sys.modules.get("app.models.base")

    sys.modules["alembic"] = alembic_stub

    app_models_stub = types.ModuleType("app.models")
    app_models_stub.all_models = object()
    sys.modules["app.models"] = app_models_stub

    app_models_base_stub = types.ModuleType("app.models.base")
    app_models_base_stub.Base = types.SimpleNamespace(metadata=object())
    sys.modules["app.models.base"] = app_models_base_stub

    try:
        spec = importlib.util.spec_from_file_location(module_name, env_path)
        if spec is None or spec.loader is None:
            raise RuntimeError("Unable to create module spec for alembic env")

        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module
    finally:
        if old_alembic is not None:
            sys.modules["alembic"] = old_alembic
        else:
            sys.modules.pop("alembic", None)

        if old_app_models is not None:
            sys.modules["app.models"] = old_app_models
        else:
            sys.modules.pop("app.models", None)

        if old_app_models_base is not None:
            sys.modules["app.models.base"] = old_app_models_base
        else:
            sys.modules.pop("app.models.base", None)
