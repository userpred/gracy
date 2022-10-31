from io import BytesIO
import boto3
from botocore.exceptions import ClientError


class S3Controller:

    def __init__(
        self,
        aws_access_key_id: str,
        aws_secret_access_key: str,
        bucket_name: str,
        bucket_domain: str,
    ):
        self.s3 = boto3.client(
            's3',
            aws_access_key_id=aws_access_key_id,
            aws_secret_access_key=aws_secret_access_key,
        )
        self.bucket_name = bucket_name
        self.bucket_domain = bucket_domain

    async def download_fileobj(self, object_path: str):
        try:
            f = BytesIO()
            await self.s3.download_fileobj(self.bucket_name, object_path, f)
            f.seek(0)
            return f
        except ClientError as e:
            if e.response['Error']['Code'] == '404':
                return None
            raise e

    async def upload_fileobj(
        self,
        file: BytesIO,
        object_path: str,
        extra: dict = None,
    ):
        """
        - 메소드 실행시, 인자로 준 file(Bytesio)를 close함. (주의 요망)
        - 충격적이게도 response가 없다고 함.
        """
        extra = extra if extra else {}
        self.s3.upload_fileobj(
            file,
            self.bucket_name,
            object_path,
            ExtraArgs=extra
        )
        return self.bucket_domain + object_path

    async def exists_object(self, object_path: str):
        """오브젝트 존재 유무만 확인(for performance)"""
        try:
            await self.s3.head_object(Bucket=self.bucket_name, Key=object_path)
            return True
        except ClientError as e:
            if e.response['Error']['Code'] == '404':
                return False
            raise e


if __name__ == '__main__':
    import requests
    import asyncio
    from io import BytesIO
    from settings import settings

    from dotenv import load_dotenv
    load_dotenv()

    s3 = S3Controller(
        aws_access_key_id=settings.s3_access_key_id,
        aws_secret_access_key=settings.s3_access_key_secret,
        bucket_name=settings.s3_bucket_name,
        bucket_domain=settings.s3_domain,
    )

    url = "URL"
    res = requests.get(url)
    img = BytesIO(res.content)
    asyncio.run(s3.upload_fileobj(img, 'test2.png'))

