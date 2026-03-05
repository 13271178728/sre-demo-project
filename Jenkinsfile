// Jenkinsfile.https
pipeline {
    agent any
    
    stages {
        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/13271178728/sre-demo-project.git',
                        credentialsId: 'github-https-token'
                    ]]
                ])
            }
        }
    }
}
