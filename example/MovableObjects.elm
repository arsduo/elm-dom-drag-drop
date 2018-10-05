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


type DropTargetIdType
    = OntoElement Id
    | EndOfList


type alias Model =
    { songs : List Song, order : List Id, dragDropState : DragDrop.State Id DropTargetIdType }


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
    | MoveTargetChanged DropTargetIdType
    | MoveCanceled
    | MoveCompleted Id DropTargetIdType


update : Msg -> Model -> Model
update msg model =
    case msg of
        MoveStarted draggedItemId ->
            { model | dragDropState = DragDrop.startDragging model.dragDropState draggedItemId }

        MoveTargetChanged dropTargetId ->
            { model | dragDropState = DragDrop.updateDropTarget model.dragDropState dropTargetId }

        MoveCanceled ->
            { model | dragDropState = DragDrop.stopDragging model.dragDropState }

        MoveCompleted draggedItemId dropTarget ->
            -- we've dropped the dragged element onto the droppable element
            -- so now, let's reorder things!
            let
                _ =
                    Debug.log "Dragged, dropped" ( DragDrop.currentlyDraggedObject model.dragDropState, dropTarget )

                listWithoutDraggedItem : List Id
                listWithoutDraggedItem =
                    model.order
                        |> List.Extra.remove draggedItemId
                        |> Debug.log "listWithoutDraggedItem"

                ( beforeDroppedElement, afterDroppedElement ) =
                    let
                        indexToSplitAt : Id -> Int
                        indexToSplitAt id =
                            List.Extra.elemIndex id model.order
                                |> Maybe.withDefault 100
                                -- add one so that the element we just dragged and dropped comes first
                                |> Debug.log "Split index"
                    in
                    case dropTarget of
                        OntoElement dropTargetId ->
                            listWithoutDraggedItem
                                |> List.Extra.splitAt (indexToSplitAt dropTargetId)
                                |> Debug.log "After split"

                        EndOfList ->
                            ( listWithoutDraggedItem, [] )
            in
            { model | order = beforeDroppedElement ++ [ draggedItemId ] ++ afterDroppedElement, dragDropState = DragDrop.initialState }


view : Model -> Html Msg
view model =
    let
        header : Dom.Element Msg
        header =
            Dom.element "h1"
                |> Dom.appendText "Dom.DragDrop Demo"

        dragDropMessages : DragDrop.Messages Msg Id DropTargetIdType
        dragDropMessages =
            { dragStarted = MoveStarted
            , dropTargetChanged = MoveTargetChanged
            , dragEnded = MoveCanceled
            , dropped = MoveCompleted
            }

        songDisplay : Song -> Dom.Element Msg
        songDisplay song =
            Dom.element "li"
                |> DragDrop.makeDraggable model.dragDropState song.id dragDropMessages
                |> DragDrop.makeDroppable model.dragDropState (OntoElement song.id) dragDropMessages
                |> Dom.appendChild
                    (Dom.element "h4" |> Dom.appendText song.title)
                |> Dom.addClass "song"

        songIndex : Song -> Int
        songIndex { id } =
            List.Extra.elemIndex id model.order
                |> Maybe.withDefault 100

        songContents : List (Dom.Element Msg)
        songContents =
            -- should we somehow not have an id in the sort order, put it at the end
            model.songs
                |> List.sortWith (\id1 id2 -> compare (songIndex id1) (songIndex id2))
                |> List.map songDisplay

        endOfList : Dom.Element Msg
        endOfList =
            Dom.element "li"
                |> Dom.appendText "⤵️"
                |> Dom.addClassList [ "end-of-list", "song" ]
                |> DragDrop.makeDroppable model.dragDropState EndOfList dragDropMessages

        songList : Dom.Element Msg
        songList =
            Dom.element "ul"
                |> Dom.addClass "song-list"
                |> Dom.appendChildList
                    (case DragDrop.currentlyDraggedObject model.dragDropState of
                        Nothing ->
                            songContents

                        Just _ ->
                            songContents ++ [ endOfList ]
                    )
    in
    Dom.element "div"
        |> Dom.appendChildList [ header, songList ]
        |> Dom.render
