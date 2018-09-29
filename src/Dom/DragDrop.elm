module Dom.DragDrop exposing
    ( State
    , isCurrentDropTarget, currentlyDraggedObject, dropTargetExists, initialState
    , startDragging, stopDragging, updateDropTarget
    , Messages
    , makeDraggable, makeDroppable
    )

{-| This library makes it easy to implement HTML5 drag-and-drop operations with Elm and
[@danielnarey's elm-dom framework](https://github.com/danielnarey/elm-modular-ui/).

Dom.Element nodes can be made draggable and droppable, with the state represented by an opaque object you can store in your model.

Each draggable/droppable element should correspond to some kind of id. This could be an (id for an) item in a list, a tag value from a type representing the various draggable/droppable elements, or whatever you want.

Your application must provide messages for each of the events triggered by this framework. The library provides helper methods to query and update the current state.


# State

@docs State


# Querying State

@docs isCurrentDropTarget, currentlyDraggedObject, dropTargetExists, initialState


# Updating State

@docs startDragging, stopDragging, updateDropTarget


# Specifying Messages

@docs Messages


# Updating the UI

@docs makeDraggable, makeDroppable

-}

import Dom
import Dom.DragDrop.Events exposing (onDragEnd, onDragEnter, onDragLeave, onDragStart, onDrop)
import Dom.DragDrop.State exposing (DropTarget(..), StateData)
import Json.Encode
import VirtualDom


{-| An opaque container for state data.
-}
type State a
    = State (StateData a)


{-| The initial state on page load, with nothing being dragged or dropped.
-}
initialState : State a
initialState =
    State { draggedObject = Nothing, dropTarget = Dom.DragDrop.State.NoDropTarget }


{-| Messages the Dom.DragDrop framework will send to your application as events occur. It is up to your application to call the appropriate Dom.DragDrop update function and store the result in your model.
-}
type alias Messages msg =
    { dragStarted : msg
    , dropTargetChanged : msg
    , dragEnded : msg
    , dropped : msg
    }



-- STATE MANIPULATION FUNCTIONS


{-| When the dragStarted message is received by your app, call this method to update the state with the newly-dragged object.
-}
startDragging : State a -> a -> State a
startDragging (State stateData) id =
    let
        updatedStateData : StateData a
        updatedStateData =
            { stateData | draggedObject = Just id }
    in
    State updatedStateData


{-| When dragging stops because either the dragEnded or dropped message were received or the user has done something else in your application, call this method to update the state appropriately.
-}
stopDragging : State a -> State a
stopDragging (State stateData) =
    initialState


{-| When the user drags an element over a potential drop zone and the dropTargetChanged message is received by your app, call this method to update the state with the currently targeted drop zone.
-}
updateDropTarget : State a -> a -> State a
updateDropTarget (State stateData) id =
    let
        updatedStateData : StateData a
        updatedStateData =
            { stateData | dropTarget = SpecificDropTarget id }
    in
    State updatedStateData


{-| This method will tell you whether a given item is currently being hovered over to allow you to provide a visual hint.
-}
isCurrentDropTarget : State a -> a -> Bool
isCurrentDropTarget (State state) id =
    case ( state.dropTarget, state.dropTarget == SpecificDropTarget id ) of
        ( SpecificDropTarget _, True ) ->
            True

        _ ->
            False


{-| This method will tell you whether the dragged element (if any) is currently over a drop zone.
-}
dropTargetExists : State a -> Bool
dropTargetExists (State stateData) =
    stateData.dropTarget /= NoDropTarget


{-| This method will return the currently dragged item (if any). Note that this will return the id (data) that corresponds to the Dom.Element node being dragged, rather than the actual DOM node itself.
-}
currentlyDraggedObject : State a -> Maybe a
currentlyDraggedObject (State stateData) =
    stateData.draggedObject



-- UI FUNCTIONS


{-| makeDraggable makes an element draggable. When an element is being dragged, it will gain the "being-dragged" CSS class, with which you can control the display of the moving element.
-}
makeDraggable : State a -> a -> Messages msg -> Dom.Element msg -> Dom.Element msg
makeDraggable state id messages element =
    case currentlyDraggedObject state of
        -- nothing is being moved currently
        -- so all the elements should be draggable
        Nothing ->
            element
                |> Dom.addAttribute (VirtualDom.property "draggable" (Json.Encode.bool True))
                -- onClickPreventDefault is a special method that hooks into the VirtualDom's onWithOptions cal
                -- as such, we have to add it directly via Dom.addAttribute rather than using Dom.addAction
                -- fortunately, many of the low-level Ui types are aliases to basic Elm types
                |> Dom.addAttribute (onDragStart messages.dragStarted)
                -- absurdly, this is needed for Firefox; see https://medium.com/elm-shorts/elm-drag-and-drop-game-630205556d2
                -- in a future version of Elm this will no longer be allowed and we'll have to use ports 😐
                |> Dom.addAttribute (VirtualDom.attribute "ondragstart" "event.dataTransfer.setData(\"text/html\", \"blank\")")

        -- This element is being dragged -- style it appropriately and add appropriate drag and drop events
        Just anObject ->
            let
                (State stateData) =
                    state

                draggedElement : Dom.Element msg
                draggedElement =
                    element
                        |> Dom.addClassConditional "being-dragged" (stateData.draggedObject == Just id)
            in
            case dropTargetExists state of
                -- There's no drop target, so if the dragged object is dropped, end the drag
                True ->
                    draggedElement
                        |> Dom.addAttribute (onDragEnd messages.dragEnded)

                False ->
                    draggedElement


{-| makeDroppable marks an element as a place that a dragged object can be dropped onto. If the dragged object is currently hovering over the droppable element, it gains the CSS class "drop-target" to allow for appropriate visual indication.
-}
makeDroppable : State a -> a -> Messages msg -> Dom.Element msg -> Dom.Element msg
makeDroppable state id messages element =
    let
        droppableElement : Dom.Element msg
        droppableElement =
            element
                |> Dom.addAttribute (VirtualDom.attribute "ondragover" "return false")
                |> Dom.addAttribute (onDragEnter messages.dropTargetChanged)
    in
    case isCurrentDropTarget state id of
        True ->
            droppableElement
                |> Dom.addClass "drop-target"
                |> Dom.addAttribute (onDrop messages.dropped)

        _ ->
            -- we'll deal with the general "this could be dropped here" later
            droppableElement
