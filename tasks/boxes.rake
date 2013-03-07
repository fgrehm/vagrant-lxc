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

    desc 'Build Ubuntu Quantal x64 Vagrant LXC box'
    task 'quantal-64' do
      unless File.exists?('/var/cache/lxc/quantal/rootfs-amd64')
        puts "Right now you need to run `lxc-create` with the right arguments to build debootstrap's cache " +
             "prior to building the box.\n" +
             "Please contact me at the mail you'll find at https://github.com/fgrehm/vagrant-lxc/issues\n" +
             "if you want to find out how to get this going."
        exit 1
      end

      sh 'mkdir -p boxes/output'
      sh 'rm -f output/lxc-quantal-64.box'
      sh 'cd boxes/quantal-64 && tar -czf ../output/lxc-quantal-64.box ./*'
    end
  end
end
