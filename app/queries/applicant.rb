class Applicant
  Result = Data.define(:application)

  def self.call(applicant_id:)
    application = Applications.call.applications.find { |a| a.id == applicant_id }
    raise NotFoundError, "Applicant not found." unless application
    Result.new(application: application)
  end
end
