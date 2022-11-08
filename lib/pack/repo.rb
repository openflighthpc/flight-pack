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
require_relative 'extractor'
require_relative 'fetcher'

require 'digest/md5'
require 'fileutils'
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
            raise UnknownRepoError, "unknown repo: #{k}"
          end
        end
      end

      def add(url)
        repo_log_file = File.join(
          Config.log_path,
          "repo.#{Digest::MD5.hexdigest(url)}.log"
        )
        repofile = File.join(
          Config.store_dir,
          "repo.#{Digest::MD5.hexdigest(url)}.yml"
        )
        # download manifest file
        if !Fetcher.fetch(
             url,
             repofile,
             log_file: repo_log_file
           )
          raise RepoOperationError, "unable to download repo manifest; see: #{repo_log_file}"
        end
        # download pack collection
        repodata = YAML.load_file(repofile)
        pack_data_file = File.join(
          Config.store_dir,
          "pack.#{Digest::MD5.hexdigest(repodata[:pack_data])}.tar.bz2"
        )
        puts repodata.inspect
        if !Fetcher.fetch(
             repodata[:pack_data],
             pack_data_file,
             log_file: repo_log_file
           )
          raise RepoOperationError, "unable to download pack data; see: #{repo_log_file}"
        end
        # create repo definition
        repo_dir = File.join(
          Config.repo_paths.first,
          repodata[:id],
        )
        FileUtils.mkdir_p(repo_dir)
        File.write(
          File.join(repo_dir, 'metadata.yml'),
          repodata[:descriptor].to_yaml
        )
        # extract pack index
        FileUtils.mkdir_p(Config.pack_paths.first)
        Extractor.extract(
          pack_data_file,
          Config.pack_paths.first,
          log_file: repo_log_file
        )
        Repo[repodata[:id]]
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
