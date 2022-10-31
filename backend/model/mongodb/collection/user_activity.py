from datetime import datetime
from pymongo import IndexModel, ASCENDING
from model.mongodb.collection import PyObjectId
from model.mongodb.collection import Model, Schema


class UserActivity(Model):

    class UserActivitySchema(Schema):
        """Community Schema"""
        user_address: str = None  # 유저 지갑 주소
        status: str = None  # 스테이킹 상태
        amount: str = None  # 스테이킹 볼륨
        start_date: datetime = None  # 스테이킹 시작일
        end_date: datetime = None  # 스테이킹 종료일
        claimed_date: datetime = None  # 스테이킹 청구일
        period: int = None  # 스테이킹 기간
        stake_id: int = None  # 스테이킹 사인 아이디
        transaction_hash: str = None  # 트랜잭션 해시

    def indexes(self) -> list:
        return [
            IndexModel([('name', ASCENDING)])
        ]

    async def insert_one(self, document: dict):
        document = UserActivity.UserActivitySchema(**document)
        return await self.col.insert_one(
            document.dict(exclude={'id'})
        )

    async def find_range_by_date(
        self, user_address: str,
        start_date: datetime,
        end_datetime: datetime
    ):
        return await (self.col.find(
            {
                "user_address": user_address,
                "created_at": {
                    "$gte": start_date,
                    "$lt": end_datetime
                }
            }
        ).sort([("created_at", -1)])).to_list(None)

    async def check_duplicated(
        self, stake_id: int,
        status: str
    ):
        return await self.col.find_one(
            {
                "stake_id": stake_id,
                "status": status
            }
        )
