namespace :boxes do
  namespace :quantal64 do
    desc 'Build Ubuntu Quantal 64 bits Vagrant LXC box'
    task :build do
      if File.exists?('./boxes/output/lxc-quantal64.box')
        puts 'Box has been built already!'
        exit 1
      end

      sh 'mkdir -p boxes/output'
      sh 'cd boxes/quantal64 && sudo ./download-ubuntu'
      sh 'rm -f boxes/quantal64/rootfs.tar.gz'
      sh 'cd boxes/quantal64 && sudo tar --numeric-owner -czf rootfs.tar.gz ./rootfs-amd64/*'
      sh "cd boxes/quantal64 && sudo chown #{ENV['USER']}:#{ENV['USER']} rootfs.tar.gz && tar -czf ../output/lxc-quantal64.box ./* --exclude=rootfs-amd64 --exclude=download-ubuntu"
      sh 'cd boxes/quantal64 && sudo rm -rf rootfs-amd64'
    end
  end
end
