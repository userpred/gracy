from pydantic import BaseModel, validator


class ReceiptStakeInfo(BaseModel):
    user_address: str
    stake_ids: list[str]
    transaction_hash: str
