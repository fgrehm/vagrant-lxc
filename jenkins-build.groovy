def vs(command) {
    ansiColor('xterm') {
        writeFile file: 'command.sh', text: command
        echo command
        sh('vagrant ssh -- -t "bash --login /vagrant/command.sh"')
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
                    sh "rm -rf ./*"
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
                    vs("git clone -b ${params.Revision} https://github.com/optimacros/vagrant-lxc")
                    vs('cd vagrant-lxc; bundler install')
                }
            }
        }
        stage('Build') {
            steps {
                script {
                    vs('cd vagrant-lxc; bundle exec rake build')
                    vs('cd vagrant-lxc/pkg; tar -zcf vagrant-lxc-1.4.4.tar.gz vagrant-lxc-1.4.4.gem')
                    vs('mv vagrant-lxc/pkg/vagrant-lxc-1.4.4.gem /vagrant/vagrant-lxc-1.4.4.tar.gz')
                }
                archiveArtifacts allowEmptyArchive: true, artifacts: 'vagrant-lxc-1.4.4.tar.gz', onlyIfSuccessful: true
            }
        }
    }
}    