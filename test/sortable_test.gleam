import gleam/option
import gleeunit
import sortable

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn reorder_list_test() {
  let items = ["A", "B", "C", "D", "E"]

  // Test moving item from position 1 to position 3
  let result1 = sortable.reorder_list(items, 1, 3)
  let assert ["A", "C", "D", "B", "E"] = result1

  // Test moving item from position 3 to position 1  
  let result2 = sortable.reorder_list(items, 3, 1)
  let assert ["A", "D", "B", "C", "E"] = result2

  // Test no change when indices are the same
  let result3 = sortable.reorder_list(items, 2, 2)
  assert items == result3

  // Test invalid indices (should return original list)
  let result4 = sortable.reorder_list(items, 5, 1)
  assert items == result4

  let result5 = sortable.reorder_list(items, 1, 5)
  assert items == result5
}

pub fn sortable_item_test() {
  let item = sortable.create_sortable_item("test-id", "Test Data")

  let assert "test-id" = sortable.get_item_id(item)
  let assert "Test Data" = sortable.get_item_data(item)
}

pub fn update_sortable_test() {
  let initial_state = sortable.NoDrag

  // Test starting drag
  let #(new_state, maybe_reorder) =
    sortable.update_sortable(sortable.StartDrag(1), initial_state)
  let assert sortable.Dragging(1, option.None) = new_state
  let assert option.None = maybe_reorder

  // Test drag enter
  let #(new_state2, maybe_reorder2) =
    sortable.update_sortable(sortable.DragEnter(3), new_state)
  let assert sortable.Dragging(1, option.Some(3)) = new_state2
  let assert option.None = maybe_reorder2

  // Test drop
  let #(final_state, maybe_reorder3) =
    sortable.update_sortable(sortable.Drop(3), new_state2)
  let assert sortable.NoDrag = final_state
  let assert option.Some(#(1, 3)) = maybe_reorder3
}
