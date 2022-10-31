import json
from datetime import datetime
from web3 import Web3
from web3.middleware import geth_poa_middleware
from web3.exceptions import ContractLogicError
from controller.chain.ethereum import EthereumController
from settings import settings, BASE_DIR


class StakingController(EthereumController):

    def __init__(
        self,
        entrypoint: str = settings.staking_domain,
        contract_addr: str = settings.staking_contract,
        abi_path: str = BASE_DIR + '/controller/chain/abi/staking_abi.json'
    ):
        super().__init__(entrypoint, contract_addr, abi_path)

    def is_valid_address(self, account_addr: str):
        """유효한 어카운트 주소인지 확인"""
        return self._web3.isAddress(account_addr)

    def get_balance(self, account_addr: str):
        """return Ether"""
        acc_check_sum = self._web3.toChecksumAddress(account_addr)
        wei = self._web3.eth.get_balance(acc_check_sum)
        return self._web3.fromWei(wei, 'ether')

    def contract_view_call(self, function: str, *args):
        """블록에 기록하지 않는 Read 메소드에 대한 호출"""
        return getattr(self._contract.functions, function)(*args).call()

    def contract_mutable_call(
        self,
        function: str,
        public_key: str,
        private_key: str,
        *args
    ):
        """블록을 기록해야 하는 Writeable 메소드 호출"""
        tx = getattr(
            self._contract.functions,
            function
        )(*args).buildTransaction(
            {
                'from': public_key,
                'nonce': self._web3.eth.getTransactionCount(
                    public_key, 'pending'
                )
            }
        )
        signed_tx = self._web3.eth.account.sign_transaction(
            tx, private_key)
        res = self._web3.eth.send_raw_transaction(
            signed_tx.rawTransaction)
        return res

    def get_transaction_receipt(self, tx_hash: str):
        receipt = self._web3.eth.get_transaction_receipt(tx_hash)
        return dict(receipt)

    def get_transaction(self, tx_hash: str) -> dict:
        """트랜잭션 정보 조회"""
        response = self._web3.eth.get_transaction(tx_hash)
        response = dict(response)

        # parse input fields
        data = response['input']
        response['input_data'] = {
            'method_id': data[:10],
            # 메소드 실행을 위한 각각의 인자
            'data': [],
        }
        data = data[10:]
        data_list = response['input_data']['data']
        while data:
            data_list.append(data[:64])
            data = data[64:]
        return response

    def get_owner(self):
        """해당 컨트랙트 발행자 addr 반환"""
        return self.contract_view_call('owner')

    def get_stake_info(self, stake_id: int):
        result = self.contract_view_call('getStakeInfo', stake_id)
        return {
            "stake_id": result[0],
            "community_id": result[1],
            "user_address": result[2],
            "start_date": datetime.fromtimestamp(result[3]),
            "end_date": datetime.fromtimestamp(result[4]),
            "claimed_date": datetime.fromtimestamp(result[5]),
            "staked_amount": result[6],
            "claimed_amount": result[7],
            "period": result[8],
            "status": result[9]
        }

    def get_stake_info_many(self, stake_ids: list):
        results = self.contract_view_call('getStakeInfoByIds', stake_ids)
        return [
            {
                "stake_id": result[0],
                "community_id": result[1],
                "user_address": result[2],
                "start_date": datetime.fromtimestamp(result[3]),
                "end_date": datetime.fromtimestamp(result[4]),
                "claimed_date": datetime.fromtimestamp(result[5]),
                "staked_amount": result[6],
                "claimed_amount": result[7],
                "period": result[8],
                "status": result[9]
            }
            for result in results
        ]


if __name__ == '__main__':
    staking = StakingController()
    print(staking.get_stake_info(21))
