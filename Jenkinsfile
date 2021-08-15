def gitHash = ""
pipeline {
  agent { 
    label "worker" 
  }
  environment {
    BUILD_DOCKER_TAG = parseTagName(env.BRANCH_NAME, env.BUILD_NUMBER)
  }
  options {
    disableConcurrentBuilds()
  }
  stages {
    stage('build docker') {
      steps {
        script {
          gitHash = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
          docker.withRegistry(
            'https://843100585464.dkr.ecr.us-east-2.amazonaws.com',
            'ecr:us-east-2:AWSAccessKey') {
            def myImage = docker.build("ice-raven-springboot:${BUILD_DOCKER_TAG}")
            myImage.push(BUILD_DOCKER_TAG)
            myImage.push(gitHash)
            if(["hotfix", "main"].contains(env.BRANCH_NAME)) {
              myImage.push('latest')
            }
          }
        }
      }
    }

    stage('Quality and Security Checks') {
      parallel {
        stage('Unit testing') {
          stages {
            stage('Test and Sonarqube') {
              when {
                not {
                  branch 'hotfix'
                }
              }
              steps {
                withSonarQubeEnv("RavenLightfeather") {
                  script {
                    def buildFailed = false
                    try {
                      withDockerContainer(image: 'gradle:7.1.1-jdk11-openj9', args: "-e HOME=/tmp") {
                        sh "gradle clean test sonarqube -g gradle-user-home"
                      }
                    }
                    catch(Exception err) {
                      println(err)
                      buildFailed = true
                    }
                    finally {
                      //make the junit test results available in any case (success & failure)
                      junit 'app/build/test-results/test/*.xml'
                      publishHTML (target : [allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'app/build/reports/jacoco/test/html/',
                        reportFiles: 'index.html',
                        reportName: 'Code Coverage',
                        reportTitles: 'Code Coverage'])
                    }
                    if(buildFailed) {
                      error("Unit test failed")
                    }
                  }
                }
              }
            }
            stage("Code Quality gate") {
              when {
                not {
                  branch 'hotfix'
                }
              }
              steps {
                timeout(time: 300, unit: 'SECONDS') {
                  waitForQualityGate abortPipeline: true
                }
              }
            }

          }
        }
        stage('Vulnerability Scan') {
          stages {
            stage('Twistlock scan') {
              when {
                not {
                  branch 'hotfix'
                }
              }
              steps {
                script {
                  prismaCloudScanImage ca: '',
                    cert: '',
                    dockerAddress: 'unix:///var/run/docker.sock',
                    image: "ice-raven-springboot:${BUILD_DOCKER_TAG}",
                    key: '',
                    logLevel: 'info',
                    podmanPath: '',
                    project: '',
                    resultsFile: 'prisma-cloud-scan-results.json'
                  prismaCloudPublish resultsFilePattern: 'prisma-cloud-scan-results.json'
                }
              }
            }
          }
        }
      }
    }
    stage('Deployment') {
      stages {
        stage('Deploy to development') {
          when {
            anyOf {
              branch 'main'
              branch 'hotfix'
            }
          }
          steps {
            script {
              generateKubeConfigFile()
              modifyAppYaml(gitHash)
              sh "kubectl --insecure-skip-tls-verify=true apply -f app_ci.yaml"
              def nodePort = sh(script: 'kubectl --insecure-skip-tls-verify=true get service springboot-server -n springboot-server -o="jsonpath={.spec.ports[0].nodePort}"', returnStdout: true).trim()
              def instanceIds = sh(returnStdout: true, script: """
                aws ec2 describe-instances --region us-east-2 --filter Name=tag:Name,Values=k8s-worker-node --query Reservations[0].Instances[*].InstanceId
              """)
              // fetch state file if it exists
              dir('terraform') {
                sh """
                  aws s3 cp s3://lf-raven-tf-state/springboot-server/terraform.tfstate . || true
                  terraform init
                  terraform apply -auto-approve -var="nodeport=${nodePort}" -var='instance_ids=${instanceIds.replaceAll(~'[\n\r]', '').trim()}'
                  aws s3 cp terraform.tfstate s3://lf-raven-tf-state/springboot-server/terraform.tfstate
                """
              }
            }
          }
        }
        stage('Smoke test development') {
          when {
            anyOf { branch 'main' }
          }
          steps {
            script {
              echo "TODO: Smoke test development"
            }
          }
        }
      }
    }
  }
}

def parseTagName(branchName, buildNumber) {
  if(branchName.equalsIgnoreCase("main") || branchName.equals("")) {
    return buildNumber
  }
  def regexValidator = ~'[^a-zA-Z0-9-\\ _]'
  def parts = [branchName.replaceAll(regexValidator, '-').toLowerCase(), buildNumber]
  return parts.join('-')
}

def generateKubeConfigFile() {
  def certificateAuthorityData = sh(script: "aws ssm get-parameter --name /k8s/config/certificate-authority-data --region us-east-2 --output text --query Parameter.Value --with-decryption", returnStdout: true).trim()
  def clientCertificateData = sh(script: "aws ssm get-parameter --name /k8s/config/client-certificate-data --region us-east-2 --output text --query Parameter.Value --with-decryption", returnStdout: true).trim()
  def clientKeyData = sh(script: "aws ssm get-parameter --name /k8s/config/client-key-data --region us-east-2 --output text --query Parameter.Value --with-decryption", returnStdout: true).trim()
  writeFile(text: getKubeConfigString(certificateAuthorityData, clientCertificateData, clientKeyData), file: '/var/lib/jenkins/.kube/config')
}

def getKubeConfigString(certificateAuthorityData, clientCertificateData, clientKeyData) {
  return """apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${certificateAuthorityData}
    server: https://18.217.127.210:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: kubernetes-admin
  name: kubernetes-admin@kubernetes
current-context: kubernetes-admin@kubernetes
kind: Config
preferences: {}
users:
- name: kubernetes-admin
  user:
    client-certificate-data: ${clientCertificateData}
    client-key-data: ${clientKeyData}
"""
}

def modifyAppYaml(hash) {
  def appYaml = readFile(file: "app.yaml")
  if(!hash.equals("")) {
    def repo = "843100585464.dkr.ecr.us-east-2.amazonaws.com/ice-raven-springboot"
    appYaml = appYaml.replace("${repo}:latest", "${repo}:${hash}")
  }
  writeFile(text: appYaml, file: "app_ci.yaml")
}