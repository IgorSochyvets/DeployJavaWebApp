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
stage('Checkout') {
  checkout scm
  sh "ls -la"
  echo "${params.deployTag}"  // parameters from upstream job - short commit
}

// build deployMap and start stages
buildDeployMap()

} // node
} //podTemplate

//
// Methods
//

// is it DEV release ?
def isMaster() {
  return ( (!isBuildingTag()) && (params.deployTag != 'Null') )
}
// is it QA release ?
def isBuildingTag() {
  return ( params.deployTag ==~ /^\d+\.\d+\.\d+$/ )
}

// check if file was changed (filePath structure example: prod-ap1/javawebapp-prod-ap1.yaml )
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

// checkout App repo to commit function
def checkoutAppRepo(commitId) {
  checkout([$class: 'GitSCM',
  branches: [[name: "${commitId}"]],
  extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: "${commitId}"]],
  userRemoteConfigs: [[credentialsId: 'github_key', url: 'https://github.com/IgorSochyvets/fizz-buzz.git']]])
  sh 'ls -la'

}

// Build MAP key : values   - which contains information which Dev/Qa/Prod release to deploy
// Start Stages for Deployment or Skipping here
def buildDeployMap() {
  // creating List list with all file paths with config yaml (dev/qa/prod-*)
  def listFilePaths = []
  stringDeploypaths = \
    sh(returnStdout: true, script: 'find $PWD | grep dev | grep yaml | cut -c 64-' ) + \
    sh(returnStdout: true, script: 'find $PWD | grep qa | grep yaml | cut -c 64-' ) + \
    sh(returnStdout: true, script: 'find $PWD | sort | grep prod- | grep yaml | cut -c 64-' )
  stringDeploypaths.split('\n').each { listFilePaths << it }

  // initializing deployMap from listFilePaths with all values = 'false'
  def deployMap = [:]
  listFilePaths.each{ i -> deployMap.put(i, 'false')}

  // check keys in map and add its value as 'true' if it needs to be deployed
  for ( k in deployMap ) {
    if (isChangeSet(k.key))  {
      k.value = 'true'
    }
    else if (isMaster()) {
        if ( getNameSpace(k.key) == "dev" ) k.value = 'true'
    }
    else if (isBuildingTag()) {
        if ( getNameSpace(k.key) == 'qa' ) k.value = 'true'
    }
  }

  echo "Map to be deployed ('true' - to be deployed): "
  deployMap.each{ k, v -> println "${k}:${v}" }

  /* do deploy stages successively
  // every deployMap element - stage (deploy or skip)
  deployMap.each {
    stage("Deploy:" + it.key) {
      if (it.value == 'true') {
        echo "Deploying " + it.key
        if ( isMaster() || isBuildingTag() ) {
          checkoutAppRepo("${params.deployTag}")
          deployHelm(getReleaseName(it.key), getNameSpace(it.key), it.key, "${params.deployTag}")
        }
        else if (isChangeSet(it.key))  {
          def values = readYaml(file: it.key)
          checkoutAppRepo("${values.image.tag}")
          deployHelm(getReleaseName(it.key), getNameSpace(it.key), it.key, "${values.image.tag}")
        }
      }
      else {
        echo "Skipping " + it.key
        Utils.markStageSkippedForConditional("Deploy:" + it.key)
      }
    }
  }
*/

  // do checkout successively and Create Folders
  def listTags = []
  deployMap.each {
      if (it.value == 'true') {
        if ( isMaster() || isBuildingTag() ) {
          listTags << params.deployTag
//          checkoutAppRepo("${params.deployTag}")
        }
        else if (isChangeSet(it.key))  {
          def values = readYaml(file: it.key)
          listTags << values.image.tag
//          checkoutAppRepo("${values.image.tag}")
        }
      }
  }
  // do checkout (tag) ( once for each tag )
  listTags.toSet().each { println checkoutAppRepo(it)}

  // return list.toSet()

    //do deploy stages in parallel
  def runningMap = [ : ]
  deployMap.each {
    runningMap.put(it.key, { stage("Deploy:"+it.key) {
      if (it.value == 'true') {
        echo "Deploying " + it.key
        if (isMaster() || isBuildingTag()) {
          deployHelm(getReleaseName(it.key), getNameSpace(it.key), it.key, "${params.deployTag}")
        }
        else if (isChangeSet(it.key))  {
          def values = readYaml(file: it.key)
          deployHelm(getReleaseName(it.key), getNameSpace(it.key), it.key, "${values.image.tag}")
        }
      }
      else {
        echo "Skipping " + it.key
        Utils.markStageSkippedForConditional("Deploy:"+it.key)
      }
    }
    })
  }

  stage('Parallel') {
    parallel(runningMap)
  }
    //end of parallel block

} //end of  buildDeployMap


// Main Methon for Helm Deployment for Dev/Qa/Prod
// name - release name; ns - namespace; filePath - path to config file releaseName.yaml, refName - name of dir where App Repo is stored;
def deployHelm(name, ns, filePath, refName) {
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

// get folder name = namespace from file path
def getNameSpace (filePath){
  def nameSpace = filePath.split('/')[0]
  return nameSpace
}
// get file name = release name from file path
def getReleaseName (filePath){
  def releaseName = ""
  releaseName=filePath.split('/')[1].take(filePath.split('/')[1].lastIndexOf('.'))
  return releaseName
}
