import asyncio
from datetime import datetime
from bson import ObjectId
from fastapi import APIRouter, Response, Depends
from app.route import GzipRoute
from app.response import OK, no_content, forbidden
from app.depends.validator import valid_eth_address
from controller.chain.staking import StakingController
from model.mongodb.collection import UserActivity
from model.basemodel.activity import ReceiptStakeInfo


api = APIRouter(
    route_class=GzipRoute,
    tags=['Activity']
)


@api.get(
    '/activity/{address}',
    summary="Get User Activity",
    response_model=OK[list[UserActivity.UserActivitySchema]]
)
async def get_activity(
    user_address: str = Depends(valid_eth_address),
    start_date: str | None = "1900-01-01",
    end_date: str | None = "2999-12-31",
):
    """
    Get User Activity

    사용자 스테이킹 활동 정보를 반환합니다.
    """
    data = await UserActivity().find_range_by_date(
        user_address,
        datetime.strptime(start_date, '%Y-%m-%d'),
        datetime.strptime(end_date, '%Y-%m-%d')
    )
    result = [UserActivity.UserActivitySchema(**document) for document in data]
    return OK(result)


@api.post(
    '/activity',
    summary="Insert User Activity",
    status_code=204, response_class=Response
)
async def insert_activity(
    stake_info: ReceiptStakeInfo,
):
    """
    Insert User Activity
    """
    contract = StakingController()
    event_loop = asyncio.get_running_loop()

    # Get Stake Info
    result = await event_loop.run_in_executor(
        None,
        contract.get_stake_info_many,
        list(map(int, stake_info.stake_ids))
    )

    # Logging User Activity
    for info in result:
        # Check Requester
        if info['user_address'] != stake_info.user_address:
            return forbidden("Requester information does not match.")

        # Check Already Exist
        if await UserActivity().check_duplicated(info['stake_id'], info['status']):
            return forbidden("This resource already exists.")

        document = {
            'user_address': info['user_address'],
            'stake_id': info['stake_id'],
            'status': info['status'],
            'start_date': info['start_date'],
            'end_date': info['end_date'],
            'claimed_date': info['claimed_date'],
            'period': info['period'],
            'transaction_hash': stake_info.transaction_hash
        }

        if info['status'] in ('claimed', 'cancelled',):
            document['amount'] = info['claimed_amount']
        elif info['status'] == 'staked':
            document['amount'] = info['staked_amount']

        await UserActivity().insert_one(document)

    return no_content
