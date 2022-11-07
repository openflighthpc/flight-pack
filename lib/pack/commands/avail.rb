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
require_relative '../command'
require_relative '../table'
require_relative '../descriptor'

module Pack
  module Commands
    class Avail < Command
      def run
        if STDOUT.tty?
          if Descriptor.all.empty?
            puts "No packs found."
          else
            Table.emit do |t|
              headers 'Id',
                      'Description',
                      'Repo',
                      'State'
              Descriptor.each do |e|
                row e.id,
                    e.description,
                    e.repo.description,
                    e.state
              end
            end
          end
        else
          Descriptor.each do |e|
            puts [
              e.id,
              e.description,
              e.repo.description,
              e.state
            ].join("\t")
          end
        end
      end
    end
  end
end
