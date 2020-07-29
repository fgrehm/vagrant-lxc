def vs(command, returnStdout = false) {
    ansiColor('xterm') {
        writeFile file: 'command.sh', text: command
        echo command
        return sh(script: 'vagrant ssh -- -t "bash --login /vagrant/command.sh"', returnStdout: returnStdout)
    }
}

pipeline {
    agent { label 'vagrant' }
    parameters {
      string(name: 'Revision', defaultValue: 'optimacros', description: 'sha, tag or branch to build')
    }
    stages {
        stage('Init container') {
            steps {
                script {
                    if(fileExists(".vagrant")) {
                        catchError {
                            sh 'vagrant destroy --force'
                        }
                    }
                    dir("vagrant-lxc") {
                        sh 'git reset --hard && git clean -ffdx'
                    }
                    sh 'rm -f Vagrantfile vagrant-lxc.tar.gz'
                    sh 'vagrant init emptybox/ubuntu-bionic-amd64-lxc'
                    sh 'vagrant up'
                    vs("sudo systemd-run --property='After=apt-daily.service apt-daily-upgrade.service' --wait /bin/true")
                }
            }
        }
        stage('Install environment') {
            steps {
                script {
                    vs('sudo apt-get update')
                    vs('echo \'* libraries/restart-without-asking boolean true\' | sudo debconf-set-selections')
                    vs('sudo apt-get -y install software-properties-common git curl')
                    vs('curl -sSL https://rvm.io/mpapis.asc | gpg --import -')
                    vs('curl -sSL https://rvm.io/pkuczynski.asc | gpg --import -')
                    vs('curl -sSL https://get.rvm.io | bash -s stable')
                    vs("echo 'source ~/.rvm/scripts/rvm' >> ~/.bashrc")
                    vs('rvm install ruby-2.3.1')
                    vs('gem install bundler')
                    vs('cp -r /vagrant/vagrant-lxc vagrant-lxc')
                    vs('cd vagrant-lxc; bundler install')
                }
            }
        }
        stage('Build') {
            steps {
                script {
                    def version = vs("cd vagrant-lxc; ruby vagrant-lxc-version.rb", true).trim()
                    echo "Version: ${version}"
                    vs('cd vagrant-lxc; bundle exec rake build')
                    vs("echo \"${version}\" > vagrant-lxc/pkg/version.txt")
                    vs("mv vagrant-lxc/pkg/vagrant-lxc-${version}.gem vagrant-lxc/pkg/vagrant-lxc.gem")
                    vs("cd vagrant-lxc/pkg; sudo tar -zcf /vagrant/vagrant-lxc.tar.gz vagrant-lxc.gem version.txt")
                }
                archiveArtifacts allowEmptyArchive: true, artifacts: 'vagrant-lxc.tar.gz', onlyIfSuccessful: true
            }
        }
    }
}