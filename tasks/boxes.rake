namespace :boxes do
  namespace :build do
    desc 'Build Ubuntu Quantal 64 bits Vagrant LXC box'
    task 'quantal64' do
      unless File.exists?('./boxes/quantal64/rootfs-amd64')
        sh 'cd boxes/quantal64 && ./download-ubuntu'
      end

      sh 'mkdir -p boxes/output'
      sh 'sudo rm -f output/lxc-quantal64.box boxes/quantal64/rootfs.tar.gz'
      sh 'cd boxes/quantal64 && sudo tar --numeric-owner -czf rootfs.tar.gz ./rootfs-amd64/*'
      sh "cd boxes/quantal64 && sudo chown #{ENV['USER']}:#{ENV['USER']} rootfs.tar.gz && tar -czf ../output/lxc-quantal64.box ./* --exclude=rootfs-amd64 --exclude=download-ubuntu"
    end
  end
end
