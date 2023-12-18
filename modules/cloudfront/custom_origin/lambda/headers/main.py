import os
import boto3

DISTRIBUTIONID = os.environ["DISTRIBUTIONID"]
FORWARDEDHOST = os.environ["FORWARDEDHOST"]
REGION = os.environ["REGION"]
SSM_FORWARDED_HOST_PARAM = os.environ["SSM_FORWARDED_HOST_PARAM"]
cloudfront = boto3.client("cloudfront", region_name=REGION)
ssm = boto3.client("ssm", region_name=REGION)


# Update CloudFront Custom Headers to support X-Forwarded-* headers
def lambda_handler(event, context):
    try:
        # 1st Step is get current CloudFront Distribution configuration
        distribution_config = cloudfront.get_distribution_config(Id=DISTRIBUTIONID)
        ssm.put_parameter(
            Name=SSM_FORWARDED_HOST_PARAM,
            Value=FORWARDEDHOST,
            Type="String",
            Overwrite=True,
        )
        # 2nd Step is to modify Headers in the Custom Origin
        origin_number = 0
        for origin in distribution_config["DistributionConfig"]["Origins"]["Items"]:
            if (
                "CustomHeaders" in origin.keys()
                and "Quantity" in origin["CustomHeaders"].keys()
                and origin["CustomHeaders"]["Quantity"] > 0
            ):
                headers_number = 0
                for headers in distribution_config["DistributionConfig"]["Origins"][
                    "Items"
                ][origin_number]["CustomHeaders"]["Items"]:
                    if headers["HeaderName"] == "X-Forwarded-Host":
                        distribution_config["DistributionConfig"]["Origins"]["Items"][
                            origin_number
                        ]["CustomHeaders"]["Items"][headers_number][
                            "HeaderValue"
                        ] = FORWARDEDHOST
                    headers_number = headers_number + 1
                distribution_config["DistributionConfig"]["Origins"]["Items"][
                    origin_number
                ]["CustomHeaders"]["Quantity"] = 3
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
