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

myFileDirectory = prod-us1
myFileName = "values.yaml"
myFile = new File(myFileDirectory + myFileName)

lastLine = myFile.readLines().get(myFile.readLines().size().toInteger() - 1)
if (lastLine ==~ /.Fatal Error.*/ ){
    println "Fatal error found"
    System.exit(1)
} else{
   println "nothing to see here"
}


// checkout Config repo
stage('Checkout SCM Deploy Config repo') {
  checkout scm
  sh "ls"
  echo "${params.DEPLOY_TAG}"  // parameters from upstream job
  echo "${params.BRANCHNAME}"  // parameters from upstream job

}

// checkout App repo
stage('Checkout SCM App repo') {
  checkout([$class: 'GitSCM',
  branches: [[name: '**']],
  doGenerateSubmoduleConfigurations: false,
  extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'AppDir']],
  submoduleCfg: [],
  userRemoteConfigs: [[credentialsId: 'github_key', url: 'https://github.com/IgorSochyvets/fizz-buzz.git']]])
  sh 'ls -l AppDir/.git/logs/refs/remotes/origin'
}

//
// *** Deploy PROD/DEV/QA  release
//

// deploy PROD
stage('Deploy PROD release') {
  if ( isChangeSet()  ) {
    tagDockerImage = "${sh(script:'cat production-release.txt',returnStdout: true)}"
    echo "Production release controlled by a change to production-release.txt file in application repository root,"
    echo "containing a git tag that should be released to production environment"
    tagDockerImage = "${sh(script:'cat production-release.txt',returnStdout: true)}"
    deployHelm("javawebapp-prod2","prod",tagDockerImage)
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

def isChangeSet() {
/* new version - need testing
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
                     if (file.path.equals("production-release.txt")) {
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
