class PosReportQueries {
  static const String getDashboardData = r'''
    query GetPOSDashboardData($days: Int) {
      GetPOSDashboardData(days: $days) {
        stats {
          today_revenue
          today_transactions
          today_avg_order
          revenue_growth
          transaction_growth
        }
        daily_sales {
          date
          label
          revenue
          transactions
        }
        payment_breakdown {
          method
          label
          count
          total
          percentage
        }
        top_products {
          _id
          nama
          kode
          qty_sold
          revenue
          percentage
        }
      }
    }
  ''';
}
