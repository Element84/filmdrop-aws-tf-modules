import hashlib
import json
import logging
import os
import time
from typing import Any, Dict, List, Optional

import boto3
import requests
import tqdm
from pystac_client import Client

logger = logging.getLogger()
logger.setLevel(logging.INFO)

NUM_RECORDS_TO_SIPHON = 3000


def lambda_handler(event, context):
    min_lat = os.environ["MIN_LAT"]
    min_long = os.environ["MIN_LONG"]
    max_lat = os.environ["MAX_LAT"]
    max_long = os.environ["MAX_LONG"]
    input_collections = os.environ["COLLECTIONS"].split(",")
    date_start = os.environ["DATE_START"]
    date_end = os.environ["DATE_END"]
    stac_source_url = os.environ["STAC_SOURCE_URL"]
    stac_dest_url = os.environ["STAC_DEST_URL"]
    ingest_sqs_url = os.environ["INGEST_SQS_URL"]
    include_historical_ingest = os.environ["HISTORICAL_INGEST"]

    # Debug / Test
    logger.info(
        f"bbox: {str(min_lat)}, {str(min_long)}, {str(max_lat)}, {str(max_long)}"
    )
    logger.info(f"collections: {str(input_collections)}")
    logger.info(f"date_start: {str(date_start)}")
    logger.info(f"date_end: {str(date_end)}")
    logger.info(f"source_url: {str(stac_source_url)}")
    logger.info(f"dest_url: {str(stac_dest_url)}")
    logger.info(f"ingest_sqs_url: {str(ingest_sqs_url)}")
    logger.info(f"include_historical_ingest: {str(include_historical_ingest)}")
    logger.info(event)
    logger.info(context)

    dest_collections = get_source_collections(stac_source_url, input_collections)

    create_new_collections(dest_collections, ingest_sqs_url)

    wait_for_new_collections(dest_collections, stac_dest_url)

    if include_historical_ingest == "true":
        logger.info("Starting historical ingest!")
        start_data_siphon(
            input_collections,
            [float(min_long), float(min_lat), float(max_long), float(max_lat)],
            date_start,
            date_end,
            ingest_sqs_url,
        )
    else:
        logger.info("Skipping historical ingest!")

    return {
        "statusCode": 200,
        "body": json.dumps(
            "Success: collections created; siphoning data (if applicable)"
        ),
    }


def get_source_collections(source_url, input_collections):
    logger.info("Fetching Collections")
    response = requests.get(f"{source_url}/collections")

    collections_list = response.json()["collections"]

    # Build our desired list, and truncate each 'links' section
    new_collections = []
    for c in collections_list:
        if c["id"] in input_collections:
            c["links"] = []
            new_collections.append(c)

    logger.info(f"New Collection List: {str(new_collections)}")
    return new_collections


def create_new_collections(collections, ingest_sqs_url):
    client = boto3.client("sqs")
    for c in collections:
        logger.info(
            f"Sending collection {json.dumps(c)} to ingest_sqs_url: {ingest_sqs_url}"
        )
        result = client.send_message(QueueUrl=ingest_sqs_url, MessageBody=json.dumps(c))
        logger.info(f"Result of creating new collection: {str(result)}")


def wait_for_new_collections(collections, stac_dest_url):
    while True:
        all_created = True

        for c in collections:
            logger.info(f'Checking status of {stac_dest_url}/collections/{c["id"]}')
            response = requests.get(f'{stac_dest_url}/collections/{c["id"]}')

            # Debug / Test
            logger.info(
                f'Collection status code: {str(c["id"])}, {str(response.status_code)}'
            )

            if response.status_code != 200:
                logger.info(f'Still waiting for Collection: {str(c["id"])}')
                all_created = False

        if all_created:
            logger.info("All Collections created!")
            return

        logger.info("Waiting for Collections to be available, sleeping")
        time.sleep(5)


def start_data_siphon(collections, bbox, date_start, date_end, ingest_sqs_url):
    input = {
        "stac_api": "earth-search",
        "collections": collections,
        "datetime": f"{date_start}/{date_end}",
        "intersects": {
            "type": "Polygon",
            "coordinates": [
                [
                    [  # minLong, minLat
                        bbox[0],
                        bbox[1],
                    ],
                    [  # minLong, maxLat
                        bbox[0],
                        bbox[3],
                    ],
                    [  # maxLong, maxLat
                        bbox[2],
                        bbox[3],
                    ],
                    [  # maxLong, minLat
                        bbox[1],
                        bbox[2],
                    ],
                    [  # minLong, minLat
                        bbox[0],
                        bbox[1],
                    ],
                ]
            ],
        },
        "limit": 80,
    }

    lib_siphon(
        json.dumps(input), ingest_sqs_url, NUM_RECORDS_TO_SIPHON, False, True, 5, False
    )


######## The remainder of this file is copied from the 'stac_siphon_sqs' repo ########


def lib_siphon(
    query: Optional[str],
    sqs_url: Optional[str],
    max_items: Optional[int],
    stream: bool,
    batch: bool,
    batch_size: int,
    quiet: bool,
) -> None:
    """Siphon STAC items from an API to a stac-server via SQS.

    \b
        stac-siphon-sqs \\
            query.json \\
            https://sqs.us-west-2.amazonaws.com/XXXXXXXXXXXX/queue-nameXXXXXXXXXXXXXXXXXXXXXXXXXX

    QUERY should a JSON file containing the arguments to be passed in to a
    pystac-client search, e.g.:

    \b
        {
            "stac_api": "earth-search",
            "collections": ["landsat-c2-l2"],
            "datetime": "2023-06",
            "intersects": {
                "type": "Point",
                "coordinates": [-105, 40]
            }
        }

    The `stac_api` key is used to identify the STAC API to search. You can use
    the "earth-search" short name, or provide a full HREF.

    If QUERY is omitted or equal to "-", the JSON will be read from stdin.

    If SQS_URL is not provided, the siphon will be a "dry run" and the messages
    will instead be printed to standard output.

    If your items are large, you may need to adjust the --batch-size.
    """

    if batch_size > 10:
        raise ValueError(
            "Batch size can't be more than 10, them's the SQS rules: "
            f"batch_size={batch_size}"
        )
    batcher = Batcher(batch_size if batch else 1)
    if sqs_url:
        sqs = boto3.client("sqs")
    else:
        sqs = None

    def qprint(*args: Any) -> None:
        if not quiet:
            tqdm.tqdm.write(*args)

    def process(item: Dict[str, Any]) -> None:
        batcher.add(item)
        if batcher.is_ready():
            send(batcher.send())

    def send(entries: List[Dict[str, Any]]) -> None:
        if not entries:
            return
        if sqs:
            if len(entries) == 1:
                sqs.send_message(
                    QueueUrl=sqs_url, MessageBody=entries[0]["MessageBody"]
                )
            else:
                sqs.send_message_batch(QueueUrl=sqs_url, Entries=entries)
        else:
            qprint(json.dumps(entries, indent=2))

    query_json = json.loads(query)
    logger.info(f"query_json: {query_json}")

    if not isinstance(query_json, dict):
        raise ValueError(f"Query JSON should be a dict, not a {type(query_json)}")
    if "stac_api" not in query_json:
        raise ValueError(
            "Query does not contain a `stac_api` attribute, which is required."
        )

    stac_api = query_json.pop("stac_api")
    if stac_api == "earth-search":
        stac_api = "https://earth-search.aws.element84.com/v1/"

    logger.info(f"stac_api: {stac_api}")

    if max_items is not None:
        query_json["max_items"] = max_items

    client = Client.open(stac_api)
    logger.info(f"query_json: {query_json}")
    search = client.search(**query_json)
    logger.info(f"search: {search}")
    if stream:
        qprint("Streaming items...")
        for item in tqdm.tqdm(search.items_as_dicts(), disable=quiet):
            process(item)
    else:
        qprint("Fetching all items...")
        logger.info(f"search.items_as_dicts(): {search.items_as_dicts()}")
        items = list(search.items_as_dicts())
        for item in tqdm.tqdm(items, disable=quiet):
            process(item)

    entries = batcher.send()
    if entries:
        send(entries)


class Batcher:
    """A class that batches up messages before sending."""

    size: int
    items: List[Dict[str, Any]]

    def __init__(self, size: int) -> None:
        self.size = size
        self.items = list()

    def is_ready(self) -> bool:
        """Returns true if the number of items equals the batcher size."""
        return len(self.items) >= self.size

    def add(self, item: Dict[str, Any]) -> None:
        """Adds a new item to the batcher.

        Raises:
            ValueError: If the batcher is ready (aka full)
        """
        if self.is_ready():
            raise ValueError("This batcher is ready to send, can't add any more items")
        self.items.append(item)

    def send(self) -> List[Dict[str, Any]]:
        """Returns all the items as message entries, and clears the items list."""
        entries = [
            {
                "Id": _id_or_hexdigest(item),
                "MessageBody": json.dumps(item, separators=(",", ":")),
            }
            for item in self.items
        ]
        self.items = list()
        return entries


def item_hexdigest(item: Dict[str, Any]) -> str:
    """Computes the hexdigest of an item.

    Used if the item doesn't have an id ... unlikely, but you never know.
    There's also a chance we'll use this function in some other way later, who
    knows?

    Args:
        item: An item as a dictionary -- but really, it could be anything, we
            don't check.

    Returns:
        str: The hex digest.
    """
    item_as_str = json.dumps(item)
    m = hashlib.sha256()
    m.update(item_as_str.encode())
    return m.hexdigest()


def _id_or_hexdigest(item: Dict[str, Any]) -> str:
    try:
        return str(item["id"])
    except KeyError:
        return item_hexdigest(item)
