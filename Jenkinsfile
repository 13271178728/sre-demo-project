// Jenkinsfile - SRE 标准流水线
pipeline {
    agent any
    
    environment {
        // 构建信息
        BUILD_ID = "${BUILD_NUMBER}"
        BUILD_TIME = timestamp()
        
        // 环境标识
        APP_ENV = "staging"  // 可根据分支动态设置
        
        // Terraform 工作目录
        TF_DIR = "${WORKSPACE}/terraform"
        
        // 从 Jenkins 凭证获取敏感信息
        OS_AUTH_URL = credentials('openstack-auth-url')
        OS_USERNAME = credentials('openstack-username')
        OS_PASSWORD = credentials('openstack-password')
        OS_PROJECT_NAME = credentials('openstack-project')
    }
    
    parameters {
        choice(
            name: 'ACTION',
            choices: ['plan', 'apply', 'destroy'],
            description: '选择 Terraform 操作'
        )
        string(
            name: 'TARGET_BRANCH',
            defaultValue: 'main',
            description: '要部署的分支'
        )
    }
    
    stages {
        // Stage 1: 代码检出
        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: "${params.TARGET_BRANCH}"]],
                    userRemoteConfigs: [[
                        url: 'https://gitlab.com/your-project/sre-demo-project.git',
                        credentialsId: 'gitlab-credentials'
                    ]]
                ])
            }
        }
        
        // Stage 2: 质量门禁 - SRE 左移实践[citation:5]
        stage('Quality Gate') {
            steps {
                script {
                    try {
                        sh '''
                            cd ${WORKSPACE}
                            python3 -m venv venv
                            . venv/bin/activate
                            pip install -r requirements.txt
                            pytest test_sample.py -v --junitxml=test-results.xml
                        '''
                    } finally {
                        // 收集测试报告
                        junit 'test-results.xml'
                    }
                }
            }
            post {
                failure {
                    // 质量门禁失败时发送告警
                    emailext(
                        to: 'sre-team@example.com',
                        subject: "质量门禁失败: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                        body: "请检查代码质量: ${env.BUILD_URL}"
                    )
                }
            }
        }
        
        // Stage 3: Terraform 初始化
        stage('Terraform Init') {
            steps {
                dir("${TF_DIR}") {
                    sh '''
                        terraform init
                    '''
                }
            }
        }
        
        // Stage 4: Terraform 执行
        stage('Terraform Execution') {
            when {
                expression { params.ACTION != 'destroy' }
            }
            steps {
                dir("${TF_DIR}") {
                    script {
                        def action = params.ACTION
                        def extraVars = "-var build_id=${BUILD_ID} -var app_env=${APP_ENV}"
                        
                        if (action == 'plan') {
                            sh "terraform plan ${extraVars}"
                        } else if (action == 'apply') {
                            sh "terraform apply -auto-approve ${extraVars}"
                            
                            // 保存输出信息供后续 Stage 使用
                            sh '''
                                terraform output instance_ip > ${WORKSPACE}/instance_ip.txt
                                terraform output security_group_name > ${WORKSPACE}/sg_name.txt
                            '''
                        }
                    }
                }
            }
        }
        
        // Stage 5: 部署验证 - 冒烟测试
        stage('Smoke Test') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                script {
                    def instanceIp = readFile('instance_ip.txt').trim()
                    
                    // SRE 核心：等待服务就绪并验证[citation:9]
                    sh """
                        # 等待 SSH 就绪
                        timeout 300 bash -c 'while ! nc -zv ${instanceIp} 22; do sleep 5; done'
                        
                        # 等待 cloud-init 完成
                        sleep 30
                        
                        # 验证 cloud-init 脚本执行
                        ssh -o StrictHostKeyChecking=no \
                            -i ~/.ssh/${JOB_NAME}.pem \
                            ubuntu@${instanceIp} \
                            'cat /tmp/welcome.txt | grep "Build ${BUILD_ID}"'
                        
                        # 验证基础服务
                        ssh ubuntu@${instanceIp} '
                            systemctl is-active docker &&
                            systemctl is-active prometheus-node-exporter
                        '
                    """
                }
            }
            post {
                failure {
                    // 验证失败时自动销毁资源（SRE 错误预算实践）
                    echo "冒烟测试失败，触发自动销毁..."
                    dir("${TF_DIR}") {
                        sh "terraform destroy -auto-approve -var build_id=${BUILD_ID} -var app_env=${APP_ENV}"
                    }
                }
            }
        }
        
        // Stage 6: 可观测性集成
        stage('Observability Integration') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                script {
                    def instanceIp = readFile('instance_ip.txt').trim()
                    
                    // 注册到监控系统（示例：Prometheus 自动发现）
                    sh """
                        curl -X POST http://prometheus-server:9090/api/v1/targets \
                            -H "Content-Type: application/json" \
                            -d '{
                                "targets": ["${instanceIp}:9100"],
                                "labels": {
                                    "job": "node",
                                    "environment": "${APP_ENV}",
                                    "build_id": "${BUILD_ID}"
                                }
                            }'
                    """
                    
                    // 记录部署信息到 CMDB（示例）
                    echo "部署完成: ${instanceIp} | 构建: ${BUILD_ID} | 时间: ${BUILD_TIME}"
                }
            }
        }
        
        // Stage 7: 清理资源
        stage('Cleanup') {
            when {
                expression { params.ACTION == 'destroy' }
            }
            steps {
                dir("${TF_DIR}") {
                    sh '''
                        terraform destroy -auto-approve \
                            -var build_id=${BUILD_ID} \
                            -var app_env=${APP_ENV}
                    '''
                }
            }
        }
    }
    
    post {
        always {
            // 清理工作空间
            cleanWs()
        }
        success {
            script {
                if (params.ACTION == 'apply') {
                    def instanceIp = readFile('instance_ip.txt').trim()
                    echo "✅ 部署成功！虚拟机 IP: ${instanceIp}"
                    
                    // 发送成功通知到钉钉/微信/邮件
                    emailext(
                        to: 'team@example.com',
                        subject: "部署成功: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                        body: "虚拟机已创建，IP: ${instanceIp}\n访问地址: ${env.BUILD_URL}"
                    )
                }
            }
        }
        failure {
            echo "❌ 流水线执行失败"
            // 发送告警到 PagerDuty/Opsgenie
        }
    }
}
