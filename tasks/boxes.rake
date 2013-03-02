namespace :boxes do
  namespace :build do
    desc 'Packages an Ubuntu cloud image as a Vagrant LXC box'
    task 'ubuntu-cloud' do
      sh 'mkdir -p boxes/output'
      sh 'cp cache/ubuntu-12.10-server-cloudimg-amd64-root.tar.gz boxes/ubuntu-cloud'
      sh 'cd boxes/ubuntu-cloud && tar -czf ../output/ubuntu-cloud.box ./*'
    end
  end
end
