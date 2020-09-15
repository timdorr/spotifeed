desc "Open an IRB session"
task :console do
  # Load all gems
  require 'rubygems'
  require 'bundler/setup'
  Bundler.require(:default)

  # Load the envs
  require 'dotenv'
  Dotenv.load!

  # Load IRB
  require 'irb'
  require 'irb/completion'

  IRB.conf[:AUTO_INDENT] = true

  ARGV.clear
  IRB.start
end
