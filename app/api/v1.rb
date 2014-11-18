Dir.glob(File.expand_path('../v1/**/*.rb', __FILE__)).sort.
  each { |f| require f }

require_relative '../../lib/actors'

module Evercam
  class APIv1 < Grape::API

	formatter :m3u8, lambda { |object, env| object }

	content_type :json, "application/json"

    # use JSON if accept header empty
    default_format :json

    helpers do
      def auth
        WithAuth.new(env)
      end
      include AuthorizationHelper
      include CameraHelper
      include CacheHelper
      include ErrorsHelper
      include LoggingHelper
      include SessionHelper
      include ThreeScaleHelper
      include ParameterMapper
    end

    # The position of this is important so beware of moving it!
    before do
      map_parameters!
    end

    # disable annoying I18n message
    I18n.enforce_available_locales = false

    # configure the api
    extend GrapeJSONFormatters
    extend GrapeErrorHandlers

    # Mount actual endpoints
    mount V1UserRoutes
    mount V1CameraRoutes
    mount V1SnapshotRoutes
    mount V1SnapshotJpgRoutes
    mount V1ModelRoutes
    mount V1TestRoutes
    mount V1ClientRoutes
    mount V1PublicRoutes
    mount V1ShareRoutes
    mount V1LogRoutes
    mount V1WebhookRoutes

    # bring on the swagger
    add_swagger_documentation(
      Evercam::Config[:swagger][:v1]
    )

    # Dalli cache
    options = { :namespace => "app_v1", :compress => true, :expires_in => 5.minutes }
    class << self; attr_accessor :dc end
    if ENV["MEMCACHEDCLOUD_SERVERS"]
      @dc = Dalli::Client.new(ENV["MEMCACHEDCLOUD_SERVERS"].split(','), :username => ENV["MEMCACHEDCLOUD_USERNAME"], :password => ENV["MEMCACHEDCLOUD_PASSWORD"])
    else
      @dc = Dalli::Client.new('127.0.0.1:11211', options)
    end

    # AWS S3 bucket
    class << self; attr_accessor :s3_bucket end
    s3 = AWS::S3.new(:access_key_id => Evercam::Config[:amazon][:access_key_id], :secret_access_key => Evercam::Config[:amazon][:secret_access_key])
    @s3_bucket = s3.buckets['evercam-camera-assets']

    # Uncomment this to see a list of available routes on start up.
    # self.routes.each do |api|
    #   puts "#{api.route_method.ljust(10)} -> /v1#{api.route_path}"
    # end
    #Sequel::Model.db.loggers << Logger.new($stdout)

  end
end

# Disable File validation, it doesn't work
# Add Boolean validation
module Grape
  module Validations
    class CoerceValidator < SingleOptionValidator
      alias_method :validate_param_old!, :validate_param!

      def to_bool(val)
        return true if val == true || val =~ (/(true|t|yes|y|1)$/i)
        return false if val == false || val.blank? || val =~ (/(false|f|no|n|0)$/i)
        nil
      end

      def validate_param!(attr_name, params)
        unless @option.to_s == 'File' or @option.to_s == 'Float'
          if @option == 'Boolean'
            params[attr_name] = to_bool(params[attr_name])
            if params[attr_name].nil?
              raise Grape::Exceptions::Validation, param: @scope.full_name(attr_name), message_key: :coerce
            end
          else
            validate_param_old!(attr_name, params)
          end
        end

      end
    end
  end
end
