module App.Model exposing (..)

import States.EditDoc
import States.Login


type Route
    = PageNotFoundR
    | LoginR
    | EditDocR States.EditDoc.Route


type Model
    = Uninitialized
    | Login States.Login.State
    | EditDoc States.EditDoc.State
