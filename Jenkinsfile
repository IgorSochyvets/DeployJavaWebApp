#!/usr/bin/env groovy

import org.jenkinsci.plugins.pipeline.modeldefinition.Utils

properties([
  parameters([
    string(name: 'deployTag', defaultValue: 'Null', description: 'Short commit ID or Tag from upstream job', )
   ])
])

def label = "jenkins-agent2"

podTemplate(label: label, yaml: """
apiVersion: v1
kind: Pod
metadata:
  name: jenkins-slave
  namespace: jenkins
  labels:
    component: ci
    jenkins: jenkins-agent2
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
  )

{ //pod template
node(label) {

def tagDockerImage

// checkout Config repo
stage('Checkout1') {
  checkout scm
  sh "ls -la"
  echo "${params.deployTag}"  // parameters from upstream job - short commit
  buildDeployMap()

}

/*
//
// *** Deploy PROD
//
      stage('DeployProdUs1') {
        if ( isChangeSet("prod-us1/javawebapp-prod-us1.yaml")  ) {
          def values = readYaml(file: 'prod-us1/javawebapp-prod-us1.yaml')
          checkoutAppRepo("${values.image.tag}")
          deploy("javawebapp-prod-us1","prod-us1","prod-us1/javawebapp-prod-us1.yaml","${values.image.tag}")
        }
        else Utils.markStageSkippedForConditional('DeployProdUs1')
      }

      stage('DeployProdUs2') {
        if ( isChangeSet("prod-us2/javawebapp-prod-us2.yaml")  ) {
          def values = readYaml(file: 'prod-us2/javawebapp-prod-us2.yaml')
          checkoutAppRepo("${values.image.tag}")
          deploy("javawebapp-prod-us2","prod-us2","prod-us2/javawebapp-prod-us2.yaml","${values.image.tag}")
        }
        else Utils.markStageSkippedForConditional('DeployProdUs2')
      }

      stage('DeployProdEu1') {
        if ( isChangeSet("prod-eu1/javawebapp-prod-eu1.yaml")  ) {
          def values = readYaml(file: 'prod-eu1/javawebapp-prod-eu1.yaml')
          checkoutAppRepo("${values.image.tag}")
          deploy("javawebapp-prod-eu1","prod-eu1","prod-eu1/javawebapp-prod-eu1.yaml","${values.image.tag}")
        }
        else Utils.markStageSkippedForConditional('DeployProdEu1')
      }

      stage('DeployProdAp1') {
        if ( isChangeSet("prod-ap1/javawebapp-prod-ap1.yaml")  ) {
          def values = readYaml(file: 'prod-ap1/javawebapp-prod-ap1.yaml')
          checkoutAppRepo("${values.image.tag}")
          deploy("javawebapp-prod-ap1","prod-ap1","prod-ap1/javawebapp-prod-ap1.yaml","${values.image.tag}")
        }
        else Utils.markStageSkippedForConditional('DeployProdAp1')
      }
*/

// Parallel - working code with issue (simulmaneuos checkout and creating same directory)
/*
running_set = [
    "prod-us1": {
      stage('DeployProdUs1') {
        if ( isChangeSet("prod-us1/javawebapp-prod-us1.yaml")  ) {
          def values = readYaml(file: 'prod-us1/javawebapp-prod-us1.yaml')
          checkoutAppRepo("${values.image.tag}")
          deploy("javawebapp-prod-us1","prod-us1","prod-us1/javawebapp-prod-us1.yaml","${values.image.tag}")
        }
        else Utils.markStageSkippedForConditional('DeployProdUs1')
      }
    },
    "prod-us2": {
      stage('DeployProdUs2') {
        if ( isChangeSet("prod-us2/javawebapp-prod-us2.yaml")  ) {
          def values = readYaml(file: 'prod-us2/javawebapp-prod-us2.yaml')
          checkoutAppRepo("${values.image.tag}")
          deploy("javawebapp-prod-us2","prod-us2","prod-us2/javawebapp-prod-us2.yaml","${values.image.tag}")
        }
        else Utils.markStageSkippedForConditional('DeployProdUs2')
      }
    },
    "prod-eu1": {
      stage('DeployProdEu1') {
        if ( isChangeSet("prod-eu1/javawebapp-prod-eu1.yaml")  ) {
          def values = readYaml(file: 'prod-eu1/javawebapp-prod-eu1.yaml')
          checkoutAppRepo("${values.image.tag}")
          deploy("javawebapp-prod-eu1","prod-eu1","prod-eu1/javawebapp-prod-eu1.yaml","${values.image.tag}")
        }
        else Utils.markStageSkippedForConditional('DeployProdEu1')
      }
    },
    "prod-ap1": {
      stage('DeployProdAp1') {
        if ( isChangeSet("prod-ap1/javawebapp-prod-ap1.yaml")  ) {
          def values = readYaml(file: 'prod-ap1/javawebapp-prod-ap1.yaml')
          checkoutAppRepo("${values.image.tag}")
          deploy("javawebapp-prod-ap1","prod-ap1","prod-ap1/javawebapp-prod-ap1.yaml","${values.image.tag}")
        }
        else Utils.markStageSkippedForConditional('DeployProdAp1')
      }
    }
]
// next Stage starts Deploy Prod in parallel


stage('DeployProd') {
  parallel(running_set)
}
*/

/*
//deploy DEV
stage('DeployDev') {
  if ( isMaster() ) {
    checkoutAppRepo("${params.deployTag}")
    deploy("javawebapp-dev2","dev","dev/javawebapp-dev2.yaml","${params.deployTag}")
  }
  else Utils.markStageSkippedForConditional('DeployDev')
}

// deploy QA
stage('DeployQa') {
  if ( isBuildingTag() ) {
    checkoutAppRepo("${params.deployTag}")
    deploy("javawebapp-qa2","qa","qa/javawebapp-qa2.yaml","${params.deployTag}")
  }
  else Utils.markStageSkippedForConditional('DeployQa')
}
*/

} // node
} //podTemplate


def isMaster() {    // is it DEV release ?
  return ( (!isBuildingTag()) && (params.deployTag != 'Null') )
}

def isBuildingTag() {
  return ( params.deployTag ==~ /^\d+\.\d+\.\d+$/ ) // // QA release has tag as paramete
}


def isChangeSet(filePath) {
  def varBooleanResult=false
  currentBuild.changeSets.each { changeSet ->
    changeSet.items.each { entry ->
      entry.affectedFiles.each { file ->
        if (file.path.equals(filePath)) {
          varBooleanResult = true
        }
      }
    }
  }
  return varBooleanResult
}


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

// Build MAP key : values   - which contains information which Prod app to deploy
// key: path to file with config_app; value: true/false (true - deploy; false - skip)
// example:
// /home/jenkins/agent/workspace/_Project_DeployJavaWebApp_master/dev/javawebapp-dev2.yaml:false
// /home/jenkins/agent/workspace/_Project_DeployJavaWebApp_master/dev/javawebapp-qa2.yaml:true



def buildDeployMap() {
  // creating List list with all file paths with config yaml (dev/qa/prod-*)
  def listFilePaths = []
  stringDeploypaths = \
    sh(returnStdout: true, script: 'find $PWD | grep dev | grep yaml' ) + \
    sh(returnStdout: true, script: 'find $PWD | grep qa | grep yaml' ) + \
    sh(returnStdout: true, script: 'find $PWD | grep prod- | grep yaml' )
  stringDeploypaths.split('\n').each { (listFilePaths - "/home/jenkins/agent/workspace/_Project_DeployJavaWebApp_master/") << it }
  listFilePaths.each{ i -> println "${i}" }

  // initializing deployMap from listFilePaths
  def deployMap = [:]
  listFilePaths.each{ i -> deployMap.put(i, 'false')}
  deployMap.each{ k, v -> println "${k}:${v}" } // test output


  // check keys in map and mark 'true' if it needs to be deployed
  // dev if isMaster()
  // qa if isBuildingTag()
  // prod-  if isChangeSet(filePath)

  // isMaster() || isBuildingTag() || isChangeSet(k)

  //deployMap.each{ k, v -> [k, v = "true"] }
  //map3.'abc'= list3

  // sh 'cat /home/jenkins/agent/workspace/_Project_DeployJavaWebApp_master/prod-us1/javawebapp-prod-us1.yaml'
  if (isChangeSet('prod-us1/javawebapp-prod-us1.yaml')) {
    echo "true!!!"
  }

  for ( k in deployMap ) {
    echo k.value
    k.value = 'true'
  }

  echo " Modified Map here --->>> "
  deployMap.each{ k, v -> println "${k}:${v}" }

  // stage = folder ?

  // parallel ?

  // TMP testing
  echo "Namespace add Release Name"
  echo getNameSpace(listFilePaths[0])
  echo getReleaseName(listFilePaths[0])
}

// get folder name = namespace from file path
def getNameSpace (filePath){
  def nameSpace = filePath.split('/')[1]
  return nameSpace
}
// get file name = release name from file path
def getReleaseName (filePath){
  def releaseName = ""
  def file2 = filePath.split('/')[2]
  releaseName=file2.take(file2.lastIndexOf('.'))
  return releaseName
}
