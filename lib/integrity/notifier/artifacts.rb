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

      def deliver!
        @delivered = commit.successful?
      end

      def delivered?
        @delivered
      end
    end

    register Artifacts
  end
end
