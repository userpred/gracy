import json
from fastapi import Depends
from bson import ObjectId
from fastapi import HTTPException


def valid_sign_id(sign_id: int) -> int:
    if sign_id < 1:
        raise HTTPException(status_code=404)
    return sign_id


def valid_eth_address(address: str) -> str:
    if not address.startswith("0x"):
        raise HTTPException(
            status_code=400,
            detail="Invalid Ethereum Address Format."
        )
    return address


def valid_chain_address(address: str) -> str:
    if not 42 <= len(address) <= 44:
        raise HTTPException(
            status_code=400,
            detail="Invalid Chain Address Format."
        )
    return address


def valid_str_json_format(value: str) -> dict:
    try:
        return json.loads(value)
    except:
        raise HTTPException(
            status_code=400,
            detail="Invalid JSON Format."
        )


def valid_object_id(object_id: str) -> ObjectId:
    try:
        return ObjectId(object_id)
    except:
        raise HTTPException(
            status_code=400,
            detail="Invalid ID Format."
        )


def valid_object_ids(community_ids: str) -> list:
    try:
        return list(map(ObjectId, community_ids))
    except:
        raise HTTPException(
            status_code=400,
            detail="Invalid ID Format."
        )
