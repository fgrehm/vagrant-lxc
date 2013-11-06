class TestUI < Vagrant::UI::Interface
  attr_reader :messages

  METHODS = [:clear_line, :report_progress, :warn, :error, :info, :success]

  def initialize
    super
    @messages = METHODS.each_with_object({}) { |m, h| h[m] = [] }
  end

  def ask(*args)
    super
    # Automated tests should not depend on user input, obviously.
    raise Errors::UIExpectsTTY
  end

  METHODS.each do |method|
    define_method(method) do |*args|#message, *opts|
      @messages[method].push args[0]
    end
  end
end
