module App.Update exposing (..)

import App.Model exposing (..)
import Doc
import Navigation
import States.EditDoc
import States.Login


type Msg
    = NoOp
    | SetActiveRoute Route
    | LoggedIn
    | LoginMsg States.Login.InternalMsg
    | EditDocMsg States.EditDoc.InternalMsg
    | NewDoc
    | HistoryBack


loginTranslationDictionary : States.Login.TranslationDictionary Msg
loginTranslationDictionary =
    { onInternalMessage = LoginMsg
    , onLoggedIn = LoggedIn
    }


loginTranslator : States.Login.Translator Msg
loginTranslator =
    States.Login.translator loginTranslationDictionary


editDocTranslationDictionary : States.EditDoc.TranslationDictionary Msg
editDocTranslationDictionary =
    { onInternalMessage = EditDocMsg
    , onHistoryBack = HistoryBack
    }


editDocTranslator : States.EditDoc.Translator Msg
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
            if not model.isLoggedIn then
                ( { model | activeState = Login (States.Login.init) }, Cmd.none )
            else
                case route of
                    PageNotFoundR ->
                        ( { model | activeState = PageNotFound }, Cmd.none )

                    LoginR ->
                        ( { model | activeState = Login (States.Login.init) }, Cmd.none )

                    EditDocR route' ->
                        let
                            currentEditDocState =
                                case model.activeState of
                                    EditDoc state ->
                                        Just state

                                    _ ->
                                        Nothing

                            ( editDocState, editDocCmd ) =
                                States.EditDoc.doRoute route' currentEditDocState
                        in
                            ( { model | activeState = EditDoc editDocState }, Cmd.map editDocTranslator editDocCmd )

        LoggedIn ->
            let
                ( editDocState, editDocCmd ) =
                    (States.EditDoc.init Doc.emptyDoc)
            in
                ( { model
                    | activeState = EditDoc editDocState
                    , isLoggedIn = True
                  }
                , Cmd.map editDocTranslator editDocCmd
                )

        NewDoc ->
            let
                ( editDocState, editDocCmd ) =
                    States.EditDoc.init Doc.emptyDoc
            in
                ( { model | activeState = EditDoc editDocState }, Cmd.map editDocTranslator editDocCmd )

        HistoryBack ->
            ( model, Navigation.back 1 )
