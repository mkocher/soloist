#!/usr/bin/env ruby

guard 'rspec', :cli => '--fail-fast --tag ~@slow:true' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec" }
end

guard 'bundler' do
  watch('Gemfile')
  watch('soloist.gemspec')
end

guard 'shell' do
  watch('Vagrantfile') { system("unset RUBYOPT; vagrant provision") }
  watch('script/bootstrap.sh') { system("unset RUBYOPT; vagrant provision") }
end
