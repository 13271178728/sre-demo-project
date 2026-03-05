pipeline {
    agent any
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Check Tools') {
            steps {
                sh '''
                    echo "=== 检查必要工具 ==="
                    python3 --version
                    pytest --version || echo "pytest not installed"
                    terraform version || echo "terraform not installed"
                '''
            }
        }
        
        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    sh '''
                        echo "=== 尝试初始化 ==="
                        terraform init || echo "terraform init failed"
                    '''
                }
            }
        }
    }
}
