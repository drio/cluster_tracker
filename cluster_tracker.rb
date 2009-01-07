#!/usr/bin/env ruby -W
# == Synopsis
#   This tool will allow us to track the CPU/RAM usages of all the lsf jobs
#   related to solid/slx pipelines.
#
# == Examples
#   To track all the jobs for user sol-pipe between a given interval:
#     $ cluster_tracker -i 2008/12/01,2008/12/31 -u sol-pipe
#     Using bacct file: ./bacct_output.txt
#     Query interval time: (2008/12/17 / 2008/12/18)
#     Total # of jobs   : 686
#     Total CPU consumed: 4601894s 76698m 1278h
#     Total RAM consumed: 1463G
#
# == Usage
#   cluster_tracker [options]
#
#   For help use: cluster_tracker -h
#
# == Options
#   -h, --help          Displays help message
#   -v, --version       Display the version, then exit
#   -u, --user <u>      Jobs belonging to this user
#   -V, --verbose       Run in verbose mode
#   -i, --interval <i>  Interval date
#   -s, --simulate <f>  Use this file instead of running the bacct cmd
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
    opts.on('-s', '--simulate f') { |f| @options.simulate = f }
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
    puts "\n"
  end

  # True if required arguments were provided
  def arguments_valid?
    true if @arguments.length >= 4 && @options.interval && @options.user
  end

  # Setup the arguments
  def process_arguments
    @interval = @options.interval
    @user     = @options.user
    @verbose  = @options.verbose
    @simulate = @options.simulate
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
    parse_interval
    try_to_run("bacct -C #{@start_date},#{@end_date} -l -u #{@user}")
    print_summary
  end

  # Print the output
  def print_summary
    puts "Query interval time: (#{@start_date} / #{@end_date})"
    puts "Total # of jobs   : #{n_jobs}"
    puts "Total CPU consumed: #{cpu_used}"
    puts "Total RAM consumed: #{ram_used}"
  end

  # Extract from bacct the cpu time used
  # Total CPU time consumed:   4601894.5
  def cpu_used
    s = "Total CPU time consumed:"
    begin
      cpu_used = @bacct_output.match(/#{s}\s+(\d+)/)[1]
    rescue
      raise "Problems parsing bacct output: CPU time not found"
    end
    "#{cpu_used}s #{cpu_used.to_i/60}m #{cpu_used.to_i/3600}h"
  end

  # Get adds up the RAM consumed by all the jobs
  def ram_used
    total_ram = 0
    @bacct_output.each_line do |line|
      next if !(line =~ /\s\d+M$/)
      total_ram += line.match(/\s(\d+)M$/)[1].to_i
    end
    (total_ram / 1000).to_s + "G"
  end

  # Parse the bacct output and return the total of number jobs processed
  def n_jobs
    #Total number of done jobs:     686      Total number of exited jobs:    82
    s1 = "Total number of done jobs:"
    s2 = "Total number of exited jobs:"
    begin 
      done, exited = @bacct_output.match(/#{s1}\s+(\d+)\s+#{s2}\s+(\d+)/)[1,2]
    rescue
      raise "Problems parsing bacct out: Total number of jobs not found."
    end
    done
  end

  # Parse the interval data provided by user
  def parse_interval
    begin
      s,e = @interval.split(',')
      # Make sure we have the date in the format bacct expects
      @start_date = Date.parse(s).strftime("%Y/%m/%d")
      @end_date   = Date.parse(e).strftime("%Y/%m/%d")
    rescue
      puts "Problems parsing interval"; raise
    end
  end

  # Try to run a cmd
  def try_to_run(cmd)
    if @simulate
      puts "Using bacct file: #{@simulate}"
      @bacct_output = File.open(@simulate).read
    else
      puts "running: #{cmd}" if @verbose
      @bacct_output = IO.popen("#{cmd}").read
      raise "Error running: #{cmd}, exitcode: #{$?}" if $? != 0
    end
  end
end

if $0 == __FILE__
  app = ClusterTracker.new(ARGV, STDIN)
  app.run
end

