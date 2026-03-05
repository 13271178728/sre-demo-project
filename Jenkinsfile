// Jenkinsfile.ssh-test
pipeline 

   environment {
        // 临时跳过 SSH 主机密钥验证（仅测试用）
        GIT_SSH_COMMAND = "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
    }


{
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
