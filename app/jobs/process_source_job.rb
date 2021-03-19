class ProcessSourceJob < ApplicationJob
  require "timeout"

  queue_as :default

  def perform(source, file)
    Timeout::timeout(JOB_TIMEOUT) do
      # TODO: unless Clamby.safe?(file)
      #  source.block! I18n.t("jobs.block_reasons.suspicious_attachment")
      #  return false
      #end
      source.attach(file)
      File.delete(file)
    end
  rescue Timeout::Error
    source.block! "+++ TIMEOUT +++"
  end
end
