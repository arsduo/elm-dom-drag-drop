module MovableObjects exposing (Model, Msg(..), main, update, view)

import Browser
import Dom
import Dom.DragDrop as DragDrop
import Html exposing (Html)
import Html.Attributes
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



{- Users can drop onto either a specific element in the list (taking that spot) or move it to the end of the list. -}


type DropTargetIdType
    = OntoElement Id
    | EndOfList


type alias Model =
    { songs : List Song
    , order : List Id
    , dragDropState : DragDrop.State Id DropTargetIdType
    , video : Bool
    }


init : Model
init =
    { songs = songs
    , order = songs |> List.map .id
    , dragDropState = DragDrop.initialState
    , video = False
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
                listWithoutDraggedItem : List Id
                listWithoutDraggedItem =
                    model.order
                        |> List.Extra.remove draggedItemId

                ( beforeDroppedElement, afterDroppedElement ) =
                    let
                        indexToSplitAt : Id -> Int
                        indexToSplitAt id =
                            List.Extra.elemIndex id model.order
                                |> Maybe.withDefault 100

                        -- add one so that the element we just dragged and dropped comes first
                    in
                    case dropTarget of
                        OntoElement dropTargetId ->
                            listWithoutDraggedItem
                                |> List.Extra.splitAt (indexToSplitAt dropTargetId)

                        EndOfList ->
                            ( listWithoutDraggedItem, [] )

                showVideo : Bool
                showVideo =
                    -- surprise!
                    model.video || (beforeDroppedElement == [] && draggedItemId == Id 6)
            in
            { model | order = beforeDroppedElement ++ [ draggedItemId ] ++ afterDroppedElement, dragDropState = DragDrop.initialState, video = showVideo }


view : Model -> Html Msg
view model =
    let
        header : Dom.Element Msg
        header =
            Dom.element "div"
                |> Dom.addClass "hero"
                |> Dom.appendChild
                    (Dom.element "div"
                        |> Dom.addClass "hero-body"
                        |> Dom.appendChildList
                            [ Dom.element "div"
                                |> Dom.addClass "title"
                                |> Dom.appendText "Dom.DragDrop Demo"
                            , Dom.element "div"
                                |> Dom.addClass "subtitle"
                                |> Dom.appendText "Drag and drop to put these ABBA songs in order!"
                            ]
                    )

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
                    (Dom.element "h4"
                        |> Dom.appendText song.title
                        |> Dom.addClass "has-text-centered"
                    )
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
                |> Dom.addClassList [ "song-list", "column", "is-two-thirds" ]
                |> Dom.appendChildList
                    (case DragDrop.currentlyDraggedObject model.dragDropState of
                        Nothing ->
                            songContents

                        Just _ ->
                            songContents ++ [ endOfList ]
                    )

        abbaImage : Dom.Element Msg
        abbaImage =
            case model.video of
                True ->
                    Dom.element "iframe"
                        |> Dom.addAttributeList
                            [ Html.Attributes.width 492
                            , Html.Attributes.height 408
                            , Html.Attributes.src "https://www.youtube.com/embed/6qmzmD4POMk?autoplay=true"
                            ]

                _ ->
                    Dom.element "div"
                        |> Dom.addClass "column"
                        |> Dom.appendChild
                            (Dom.element "img"
                                |> Dom.addAttribute (Html.Attributes.src "abba.png")
                            )

        content : Dom.Element Msg
        content =
            Dom.element "div"
                |> Dom.addClass "columns"
                |> Dom.appendChildList [ songList, abbaImage ]
    in
    Dom.element "div"
        |> Dom.appendChildList [ header, content ]
        |> Dom.render
