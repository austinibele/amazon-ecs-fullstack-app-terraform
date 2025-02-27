# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

/*=======================================================
      AWS CodePipeline for build and deployment
========================================================*/

# module "codestar_connection" {
#   source          = "./CodeStar" 
#   connection_name = "my-github-connection"
# }

resource "aws_codepipeline" "aws_codepipeline" {
  name     = var.name
  role_arn = var.pipe_role

  artifact_store {
    location = var.s3_bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["SourceArtifact"]

      configuration = {
        OAuthToken           = var.github_token
        Owner                = var.repo_owner
        Repo                 = var.repo_name
        Branch               = var.branch
        PollForSourceChanges = true
      }
    }
  }

  # stage {
  #   name = "Source"

  #   action {
  #     name             = "Source"
  #     category         = "Source"
  #     owner            = "AWS"
  #     provider         = "CodeStarSourceConnection"
  #     version          = "1"
  #     output_artifacts = ["SourceArtifact"]

  #     configuration = {
  #       ConnectionArn = module.codestar_connection.codestar_connection_arn
  #       FullRepositoryId = "${var.repo_owner}/${var.repo_name}"
  #       BranchName     = var.branch
  #       DetectChanges  = true
  #     }
  #   }
  # }

  stage {
    name = "Build"

    action {
      name             = "Build_server"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["SourceArtifact"]
      output_artifacts = ["BuildArtifact_server"]

      configuration = {
        ProjectName = var.codebuild_project_server
      }
    }

    action {
      name             = "Build_client"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["SourceArtifact"]
      output_artifacts = ["BuildArtifact_client"]
      configuration = {
        ProjectName = var.codebuild_project_client
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy_server"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      input_artifacts = ["BuildArtifact_server"]
      version         = "1"

      configuration = {
        ApplicationName                = var.app_name_server
        DeploymentGroupName            = var.deployment_group_server
        TaskDefinitionTemplateArtifact = "BuildArtifact_server"
        TaskDefinitionTemplatePath     = "taskdef.json"
        AppSpecTemplateArtifact        = "BuildArtifact_server"
        AppSpecTemplatePath            = "appspec.yaml"
      }
    }

    action {
      name            = "Deploy_client"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      input_artifacts = ["BuildArtifact_client"]
      version         = "1"

      configuration = {
        ApplicationName                = var.app_name_client
        DeploymentGroupName            = var.deployment_group_client
        TaskDefinitionTemplateArtifact = "BuildArtifact_client"
        TaskDefinitionTemplatePath     = "taskdef.json"
        AppSpecTemplateArtifact        = "BuildArtifact_client"
        AppSpecTemplatePath            = "appspec.yaml"
      }
    }
  }

  lifecycle {
    # prevents github OAuthToken from causing updates, since it's removed from state file
    ignore_changes = [stage[0].action[0].configuration]
  }

}