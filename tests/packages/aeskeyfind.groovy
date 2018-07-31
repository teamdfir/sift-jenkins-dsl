pipelineJob('aeskeyfind') {
  definition {
    cps {
      sandbox()
      script("""
        pipeline {
            agent none
            stages {
                stage('Clone') {
                    steps {
                        git "https://github.com/sans-dfir/sift-saltstack.git"
                    }
                }
                stage('Prepare') {
                    steps {
                        node('docker') {
                          container('dind') {
                              sh "docker pull sansdfir/sift-salt-tester"
                          }
                        }
                    }
                }
                stage('Test') {
                    steps {
                        node('docker') {
                          container('dind') {
                              sh "docker run --rm --cap-add SYS_ADMIN -v /Users/ekristen/Development/sift/sift-jenkins/sift:/srv/salt/sift sansdfir/sift-salt-tester salt-call --local --retcode-passthrough --state-output=mixed state.sls sift.packages.aeskeyfind"
                          }
                        }
                    }
                }
            }
        }
      """.stripIndent())
    }
  }
}
