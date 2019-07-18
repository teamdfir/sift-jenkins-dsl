freeStyleJob('maintenance-apply-dsl') {
    displayName('apply-dsl')
    description('Applies all the Jenkins DSLs in the sift-jenkins-dsl repository.')

    checkoutRetryCount(3)

    properties {
        githubProjectUrl('https://github.com/sans-dfir/sift-jenkins-dsl.git')
    }

    logRotator {
        numToKeep(100)
        daysToKeep(15)
    }

    scm {
        git {
            remote {
                url('https://github.com/sans-dfir/sift-jenkins-dsl.git')
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
            folder('sift/16.04-xenial') {
              description('folder containing jobs for testing packages installed via apt for SIFT on Xenial')
            }
            folder('sift/18.04-bionic') {
              description('folder containing jobs for testing packages installed via apt for SIFT on Xenial')
            }
            external('**/*.groovy')
            removeAction('DELETE')
            removeViewAction('DELETE')
            additionalClasspath('.')
        }
    }
}
