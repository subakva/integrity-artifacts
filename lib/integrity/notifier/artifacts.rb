require "integrity"

module Integrity
  class Notifier
    class Artifacts < Notifier::Base
      def self.to_haml
        File.read(File.dirname(__FILE__) + "/config.haml")
      end

      def initialize(build, config={})
        super
      end

      # def config
      #   configatron.integrity.artifacts
      # end

      # def log(message)
      #   puts "\n#{message}\n\n"
      # end

      # def run_tasks
      #   config.retrieve('artifacts', []).each do |name|
      #     artifact_enabled = config.retrieve(name).retrieve('enabled', true)
      #     log "Skipping disabled artifact: #{name}" unless artifact_enabled
      #     next unless artifact_enabled
      #   
      #     artifact_task = config.retrieve(name).retrieve('task_name', nil)
      #     next unless artifact_task
      #   
      #     log "Executing task: #{artifact_task} for #{name}..."
      #     Rake::Task[artifact_task].invoke
      #     log "Done."
      #   end
      # end

      # def publish_artifacts
      #   config.retrieve('artifacts', []).each do |name|
      #     next unless config.retrieve(name).retrieve('enabled', true)
      #   
      #     if File.exists?(config.retrieve('public_dir', ''))
      #       artifact_output_dir = config.retrieve(name).output_dir
      #       artifact_archive_dir = File.join(config.public_dir, config.retrieve(name).url_prefix, config.build_name)
      #       artifact_url = URI.join (config.base_url,   config.retrieve(name).url_prefix, config.build_name)
      #       artifact_name = config.retrieve(name).retrieve('display_name', name.capitalize)
      #   
      #       log "#{artifact_name}: Moving artifact from #{artifact_output_dir} to #{artifact_archive_dir}"
      #       mv artifact_output_dir, artifact_archive_dir
      #       log "#{artifact_name}: #{artifact_url}"
      #     end
      #   end
      # end

      def deliver!
        @published = commit.successful?
      end

      def published?
        @published
      end
    end

    register Artifacts
  end
end
