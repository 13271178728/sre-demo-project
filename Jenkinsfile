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
                sh '''
                    echo "=== 当前目录 ==="
                    pwd
                    echo "=== 文件列表 ==="
                    ls -la
                '''
            }
        }
        
        stage('Check Terraform Directory') {
            steps {
                sh '''
                    echo "=== 检查 terraform 目录 ==="
                    if [ -d "terraform" ]; then
                        echo "✅ terraform 目录存在"
                        cd terraform
                        ls -la
                    else
                        echo "❌ terraform 目录不存在"
                        exit 1
                    fi
                '''
            }
        }
        
        stage('Check Terraform Files') {
            steps {
                dir('terraform') {
                    sh '''
                        echo "=== 检查必要文件 ==="
                        for file in main.tf variables.tf outputs.tf; do
                            if [ -f "$file" ]; then
                                echo "✅ $file 存在"
                            else
                                echo "❌ $file 不存在"
                            fi
                        done
                        
                        echo "=== terraform.tfvars 检查 ==="
                        if [ -f "terraform.tfvars" ]; then
                            echo "✅ terraform.tfvars 存在"
                            echo "=== 内容预览（隐藏密码）==="
                            cat terraform.tfvars | grep -v password
                        else
                            echo "⚠️ terraform.tfvars 不存在，将使用环境变量"
                        fi
                    '''
                }
            }
        }
        
        stage('Terraform Version') {
            steps {
                sh '''
                    echo "=== Terraform 版本 ==="
                    terraform version || echo "❌ Terraform 未安装"
                    
                    echo "=== 检查 Terraform 工作目录 ==="
                    which terraform
                '''
            }
        }
        
        stage('Terraform Init Debug') {
            steps {
                dir('terraform') {
                    sh '''
                        echo "=== 清理旧配置 ==="
                        rm -rf .terraform .terraform.lock.hcl
                        
                        echo "=== 初始化（带调试）==="
                        TF_LOG=DEBUG terraform init 2>&1 | tee terraform-init.log
                        
                        echo "=== 初始化结果 ==="
                        if [ $? -eq 0 ]; then
                            echo "✅ 初始化成功"
                        else
                            echo "❌ 初始化失败"
                            echo "=== 错误日志最后20行 ==="
                            tail -20 terraform-init.log
                            exit 1
                        fi
                    '''
                }
            }
        }
        
        stage('Terraform Plan Debug') {
            steps {
                dir('terraform') {
                    sh '''
                        echo "=== 执行 Terraform Plan ==="
                        echo "参数: build_id=${BUILD_ID}, app_env=${ENVIRONMENT}"
                        
                        # 尝试 plan，捕获所有输出
                        TF_LOG=DEBUG terraform plan \
                            -var "build_id=${BUILD_ID}" \
                            -var "app_env=${ENVIRONMENT}" \
                            2>&1 | tee terraform-plan.log
                        
                        PLAN_EXIT_CODE=$?
                        
                        if [ $PLAN_EXIT_CODE -eq 0 ]; then
                            echo "✅ Plan 成功"
                        else
                            echo "❌ Plan 失败，退出码: $PLAN_EXIT_CODE"
                            echo "=== 错误日志最后50行 ==="
                            tail -50 terraform-plan.log
                            
                            # 检查常见错误
                            if grep -q "no valid credential sources" terraform-plan.log; then
                                echo "⚠️ 认证失败：检查 OpenStack 凭证"
                            elif grep -q "Error finding" terraform-plan.log; then
                                echo "⚠️ 资源找不到：检查网络、镜像等配置"
                            elif grep -q "Permission denied" terraform-plan.log; then
                                echo "⚠️ 权限不足"
                            fi
                            
                            exit $PLAN_EXIT_CODE
                        fi
                    '''
                }
            }
        }
    }
    
    post {
        always {
            echo "=== 调试信息收集 ==="
            sh '''
                echo "=== 环境变量 ==="
                env | grep -E "OS_|TF_|BUILD" || true
            '''
            
            // 保存日志文件
            archiveArtifacts artifacts: 'terraform/*.log', allowEmptyArchive: true
        }
        success {
            echo "✅ 调试阶段成功"
        }
        failure {
            echo "❌ 调试阶段失败"
        }
    }
}
