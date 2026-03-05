// Jenkinsfile.fixed
pipeline {
    agent any
    
    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['staging', 'dev'],
            description: '选择部署环境'
        )
        string(
            name: 'BUILD_ID',
            defaultValue: "${BUILD_NUMBER}",
            description: '构建ID'
        )
    }
    
    stages {
        stage('Checkout') {
            steps {
                // 使用简单的 git 命令，和成功的测试一样
                sh '''
                    echo "=== 克隆代码 ==="
                    rm -rf sre-demo-project || true
                    git clone git@github.com:13271178728/sre-demo-project.git sre-demo-project
                    cd sre-demo-project
                    git checkout main
                    echo "=== 克隆完成 ==="
                    ls -la
                '''
            }
        }
        
        stage('Check Terraform Files') {
            steps {
                dir('sre-demo-project/terraform') {
                    sh '''
                        echo "=== 检查 Terraform 文件 ==="
                        ls -la
                        if [ ! -f main.tf ]; then
                            echo "❌ main.tf 不存在"
                            exit 1
                        fi
                        echo "✅ 所有文件存在"
                    '''
                }
            }
        }
        
        stage('Terraform Init') {
            steps {
                dir('sre-demo-project/terraform') {
                    sh 'terraform init'
                }
            }
        }
        
        stage('Terraform Plan') {
            steps {
                dir('sre-demo-project/terraform') {
                    sh """
                        terraform plan \
                            -var "build_id=${BUILD_ID}" \
                            -var "app_env=${ENVIRONMENT}"
                    """
                }
            }
        }
    }
    
    post {
        success {
            echo "✅ 构建成功"
        }
        failure {
            echo "❌ 构建失败"
        }
    }
}
