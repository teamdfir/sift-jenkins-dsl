freeStyleJob('maintenance-apply-dsl') {
    displayName('apply-dsl')
    description('Applies all the Jenkins DSLs in the sift-jenkins-dsl repository.')

    checkoutRetryCount(3)

    properties {
        githubProjectUrl('git@github.com:ekristen/sift-jenkins-dsl.git')
    }

    logRotator {
        numToKeep(100)
        daysToKeep(15)
    }

    scm {
        git {
            remote {
                url('git@github.com:ekristen/sift-jenkins-dsl.git')
                credentials('github')
            }
            branches('*/master')
            extensions {
                wipeOutWorkspace()
                cleanAfterCheckout()
            }
        }
    }

    triggers {
        githubPush()
    }

    wrappers { colorizeOutput() }

    steps {
        dsl {
            folder('sift') {
              description('folder for SIFT related tests')
            }
            folder('sift/saltstack') {
              description('folder containing jobs for testing packages installed via apt for SIFT')
            }
            external('**/*.groovy')
            removeAction('DELETE')
            removeViewAction('DELETE')
            additionalClasspath('.')
        }
    }
}
