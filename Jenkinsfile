pipeline {
    agent any

    environment {
        AWS_REGION       = 'ap-southeast-1'
        PROJECT_NAME     = 'autodesk-practice-app'
        
        // --- Credentials ID (Must exist in Jenkins) ---
        AWS_CREDS_ID     = 'aws-static-creds'
        STATE_BUCKET     = credentials('terraform-state-bucket')
        
        // --- The name of the Role you created in AWS ---
        DEPLOY_ROLE_NAME = 'jenkins-test'
        
        // --- Metadata ---
        GIT_COMMIT_REV   = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
    }

    stages {
        stage('Auto-Detect Account ID') {
            steps {
                script {
                    // Use the static keys to ask AWS for the Account ID
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding', 
                        credentialsId: "${AWS_CREDS_ID}"
                    ]]) {
                        // This command extracts just the 12-digit Account ID
                        env.AWS_ACCOUNT_ID = sh(
                            returnStdout: true, 
                            script: "aws sts get-caller-identity --query Account --output text"
                        ).trim()
                        
                        echo "Automatically detected Account ID: ${env.AWS_ACCOUNT_ID}"
                    }
                }
            }
        }

        stage('Build & Push') {
            steps {
                script {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${AWS_CREDS_ID}"]]) {
                        def ecrRegistry = "${env.AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
                        sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ecrRegistry}"
                        
                        docker.build("${ecrRegistry}/${PROJECT_NAME}:${GIT_COMMIT_REV}").push()
                        docker.build("${ecrRegistry}/${PROJECT_NAME}:latest").push()
                    }
                }
            }
        }

        stage('Terraform Infrastructure') {
            steps {
                // withAWS will now use the env.AWS_ACCOUNT_ID we just detected
                withAWS(role: "${DEPLOY_ROLE_NAME}", roleAccount: "${env.AWS_ACCOUNT_ID}", region: "${AWS_REGION}") {
                    dir('terraform') {
                        sh """
                            terraform init \
                            -backend-config="bucket=${STATE_BUCKET}" \
                            -backend-config="key=${PROJECT_NAME}/terraform.tfstate" \
                            -backend-config="region=${AWS_REGION}"
                        """
                        sh "terraform apply -var='image_tag=${GIT_COMMIT_REV}' -auto-approve"
                    }
                }
            }
        }
    }
}