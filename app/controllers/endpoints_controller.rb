class EndpointsController < ApplicationController
  before_action :authenticate_user!, only: %i[index destroy]
  before_action :set_endpoint, except: %i[index create]

  # GET /endpoints
  # GET /endpoints.json
  def index
    # TODO: Add group
    @pagy, @endpoints = pagy_countless(
      current_user.endpoints,
      items: params[:items],
    )
  end

  # GET /endpoints/1
  # GET /endpoints/1.json
  def show; end

  # POST /endpoints.json
  def create
    respond_to do |format|
      # We allowing to register anonymous endpoints without any limit
      format.html { head :method_not_allowed }
      format.json do
        @endpoint = Endpoint.find_by(id: endpoint_params[:id], user: current_user) ||
                    Endpoint.new(name: endpoint_params[:name], user: current_user)
        @endpoint.update({
          remote_ip: request.remote_ip, # TODO: Additional security by IP compare
          locale: current_user&.locale || I18n.default_locale.to_s,
        })
        sign_in_endpoint(@endpoint)
        render :show, status: :created, location: @endpoint
      end
    end
  end

  # PATCH/PUT /endpoint
  # PATCH/PUT /endpoint.json
  def update
    respond_to do |format|
      if @endpoint.update(endpoint_params)
        format.html do
          redirect_to @endpoint, notice: "Endpoint was successfully updated."
        end
        format.json { render :show, status: :ok, location: @endpoint }
      else
        format.html { render :edit }
        format.json do
          render_json_error @endpoint.errors.full_messages, status: :unprocessable_entity
        end
      end
    end
  end

  # DELETE /endpoints/1
  # DELETE /endpoints/1.json
  def destroy
    respond_to do |format|
      if @endpoint.destroy
        format.html do
          redirect_to endpoints_url,
                      notice: "Endpoint was successfully destroyed."
        end
        format.json { head :no_content }
      else
        format.html { render :edit }
        format.json do
          render_json_error @endpoint.errors.full_messages, status: :unprocessable_entity
        end
      end
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_endpoint
    @endpoint = current_endpoint || current_user&.endpoints&.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def endpoint_params
    params.require(:endpoint).permit(:id, :name, :package)
  end
end
