pipeline {
    agent any
    stages {
        stage('Create ECR Repository') {
            steps {
                script {
                    def repoName = 'my-spring-boot-app'
                    
                    withCredentials([aws(credentialsId: 'AWS-Cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        sh "aws ecr create-repository --repository-name ${repoName} --region ap-south-1 || true"
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build -t my-spring-boot-app ."
                }
            }
        }

        stage('Push Docker Image to ECR') {
            steps {
                script {
                    def repoName = 'my-spring-boot-app'
                    def region = 'ap-south-1'
                    def accountId = '730335267178'
                    
                    withCredentials([aws(credentialsId: 'AWS-Cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        sh """
                            aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin ${accountId}.dkr.ecr.${region}.amazonaws.com
                        """
                        
                        sh "docker tag my-spring-boot-app:latest ${accountId}.dkr.ecr.${region}.amazonaws.com/${repoName}:latest"
                        
                        sh "docker push ${accountId}.dkr.ecr.${region}.amazonaws.com/${repoName}:latest"
                    }
                }
            }
        }

        stage('Terraform apply') {
            steps {
                script {
                    withCredentials([aws(credentialsId: 'AWS-Cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        sh 'terraform apply -auto-approve'
                    }
                }
            }
        }
    }
}
