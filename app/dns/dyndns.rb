require_relative '../api/v1/helpers/with_auth'

module Evercam
  class DynDNS < Sinatra::Base

    include WebErrors

    helpers do
      def auth
        WithAuth.new(env)
      end
    end

    get '/update' do
      return [401, {}, 'no authentication provided'] unless auth.user

      camera = ::Stream.by_name(params[:hostname])
      return [404, {}, 'camera does not exist'] unless camera

      return [403, {}, 'unauthorized camera owner'] unless camera.owner == auth.user

      camera.update(ip_address: params[:myip]) unless camera.ip_address == params[:myip]
    end

  end
end

