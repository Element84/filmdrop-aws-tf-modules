import boto3
import os

ANALYTICS_MAIN_NODE_NAME = os.environ["ANALYTICS_MAIN_NODE_NAME"]
ANALYTICS_DASK_NODE_NAME = os.environ["ANALYTICS_DASK_NODE_NAME"]
ANALYTICS_NODE_LIMIT = os.environ["ANALYTICS_NODE_LIMIT"]
SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]
STAGE = os.environ["STAGE"]

ec2 = boto3.client("ec2")
sns = boto3.client("sns")


def lambda_handler(event, context):
    main_nodes = get_node_count(ANALYTICS_MAIN_NODE_NAME)
    print("There are %d main analytics nodes running..." % main_nodes)
    dask_nodes = get_node_count(ANALYTICS_DASK_NODE_NAME)
    print("There are %d dask worker analytics nodes running..." % dask_nodes)
    total_nodes = main_nodes + dask_nodes
    print("There are %d total analytics nodes running..." % total_nodes)

    if total_nodes >= int(ANALYTICS_NODE_LIMIT):
        print(
            "Total analytics nodes have exceeded the limit of %s nodes..."
            % ANALYTICS_NODE_LIMIT
        )
        print("Sending alert to SNS Topic: ", SNS_TOPIC_ARN)
        message = (
            "The %s account has a total number of %s filmdrop analytics nodes running and has reached or exceeded the limit of %s nodes running. Check with your team to make sure there is no workload running. For clean-up, connect to your %s environment and run the lambda cleanup function."
            % (STAGE, str(total_nodes), ANALYTICS_NODE_LIMIT, STAGE)
        )
        sns.publish(TopicArn=SNS_TOPIC_ARN, Message=message)


def get_node_count(node_name):
    node_count = 0
    node_filter = [
        {"Name": "tag:Name", "Values": [node_name]},
        {"Name": "instance-state-name", "Values": ["running"]},
    ]

    nodes = ec2.describe_instances(Filters=node_filter)

    for reservation in nodes["Reservations"]:
        node_count = node_count + len(reservation["Instances"])

    return node_count
