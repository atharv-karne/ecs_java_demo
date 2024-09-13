pipeline {
    agent any
    stages {
        stage('Create ECR Repository') 
        {
            steps {
                script {
                    def repoName = 'my-spring-boot-app'

                    withCredentials([aws(credentialsId: 'AWS-Cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        sh """
                            aws ecr create-repository --repository-name ${repoName} --region <your-region> || true
                        """
                    }
                }
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
                    {
                        sh 'docker build -t my-spring-boot-app .'
                    }
                }
            }
        }
        stage('Push Docker Image to ECR') {
            steps {
                script {
                    def repoName = 'my-spring-boot-app'
                    def region = 'ap-south-1'
                    
                    withCredentials([aws(credentialsId: 'AWS-Cred', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        sh """
                            $(aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin <your-account-id>.dkr.ecr.${region}.amazonaws.com)
                        """
                        
                        sh """
                            docker tag my-spring-boot-app:latest 730335267178.dkr.ecr.${region}.amazonaws.com/${repoName}:latest
                        """
                        
                        sh """
                            docker push 730335267178.dkr.ecr.${region}.amazonaws.com/${repoName}:latest
                        """
                    }
                }
            }
        // stage('Terraform plan') 
        // {
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
}