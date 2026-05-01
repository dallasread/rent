class ApiTokensController < ApplicationController
  def index
    @result = ApiTokens.call
    flash_token_id = flash[:new_token_id]
    @just_created = flash_token_id ? ApiToken.call(token_id: flash_token_id).api_token : nil
  end

  def new
    @form = Data.define(:name).new(name: "")
  end

  def create
    CreateApiToken.call(actor: current_user.mobile, name: params[:name])
    just = ApiTokens.call.api_tokens.find { |t| t.created_by == current_user.mobile && t.name == params[:name].to_s.strip }
    flash[:new_token_id] = just&.id
    redirect_to api_tokens_path, notice: "Token created."
  end

  def destroy
    RevokeApiToken.call(actor: current_user.mobile, token_id: params[:id])
    redirect_to api_tokens_path, notice: "Token revoked."
  end
end
