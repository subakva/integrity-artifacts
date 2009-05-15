require 'spec'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rubygems'
require 'integrity'
require "integrity/notifier/test"

require 'integrity/notifier/artifacts'

Spec::Runner.configure do |config|
  
end
