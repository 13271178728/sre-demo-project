// Jenkinsfile - SRE Demo Pipeline
pipeline {
    agent any
    
    parameters {
        choice(name: 'ACTION', choices: ['plan', 'apply', 'destroy'], description: 'Terraform Action')
        string(name: 'BRANCH', defaultValue: 'main', description: 'Git Branch')
        string(name: 'APP_ENV', defaultValue: 'staging', description: 'Environment')
    }
    
    environment {
        // 从 Jenkins 凭证读取
        GITHUB_TOKEN = credentials('github-api-token')
        OS_AUTH_URL = credentials('openstack-auth-url')
        OS_USERNAME = credentials('openstack-username')
        OS_PASSWORD = credentials('openstack-password')
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: "*/${params.BRANCH}"]],
                    userRemoteConfigs: [[
                        url: 'https://github.com/your-org/sre-demo-project.git',
                        credentialsId: 'github-ssh-key'
                    ]]
                ])
            }
        }
        
        stage('Quality Gate') {
            steps {
                sh '''
                    python3 -m venv venv
                    . venv/bin/activate
                    pip install -r requirements.txt
                    pytest test_sample.py -v --junitxml=test-results.xml
                '''
            }
            post {
                always {
                    junit 'test-results.xml'
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
        
        stage('Terraform Plan/Apply') {
            steps {
                dir('terraform') {
                    script {
                        def action = params.ACTION
                        def vars = "-var build_id=${BUILD_NUMBER} -var app_env=${params.APP_ENV}"
                        
                        if (action == 'plan') {
                            sh "terraform plan ${vars}"
                        } else if (action == 'apply') {
                            sh "terraform apply -auto-approve ${vars}"
                            sh 'terraform output instance_ip > ../instance_ip.txt'
                        } else if (action == 'destroy') {
                            sh "terraform destroy -auto-approve ${vars}"
                        }
                    }
                }
            }
        }
        
        stage('Smoke Test') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                script {
                    def instanceIp = readFile('instance_ip.txt').trim()
                    sh """
                        timeout 300 bash -c 'while ! nc -zv ${instanceIp} 22; do sleep 5; done'
                        echo "VM is ready!"
                    """
                }
            }
        }
    }
    
    post {
        success {
            echo "Pipeline completed successfully!"
            // 更新 GitHub 状态
            githubNotify(
                context: 'sre-pipeline',
                description: "Build #${BUILD_NUMBER} succeeded",
                status: 'SUCCESS'
            )
        }
        failure {
            echo "Pipeline failed!"
            githubNotify(
                context: 'sre-pipeline',
                description: "Build #${BUILD_NUMBER} failed",
                status: 'FAILURE'
            )
        }
    }
}
