#!/bin/bash

# This script generates the DSLs for building Dockerfiles in each of my repos.

set -e
set -o pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}"  )" && pwd  )"

generate_dsl(){
	local orig=$1
	local name=${orig#*/}

	local image=${name}
  
  name=$(basename $name)

  rname=${name//.sls/}
	file="${DIR}/tests/packages/${rname}.groovy"

	echo "-  ${file} == ${rname}"

	cat <<-EOF > $file
freeStyleJob('${rname//./_}') {
    displayName('${name}')
    description('Test SLS file in ${name}.')

    concurrentBuild()
    checkoutRetryCount(3)

    properties {
        githubProjectUrl('https://github.com/sans-dfir/sift-saltstack')
    }

    logRotator {
        numToKeep(100)
        daysToKeep(15)
    }

    scm {
        git {
            remote {
                url('https://github.com/sans-dfir/sift-saltstack.git')
            }
			      branches('*/master', '*/tags/*')
            extensions {
                wipeOutWorkspace()
                cleanAfterCheckout()
            }
        }
    }

    triggers {
        cron('H H * * *')
        githubPush()
    }

    wrappers { colorizeOutput() }

    environmentVariables(DOCKER_CONTENT_TRUST: '1')
    steps {
        shell('export BRANCH=\$(git symbolic-ref -q --short HEAD || git describe --tags --exact-match || echo "master"); if [[ "\$BRANCH" == "master" ]]; then export BRANCH="latest"; fi; echo "\$BRANCH" > .branch')
        shell('docker pull sansdfir/sift-salt-tester')
        shell('docker run --it --rm --cap-add SYS_ADMIN sansdir/sift-salt-tester salt-call --local --retcode-passthrough --state-output=mixed state.sls sift.packages.$rname')

    }

    publishers {
        retryBuild {
            retryLimit(2)
            fixedDelay(15)
        }

        extendedEmail {
            recipientList('\$DEFAULT_RECIPIENTS')
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
EOF

}



packages=$(ls ../sift-saltstack/sift/packages/*.sls)

main(){
	mkdir -p $DIR/tests/packages
	echo "FILE | IMAGE"

	for r in $packages; do
    generate_dsl "${r}"
	done
}

main
