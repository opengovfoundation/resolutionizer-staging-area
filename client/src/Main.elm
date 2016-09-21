module Main exposing (..)

import App.Model exposing (Model)
import App.Router
import App.Update exposing (Msg)
import App.View
import RouteUrl


main : Program Never
main =
    RouteUrl.program
        { delta2url = App.Router.delta2url
        , location2messages = App.Router.location2messages
        , init = App.Update.init
        , view = App.View.view
        , update = App.Update.update
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
