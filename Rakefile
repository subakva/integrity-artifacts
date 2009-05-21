require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "integrity-artifacts"
    gem.summary = %Q{Simple artifact publishing notifier for Integrity}
    gem.email = "jason@secondrotation.com"
    gem.homepage = "http://github.com/subakva/integrity-artifacts"
    gem.authors = ["Jason Wadsworth"]

    gem.add_dependency "integrity"
  end

rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end


task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION.yml')
    config = YAML.load(File.read('VERSION.yml'))
    version = "#{config[:major]}.#{config[:minor]}.#{config[:patch]}"
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "integrity-artifacts #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc "Installs gems required for development"
task :gems do
  puts "Installing gems required for development..."
  sh 'geminstaller -s'
  puts "Done."
end

desc "Execute the integrity build..."
task :integrity do
  puts "Executing the integrity build......"

  Rake::Task['rcov'].invoke

  require 'metric_fu'
  MetricFu::Configuration.run do |fu|
    fu.metrics -= [:rcov] # running rcov seperately
    fu.metrics -= [:saikuro] # saikuro isn't working for this project...
  end
  Rake::Task['metrics:all'].invoke

  # create the build.my.gem file to trigger a gem build/publish cycle
  require 'fileutils'
  FileUtils::Verbose.touch('build.my.gem')

  puts "Done."
end
