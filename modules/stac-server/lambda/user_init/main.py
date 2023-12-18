import http
import os
import base64
import ssl
import json
import time
import boto3

OPENSEARCH_HOST = os.environ["OPENSEARCH_HOST"]
OPENSEARCH_MASTER_CREDS_SECRET_ARN = os.environ["OPENSEARCH_MASTER_CREDS_SECRET_ARN"]
OPENSEARCH_USER_CREDS_SECRET_ARN = os.environ["OPENSEARCH_USER_CREDS_SECRET_ARN"]
REGION = os.environ["REGION"]
secretsmanager = boto3.client("secretsmanager", region_name=REGION)


def lambda_handler(event, context):
    disable_auto_create_index()
    create_stac_server_role()
    create_stac_server_user()
    create_stac_server_user_role_mapping()

    return {
        "statusCode": 200,
        "body": json.dumps("Success setting up OpenSearch!"),
    }


def default_headers():
    admin_secret = secretsmanager.get_secret_value(
        SecretId=OPENSEARCH_MASTER_CREDS_SECRET_ARN
    )
    credentials = json.loads(admin_secret["SecretString"])
    auth_string = "%s:%s" % (credentials["username"], credentials["password"])
    userAndPass = base64.b64encode(auth_string.encode("utf-8")).decode("ascii")
    return {
        "Authorization": "Basic %s" % userAndPass,
        "Content-Type": "application/json; charset=utf-8",
        # "Origin": "https://" + OPENSEARCH_HOST # unsure why this is set
    }


def disable_auto_create_index():
    update_success = False
    while not update_success:
        try:
            print(f"Disabling index auto-creation on {OPENSEARCH_HOST}")
            headers = default_headers()
            host = OPENSEARCH_HOST + ":443"

            path = "/_cluster/settings"
            request = {"persistent": {"action.auto_create_index": "false"}}

            connection = http.client.HTTPSConnection(
                host, context=ssl._create_unverified_context()
            )

            # PUT request, but it has PATCH semantics
            connection.request(
                "PUT", path, json.dumps(request).encode("utf-8"), headers
            )

            response = connection.getresponse()

            output = {}
            output["statusCode"] = response.status
            output["headers"] = dict(
                (key, value) for key, value in response.getheaders()
            )
            responseBody = response.read()
            output["body"] = responseBody.decode("utf-8")

            if response.status < 400:
                connection.close()
                print(f"Successfully set auto_create_index on {OPENSEARCH_HOST}")
                print(output)
                update_success = True
            else:
                connection.close()
                print(
                    f"Failed setting auto_create_index on  {OPENSEARCH_HOST}. Sleeping for 10s..."
                )
                print(output)
                time.sleep(10)

        except Exception as e:
            print(f"Error setting auto_create_index: {e}")
            time.sleep(10)


def create_stac_server_role():
    update_success = False
    while not update_success:
        try:
            print("Creating Stac Server Role on OpenSearch Host %s" % OPENSEARCH_HOST)
            headers = default_headers()
            path = "/_plugins/_security/api/roles/stac_server_role"
            host = OPENSEARCH_HOST + ":443"
            request = {
                "cluster_permissions": [
                    "cluster_composite_ops",
                    "cluster:monitor/health",
                ],
                "index_permissions": [
                    {"index_patterns": ["*"], "allowed_actions": ["indices_all"]}
                ],
                "tenant_permissions": [
                    {
                        "tenant_patterns": ["global_tenant"],
                        "allowed_actions": ["kibana_all_read"],
                    }
                ],
            }

            connection = http.client.HTTPSConnection(
                host, context=ssl._create_unverified_context()
            )

            connection.request(
                "PUT", path, json.dumps(request).encode("utf-8"), headers
            )

            response = connection.getresponse()

            output = {}
            output["statusCode"] = response.status
            output["headers"] = dict(
                (key, value) for key, value in response.getheaders()
            )
            responseBody = response.read()
            output["body"] = responseBody.decode("utf-8")

            if response.status < 400:
                connection.close()
                print(
                    "Successfully Created Stac Server Role on OpenSearch Host  %s"
                    % OPENSEARCH_HOST
                )
                print(output)
                update_success = True
            else:
                connection.close()
                print(
                    "Failed Creating Stac Server Role on OpenSearch Host %s. Sleeping for 10s..."
                    % OPENSEARCH_HOST
                )
                print(output)
                time.sleep(10)

        except Exception as e:
            print("Error Creating Stac Server Role. Sleeping for 10s...")
            print(e)
            time.sleep(10)


def create_stac_server_user():
    update_success = False
    while not update_success:
        try:
            print("Creating Stac Server User on OpenSearch Host %s" % OPENSEARCH_HOST)
            headers = default_headers()
            user_secret = secretsmanager.get_secret_value(
                SecretId=OPENSEARCH_USER_CREDS_SECRET_ARN
            )
            user_credentials = json.loads(user_secret["SecretString"])
            path = (
                "/_plugins/_security/api/internalusers/%s"
                % user_credentials["username"]
            )
            host = OPENSEARCH_HOST + ":443"
            request = {"password": "%s" % user_credentials["password"]}

            connection = http.client.HTTPSConnection(
                host, context=ssl._create_unverified_context()
            )

            connection.request(
                "PUT", path, json.dumps(request).encode("utf-8"), headers
            )

            response = connection.getresponse()

            output = {}
            output["statusCode"] = response.status
            output["headers"] = dict(
                (key, value) for key, value in response.getheaders()
            )
            responseBody = response.read()
            output["body"] = responseBody.decode("utf-8")

            if response.status < 400:
                connection.close()
                print(
                    "Successfully Created Stac Server User on OpenSearch Host  %s"
                    % OPENSEARCH_HOST
                )
                print(output)
                update_success = True
            else:
                connection.close()
                print(
                    "Failed Creating Stac Server User on OpenSearch Host %s. Sleeping for 10s..."
                    % OPENSEARCH_HOST
                )
                print(output)
                time.sleep(10)

        except Exception as e:
            print("Error Creating Stac Server User. Sleeping for 10s...")
            print(e)
            time.sleep(10)


def create_stac_server_user_role_mapping():
    update_success = False
    while not update_success:
        try:
            print(
                "Creating Stac Server User-Role Mapping on OpenSearch Host %s"
                % OPENSEARCH_HOST
            )
            headers = default_headers()
            user_secret = secretsmanager.get_secret_value(
                SecretId=OPENSEARCH_USER_CREDS_SECRET_ARN
            )
            user_credentials = json.loads(user_secret["SecretString"])
            path = "/_plugins/_security/api/rolesmapping/stac_server_role"
            host = OPENSEARCH_HOST + ":443"
            request = {"users": ["%s" % user_credentials["username"]]}

            connection = http.client.HTTPSConnection(
                host, context=ssl._create_unverified_context()
            )

            connection.request(
                "PUT", path, json.dumps(request).encode("utf-8"), headers
            )

            response = connection.getresponse()

            output = {}
            output["statusCode"] = response.status
            output["headers"] = dict(
                (key, value) for key, value in response.getheaders()
            )
            responseBody = response.read()
            output["body"] = responseBody.decode("utf-8")

            if response.status < 400:
                connection.close()
                print(
                    "Successfully Created Stac Server User-Role Mapping on OpenSearch Host  %s"
                    % OPENSEARCH_HOST
                )
                print(output)
                update_success = True
            else:
                connection.close()
                print(
                    "Failed Creating Stac Server User-Role Mapping on OpenSearch Host %s. Sleeping for 10s..."
                    % OPENSEARCH_HOST
                )
                print(output)
                time.sleep(10)

        except Exception as e:
            print("Error Creating Stac Server User-Role Mapping. Sleeping for 10s...")
            print(e)
            time.sleep(10)
