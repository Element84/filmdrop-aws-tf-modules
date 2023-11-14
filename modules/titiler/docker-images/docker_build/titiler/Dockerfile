FROM public.ecr.aws/lambda/python:3.8

RUN pip install pip -U
RUN pip install "titiler.application==0.6.0" "mangum>=0.10.0"  --target "${LAMBDA_TASK_ROOT}"

COPY handler.py ${LAMBDA_TASK_ROOT}

CMD ["handler.handler"]
