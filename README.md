# Sortable for Lustre

A pure Gleam sortable library for Lustre applications. This library provides drag-and-drop style functionality for reordering lists in Lustre SPAs without external JavaScript dependencies.

## Features

- 🎯 **Pure Gleam**: No JavaScript FFI required
- 🔧 **Type Safe**: Full Gleam type safety throughout
- 🎨 **Customizable**: Configure CSS classes and styling
- 📱 **Responsive**: Works on desktop and mobile
- 🚀 **Efficient**: Optimized list reordering algorithms
- ✅ **Tested**: Comprehensive test suite included

## Installation

Add `sortable` to your Gleam project dependencies:

```toml
[dependencies]
sortable = { path = "../path/to/sortable" }
lustre = ">= 5.1.0 and < 6.0.0"
```

## Quick Start

```gleam
import sortable
import lustre/element.{type Element}
import lustre/element/html

pub type Model {
  Model(
    items: List(String),
    drag_state: sortable.DragState,
  )
}

pub type Msg {
  SortableMsg(sortable.SortableMsg(Msg))
  Reorder(Int, Int)
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    SortableMsg(sortable_msg) -> {
      let #(new_drag_state, maybe_reorder) = 
        sortable.update_sortable(sortable_msg, model.drag_state)
      
      case maybe_reorder {
        None -> #(Model(..model, drag_state: new_drag_state), effect.none())
        Some(#(from_index, to_index)) -> {
          let new_items = sortable.reorder_list(model.items, from_index, to_index)
          #(Model(items: new_items, drag_state: new_drag_state), effect.none())
        }
      }
    }
    Reorder(from, to) -> {
      let new_items = sortable.reorder_list(model.items, from, to)
      #(Model(..model, items: new_items), effect.none())
    }
  }
}

pub fn view(model: Model) -> Element(Msg) {
  let sortable_items = 
    list.index_map(model.items, fn(item, index) {
      sortable.create_sortable_item("item-" <> int.to_string(index), item)
    })

  let config = sortable.default_config(Reorder, "my-sortable-list")

  html.div([], [
    element.map(
      sortable.sortable_container(config, model.drag_state, sortable_items, render_item),
      SortableMsg
    )
  ])
}
```

## API Reference

### Types

#### `DragState`
```gleam
pub type DragState {
  NoDrag
  Dragging(source_index: Int, over_index: Option(Int))
}
```

#### `SortableItem(a)`
```gleam
pub type SortableItem(a) {
  SortableItem(id: String, data: a)
}
```

#### `SortableConfig(msg)`
```gleam
pub type SortableConfig(msg) {
  SortableConfig(
    on_reorder: fn(Int, Int) -> msg,
    container_id: String,
    item_class: String,
    dragging_class: String,
    drag_over_class: String,
    ghost_class: String,
  )
}
```

### Functions

#### `default_config`
```gleam
pub fn default_config(
  on_reorder: fn(Int, Int) -> msg,
  container_id: String,
) -> SortableConfig(msg)
```

#### `sortable_container`
```gleam
pub fn sortable_container(
  config: SortableConfig(msg),
  drag_state: DragState,
  items: List(SortableItem(a)),
  render_item: fn(SortableItem(a), Int, DragState) -> Element(msg),
) -> Element(SortableMsg(msg))
```

#### `reorder_list`
```gleam
pub fn reorder_list(
  items: List(a),
  from_index: Int,
  to_index: Int,
) -> List(a)
```

## CSS Classes

Style these CSS classes in your application:

- `.sortable-container` - The main container
- `.sortable-active` - Container during active operations  
- `.sortable-item` - Individual sortable items
- `.sortable-dragging` - Item being dragged
- `.sortable-drag-over` - Item being dragged over

## Running the Example

```bash
gleam build
gleam run -m example
# Open index.html in browser
```

## Development

```bash
gleam run   # Run the project
gleam test  # Run the tests
```

## Current Implementation

This provides a foundation for sortable lists with:
- ✅ Core sortable container and item components  
- ✅ List reordering utilities
- ✅ Type-safe message handling
- ✅ Configurable styling
- ✅ Comprehensive tests

The current implementation uses click-based interaction. Full HTML5 drag-and-drop can be added by extending the event handlers.
