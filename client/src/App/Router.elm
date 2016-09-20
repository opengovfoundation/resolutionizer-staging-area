module App.Router exposing (..)

import App.Model exposing (..)
import App.Update exposing (Msg(..))
import Navigation exposing (Location)
import States.EditDoc
import String
import RouteUrl exposing (HistoryEntry(..), UrlChange)


delta2url : Model -> Model -> Maybe UrlChange
delta2url previous current =
    case current.activeState of
        Login state ->
            Just <| UrlChange NewEntry "/login"

        EditDoc state ->
            States.EditDoc.stateToUrl state


location2messages : Location -> List Msg
location2messages location =
    if String.isEmpty location.pathname then
        []
    else if String.startsWith "/login" location.pathname then
        [ SetActiveRoute LoginR ]
    else if String.startsWith "/new" location.pathname then
        [ SetActiveRoute <| Maybe.withDefault PageNotFoundR <| Maybe.map EditDocR <| States.EditDoc.locationToRoute "/new" location ]
    else
        [ SetActiveRoute PageNotFoundR ]
