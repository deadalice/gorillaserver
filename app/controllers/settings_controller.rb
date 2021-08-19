class SettingsController < ApplicationController
  # Settings can be used by user only within packages/endpoints
  before_action :set_endpoint
  before_action :set_setting, except: %i[index create]

  # GET /endpoints/1/settings
  def index
    # TODO: Timestamp is REQUIRED. We show here:
    # - Settings with ALL sources if created_at > timestamp
    # - ELSE Settings with current sources if updated_at > timestamp
    @settings = @endpoint.actualized_settings(params[:t]) # TODO: setting_index_params(params[:t])
    # TODO: @pagy, @settings = pagy_countless(settings, items: SETTINGS_PER_REQUEST)
  end

  # GET /endpoints/1/settings/1
  def show; end

  # POST /endpoints/1/settings
  # TODO: Return all components as index output to avoid using 2 queries
  def create
    package = Package.find(params[:package_id])
    respond_to do |format|
      if @setting = @endpoint.install(package)
        format.html do
          redirect_to [@endpoint, @setting], notice: "Package soon will be installed."
        end
        format.json { render :show, status: :accepted, location: [@endpoint, @setting] }
      else
        format.html { render :edit }
        format.json { render json: @setting.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /endpoints/1/settings/1
  # TODO: Add source_id updating to show current state
  def update
    respond_to do |format|
      if @setting.update(setting_params)
        redirect_to [@endpoint, @setting], notice: "Setting was successfully updated."
      else
        render_json_error @setting.errors.full_messages, status: :unprocessable_entity
      end
    end
  end

  # DELETE /endpoints/1/settings/1
  # No need in permission check here: endpoint is already authorized
  def destroy
    respond_to do |format|
      setting = @endpoint.settings.find_by(package_id: params[:package_id])
      if setting.destroy
        format.html do
          redirect_to settings_url, notice: "Package was successfully removed."
        end
        format.json { head :no_content }
      else
        format.html { render :edit }
        format.json do
          render_json_error @endpoint.errors.full_messages,
                            status: :unprocessable_entity
        end
      end
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_setting
    @setting = @endpoint.settings.find_by!(package_id: params[:id])
  end

  def set_endpoint
    @endpoint = current_endpoint ||
                Endpoint.find_by!(id: params[:endpoint_id], user: current_user)
  end

  # Only allow a trusted parameter "white list" through.
  #def setting_params
  #  params.permit(:id, :updates)
  #end

  def setting_index_params
    params.require(:t)
  end
end
