pipeline {
  agent any

  environment {
    DOCKERHUB_REPO = "antoshreya/healthcare"
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Build Backend Image') {
      steps {
        dir('backend') {
          sh "docker build -t ${DOCKERHUB_REPO}-backend:${env.BUILD_NUMBER} ."
        }
      }
    }

    stage('Build Frontend Image') {
      steps {
        dir('frontend') {
          sh "docker build -t ${DOCKERHUB_REPO}-frontend:${env.BUILD_NUMBER} ."
        }
      }
    }

    stage('Push Images') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
          sh "echo $DH_PASS | docker login -u $DH_USER --password-stdin"
          sh "docker push ${DOCKERHUB_REPO}-backend:${env.BUILD_NUMBER}"
          sh "docker push ${DOCKERHUB_REPO}-frontend:${env.BUILD_NUMBER}"
        }
      }
    }

    stage('Run Containers (smoke)') {
      steps {
        sh "docker rm -f healthcare-backend || true"
        sh "docker rm -f healthcare-frontend || true"
        sh "docker run -d --name healthcare-backend -p 3000:3000 ${DOCKERHUB_REPO}-backend:${env.BUILD_NUMBER}"
        sh "docker run -d --name healthcare-frontend -p 8080:80 ${DOCKERHUB_REPO}-frontend:${env.BUILD_NUMBER}"
      }
    }
  }

  post {
    success { echo "Build Succeeded" }
    failure { echo "Build Failed" }
  }
}

