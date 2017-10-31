#!/usr/bin/env ruby

module Phraugr

  #
  # Randomly split a file, line by line, into multiple files.
  #
  class Chunk

    class << self

      # @param i_filename [String] the name of the input file
      # @param num_chunks [Integer] the number of output files
      # @param options [Hash] the command line options
      def perform(i_filename, num_chunks, options = {})
        s = new(i_filename, num_chunks, options)
        s.perform
      end

    end

    # @param i_filename [String] the name of the input file
    # @param num_chunks [Integer] the number of output files
    # @param options [Hash] the command line options
    def initialize(i_filename, num_chunks, options = {})
      @i_filename = i_filename
      @num_chunks = num_chunks.to_i
      @options = options

      @seed = @options[:random_seed]
      if @seed.nil? then @random = Random.new
      else
        # Ruby expects Seed values in the form of an Integer
        # Eg. 67009785950850649671507300830502845258
        if @seed.respond_to?(:unpack)
          # Convert a String seed into an Integer
          @seed = @seed.unpack("U*").inject(1) { |v, n| v * n }
        end
        @random = Random.new(@seed)
      end
    end

    def perform
      basename = File.basename(@i_filename)
      ext = File.extname(@i_filename) # ".csv"
      o_file_array = []
      o_file_basename = basename[0..(-1 * (ext.size + 1))]

      @num_chunks.times do |n|
        o_filename = "#{o_file_basename}_%03d#{ext}" % (n + 1)
        o_file_array.push( File.open(o_filename, 'wb') )
      end

      counter = 0
      File.open(@i_filename, 'r').each_line do |line|

        if 0 == counter
          if @options[:skip_headers] && @options[:copy_headers]
            puts "You can either skip or copy headers, not both."
            exit()
          elsif @options[:skip_headers] # Skip
          elsif @options[:copy_headers] # Copy to both
            o1 << line
            o2 << line
          else
            o_file_array[@random.rand(@num_chunks)] << line
          end

        else
          o_file_array[@random.rand(@num_chunks)] << line
        end

        counter += 1
        puts counter if @options[:verbose] && (0 == (counter % 100000))
      end
    end

  end

end

if (__FILE__ == $0) # If called from the command line
  require 'optparse'

  options = {}

  opt_parser = OptionParser.new do |opt|
    opt.banner = "usage: chunk.rb [-h] [-r RANDOM_SEED] [-s] [-c] input_file num_chunks"

    opt.on("-h","--help") do
      puts opt_parser
      exit()
    end

    # Note in the Python version, -s is for SEED, unlike in 'split.py'
    # I changed it because it's nice to be consistent.
    opt.on("-r","--random_seed RANDOM_SEED","random seed") do |random_seed|
      options[:random_seed] = random_seed
    end

    opt.on("-v","--verbose","will write counts during process to standard out") do
      options[:verbose] = true
    end

    opt.on("-s","--skip_headers","skip the header line") do
      options[:skip_headers] = true
    end

    opt.on("-c","--copy_headers","copy the header line to all output files") do
      options[:copy_headers] = true
    end

  end

  opt_parser.parse!

  if ARGV.size < 2
    raise "Not enough arguments"
  end

  Phraugr::Chunk.perform(ARGV[0], ARGV[1], options)
end
