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
                    sh '''
                        echo "=== 创建 terraform.tfvars ==="
                        cat > terraform.tfvars << 'EOF'
auth_url = "http://10.1.1.180:5000/v3"
tenant_name = "admin"
user_name = "admin"
password = "jiaxun@123"
region = "RegionOne"
image_name = "ceos-arrch"
flavor_name = "flavor1"
key_pair_name = "sre-demo-key"
network_name = "network2"
EOF
                        chmod 600 terraform.tfvars
                        echo "✅ 变量文件创建完成"
                    '''
                }
            }
        }

        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
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
                        terraform plan \
                            -var "build_id=${BUILD_ID}" \
                            -var "app_env=${ENVIRONMENT}"
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
                    sh 'terraform apply -auto-approve'
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
            echo "操作完成: ${params.ACTION}"
        }
    }
}
