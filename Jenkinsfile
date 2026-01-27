pipeline {
  agent any

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Backup Jenkins Home to S3') {
      steps {
        sh 'chmod +x scripts/backup/jenkins-backup.sh'
        sh 'scripts/backup/jenkins-backup.sh'
      }
    }
  }
}
