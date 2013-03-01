desc 'Packages a dummy Vagrant box to be used during development'
task :package_dummy_box do
  sh 'cd dummy-box-files/ && tar -czf ../dummy-ubuntu-cloudimg.box ./*'
end
