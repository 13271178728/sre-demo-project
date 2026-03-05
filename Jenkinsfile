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
                sh 'ls -la'
            }
        }
        
        stage('Prepare Terraform Files') {
            steps {
                dir('terraform') {
                    // 使用从凭证中获取的 tfvars 文件
                    withCredentials([file(credentialsId: 'terraform-tfvars', variable: 'TFVARS_FILE')]) {
                        sh '''
                            echo "=== 复制 Terraform 变量文件 ==="
                            cp ${TFVARS_FILE} terraform.tfvars
                            chmod 600 terraform.tfvars
                            
                            echo "=== 检查文件 ==="
                            ls -la
                            
                            echo "=== 验证必要文件（隐藏密码）==="
                            cat terraform.tfvars | grep -v password
                        '''
                    }
                }
            }
        }
        
        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    sh '''
                        terraform init
                    '''
                }
            }
        }
        
        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    sh '''
                        terraform plan \
                            -var "build_id=${BUILD_ID}" \
                            -var "app_env=${ENVIRONMENT}"
                    '''
                }
            }
        }
    }
    
    post {
        success {
            echo "✅ Plan 成功"
        }
        failure {
            echo "❌ Plan 失败"
        }
    }
}
