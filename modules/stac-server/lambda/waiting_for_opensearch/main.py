import logging
import os
import time

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)
COLLECTION_NAME = os.environ["COLLECTION_NAME"]
REGION = os.environ["REGION"]
opensearchserverless = boto3.client("opensearchserverless", region_name=REGION)


def lambda_handler(event, context):
    wait_for_opensearch_serverless_collection(COLLECTION_NAME)


def wait_for_opensearch_serverless_collection(collection):
    collection_active = False
    while not collection_active:
        logger.info(
            f"Checking if opensearch serverless collection {collection} is active"
        )
        collection_list = {}
        try:
            collection_list = opensearchserverless.list_collections(
                collectionFilters={"name": COLLECTION_NAME}
            )
        except Exception as e:
            logger.info(
                f"Permissions for {collection} or OpenSearch Serverless may not be available yet, sleeping...: {e}"
            )
            collection_list = {}
        if (
            "collectionSummaries" in collection_list
            and len(collection_list["collectionSummaries"]) > 0
            and collection_list["collectionSummaries"][0]["status"] == "ACTIVE"
        ):
            logger.info(
                f"Permissions available for {collection}; found active opensearch serverless collection: {collection_list}"
            )
            collection_active = True
        elif (
            "collectionSummaries" in collection_list
            and len(collection_list["collectionSummaries"]) > 0
            and collection_list["collectionSummaries"][0]["status"] == "FAILED"
        ):
            raise Exception(
                f"Opensearch serverless collection {collection_list} has failed to create..."
            )
        else:
            logger.info(
                f"Waiting for opensearch serverless collection {collection} to be available, sleeping..."
            )
            time.sleep(5)
