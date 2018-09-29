module Ui.DragDrop.State exposing (StateData, DropTarget(..))

{-| This type represents a drop target -- something that a dragged element can be dropped upon.
This can be one of several values:

  - NoDropTarget: the dragged object (if any) is not hovering over a droppable element.
  - SpecificDropTarget: the dragged object is hovering over an specific element of an equivalent type (e.g. reordering a list).

In the future, this will also support general drop targets (for instance, a trash bin or something
not like an item in a list).

-}


type
    DropTarget a
    -- Don't show any drop targetting
    = NoDropTarget
      -- The target is on an element represented by a specific piece of data
    | SpecificDropTarget a


{-| The state of the dragging and dropping.
-}
type alias StateData a =
    { draggedObject : Maybe a
    , dropTarget : DropTarget a
    }
