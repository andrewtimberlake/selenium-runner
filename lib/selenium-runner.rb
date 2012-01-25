require 'rspec'
require 'selenium-webdriver'
require_relative 'process_reporter'
require_relative 'process_formatter'

module RSpec::Core::DSL
  def visit(url, description, &example_group_block)
    child = describe description, &example_group_block
    child.instance_variable_set("@browser_url", url)
    child
  end
end

class SeleniumRunner
  def self.trap_interrupt
    RSpec::Core::Runner.trap_interrupt
  end

  def self.run(args)
    trap_interrupt
    options = RSpec::Core::ConfigurationOptions.new(args)
    options.parse_options

    configuration = RSpec::configuration
    world = RSpec::world
    configuration.error_stream = $stderr
    configuration.output_stream = $stdout
    options.configure(configuration)
    configuration.load_spec_files
    world.announce_filters

    reporter = ProcessReporter.new(configuration.reporter)

    browsers = [:firefox, :chrome]
    browsers = [:firefox]

    reporter.report(world.example_count, configuration.randomize? ? configuration.seed : nil) do |reporter|
      begin
        configuration.run_hook(:before, :suite)
        mutex = Mutex.new

        results = []
        threads = []
        example_group_indexes = {}
        browsers.each { |b| example_group_indexes[b] = 0 }

        4.times do |i|
          threads << Thread.new do
            browsers.each do |browser|
              until RSpec.wants_to_quit
                group = nil
                mutex.synchronize do
                  group = world.example_groups[example_group_indexes[browser]]
                  example_group_indexes[browser] += 1
                end
                break unless group

                read_end, write_end = IO.pipe
                pid = fork do
                  read_end.close
                  GC.copy_on_write_friendly = true if GC.respond_to?(:copy_on_write_friendly=)  #REE memory benefits

                  url = group.instance_variable_get("@browser_url")
                  group.metadata[:example_group][:description] = "[#{browser}:#{url}] #{group.description}"
                  before_hook = RSpec::Core::Hooks::BeforeHook.new({}) do
                    capabilities = Selenium::WebDriver::Remote::Capabilities.send(browser)
                    # capabilities.version = 5
                    # capabilities.platform = :XP
                    capabilities[:name] = group.description

                    # @driver = Selenium::WebDriver.for(:remote, :url => "http://internuity:235ebfbc-197c-49d2-982e-cc4cb0468f7a@ondemand.saucelabs.com:80/wd/hub", :desired_capabilities => capabilities).tap do |driver|
                    #   driver.navigate.to url
                    # end
                    @driver = Selenium::WebDriver.for(browser).tap do |driver|
                      if url
                        driver.navigate.to url
                      end
                    end
                  end
                  group.hooks[:before][:all].unshift before_hook
                  after_hook = RSpec::Core::Hooks::AfterHook.new({}) { @driver.quit if @driver }
                  group.hooks[:after][:all].unshift after_hook
                  group.let(:driver) { @driver }

                  results << group.run(reporter)
                  write_end.write reporter.results_of_forked_process
                  write_end.close
                end
                write_end.close
                Process.wait
                mutex.synchronize do
                  reporter.parse_forked_result(read_end.read)
                end
              end
            end
          end
        end
        threads.each do |t|
          begin
            t.join if t.alive?
          rescue Interrupt
          end
        end

        results.all? ? 0 : configuration.failure_exit_code
      ensure
        configuration.run_hook(:after, :suite)
      end
    end
  end
end

at_exit do
  SeleniumRunner.run(ARGV)
end
