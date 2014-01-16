['config',
 'errors',
 'models',
 'actors',
 'mailers',
 'oauth2'
].each { |f| require_relative "../../lib/#{f}" }

['helpers/form_helpers',
 'helpers/template_helpers',
 'routes/root_router',
 'routes/connect_router',
 'routes/docs_router',
 'routes/user_router',
 'routes/signup_router',
 'routes/login_router',
 'routes/oauth2_router',
 'routes/marketplace_router'
].each { |f| require_relative "./#{f}" }

module Evercam
  class WebApp < Sinatra::Base

    use Evercam::WebRootRouter
    use Evercam::WebConnectRouter
    use Evercam::WebDocsRouter
    use Evercam::WebUserRouter
    use Evercam::WebSignupRouter
    use Evercam::WebLoginRouter
    use Evercam::WebOAuth2Router
    use Evercam::WebMarketPlaceRouter

  end
end

