import boto3
import os

# BE CAREFUL ABOUT RUNNING THIS FUNCTION, IT WILL TERMINATE ALL ANALYTICS INSTANCES
# AND RECREATE THE ANALYTICS ENVIRONMENT!!!
# MAKE SURE YOU HAVE CONFIRMED THAT NO WORKLOAD IS ACTIVELY RUNNING ON THE ANALYTICS JUPYTERHUB CLUSTER

ANALYTICS_MAIN_NODE_NAME = os.environ["ANALYTICS_MAIN_NODE_NAME"]
ANALYTICS_DASK_NODE_NAME = os.environ["ANALYTICS_DASK_NODE_NAME"]
ANALYTICS_ASG_MIN = os.environ["ANALYTICS_ASG_MIN"]
ANALYTICS_CLUSTER_NAME = os.environ["ANALYTICS_CLUSTER_NAME"]

ec2 = boto3.client("ec2")
sns = boto3.client("sns")
asg = boto3.client("autoscaling")


def lambda_handler(event, context):
    main_asg = get_auto_scaling_group_name(ANALYTICS_CLUSTER_NAME, "main")
    dask_asg = get_auto_scaling_group_name(ANALYTICS_CLUSTER_NAME, "dask-workers")
    print("Resetting analytics main node ASG to %s..." % ANALYTICS_ASG_MIN)
    reset_asgs(main_asg, int(ANALYTICS_ASG_MIN))
    print("Resetting analytics dask worker node ASG to %s..." % ANALYTICS_ASG_MIN)
    reset_asgs(dask_asg, int(ANALYTICS_ASG_MIN))
    print("Terminating main nodes...")
    terminate_nodes(ANALYTICS_MAIN_NODE_NAME)
    print("Terminating dask worker nodes...")
    terminate_nodes(ANALYTICS_DASK_NODE_NAME)


def terminate_nodes(node_name):
    node_filter = [
        {"Name": "tag:Name", "Values": [node_name]},
        {"Name": "instance-state-name", "Values": ["running"]},
    ]

    nodes = ec2.describe_instances(Filters=node_filter)

    for reservation in nodes["Reservations"]:
        for node_instance in reservation["Instances"]:
            print("Terminating analytics instance %s ..." % node_instance["InstanceId"])
            ec2.terminate_instances(InstanceIds=[node_instance["InstanceId"]])


def reset_asgs(asg_name, asg_capacity):
    print("Setting %s ASG desired capacity to %d ..." % (asg_name, asg_capacity))
    asg.update_auto_scaling_group(AutoScalingGroupName=asg_name, MinSize=asg_capacity)
    asg.set_desired_capacity(
        AutoScalingGroupName=asg_name, DesiredCapacity=asg_capacity
    )


def get_auto_scaling_group_name(cluster_name, nodegroup_name):
    asg_name = ""
    asgs = asg.describe_auto_scaling_groups(
        Filters=[
            {"Name": "tag:eks:cluster-name", "Values": [cluster_name]},
            {"Name": "tag:eks:nodegroup-name", "Values": [nodegroup_name]},
        ]
    )
    if "AutoScalingGroups" in asgs and len(asgs["AutoScalingGroups"]) > 0:
        asg_name = asgs["AutoScalingGroups"][0]["AutoScalingGroupName"]

    return asg_name
