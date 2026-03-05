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
                checkout scm
                sh 'echo "代码检出成功"'
            }
        }
        
        stage('Check Terraform Files') {
            steps {
                dir('terraform') {
                    sh '''
                        echo "=== 检查 Terraform 文件 ==="
                        ls -la
                        echo "=== main.tf 内容预览 ==="
                        cat main.tf | head -20
                    '''
                }
            }
        }
        
        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    sh '''
                        echo "=== 初始化 Terraform ==="
                        terraform init
                    '''
                }
            }
        }
        
        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    sh '''
                        echo "=== 生成执行计划 ==="
                        terraform plan \
                            -var "build_id=${BUILD_ID}" \
                            -var "app_env=${ENVIRONMENT}"
                    '''
                }
            }
        }
        
        stage('Show Outputs') {
            steps {
                dir('terraform') {
                    sh '''
                        echo "=== 计划完成 ==="
                        echo "环境: ${ENVIRONMENT}"
                        echo "构建ID: ${BUILD_ID}"
                        echo "如果这是 apply，将会创建虚拟机"
                    '''
                }
            }
        }
    }
    
    post {
        always {
            echo "阶段4执行完成"
        }
        success {
            echo "✅ Terraform Plan 成功"
        }
        failure {
            echo "❌ Terraform Plan 失败"
        }
    }
}
