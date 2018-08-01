
pipelineJob('sift/packages/phonon') {
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
                stage('Clone') {
                    steps {
                        git "https://github.com/sans-dfir/sift-saltstack.git"
                    }
                }
                stage('Fetch Docker Testing Image') {
                    steps {
                        container('dind') {
                            sh "docker pull sansdfir/sift-salt-tester"
                        }
                    }
                }
                stage('Test State') {
                    steps {
                        container('dind') {
                            sh "docker run --rm --cap-add SYS_ADMIN -v `pwd`/sift:/srv/salt/sift sansdfir/sift-salt-tester salt-call --local --retcode-passthrough --state-output=mixed state.sls sift.packages.phonon"
                        }
                    }
                }
            }
        }
      """.stripIndent())
    }
  }

  triggers {
      cron('H H * * *')
  }

  logRotator {
      numToKeep(100)
      daysToKeep(15)
  }
  
  publishers {
      extendedEmail {
          recipientList('')
          contentType('text/plain')
          triggers {
              stillFailing {
                    attachBuildLog(true)
              }
          }
      }
      wsCleanup()
  }
}
