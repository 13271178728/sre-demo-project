// Jenkinsfile.debug
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
                sh '''
                    echo "=== 详细目录调试 ==="
                    
                    # 1. 显示当前目录
                    echo "1. 当前目录: $(pwd)"
                    
                    # 2. 清理旧目录
                    echo "2. 清理旧目录"
                    rm -rf sre-demo-project
                    
                    # 3. 克隆代码
                    echo "3. 克隆代码"
                    git clone git@github.com:13271178728/sre-demo-project.git sre-demo-project
                    
                    # 4. 查看克隆结果
                    echo "4. 克隆结果:"
                    ls -la sre-demo-project/
                    
                    # 5. 进入项目目录
                    echo "5. 进入项目目录"
                    cd sre-demo-project
                    
                    # 6. 查看当前分支
                    echo "6. 当前分支:"
                    git branch
                    
                    # 7. 查看所有文件
                    echo "7. 项目文件列表:"
                    ls -la
                    
                    # 8. 特别检查 terraform 目录
                    echo "8. terraform 目录内容:"
                    if [ -d "terraform" ]; then
                        ls -la terraform/
                        echo "✅ terraform 目录存在"
                    else
                        echo "❌ terraform 目录不存在"
                    fi
                '''
            }
        }
        
        stage('Check Files') {
            steps {
                script {
                    // 检查必要文件
                    def filesToCheck = [
                        'sre-demo-project/terraform/main.tf',
                        'sre-demo-project/terraform/variables.tf',
                        'sre-demo-project/terraform/outputs.tf'
                    ]
                    
                    for (file in filesToCheck) {
                        if (fileExists(file)) {
                            echo "✅ ${file} 存在"
                        } else {
                            echo "❌ ${file} 不存在"
                        }
                    }
                }
            }
        }
        
        // 如果文件存在，再继续
        stage('Terraform Init') {
            when {
                expression { fileExists('sre-demo-project/terraform/main.tf') }
            }
            steps {
                dir('sre-demo-project/terraform') {
                    sh 'terraform init'
                }
            }
        }
    }
}
