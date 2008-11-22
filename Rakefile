# -*- ruby -*-
require 'rubygems'
require 'hoe'
require 'spec/rake/spectask'

$: << '../../ParseTree/dev/lib' << '../../RubyInline/dev/lib'

require './lib/flog'

Hoe.new('flog', Flog::VERSION) do |flog|
  flog.rubyforge_name = 'seattlerb'

  flog.developer('Ryan Davis', 'ryand-ruby@zenspider.com')

  flog.extra_deps << ["ParseTree", '>= 2.0.1']
end

task :default => :spec

desc "Run all specs in spec directory (excluding plugin specs)"
Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_opts = ['--options', "\"#{File.dirname(__FILE__)}/spec/spec.opts\""]
  t.spec_files = FileList['spec/**/*_spec.rb']
end

# vim: syntax=Ruby
