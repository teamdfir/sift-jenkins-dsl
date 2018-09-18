#!/bin/bash

# This script generates the DSLs for building Dockerfiles in each of my repos.

set -e
set -o pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}"  )" && pwd  )"

generate_dsl(){
  local prefix=${1}
	local orig=$2
	local name=${orig#*/}

	local image=${name}
  
  name=$(basename $name)

  rname=${name//.sls/}
	file="${DIR}/saltstack/${prefix//-/_}_${rname//[\+.-]/_}.groovy"

	echo "-  ${file} == ${rname}"

	cat <<-EOF > $file

pipelineJob('sift/saltstack/${rname//[\+.-]/_}') {
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
                stage('Fetch Testing Image') {
                    steps {
                        container('dind') {
                            sh "docker pull sansdfir/sift-salt-tester"
                        }
                    }
                }
                stage('Test State') {
                    steps {
                        container('dind') {
                            sh "docker run --rm --cap-add SYS_ADMIN -v \`pwd\`/sift:/srv/salt/sift sansdfir/sift-salt-tester salt-call --local --retcode-passthrough --state-output=mixed state.sls sift.$prefix.$rname"
                        }
                    }
                }
            }
        }
      """.stripIndent())
    }
  }

  triggers {
      cron('W W * * *')
  }

  logRotator {
      numToKeep(100)
      daysToKeep(15)
  }
  
  publishers {
      extendedEmail {
          recipientList('$DEFAULT_RECIPIENTS')
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

packages=$(ls ../sift-saltstack/sift/packages/*.sls | grep -v init.sls)
python_packages=$(ls ../sift-saltstack/sift/python-packages/*.sls | grep -v init.sls)
scripts=$(ls ../sift-saltstack/sift/scripts/*.sls | grep -v init.sls)

main(){
	mkdir -p $DIR/saltstack
  rm -f $DIR/saltstack/*.groovy
	echo "FILE | IMAGE"

	for r in $packages; do
    generate_dsl "packages" "${r}"
	done

	for r in $python_packages; do
    generate_dsl "python-packages" "${r}"
	done

	for r in $scripts; do
    generate_dsl "scripts" "${r}"
	done
}

main
