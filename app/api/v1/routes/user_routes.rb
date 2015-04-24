require_relative '../presenters/user_presenter'
require_relative '../presenters/camera_presenter'

module Evercam
  class V1UserRoutes < Grape::API

    include WebErrors

    namespace :testusername do
      desc 'Internal endpoint only, keep hidden', {
        :hidden => true
      }
      params do
        requires :username, type: String
      end
      get do
        user = ::User.by_login(params[:username])
        raise BadRequestError, 'Username already in use' if user

        {:message => 'OK'}
      end
    end

    resource :users do
      #-------------------------------------------------------------------------
      # POST /v1/users
      #-------------------------------------------------------------------------
      desc 'Starts the new user signup process', {
        entity: Evercam::Presenters::User
      }
      params do
        requires :firstname, type: String, desc: "First Name"
        requires :lastname, type: String, desc: "Last Name"
        requires :username, type: String, desc: "Username"
        requires :email, type: String, desc: "Email"
        requires :password, type: String, desc: "Password"
        optional :country, type: String, desc: "Country"
        optional :share_request_key, type: String, desc: "The key for a camera share request to be processed during the sign up"
      end
      post do
        if params[:country]
          params[:country].downcase!
        end
        params[:username].downcase!
        outcome = Actors::UserSignup.run(params)
        if !outcome.success?
          raise_error(400, "invalid_parameters",
                      "Invalid parameters specified to request.",
                      *(outcome.errors.keys))
        end

        user = outcome.result
        if params[:share_request_key]
          outcome = Actors::ShareCreateForRequest.run({key: params[:share_request_key],
                                                       email: params[:email]})
          if !outcome.success?
            raise OutcomeError "Failed to create camera share for camera share "\
                               "request key '#{params[:share_request_key]}'."
          end
        end

        share_requests = CameraShareRequest.where(email: user.email).all
        unless share_requests.blank?
          share_requests.each do |share_request|
            Actors::ShareCreateForRequest.run({key: share_request.key, email: user.email})
          end
        end

        present Array(user), with: Presenters::User
      end
    end

    resource :users do
      helpers do
        include AuthorizationHelper
        include LoggingHelper
        include SessionHelper
      end

      #-------------------------------------------------------------------------
      # GET /v1/users/:id
      #-------------------------------------------------------------------------
      desc 'Returns available information for the user'
      get '/:id', requirements: { id: /[^\/]*/ } do
        authorize!
        # I can't find cleaner way to do it with current grape version
        params[:id] = params[:id][0..-6] if params[:id].end_with?('.json')
        params[:id] = params[:id][0..-5] if params[:id].end_with?('.xml')
        params[:id].downcase!
        target = ::User.by_login(params[:id])
        raise NotFoundError, 'user does not exist' unless target

        rights = requester_rights_for(target, AccessRight::USER)
        raise AuthorizationError.new if !rights.allow?(AccessRight::VIEW)

        present Array(target), with: Presenters::User
      end

      #-------------------------------------------------------------------------
      # PATCH /v1/users/:id
      #-------------------------------------------------------------------------
      desc 'Updates full or partial data on your existing user account', {
        entity: Evercam::Presenters::User
      }
      params do
        requires :id, type: String, desc: "Username"
        optional :firstname, type: String, desc: "First Name"
        optional :lastname, type: String, desc: "Last Name"
        optional :username, type: String, desc: "Username"
        optional :country, type: String, desc: "Country"
        optional :email, type: String, desc: "Email"
        optional :billing_id, type: String, desc: "Billing ID"
      end
      patch '/:id', requirements: { id: /[^\/]*/ } do
        authorize!
        # I can't find cleaner way to do it with current grape version
        params[:id] = params[:id][0..-6] if params[:id].end_with?('.json')
        params[:id] = params[:id][0..-5] if params[:id].end_with?('.xml')
        params[:id].downcase!
        target = ::User.by_login(params[:id])
        raise NotFoundError, 'user does not exist' unless target

        rights = requester_rights_for(target, AccessRight::USER)
        raise AuthorizationError.new if !rights.allow?(AccessRight::EDIT)

        outcome = Actors::UserUpdate.run(params)
        raise OutcomeError, outcome.to_json unless outcome.success?

        present Array(target.reload), with: Presenters::User
      end

      #-------------------------------------------------------------------------
      # DELETE /v1/users/:id
      #-------------------------------------------------------------------------
      desc 'Delete your account, any cameras you own and all stored media', {
        entity: Evercam::Presenters::User
      }
      delete '/:id', requirements: { id: /[^\/]*/ } do
        authorize!
        # I can't find cleaner way to do it with current grape version
        params[:id] = params[:id][0..-6] if params[:id].end_with?('.json')
        params[:id] = params[:id][0..-5] if params[:id].end_with?('.xml')
        params[:id].downcase!
        target = ::User.by_login(params[:id])
        raise NotFoundError, 'user does not exist' unless target

        rights = requester_rights_for(target, AccessRight::USER)
        raise AuthorizationError.new if !rights.allow?(AccessRight::DELETE)

        target.destroy
        {}
      end

      #-------------------------------------------------------------------------
      # GET /v1/users/:id/credentials
      #-------------------------------------------------------------------------
      desc "Fetch API credentials for an authenticated user."
      params do
        requires :id, type: String, desc: "User name or email for the user to fetch credentials for."
        requires :password, type: String, desc: "Password for the user to fetch credentials for."
      end
      get '/:id/credentials', requirements: { id: /[^\/]*/ } do
        params[:id].downcase!
        user = User.by_login(params[:id])
        raise NotFoundError.new("No user with an id of #{params[:id]} exists.") if user.nil?

        if user.password != params[:password]
          raise AuthenticationError.new("Invalid user name and/or password.")
        end

        {api_id: user.api_id, api_key: user.api_key}
      end
    end
  end
end
