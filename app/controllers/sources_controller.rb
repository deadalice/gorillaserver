class SourcesController < ApplicationController
  include SourcesHelper
  before_action :authenticate_user!
  before_action :set_source, except: %i[index new create merge]
  before_action :check_file_params, only: %i[create]

  # GET /sources
  def index
    @sources = policy_scope(Package).find(params[:package_id]).sources
  end

  # GET /sources/1
  def show
    authorize @source
  end

  # GET /sources/new
  def new
    @source = Source.new
  end

  # GET /sources/1/edit
  def edit; end

  # TODO: DirectUpload must be used here, but we still need to process the file
  # URL must be checked to be from S3 server.

  # POST /sources
  def create
    # Params removed from create() because user must fill fields only after creation
    @package = policy_scope(Package).find(file_params[:package_id])
    authorize @package, :show?, policy_class: PackagePolicy
    if source = source_exists?(current_user, file_params[:file].size, params[:checksum])
      # TODO: Link to source
      current_user.notify :flash_alert, @package,
                          I18n.t("warnings.attributes.source.file_already_exists")
    end
    @source = @package.sources.create
    respond_to do |format|
      if @source.save
        ProcessSourceJob.perform_later @source, write_tmp(file_params[:file])
        format.html do
          redirect_to [@source.package, @source],
                      notice: "Source was successfully created."
        end
        format.json do
          render :show, status: :created, location: [@source.package, @source]
        end
      else
        format.html { render :new }
        format.json do
          render json: @source.errors, status: :unprocessable_entity
        end
      end
    end
  end

  # PATCH/PUT /sources/1
  def update
    authorize @source
    respond_to do |format|
      if @source.update(source_params)
        redirect_to @source, notice: "Source was successfully updated."
      else
        format.html { render :edit }
        format.json do
          render_json_error @package.errors.full_messages,
                            status: :unprocessable_entity
        end
      end
    end
  end

  # DELETE /sources/1
  def destroy
    authorize @source
    respond_to do |format|
      if @source.destroy
        format.html do
          redirect_to sources_url, notice: "Source was successfully destroyed."
        end
        format.json { head :no_content }
      else
        format.html { render :show }
        format.json do
          render_json_error @source.errors.full_messages,
                            status: :unprocessable_entity
        end
      end
    end
  end

  # POST /package/1/sources/merge
  def merge
    authorize @source
    @package = policy_scope(Package).find(params[:package_id])
    respond_to do |format|
      format.html do
        # TODO: Normal response with render_json_error
        if @package.sources.merged?
          head :unprocessable_entity
        else
          MergeSourcesJob.perform_later policy_scope(Package).find(
            params[:package_id],
          )
          head :accepted
        end
      end
      format.json { head :method_not_allowed }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_source
    if @package = policy_scope(Package)
       .find_by(package_id: params[:package_id])
      @source = @package.sources.find(params[:id])
    end
  end

  def check_file_params
    %i[package_id file checksum].all? { |s| params[s].present? }
  end

  # Only allow a trusted parameter "white list" through.
  def source_params
    params.require(:source).permit(:description)
  end

  def file_params
    params.require(:file, :package_id)
  end
end
