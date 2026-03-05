// Jenkinsfile.minimal
pipeline {
    agent any
    
    stages {
        stage('Git Clone Test') {
            steps {
                // 直接使用 git 命令测试
                sh '''
                    echo "=== Git 版本 ==="
                    git --version
                    
                    echo "=== 尝试直接 git clone ==="
                    rm -rf test-repo || true
                    GIT_SSH_COMMAND="ssh -v" git clone git@github.com:13271178728/sre-demo-project.git test-repo
                    
                    echo "=== Clone 结果 ==="
                    ls -la test-repo/
                '''
            }
        }
    }
}
