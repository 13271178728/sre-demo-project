// Jenkinsfile.test
pipeline {
    agent any
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh 'ls -la'
            }
        }
        
        stage('Test Only') {
            steps {
                sh '''
                    echo "Testing only this stage"
                    # 先不运行实际命令
                '''
            }
        }
    }
}
