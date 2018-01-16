#!/bin/env ruby

require 'pathname'

require 'erb'
require 'yaml'
config_dir = Pathname(__dir__).realdirpath.parent + 'config'
blacklight_yaml = config_dir + 'blacklight.yml'
blacklight_config = YAML.load(ERB.new(File.read(blacklight_yaml)).result)

uri  = URI(ENV['SOLR_URL'] || blacklight_config['production']['url'])

path = uri.path.split('/')
corename = path.pop
uri.path = path.join('/') # go up a level -- we popped off the core name
SOLR_URL = uri.to_s



$:.unshift Pathname(__dir__).parent.realdirpath + "lib"
require 'nokogiri'
require 'simple_solr_client'
require_relative '../lib/dromedary/entry_set'


path_to_marshal    = ARGV[0]
individual_entries = ARGV[1..-1]

unless path_to_marshal
  $stderr.puts <<~USAGE

    Usage: 
      export SOLR_URL="http://whatever:whateverport" (default: localhost:8983)
      
          ruby indexer.rb <path/to/data> (which has xml/*/MED*.xml)
      or  ruby indexer.rb </path/to/data> A B (only index entries that start with 'A' or 'B')

  USAGE
  exit(1)
end


module Dromedary
  class Indexer

    LOGGER = Dromedary::Entry::Constants::LOGGER
    attr_reader :target_dirs
    attr_reader :client

    def initialize(datapath, *letters)
      @client  = self.get_client(SOLR_URL)
      @entries = Dromedary::EntrySet.new
      @letters = letters.flatten
      if @letters.empty?
        @full = true
        @letters = ('A'..'Z').to_a
      else
        @full = false
      end
      @datapath = datapath
    rescue => err
      self.logger.error "#{err.message}:\n#{err.backtrace}"
      exit(1)
    end

    def get_client(solr_url)
      solr_client = SimpleSolrClient::Client.new(solr_url)
      med         = solr_client.core('med')

      unless med.up?
        raise "Can't find solr core #{med.name} at #{solr_url}: #{med.ping}"
      end
      med
    end

    def index
      clean_out if @full
      reload
      @letters.each do |letter|
        subset = Dromedary::EntrySet.new.load_by_letter(@datapath, letter)
        logger.info "Working on #{letter}"
        index_all(subset)
      end
      logger.info "Committing..."
      client.commit
      logger.info "Build the suggestions index (may take a bit)"
      client.get('search', {'suggest.buildAll' => 'true'})
      logger.info "Indexing complete"
    end

    def clean_out
      logger.info "Clearing out solr"
      @client.clear.commit
    end

    def reload
      logger.info "Reload core, in case the config changed"
      @client.reload
    end

    def index_all(entries)
      logger.info "Beginning indexing of #{entries.count} entries"
      i     = 1
      slice = 10_000
      entries.each_slice(slice) do |e|
        begin
          client.add_docs e.map(&:solr_doc)
        rescue => err
          logger.warn "Problem with batch; trying documents one at a time"
          e.each do |doc|
            begin
              client.add_docs(doc.solr_doc)
            rescue => err2
              logger.warn "Problem is with #{doc.id}: #{err2.message} #{err2.backtrace}"
            end
          end
        end
      end
    end

    def logger
      LOGGER
    end

  end
end

indexer = Dromedary::Indexer.new(path_to_marshal, individual_entries)
indexer.index
