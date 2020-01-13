#!/usr/bin/env groovy

env.DOCKERHUB_IMAGE = 'fizz-buzz'
env.DOCKERHUB_USER = 'kongurua'

def label = "jenkins-agent"

podTemplate(label: label, yaml: """
apiVersion: v1
kind: Pod
metadata:
  name: jenkins-slave
  namespace: jenkins
  labels:
    component: ci
    jenkins: jenkins-agent
spec:
  # Use service account that can deploy to all namespaces
  serviceAccountName: jenkins
  volumes:
  - name: dind-storage
    emptyDir: {}
  containers:
  - name: git
    image: alpine/git
    command:
    - cat
    tty: true
  - name: maven
    image: maven:latest
    command:
    - cat
    tty: true
  - name: kubectl
    image: lachlanevenson/k8s-kubectl:v1.8.8
    command:
    - cat
    tty: true
  - name: docker
    image: docker:19-git
    command:
    - cat
    tty: true
    env:
    - name: DOCKER_HOST
      value: tcp://docker-dind:2375
    volumeMounts:
      - name: dind-storage
        mountPath: /var/lib/docker
  - name: helm
    image: lachlanevenson/k8s-helm:v2.16.1
    command:
    - cat
    tty: true
"""
  ){

node(label) {

def tagDockerImage



// checkout Config repo
stage('Checkout SCM Deploy Config repo') {
  checkout scm
  sh "ls"
  echo "${params.DEPLOY_TAG}"  // parameters from upstream job
  echo "${params.BRANCHNAME}"  // parameters from upstream job
}

// checkout App repo
stage('Checkout SCM App repo') {

  checkoutAppRepo ("8f5d6c5")

//  checkout([$class: 'GitSCM',
//  branches: [[name: '**']],
//  doGenerateSubmoduleConfigurations: false,
//  extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'AppDir']],
//  submoduleCfg: [],
//  userRemoteConfigs: [[credentialsId: 'github_key', url: 'https://github.com/IgorSochyvets/fizz-buzz.git']]])
//  sh 'ls -la AppDir/'
}

//
// *** Deploy PROD/DEV/QA  release
//

// deploy PROD
stage('Deploy prod-us1 release') {
  if ( isChangeSet("prod-us1/values.yaml")  ) {
    def values1 = readYaml(file: 'prod-us1/values.yaml')
    println "tag for prod-us1: ${values1.image.tag}"
    deployProd("javawebapp-prod-us1","prod-us1","prod-us1/values.yaml")
  }
}
stage('Deploy prod-us2 release') {
  if ( isChangeSet("prod-us2/values.yaml")  ) {
    def values2 = readYaml(file: 'prod-us2/values.yaml')
    println "tag for prod-us2: ${values2.image.tag}"
    deployProd("javawebapp-prod-us2","prod-us2","prod-us2/values.yaml")
  }
}
stage('Deploy prod-eu1 release') {
  if ( isChangeSet("prod-eu1/values.yaml")  ) {
    def values1 = readYaml(file: 'prod-eu1/values.yaml')
    println "tag for prod-eu1: ${values1.image.tag}"
    deployProd("javawebapp-prod-eu1","prod-eu1","prod-eu1/values.yaml")
  }
}
stage('Deploy prod-ap1 release') {
  if ( isChangeSet("prod-ap1/values.yaml")  ) {
    def values1 = readYaml(file: 'prod-ap1/values.yaml')
    println "tag for prod-ap1: ${values1.image.tag}"
    deployProd("javawebapp-prod-ap1","prod-ap1","prod-ap1/values.yaml")
  }
}
//deploy DEV
stage('Deploy DEV release') {
  if ( isMaster() ) {
    tagDockerImage = params.DEPLOY_TAG
    echo "Every commit to master branch is a dev release"
    echo "Deploy Dev release after commit to master"
    deployDEVQA("javawebapp-dev2","dev",tagDockerImage)
  }
}
// deploy QA
stage('Deploy QA release') {
  if ( isBuildingTag() ) {
    tagDockerImage = params.BRANCHNAME
    echo "Every commit to master branch is a dev release"
    echo "Deploy Dev release after commit to master"
    deployDEVQA("javawebapp-qa2","qa",tagDockerImage)
  }
}


    } // node
  } //podTemplate

def isMaster() {
  return ( params.BRANCHNAME == "master" )
}

def isBuildingTag() {
  return ( params.BRANCHNAME ==~ /^\d.\d.\d$/ )
}

def isChangeSet(file_path) {
/* new version - need to test
    currentBuild.changeSets.any { changeSet ->
          changeSet.items.any { entry ->
            entry.affectedFiles.any { file ->
              if (file.path.equals("production-release.txt")) {
                return true
              }
            }
          }
        }
*/
// old version
      def changeLogSets = currentBuild.changeSets
             for (int i = 0; i < changeLogSets.size(); i++) {
             def entries = changeLogSets[i].items
             for (int j = 0; j < entries.length; j++) {
                 def files = new ArrayList(entries[j].affectedFiles)
                 for (int k = 0; k < files.size(); k++) {
                     def file = files[k]
                     if (file.path.equals(file_path)) {
                         return true
                     }
                 }
              }
      }
}

//
// deployment function for PROD releases
  def deployProd(name, ns, file_path) {
     container('helm') {
        withKubeConfig([credentialsId: 'kubeconfig']) {
        sh """
            echo "Deployments is starting..."
            helm upgrade --install $name --debug AppDir/javawebapp-chart \
            --force \
            --wait \
            --namespace $ns \
            --values $file_path --reuse-values
            helm ls
        """
        }
    }
  }


// deployment function for DEV qa QA releases
  def deployDEVQA(name, ns, tag) {
   container('helm') {
      withKubeConfig([credentialsId: 'kubeconfig']) {
      sh """
          echo "Deployments is starting..."
          helm upgrade --install $name --debug AppDir/javawebapp-chart \
          --force \
          --wait \
          --namespace $ns \
          --set image.repository=$DOCKERHUB_USER/$DOCKERHUB_IMAGE \
          --set-string ingress.hosts[0].host=${name}.ddns.net \
          --set-string ingress.tls[0].hosts[0]=${name}.ddns.net \
          --set-string ingress.tls[0].secretName=acme-${name}-tls \
          --set image.tag=$tag
          helm ls
      """
      }
  }
}


// checkout App repo to commit function
def checkoutAppRepo (commitId) {
  checkout([$class: 'GitSCM',
  branches: [[name: '$commitId']],
  doGenerateSubmoduleConfigurations: false,
  extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: '$commitId']],
  submoduleCfg: [],
  userRemoteConfigs: [[credentialsId: 'github_key', url: 'https://github.com/IgorSochyvets/fizz-buzz.git']]])
  sh 'ls -la $commitId'
}
