module Ui.DragDrop exposing (State, Messages, DropTarget(..), makeDraggable, makeDroppable)

{-| This library makes it easy to implement HTML5 drag-and-drop operations with Elm and
[@danielnarey's Modular Ui framework](https://github.com/danielnarey/elm-modular-ui/).

Ui.Element nodes can be made draggable and droppable, with the state represented by a simple
format you can embed in the appropriate place in your model.


# State

@docs State, DropTarget


# Specifying Messages

@docs Messages


# Updating the UI

@docs makeDraggable, makeDroppable

-}

-- Events

import Ui.DragDrop.DragEvents exposing (onDragStart, onDragEnd, onDrop, onDragEnter, onDragLeave)


-- Ui Library

import Ui
import Ui.Modifier
import Dom.Property
import Dom.Element


-- Elm

import VirtualDom


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

{-| The state of the dra}
type alias State a =
    { draggedObject : Maybe a
    , dropTarget : DropTarget a
    }


type alias Messages msg =
    { dragStarted : msg
    , dropTargetChanged : msg
    , dragEnded : msg
    , dropped : msg
    }


makeDraggable : State a -> a -> Messages msg -> Ui.Element msg -> Ui.Element msg
makeDraggable state objectForElement messages element =
    case state.draggedObject of
        -- nothing is being moved currently
        -- so all the elements should be draggable
        Nothing ->
            element
                |> Ui.Attribute.add ( "draggable", Dom.Property.bool True )
                -- onClickPreventDefault is a special method that hooks into the VirtualDom's onWithOptions cal
                -- as such, we have to add it directly via Dom.Element.addAttribute rather than using Ui.Action
                -- fortunately, many of the low-level Ui types are aliases to basic Elm types
                |> Dom.Element.addAttribute (onDragStart messages.dragStarted)
                -- absurdly, this is needed for Firefox; see https://medium.com/elm-shorts/elm-drag-and-drop-game-630205556d2
                -- in a future version of Elm this will no longer be allowed and we'll have to use ports 😐
                |> Dom.Element.addAttribute (VirtualDom.attribute "ondragstart" "event.dataTransfer.setData(\"text/html\", \"blank\")")

        -- This element is being dragged -- style it appropriately and add appropriate drag and drop events
        Just anObject ->
            let
                draggedElement : Ui.Element msg
                draggedElement =
                    element
                        |> Ui.Modifier.conditional ( "being-dragged", state.draggedObject == Just objectForElement )
                        |> Dom.Element.addAttribute (VirtualDom.attribute "ondragover" "return false")
                        |> Dom.Element.addAttribute (onDragEnter messages.dropTargetChanged)
            in
                case state.dropTarget of
                    -- There's no drop target, so if the dragged object is dropped, end the drag
                    NoDropTarget ->
                        draggedElement
                            |> Dom.Element.addAttribute (onDragEnd messages.dragEnded)

                    _ ->
                        draggedElement


makeDroppable : State a -> a -> Messages msg -> Ui.Element msg -> Ui.Element msg
makeDroppable { dropTarget } objectForElement messages element =
    case ( dropTarget, dropTarget == SpecificDropTarget objectForElement ) of
        ( SpecificDropTarget _, True ) ->
            element
                |> Ui.Modifier.add "drop-target"
                |> Dom.Element.addAttribute (onDrop messages.dropped)

        _ ->
            -- we'll deal with the general "this could be dropped here" later
            element
