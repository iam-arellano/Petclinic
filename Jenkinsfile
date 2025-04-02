pipeline {
    agent any
    
    environment {
        SCANNER_HOME= tool 'sonar-scanner'                      
        
        /// THIS IS FOR DOCKER CRED TO PUSH 
        APP_NAME = "nodejs-app"      
        RELEASE = "1.0.0"
        DOCKER_USER = "raemondarellano"
        DOCKER_PASS = 'jenkins-docker-credentials'              
        IMAGE_NAME = "${DOCKER_USER}" + "/" + "${APP_NAME}"  
        IMAGE_TAG = "${RELEASE}-${BUILD_NUMBER}"
        JENKINS_API_TOKEN = credentials("JENKINS_API_TOKEN")
        SONAR_TOKEN = credentials("sonarqube_access")               // credential access for sonarqube
        
    }

    stages {
        stage("Cleanup Workspace") {
            steps {
                cleanWs()
            }
        }
        
        stage("Checkout from SCM"){
            steps {
                git branch: 'master', credentialsId: 'github', url: 'https://github.com/iam-arellano/node-js-app.git'
                    echo 'Git Checkout Completed'
            }
        }
        
          stage("Install Dependencies"){
            steps {
              sh 'npm init -y'
              sh 'npm install express mongoose cors -y'
                echo 'Git Checkout Completed'
            }
        }
        
          stage("SonarQube Analysis") {
            steps {
                script {
                    withSonarQubeEnv('sonarqube_server') {  // Make sure you've configured SonarQube server in Jenkins under Manage Jenkins > Configure System > SonarQube Servers
                        sh """
                            ${SCANNER_HOME}/bin/sonar-scanner \
                            -Dsonar.projectKey=${APP_NAME} \
                            -Dsonar.projectName=${APP_NAME} \
                            -Dsonar.projectVersion=${RELEASE}-${BUILD_NUMBER} \
                            -Dsonar.sources=. \
                            -Dsonar.login=${SONAR_TOKEN} \
                        """
                    }
                }
            }
        }
        
        stage ('DEV Approve') {                 //aproval before proceed
             steps {
                echo "Taking approval from DEV Manager for QA Deployment"
                timeout(time: 7, unit: 'DAYS') {
                input message: 'Do you want to deploy?', submitter: 'admin'
              }
            }
        }    
        
        stage("Build & Push Docker Image") {
            steps {
                script {
                    docker.withRegistry('',DOCKER_PASS) {
                        docker_image = docker.build "${IMAGE_NAME}"
                    }

                    docker.withRegistry('',DOCKER_PASS) {
                        docker_image.push("${IMAGE_TAG}")
                        docker_image.push('latest')
                    }
                }
            }
       }
       
       //  to scan docker image 
        stage("Trivy Scan") {
           steps {
               script {
	            sh ('docker run -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image raemondarellano/nodejs-app:latest --no-progress --scanners vuln  --exit-code 0 --severity HIGH,CRITICAL --format table')
               }
           }
       }
       
        stage ('Cleanup Artifacts') {
           steps {
               script {
                    sh "docker rmi ${IMAGE_NAME}:${IMAGE_TAG}"
                    sh "docker rmi ${IMAGE_NAME}:latest"
               }
            }
        }
        
        
              // Update Deployment yaml
        stage("Update the Deployment Tags") {
            steps {
                sh """
                   cd k8s_yaml                                     
                   cat nodejs-deployment.yaml
                   sed -i 's/${APP_NAME}.*/${APP_NAME}:${IMAGE_TAG}/g' nodejs-deployment.yaml
                   cat nodejs-deployment.yaml
                """
                 }
             }
        
             // Push deployment to Git
        stage("Push the changed deployment file to Git") {
            steps {
                sh """
                   git config --global user.name "raemond.arellano01@gmail.com"
                   git config --global user.email "raemond.arellano01@gmail.com"
                   git add k8s_yaml/nodejs-deployment.yaml
                   git commit -m "Updated Deployment Manifest"
                """
                withCredentials([gitUsernamePassword(credentialsId: 'github_token', gitToolName: 'Default')]) {
                  sh "git push https://github.com/iam-arellano/node-js-app.git  master"
                }
            }
        }
        

    }
}
