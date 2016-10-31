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
    | LoginMsg States.Login.Internal
    | EditDocMsg States.EditDoc.Internal
    | NewDoc
    | HistoryBack


loginDictionary : States.Login.Dictionary Msg
loginDictionary =
    { onInternalMessage = LoginMsg
    , onLoggedIn = LoggedIn
    }


loginTagger : States.Login.Tagger Msg
loginTagger =
    States.Login.translator loginDictionary


editDocDictionary : States.EditDoc.Dictionary Msg
editDocDictionary =
    { onInternalMessage = EditDocMsg
    , onHistoryBack = HistoryBack
    }


editDocTagger : States.EditDoc.Tagger Msg
editDocTagger =
    States.EditDoc.translator editDocDictionary


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
                        ( { model | activeState = Login loginState }, Cmd.map loginTagger loginCmds )

                _ ->
                    ( model, Cmd.none )

        EditDocMsg msg' ->
            case model.activeState of
                EditDoc state ->
                    let
                        ( editDocState, editDocCmds ) =
                            States.EditDoc.update msg' state
                    in
                        ( { model | activeState = EditDoc editDocState }, Cmd.map editDocTagger editDocCmds )

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
                            ( { model | activeState = EditDoc editDocState }, Cmd.map editDocTagger editDocCmd )

        LoggedIn ->
            let
                ( editDocState, editDocCmd ) =
                    (States.EditDoc.init Doc.emptyDoc)
            in
                ( { model
                    | activeState = EditDoc editDocState
                    , isLoggedIn = True
                  }
                , Cmd.map editDocTagger editDocCmd
                )

        NewDoc ->
            let
                ( editDocState, editDocCmd ) =
                    States.EditDoc.init Doc.emptyDoc
            in
                ( { model | activeState = EditDoc editDocState }, Cmd.map editDocTagger editDocCmd )

        HistoryBack ->
            ( model, Navigation.back 1 )
