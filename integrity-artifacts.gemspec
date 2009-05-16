# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{integrity-artifacts}
  s.version = "0.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jason Wadsworth"]
  s.date = %q{2009-05-16}
  s.email = %q{jason@secondrotation.com}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "TODO.rdoc",
     "VERSION",
     "geminstaller.yml",
     "lib/integrity/notifier/artifacts.rb",
     "lib/integrity/notifier/config.haml",
     "spec/integrity/notifier/artifacts_spec.rb",
     "spec/spec_helper.rb"
  ]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/subakva/integrity-artifacts}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Simple artifact publishing notifier for Integrity}
  s.test_files = [
    "spec/integrity/notifier/artifacts_spec.rb",
     "spec/spec_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<integrity>, [">= 0"])
    else
      s.add_dependency(%q<integrity>, [">= 0"])
    end
  else
    s.add_dependency(%q<integrity>, [">= 0"])
  end
end
