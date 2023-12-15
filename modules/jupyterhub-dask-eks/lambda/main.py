import os
import boto3

DISTRIBUTIONID = os.environ["DISTRIBUTIONID"]
SSM_ORIGIN_PARAM = os.environ["SSM_ORIGIN_PARAM"]


# Update CloudFront Custom Origin
def lambda_handler(event, context):
    try:
        cloudfront = boto3.client("cloudfront", region_name="us-east-1")
        ssm = boto3.client("ssm", region_name="us-east-1")
        try:
            # 1st Step is get current CloudFront Distribution configuration
            distribution_config = cloudfront.get_distribution_config(Id=DISTRIBUTIONID)
            origin_value = ssm.get_parameter(Name=SSM_ORIGIN_PARAM)["Parameter"][
                "Value"
            ]
            # 2nd Step is to modify the Custom Origin
            origin_number = 0
            for origin in distribution_config["DistributionConfig"]["Origins"]["Items"]:
                if (
                    "CustomHeaders" in origin.keys()
                    and "Quantity" in origin["CustomHeaders"].keys()
                    and origin["CustomHeaders"]["Quantity"] > 0
                ):
                    distribution_config["DistributionConfig"]["Origins"]["Items"][
                        origin_number
                    ]["DomainName"] = origin_value
                origin_number = origin_number + 1

            # 3rd Step is to update the CloudFront Distribution
            cloudfront.update_distribution(
                Id=DISTRIBUTIONID,
                IfMatch=distribution_config["ETag"],
                DistributionConfig=distribution_config["DistributionConfig"],
            )

        except Exception as e:
            print(e)
            raise e

    except Exception as e:
        print(e)
        return
