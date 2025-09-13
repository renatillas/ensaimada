import gleam/bool
import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre/attribute.{attribute, class, id}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub type SortableConfig(msg) {
  SortableConfig(
    on_reorder: fn(Int, Int) -> msg,
    container_id: String,
    container_class: String,
    item_class: String,
    dragging_class: String,
    drag_over_class: String,
    ghost_class: String,
  )
}

pub type DragState {
  NoDrag
  Dragging(source_index: Int, over_index: Option(Int))
  TouchDragging(source_index: Int, over_index: Option(Int))
}

pub opaque type SortableItem(a) {
  SortableItem(id: String, data: a)
}

pub fn default_config(
  on_reorder: fn(Int, Int) -> msg,
  container_id: String,
) -> SortableConfig(msg) {
  SortableConfig(
    on_reorder: on_reorder,
    container_id: container_id,
    container_class: "sortable-container",
    item_class: "sortable-item",
    dragging_class: "sortable-dragging",
    drag_over_class: "sortable-drag-over",
    ghost_class: "sortable-ghost",
  )
}

pub fn sortable_container(
  config: SortableConfig(msg),
  drag_state: DragState,
  items: List(SortableItem(a)),
  render_item: fn(SortableItem(a), Int, DragState) -> Element(msg),
) -> Element(SortableMsg(msg)) {
  let container_classes = case drag_state {
    NoDrag -> config.container_class
    Dragging(_, _) -> config.container_class <> " sortable-active"
    TouchDragging(_, _) -> config.container_class <> " sortable-active"
  }

  html.div(
    [
      id(config.container_id),
      class(container_classes),
      attribute.style("user-select", "none"),
      attribute.style("-webkit-user-select", "none"),
      attribute.style("-moz-user-select", "none"),
      attribute.style("-ms-user-select", "none"),
    ],
    list.index_map(items, fn(item, index) {
      render_sortable_item(config, drag_state, item, index, render_item)
    }),
  )
}

fn render_sortable_item(
  config: SortableConfig(msg),
  drag_state: DragState,
  item: SortableItem(a),
  index: Int,
  render_item: fn(SortableItem(a), Int, DragState) -> Element(msg),
) -> Element(SortableMsg(msg)) {
  let is_dragging = case drag_state {
    Dragging(source_index, _) -> source_index == index
    TouchDragging(source_index, _) -> source_index == index
    NoDrag -> False
  }

  let is_drag_over = case drag_state {
    Dragging(source_index, Some(over_index)) ->
      over_index == index && source_index != index
    TouchDragging(source_index, Some(over_index)) ->
      over_index == index && source_index != index
    _ -> False
  }

  let item_classes =
    config.item_class
    <> bool.lazy_guard(is_dragging, fn() { " " <> config.dragging_class }, fn() {
      ""
    })
    <> bool.lazy_guard(
      is_drag_over,
      fn() { " " <> config.drag_over_class },
      fn() { "" },
    )

  html.div(
    [
      class(item_classes),
      attribute("draggable", "true"),
      attribute("data-index", int.to_string(index)),
      attribute("data-item-id", item.id),
      attribute.style("cursor", case is_dragging {
        True -> "grabbing"
        False -> "grab"
      }),
      attribute.style("touch-action", "manipulation"),
      attribute.style("-webkit-user-select", "none"),
      attribute.style("user-select", "none"),
      attribute.style("opacity", case is_dragging {
        True -> "0.5"
        False -> "1"
      }),
      attribute.style("transform", case is_dragging {
        True -> "scale(1.05) rotate(3deg)"
        False -> "scale(1)"
      }),
      attribute.style("transition", "all 0.2s ease"),
      attribute.style("z-index", case is_dragging {
        True -> "1000"
        False -> "1"
      }),
      // HTML5 Drag and Drop events
      event.on("dragstart", drag_start_decoder(index)),
      event.on("dragover", drag_over_decoder()) |> event.prevent_default,
      event.on("dragenter", drag_enter_decoder(index)) |> event.prevent_default,
      event.on("dragleave", drag_leave_decoder()) |> event.prevent_default,
      event.on("drop", drop_decoder(index)) |> event.prevent_default,
      event.on("dragend", drag_end_decoder()) |> event.prevent_default,
      // Touch events for mobile support
      event.on("touchstart", touch_start_decoder(index)),
      event.on("touchmove", touch_move_decoder()) |> event.prevent_default,
      event.on("touchend", touch_end_decoder()),
      event.on("touchenter", touch_enter_decoder(index)),
    ],
    [element.map(render_item(item, index, drag_state), UserMsg)],
  )
}

pub type SortableMsg(msg) {
  StartDrag(Int)
  DragOver(Int)
  DragEnter(Int)
  DragLeave
  Drop(Int)
  DragEnd
  TouchStart(Int)
  TouchMove
  TouchEnd
  TouchEnter(Int)
  UserMsg(msg)
}

pub fn reorder_list(items: List(a), from_index: Int, to_index: Int) -> List(a) {
  case from_index == to_index {
    True -> items
    False -> {
      let item_count = list.length(items)
      case
        from_index >= 0
        && from_index < item_count
        && to_index >= 0
        && to_index < item_count
      {
        True -> {
          case list.split(items, from_index) {
            #(before_from, after_from) -> {
              case after_from {
                [moving_item, ..rest_after_from] -> {
                  let without_moving_item =
                    list.append(before_from, rest_after_from)
                  case list.split(without_moving_item, to_index) {
                    #(before_to, after_to) ->
                      list.append(before_to, [moving_item, ..after_to])
                  }
                }
                [] -> items
              }
            }
          }
        }
        False -> items
      }
    }
  }
}

pub fn create_sortable_item(id: String, data: a) -> SortableItem(a) {
  SortableItem(id: id, data: data)
}

pub fn get_item_data(item: SortableItem(a)) -> a {
  item.data
}

pub fn get_item_id(item: SortableItem(a)) -> String {
  item.id
}

// Event decoders for HTML5 drag and drop
fn drag_start_decoder(index: Int) -> decode.Decoder(SortableMsg(msg)) {
  decode.success(StartDrag(index))
}

fn drag_over_decoder() -> decode.Decoder(SortableMsg(msg)) {
  decode.success(DragOver(-1))
}

fn drag_enter_decoder(index: Int) -> decode.Decoder(SortableMsg(msg)) {
  decode.success(DragEnter(index))
}

fn drag_leave_decoder() -> decode.Decoder(SortableMsg(msg)) {
  decode.success(DragLeave)
}

fn drop_decoder(index: Int) -> decode.Decoder(SortableMsg(msg)) {
  decode.success(Drop(index))
}

fn drag_end_decoder() -> decode.Decoder(SortableMsg(msg)) {
  decode.success(DragEnd)
}

// Touch event decoders for mobile support
fn touch_start_decoder(index: Int) -> decode.Decoder(SortableMsg(msg)) {
  decode.success(TouchStart(index))
}

fn touch_move_decoder() -> decode.Decoder(SortableMsg(msg)) {
  decode.success(TouchMove)
}

fn touch_end_decoder() -> decode.Decoder(SortableMsg(msg)) {
  decode.success(TouchEnd)
}

fn touch_enter_decoder(index: Int) -> decode.Decoder(SortableMsg(msg)) {
  decode.success(TouchEnter(index))
}

pub fn update_sortable(
  sortable_msg: SortableMsg(msg),
  drag_state: DragState,
) -> #(DragState, Option(#(Int, Int))) {
  case sortable_msg {
    StartDrag(index) -> {
      #(Dragging(index, None), None)
    }
    DragEnter(index) ->
      case drag_state {
        Dragging(source_index, _) -> #(
          Dragging(source_index, Some(index)),
          None,
        )
        NoDrag -> #(drag_state, None)
        TouchDragging(source_index, _) -> #(
          TouchDragging(source_index, Some(index)),
          None,
        )
      }
    DragLeave -> #(drag_state, None)
    Drop(target_index) ->
      case drag_state {
        Dragging(source_index, _) -> {
          #(NoDrag, Some(#(source_index, target_index)))
        }
        NoDrag -> #(drag_state, None)
        TouchDragging(source_index, _) -> {
          #(NoDrag, Some(#(source_index, target_index)))
        }
      }
    DragEnd ->
      case drag_state {
        Dragging(source_index, Some(target_index)) -> #(
          NoDrag,
          Some(#(source_index, target_index)),
        )
        _ -> #(NoDrag, None)
      }
    DragOver(_) -> #(drag_state, None)
    TouchStart(index) -> #(TouchDragging(index, None), None)
    TouchMove ->
      case drag_state {
        TouchDragging(source_index, _) -> {
          // Calculate which item we're over based on touch position
          // For now, we'll use a simplified approach
          #(TouchDragging(source_index, None), None)
        }
        _ -> #(drag_state, None)
      }
    TouchEnd ->
      case drag_state {
        TouchDragging(source_index, Some(target_index)) -> #(
          NoDrag,
          Some(#(source_index, target_index)),
        )
        TouchDragging(_, None) -> #(NoDrag, None)
        _ -> #(NoDrag, None)
      }
    TouchEnter(index) ->
      case drag_state {
        TouchDragging(source_index, _) -> #(
          TouchDragging(source_index, Some(index)),
          None,
        )
        _ -> #(drag_state, None)
      }
    UserMsg(_) -> #(drag_state, None)
  }
}
