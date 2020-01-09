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
      def nameStage

// checkout Config repo
      stage('Checkout SCM Deploy Config repo') {
        checkout scm
        sh "ls"
        echo "${params.DEPLOY_TAG}"
        tagDockerImage = "${params.DEPLOY_TAG}"
        echo $tagDockerImage
      }

// working / tested
//
// *** Git Clone /
//

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


/*
    sh "pwd"
    sh "ls -la"
    sh "git log --oneline -n 1 | cut -b 1-7"
    sh "git describe --tags $(git rev-list --tags --max-count=1)"
*/


// git log --oneline -n 1 | cut -b 1-7  # it is mast recent short commit from master
// git describe --tags $(git rev-list --tags --max-count=1) # most recent tag
// git tag -l  | tail -n1  # highest tag

//
// *** Deploy DEV release
//
// tagDockerImage = ${params.DEPLOY_TAG}
    stage('Deploy DEV release') {
        echo "Every commit to master branch is a dev release"
        echo "Deploy Dev release after commit to master"
        deployHelm("javawebapp-dev2","dev",${params.DEPLOY_TAG})
    }



    } // node
  } //podTemplate


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
            helm upgrade --install $name --debug .AppDir/javawebapp-chart \
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
