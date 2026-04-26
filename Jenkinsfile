pipeline {
    agent any

    environment {
        AWS_REGION       = 'ap-southeast-1'
        PROJECT_NAME     = 'auto-deployment-jenkins'
        
        // This matches the ID you gave your AWS keys in Jenkins
        AWS_CREDS_ID     = 'aws-static-creds'
        
        // Hardcode these since they are specific to your setup
        S3_BUCKET_NAME   = 'yuanyang-terraform-state-2026'
        DYNAMO_TABLE_NAME = 'terraform-state-lock-wei' // Remove if not using locking
        
        // --- The name of the Role you created in AWS ---
        DEPLOY_ROLE_NAME = 'jenkins-test'
        
        // Metadata
        GIT_COMMIT_REV   = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
    }

    stages {
        stage('Auto-Detect Account ID') {
            steps {
                script {
                    // This pulls the 12-digit Account ID using your static keys
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding', 
                        credentialsId: "${AWS_CREDS_ID}"
                    ]]) {
                        env.AWS_ACCOUNT_ID = sh(
                            returnStdout: true, 
                            script: "aws sts get-caller-identity --query Account --output text"
                        ).trim()
                        echo "Detected Account ID: ${env.AWS_ACCOUNT_ID}"
                    }
                }
            }
        }
        stage('Run Tests') {
        steps {
            sh 'pytest --maxfail=1 --disable-warnings -q'
            }
        }

        stage('Build & Push') {
            steps {
                script {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${AWS_CREDS_ID}"]]) {
                        def ecrRegistry = "${env.AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
                        // Login to ECR
                        sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ecrRegistry}"
                        
                        // Build and Push
                        sh "docker build -t ${ecrRegistry}/${PROJECT_NAME}:${GIT_COMMIT_REV} ."
                        sh "docker push ${ecrRegistry}/${PROJECT_NAME}:${GIT_COMMIT_REV}"
                    }
                }
            }
        }

        stage('Terraform Infrastructure') {
            steps {
                // withAWS uses the detected account ID and the role name
                withAWS(role: "${DEPLOY_ROLE_NAME}", roleAccount: "${env.AWS_ACCOUNT_ID}", region: "${AWS_REGION}") {
                    dir('terraform') {
                        sh """
                            terraform init \
                                -backend-config="bucket=${S3_BUCKET_NAME}" \
                                -backend-config="key=autodesk-project/terraform.tfstate" \
                                -backend-config="region=${AWS_REGION}"
                        """
                        sh "terraform apply -var='image_tag=${GIT_COMMIT_REV}' -auto-approve"
                    }
                }
            }
        }
    }
}