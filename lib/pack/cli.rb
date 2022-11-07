#==============================================================================
# Copyright (C) 2022-present Alces Flight Ltd.
#
# This file is part of Flight Pack.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Flight Pack is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Flight Pack. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Flight Pack, please visit:
# https://github.com/openflighthpc/flight-pack
#==============================================================================
require_relative 'commands'
require_relative 'version'

require 'tty/reader'
require 'commander'
require_relative 'patches/highline-ruby_27_compat'

module Pack
  module CLI
    PROGRAM_NAME = ENV.fetch('FLIGHT_PROGRAM_NAME','pack')

    extend Commander::Delegates
    program :application, "Flight Pack"
    program :name, PROGRAM_NAME
    program :version, "v#{Pack::VERSION}"
    program :description, 'Manage content packs.'
    program :help_paging, false
    default_command :help
    silent_trace!

    error_handler do |runner, e|
      case e
      when TTY::Reader::InputInterrupt
        $stderr.puts "\n#{Paint['WARNING', :underline, :yellow]}: Cancelled by user"
        exit(130)
      else
        Commander::Runner::DEFAULT_ERROR_HANDLER.call(runner, e)
      end
    end

    if ENV['TERM'] !~ /^xterm/ && ENV['TERM'] !~ /rxvt/
      Paint.mode = 0
    end

    class << self
      def cli_syntax(command, args_str = nil)
        command.syntax = [
          PROGRAM_NAME,
          command.name,
          args_str
        ].compact.join(' ')
      end
    end

    command :avail do |c|
      cli_syntax(c)
      c.summary = 'Show available packs'
      c.action Commands, :avail
#      c.option '-r', '--role ROLE', String, 'Specify desktop geometry.'
      c.description = <<EOF
Display a list of available packs.
EOF
    end
    alias_command :av, :avail

    command :download do |c|
      cli_syntax(c, 'PACK')
      c.summary = 'Download a pack'
      c.action Commands, :download
      c.description = <<EOF
Download a pack to make it available for later installation.
EOF
    end
    
    command :info do |c|
      cli_syntax(c, 'PACK')
      c.summary = 'Show information about a pack'
      c.action Commands, :info
      c.option '--no-pager', 'Do not open in a pager'
      c.option '--no-pretty', 'Display as raw markdown'
      c.description = <<EOF
Show information about a pack.
EOF
    end

    command :install do |c|
      cli_syntax(c, 'PACK')
      c.summary = 'Install a pack'
      c.action Commands, :install
      c.description = <<EOF
Install a pack.
EOF
    end
  end
end
