$LOAD_PATH << File.expand_path('../../lib', __FILE__)

require 'pry'
require 'logger'

require 'spec_helper'

Dir[File.expand_path('../support/**/*.rb', __FILE__)].each {|f| require f }

require 'web_shield'

