require 'integrity'
require 'configatron'
require 'fileutils'

module Integrity
  class Notifier
    class Artifacts < Notifier::Base
      def self.to_haml
        File.read(File.dirname(__FILE__) + "/config.haml")
      end

      def initialize(commit, config={})
        # puts "commit.class = #{commit.class}<br/>"
        # @config = config
        # @commit = commit
        # @build = @commit.build
        # @project = @commit.project
        super
      end

      # def config
      #   configatron.integrity.artifacts
      # end

      # def run_tasks
      #   config.retrieve('artifacts', []).each do |name|
      #     artifact_enabled = config.retrieve(name).retrieve('enabled', true)
      #     Integrity.log "Skipping disabled artifact: #{name}" unless artifact_enabled
      #     next unless artifact_enabled
      #   
      #     artifact_task = config.retrieve(name).retrieve('task_name', nil)
      #     next unless artifact_task
      #   
      #     Integrity.log "Executing task: #{artifact_task} for #{name}..."
      #     Rake::Task[artifact_task].invoke
      #     Integrity.log "Done."
      #   end
      # end

      def publish_artifacts
        @project = self.commit.project
        working_dir = Integrity.config[:export_directory] / "#{Integrity::SCM.working_tree_path(@project.uri)}-#{@project.branch}"
        artifact_output_dir = File.expand_path(File.join(working_dir, 'coverage'))
        artifact_archive_dir = File.expand_path(File.join(
          Integrity.config[:export_directory],
          '..',
          'public',
          'coverage',
          @project.name,
          self.commit.short_identifier
        ))

        Integrity.log "HEEEELLLLLOOOOOOO"
        Integrity.log("Artifacts") { "HEEEELLLLLOOOOOOO" }
        puts "artifact_output_dir = #{artifact_output_dir}<br/>"
        puts "artifact_archive_dir = #{artifact_archive_dir}<br/>"
        result = FileUtils.mv artifact_output_dir, artifact_archive_dir, :force => true
        puts "result = #{result}<br/>"
        puts "HEEEELLLLLOOOOOOO".reverse

        # config = configatron.integrity.artifacts
        # if config.nil?
        # Assume that the export_directory is {integrity_dir}/builds


        # artifact_output_dir = 'dunno<br/>'

          # Integrity.log "@build = #{@build.inspect}<br/>"
          # Integrity.log "@project = #{@build.commit.project.inspect}<br/>"
          # Integrity.config[:export_directory] / "#{SCM.working_tree_path(@project.uri)}-#{branch}"
          # Integrity.log "SCM.working_tree_path(@project.uri) = #{SCM.working_tree_path(@project.uri)}<br/>"

          # Integrity.config[:export_directory] / "#{SCM.working_tree_path(@project.)}-#{branch}"
          # Integrity.log "@scm = #{@build.commit.project.scm.inspect}<br/>"
          # Integrity.log "@working_directory = #{@build.commit.project.scm.working_directory.inspect}<br/>"
          
          # Integrity.log "@config = #{@config.inspect}<br/>"
          # Integrity.log "Integrity.config = #{Integrity.config.inspect}<br/>"
          # Integrity.log "artifact_archive_dir = #{artifact_archive_dir}<br/>"
          # Integrity.log "artifact_output_dir = #{artifact_output_dir}<br/>"
          # mv artifact_output_dir, artifact_archive_dir
        # end
        
        # artifact_output_dir = config.retrieve(name).output_dir
        # url_prefix = config.retrieve(name).url_prefix
        # artifact_archive_dir = File.join(config.public_dir, url_prefix, config.build_name)
        # mv artifact_output_dir, artifact_archive_dir

        # config.retrieve('artifacts', []).each do |name|
        #   next unless config.retrieve(name).retrieve('enabled', true)
        # 
        #   if File.exists?(config.retrieve('public_dir', ''))
        #     artifact_output_dir = config.retrieve(name).output_dir
        #     url_prefix = config.retrieve(name).url_prefix
        #     artifact_archive_dir = File.join(config.public_dir, url_prefix,       config.build_name)
        #     artifact_url =         URI.join (config.base_url,   url_prefix + '/', config.build_name)
        #     artifact_name = config.retrieve(name).retrieve('display_name', name.capitalize)
        # 
        #     Integrity.log "#{artifact_name}: Moving artifact from #{artifact_output_dir} to #{artifact_archive_dir}"
        #     mv artifact_output_dir, artifact_archive_dir
        #     puts "#{artifact_name}: #{artifact_url}"
        #   end
        # end
      end

      def deliver!
        @published = commit.successful?
        publish_artifacts
      end

      def published?
        @published
      end
    end

    register Artifacts
  end
end
