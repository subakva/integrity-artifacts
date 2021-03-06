Integrity Artifacts
=========

You can use integrity-artifacts to copy build artifacts from your integrity builds

Installation
=========

1. sudo gem install subakva-integrity-artifacts --source=http://gems.github.com
2. Add require 'integrity/notifier/artifacts' to config.ru
3. Enable the notifier on the project page
4. [Optional] Set "Artifact Root" to the file-system path where the artifacts should be saved
5. [Optional] Set "Config YAML" to the location of your artifacts config file relative to your repository root
6. Click "Update Project"

Example config.ru
=========

    #!/usr/bin/env ruby

    require "rubygems"
    require "integrity"

    require 'integrity/notifier/artifacts'

    # Load configuration and initialize Integrity
    Integrity.new(File.dirname(__FILE__) + "/config.yml")

    # You probably don't want to edit anything below
    Integrity::App.set :environment, ENV["RACK_ENV"] || :production
    Integrity::App.set :port,        8910

    run Integrity::App

Example artifacts.yml
=========

    ---
      rcov: 
        output_dir: coverage
      metric_fu: 
        output_dir: tmp/metric_fu

Example integrity.rake
=========

    namespace :integrity do
      desc "Execute the integrity build..."
      task :build do
        puts "Executing the integrity build......"

        Rake::Task['rcov'].invoke

        require 'metric_fu'
        MetricFu::Configuration.run do |fu|
          fu.metrics -= [:rcov] # running rcov seperately
          fu.metrics -= [:saikuro] # saikuro isn't working for this project...
        end
        Rake::Task['metrics:all'].invoke

        puts "Done."
      end
    end


Copyright
==========

Copyright (c) 2009 Jason Wadsworth. See LICENSE for details.
