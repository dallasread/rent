module TransactionsHelper
  def format_money_cents(cents)
    return "" if cents.nil?
    "$#{format("%.2f", cents.to_i / 100.0)}"
  end

  def transaction_status_label(transaction)
    if transaction.paid?
      content_tag(:span, "Paid", class: "badge", data: { variant: "success" })
    else
      content_tag(:span, "Pending", class: "badge", data: { variant: "warning" })
    end
  end
end
