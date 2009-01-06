#!/usr/bin/env ruby -W
# == Synopsis
#   This tool will allow us to track the CPU/RAM usages of all the lsf jobs
#   related to solid/slx pipelines.
#
# == Examples
#   To track all the jobs for user sol-pipe between a given interval:
#     $ cluster_tracker -i 2008/12/01,2008/12/31 -u sol-pipe
#
# == Usage
#   cluster_tracker [options]
#
#   For help use: cluster_tracker -h
#
# == Options
#   -h, --help          Displays help message
#   -v, --version       Display the version, then exit
#   -u, --user          Jobs belonging to this user
#   -V, --verbose       Run in verbose mode
#   -i, --interval      Interval date.
#
# == Author
#   David Rio Deiros (mailto: deiros@bcm.edu)
#
# == Copyright
#   Copyright (c) 2008 David Rio Deiros. Licensed under the BSD License:
#   http://www.opensource.org/licenses/bsd-license.php

require 'optparse'
require 'rdoc/usage'
require 'ostruct'
require 'date'

class ClusterTracker
  VERSION = '0.0.1'

  attr_reader :options

  def initialize(arguments, stdin)
    @arguments = arguments
    @stdin     = stdin

    # Default options
    @options = OpenStruct.new
    @options.verbose  = false
    @options.user     = nil
    @options.interval = nil
  end

  # Parse options, check arguments, then process the command
  def run
    if parsed_options? && arguments_valid?
      puts "Start at #{DateTime.now}\n\n" if @options.verbose

      output_options if @options.verbose # [Optional]

      process_arguments
      process_command

      puts "\nFinished at #{DateTime.now}" if @options.verbose
    else
      output_usage
    end
  end

protected

  def parsed_options?
    # Specify options
    opts = OptionParser.new
    opts.on('-v', '--version')    { output_version ; exit 0 }
    opts.on('-h', '--help')       { output_help }
    opts.on('-V', '--verbose')    { @options.verbose      = true }
    opts.on('-i', '--interval i') { |i| @options.interval = i }
    opts.on('-u', '--user u')     { |u| @options.user     = u }

    opts.parse!(@arguments.dup) rescue return false

    process_options
    true
  end

  # Performs post-parse processing on options
  def process_options
    # For example: @options.verbose = false if @options.quiet
  end

  def output_options
    puts "Options:\n"

    @options.marshal_dump.each do |name, val|
      puts "  #{name} = #{val}"
    end
  end

  # True if required arguments were provided
  def arguments_valid?
    puts @arguments.size.to_s
    true if @arguments.length == 4 && @options.interval && @options.user
  end

  # Setup the arguments
  def process_arguments
    @interval = @options.interval 
    @user     = @options.user
  end
  
  def output_help
    output_version
    RDoc::usage() #exits app
  end
  
  def output_usage
    RDoc::usage('usage') # gets usage from comments above
  end
  
  def output_version
    puts "#{File.basename(__FILE__)} version #{VERSION}"
  end
  
  def process_command
    p "App running here ..." 
  end
end

app = ClusterTracker.new(ARGV, STDIN)
app.run

