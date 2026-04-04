import uuid
from typing import Generic, TypeVar

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.base import Base

ModelType = TypeVar("ModelType", bound=Base)


class BaseRepository(Generic[ModelType]):
    def __init__(self, model: type[ModelType]) -> None:
        self.model = model

    def get(self, db: Session, entity_id: uuid.UUID) -> ModelType | None:
        return db.get(self.model, entity_id)

    def list(self, db: Session, limit: int = 100, offset: int = 0) -> list[ModelType]:
        statement = select(self.model).offset(offset).limit(limit)
        return list(db.scalars(statement).all())

    def create(self, db: Session, **data: object) -> ModelType:
        entity = self.model(**data)
        db.add(entity)
        db.flush()
        db.refresh(entity)
        return entity

    def update(self, db: Session, entity: ModelType, **data: object) -> ModelType:
        for key, value in data.items():
            setattr(entity, key, value)
        db.add(entity)
        db.flush()
        db.refresh(entity)
        return entity

    def delete(self, db: Session, entity: ModelType) -> None:
        db.delete(entity)
        db.flush()
