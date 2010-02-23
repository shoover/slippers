load File.expand_path(File.dirname(__FILE__) + "/tasks/spec.rake")

require 'rake'
require 'spec/rake/spectask'

desc "Generate the gem using technicalpickles jeweler"
begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "slippers"
    gem.summary = "A strict templating library for Ruby"
    gem.email = "me@sarahtaraporewalla.com"
    gem.homepage = "http://slippersrb.com"
    gem.description = "A strict templating library for ruby"
    gem.authors = ["Sarah Taraporewalla"]
    gem.files =  FileList["[A-Z]*", "{bin,lib,spec,examples,tasks}/**/*"]
    gem.add_dependency 'treetop'
    gem.add_development_dependency 'mocha'
    gem.add_development_dependency 'rspec'
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler, or one of its dependencies, is not available. Install it with: sudo gem install jeweler"
end

task :default => "spec:run"
