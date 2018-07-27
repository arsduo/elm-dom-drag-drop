module Ui.DragDrop.DragEvents
    exposing
        ( onDragStart
        , onDrag
        , onDragEnd
        , onDragEnter
        , onDragOver
        , onDragLeave
        , onDrop
        )

{- custom events for Html5 drag and drop

   Courtesy of https://github.com/wintvelt/elm-html5-drag-drop/blob/master/src/DragEvents.elm
   and https://medium.com/elm-shorts/elm-drag-and-drop-game-630205556d2
-}

import Html.Events exposing (on, onWithOptions)
import Html exposing (Attribute)
import Json.Decode


-- when drag of element starts


onDragStart : msg -> Attribute msg
onDragStart message =
    onDragHelper "dragstart" message



-- when element is being dragged (fires multiple times between dragStart and dragEnd)


onDrag : msg -> Attribute msg
onDrag message =
    onDragHelper "drag" message



-- when this element is no longer being dragged


onDragEnd : msg -> Attribute msg
onDragEnd message =
    onDragHelper "dragend" message



-- when another dragged element enters this element


onDragEnter : msg -> Attribute msg
onDragEnter message =
    onDragHelper "dragenter" message



-- when another dragged element is over this element (fired multiple times during drag)


onDragOver : msg -> Attribute msg
onDragOver message =
    onPreventHelper "dragover" message



-- when another dragged element leaves this element (moved outside border)


onDragLeave : msg -> Attribute msg
onDragLeave message =
    onDragHelper "dragleave" message



-- when another dragged element is dropped over this element


onDrop : msg -> Attribute msg
onDrop message =
    onPreventHelper "drop" message



-- helpers


onDragHelper : String -> msg -> Attribute msg
onDragHelper eventName message =
    onWithOptions
        eventName
        { preventDefault = False
        , stopPropagation = False
        }
        (Json.Decode.succeed message)


onPreventHelper : String -> msg -> Attribute msg
onPreventHelper eventName message =
    onWithOptions
        eventName
        { preventDefault = True
        , stopPropagation = False
        }
        (Json.Decode.succeed message)
