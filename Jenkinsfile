pipeline {
    agent any

    stages {
        stage('Lint') {
            steps {
                script {
                    sh 'helm lint charts/*'
                }
            }
        }
        stage('Build') {
            steps {
                script {
                    docker.build('user/app:latest', '-f apps/webapp/Dockerfile apps/webapp')
                }
            }
        }
        stage('E2E Test') {
            steps {
                script {
                    sh 'pip install -r tests/requirements.txt'
                    sh 'pytest tests/e2e_test.py'
                }
            }
        }
    }
}
