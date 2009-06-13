$: << File.join(File.dirname(__FILE__), '/../../lib')

require 'just_played'
require 'fileutils'
require 'chronic'
require 'spec/expectations'

module SnapsHelper
  def app
    @app ||= JustPlayed.new 'localhost'
  end

  def test_server
    'http://localhost:4567'
  end
end

World(SnapsHelper)

Before do
  app.reset
end
