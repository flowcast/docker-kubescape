DEFAULT_NODE_LABEL = 'us-west-2-dev'
CHANNEL = '#alerts-kubescape'
K8S_CONTEXTS = [
  'eks-till-dev-00',
  'eks-till-prod-00',
]

main()

def main() {
  timeout(time: 2, unit: 'HOURS') {
    node(DEFAULT_NODE_LABEL) {
      try {
        setupProperties()
        runPipeline()
      } catch (err) {
        currentBuild.result = 'FAILURE'
        throw err
      } finally {
        postBuildActions()
      }
    }
  }
}

def setupProperties() {
  // set the TERM env var so colors show up
  env.TERM = 'xterm'
  properties([
    pipelineTriggers([cron('H 3 * * *')]), # 
    buildDiscarder(logRotator(daysToKeepStr: '30')),
    disableConcurrentBuilds(),
  ])
}

def runPipeline() {
  githubNotify status: 'PENDING', context: 'Pipeline'
  stage('Checkout') { checkout scm }
  stage('Setup') { sh 'make setup' }
  stage('Build') { sh 'make build' }
  stage('Push') { withArtifactCreds { sh 'make push' } }
  stage('Contexts') { parallel checkContexts(K8S_CONTEXTS) }
}

def checkContexts(contexts) {
  def returnVal = [:]
  for (context in contexts) {
    returnVal[context] = createContextCheck(context)
  }
  return returnVal
}

def createContextCheck(context) {
  return {
    try {
      sh "K8S_CONTEXT=${context} make kubeconfig"
      sh "K8S_CONTEXT=${context} make run"
    } catch (err) {
      currentBuild.result = 'FAILURE'
      throw err
    }
  }
}

def withArtifactCreds(Closure block) {
  return withCredentials([usernamePassword(credentialsId: 'admin-login-for-artifacts-flowcast-ai',
    passwordVariable: 'ARTIFACTS_PASSWORD',
    usernameVariable: 'ARTIFACTS_USERNAME')]) {
    block()
  }
}

def postBuildActions() {
  echo "Running post build actions"
  String currentResult = currentBuild.result ?: 'SUCCESS'
  String previousResult = currentBuild.previousBuild.result ?: 'SUCCESS'
  if (previousResult != currentResult) {
    if (currentResult == 'FAILURE') {
      echo "Build failure"
      def message = ("Build failed: ${env.JOB_NAME} "
        + "${env.BUILD_NUMBER} (<${env.RUN_DISPLAY_URL}/|Open>)")
      echo message
      slackSend channel: CHANNEL, color: "danger",  message: message
    } else {
      message = ("Build fixed: ${env.JOB_NAME} "
          + "${env.BUILD_NUMBER} (<${env.RUN_DISPLAY_URL}/|Open>)")
      slackSend channel: CHANNEL, color: "good",  message: message
    }
  } else {
    echo "previous/current build status equal: ${previousResult}"
  }
}
