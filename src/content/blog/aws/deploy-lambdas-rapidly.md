---
title: "Deploying AWS Lambdas Rapidly"
description: "A Guide to Faster AWS Workflows"
pubDate: "Aug 2 2023"
heroImage: "/placeholder-hero.jpg"
---

As a beginner to AWS lambda and serverless functions, it might be tempting to fiddle around in the management console. While there is absolutely nothing wrong with that, the cli will improve your workflow significantly.

Using the CLI, you can create lambda functions and attach proper tags and roles to them within seconds, as opposed to getting lost in the GUI of the management console.

Hear me out!

- Time to read: 5 min
- Time to implement: 10-40 min

## Step 0: Set up the AWS CLI

In order to avoid posting outdated information and steps, I will attach the documentation to the official source. Visit here for AWS CLI installation steps for Windows, Linux, and MacOS:

https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

Before moving to step 1, confirm that the CLI is successfully configured:

```
aws s3 ls
```

If you are authenticated, you will see a list of your s3 buckets.

## Step 1: Create a Role with The Lambda Permissions You Want

The policy you may want to consider for your role is the managed `AWSLambdaBasicExecutionRole` (https://docs.aws.amazon.com/aws-managed-policy/latest/reference/AWSLambdaBasicExecutionRole.html)

The policy document looks like this

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
```

This gives access to cloudwatch logs.

I also use dynamodb in this tutorial, so I will attach the AWS Managed policy `AmazonDynamoDBFullAccess`. (https://docs.aws.amazon.com/aws-managed-policy/latest/reference/AmazonDynamoDBFullAccess.html)

Save the policy document you wish to associate to the role, and invoke the CLI

```bash
aws iam create-role \
  --role-name Test-Role \
  --assume-role-policy-document file://Test-Role-Trust-Policy.json
```

If successful, you may get an output that looks like this

```json
{
  "Role": {
    "AssumeRolePolicyDocument": "<URL-encoded-JSON>",
    "RoleId": "AKIAIOSFODNN7EXAMPLE",
    "CreateDate": "2013-06-07T20:43:32.821Z",
    "RoleName": "Test-Role",
    "Path": "/",
    "Arn": "arn:aws:iam::123456789012:role/Test-Role"
  }
}
```

\*\*\*If not successful, you may have a malformed policy.

Make note of the ARN of the role you create. You will attach this role to the lambda function in step 2. An arn will look something like this: arn:partition:service:region:account-id:resource-type:resource-id

## Step 2: Make a basic Lambda function

Copy this into a file called `web_api.py`

`web_api.py`

```python
import boto3
import json
import os

def handler(event, context):
	return {"statusCode": 200, "body": "Hello World!"}
```

## Step 3: Zip up the file and deploy!

Use the below template:

```bash
aws lambda create-function \
--function-name YOUR_FUNCTION \
--zip-file fileb://YOUR_FUNCTION_ZIPPED.zip \
--handler YOUR_FUNCTION.HANDLER_METHOD \
--runtime RUNTIME \
--role ROLE_ARN_YOU_MADE \
--tags Name=Test
```

A full list of the create-function options can be found here
https://docs.aws.amazon.com/cli/latest/reference/lambda/create-function.html

You may want to add environment variables at this step as well, like `--environment "Variables={table_name=myTable}"`. You will need the role ARN as shown above.

An example might look like this

```bash
aws lambda create-function \
--function-name web_api \
--zip-file fileb://web_api.zip \
--handler web_api.handler \
--runtime python3.10 \
--role arn:aws:iam::43085344343534:role/lambda-apigateway-role \
--tags Name=test_api \
--environment "Variables={table_name=myTable}
```

## Step 4: You're done!

Want to confirm your configuration?

```
aws lambda get-function-configuration --function-name web_api
```

Want to actually invoke it?

Make a test input payload (test_input.json) and populate it with the below

```json
{
  "operation": "echo",
  "payload": {
    "somekey1": "somevalue1",
    "somekey2": "somevalue2"
  }
}
```

Now invoke it

```bash
aws lambda invoke --function-name web_api --payload file://test_input.json outputfile.json --cli-binary-format raw-in-base64-out
```

## Step 5: Check out the results

Peek at `outputfile.json`

That's all!

Now you can make lambda functions fast and configure them even faster.

Some useful commands to keep in mind:

```bash
aws lambda create-function
aws lambda configure-function
aws lambda update-function-code
aws lambda invoke
```

And here's a demonstration of the power of using the CLI

```bash
aws lambda invoke --function-name XXXXX --payload file://XXXXXX /dev/stdout --region us-west-2 --cli-binary-format raw-in-base64-out | jq
```
