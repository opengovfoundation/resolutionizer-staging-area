module App.View exposing (..)

import App.Model exposing (..)
import App.Update exposing (..)
import Html.App as Html
import Html exposing (..)
import States.EditDoc
import States.Login
import States.PageNotFound


view : Model -> Html Msg
view model =
    case model.activeState of
        Login state ->
            Html.map loginTranslator <| States.Login.view state

        EditDoc state ->
            Html.map EditDocMsg <| States.EditDoc.view state

        PageNotFound ->
            Html.map (always NoOp) <| States.PageNotFound.view
