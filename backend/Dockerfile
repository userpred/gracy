FROM python:3.10-alpine as base

COPY ./ /home/gracy-staking-api/

WORKDIR /home/gracy-staking-api/

RUN apk update && \
    apk add  && \
    apk add --update --no-cache alpine-sdk gcc libffi-dev jpeg-dev zlib-dev && \
    pip install --upgrade pip && \
    pip wheel --wheel-dir=/home/gracy-staking-api/wheels -r requirements.txt

FROM python:3.10-alpine

COPY --from=base /home/gracy-staking-api/ /home/gracy-staking-api/
WORKDIR /home/gracy-staking-api/

RUN apk update && \
	apk add --update --no-cache bash curl && \
	mkdir /home/assets && \
	pip install --no-index --find-links=/home/gracy-staking-api/wheels -r requirements.txt && \
	rm -rf /home/gracy-staking-api/wheels
EXPOSE 5000

CMD ["uvicorn", "main:application", \
    "--workers", "4", \
    "--port", "5000", \
    "--env-file", "prod.env", \
    "--host=0.0.0.0"]