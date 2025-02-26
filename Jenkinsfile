pipeline {
    agent any

    tools {
        git 'git'
        maven 'maven'
    }

    environment {
        MAVEN_HOME = tool 'maven'
        ARTIFACTORY_CREDENTIALS = 'artifactory-credentials'
        REPO_RELEASE = 'springReleases'
        REPO_SNAPSHOT = 'SpringSnapshot'
        DOCKERHUB_CREDENTIALS = credentials('docker')
    }

    stages {
        stage('Source') {
            steps {
                git url: 'https://github.com/kparunsagar/devsecopspractice.git', branch: 'main'
            }
        }

        stage('Build') {
            steps {
                script {
                    echo "-----------Build started--------------"
                    sh "${MAVEN_HOME}/bin/mvn clean verify"  // Do NOT skip tests
                    sh "${MAVEN_HOME}/bin/mvn clean deploy"  // No test skipping!
                }
            }
        }

        stage("OWASP Dependency Check") {
            steps {
                withEnv(["_JAVA_OPTIONS=-Xmx4G"]) { 
                    dependencyCheck additionalArguments: '--scan ./target --format HTML --enableExperimental --noupdate', 
                                    odcInstallation: 'owasp'
                }
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }

        stage('JUnit Test Results') {
            steps{ 
                catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                junit '**/target/surefire-reports/*.xml'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    withSonarQubeEnv('sonarqube-server') {  
                        echo "-----------SonarQube Analysis started--------------"
                        sh "${MAVEN_HOME}/bin/mvn sonar:sonar -Dsonar.projectKey=springProject"
                        echo "-----------SonarQube Analysis completed--------------"
                    }
                }
            }
        }

        stage('RunSCAAnalysisUsingSnyk') {
            steps {
                withCredentials([string(credentialsId: 'SNYK_TOKEN', variable: 'SNYK_TOKEN')]) {
                    withEnv(["_JAVA_OPTIONS=-Xmx4G"]) {
                        sh "${MAVEN_HOME}/bin/mvn snyk:test -fn"
                    }
                }
            }
        }

        stage('Packaging') {
            steps {
                step([$class: 'ArtifactArchiver', artifacts: '**/target/*.jar', fingerprint: true])
            }
        }

        stage("Artifactory Publish") {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'artifactory-credentials', 
                                                     usernameVariable: 'ARTIFACTORY_USERNAME', 
                                                     passwordVariable: 'ARTIFACTORY_PASSWORD')]) {
                        def server = Artifactory.server 'Artifactory'
                        def rtMaven = Artifactory.newMavenBuild()
                        rtMaven.deployer server: server, releaseRepo: 'springReleases', snapshotRepo: 'SpringSnapshot'
                        rtMaven.tool = 'maven'
        
                        server.credentialsId = 'artifactory-credentials'
        
                        def buildInfo = rtMaven.run pom: '$workspace/pom.xml', goals: 'clean install'
                        rtMaven.deployer.deployArtifacts = true
                        rtMaven.deployer.deployArtifacts buildInfo
        
                        server.publishBuildInfo buildInfo
                    }
                }
            }
        }
        stage("Build docker image"){
          steps {
            sh 'cp target/*.jar .'
            sh 'docker build -t kparun/devsecopspractice:$BUILD_NUMBER .'
          }
        }
        stage("Login to docker hub") {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker', 
                                                  usernameVariable: 'DOCKER_USER', 
                                                  passwordVariable: 'DOCKER_PASS')]) {
                    sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
                }
            }
        }
        stage("Docker push"){
          steps {
            sh 'docker push kparun/devsecopspractice:$BUILD_NUMBER'
          }
        }
    }
}
