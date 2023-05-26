/* groovylint-disable UnnecessaryGString */
import groovy.test.GroovyTestCase

class JenkinsFileTest extends GroovyTestCase {

  void testSuccess() {
    def jenkinsPipeline = getJenkinsPipeline()
    jenkinsPipeline.metaClass.currentBuild = [
      result: "SUCCESS",
      previousBuild: [
        result: "FAILURE"
      ]
    ]
    captureStdOut() { buffer ->
      jenkinsPipeline.main()
      def actual = buffer.toString()
      new File('/tmp/success.txt').write(actual)
      assertEquals expectedSuccess, actual
    }
  }

  void testFailure() {
    def jenkinsPipeline = getJenkinsPipeline()
    jenkinsPipeline.metaClass.currentBuild = [
      result: "FAILURE",
      previousBuild: [
        result: "SUCCESS"
      ]
    ]
    captureStdOut() { buffer ->
      jenkinsPipeline.main()
      def actual = buffer.toString()
      new File('/tmp/failure.txt').write(actual)
      assertEquals expectedFailure, actual
    }
  }

  void testException() {
    def jenkinsPipeline = getJenkinsPipeline()
    jenkinsPipeline.metaClass.sh = { command ->
      println("Running sh command: ${command}")
      throw new Exception("asdf")
    }
    jenkinsPipeline.metaClass.currentBuild = [
      result: "FAILURE",
      previousBuild: [
        result: "SUCCESS"
      ]
    ]
    captureStdOut() { buffer ->
      shouldFail Exception, {
        jenkinsPipeline.main()
      }
      def actual = buffer.toString()
      new File('/tmp/exception.txt').write(actual)
      assertEquals expectedError, actual
    }
  }

  def getJenkinsPipeline() {
    def shell = new GroovyShell()
    def jenkinsPipeline = shell.parse(new File('Jenkinsfile'))
    stubJenkinsApi(jenkinsPipeline)
    return jenkinsPipeline
  }

  def captureStdOut(func) {
    def oldOut = System.out
    def buffer = new ByteArrayOutputStream()
    def newOut = new PrintStream(buffer)
    System.out = newOut
    func(buffer)
    System.out = oldOut
  }

  def stubJenkinsApi(jenkinsPipeline) {
    jenkinsPipeline.metaClass.DEFAULT_NODE_LABEL = 'us-west-2-dev'
    jenkinsPipeline.metaClass.CHANNEL = '#alerts-kubescape'
    jenkinsPipeline.metaClass.K8S_CONTEXTS = [
      'eks-till-dev-02',
      'eks-till-prod-00',
    ]
    jenkinsPipeline.metaClass.buildDiscarder = { args -> }
    jenkinsPipeline.metaClass.checkout = { args -> }
    jenkinsPipeline.metaClass.cron = {}
    jenkinsPipeline.metaClass.currentBuild = [
      result: "SUCCESS",
      previousBuild: [result: "SUCCESS"],
    ]
    jenkinsPipeline.metaClass.disableConcurrentBuilds = {}
    jenkinsPipeline.metaClass.echo = { message -> println(message) }
    jenkinsPipeline.metaClass.env = [
      BRANCH_NAME: "develop",
      BUILD_NUMBER: "1",
      JOB_NAME: "asdf",
      RUN_DISPLAY_URL: "asdf2",
    ]
    jenkinsPipeline.metaClass.fileExists = { path ->
      return new File(path).exists()
    }
    jenkinsPipeline.metaClass.githubNotify = { args ->
      println("Notifying github status: ${args.status}, context: ${args.context}")
    }
    jenkinsPipeline.metaClass.logRotator = { args ->
      println("Setting log rotate to ${args.daysToKeepStr} days")
    }
    jenkinsPipeline.metaClass.node = { name = "default", func ->
      println("Running on node ${name}"); func()
    }
    jenkinsPipeline.metaClass.parallel = { args ->
      println("Running in parallel")
      args.each { arg ->
        println("Running target ${arg.key}")
        arg.value()
      }
    }
    jenkinsPipeline.metaClass.pipelineTriggers = {}
    jenkinsPipeline.metaClass.properties = {}
    jenkinsPipeline.metaClass.readFile = { path ->
      return new File(path).getText().trim()
    }
    jenkinsPipeline.metaClass.scm = [:]
    jenkinsPipeline.metaClass.sh = { command ->
      println("Running sh command: ${command}")
    }
    jenkinsPipeline.metaClass.slackSend = { args ->
      println("slackSend channel:${args.channel} "
        + "message:${args.message} color:${args.color}")
    }
    jenkinsPipeline.metaClass.stage = { name, func ->
      println("Running stage: ${name}"); func()
    }
    jenkinsPipeline.metaClass.timeout = { args, func ->
      println("Setting timeout to ${args.time} ${args.unit}"); func()
    }
    jenkinsPipeline.metaClass.usernamePassword = { args ->
      println("Using username and password ${args}")
    }
    jenkinsPipeline.metaClass.withCredentials = { creds, func -> func() }
    jenkinsPipeline.metaClass.withPyenv = { verison, func -> func() }
    jenkinsPipeline.metaClass.writeFile = { path, text ->
      new File(path) << text
    }
  }

  def expectedSuccess = """\
  Setting timeout to 2 HOURS
  Running on node us-west-2-dev
  Setting log rotate to 30 days
  Notifying github status: PENDING, context: Pipeline
  Running stage: Checkout
  Running stage: Jenkinsfile
  Running sh command: make test-jenkinsfile
  Running stage: Setup
  Running sh command: make setup
  Running stage: Build
  Running sh command: make build
  Running stage: Push
  Using username and password [credentialsId:admin-login-for-artifacts-flowcast-ai, passwordVariable:ARTIFACTS_PASSWORD, usernameVariable:ARTIFACTS_USERNAME]
  Running sh command: make push
  Running stage: Contexts
  Running in parallel
  Running target eks-till-dev-02
  Running sh command: K8S_CONTEXT=eks-till-dev-02 make kubeconfig
  Running sh command: K8S_CONTEXT=eks-till-dev-02 make scan
  Running target eks-till-prod-00
  Running sh command: K8S_CONTEXT=eks-till-prod-00 make kubeconfig
  Running sh command: K8S_CONTEXT=eks-till-prod-00 make scan
  Running post build actions
  slackSend channel:#alerts-kubescape message:Build fixed: asdf 1 (<asdf2/|Open>) color:good
  """.stripIndent()

  def expectedFailure = """\
  Setting timeout to 2 HOURS
  Running on node us-west-2-dev
  Setting log rotate to 30 days
  Notifying github status: PENDING, context: Pipeline
  Running stage: Checkout
  Running stage: Jenkinsfile
  Running sh command: make test-jenkinsfile
  Running stage: Setup
  Running sh command: make setup
  Running stage: Build
  Running sh command: make build
  Running stage: Push
  Using username and password [credentialsId:admin-login-for-artifacts-flowcast-ai, passwordVariable:ARTIFACTS_PASSWORD, usernameVariable:ARTIFACTS_USERNAME]
  Running sh command: make push
  Running stage: Contexts
  Running in parallel
  Running target eks-till-dev-02
  Running sh command: K8S_CONTEXT=eks-till-dev-02 make kubeconfig
  Running sh command: K8S_CONTEXT=eks-till-dev-02 make scan
  Running target eks-till-prod-00
  Running sh command: K8S_CONTEXT=eks-till-prod-00 make kubeconfig
  Running sh command: K8S_CONTEXT=eks-till-prod-00 make scan
  Running post build actions
  Build failure
  Build failed: asdf 1 (<asdf2/|Open>)
  slackSend channel:#alerts-kubescape message:Build failed: asdf 1 (<asdf2/|Open>) color:danger
  """.stripIndent()

  def expectedError = """\
  Setting timeout to 2 HOURS
  Running on node us-west-2-dev
  Setting log rotate to 30 days
  Notifying github status: PENDING, context: Pipeline
  Running stage: Checkout
  Running stage: Jenkinsfile
  Running sh command: make test-jenkinsfile
  Running post build actions
  Build failure
  Build failed: asdf 1 (<asdf2/|Open>)
  slackSend channel:#alerts-kubescape message:Build failed: asdf 1 (<asdf2/|Open>) color:danger
  """.stripIndent()
}
