class ProcessReporter
  def initialize(reporter)
    @reporter = reporter
    @process_formatter = ProcessFormatter.new
  end

  def report(count)
    start(count)
    begin
      yield self
    ensure
      finish
    end
  end

  def method_missing(method_name, *args, &block)
    @reporter.send(method_name, *args, &block) if @reporter.respond_to?(method_name)
    @process_formatter.send(method_name, *args, &block) if @process_formatter.respond_to?(method_name)
  end

  def example_failed(example)
    @reporter.send(:example_failed, example)
    @process_formatter.send(:example_failed, example)
    puts example.full_description
    puts example.execution_result[:exception]
  end

  def results_of_forked_process
    @process_formatter.result
  end

  def parse_forked_result(result)
    results = result.split(//).group_by{|e| e}
    results.map{|k, arr| results[k] = arr.size}
    passed = results['S'].to_i
    failed = results['F'].to_i
    pending = results['P'].to_i

    @reporter.instance_variable_set("@example_count", @reporter.instance_variable_get("@example_count") + passed + failed + pending)
    @reporter.instance_variable_set("@failure_count", @reporter.instance_variable_get("@failure_count") + failed)
    @reporter.instance_variable_set("@pending_count", @reporter.instance_variable_get("@pending_count") + pending)
  end
end
