require 'integrity'
require 'fileutils'

module Integrity
  class Notifier
    class Artifacts < Notifier::Base

      def initialize(commit, config={})
        @project = commit.project
        super
      end

      def deliver!
        return unless self.commit.successful?
        self.publish_artifacts
        self.generate_indexes if should_generate_indexes
      end

      def generate_indexes
        Artifacts.generate_index(self.artifact_root, false)
        Artifacts.generate_index(File.join(self.artifact_root, @project.name), true)
        Artifacts.generate_index(self.artifact_archive_dir, true)
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
        @artifact_root ||= Artifacts.default_artifact_path
        @artifact_root
      end

      def working_dir
        @working_dir ||= Integrity.config[:export_directory] / "#{Integrity::SCM.working_tree_path(@project.uri)}-#{@project.branch}"
        @working_dir
      end

      def should_generate_indexes
        @config.has_key?('generate_indexes') ? @config['generate_indexes'] == '1' : false
      end

      protected

      def load_artifact_root
        if @config.has_key?('artifact_root')
          root_path = @config['artifact_root']
          unless File.exists?(root_path)
            default_path = Artifacts.default_artifact_path
            Integrity.log "WARNING: Configured artifact_root: #{root_path} does not exist. Using default: #{default_path}"
            root_path = default_path
          end
        end
        root_path
      end

      def load_config_yaml
        config = nil
        if @config.has_key?('config_yaml')
          config_yaml = File.expand_path(File.join(working_dir, @config['config_yaml']))
          if File.exists?(config_yaml)
            config = YAML.load_file(config_yaml)
          else
            Integrity.log "WARNING: Configured yaml file: #{config_yaml} does not exist! Using default configuration."
          end
        end
        config
      end

      class << self
        def to_haml
          File.read(File.dirname(__FILE__) + "/config.haml")
        end

        def default_artifact_path
          File.expand_path(File.join(Integrity.config[:export_directory], '..', 'public', 'artifacts'))
        end

        def generate_index(dir, link_to_parent)
          hrefs = build_hrefs(dir, link_to_parent)
          rendered = render_index(dir, hrefs)
          write_index(dir, rendered)
        end

        def build_hrefs(dir, link_to_parent)
          hrefs = {}
          Dir.entries(dir).each do |name|
            # skip dot files
            next if name.match(/^\./)
            hrefs[name] = name
            hrefs[name] << "/index.html" if File.directory?(File.join(dir, name))
          end
          hrefs['..'] = '../index.html' if link_to_parent
          hrefs
        end

        def render_index(dir, hrefs)
          index_haml = File.read(File.dirname(__FILE__) + '/index.haml')
          engine = ::Haml::Engine.new(index_haml, {})
          engine.render(nil, {:dir => dir, :hrefs => hrefs})
        end

        def write_index(dir, content)
          index_path = File.join(dir, 'index.html')
          File.open(index_path, 'w') {|f| f.write(content) }
        end
      end
    end

    register Artifacts
  end
end
