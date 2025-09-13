import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None}
import lustre
import lustre/attribute.{class}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import sortable

pub type Model {
  Model(items: List(String), drag_state: sortable.DragState)
}

pub type Msg {
  SortableMsg(sortable.SortableMsg(Msg))
  NoOp
}

pub fn init(_flags) -> #(Model, Effect(Msg)) {
  #(
    Model(
      items: ["🎯 Item 1", "🚀 Item 2", "✨ Item 3", "🎨 Item 4", "🔥 Item 5"],
      drag_state: sortable.NoDrag,
    ),
    effect.none(),
  )
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    SortableMsg(sortable_msg) -> {
      let #(new_drag_state, maybe_reorder) =
        sortable.update_sortable(sortable_msg, model.drag_state)

      case maybe_reorder {
        None -> #(Model(..model, drag_state: new_drag_state), effect.none())
        option.Some(#(from_index, to_index)) -> {
          let new_items =
            sortable.reorder_list(model.items, from_index, to_index)
          #(Model(items: new_items, drag_state: new_drag_state), effect.none())
        }
      }
    }
    NoOp -> #(model, effect.none())
  }
}

fn render_item(
  item: sortable.SortableItem(String),
  index: Int,
  drag_state: sortable.DragState,
) -> Element(Msg) {
  let is_dragging = case drag_state {
    sortable.Dragging(source_index, _) -> source_index == index
    sortable.NoDrag -> False
  }

  let is_drag_over = case drag_state {
    sortable.Dragging(source_index, option.Some(over_index)) ->
      over_index == index && source_index != index
    _ -> False
  }

  let base_classes = "p-4 rounded-lg shadow-md border-2 transition-all duration-200 cursor-grab"
  let drag_classes = case is_dragging {
    True -> " opacity-50 scale-105 rotate-2 border-blue-500 bg-blue-50 z-10"
    False -> case is_drag_over {
      True -> " border-green-400 bg-green-50 scale-105"
      False -> " border-gray-200 bg-white hover:border-blue-300 hover:shadow-lg"
    }
  }

  html.div([class(base_classes <> drag_classes)], [
    html.div([class("flex items-center justify-between")], [
      html.span([class("font-medium text-gray-800 text-lg")], [
        element.text(sortable.get_item_data(item)),
      ]),
      html.div([class("flex items-center space-x-2")], [
        html.span([class("text-sm text-gray-500")], [
          element.text("Index: " <> int.to_string(index)),
        ]),
        case is_dragging {
          True -> html.span([class("text-xs text-blue-600 font-semibold animate-pulse")], [
            element.text("✋ Dragging..."),
          ])
          False -> case is_drag_over {
            True -> html.span([class("text-xs text-green-600 font-semibold animate-bounce")], [
              element.text("📍 Drop here!"),
            ])
            False -> html.span([class("text-xs text-gray-400")], [
              element.text("🎯 Drag me!"),
            ])
          }
        },
      ]),
    ]),
  ])
}

pub fn view(model: Model) -> Element(Msg) {
  let sortable_items =
    list.index_map(model.items, fn(item, index) {
      sortable.create_sortable_item("item-" <> int.to_string(index), item)
    })

  let config =
    sortable.default_config(
      fn(_from, _to) { SortableMsg(sortable.UserMsg(NoOp)) },
      "sortable-container",
    )

  let drag_status = case model.drag_state {
    sortable.NoDrag -> "🎯 Ready to drag"
    sortable.Dragging(source, target) ->
      "🎯 Dragging item " <> int.to_string(source) <> case target {
        option.Some(t) -> " over item " <> int.to_string(t)
        option.None -> "..."
      }
  }

  html.div([class("min-h-screen bg-gradient-to-br from-purple-50 to-pink-50 p-8")], [
    html.div([class("max-w-md mx-auto")], [
      html.div([class("text-center mb-8")], [
        html.h1([class("text-3xl font-bold text-gray-900 mb-2")], [
          element.text("🚀 Drag & Drop Demo"),
        ]),
        html.p([class("text-gray-600 mb-4")], [
          element.text("Drag items to reorder them"),
        ]),
        html.div([
          class("p-3 bg-white rounded-lg shadow-sm border border-gray-200"),
        ], [
          html.p([class("text-sm font-medium text-gray-700")], [
            element.text("Status: " <> drag_status),
          ]),
        ]),
      ]),
      
      html.div([class("space-y-3 mb-8")], [
        element.map(
          sortable.sortable_container(
            config,
            model.drag_state,
            sortable_items,
            render_item,
          ),
          SortableMsg,
        ),
      ]),
      
      html.div([class("bg-white rounded-lg p-6 shadow-sm border border-gray-200")], [
        html.h3([class("font-semibold text-gray-800 mb-3 flex items-center")], [
          element.text("📋 Current Order"),
        ]),
        html.div([class("space-y-2")], list.index_map(model.items, fn(item, index) {
          html.div([
            class("flex items-center justify-between p-2 rounded bg-gray-50"),
          ], [
            html.span([class("text-sm text-gray-600")], [
              element.text(int.to_string(index + 1) <> "."),
            ]),
            html.span([class("text-sm font-medium text-gray-800")], [
              element.text(item),
            ]),
          ])
        })),
      ]),
      
      html.div([class("mt-6 text-center")], [
        html.p([class("text-xs text-gray-500")], [
          element.text("✨ Pure Gleam drag & drop with Lustre"),
        ]),
      ]),
    ]),
  ])
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  io.println("🚀 Sortable drag & drop example started!")
}
