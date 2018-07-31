
pipelineJob('aeskeyfind') {
  definition {
    cps {
      sandbox()
      script("""
        pipeline {
            agent {
                node {
                    label 'docker'
                }
            }
            stages {
                stage('Prepare') {
                    steps {
                        container('dind') {
                            sh """
                            docker pull sansdfir/sift-salt-tester
                            """
                        }
                    }
                }
                stage('Clone') {
                    steps {
                        git "https://github.com/sans-dfir/sift-saltstack.git"
                    }
                }
                stage('Test - aeskeyfind') {
                    steps {
                        container('dind') {
                            sh """
                            docker run --rm --cap-add SYS_ADMIN -v /Users/ekristen/Development/sift/sift-jenkins/sift:/srv/salt/sift sansdfir/sift-salt-tester salt-call --local --retcode-passthrough --state-output=mixed state.sls sift.packages.aeskeyfind
                            """
                        }
                    }
                }
            }
        }
      """.stripIndent())
    }
  }
}
