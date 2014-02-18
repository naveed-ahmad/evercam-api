require 'rack_helper'
require_app 'web/helpers'

describe 'WebApp routes/connect_router' do

  let(:app) { Evercam::FormHelpers }

  describe 'GET /connect' do
    it 'renders with an OK status' do
      get '/connect'
      expect(last_response.status).to eq(200)
    end
  end

end