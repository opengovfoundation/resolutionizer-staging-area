module App.Update exposing (..)

import App.Model exposing (..)
import Doc.Model
import States.EditDoc
import Task


type Msg
    = Init Int
    | NoOp
    | EditDocM States.EditDoc.Msg
    | SetActivePage Route


init : ( Model, Cmd Msg )
init =
    ( Uninitialized, Task.perform (always (Init 0)) Init (Task.succeed 0) )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case model of
        Uninitialized ->
            case msg of
                Init _ ->
                    ( EditDoc (States.EditDoc.init Doc.Model.emptyDoc), Cmd.none )

                _ ->
                    ( model, Cmd.none )

        EditDoc state ->
            case msg of
                EditDocM msg' ->
                    mapEach EditDoc (Cmd.map EditDocM) <| States.EditDoc.update msg' state

                SetActivePage route ->
                    case route of
                        PageNotFoundR ->
                            ( model, Cmd.none )

                        LoginR ->
                            ( model, Cmd.none )

                        EditDocR route' ->
                            ( EditDoc { state | activeRoute = route' }, Cmd.none )

                _ ->
                    ( model, Cmd.none )


mapFst : (a -> x) -> ( a, b ) -> ( x, b )
mapFst f ( a, b ) =
    ( f a, b )


mapEach : (a -> x) -> (b -> x') -> ( a, b ) -> ( x, x' )
mapEach f g ( a, b ) =
    ( f a, g b )
