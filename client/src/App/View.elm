module App.View exposing (..)

import App.Model exposing (..)
import App.Update exposing (..)
import Html.App as Html
import Html exposing (..)
import Html.Attributes exposing (..)
import States.EditDoc


view : Model -> Html Msg
view model =
    case model of
        Uninitialized ->
            div []
                [ text "Hello world"
                ]

        EditDoc state ->
          Html.map EditDocM <| States.EditDoc.view state
