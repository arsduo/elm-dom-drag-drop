module Stuff exposing (Model, Msg(..), main, update, view)

import Dom.DragDrop as DragDrop
import Html exposing (Html, button, div, input, span, text)
import Html.Attributes exposing (style, value)
import Html.Events exposing (onClick, onInput)


type Id
    = Id Int


type alias Song =
    { id : Id
    , title : String
    }


songs : List Song
songs =
    [ { id = 1, title = "Mamma Mia" }
    , { id = 2, title = "Ring Ring" }
    , { id = 3, title = "Take a Chance on Me" }
    , { id = 4, title = "Waterloo" }
    , { id = 5, title = "Dancing Queen" }
    , { id = 6, title = "No Hay un Quien Cuplar" }
    ]


type alias Model =
    { songs : List Song, order : List Id, dragDropState = DragDrop.State Id}

init : Model
init =
  {
    songs = songs
    , order = songs |> List.map .id
    , DragDrop.initialState
  }

main : Program Never Model Msg
main =
    Html.beginnerProgram { model = init, update = update, view = view }


type Msg
    = DragStarted Id
    | DropTargetChanged
    | UpdateSecretField String


view : Model -> Html Msg
view model =
    div []
        [ div []
            [ button
                [ onClick Decrement ]
                [ text "-" ]
            , span
                []
                [ text (toString model.counter) ]
            , button [ onClick Increment ]
                [ text "+" ]
            ]
        , div [ style "margin-top" "15px" ]
            [ div [] [ text "Super secret field" ]
            , input [ onInput UpdateSecretField, value model.secretField ] []
            , div [ style "font-size" "0.8em" ] [ text ("Current value: " ++ model.secretField) ]
            ]
        ]


update : Msg -> Model -> Model
update msg model =
    case msg of
        Increment ->
            { model | counter = model.counter + 1 }

        Decrement ->
            { model | counter = model.counter - 1 }

        UpdateSecretField string ->
            { model | secretField = string }
