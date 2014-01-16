require 'rack_helper'
require_app 'dns/dyndns'

module Evercam
  describe DynDNS, :focus => true do

    let(:app) { Evercam::DynDNS }

    let(:camera0) { create(:stream, name: 'qwerty') }

    let!(:user0) { create(:user, username: 'aaaa', password: 'bbbb') }

    let(:env) { { 'HTTP_AUTHORIZATION' => "Basic #{Base64.encode64('aaaa:bbbb')}" } }

    describe 'GET /update' do

      context 'when no credentials are supplied' do
        it 'returns an UNAUTHORIZED status' do
          response = get("/update?hostname=#{camera0.name}")
          expect(response.status).to eq(401)
        end
      end

      context 'when hostname does not exist' do
        it 'returns a NOT FOUND status' do
          response = get('/update?hostname=xxxx', {}, env)
          expect(response.status).to eq(404)
        end
      end

      context 'when hostname does exist' do

        context 'when the credentials are incorrect' do
          it 'returns an FORBIDDEN status' do
            response = get("/update?hostname=#{camera0.name}", {}, env)
            expect(response.status).to eq(403)
          end
        end

        context 'when the credentials are correct' do

          before(:each) do
            camera0.update(owner: user0)
          end

          it 'returns an OK status' do
            response = get("/update?hostname=#{camera0.name}&myip=192.168.1.1", {}, env)
            expect(response.status).to eq(200)
          end

          context 'where the ip has not changed' do
            it 'does not updated the database' do
              camera0.update(ip_address: '192.168.1.1')
              Stream.any_instance.expects(:update).never
              get("/update?hostname=#{camera0.name}&myip=192.168.1.1", {}, env)
            end
          end

          context 'where the ip has changed' do
            it 'updates the database' do
              get("/update?hostname=#{camera0.name}&myip=192.168.1.1", {}, env)
              expect(camera0.reload.ip_address).to eq('192.168.1.1')
            end
          end

        end

      end

    end

  end
end

