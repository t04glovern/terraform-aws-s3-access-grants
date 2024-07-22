import csv
import json
import io
import os
import logging

import jwt
import boto3

from flask import Flask, session, redirect, url_for
from flask_oidc import OpenIDConnect

from dotenv import load_dotenv

# Load environment variables from a .env file if it exists
load_dotenv()

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Configure your Flask app - secret key and OIDC settings
app.config.update(
    {
        "SECRET_KEY": os.getenv("FLASK_SECRET_KEY", "Your_Secret_Key"),
        "OIDC_CLIENT_SECRETS": "client_secrets.json",
        "OIDC_ID_TOKEN_COOKIE_SECURE": False,  # Set to True in production with HTTPS
    }
)

oidc = OpenIDConnect(app)

AWS_REGION = "ap-southeast-2"


@app.route("/")
def index() -> str:
    if oidc.user_loggedin:
        return 'Welcome, {}! <a href="/logout">Log out</a> --- <a href="/get-s3-data">Get S3 Data</a>'.format(
            session['oidc_auth_profile']['email']
        )
    else:
        return 'Not logged in! <a href="/login">Log in</a>'


@app.route("/login")
@oidc.require_login
def login():
    return redirect(url_for("index"))


@app.route("/logout")
def logout():
    oidc.logout()
    return redirect(url_for("index"))


@app.route("/get-s3-data")
@oidc.require_login
def get_s3_data() -> str:

    # Step 1: Exchange OIDC token for AWS token
    auth_token = session.get("oidc_auth_token")
    logger.debug(auth_token)
    id_token = auth_token.get("id_token")
    logger.debug(id_token)
    sso_oidc_client = boto3.client("sso-oidc", region_name=AWS_REGION)
    aws_token = sso_oidc_client.create_token_with_iam(
        clientId=os.getenv("AWS_IIC_APPLICATION_ARN"),
        grantType="urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion=id_token,
    )
    logger.debug(aws_token)
    decoded_token = jwt.decode(
        aws_token["idToken"], options={"verify_signature": False}
    )
    logger.debug(decoded_token)

    # Step 2:
    sts_client = boto3.client("sts", region_name=AWS_REGION)
    sts_response = sts_client.assume_role(
        RoleArn=os.getenv("AWS_S3_ACCESS_GRANT_ROLE_ARN"),
        RoleSessionName="my-role-session-with-identity-context",
        ProvidedContexts=[
            {
                "ProviderArn": "arn:aws:iam::aws:contextProvider/IdentityCenter",
                "ContextAssertion": decoded_token["sts:identity_context"],
            }
        ],
    )
    logger.debug(sts_response)

    # Step 3: Request Access to Data from S3 Access Grants
    s3_access_grants_client = boto3.client(
        "s3control",
        aws_access_key_id=sts_response["Credentials"]["AccessKeyId"],
        aws_secret_access_key=sts_response["Credentials"]["SecretAccessKey"],
        aws_session_token=sts_response["Credentials"]["SessionToken"],
        region_name=AWS_REGION,
    )
    data_access_response = s3_access_grants_client.get_data_access(
        AccountId=os.getenv("AWS_S3_ACCESS_GRANT_ACCOUNT_ID"),
        Target=f's3://{os.getenv("AWS_TARGET_BUCKET_NAME")}/users*',
        Permission="READ",
    )
    temp_credentials = data_access_response["Credentials"]

    # Step 4: Read Objects from S3
    s3_client = boto3.client(
        "s3",
        aws_access_key_id=temp_credentials["AccessKeyId"],
        aws_secret_access_key=temp_credentials["SecretAccessKey"],
        aws_session_token=temp_credentials["SessionToken"],
        region_name=AWS_REGION,
    )
    s3_object = s3_client.get_object(
        Bucket=os.getenv("AWS_TARGET_BUCKET_NAME"), Key="users/user_list"
    )

    # Process the S3 object as needed
    s3_object_data = s3_object["Body"].read().decode("utf-8")
    logger.debug(s3_object_data)

    # csv to json
    csv_file = io.StringIO(s3_object_data)
    csv_reader = csv.DictReader(csv_file)
    s3_object_data = []
    for row in csv_reader:
        s3_object_data.append(row)

    response = json.dumps({"s3_object_data": s3_object_data}, indent=2)
    return response


if __name__ == "__main__":
    app.run(debug=True, use_reloader=False)
