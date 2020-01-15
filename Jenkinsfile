#!/usr/bin/env groovy

import org.jenkinsci.plugins.pipeline.modeldefinition.Utils

env.DOCKERHUB_IMAGE = 'fizz-buzz'
env.DOCKERHUB_USER = 'kongurua'

properties([
  parameters([
    string(name: 'deployTag', defaultValue: 'Null', description: 'Short commit ID or Tag from upstream job', )
   ])
])

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
  containers:
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
stage('CheckoutScmDeployConfigRepo') {
  checkout scm
  sh "ls -la"
  echo "${params.deployTag}"  // parameters from upstream job - short commit
  echo "${params.BRANCHNAME}"  // parameters from upstream job
}

//
// *** Deploy PROD/DEV/QA  release
//

// deploy PROD
stage('DeployProdUs1') {
  if ( isChangeSet("prod-us1/javawebapp.yaml")  ) {
    def values = readYaml(file: 'prod-us1/javawebapp.yaml')
    println "tag for prod-us1: ${values.image.tag}"
    checkoutAppRepo("${values.image.tag}")    //for checkout to separate Folder, if it will be needed in future (deploy several PRODS simultaneously)
    deployProd("javawebapp-prod-us1","prod-us1","prod-us1/javawebapp.yaml","${values.image.tag}")
  }
  else Utils.markStageSkippedForConditional('DeployProdUs1')
}
stage('DeployProdUs2') {
  if ( isChangeSet("prod-us2/javawebapp.yaml")  ) {
    def values = readYaml(file: 'prod-us2/javawebapp.yaml')
    println "tag for prod-us2: ${values.image.tag}"
    checkoutAppRepo("${values.image.tag}")
    deployProd("javawebapp-prod-us2","prod-us2","prod-us2/javawebapp.yaml","${values.image.tag}")
  }
  else Utils.markStageSkippedForConditional('DeployProdUs2')
}
stage('DeployProdEu1') {
  if ( isChangeSet("prod-eu1/javawebapp.yaml")  ) {
    def values = readYaml(file: 'prod-eu1/javawebapp.yaml')
    println "tag for prod-eu1: ${values.image.tag}"
    checkoutAppRepo("${values.image.tag}")
    deployProd("javawebapp-prod-eu1","prod-eu1","prod-eu1/javawebapp.yaml","${values.image.tag}")
  }
  else Utils.markStageSkippedForConditional('DeployProdEu1')
}
stage('DeployProdAp1') {
  if ( isChangeSet("prod-ap1/javawebapp.yaml")  ) {
    def values = readYaml(file: 'prod-ap1/javawebapp.yaml')
    println "tag for prod-ap1: ${values.image.tag}"
    checkoutAppRepo("${values.image.tag}")
    deployProd("javawebapp-prod-ap1","prod-ap1","prod-ap1/javawebapp.yaml","${values.image.tag}")
  }
  else Utils.markStageSkippedForConditional('DeployProdAp1')
}
//deploy DEV
stage('DeployDev') {
  if ( isMaster() ) {
    checkoutAppRepo("${params.deployTag}")
    deployProd("javawebapp-dev2","dev","dev/javawebapp.yaml","${params.deployTag}")
  }
  else Utils.markStageSkippedForConditional('DeployDev')
}
/*
stage('DeployDev') {
  if ( isMaster() ) {
    checkoutAppRepo("${params.deployTag}")
    deployDEVQA("javawebapp-dev2","dev","${params.deployTag}")
  }
  else Utils.markStageSkippedForConditional('DeployDev')
}
*/
// deploy QA
stage('DeployQa') {
  if ( isBuildingTag() ) {
    checkoutAppRepo("${params.BRANCHNAME}")
    deployDEVQA("javawebapp-qa2","qa","${params.BRANCHNAME}")
  }
  else Utils.markStageSkippedForConditional('DeployQa')
}


    } // node
  } //podTemplate

def isMaster() {
  return ( params.BRANCHNAME == "master" )
}

def isBuildingTag() {
  return ( params.BRANCHNAME ==~ /^\d+.\d+.\d+$/ )
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
// name - app's name; ns - namespace; file_path - path to values.yaml, dir_name - name of dir where App Repo is stored;
  def deployProd(name, ns, file_path, dir_name) {
     container('helm') {
        withKubeConfig([credentialsId: 'kubeconfig']) {
        sh """
            helm upgrade --install $name --debug $dir_name/javawebapp-chart \
            --force \
            --wait \
            --namespace $ns \
            --values $file_path
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
          helm upgrade --install $name --debug '${tag}/javawebapp-chart' \
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
def checkoutAppRepo(commitId) {
  checkout([$class: 'GitSCM',
  branches: [[name: "${commitId}"]],
  doGenerateSubmoduleConfigurations: false,
  extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: "${commitId}"]],
  submoduleCfg: [],
  userRemoteConfigs: [[credentialsId: 'github_key', url: 'https://github.com/IgorSochyvets/fizz-buzz.git']]])
  sh 'ls -la'
}
