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
require_relative 'config'

require 'yaml'

module Pack
  class Repo
    class << self
      def each(&block)
        all.values.each(&block)
      end

      def [](k)
        all[k.to_sym].tap do |t|
          if t.nil?
            raise UnknownRepoError, "unknown pack: #{k}"
          end
        end
      end

      def all
        @packs ||= {}.tap do |h|
          {}.tap do |a|
            Config.repo_paths.each do |p|
              Dir[File.join(p,'*')].each do |d|
                begin
                  md = YAML.load_file(File.join(d,'metadata.yml'))
                  e = Repo.new(md, d)
                  a[e.id.to_sym] = e
                rescue Errno::ENOENT
                  nil
                end
              end
            end
          end
            .values.sort {|a,b| a.id <=> b.id}
            .each {|t| h[t.id.to_sym] = t}
        end
      end
    end

    attr_reader :description
    attr_reader :id
    attr_reader :locations

    def initialize(md, dir)
      @id = File.basename(dir)
      @description = md[:description]
      @locations = md[:locations]
    end
  end
end
