module States.PageNotFound exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)


view : Html msg
view =
    div [ class "center-block" ]
        [ p [] [ text "Couldn't find what you were looking for." ]
        ]
