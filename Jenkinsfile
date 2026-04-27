pipeline {
    agent none // Do not use a global agent

    environment {
        // --- Dynamic Configuration (Market Best Practice) ---
        AWS_REGION        = 'ap-southeast-1'
        PROJECT_NAME      = 'auto-deployment-jenkins'
        AWS_CREDS_ID      = 'aws-static-creds'
        S3_BUCKET_NAME    = 'yuanyang-terraform-state-2026'
        DEPLOY_ROLE_NAME  = 'jenkins-test'
        // Metadata
        GIT_COMMIT_REV    = ""
    }

        stage('Setup & Discovery') {
            agent { 
                docker { 
                    image 'amazon/aws-cli:latest' 
                    args '--entrypoint=""' // FIX: Allows Jenkins to run scripts inside this image
                } 
            } 
            steps {
                script {
                    // FIX: Use Jenkins built-in variable (first 7 chars) instead of 'sh git'
                    env.GIT_COMMIT_REV = "${env.GIT_COMMIT}".take(7)
                    
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding', 
                        credentialsId: "${AWS_CREDS_ID}"
                    ]]) {
                        env.AWS_ACCOUNT_ID = sh(script: "aws sts get-caller-identity --query Account --output text", returnStdout: true).trim()
                        env.S3_BUCKET_NAME = sh(script: "aws s3api list-buckets --query 'Buckets[?contains(Name, `terraform-state`)].Name' --output text", returnStdout: true).trim()
                        
                        echo "Targeting Account: ${env.AWS_ACCOUNT_ID} | Revision: ${env.GIT_COMMIT_REV}"
                    }
                }
            }
        }

        stage('Run Tests') {
            // FIX: Using the proper docker agent syntax
            agent { docker { image 'python:3.11-slim' } } 
            steps {
                // Installs requirements fresh in the ephemeral container
                sh 'pip install -r requirements.txt pytest flask || true' 
                sh 'pytest --maxfail=1 --disable-warnings -q'
            }
        }

        stage('Build & Push') {
            agent { 
                docker { 
                    image 'docker:latest'
                    // Mounts the host socket to allow building images from inside the agent
                    args '-v /var/run/docker.sock:/var/run/docker.sock -u root' 
                } 
            }
            steps {
                script {
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding', 
                        credentialsId: "${AWS_CREDS_ID}"
                    ]]) {
                        def ecrRegistry = "${env.AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
                        
                        // Login to ECR
                        sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ecrRegistry}"
                        
                        // Build and Tag
                        sh "docker build -t ${ecrRegistry}/${PROJECT_NAME}:${GIT_COMMIT_REV} ."
                        
                        // Ensure ECR repository exists
                        sh """
                            aws ecr describe-repositories --repository-names ${PROJECT_NAME} \
                            || aws ecr create-repository --repository-name ${PROJECT_NAME}
                        """
                        
                        // Push to AWS
                        sh "docker push ${ecrRegistry}/${PROJECT_NAME}:${GIT_COMMIT_REV}"
                    }
                }
            }
        }

        stage('Terraform Infrastructure') {
            // FIX: Official Terraform image wrapped in docker block
            agent { docker { image 'hashicorp/terraform:1.7.5' } } 
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${AWS_CREDS_ID}"]]) {
                    dir('terraform') {
                        sh """
                            terraform init \
                                -backend-config="bucket=${env.S3_BUCKET_NAME}" \
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