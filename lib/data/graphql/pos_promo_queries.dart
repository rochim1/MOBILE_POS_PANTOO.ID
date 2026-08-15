class PosPromoQueries {
  static const String getAll = r'''
    query GetAllDiscounts($filter: DiscountFilterInput, $sorting: DiscountSortingInput, $pagination: PaginationInput) {
      getAllDiscounts(filter: $filter, sorting: $sorting, pagination: $pagination) {
        discounts {
          _id
          code
          name
          description
          discount_type
          value_type
          discount_value
          max_discount_amount
          usage_limit
          usage_per_user
          current_usage_count
          start_date
          end_date
          min_purchase_amount
          allowed_channels
          allowed_segments
          is_active
          is_valid
          remaining_usage
          usage_percentage
          createdAt
          updatedAt
        }
        info_page {
          count
        }
      }
    }
  ''';

  static const String getOne = r'''
    query GetDiscountById($id: ID!) {
      getDiscountById(id: $id) {
        _id
        code
        name
        description
        discount_type
        value_type
        discount_value
        max_discount_amount
        usage_limit
        usage_per_user
        current_usage_count
        start_date
        end_date
        min_purchase_amount
        allowed_channels
        allowed_segments
        is_active
        is_valid
        remaining_usage
        usage_percentage
        createdAt
        updatedAt
      }
    }
  ''';

  static const String create = r'''
    mutation CreateDiscount($input: CreateDiscountInput!) {
      createDiscount(input: $input) {
        success message
        discount { _id code name discount_type value_type discount_value is_active }
      }
    }
  ''';

  static const String update = r'''
    mutation UpdateDiscount($id: ID!, $input: UpdateDiscountInput!) {
      updateDiscount(id: $id, input: $input) {
        success message
        discount { _id code name discount_type value_type discount_value is_active }
      }
    }
  ''';

  static const String delete = r'''
    mutation DeleteDiscount($id: ID!) {
      deleteDiscount(id: $id) {
        success message
        discount { _id code }
      }
    }
  ''';

  static const String toggleStatus = r'''
    mutation ToggleDiscountStatus($id: ID!) {
      toggleDiscountStatus(id: $id) {
        success message
        discount { _id code name is_active }
      }
    }
  ''';
}
