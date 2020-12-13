module Owners
  class CheckoutsController < Owners::ApplicationController
    before_action :authenticate_owner!

    def create
      render json: checkout_session
    end

    def setup_intent
      render json: client_secret
    end

    private

    def checkout_session
      Stripe::Checkout::Session.create(checkout_session_params)
    end

    def client_secret
      intent = Stripe::SetupIntent.create({ payment_method_types: ['sepa_debit'], customer: current_owner.email })
      intent['client_secret']
    end

    def checkout_session_params
      params = {
        success_url: "#{current_owner.frontend_url}/business/profile?success=true",
        cancel_url: "#{current_owner.frontend_url}/business/profile?success=false",
        payment_method_types: ['card'],
        billing_address_collection: 'required',
        client_reference_id: current_owner.id,
      }

      if current_owner.active_stripe_subscription?
        params.merge(params_for_existing_subscription)
      else
        params.merge(params_for_new_subscription)
      end
    end

    def params_for_new_subscription
      # There is not trial if the trial is blank or has already been passed, else it has to be at least two days in the future
      trial_end = current_owner.trial_ends_at? && current_owner.trial_ends_at.future? ?
        [current_owner.trial_ends_at, 50.hours.from_now].max.to_i :
        nil

      {
        mode: 'subscription',
        customer_email: current_owner.email,
        line_items: [{ price: current_owner.stripe_price_id, quantity: current_owner.companies.count }],
        subscription_data: {
          trial_end: trial_end,
          default_tax_rates: [ENV['STRIPE_TAX_RATE_ID']]
        }
      }
    end

    def params_for_existing_subscription
      {
        mode: 'setup',
        customer: current_owner.stripe_customer_id,
        setup_intent_data: {
          metadata: {
            subscription_id: current_owner.stripe_subscription_id
          }
        }
      }
    end
  end
end
