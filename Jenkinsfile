// Jenkinsfile.ssh-test
pipeline {
    agent any
    
    stages {
        stage('Test SSH Checkout') {
            steps {
                // 直接使用 SSH URL 测试
                git branch: 'main',
                    url: 'git@github.com:13271178728/sre-demo-project.git',
                    credentialsId: 'github-ssh-key'
                
                sh 'ls -la'
            }
        }
    }
}
