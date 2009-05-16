require File.dirname(__FILE__) + '/../../spec_helper'

describe Integrity::Notifier::Artifacts do
  include Integrity::Notifier::Test

  before(:each) do
    setup_database
    Integrity.config[:export_directory] = '/home/neverland/integrity/builds'
    File.stub!(:exists?).and_return(true)
    FileUtils::Verbose.stub!(:mkdir_p)
    FileUtils::Verbose.stub!(:mv)
    YAML.stub!(:load_file).and_return({})
  end

  def commit(state)
    Integrity::Build.gen(state).commit
  end

  def init_expected_dirs
    @project = @commit.project
    @working_dir = "#{Integrity::SCM.working_tree_path(@project.uri)}-#{@project.branch}"

    @archive_dir = "/home/neverland/integrity/public/artifacts/#{@project.name}/#{@commit.short_identifier}"

    @default_output_dir = "/home/neverland/integrity/builds/#{@working_dir}/coverage"
    @rcov_output_dir = "/home/neverland/integrity/builds/#{@working_dir}/rcov"
    @metric_fu_output_dir = "/home/neverland/integrity/builds/#{@working_dir}/tmp/metric_fu"
  end

  describe 'after a successful build' do

    before(:each) do
      @commit = commit(:successful)
    end

    describe 'with a configuration file' do
      before(:each) do
        @notifier = Integrity::Notifier::Artifacts.new(commit(:successful), {'config_yaml' => "config/artifacts.yml"})
        init_expected_dirs

        @config_file = "/home/neverland/integrity/builds/#{@working_dir}/config/artifacts.yml"
        YAML.should_receive(:load_file).with(@config_file).and_return({
          'rcov' => { 'output_dir' => 'rcov' },
          'metric_fu' => {'output_dir' => 'tmp/metric_fu'}
        })
      end
    
      it "should not try to move the default rcov output" do
        FileUtils::Verbose.should_not_receive(:mv).with(@default_output_dir, @archive_dir, :force => true)
        @notifier.deliver!
      end
    
      it "should move the rcov output as configured" do
        FileUtils::Verbose.should_receive(:mv).with(@rcov_output_dir, @archive_dir, :force => true)
        @notifier.deliver!
      end
    
      it "should move the metric_fu output as configured" do
        FileUtils::Verbose.should_receive(:mv).with(@metric_fu_output_dir, @archive_dir, :force => true)
        @notifier.deliver!
      end

      describe 'with rcov disabled' do
        before(:each) do
          YAML.rspec_reset
          YAML.should_receive(:load_file).with(@config_file).and_return({
            'rcov' => { 'output_dir' => 'rcov', 'disabled' => true },
            'metric_fu' => {'output_dir' => 'tmp/metric_fu'}
          })
        end

        it "should not move the default rcov output" do
          FileUtils::Verbose.should_not_receive(:mv).with(@default_output_dir, @archive_dir, :force => true)
          @notifier.deliver!
        end

        it "should not move the configured rcov output" do
          FileUtils::Verbose.should_not_receive(:mv).with(@rcov_output_dir, @archive_dir, :force => true)
          @notifier.deliver!
        end

        it "should move the metric_fu output" do
          FileUtils::Verbose.should_receive(:mv).with(@metric_fu_output_dir, @archive_dir, :force => true)
          @notifier.deliver!
        end
      end
    end

    describe 'with a missing configuration file' do
      before(:each) do
        @notifier = Integrity::Notifier::Artifacts.new(commit(:successful), {'config_yaml' => "config/artifacts.yml"})
        init_expected_dirs

        @config_file = "/home/neverland/integrity/builds/#{@working_dir}/config/artifacts.yml"
        File.should_receive(:exists?).with(@config_file).and_return(false)
      end

      it "should not try to load the YAML" do
        YAML.should_not_receive(:load_file).with(@config_file)
        @notifier.deliver!
      end

      it "should move the default rcov output" do
        FileUtils::Verbose.should_receive(:mv).with(@default_output_dir, @archive_dir, :force => true)
        @notifier.deliver!
      end
    end

    describe 'with configured artifact_root' do
      before(:each) do
        @notifier = Integrity::Notifier::Artifacts.new(commit(:successful), {'artifact_root'=>'/var/www/artifacts'})
        init_expected_dirs
      end

      it "should move the artifact folder to the configured artifact_root" do
        configured_archive_dir = "/var/www/artifacts/#{@project.name}/#{@commit.short_identifier}"
        FileUtils::Verbose.should_receive(:mv).with(@default_output_dir, configured_archive_dir, :force => true)
        @notifier.deliver!
      end
    end

    describe 'with a missing artifact_root' do
      before(:each) do
        @notifier = Integrity::Notifier::Artifacts.new(commit(:successful), {'artifact_root'=>'/var/www/artifacts'})
        File.should_receive(:exists?).with('/var/www/artifacts').and_return(false)
        init_expected_dirs
      end

      it "should use the default artifact_root if the configured one does not exist" do
        configured_archive_dir = "/var/www/artifacts/#{@project.name}/#{@commit.short_identifier}"
        FileUtils::Verbose.should_receive(:mv).with(@default_output_dir, @archive_dir, :force => true)
        @notifier.deliver!
      end
    end

    describe 'with no configuration' do

      before(:each) do
        @notifier = Integrity::Notifier::Artifacts.new(@commit, {})
        init_expected_dirs
      end

      it "should create the archive directory if it does not exist" do
        File.should_receive(:exists?).with(@archive_dir).and_return(false)
        FileUtils::Verbose.should_receive(:mkdir_p).with(@archive_dir)
        @notifier.deliver!
      end

      it "should not create the archive directory if it already exists" do
        File.should_receive(:exists?).with(@archive_dir).and_return(true)
        FileUtils::Verbose.should_not_receive(:mkdir_p)
        @notifier.deliver!
      end

      it "should move the rcov output" do
        FileUtils::Verbose.should_receive(:mv).with(@default_output_dir, @archive_dir, :force => true)
        @notifier.deliver!
      end

      it "should not try to move the coverage data if the expected rcov output directory does not exist" do
        File.should_receive(:exists?).with(@default_output_dir).and_return(false)
        FileUtils::Verbose.should_not_receive(:mv)
        @notifier.deliver!
      end
    end
  end

  describe 'after a failed build' do
    it "should not move artifacts" do
      FileUtils::Verbose.should_not_receive(:mv)
      notifier = Integrity::Notifier::Artifacts.new(commit(:failed), {})
      notifier.deliver!
    end
  end
  
end
