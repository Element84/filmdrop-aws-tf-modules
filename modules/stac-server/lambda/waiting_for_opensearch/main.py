import json
import boto3
import os
import logging
import time

logger = logging.getLogger()
logger.setLevel(logging.INFO)
COLLECTION_NAME = os.environ['COLLECTION_NAME']
REGION = os.environ['REGION']
opensearchserverless = boto3.client('opensearchserverless', region_name=REGION)

def lambda_handler(event, context):
    wait_for_opensearch_serverless_collection(COLLECTION_NAME)

def wait_for_opensearch_serverless_collection(collection):
    collection_active = False
    while not collection_active:
        try:
            logger.info(f'Checking if opensearch serverless collection {collection} is active')
            collection_list = opensearchserverless.list_collections(
                collectionFilters={
                    'name': COLLECTION_NAME,
                    'status': 'ACTIVE'
                }
            )
            if 'collectionSummaries' in collection_list and len(collection_list['collectionSummaries']) > 0:
                logger.info(f'Found opensearch serverless collection {collection_list}')
                collection_active = True
            else:
                logger.info(f'Waiting for opensearch serverless collection {collection} to be available, sleeping...')
                collection_active = False
                time.sleep(5)

        except Exception as e:
            logger.info(f'Waiting for opensearch serverless collection {collection} to be available, sleeping...')
            print(e)
            time.sleep(5)
