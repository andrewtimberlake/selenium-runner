class ProcessFormatter
  def initialize
    @buffer = ''
  end

  def example_started(*)
  end

  def example_passed(*)

    @buffer << 'S' #Succeeded
  end

  def example_failed(*)
    @buffer << 'F'
  end

  def example_pending(*)
    @buffer << 'P'
  end

  def result
    @buffer
  end
end
