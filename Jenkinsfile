pipeline {
    agent any
    stages {
        stage('Checkout Code') {
            steps {
                script {
                    sh 'mkdir -p javaapp'
                    
                    dir('javaapp') {
                        sh 'git clone https://github.com/atharv-karne/ecs_java_demo.git'
                        

                    }
                }
            }
        }
    }
}
