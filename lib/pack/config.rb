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
require 'xdg'
require 'tty-config'
require 'fileutils'

module Pack
  module Config
    class << self
      def data
        @data ||= TTY::Config.new.tap do |cfg|
          cfg.append_path(File.join(root, 'etc'))
          begin
            cfg.read
          rescue TTY::Config::ReadError
            nil
          end
        end
      end

      def root
        @root ||= File.expand_path(File.join(__dir__, '..', '..'))
      end

      def flight_root
        @flight_root ||= ENV.fetch('flight_ROOT', '/opt/flight')
      end

      def pack_paths
        @pack_paths ||=
          data.fetch(
            :pack_paths,
            default: [
              'etc/packs'
            ]
          ).map {|p| File.expand_path(p, Config.root)}
      end

      def repo_paths
        @repo_paths ||=
          data.fetch(
            :repo_paths,
            default: [
              'etc/repos'
            ]
          ).map {|p| File.expand_path(p, Config.root)}
      end
      
      def log_path
        @log_path ||=
          File.expand_path(
            data.fetch(
              :log_path,
              default: 'var/log'
            ),
            Config.root
          )
      end

      def store_dir
        @store_dir ||=
          File.expand_path(
            data.fetch(
              :store_dir,
              default: File.join(flight_root, 'var', 'lib', 'pack')
            ),
            Config.root
          )
      end

      def groff_render
        true
      end

      private
      def xdg_config
        @xdg_config ||= XDG::Config.new
      end

      def xdg_data
        @xdg_data ||= XDG::Data.new
      end

      def xdg_cache
        @xdg_cache ||= XDG::Cache.new
      end
    end
  end
end
