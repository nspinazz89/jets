require "json"
require "rack/utils" # Rack::Utils.parse_nested_query

# Controller public methods get turned into Lambda functions.
class Jets::Controller
  class Base < Jets::Lambda::Functions
    include ActiveSupport::Rescuable
    include Authorization
    include Callbacks
    include Cookies
    include ForgeryProtection
    include Jets::Router::Helpers
    include Layout
    include Params
    include Rendering

    delegate :headers, to: :request
    delegate :set_header, to: :response
    attr_reader :request, :response
    attr_accessor :session
    def initialize(event, context={}, meth)
      super
      @request = Request.new(event, context)
      @response = Response.new
    end

    # Overrides Base.process
    def self.process(event, context={}, meth)
      controller = new(event, context, meth)
      # Using send because process! is private method in Jets::RackController so
      # it doesnt create a lambda function.  It's doesnt matter what scope process!
      # is in Controller::Base because Jets lambda functions inheritance doesnt
      # include methods in Controller::Base.
      controller.send(:process!)
    end

    # One key difference between process! vs dispatch!
    #
    #    process! - takes the request through the middleware stack
    #    dispatch! - does not
    #
    # Most of the time, you want process! instead of dispatch!
    #
    def process!
      adapter = Jets::Controller::Rack::Adapter.new(event, context, meth)
      adapter.rack_vars(
        'jets.controller' => self,
        'lambda.context' => context,
        'lambda.event' => event,
        'lambda.meth' => meth,
      )
      # adapter.process ultimately calls app controller action at the very last
      # middleware stack.
      adapter.process # Returns API Gateway hash structure
    end

    def dispatch!
      t1 = Time.now
      log_info_start

      begin
        if run_before_actions(break_if: -> { @rendered })
          send(@meth)
          action_completed = true
        else
          Jets.logger.info "Filter chain halted as #{@last_callback_name} rendered or redirected"
        end

        triplet = ensure_render
        run_after_actions if action_completed
      rescue Exception => exception
        rescue_with_handler(exception) || raise
        triplet = ensure_render
      end

      took = Time.now - t1
      status = triplet[0]
      Jets.logger.info "Completed Status Code #{status} in #{took}s"
      triplet # status, headers, body
    end

    def log_info_start
      display_event = @event.dup
      display_event['body'] = '[BASE64_ENCODED]' if @event['isBase64Encoded']
      # JSON.dump makes logging look pretty in CloudWatch logs because it keeps it on 1 line
      ip = request.ip
      Jets.logger.info "Started #{@event['httpMethod']} \"#{@event['path']}\" for #{ip} at #{Time.now}"
      Jets.logger.info "Processing #{self.class.name}##{@meth}"
      Jets.logger.info "  Event: #{json_dump(display_event)}"
      Jets.logger.info "  Parameters: #{JSON.dump(params(raw: true).to_h)}"
    end

    # Handles binary data safely
    def json_dump(data)
      JSON.dump(data)
    rescue Encoding::UndefinedConversionError
      data['body'] = '[BINARY]'
      JSON.dump(data)
    end

    def controller_paths
      paths = []
      klass = self.class
      while klass != Jets::Controller::Base
        paths << klass.controller_path
        klass = klass.superclass
      end
      paths
    end

    def action_name
      @meth
    end

    class_attribute :internal_controller
    class << self
      def internal(value=nil)
        if !value.nil?
          self.internal_controller = value
        else
          self.internal_controller
        end
      end

      def helper_method(*meths)
        meths.each do |meth|
          Jets::Router::Helpers.define_helper_method(meth)
        end
      end
    end
  end
end
