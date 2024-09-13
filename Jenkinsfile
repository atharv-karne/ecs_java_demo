pipeline {
    agent any
    stages {
        stage('Create ECR Repository') {
            steps {
                script {
                    def repoName = 'my-spring-boot-app'
                    
                    withCredentials([aws(credentialsId: 'AWS-Cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        sh """
                            aws ecr create-repository --repository-name ${repoName} --region ap-south-1 || true
                        """
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    // Build the Docker image
                    sh 'docker build -t my-spring-boot-app .'
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
                        // Authenticate Docker to the ECR registry
                        sh """
                            $(aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin ${accountId}.dkr.ecr.${region}.amazonaws.com)
                        """
                        
                        // Tag the Docker image
                        sh """
                            docker tag my-spring-boot-app:latest ${accountId}.dkr.ecr.${region}.amazonaws.com/${repoName}:latest
                        """
                        
                        // Push the Docker image
                        sh """
                            docker push ${accountId}.dkr.ecr.${region}.amazonaws.com/${repoName}:latest
                        """
                    }
                }
            }
        }

        // Uncomment and adjust as needed for Terraform
        // stage('Terraform plan') {
        //     steps {
        //         script {
        //             withCredentials([aws(credentialsId: 'AWS-Cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
        //                 sh 'terraform plan'
        //                 sh 'terraform apply -auto-approve'
        //             }
        //         }
        //     }
        // }
    }
}
