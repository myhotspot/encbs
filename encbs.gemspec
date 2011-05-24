# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{encbs}
  s.version = "0.2.1.beta1"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1") if s.respond_to? :required_rubygems_version=
  s.authors = ["Timothy Klim"]
  s.date = %q{2011-05-24}
  s.default_executable = %q{encbs}
  s.description = %q{Simple backup system for pushing into cloud}
  s.email = %q{klimtimothy@gmail.com}
  s.executables = ["encbs"]
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]
  s.files = [
    "Gemfile",
    "LICENSE.txt",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "bin/encbs",
    "encbs.gemspec",
    "lib/archive.rb",
    "lib/backup.rb",
    "lib/backup/file_item.rb",
    "lib/backup/file_item/base.rb",
    "lib/backup/file_item/cloud.rb",
    "lib/backup/file_item/local.rb",
    "lib/backup/jar.rb",
    "lib/backup/timestamp.rb",
    "lib/crypto.rb",
    "lib/encbsconfig.rb",
    "lib/helpers.rb",
    "test/fixtures/etc/.hide",
    "test/fixtures/etc/root/file",
    "test/fixtures/test_crypto.rb",
    "test/helper.rb",
    "test/test_backup.rb",
    "test/test_backup_file_item.rb",
    "test/test_backup_timestamp.rb",
    "test/test_jar.rb"
  ]
  s.homepage = %q{http://github.com/TimothyKlim/encbs}
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{Simple backup system for pushing into cloud}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<fog>, [">= 0"])
      s.add_runtime_dependency(%q<slop>, [">= 0"])
      s.add_runtime_dependency(%q<ruby-progressbar>, [">= 0"])
      s.add_runtime_dependency(%q<lzoruby>, [">= 0"])
      s.add_development_dependency(%q<rake>, ["= 0.8.4"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.6.0"])
      s.add_development_dependency(%q<rcov>, [">= 0"])
    else
      s.add_dependency(%q<fog>, [">= 0"])
      s.add_dependency(%q<slop>, [">= 0"])
      s.add_dependency(%q<ruby-progressbar>, [">= 0"])
      s.add_dependency(%q<lzoruby>, [">= 0"])
      s.add_dependency(%q<rake>, ["= 0.8.4"])
      s.add_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_dependency(%q<jeweler>, ["~> 1.6.0"])
      s.add_dependency(%q<rcov>, [">= 0"])
    end
  else
    s.add_dependency(%q<fog>, [">= 0"])
    s.add_dependency(%q<slop>, [">= 0"])
    s.add_dependency(%q<ruby-progressbar>, [">= 0"])
    s.add_dependency(%q<lzoruby>, [">= 0"])
    s.add_dependency(%q<rake>, ["= 0.8.4"])
    s.add_dependency(%q<bundler>, ["~> 1.0.0"])
    s.add_dependency(%q<jeweler>, ["~> 1.6.0"])
    s.add_dependency(%q<rcov>, [">= 0"])
  end
end

