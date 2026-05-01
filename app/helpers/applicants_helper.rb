module ApplicantsHelper
  def applicant_link(applicant_id, fallback: "(deleted)")
    application = Applicant.call(applicant_id: applicant_id).application
    return fallback unless application

    link_to application.name, applicant_path(application.id)
  end

  def applicant_name(applicant_id, fallback: "(deleted)")
    application = Applicant.call(applicant_id: applicant_id).application
    application ? application.name : fallback
  end

  def applicant_mobile(applicant_id)
    application = Applicant.call(applicant_id: applicant_id).application
    application&.mobile
  end
end
