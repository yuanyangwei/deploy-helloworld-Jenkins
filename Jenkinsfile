pipeline {
    agent none 

    environment {
        AWS_REGION       = 'ap-southeast-1'
        PROJECT_NAME     = 'auto-deployment-jenkins'
        AWS_CREDS_ID     = 'aws-static-creds'
        S3_BUCKET_NAME   = 'yuanyang-terraform-state-2026'
        DEPLOY_ROLE_NAME = 'jenkins-test'
        GIT_COMMIT_REV   = ""
    }

    // CRITICAL FIX: Added the missing stages wrapper
    stages {
        stage('Setup & Discovery') {
            agent { 
                docker { 
                    image 'amazon/aws-cli:latest' 
                    args '--entrypoint=""' 
                } 
            } 
            steps {
                script {
                    // Pulls the 7-character short hash
                    env.GIT_COMMIT_REV = "${env.GIT_COMMIT}".take(7)
                    
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding', 
                        credentialsId: "${AWS_CREDS_ID}"
                    ]]) {
                        env.AWS_ACCOUNT_ID = sh(script: "aws sts get-caller-identity --query Account --output text", returnStdout: true).trim()
                        // This dynamically updates the bucket name if it matches the pattern
                        env.S3_BUCKET_NAME = "yuanyang-terraform-state-2026"
                        
                        echo "Targeting Account: ${env.AWS_ACCOUNT_ID} | Revision: ${env.GIT_COMMIT_REV}"
                    }
                }
            }
        }

        stage('Run Tests') {
            agent { docker { image 'python:3.11-slim' } } 
            steps {
                sh 'pip install -r requirements.txt pytest flask || true' 
                sh 'pytest --maxfail=1 --disable-warnings -q'
            }
        }

        stage('Build & Push') {
            agent { 
                docker { 
                    image 'docker:latest'
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
                        
                        sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ecrRegistry}"
                        
                        // FIX: Added env. prefix for the dynamic variable
                        sh "docker build -t ${ecrRegistry}/${PROJECT_NAME}:${env.GIT_COMMIT_REV} ."
                        
                        sh """
                            aws ecr describe-repositories --repository-names ${PROJECT_NAME} \
                            || aws ecr create-repository --repository-name ${PROJECT_NAME}
                        """
                        
                        sh "docker push ${ecrRegistry}/${PROJECT_NAME}:${env.GIT_COMMIT_REV}"
                    }
                }
            }
        }

        stage('Terraform Infrastructure') {
            agent { 
                docker { 
                    image 'hashicorp/terraform:1.7.5' 
                    args '--entrypoint=""' // FIX: Ensure shell commands can run
                } 
            } 
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${AWS_CREDS_ID}"]]) {
                    dir('terraform') {
                        sh """
                            terraform init \
                                -backend-config="bucket=${env.S3_BUCKET_NAME}" \
                                -backend-config="key=autodesk-project/terraform.tfstate" \
                                -backend-config="region=${AWS_REGION}"
                        """
                        // FIX: Added env. prefix
                        sh "terraform apply -var='image_tag=${env.GIT_COMMIT_REV}' -auto-approve"
                    }
                }
            }
        }
    } // End of stages
}