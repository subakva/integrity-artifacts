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

    @integrity_path = "/home/neverland/integrity"
    @builds_path            = "#{@integrity_path}/builds"
    @public_path            = "#{@integrity_path}/public"
    @default_artifact_root    = "#{@public_path}/artifacts"
    
    @config_artifact_root = '/var/www/artifacts'

    @config_file = 'config/artifacts.yml'
  end

  def commit(state)
    Integrity::Build.gen(state).commit
  end

  def init_expected_paths
    @project = @commit.project

    @project_artifacts_path = "#{@default_artifact_root}/#{@project.name}"
    @commit_artifacts_path  = "#{@project_artifacts_path}/#{@commit.short_identifier}"

    @working_path          = "#{Integrity::SCM.working_tree_path(@project.uri)}-#{@project.branch}"
    @full_working_path     = "#{@builds_path}/#{@working_path}"

    @config_path           = "#{@full_working_path}/#{@config_file}"
    @default_output_path   = "#{@full_working_path}/coverage"
    @rcov_output_path      = "#{@full_working_path}/rcov"
    @metric_fu_output_path = "#{@full_working_path}/tmp/metric_fu"
  end

  describe '#to_haml' do
    before(:each) do
      @haml = Integrity::Notifier::Artifacts.to_haml
    end

    it "should be renderable" do
      engine = ::Haml::Engine.new(@haml, {})
      engine.render(self, {:config=>{}})
    end

    it "should render form elements" do
      engine = ::Haml::Engine.new(@haml, {})
      html = engine.render(self, {:config=>{}})
      html.strip.should == %{
<p class='normal'>
  <label for='artifacts_artifact_root'>Artifact Root</label>
  <input class='text' id='artifacts_artifact_root' name='notifiers[Artifacts][artifact_root]' type='text' />
</p>
<p class='normal'>
  <label for='artifacts_config_yaml'>Config YAML</label>
  <input class='text' id='artifacts_config_yaml' name='notifiers[Artifacts][config_yaml]' type='text' />
</p>
<p class='normal'>
  <label for='artifacts_generate_indexes'>
    <input class='checkbox' id='artifacts_generate_indexes' name='notifiers[Artifacts][generate_indexes]' type='checkbox' />
    Generate Indexes?
  </label>
</p>
      }.strip
    end
  end

  describe '#generate_index' do
    before(:each) do
      @dir_name = 'indexed_dir'
      Dir.stub!(:entries).and_return(['.','..'])
      File.stub!(:directory?).and_return(false)

      @file = mock(File)
      @file.stub!(:write)
      File.stub!(:open).and_yield(@file)
    end

    it "creates an index file in the directory" do
      File.should_receive(:open).with("#{@dir_name}/index.html", 'w')
      Integrity::Notifier::Artifacts.generate_index(@dir_name, true)
    end

    it "renders a page containing links to local files" do
      File.should_receive(:open).and_yield(@file)
      @file.should_receive(:write).with(%{<?xml version='1.0' encoding='utf-8' ?>
<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">
<html>
  <head>
    <title>Index of indexed_dir</title>
  </head>
  <body>
    <h1>Index of indexed_dir</h1>
    <ul>
    </ul>
  </body>
</html>
})

      Integrity::Notifier::Artifacts.generate_index(@dir_name, false)
    end

    it "does not create links to dot files" do
      Dir.stub!(:entries).and_return(['.','..','.dotfile'])
      @file.should_receive(:write) do |content|
        content.should_not =~ Regexp.new("<a href='.dotfile'>.dotfile</a>")
      end
      Integrity::Notifier::Artifacts.generate_index(@dir_name, false)
    end

    it "renders a file link" do
      Dir.stub!(:entries).and_return(['.','..','file.txt'])
      @file.should_receive(:write) do |content|
        content.should =~ Regexp.new("<a href='file.txt'>file.txt</a>")
      end
      Integrity::Notifier::Artifacts.generate_index(@dir_name, false)
    end

    it "renders a directory link as a link to an index.html file in that directory" do
      File.should_receive(:directory?).with("#{@dir_name}/directory").and_return(true)
      Dir.stub!(:entries).and_return(['.','..','directory'])
      @file.should_receive(:write) do |content|
        content.should =~ Regexp.new("<a href='directory/index.html'>directory</a>")
      end
      Integrity::Notifier::Artifacts.generate_index(@dir_name, false)
    end

    it "creates a link to the parent by default" do
      @file.should_receive(:write) do |content|
        content.should =~ Regexp.new("<a href='../index.html'>..</a>")
      end
      Integrity::Notifier::Artifacts.generate_index(@dir_name, true)
    end

    it "does not create the link to parent if link_to_parent is false" do
      @file.should_receive(:write) do |content|
        content.should_not =~ Regexp.new("<a href='../index.html'>..</a>")
      end
      Integrity::Notifier::Artifacts.generate_index(@dir_name, false)
    end
  end

  describe 'after a successful build' do

    before(:each) do
      @commit = commit(:successful)
      Integrity::Notifier::Artifacts.stub!(:generate_index)
    end

    describe 'with generate indexes set to true' do
      before(:each) do
        @notifier = Integrity::Notifier::Artifacts.new(commit(:successful), {'generate_indexes' => '1'})
        init_expected_paths
        stub_index_created_for(@default_artifact_root, false)
        stub_index_created_for(@project_artifacts_path, true)
        stub_index_created_for(@commit_artifacts_path, true)
      end

      def stub_index_created_for(path, link_to_parent = true)
        Integrity::Notifier::Artifacts.stub!(:generate_index).with(path, link_to_parent)
      end

      def expect_index_created_for(path, link_to_parent = true)
        Integrity::Notifier::Artifacts.should_receive(:generate_index).with(path, link_to_parent)
      end

      it "should generate the index in the artifact root" do
        expect_index_created_for(@default_artifact_root, false)
        @notifier.deliver!
      end

      it "should generate the index in the project artifact dir" do
        expect_index_created_for(@project_artifacts_path)
        @notifier.deliver!
      end

      it "should generate the index in the commit artifact dir" do
        expect_index_created_for(@commit_artifacts_path)
        @notifier.deliver!
      end
    end

    describe 'with generate indexes set to false' do
      before(:each) do
        @notifier = Integrity::Notifier::Artifacts.new(commit(:successful), {'generate_indexes' => "0"})
        init_expected_paths
      end

      it "should not generate indexes" do
        Integrity::Notifier::Artifacts.should_not_receive(:generate_index)
        @notifier.deliver!
      end
    end

    describe 'with a configuration file' do
      before(:each) do
        @notifier = Integrity::Notifier::Artifacts.new(commit(:successful), {'config_yaml' => @config_file})
        init_expected_paths

        YAML.should_receive(:load_file).with(@config_path).and_return({
          'rcov' => { 'output_dir' => 'rcov' },
          'metric_fu' => {'output_dir' => 'tmp/metric_fu'}
        })
      end
    
      it "should not try to move the default rcov output" do
        FileUtils::Verbose.should_not_receive(:mv).with(@default_output_path, @commit_artifacts_path, :force => true)
        @notifier.deliver!
      end
    
      it "should move the rcov output as configured" do
        FileUtils::Verbose.should_receive(:mv).with(@rcov_output_path, @commit_artifacts_path, :force => true)
        @notifier.deliver!
      end
    
      it "should move the metric_fu output as configured" do
        FileUtils::Verbose.should_receive(:mv).with(@metric_fu_output_path, @commit_artifacts_path, :force => true)
        @notifier.deliver!
      end

      describe 'with rcov disabled' do
        before(:each) do
          YAML.rspec_reset
          YAML.should_receive(:load_file).with(@config_path).and_return({
            'rcov' => { 'output_dir' => 'rcov', 'disabled' => true },
            'metric_fu' => {'output_dir' => 'tmp/metric_fu'}
          })
        end

        it "should not move the default rcov output" do
          FileUtils::Verbose.should_not_receive(:mv).with(@default_output_path, @commit_artifacts_path, :force => true)
          @notifier.deliver!
        end

        it "should not move the configured rcov output" do
          FileUtils::Verbose.should_not_receive(:mv).with(@rcov_output_path, @commit_artifacts_path, :force => true)
          @notifier.deliver!
        end

        it "should move the metric_fu output" do
          FileUtils::Verbose.should_receive(:mv).with(@metric_fu_output_path, @commit_artifacts_path, :force => true)
          @notifier.deliver!
        end
      end
    end

    describe 'with a missing configuration file' do
      before(:each) do
        @notifier = Integrity::Notifier::Artifacts.new(commit(:successful), {'config_yaml' => @config_file})
        init_expected_paths

        File.should_receive(:exists?).with(@config_path).and_return(false)
        Integrity.stub!(:log)
      end

      it "should not try to load the YAML" do
        YAML.should_not_receive(:load_file).with(@config_path)
        @notifier.deliver!
      end

      it "should move the default rcov output" do
        FileUtils::Verbose.should_receive(:mv).with(@default_output_path, @commit_artifacts_path, :force => true)
        @notifier.deliver!
      end

      it "should write a warning to the log" do
        Integrity.should_receive(:log).with("WARNING: Configured yaml file: #{@config_path} does not exist! Using default configuration.")
        @notifier.deliver!
      end
    end

    describe 'with configured artifact_root' do
      before(:each) do
        @notifier = Integrity::Notifier::Artifacts.new(commit(:successful), {'artifact_root'=>@config_artifact_root})
        init_expected_paths
      end

      it "should move the artifact folder to the configured artifact_root" do
        configured_archive_path = "#{@config_artifact_root}/#{@project.name}/#{@commit.short_identifier}"
        FileUtils::Verbose.should_receive(:mv).with(@default_output_path, configured_archive_path, :force => true)
        @notifier.deliver!
      end

    end

    describe 'with a missing artifact_root' do
      before(:each) do
        @notifier = Integrity::Notifier::Artifacts.new(commit(:successful), {'artifact_root' => @config_artifact_root})
        File.should_receive(:exists?).with(@config_artifact_root).and_return(false)
        Integrity.stub!(:log)
        init_expected_paths
        @configured_archive_path = "#{@config_artifact_root}/#{@project.name}/#{@commit.short_identifier}"
      end

      it "should use the default artifact_root if the configured one does not exist" do
        FileUtils::Verbose.should_receive(:mv).with(@default_output_path, @commit_artifacts_path, :force => true)
        FileUtils::Verbose.should_not_receive(:mv).with(@default_output_path, @configured_archive_path, :force => true)
        @notifier.deliver!
      end

      it "should write a warning to the log" do
        Integrity.should_receive(:log).with("WARNING: Configured artifact_root: #{@config_artifact_root} does not exist. Using default: #{@default_artifact_root}")
        @notifier.deliver!
      end
    end

    describe 'with no configuration' do

      before(:each) do
        @notifier = Integrity::Notifier::Artifacts.new(@commit, {})
        init_expected_paths
      end

      it "should create the archive directory if it does not exist" do
        File.should_receive(:exists?).with(@commit_artifacts_path).and_return(false)
        FileUtils::Verbose.should_receive(:mkdir_p).with(@commit_artifacts_path)
        @notifier.deliver!
      end

      it "should not create the archive directory if it already exists" do
        File.should_receive(:exists?).with(@commit_artifacts_path).and_return(true)
        FileUtils::Verbose.should_not_receive(:mkdir_p)
        @notifier.deliver!
      end

      it "should move the rcov output" do
        FileUtils::Verbose.should_receive(:mv).with(@default_output_path, @commit_artifacts_path, :force => true)
        @notifier.deliver!
      end

      it "should not try to move the coverage data if the expected rcov output directory does not exist" do
        File.should_receive(:exists?).with(@default_output_path).and_return(false)
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
