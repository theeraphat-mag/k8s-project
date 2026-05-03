pipeline {
    agent any

    environment {
        DOCKERHUB_USER = 'thamonwanfirst'
        // ชื่อ Credential ID ที่คุณต้องไปตั้งค่าใน Jenkins
        DOCKER_CREDENTIALS_ID = 'docker-hub-credentials' 
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build & Push Backend') {
            steps {
                script {
                    dir('backend') {
                        def backendImage = docker.build("${DOCKERHUB_USER}/monkeypop-backend:${env.BUILD_NUMBER}")
                        docker.withRegistry('', DOCKER_CREDENTIALS_ID) {
                            backendImage.push()
                            backendImage.push('latest')
                        }
                    }
                }
            }
        }

        stage('Build & Push Frontend') {
            steps {
                script {
                    dir('frontend') {
                        def frontendImage = docker.build("${DOCKERHUB_USER}/monkeypop-frontend:${env.BUILD_NUMBER}")
                        docker.withRegistry('', DOCKER_CREDENTIALS_ID) {
                            frontendImage.push()
                            frontendImage.push('latest')
                        }
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                // ขั้นตอนนี้ต้องมีการติดตั้ง kubectl และตั้งค่า kubeconfig ในเครื่อง Jenkins
                sh "kubectl apply -f k8s/redis.yaml"
                sh "kubectl apply -f k8s/backend.yaml"
                sh "kubectl apply -f k8s/frontend.yaml"
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
