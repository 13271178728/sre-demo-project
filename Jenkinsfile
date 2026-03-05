// Jenkinsfile.apply - 修复版
pipeline {
    agent any
    
    parameters {
        choice(
            name: 'ACTION',
            choices: ['plan', 'apply', 'destroy'],
            description: '选择 Terraform 操作'
        )
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
                git branch: 'main',
                    url: 'git@github.com:13271178728/sre-demo-project.git'
            }
        }
        
        stage('Prepare Terraform Variables') {
            steps {
                dir('terraform') {
                    withCredentials([file(credentialsId: 'terraform-tfvars', variable: 'TFVARS_FILE')]) {
                        sh '''
                            echo "=== 准备 Terraform 变量文件 ==="
                            cp ${TFVARS_FILE} terraform.tfvars
                            chmod 600 terraform.tfvars
                            echo "✅ 变量文件已准备"
                            
                            echo "=== 变量文件内容（隐藏密码）==="
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
                        echo "=== 初始化 Terraform ==="
                        terraform init
                    '''
                }
            }
        }
        
        stage('Terraform Plan') {
            when {
                expression { params.ACTION == 'plan' || params.ACTION == 'apply' }
            }
            steps {
                dir('terraform') {
                    sh """
                        echo "=== 执行 Terraform Plan ==="
                        echo "环境: ${ENVIRONMENT}"
                        echo "构建ID: ${BUILD_ID}"
                        
                        terraform plan \
                            -var "build_id=${BUILD_ID}" \
                            -var "app_env=${ENVIRONMENT}" \
                            -out=tfplan
                    """
                }
            }
        }
        
        stage('Terraform Apply') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                dir('terraform') {
                    sh '''
                        echo "=== 创建虚拟机 ==="
                        terraform apply tfplan
                        
                        echo "=== 虚拟机信息 ==="
                        terraform output
                        
                        # 保存 VM IP 用于后续步骤
                        terraform output -raw instance_ip > ../vm_ip.txt
                    '''
                }
            }
        }
        
        stage('Terraform Destroy') {
            when {
                expression { params.ACTION == 'destroy' }
            }
            steps {
                dir('terraform') {
                    sh """
                        echo "=== 销毁虚拟机 ==="
                        terraform destroy -auto-approve \
                            -var "build_id=${BUILD_ID}" \
                            -var "app_env=${ENVIRONMENT}"
                    """
                }
            }
        }
        
        stage('Verify VM') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                script {
                    def vmIp = readFile('vm_ip.txt').trim()
                    sh """
                        echo "=== 验证虚拟机 ==="
                        echo "虚拟机 IP: ${vmIp}"
                        
                        # 等待 SSH 就绪（最多等待 2 分钟）
                        echo "等待 SSH 服务启动..."
                        timeout 120 bash -c '
                            while ! nc -zv ${vmIp} 22; do
                                echo "  等待中..."
                                sleep 5
                            done
                        ' && echo "✅ SSH 已就绪" || echo "⚠️ SSH 未就绪"
                        
                        # 尝试连接并查看欢迎信息
                        ssh -o StrictHostKeyChecking=no \
                            -o ConnectTimeout=5 \
                            -i ~/.ssh/id_rsa \
                            ubuntu@${vmIp} \
                            'cat /tmp/welcome.txt' || echo "⚠️ 无法查看欢迎文件"
                    """
                }
            }
        }
    }
    
    post {
        always {
            echo "=== 构建完成 ==="
            echo "操作: ${params.ACTION}"
            echo "结果: ${currentBuild.result ?: 'SUCCESS'}"
        }
        success {
            script {
                // 注意：这里要用 script 块包裹
                if (params.ACTION == 'apply') {
                    def vmIp = readFile('vm_ip.txt').trim()
                    echo "✅ 虚拟机创建成功！IP: ${vmIp}"
                } else if (params.ACTION == 'destroy') {
                    echo "✅ 资源已销毁"
                } else if (params.ACTION == 'plan') {
                    echo "✅ Plan 执行成功，可以执行 apply"
                }
            }
        }
        failure {
            echo "❌ 操作失败，请查看日志"
            script {
                if (params.ACTION == 'apply') {
                    echo "⚠️ 虚拟机创建失败，可能需要手动清理资源"
                }
            }
        }
    }
}
