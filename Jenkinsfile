// Jenkinsfile.debug-apply
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
                
                sh '''
                    echo "=== 克隆完成 ==="
                    ls -la
                '''
            }
        }
        
        stage('Debug Credentials') {
            steps {
                script {
                    // 检查是否有凭证
                    def creds = com.cloudbees.plugins.credentials.CredentialsProvider.lookupCredentials(
                        com.cloudbees.plugins.credentials.common.StandardCredentials,
                        jenkins.model.Jenkins.instance,
                        null,
                        null
                    )
                    
                    echo "=== 可用凭证列表 ==="
                    creds.each { cred ->
                        echo "ID: ${cred.id}, Type: ${cred.class.simpleName}"
                    }
                }
            }
        }
        
        stage('Prepare Terraform Variables') {
            steps {
                dir('terraform') {
                    script {
                        try {
                            withCredentials([file(credentialsId: 'terraform-tfvars', variable: 'TFVARS_FILE')]) {
                                sh '''
                                    echo "=== 开始准备变量文件 ==="
                                    echo "TFVARS_FILE: ${TFVARS_FILE}"
                                    
                                    echo "=== 检查源文件 ==="
                                    ls -la ${TFVARS_FILE} || echo "源文件不存在"
                                    
                                    echo "=== 复制文件 ==="
                                    cp -v ${TFVARS_FILE} terraform.tfvars
                                    
                                    echo "=== 设置权限 ==="
                                    chmod 600 terraform.tfvars
                                    
                                    echo "=== 验证文件 ==="
                                    ls -la terraform.tfvars
                                    
                                    echo "=== 文件内容（不含密码）==="
                                    cat terraform.tfvars | grep -v -E 'password|token|key'
                                    
                                    echo "✅ 变量文件准备完成"
                                '''
                            }
                        } catch (Exception e) {
                            echo "❌ 准备变量文件失败: ${e.message}"
                            // 创建临时变量文件用于测试
                            sh '''
                                echo "=== 创建临时变量文件用于测试 ==="
                                cat > terraform.tfvars << 'EOF'
auth_url = "http://10.1.1.180:5000/v3"
tenant_name = "demo"
user_name = "demo"
password = "demo"
region = "RegionOne"
image_name = "ubuntu-22.04"
flavor_name = "m1.small"
key_pair_name = "sre-demo-key"
network_name = "private-network"
EOF
                                echo "✅ 已创建临时变量文件"
                                cat terraform.tfvars | grep -v password
                            '''
                        }
                    }
                }
            }
        }
        
        stage('Check Terraform Files') {
            steps {
                dir('terraform') {
                    sh '''
                        echo "=== 检查 Terraform 文件 ==="
                        ls -la
                        
                        echo "=== main.tf 内容预览 ==="
                        head -30 main.tf
                        
                        echo "=== terraform.tfvars 存在性 ==="
                        if [ -f terraform.tfvars ]; then
                            echo "✅ terraform.tfvars 存在"
                        else
                            echo "❌ terraform.tfvars 不存在"
                        fi
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
    }
    
    post {
        always {
            echo "=== 构建完成 ==="
            echo "操作: ${params.ACTION}"
            echo "结果: ${currentBuild.result ?: 'SUCCESS'}"
            
            // 收集日志文件
            archiveArtifacts artifacts: 'terraform/*.log', allowEmptyArchive: true
        }
        success {
            script {
                if (params.ACTION == 'apply') {
                    def vmIp = readFile('vm_ip.txt').trim()
                    echo "✅ 虚拟机创建成功！IP: ${vmIp}"
                } else if (params.ACTION == 'destroy') {
                    echo "✅ 资源已销毁"
                } else if (params.ACTION == 'plan') {
                    echo "✅ Plan 执行成功"
                }
            }
        }
        failure {
            echo "❌ 操作失败"
            script {
                // 显示最后 50 行日志
                def log = currentBuild.rawBuild.getLog(50).join('\n')
                echo "最后 50 行日志:\n${log}"
            }
        }
    }
}
