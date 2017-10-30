#!/usr/bin/env ruby

module Phraugr

  #
  # Randomly split a file, line by line, into two files.
  #
  class Split

    class << self

      # @param i_filename [String] the name of the input file
      # @param o1_filename [String] the name of the first output file
      # @param o2_filename [String] the name of the second output file
      # @param options [Hash] the command line options
      def perform(i_filename, o1_filename, o2_filename, options = {})
        s = new(i_filename, o1_filename, o2_filename, options)
        s.perform
      end

    end

    # @param i_filename [String] the name of the input file
    # @param o1_filename [String] the name of the first output file
    # @param o2_filename [String] the name of the second output file
    # @param options [Hash] the command line options
    def initialize(i_filename, o1_filename, o2_filename, options = {})
      @i_filename = i_filename
      @o1_filename = o1_filename
      @o2_filename = o2_filename
      @options = options

      @probability = @options[:probability] || 0.9

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
      o1 = File.open(@o1_filename, 'wb')
      o2 = File.open(@o2_filename, 'wb')

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
            @random.rand > @probability ? o1 << line : o2 << line
          end

        else
          @random.rand > @probability ? o1 << line : o2 << line
        end

        counter += 1
        print counter if counter % 100000 == 0
      end
    end

  end

end

if (__FILE__ == $0) # If called from the command line
  require 'optparse'

  options = {}

  opt_parser = OptionParser.new do |opt|
    opt.banner = "usage: split.rb [-h] [-p PROBABILITY] [-r RANDOM_SEED] [-s] [-c] input_file output_file1 output_file2"

    opt.on("-h","--help") do
      puts opt_parser
      exit()
    end

    opt.on("-p","--probability PROBABILITY","probability of writing to the first file (default 0.9)") do |probability|
      options[:probability] = probability
    end

    opt.on("-r","--random_seed RANDOM_SEED","random seed") do |random_seed|
      options[:random_seed] = random_seed
    end

    opt.on("-s","--skip_headers","skip the header line") do
      options[:skip_headers] = true
    end

    opt.on("-c","--copy_headers","copy the header line to both output files") do
      options[:copy_headers] = true
    end

  end

  opt_parser.parse!

  if ARGV.size < 3
    raise "Not enough arguments"
  end

  Phraugr::Split.perform(ARGV[0], ARGV[1], ARGV[2], options)
end
