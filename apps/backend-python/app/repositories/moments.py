from app.models.moments import Moment
from app.repositories.base import BaseRepository


class MomentRepository(BaseRepository[Moment]):
    def __init__(self) -> None:
        super().__init__(Moment)


moment_repository = MomentRepository()
