FROM public.ecr.aws/lambda/python:3.8

RUN pip install pip -U

# pin fastapi, as versions >= 0.95 don't work with
# even the latest titiler
RUN pip install "fastapi==0.94.1" "titiler.application==0.6.0" "mangum>=0.10.0"  --target "${LAMBDA_TASK_ROOT}"

COPY handler.py ${LAMBDA_TASK_ROOT}

CMD ["handler.handler"]
