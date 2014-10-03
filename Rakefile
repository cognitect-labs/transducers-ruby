# -*- ruby -*-
#!/usr/bin/env rake

# Copyright 2014 Cognitect. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS-IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'bundler'
# Bundler.setup

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
task :default => :spec

task :irb do
  sh 'irb -I lib -r transducers -I dev -r irb_tools'
end

def project_name
  "transducers"
end

def gemspec_filename
  @gemspec_filename ||= "#{project_name}.gemspec"
end

def minor_version
  @minor_version ||= /"(\d+\.\d+).dev"/.match(File.read(gemspec_filename))[1]
end

def revision
  @revision ||= `build/revision`.chomp.to_i
end

def build_version
  @build_version ||= "#{minor_version}.#{revision}"
end

def gem_filename
  @gem_filename ||= "#{project_name}-#{build_version}.gem"
end

def gem_path
  @gem_path ||= "pkg/#{gem_filename}"
end

desc "Build #{gem_filename}.gem into the pkg directory"
task :build do
  begin
    gemspec_content = File.read(gemspec_filename)
    File.open(gemspec_filename, 'w+') do |f|
      f.write gemspec_content.sub("#{minor_version}.dev", build_version)
    end
    sh "gem build #{gemspec_filename}"
    sh "mkdir -p pkg"
    sh "mv #{gem_filename} #{gem_path}"
  ensure
    File.open(gemspec_filename, 'w+') do |f|
      f.write gemspec_content
    end
  end
end

task :set_signed do
  unless ENV['SIGN'] == 'false'
    key  = "~/.gem/transit-ruby-private_key.pem"
    cert = "~/.gem/transit-ruby-public_cert.pem"
    raise "#{cert} and #{key} must both be present to sign the gem" unless
      File.exists?(File.expand_path(cert)) && File.exists?(File.expand_path(key))
    ENV['SIGN'] = 'true'
   end
end

desc "Build and install #{gem_filename}"
task :install => [:build] do
  sh "gem install #{gem_path}"
end

task :ensure_committed do
  raise "Can not release with uncommitted changes." unless `git status` =~ /clean/
end

task :publish => [:build] do
  sh "git tag v#{build_version}"
  puts "Ready to publish #{gem_filename} to rubygems. Enter 'Y' to publish, anything else to stop:"
  input = STDIN.gets.chomp
  if input.downcase == 'y'
    sh "gem push #{gem_path}"
  else
    puts "Canceling publish (you entered #{input.inspect} instead of 'Y')"
    sh "git tag -d v#{build_version}"
  end
end

desc "Create tag v#{build_version} and build and push #{gem_filename} to Rubygems"
task :release => [:ensure_committed, :publish]

desc "Uninstall #{project_name}"
task :uninstall do
  sh "gem uninstall #{project_name}"
end

desc "Clean up generated files"
task :clobber do
  sh "rm -rf ./tmp ./pkg ./.yardoc doc"
end
