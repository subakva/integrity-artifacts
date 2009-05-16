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

      def deliver!
        self.publish_artifacts if self.commit.successful?
      end

      def publish_artifacts
        self.artifacts.each do |name, config|
          next if config.has_key?('disabled') && config['disabled']
          artifact_output_dir = File.expand_path(File.join(self.working_dir, config['output_dir']))
          if File.exists?(artifact_output_dir)
            FileUtils::Verbose.mkdir_p(self.artifact_archive_dir) unless File.exists?(self.artifact_archive_dir)
            FileUtils::Verbose.mv artifact_output_dir, self.artifact_archive_dir, :force => true
          end
        end
      end

      def artifacts
        # If the configuration is missing, try rcov for kicks
        @artifacts ||= self.load_config_yaml
        @artifacts ||= {'rcov' => { 'output_dir' => 'coverage' }}
        @artifacts
      end

      def artifact_archive_dir
        @artifact_archive_dir ||= File.expand_path(File.join(self.artifact_root, @project.name, self.commit.short_identifier))
        @artifact_archive_dir
      end

      def artifact_root
        # If the configuration is missing, assume that the export_directory is {integrity_dir}/builds
        @artifact_root ||= self.load_artifact_root
        @artifact_root ||= self.default_artifact_path
        @artifact_root
      end

      def working_dir
        @working_dir ||= Integrity.config[:export_directory] / "#{Integrity::SCM.working_tree_path(@project.uri)}-#{@project.branch}"
        @working_dir
      end

      protected

      def default_artifact_path
        File.expand_path(File.join(Integrity.config[:export_directory], '..', 'public', 'artifacts'))
      end

      def load_artifact_root
        if @config.has_key?('artifact_root')
          root_path = @config['artifact_root']
          unless File.exists?(root_path)
            Integrity.log "WARNING: Configured artifact_root: #{root_path} does not exist. Using default: #{self.default_artifact_path}"
            root_path = self.default_artifact_path
          end
        end
        root_path
      end

      def load_config_yaml
        config = nil
        if @config.has_key?('config_yaml')
          config_yaml = File.expand_path(File.join(working_dir, @config['config_yaml']))
          if File.exists?(config_yaml)
            config = YAML.load_file(config_yaml) if File.exists?(config_yaml)
          else
            Integrity.log "WARNING: Configured yaml file: #{config_yaml} does not exist! Using default configuration."
          end
        end
        config
      end

    end

    register Artifacts
  end
end
