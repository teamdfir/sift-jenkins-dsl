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

pipelineJob('sift/packages/${rname//./_}') {
  definition {
    cps {
      sandbox()
      script("""
        pipeline {
            agent none
            stages {
                stage('Clone') {
                    steps {
                        node('docker') {
                            git "https://github.com/sans-dfir/sift-saltstack.git"
                        }
                    }
                }
                stage('Fetch Docker Testing Image') {
                    steps {
                        node('docker') {
                            container('dind') {
                                sh "docker pull sansdfir/sift-salt-tester"
                            }
                        }
                    }
                }
                stage('Test State') {
                    steps {
                        node('docker') {
                            container('dind') {
                                sh "docker run --rm --cap-add SYS_ADMIN -v \`pwd\`/sift:/srv/salt/sift sansdfir/sift-salt-tester salt-call --local --retcode-passthrough --state-output=mixed state.sls sift.packages.$rname"
                            }
                        }
                    }
                }
            }
        }
      """.stripIndent())
    }
  }

  logRotator {
      numToKeep(100)
      daysToKeep(15)
  }

  publishers {
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

packages=$(ls ../sift-saltstack/sift/packages/*.sls | head -n 10)

main(){
	mkdir -p $DIR/tests/packages
	echo "FILE | IMAGE"

	for r in $packages; do
    generate_dsl "${r}"
	done
}

main
