#!/usr/bin/env groovy

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
  def values = readYaml(file: 'prod-us1/values.yaml')
  println "tag from yaml: ${values.image.tag}"
}

// checkout App repo
stage('Checkout SCM App repo') {
  checkout([$class: 'GitSCM',
  branches: [[name: '**']],
  doGenerateSubmoduleConfigurations: false,
  extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'AppDir']],
  submoduleCfg: [],
  userRemoteConfigs: [[credentialsId: 'github_key', url: 'https://github.com/IgorSochyvets/fizz-buzz.git']]])
  sh 'ls -la AppDir/'
}

//
// *** Deploy PROD/DEV/QA  release
//

// deploy PROD
stage('Deploy prod-us1 release') {
  if ( isChangeSet("prod-us1/values.yaml")  ) {
    def values1 = readYaml(file: 'prod-us1/values.yaml')
    println "tag for prod-us1: ${values1.image.tag}"
//    tagDockerImage = "${values1.image.tag}"
    deployHelm("javawebapp-prod-us1","prod-us1","${values1.image.tag}")
  }
}
stage('Deploy prod-us2 release') {
  if ( isChangeSet("prod-us2/values.yaml")  ) {
    def values1 = readYaml(file: 'prod-us2/values.yaml')
    println "tag from yaml: ${values1.image.tag}"
    tagDockerImage = "${values1.image.tag}"
    deployHelm("javawebapp-prod-us2","prod-us2",tagDockerImage)
  }
}
stage('Deploy prod-eu1 release') {
  if ( isChangeSet("prod-eu1/values.yaml")  ) {
    def values1 = readYaml(file: 'prod-us1/values.yaml')
    println "tag from yaml: ${values1.image.tag}"
    tagDockerImage = "${values1.image.tag}"
    deployHelm("javawebapp-prod-us1","prod-us1",tagDockerImage)
  }
}
stage('Deploy prod-ap1 release') {
  if ( isChangeSet("prod-ap1/values.yaml")  ) {
    def values1 = readYaml(file: 'prod-us1/values.yaml')
    println "tag from yaml: ${values1.image.tag}"
    tagDockerImage = "${values1.image.tag}"
    deployHelm("javawebapp-prod-us1","prod-us1",tagDockerImage)
  }
}
//deploy DEV
stage('Deploy DEV release') {
  if ( isMaster() ) {
    tagDockerImage = params.DEPLOY_TAG
    echo "Every commit to master branch is a dev release"
    echo "Deploy Dev release after commit to master"
    deployHelm("javawebapp-dev2","dev",tagDockerImage)
  }
}
// deploy QA
stage('Deploy QA release') {
  if ( isBuildingTag() ) {
    tagDockerImage = params.BRANCHNAME
    echo "Every commit to master branch is a dev release"
    echo "Deploy Dev release after commit to master"
    deployHelm("javawebapp-qa2","qa",tagDockerImage)
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

def isChangeSet(file_to_check) {
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
                     if (file.path.equals(file_to_check)) {
                         return true
                     }
                 }
              }
      }
}

//
// Deployment function
// name = javawebapp
// ns = dev/qa/prod
// tag = image's tag
  def deployHelm(name, ns, tag) {
     container('helm') {
        withKubeConfig([credentialsId: 'kubeconfig']) {
        sh """
            echo "Deployments is starting..."
            helm upgrade --install $name --debug AppDir/javawebapp-chart \
            --force \
            --wait \
            --namespace $ns \
            --values prod-us1/values.yaml --reuse-values
            helm ls
        """
        }
    }
  }

  // helm upgrade --install javawebapp-prod2 --debug javawebapp-chart --force --wait --namespace prod  --values ./file1.yaml --reuse-values
