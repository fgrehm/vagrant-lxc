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
  end
end
