# iterate

Iterates over Job Array submissions.

- Determines index of current Job Array to execute on.
- Links the number of child jobs in the job array to the number of elements in the current batch.
- Determines the total number of job arrays to submit.

## deployment

There is a script to deploy the Lambda function AWS infrastructure called `deploy.sh`.

REQUIRES:

- AWS CLI (<https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html>)
- Terraform (<https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli>)

Command line arguments:

 [1] app_name: Name of application to create a zipped deployment package for
 [2] s3_state_bucket: Name of the S3 bucket to store Terraform state in (no need for s3:// prefix)
 [3] profile: Name of profile used to authenticate AWS CLI commands

# Example usage: `./deploy.sh "my-app-name" "s3-state-bucket-name" "confluence-named-profile"`
