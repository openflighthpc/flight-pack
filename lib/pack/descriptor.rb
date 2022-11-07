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
require_relative 'errors'
require_relative 'markdown_renderer'
require_relative 'repo'

require 'cgi'
require 'yaml'
require 'whirly'
require 'fileutils'

module Pack
  class Descriptor
    FUNC_DELIMITER = begin
                       major, minor, patch =
                                     IO.popen("/bin/bash -c 'echo $BASH_VERSION'")
                                       .read.split('.')[0..2]
                                       .map(&:to_i)
                       (
                         major > 4 ||
                         major == 4 && minor > 3 ||
                         major == 4 && minor == 3 && patch >= 27
                       ) ? '%%' : '()'
                     end

    class << self
      def each(&block)
        all.values.each(&block)
      end

      def [](k)
        all[k.to_sym].tap do |t|
          if t.nil?
            raise UnknownPackError, "unknown pack: #{k}"
          end
        end
      end

      def all
        @packs ||= {}.tap do |h|
          {}.tap do |a|
            Config.pack_paths.each do |p|
              Dir[File.join(p,'*')].each do |d|
                begin
                  md = YAML.load_file(File.join(d,'metadata.yml'))
                  e = Descriptor.new(md, d)
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

    attr_reader :archives
    attr_reader :author
    attr_reader :id
    attr_reader :description
    attr_reader :dir
    attr_reader :repo

    def initialize(md, dir)
      @id = File.basename(dir)
      @description = md[:description]
      @author = md[:author]
      @archives = md[:archives] || []
      @repo = Repo[md[:repo]]
      @dir = dir
    end

    def locations
      repo.locations
    end
    
    def info_file
      File.join(@dir, 'info.md')
    end

    def usage_file
      File.join(@dir, 'usage.md')
    end

    def state
      if mirrored?
        'Mirrored'
      else
        'Remote'
      end
    end
    
    def mirrored?
      @archives.all? do |a|
        File.exists?(
          File.join(
            Config.store_dir,
            a
          )
        )
      end
    end

    def download
      puts "Downloading pack #{Paint[self.id, :cyan]}"
      puts ""
      t = @archives.length
      n = 0
      if @archives.all? do |a|
          n += 1
          @stage = "Archive #{n}/#{t}: #{a}"
          stage_start
          fetch(a).tap do |r|
            stage_stop(r)
          end
        end
        puts "\nPack #{Paint[self.id, :cyan]} has been downloaded."
      else
        log_file = File.join(
          Config.log_path,
          "#{[self.id, 'download'].compact.join('+')}.log"
        )
        raise PackOperationError, "Download failed for pack #{self.id}; see: #{log_file}"
      end
    end

    def fetch(f)
      if !File.directory?(Config.store_dir)
        FileUtils.mkdir_p(Config.store_dir)
      end
      fetched = locations.find do |l|
        if l.start_with?('/')
          begin
            # file location
            FileUtils.cp(
              File.join(l, f),
              Config.store_dir
            )
            true
          rescue
            false
          end
        else
          # network location
          target = File.join(Config.store_dir, f)
          Signal.trap('INT','IGNORE')
          rd, wr = IO.pipe
          log_file = File.join(
            Config.log_path,
            "#{[self.id, 'download'].compact.join('+')}.log"
          )
          pid = fork {
            rd.close
            Signal.trap('INT','DEFAULT')
            Kernel.exec(
              'wget',
              File.join(l, CGI.escape(f)),
              '-t', '1',
              '-O',"#{target}.alcesdownload",
              [:out, :err] => [log_file,'a+']
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
      !!fetched
    end
    
    def install
      if !mirrored?
        download
      end
      puts "Installing pack #{Paint[self.id, :cyan]}"
      puts ""
      if run_script('install')
        puts "\nPack #{Paint[self.id, :cyan]} has been installed."
        puts "\n"
        puts MarkdownRenderer.new("---\n\n" << File.read(usage_file)).wrap_markdown
      else
        log_file = File.join(
          Config.log_path,
          "#{[self.id, 'install'].compact.join('+')}.log"
        )
        raise PackOperationError, "Installation of pack #{self.id} failed; see: #{log_file}"
      end
    end

    private
    def apply_script
      File.join(@dir, 'apply.sh')
    end

    def run_fork(&block)
      Signal.trap('INT','IGNORE')
      rd, wr = IO.pipe
      pid = fork {
        rd.close
        Signal.trap('INT','DEFAULT')
        begin
          if block.call(wr)
            exit(0)
          else
            exit(1)
          end
        rescue Interrupt
          nil
        end
      }
      wr.close
      while !rd.eof?
        line = rd.readline
        if line =~ /^STAGE:/
          stage_stop
          @stage = line[6..-2]
          stage_start
        elsif line =~ /^ERR:/
          puts "#{Paint[Pack::CLI::PROGRAM_NAME, '#2794d8']}: #{Paint[line[4..-2], :red, :bright]}"
        else
          puts " > #{line}"
        end
      end
      _, status = Process.wait2(pid)
      raise InterruptedOperationError, "Interrupt" if status.termsig == 2
      stage_stop(status.success?)
      Signal.trap('INT','DEFAULT')
      status.success?
    end

    def stage_start
      print "   > "
      Whirly.start(
        spinner: 'star',
        remove_after_stop: true,
        append_newline: false,
        status: Paint[@stage, '#2794d8']
      )
    end

    def stage_stop(success = true)
      return if @stage.nil?
      Whirly.stop
      puts "#{success ? "\u2705" : "\u274c"} #{Paint[@stage, '#2794d8']}"
      @stage = nil
    end

    def setup_bash_funcs(h, fileno)
      h["BASH_FUNC_flight_pack_comms#{FUNC_DELIMITER}"] = <<EOF
() { local msg=$1
 shift
 if [ "$1" ]; then
 echo "${msg}:$*" 1>&#{fileno};
 else
 cat | sed "s/^/${msg}:/g" 1>&#{fileno};
 fi
}
EOF
      h["BASH_FUNC_pack_err#{FUNC_DELIMITER}"] = "() { flight_pack_comms ERR \"$@\"\n}"
      h["BASH_FUNC_pack_stage#{FUNC_DELIMITER}"] = "() { flight_pack_comms STAGE \"$@\"\n}"
#      h['BASH_FUNC_pack_cat()'] = "() { flight_pack_comms\n}"
#      h['BASH_FUNC_pack_echo()'] = "() { flight_pack_comms DATA \"$@\"\necho \"$@\"\n}"
    end

    def run_script(script)
      script_sh = File.join(self.dir, script + '.sh')
      if File.exists?(script_sh)
        with_clean_env do
          run_fork do |wr|
            wr.close_on_exec = false
            setup_bash_funcs(ENV, wr.fileno)
            log_file = File.join(
              Config.log_path,
              "#{[self.id, script].compact.join('+')}.log"
            )
            exec(
              {
                'flight_PACK_ROOT' => Config.root,
                'flight_PACK_store_dir' => Config.store_dir,
              },
              '/bin/bash',
              '-x',
              script_sh,
              self.dir,
              close_others: false,
              [:out, :err] => [log_file ,'w']
            )
          end
        end
      end
    end

    def with_clean_env(&block)
      if Kernel.const_defined?(:OpenFlight) && OpenFlight.respond_to?(:with_standard_env)
        OpenFlight.with_standard_env { block.call }
      else
        msg = Bundler.respond_to?(:with_unbundled_env) ? :with_unbundled_env : :with_clean_env
        Bundler.__send__(msg) { block.call }
      end
    end
  end
end
