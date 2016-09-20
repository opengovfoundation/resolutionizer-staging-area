module App.Model exposing (..)

import States.EditDoc
import States.Login


type Route
    = PageNotFoundR
    | LoginR
    | EditDocR States.EditDoc.Route


type alias Model =
    { activeState : State
    , isLoggedIn : Bool
    }


type State
    = Login States.Login.State
    | EditDoc States.EditDoc.State
    | PageNotFound


init : Model
init =
    { activeState = Login States.Login.init
    , isLoggedIn = False
    }
