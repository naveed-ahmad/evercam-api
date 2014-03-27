['config', 'models', 'errors', 'actors', 'mailers'].
  each { |f| require_relative "../../lib/#{f}" }

Dir.glob(File.expand_path('../v1/**/*.rb', __FILE__)).sort.
  each { |f| require f }

module Evercam
  class APIv1 < Grape::API

    # use JSON if accept header empty
    default_format :json

    helpers do
      def auth
        WithAuth.new(env)
      end
      include AuthorizationHelper
      include LoggingHelper
      include SessionHelper
      include ThreeScaleHelper
    end

    # disable annoying I18n message
    I18n.enforce_available_locales = false

    # configure the api
    extend GrapeJSONFormatters
    extend GrapeErrorHandlers

    # mount actual endpoints
    mount V1UserRoutes
    mount V1CameraRoutes
    mount V1SnapshotRoutes
    mount V1SnapshotJpgRoutes
    mount V1ModelRoutes
    mount V1TestRoutes
    mount V1ClientRoutes

    # bring on the swagger
    add_swagger_documentation(
      Evercam::Config[:swagger][:v1]
    )

  end
end

