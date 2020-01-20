#!/usr/bin/env groovy

import org.jenkinsci.plugins.pipeline.modeldefinition.Utils

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
stage('Checkout1') {
  checkout scm
  sh "ls -la"
  echo "${params.deployTag}"  // parameters from upstream job - short commit

}

//
// *** Deploy PROD /  parallel
//

running_set = [
    "prod-us1": {
      stage('DeployProdUs1') {
        if ( isChangeSet("prod-us1/javawebapp.yaml")  ) {
          def values = readYaml(file: 'prod-us1/javawebapp.yaml')
          checkoutAppRepo("${values.image.tag}")
          deploy("javawebapp-prod-us1","prod-us1","prod-us1/javawebapp.yaml","${values.image.tag}")
        }
        else Utils.markStageSkippedForConditional('DeployProdUs1')
      }
    },
    "prod-us2": {
      stage('DeployProdUs2') {
        if ( isChangeSet("prod-us2/javawebapp.yaml")  ) {
          def values = readYaml(file: 'prod-us2/javawebapp.yaml')
          checkoutAppRepo("${values.image.tag}")
          deploy("javawebapp-prod-us2","prod-us2","prod-us2/javawebapp.yaml","${values.image.tag}")
        }
        else Utils.markStageSkippedForConditional('DeployProdUs2')
      }
    },
    "prod-eu1": {
      stage('DeployProdEu1') {
        if ( isChangeSet("prod-eu1/javawebapp.yaml")  ) {
          def values = readYaml(file: 'prod-eu1/javawebapp.yaml')
          checkoutAppRepo("${values.image.tag}")
          deploy("javawebapp-prod-eu1","prod-eu1","prod-eu1/javawebapp.yaml","${values.image.tag}")
        }
        else Utils.markStageSkippedForConditional('DeployProdEu1')
      }
    },
    "prod-ap1": {
      stage('DeployProdAp1') {
        if ( isChangeSet("prod-ap1/javawebapp.yaml")  ) {
          def values = readYaml(file: 'prod-ap1/javawebapp.yaml')
          checkoutAppRepo("${values.image.tag}")
          deploy("javawebapp-prod-ap1","prod-ap1","prod-ap1/javawebapp.yaml","${values.image.tag}")
        }
        else Utils.markStageSkippedForConditional('DeployProdAp1')
      }
    }
]
// next Stage starts Deploy Prod in parallel
stage('DeployProd') {
  parallel(running_set)
}


//deploy DEV
stage('DeployDev') {
  if ( isMaster() ) {
    checkoutAppRepo("${params.deployTag}")
    deploy("javawebapp-dev2","dev","dev/javawebapp.yaml","${params.deployTag}")
  }
  else Utils.markStageSkippedForConditional('DeployDev')
}

// deploy QA
stage('DeployQa') {
  if ( isBuildingTag() ) {
    checkoutAppRepo("${params.deployTag}")
    deploy("javawebapp-qa2","qa","qa/javawebapp.yaml","${params.deployTag}")
  }
  else Utils.markStageSkippedForConditional('DeployQa')
}

    } // node
  } //podTemplate

def isMaster() {    // is it DEV release ?
  return ( (!isBuildingTag()) && (params.deployTag != 'Null') )
}

def isBuildingTag() {
  return ( params.deployTag ==~ /^\d+\.\d+\.\d+$/ ) // // QA release has tag as paramete
}


//=====================================================
def isChangeSet(file_path) {

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
//=====================================================

//
// deployment function for PROD releases
// name - app's name; ns - namespace; filePath - path to values.yaml, refName - name of dir where App Repo is stored;

def deploy(name, ns, filePath, refName) {
 container('helm') {
    withKubeConfig([credentialsId: 'kubeconfig']) {
    sh """
        echo appVersion: \"$refName\" >> '$refName/javawebapp-chart/Chart.yaml'
        helm upgrade --install $name --debug '$refName/javawebapp-chart' \
        --force \
        --wait \
        --namespace $ns \
        --values $filePath \
        --set image.tag=$refName
        helm ls
    """
    }
}
}

// checkout App repo to commit function
def checkoutAppRepo(commitId) {
  checkout([$class: 'GitSCM',
  branches: [[name: "${commitId}"]],
  extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: "${commitId}"]],
  userRemoteConfigs: [[credentialsId: 'github_key', url: 'https://github.com/IgorSochyvets/fizz-buzz.git']]])
  sh 'ls -la'
}
