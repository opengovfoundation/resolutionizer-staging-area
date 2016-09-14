module App.Router exposing (..)

import App.Model exposing (..)
import App.Update exposing (Msg(..))
import Navigation exposing (Location)
import States.EditDoc
import RouteUrl exposing (HistoryEntry(..), UrlChange)


delta2url : Model -> Model -> Maybe UrlChange
delta2url previous current =
    case current of
        Uninitialized ->
            Nothing

        EditDoc state ->
            States.EditDoc.route state.activeRoute


location2messages : Location -> List Msg
location2messages location = Debug.log ("Path: " ++ location.pathname) <|
    -- TODO: use something better like evancz/url-parser
    case location.pathname of
        "" ->
            []

        "/login" ->
            [ SetActivePage LoginR ]

        "/new" ->
            [ SetActivePage (EditDocR States.EditDoc.Meta) ]

        -- TODO: stuff these away inside States.EditDoc somehow?
        -- And they should ideally all be prefixed with /new/, how to pass that
        -- fact along as well?
        "/meta" ->
            [ SetActivePage (EditDocR States.EditDoc.Meta) ]

        "/clauses" ->
            [ SetActivePage (EditDocR States.EditDoc.Clauses) ]

        _ ->
            [ SetActivePage PageNotFoundR ]
