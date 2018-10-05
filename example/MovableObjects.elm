module MovableObjects exposing (Model, Msg(..), main, update, view)

import Browser
import Dom
import Dom.DragDrop as DragDrop
import Html exposing (Html)
import List.Extra


type Id
    = Id Int


type alias Song =
    { id : Id
    , title : String
    }


songs : List Song
songs =
    [ { id = Id 1, title = "Mamma Mia" }
    , { id = Id 2, title = "Ring Ring" }
    , { id = Id 3, title = "Take a Chance on Me" }
    , { id = Id 4, title = "Waterloo" }
    , { id = Id 5, title = "Dancing Queen" }
    , { id = Id 6, title = "No Hay un Quien Cuplar" }
    ]


type alias Model =
    { songs : List Song, order : List Id, dragDropState : DragDrop.State Id }


init : Model
init =
    { songs = songs
    , order = songs |> List.map .id
    , dragDropState = DragDrop.initialState
    }


main : Program () Model Msg
main =
    Browser.sandbox { init = init, update = update, view = view }


type Msg
    = MoveStarted Id
    | MoveTargetChanged Id
    | MoveCanceled
    | MoveCompleted Id


update : Msg -> Model -> Model
update msg model =
    case msg of
        MoveStarted draggedItemId ->
            { model | dragDropState = DragDrop.startDragging model.dragDropState draggedItemId }

        MoveTargetChanged dropTargetId ->
            { model | dragDropState = DragDrop.updateDropTarget model.dragDropState dropTargetId }

        MoveCanceled ->
            { model | dragDropState = DragDrop.stopDragging model.dragDropState }

        MoveCompleted dropTargetId ->
            -- we've dropped the dragged element onto the droppable element
            -- so now, let's reorder things!
            let
                _ =
                    Debug.log "Dragged, dropped" ( DragDrop.currentlyDraggedObject model.dragDropState, dropTargetId )

                listWithoutDraggedItem : Id -> List Id
                listWithoutDraggedItem draggedId =
                    model.order
                        |> List.Extra.remove draggedId
                        |> Debug.log "listWithoutDraggedItem"

                splitOnDroppedItem : Id -> ( List Id, List Id )
                splitOnDroppedItem draggedId =
                    let
                        indexToSplitAt : Int
                        indexToSplitAt =
                            List.Extra.elemIndex dropTargetId model.order
                                |> Maybe.withDefault 100
                                -- add one so that the element we just dragged and dropped comes first
                                |> (+) 1
                                |> Debug.log "Split index"
                    in
                    listWithoutDraggedItem draggedId
                        |> List.Extra.splitAt indexToSplitAt
                        |> Debug.log "After split"
            in
            case DragDrop.currentlyDraggedObject model.dragDropState of
                Nothing ->
                    { model | dragDropState = DragDrop.initialState }

                Just aDraggedId ->
                    let
                        ( beforeDroppedElement, afterDroppedElement ) =
                            splitOnDroppedItem aDraggedId
                    in
                    { model | order = beforeDroppedElement ++ [ aDraggedId ] ++ afterDroppedElement, dragDropState = DragDrop.initialState }


view : Model -> Html Msg
view model =
    let
        header : Dom.Element Msg
        header =
            Dom.element "h1"
                |> Dom.appendText "Dom.DragDrop Demo"

        dragDropMessages : Song -> DragDrop.Messages Msg
        dragDropMessages { id } =
            { dragStarted = MoveStarted id
            , dropTargetChanged = MoveTargetChanged id
            , dragEnded = MoveCanceled
            , dropped = MoveCompleted id
            }

        songDisplay : Song -> Dom.Element Msg
        songDisplay song =
            Dom.element "div"
                |> DragDrop.makeDraggable model.dragDropState song.id (dragDropMessages song)
                |> DragDrop.makeDroppable model.dragDropState song.id (dragDropMessages song)
                |> Dom.appendChild
                    (Dom.element "h4" |> Dom.appendText song.title)
                |> Dom.addClass "song"

        songIndex : Song -> Int
        songIndex { id } =
            List.Extra.elemIndex id model.order
                |> Maybe.withDefault 100

        songList : List (Dom.Element Msg)
        songList =
            -- should we somehow not have an id in the sort order, put it at the end
            model.songs
                |> List.sortWith (\id1 id2 -> compare (songIndex id1) (songIndex id2))
                |> List.map songDisplay
    in
    Dom.element "div"
        |> Dom.appendChildList (header :: songList)
        |> Dom.render
