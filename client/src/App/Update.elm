module App.Update exposing (..)

import App.Model exposing (..)
import Doc.Model
import States.EditDoc
import States.Login
import Task


type Msg
    = NoOp
    | SetActiveRoute Route
    | LoggedIn
    | LoginMsg States.Login.InternalMsg
    | EditDocMsg States.EditDoc.InternalMsg


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
    ( App.Model.init, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        LoginMsg msg' ->
            case model.activeState of
                Login state ->
                    let
                        ( loginState, loginCmds ) =
                            States.Login.update msg' state
                    in
                        ( { model | activeState = Login loginState }, Cmd.map loginTranslator loginCmds )

                _ ->
                    ( model, Cmd.none )

        EditDocMsg msg' ->
            case model.activeState of
                EditDoc state ->
                    let
                        ( editDocState, editDocCmds ) =
                            States.EditDoc.update msg' state
                    in
                        ( { model | activeState = EditDoc editDocState }, Cmd.map editDocTranslator editDocCmds )

                _ ->
                    ( model, Cmd.none )

        SetActiveRoute route ->
            case route of
                PageNotFoundR ->
                    ( model, Cmd.none )

                LoginR ->
                    ( { model | activeState = Login (States.Login.init) }, Cmd.none )

                EditDocR route' ->
                    let
                        -- TODO: move this stuff into the EditDoc module? Some
                        -- routes we may be able to just go to, others we may
                        -- want to forbid users from just jumping to them (e.g.
                        -- filling out clauses before the details), that logic
                        -- has to live somewhere when we implement it
                        editDocState =
                            case model.activeState of
                                EditDoc state ->
                                    state

                                _ ->
                                    (States.EditDoc.init Doc.Model.emptyDoc)

                        newActiveState =
                            EditDoc { editDocState | activeRoute = route' }
                    in
                        ( { model | activeState = newActiveState }, Cmd.none )

        LoggedIn ->
            ( { model | activeState = EditDoc (States.EditDoc.init Doc.Model.emptyDoc) }, Cmd.none )
