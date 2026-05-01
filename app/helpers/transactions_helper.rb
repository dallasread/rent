module TransactionsHelper
  def format_money_cents(cents)
    return "" if cents.nil?
    "$#{format("%.2f", cents.to_i / 100.0)}"
  end

  def transaction_status_label(transaction)
    transaction.paid? ? "Paid" : "Pending"
  end
end
