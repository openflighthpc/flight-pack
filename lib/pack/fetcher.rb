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
require_relative 'errors'

require 'fileutils'

module Pack
  module Fetcher
    class << self
      def fetch(url, target, log_file:)
        Signal.trap('INT','IGNORE')
        if !File.directory?(File.dirname(target))
          FileUtils.mkdir_p(File.dirname(target))
        end
        rd, wr = IO.pipe
        pid = fork {
          rd.close
          Signal.trap('INT','DEFAULT')
          Kernel.exec(
            'wget',
            url,
            '-t', '1',
            '-O',"#{target}.alcesdownload",
            [:out, :err] => [log_file.nil? ? '/dev/null' : log_file, 'a+']
          )
        }
        wr.close
        _, status = Process.wait2(pid)
        raise InterruptedOperationError, "Interrupt" if status.termsig == 2
        Signal.trap('INT','DEFAULT')
        if !status.success?
          false
        else
          FileUtils.mv("#{target}.alcesdownload",target)
          true
        end
      end
    end
  end
end
