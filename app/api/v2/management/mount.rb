# encoding: UTF-8
# frozen_string_literal: true

module API
  module V2
    module Management
      class Mount < Grape::API
        PREFIX = '/management'

        format         :json
        content_type   :json, 'application/json'
        default_format :json

        do_not_route_options!

        helpers Management::Helpers

        rescue_from Management::Exceptions::Base do |e|
          Management::Mount.logger.error { e.inspect }
          error!(e.message, e.status, e.headers)
        end

        rescue_from Grape::Exceptions::ValidationErrors do |e|
          Management::Mount.logger.error { e.inspect }
          Management::Mount.logger.debug { e.full_messages }
          error!(e.message, 422)
        end

        rescue_from ActiveRecord::RecordNotFound do |e|
          Management::Mount.logger.error { e.inspect }
          error!('Couldn\'t find record.', 404)
        end

        logger Rails.logger.dup
        logger.formatter = GrapeLogging::Formatters::Rails.new
        use GrapeLogging::Middleware::RequestLogger,
            logger:    logger,
            log_level: :info,
            include:   [GrapeLogging::Loggers::Response.new,
                        GrapeLogging::Loggers::FilterParameters.new,
                        GrapeLogging::Loggers::ClientEnv.new,
                        GrapeLogging::Loggers::RequestHeaders.new]

        use Management::JWTAuthenticationMiddleware

        mount Management::Accounts
        mount Management::Deposits
        mount Management::Withdraws
        mount Management::Tools
        mount Management::Operations
        mount Management::Transfers

        # The documentation is accessible at http://localhost:3000/swagger?url=/api/v2/management/swagger
        # Add swagger documentation for Peatio Management API
        add_swagger_documentation base_path: File.join(API::Mount::PREFIX, API::V2::Mount::API_VERSION, PREFIX),
                                  mount_path:  '/swagger',
                                  api_version: API::V2::Mount::API_VERSION,
                                  doc_version: Peatio::Application::VERSION,
                                  info: {
                                    title:          "Peatio Management API #{API::V2::Mount::API_VERSION}",
                                    description:    'Management API is server-to-server API with high privileges.',
                                    contact_name:   'peatio.tech',
                                    contact_email:  'hello@peatio.tech',
                                    contact_url:    'https://www.peatio.tech',
                                    licence:        'MIT',
                                    license_url:    'https://github.com/rubykube/peatio/blob/master/LICENSE.md'
                                  },
                                  models: [
                                    API::V2::Management::Entities::Balance,
                                    API::V2::Management::Entities::Deposit,
                                    API::V2::Management::Entities::Withdraw,
                                    API::V2::Management::Entities::Operation
                                  ]
      end
    end
  end
end
