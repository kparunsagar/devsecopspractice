pipeline {
    agent any

    tools {
        git 'git'
        maven 'maven'
        // Define the tool 'DP' for OWASP Dependency-Check here if it's installed globally
    }

    environment {
        // Define environment variables here if needed
        MAVEN_HOME = tool 'maven'   // Referencing Maven tool globally
        ARTIFACTORY_CREDENTIALS = 'artifactory-credentials'
        REPO_RELEASE = 'springReleases'
        REPO_SNAPSHOT = 'SpringSnapshot'
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
                    sh "${MAVEN_HOME}/bin/mvn -B verify"
                    // Uncomment for skipping tests during build
                    sh "${MAVEN_HOME}/bin/mvn clean deploy -Dmaven.test.skip=true"
                }
            }
        }

        //stage("OWASP Dependency Check") {
        //    steps {
        //        dependencyCheck additionalArguments: '--scan ./ --format HTML', odcInstallation: 'owasp'
        //        dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
        //    }
        //}

        stage('Test') {
            steps {
                script {
                    echo "-----------Unit test started--------------"
                    // Run unit tests with Maven
                    sh "${MAVEN_HOME}/bin/mvn test"
                    sh 'mvn surefire-report:report'
                    echo "-----------Unit test completed--------------"
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    // Ensure that 'sonarqube-server' is defined in Jenkins system configuration under SonarQube servers
                    withSonarQubeEnv('sonarqube-server') {  
                        echo "-----------SonarQube Analysis started--------------"
                        // Run SonarQube analysis using Maven command directly
                        sh "${MAVEN_HOME}/bin/mvn clean verify sonar:sonar -Dsonar.projectKey=springProject"
                        echo "-----------SonarQube Analysis completed--------------"
                    }
                }
            }
        }

        //stage('Quality Gate') {
          //  steps {
            //    timeout(time: 5, unit: 'MINUTES') {  // Timeout of 5 minutes
              //      script {
                //        def qg = waitForQualityGate()  // Wait for the quality gate result
                  //      if (qg.status != 'OK') {
                    //        error "Pipeline aborted due to quality gate failure: ${qg.status}"
                      //  }
                    //}
                //}
            //}
        //}

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
        
                        // Use the credentials for authentication
                        server.credentialsId = 'artifactory-credentials'
        
                        def buildInfo = rtMaven.run pom: '$workspace/pom.xml', goals: 'clean install'
                        rtMaven.deployer.deployArtifacts = true
                        rtMaven.deployer.deployArtifacts buildInfo
        
                        server.publishBuildInfo buildInfo
                    }
                }
            }
        }


    }
}
