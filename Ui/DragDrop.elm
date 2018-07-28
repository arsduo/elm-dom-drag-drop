module Ui.DragDrop exposing (State, Messages, isCurrentDropTarget, updateDropTarget, startDragging, stopDragging, initialState, currentlyDraggedObject, dropTargetExists, makeDraggable, makeDroppable)

{-| This library makes it easy to implement HTML5 drag-and-drop operations with Elm and
[@danielnarey's Modular Ui framework](https://github.com/danielnarey/elm-modular-ui/).

Ui.Element nodes can be made draggable and droppable, with the state represented by a simple
format you can embed in the appropriate place in your model.


# State

@docs State


# Querying State

@docs isCurrentDropTarget, startDragging, stopDragging, updateDropTarget, currentlyDraggedObject, dropTargetExists, initialState


# Specifying Messages

@docs Messages


# Updating the UI

@docs makeDraggable, makeDroppable

-}

import Ui.DragDrop.State exposing (StateData, DropTarget(..))


-- Events

import Ui.DragDrop.Events exposing (onDragStart, onDragEnd, onDrop, onDragEnter, onDragLeave)


-- Ui Library

import Ui
import Ui.Modifier
import Ui.Attribute
import Dom.Property
import Dom.Element


-- Elm

import VirtualDom


{-| An opaque container for state data.
-}
type State a
    = State (StateData a)


{-| Documentation coming soon
-}
initialState : State a
initialState =
    State { draggedObject = Nothing, dropTarget = Ui.DragDrop.State.NoDropTarget }


{-| Messages the Ui.DragDrop framework will send to your application as events occur.
-}
type alias Messages msg =
    { dragStarted : msg
    , dropTargetChanged : msg
    , dragEnded : msg
    , dropped : msg
    }



-- STATE MANIPULATION FUNCTIONS


{-| Documentation coming soon
-}
startDragging : State a -> a -> State a
startDragging (State stateData) id =
    let
        updatedStateData : StateData a
        updatedStateData =
            { stateData | draggedObject = Just id }
    in
        State updatedStateData


{-| Documentation coming soon
-}
stopDragging : State a -> State a
stopDragging (State stateData) =
    let
        updatedStateData : StateData a
        updatedStateData =
            { stateData | draggedObject = Nothing, dropTarget = NoDropTarget }
    in
        State updatedStateData


{-| Documentation coming soon
-}
updateDropTarget : State a -> a -> State a
updateDropTarget (State stateData) id =
    let
        updatedStateData : StateData a
        updatedStateData =
            { stateData | dropTarget = SpecificDropTarget id }
    in
        State updatedStateData


{-| Documentation coming soon
-}
isCurrentDropTarget : State a -> a -> Bool
isCurrentDropTarget (State state) id =
    case ( state.dropTarget, state.dropTarget == SpecificDropTarget id ) of
        ( SpecificDropTarget _, True ) ->
            True

        _ ->
            False


{-| Documentation coming soon
-}
dropTargetExists : State a -> Bool
dropTargetExists (State stateData) =
    stateData.dropTarget == NoDropTarget


{-| Documentation coming soon
-}
currentlyDraggedObject : State a -> Maybe a
currentlyDraggedObject (State stateData) =
    stateData.draggedObject



-- UI FUNCTIONS


{-| makeDraggable makes an element draggable, accounting properly for whether it's currently being dragged.
-}
makeDraggable : State a -> a -> Messages msg -> Ui.Element msg -> Ui.Element msg
makeDraggable state id messages element =
    case currentlyDraggedObject state of
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
                (State stateData) =
                    state

                draggedElement : Ui.Element msg
                draggedElement =
                    element
                        |> Ui.Modifier.conditional ( "being-dragged", stateData.draggedObject == Just id )
                        |> Dom.Element.addAttribute (VirtualDom.attribute "ondragover" "return false")
                        |> Dom.Element.addAttribute (onDragEnter messages.dropTargetChanged)
            in
                case dropTargetExists state of
                    -- There's no drop target, so if the dragged object is dropped, end the drag
                    True ->
                        draggedElement
                            |> Dom.Element.addAttribute (onDragEnd messages.dragEnded)

                    False ->
                        draggedElement


{-| makeDroppable allows the user to drop a dragged element onto another element, accounting properly for whether the dragged object is currently hovering over the droppable.
-}
makeDroppable : State a -> a -> Messages msg -> Ui.Element msg -> Ui.Element msg
makeDroppable state id messages element =
    case isCurrentDropTarget state id of
        True ->
            element
                |> Ui.Modifier.add "drop-target"
                |> Dom.Element.addAttribute (onDrop messages.dropped)

        _ ->
            -- we'll deal with the general "this could be dropped here" later
            element
