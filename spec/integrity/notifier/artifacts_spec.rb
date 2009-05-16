require File.dirname(__FILE__) + '/../../spec_helper'

describe Integrity::Notifier::Artifacts do
  include Integrity::Notifier::Test

  before(:each) do
    setup_database
    Integrity.config[:export_directory] = '/home/neverland/integrity/builds'
    FileUtils.stub!(:mv)
  end

  def commit(state)
    @build = Integrity::Build.gen(state)
    @commit = @build.commit
    @project = @commit.project
    @commit
  end

  describe 'after a successful build' do
    before(:each) do
      @notifier = Integrity::Notifier::Artifacts.new(commit(:successful), {})
    end

    it "does something when the build is successful" do
      @notifier.deliver!
      @notifier.should be_published
    end

    describe 'with no configuration' do
      it "moves the rcov output" do
        working_dir = "#{Integrity::SCM.working_tree_path(@project.uri)}-#{@project.branch}"

        output_dir = "/home/neverland/integrity/builds/#{working_dir}/coverage"
        archive_dir = "/home/neverland/integrity/public/coverage/#{@project.name}/#{@commit.short_identifier}"

        FileUtils.should_receive(:mv).with(output_dir, archive_dir, :force => true)
        @notifier.deliver!
      end
    end
  end

  describe 'after a failed build' do
    it "does not do something when the build fails" do
      notifier = Integrity::Notifier::Artifacts.new(commit(:failed), {})
      notifier.deliver!
      notifier.should_not be_published
    end
  end
  
end
