# Sortable for Lustre

A pure Gleam sortable library for Lustre applications that provides full drag-and-drop functionality for reordering lists. Supports both desktop (HTML5 drag-and-drop) and mobile (touch events) interactions without external JavaScript dependencies.

## Features

- 🎯 **Pure Gleam**: No JavaScript FFI required
- 🔧 **Type Safe**: Full Gleam type safety throughout  
- 🖱️ **Desktop Support**: Full HTML5 drag-and-drop API support
- 📱 **Mobile Support**: Touch events for drag-and-drop on mobile devices
- 🎨 **Framework Agnostic**: No built-in CSS framework dependencies
- ⚙️ **Customizable**: Configure CSS classes and styling
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

fn render_item(
  item: sortable.SortableItem(String), 
  _index: Int, 
  _drag_state: sortable.DragState
) -> Element(Msg) {
  let data = sortable.item_data(item)
  html.div([
    class("bg-white p-4 rounded-lg shadow-md cursor-move hover:shadow-lg transition-shadow")
  ], [
    html.text(data)
  ])
}

pub fn view(model: Model) -> Element(Msg) {
  let sortable_items = 
    list.index_map(model.items, fn(item, index) {
      sortable.create_sortable_item("item-" <> int.to_string(index), item)
    })

  let config = sortable.SortableConfig(
    on_reorder: Reorder,
    container_id: "my-sortable-list",
    container_class: "flex flex-col gap-2 p-4",
    item_class: "sortable-item",
    dragging_class: "opacity-50",
    drag_over_class: "ring-2 ring-blue-300",
    ghost_class: "opacity-30"
  )

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
  NoDrag                                                    // No drag operation in progress
  Dragging(source_index: Int, over_index: Option(Int))     // Desktop drag in progress
  TouchDragging(source_index: Int, over_index: Option(Int)) // Mobile touch drag in progress
}
```

#### `SortableItem(a)` (opaque)
```gleam
// Opaque type - use create_sortable_item, item_data, and item_id functions
```

#### `SortableConfig(msg)`
```gleam
pub type SortableConfig(msg) {
  SortableConfig(
    on_reorder: fn(Int, Int) -> msg,     // Callback when items are reordered
    container_id: String,                // HTML id for the container
    container_class: String,             // CSS classes for the container (e.g., grid classes)
    item_class: String,                  // CSS class for individual items
    dragging_class: String,              // CSS class applied when dragging
    drag_over_class: String,             // CSS class applied when dragging over
    ghost_class: String,                 // CSS class for the drag ghost/placeholder
  )
}
```

#### `SortableMsg(msg)`
```gleam
pub type SortableMsg(msg) {
  // Desktop events
  StartDrag(Int)
  DragOver(Int)
  DragEnter(Int)
  DragLeave
  Drop(Int)
  DragEnd
  
  // Mobile events
  TouchStart(Int)
  TouchMove
  TouchEnd
  TouchEnter(Int)
  
  // User messages
  UserMsg(msg)
}
```

### Core Functions

#### `default_config`
```gleam
pub fn default_config(
  on_reorder: fn(Int, Int) -> msg,
  container_id: String,
) -> SortableConfig(msg)
```
Creates a configuration with default CSS classes.

#### `sortable_container`
```gleam
pub fn sortable_container(
  config: SortableConfig(msg),
  drag_state: DragState,
  items: List(SortableItem(a)),
  render_item: fn(SortableItem(a), Int, DragState) -> Element(msg),
) -> Element(SortableMsg(msg))
```
Creates the main sortable container element.

#### `update_sortable`
```gleam
pub fn update_sortable(
  sortable_msg: SortableMsg(msg),
  drag_state: DragState,
) -> #(DragState, Option(#(Int, Int)))
```
Updates drag state and returns reorder information.

#### `reorder_list`
```gleam
pub fn reorder_list(
  items: List(a),
  from_index: Int,
  to_index: Int,
) -> List(a)
```
Utility function to reorder a list.

### Item Functions

#### `create_sortable_item`
```gleam
pub fn create_sortable_item(id: String, data: a) -> SortableItem(a)
```
Creates a new sortable item.

#### `item_data`
```gleam
pub fn item_data(item: SortableItem(a)) -> a
```
Extracts data from a sortable item.

#### `item_id`
```gleam
pub fn item_id(item: SortableItem(a)) -> String
```
Gets the ID of a sortable item.

## CSS Classes

The library uses configurable CSS classes. Default classes include:

- `.sortable-container` - The main container element
- `.sortable-active` - Added to container during drag operations
- `.sortable-item` - Individual sortable items
- `.sortable-dragging` - Applied to the item being dragged
- `.sortable-drag-over` - Applied to the item being dragged over
- `.sortable-ghost` - Applied to drag ghost/placeholder

### Example CSS (with Tailwind)
```css
.sortable-container {
  @apply relative;
}

.sortable-active {
  @apply bg-gray-50;
}

.sortable-item {
  @apply transition-all duration-200 cursor-move;
  touch-action: manipulation;
}

.sortable-dragging {
  @apply opacity-50 scale-105 rotate-2 z-50;
}

.sortable-drag-over {
  @apply ring-2 ring-blue-300 bg-blue-50;
}

.sortable-ghost {
  @apply opacity-30;
}
```

## Advanced Usage

### Grid Layout Example
```gleam
let config = sortable.SortableConfig(
  on_reorder: ReorderImages,
  container_id: "image-grid",
  container_class: "grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4",
  item_class: "sortable-item",
  dragging_class: "opacity-50 scale-105 rotate-2 z-10",
  drag_over_class: "ring-2 ring-pink-300",
  ghost_class: "opacity-30"
)
```

### Custom Item Rendering with Drag State
```gleam
fn render_item(
  item: sortable.SortableItem(MyData), 
  index: Int, 
  drag_state: sortable.DragState
) -> Element(Msg) {
  let data = sortable.item_data(item)
  let is_dragging = case drag_state {
    sortable.Dragging(source_index, _) -> source_index == index
    sortable.TouchDragging(source_index, _) -> source_index == index
    sortable.NoDrag -> False
  }
  
  html.div([
    class("p-4 rounded-lg shadow-md cursor-move hover:shadow-lg transition-all duration-200"),
    class(case is_dragging {
      True -> "opacity-50 scale-105 rotate-2"
      False -> ""
    })
  ], [
    html.h3([class("font-semibold")], [html.text(data.title)]),
    html.p([class("text-gray-600")], [html.text(data.description)])
  ])
}
```

## Mobile Support

The library automatically handles touch events for mobile drag-and-drop:

- **Touch to start drag**: Long press or touch start to begin dragging
- **Touch move**: Drag finger to move item around
- **Touch enter**: Drag over other items to indicate drop target
- **Touch end**: Release finger to drop item

No additional configuration is needed - mobile support works out of the box.

## Testing

```bash
gleam test  # Run the comprehensive test suite
```

The test suite includes:
- List reordering functionality
- Drag state management
- Sortable item creation and access
- Touch and desktop event handling

## Browser Compatibility

- **Desktop**: All modern browsers with HTML5 drag-and-drop support
- **Mobile**: iOS Safari 13+, Chrome for Android, Firefox Mobile
- **Touch**: Full touch event support for mobile devices

## Implementation Details

### Current Features
- ✅ Full HTML5 drag-and-drop support for desktop
- ✅ Touch events for mobile drag-and-drop  
- ✅ Type-safe message handling with `SortableMsg`
- ✅ Configurable CSS classes and styling
- ✅ Grid and flexbox layout support via `container_class`
- ✅ Opaque `SortableItem` type for data encapsulation
- ✅ Comprehensive test coverage
- ✅ Framework-agnostic design
- ✅ Efficient list reordering algorithms

### Architecture
- Pure Gleam implementation with no external JavaScript dependencies
- Event-driven architecture using Lustre's message system
- Separate drag states for desktop and mobile interactions
- Configurable rendering through render functions
