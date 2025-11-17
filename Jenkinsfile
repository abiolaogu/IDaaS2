pipeline {
    agent any

    environment {
        // Docker registry configuration
        DOCKER_REGISTRY = credentials('docker-registry')
        DOCKER_REGISTRY_URL = 'docker.io'

        // Application configuration
        APP_NAME = 'idaas-platform'
        APP_VERSION = "${env.BUILD_NUMBER}"

        // Image names
        WEBAPP_IMAGE = "idaas-webapp:${APP_VERSION}"
        KEYCLOAK_IMAGE = "idaas-keycloak:${APP_VERSION}"
        OAUTH2_PROXY_IMAGE = "idaas-oauth2-proxy:${APP_VERSION}"

        // Scanning thresholds
        TRIVY_SEVERITY = 'HIGH,CRITICAL'
        BANDIT_SEVERITY = 'medium'
    }

    options {
        // Keep builds for 30 days
        buildDiscarder(logRotator(numToKeepStr: '30'))

        // Add timestamps to console output
        timestamps()

        // Timeout after 1 hour
        timeout(time: 1, unit: 'HOURS')
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
                script {
                    // Get git commit info
                    env.GIT_COMMIT_SHORT = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()
                    env.BUILD_DATE = sh(
                        script: "date -u +'%Y-%m-%dT%H:%M:%SZ'",
                        returnStdout: true
                    ).trim()
                }
            }
        }

        stage('Lint') {
            parallel {
                stage('Helm Lint') {
                    steps {
                        echo 'Linting Helm charts...'
                        sh 'helm lint charts/webapp'
                        sh 'helm lint charts/keycloak'
                        sh 'helm lint charts/oauth2-proxy'
                    }
                }

                stage('Python Lint') {
                    steps {
                        echo 'Linting Python code...'
                        dir('apps/webapp') {
                            sh 'pip install flake8 black'
                            sh 'flake8 . --exclude=venv,env,tests --max-line-length=120 || true'
                            sh 'black --check . --exclude="venv|env|tests" || true'
                        }
                    }
                }
            }
        }

        stage('Dependency Scan') {
            steps {
                echo 'Scanning dependencies for vulnerabilities...'
                sh 'pip install safety pip-audit'
                sh 'bash scripts/dependency-scan.sh || true'

                // Archive reports
                archiveArtifacts artifacts: 'security-reports/*-dependencies*.json', allowEmptyArchive: true
                archiveArtifacts artifacts: 'security-reports/*-pip-audit*.json', allowEmptyArchive: true
            }
        }

        stage('SAST Scan') {
            steps {
                echo 'Running Static Application Security Testing...'
                sh 'pip install bandit'
                sh 'bash scripts/sast-scan.sh || true'

                // Archive reports
                archiveArtifacts artifacts: 'security-reports/*-bandit*.json', allowEmptyArchive: true
                archiveArtifacts artifacts: 'security-reports/*-bandit*.sarif', allowEmptyArchive: true
                archiveArtifacts artifacts: 'security-reports/*-flake8*.txt', allowEmptyArchive: true
            }
        }

        stage('Unit Tests') {
            steps {
                echo 'Running unit tests...'
                dir('apps/webapp') {
                    sh 'pip install -r requirements.txt'
                    sh 'pytest tests/ --cov=. --cov-report=xml --cov-report=html --cov-report=term -v'
                }

                // Archive test results
                archiveArtifacts artifacts: 'apps/webapp/htmlcov/**/*', allowEmptyArchive: true
                junit 'apps/webapp/coverage.xml'
            }
        }

        stage('Build Images') {
            parallel {
                stage('Build Webapp') {
                    steps {
                        echo 'Building webapp Docker image...'
                        script {
                            docker.build(
                                WEBAPP_IMAGE,
                                "--build-arg APP_VERSION=${APP_VERSION} " +
                                "--build-arg BUILD_DATE=${BUILD_DATE} " +
                                "--build-arg VCS_REF=${GIT_COMMIT_SHORT} " +
                                "-f apps/webapp/Dockerfile apps/webapp"
                            )
                        }
                    }
                }

                stage('Build Keycloak') {
                    steps {
                        echo 'Building Keycloak Docker image...'
                        script {
                            docker.build(KEYCLOAK_IMAGE, 'apps/keycloak')
                        }
                    }
                }

                stage('Build OAuth2 Proxy') {
                    steps {
                        echo 'Building OAuth2 Proxy Docker image...'
                        script {
                            docker.build(OAUTH2_PROXY_IMAGE, 'apps/oauth2-proxy')
                        }
                    }
                }
            }
        }

        stage('Container Security Scan') {
            steps {
                echo 'Scanning Docker images for vulnerabilities...'

                // Install Trivy if not present
                sh '''
                    if ! command -v trivy &> /dev/null; then
                        wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
                        echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
                        sudo apt-get update
                        sudo apt-get install trivy -y
                    fi
                '''

                // Scan images
                sh """
                    trivy image --severity ${TRIVY_SEVERITY} --format json --output security-reports/webapp-trivy.json ${WEBAPP_IMAGE} || true
                    trivy image --severity ${TRIVY_SEVERITY} --format json --output security-reports/keycloak-trivy.json ${KEYCLOAK_IMAGE} || true
                    trivy image --severity ${TRIVY_SEVERITY} --format json --output security-reports/oauth2-trivy.json ${OAUTH2_PROXY_IMAGE} || true
                """

                // Archive reports
                archiveArtifacts artifacts: 'security-reports/*-trivy.json', allowEmptyArchive: true
            }
        }

        stage('Integration Tests') {
            steps {
                echo 'Starting services for integration tests...'
                sh 'docker-compose up -d'
                sh 'sleep 30' // Wait for services to be ready

                echo 'Running E2E tests...'
                sh 'pip install -r tests/requirements.txt'
                sh 'E2E_BASE_URL=http://localhost:8081 pytest tests/e2e_test.py -v || true'

                echo 'Stopping services...'
                sh 'docker-compose down'
            }
        }

        stage('Tag Images') {
            when {
                branch 'main'
            }
            steps {
                echo 'Tagging Docker images...'
                script {
                    docker.image(WEBAPP_IMAGE).tag('latest')
                    docker.image(KEYCLOAK_IMAGE).tag('latest')
                    docker.image(OAUTH2_PROXY_IMAGE).tag('latest')
                }
            }
        }

        stage('Push Images') {
            when {
                branch 'main'
            }
            steps {
                echo 'Pushing Docker images to registry...'
                script {
                    docker.withRegistry("https://${DOCKER_REGISTRY_URL}", 'docker-registry') {
                        docker.image(WEBAPP_IMAGE).push()
                        docker.image(WEBAPP_IMAGE).push('latest')
                        docker.image(KEYCLOAK_IMAGE).push()
                        docker.image(KEYCLOAK_IMAGE).push('latest')
                        docker.image(OAUTH2_PROXY_IMAGE).push()
                        docker.image(OAUTH2_PROXY_IMAGE).push('latest')
                    }
                }
            }
        }

        stage('Deploy to Staging') {
            when {
                branch 'main'
            }
            steps {
                echo 'Deploying to staging environment...'
                sh """
                    helm upgrade --install ${APP_NAME}-webapp \
                        charts/webapp \
                        --namespace staging \
                        --create-namespace \
                        --set image.tag=${APP_VERSION} \
                        --wait
                """
            }
        }

        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            steps {
                input message: 'Deploy to production?', ok: 'Deploy'
                echo 'Deploying to production environment...'
                sh """
                    helm upgrade --install ${APP_NAME}-webapp \
                        charts/webapp \
                        --namespace production \
                        --create-namespace \
                        --set image.tag=${APP_VERSION} \
                        --wait
                """
            }
        }
    }

    post {
        always {
            echo 'Cleaning up...'
            sh 'docker-compose down || true'

            // Archive all security reports
            archiveArtifacts artifacts: 'security-reports/**/*', allowEmptyArchive: true

            // Clean workspace
            cleanWs()
        }

        success {
            echo 'Pipeline succeeded!'
        }

        failure {
            echo 'Pipeline failed!'
        }
    }
}
