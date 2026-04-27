pipeline {
    agent none // Don't use a global agent

    environment {
        AWS_REGION        = 'ap-southeast-1'
        PROJECT_NAME      = 'auto-deployment-jenkins'
        AWS_CREDS_ID      = 'aws-static-creds'
        S3_BUCKET_NAME    = 'yuanyang-terraform-state-2026'
        DEPLOY_ROLE_NAME  = 'jenkins-test'
        // Metadata
        GIT_COMMIT_REV    = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
    }

    stages {
        stage('Auto-Detect Account ID') {
            agent { image 'amazon/aws-cli:latest' } // Use AWS CLI image
            steps {
                script {
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
            agent { image 'python:3.11-slim' } // Use Python image
            steps {
                // We install requirements fresh in the container for testing
                sh 'pip install -r requirements.txt pytest flask'
                sh 'pytest --maxfail=1 --disable-warnings -q'
            }
        }

        stage('Build & Push') {
            agent { 
                docker { 
                    image 'docker:latest' // Use Docker-in-Docker agent
                    args '-v /var/run/docker.sock:/var/run/docker.sock -u root' 
                } 
            }
            steps {
                script {
                    // Use standard env vars for AWS login inside the Docker container
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding', 
                        credentialsId: "${AWS_CREDS_ID}"
                    ]]) {
                        def ecrRegistry = "${env.AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
                        
                        // Login to ECR
                        sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ecrRegistry}"
                        
                        // Build and Push
                        sh "docker build -t ${ecrRegistry}/${PROJECT_NAME}:${GIT_COMMIT_REV} ."
                        
                        // Ensure repo exists (requires AWS CLI, which docker:latest usually includes)
                        sh "aws ecr describe-repositories --repository-names ${PROJECT_NAME} || aws ecr create-repository --repository-name ${PROJECT_NAME}"
                        
                        sh "docker push ${ecrRegistry}/${PROJECT_NAME}:${GIT_COMMIT_REV}"
                    }
                }
            }
        }

        stage('Terraform Infrastructure') {
            agent { image 'hashicorp/terraform:1.7.5' } // Use official Terraform image
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${AWS_CREDS_ID}"]]) {
                    dir('terraform') {
                        // Terraform uses these ENV vars automatically if they exist
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