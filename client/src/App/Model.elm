module App.Model exposing (..)

import Array exposing (Array)
import States.EditDoc


type Route
    = PageNotFoundR
    | LoginR
    | EditDocR States.EditDoc.Route


type Model
    = Uninitialized
    | EditDoc States.EditDoc.State
