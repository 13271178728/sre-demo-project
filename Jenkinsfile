stage('SSH Debug') {
    steps {
        sshagent(['github-ssh-key']) {
            sh '''
                echo "=== SSH Debug Info ==="
                echo "SSH Agent 状态:"
                ssh-add -l || echo "No keys in agent"
                
                echo "SSH 连接测试:"
                ssh -T git@github.com || true
                
                echo "当前用户: $(whoami)"
                echo "HOME 目录: $HOME"
                ls -la $HOME/.ssh/ || echo "No .ssh directory"
            '''
        }
    }
}

stage('Checkout') {
    steps {
        sshagent(['github-ssh-key']) {
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
