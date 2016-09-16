module App.Update exposing (..)

import App.Model exposing (..)
import Doc.Model
import States.EditDoc
import States.Login
import Task


type Msg
    = Init Int
    | NoOp
    | LoginMsg States.Login.InternalMsg
    | EditDocMsg States.EditDoc.InternalMsg
    | SetActivePage Route
    | LoggedIn


loginTranslationDictionary =
    { onInternalMessage = LoginMsg
    , onLoggedIn = LoggedIn
    }


loginTranslator =
    States.Login.translator loginTranslationDictionary


editDocTranslationDictionary =
    { onInternalMessage = EditDocMsg
    , onSetUrl = always NoOp
    }


editDocTranslator =
    States.EditDoc.translator editDocTranslationDictionary


init : ( Model, Cmd Msg )
init =
    ( Uninitialized, Task.perform (always (Init 0)) Init (Task.succeed 0) )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case model of
        Uninitialized ->
            case msg of
                Init _ ->
                    ( Login States.Login.init, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        Login state ->
            case msg of
                LoginMsg msg' ->
                    mapEach Login (Cmd.map loginTranslator) <| States.Login.update msg' state

                LoggedIn ->
                    ( EditDoc (States.EditDoc.init Doc.Model.emptyDoc), Cmd.none )

                _ ->
                    ( model, Cmd.none )

        EditDoc state ->
            case msg of
                EditDocMsg msg' ->
                    mapEach EditDoc (Cmd.map editDocTranslator) <| States.EditDoc.update msg' state

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
