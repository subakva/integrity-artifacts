require 'integrity'
require 'fileutils'

module Integrity
  class Notifier
    class Artifacts < Notifier::Base
      def self.to_haml
        File.read(File.dirname(__FILE__) + "/config.haml")
      end

      def initialize(commit, config={})
        @project = commit.project
        super
      end

      def artifact_root
        # If the configuration is missing, assume that the export_directory is {integrity_dir}/builds
        @artifact_root ||= @config['artifact_root']
        unless File.exists?(@artifact_root)
          @artifact_root = File.expand_path(File.join(Integrity.config[:export_directory], '..', 'public', 'artifacts'))
        end
        @artifact_root ||= File.expand_path(File.join(Integrity.config[:export_directory], '..', 'public', 'artifacts'))
        @artifact_root
      end

      def working_dir
        @working_dir ||= Integrity.config[:export_directory] / "#{Integrity::SCM.working_tree_path(@project.uri)}-#{@project.branch}"
        @working_dir
      end

      def artifact_archive_dir
        @artifact_archive_dir ||= File.expand_path(File.join(self.artifact_root, @project.name, self.commit.short_identifier))
        @artifact_archive_dir
      end

      def load_config_yaml
        if @config.has_key?('config_yaml')
          config_yaml = File.expand_path(File.join(working_dir, @config['config_yaml']))
          config = YAML.load_file(config_yaml) if File.exists?(config_yaml)
        end
        config
      end

      def artifacts
        # If the configuration is missing, try rcov for kicks
        @artifacts ||= load_config_yaml
        @artifacts ||= {'rcov' => { 'output_dir' => 'coverage' }}
        @artifacts
      end

      def publish_artifacts
        self.artifacts.each do |name, config|
          next if config.has_key?('disabled') && config['disabled']
          artifact_output_dir = File.expand_path(File.join(working_dir, config['output_dir']))
          if File.exists?(artifact_output_dir)
            FileUtils::Verbose.mkdir_p(artifact_archive_dir) unless File.exists?(artifact_archive_dir)
            FileUtils::Verbose.mv artifact_output_dir, artifact_archive_dir, :force => true
          end
        end
      end

      def deliver!
        publish_artifacts if self.commit.successful?
      end

    end

    register Artifacts
  end
end
