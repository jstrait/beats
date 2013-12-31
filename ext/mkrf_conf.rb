# Based on: http://www.programmersparadox.com/2012/05/21/gemspec-loading-dependent-gems-based-on-the-users-system/

# This file needs to be named mkrf_conf.rb
# so that rubygems will recognize it as a ruby extension
# file and not think it is a C extension file

require 'rubygems/dependency_installer.rb'

# Load up the rubygem's dependency installer to 
# installer the gems we want based on the version
# of Ruby the user has installed
installer = Gem::DependencyInstaller.new
begin
  if RUBY_VERSION >= "2"
    installer.install "syck"
  end

  rescue
    # Exit with a non-zero value to let rubygems something went wrong
    exit(1)
end  

# If this was C, rubygems would attempt to run make
# Since this is Ruby, rubygems will attempt to run rake
# If it doesn't find and successfully run a rakefile, it errors out
f = File.open(File.join(File.dirname(__FILE__), "Rakefile"), "w")
f.write("task :default\n")
f.close
