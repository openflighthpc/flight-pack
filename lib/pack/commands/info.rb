# =============================================================================
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
# ==============================================================================
require_relative '../command'
require_relative '../config'
require_relative '../descriptor'

require 'tty-pager'
require 'open3'

module Pack
  module Commands
    class Info < Command
      GROFF_CMD = 'groff -mtty-char -mandoc -Tascii -t -'

      def run
        ENV['PAGER'] ||= 'less -FRX'
        if !pager?
          puts load_content
        else
          TTY::Pager.new.page(load_content)
        end
      end

      def pager?
        options.no_pager.nil?
      end

      def pretty?
        options.no_pretty.nil?
      end
      
      def load_content
        arg_pack = args[0]
        pack = Descriptor[arg_pack]
        content = File.read(pack.info_file) + "\n\n" + File.read(pack.usage_file)
        if $stdout.tty? && pretty?
          if Config.groff_render
            render_manpage(content)
          else
            render(content)
          end
        else
          content
        end
      end
      
      def render_manpage(content)
        env = {
          'PATH' => '/bin:/sbin:/usr/bin:/usr/sbin',
          'HOME' => ENV['HOME'],
          'USER' => ENV['USER'],
          'LOGNAME' => ENV['LOGNAME'],
        }
        html  = Kramdown::Document.new(content,
                                       smart_quotes: ['apos', 'apos', 'quot', 'quot'],
                                       typographic_symbols: { hellip: '...', ndash: '--', mdash: '--' },
                                       hard_wrap: false,
                                       input: 'GFM').to_html
        roff  = Kramdown::Document.new(html, input: 'html').to_man
        out, errors, status = Open3.capture3(
                       env,
                       GROFF_CMD,
                       stdin_data: roff,
                       unsetenv_others: true,
                       close_others: true,
                     )

        if status.success?
          out
        else
          raise RenderError, "Failed to render info: #{pack.id} #{errors}"
        end
      end

      ##
      # Renders the markdown
      def render(content)
        MarkdownRenderer.new(content).wrap_markdown
      end
    end
  end
end
