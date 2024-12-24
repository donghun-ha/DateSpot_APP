pipeline {
    agent any

    environment {
        DOCKER_IMAGE_TAG = "datespot-${BUILD_NUMBER}"  // 고유한 Docker 이미지 태그
        ECR_REPO = "240317130487.dkr.ecr.ap-northeast-2.amazonaws.com/datespot"
        AWS_REGION = "ap-northeast-2"
    }

    stages {
        stage("Init") {
            steps {
                script {
                    gv = load "script.groovy"
                }
            }
        }
        stage("Checkout") {
            steps {
                checkout scm
            }
        }
        stage('Build Docker Image') {
            steps {
                sh '''
                    echo "Building Docker Image with tag: ${DOCKER_IMAGE_TAG}"
                    docker build -t ${ECR_REPO}:${DOCKER_IMAGE_TAG} -f Dockerfile .
                    echo "Tagging image as latest"
                    docker tag ${ECR_REPO}:${DOCKER_IMAGE_TAG} ${ECR_REPO}:latest
                '''
            }
        }
        stage('Push Docker Image to ECR Repo') {
            steps {
                withAWS(credentials: 'datespotecr', region: "${AWS_REGION}") {
                    sh '''
                        # ECR 로그인
                        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin "${ECR_REPO}"
                        
                        # 고유한 태그로 이미지 푸시
                        echo "Pushing Docker Image with tag: ${DOCKER_IMAGE_TAG}"
                        docker push "${ECR_REPO}:${DOCKER_IMAGE_TAG}"
                        
                        # 'latest' 태그로 이미지 푸시
                        echo "Pushing Docker Image with tag: latest"
                        docker push "${ECR_REPO}:latest"
                    '''
                }
            }
        }
        stage("Test") {
            when {
                expression {
                    params.executeTests
                }
            }
            steps {
                script {
                    gv.testApp()
                }
            }
        }
        stage("Deploy") {
            steps {
                sh '''
                    echo "Deploying Docker Image with tag: ${DOCKER_IMAGE_TAG}"
                    DOCKER_IMAGE_TAG=${DOCKER_IMAGE_TAG} docker-compose up -d
                '''
            }
        }
    }
}
