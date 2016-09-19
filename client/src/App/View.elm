module App.View exposing (..)

import App.Model exposing (..)
import App.Update exposing (..)
import Html.App as Html
import Html exposing (..)
import Html.Attributes exposing (..)
import States.EditDoc
import States.Login


view : Model -> Html Msg
view model =
    case model.activeState of
        Login state ->
          Html.map loginTranslator <| States.Login.view state

        EditDoc state ->
          Html.map editDocTranslator <| States.EditDoc.view state
