namespace :boxes do
  namespace :build do
    IMAGE_ROOT = 'https://cloud-images.ubuntu.com/releases/quantal/release-20130206'
    IMAGE_NAME = 'ubuntu-12.10-server-cloudimg-amd64-root.tar.gz'
    def download(source, destination)
      destination = "#{File.dirname __FILE__}/../#{destination}"
      if File.exists?(destination)
        puts 'Skipping box image download'
      else
        sh "wget #{source} -O #{destination}"
      end
    end

    desc 'Packages an Ubuntu cloud image as a Vagrant LXC box'
    task 'ubuntu-cloud' do
      sh 'mkdir -p boxes/output'
      download "#{IMAGE_ROOT}/#{IMAGE_NAME}", "boxes/ubuntu-cloud/#{IMAGE_NAME}"
      sh 'rm -f output/ubuntu-cloud.box'
      sh 'cd boxes/ubuntu-cloud && tar -czf ../output/ubuntu-cloud.box ./*'
    end

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
