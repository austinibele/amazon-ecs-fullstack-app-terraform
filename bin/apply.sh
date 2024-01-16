#!/bin/sh

# Load environment variables from the .env file
set -a # automatically export all variables
source .env
set +a

cd Infrastructure
terraform apply --auto-approve -var aws_profile=$AWS_PROFILE -var aws_region=$AWS_REGION -var environment_name=$ENVIRONMENT -var github_token=$GITHUB_TOKEN -var repository_name=$REPO_NAME -var repository_owner=$REPO_OWNER

