pipeline {
    agent any
    
    environment {
        // 临时跳过 SSH 主机密钥验证（仅测试用）
        GIT_SSH_COMMAND = "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[
                        url: 'git@github.com:13271178728/sre-demo-project.git',
                        credentialsId: 'github-ssh-key'
                    ]]
                ])
            }
        }
    }
}
