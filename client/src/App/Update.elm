module App.Update exposing (..)

import App.Model exposing (..)
import Doc.Model
import States.EditDoc
import States.Login


type Msg
    = NoOp
    | SetActiveRoute Route
    | LoggedIn
    | LoginMsg States.Login.InternalMsg
    | EditDocMsg States.EditDoc.Msg


loginTranslationDictionary :
      { onInternalMessage : States.Login.InternalMsg -> Msg, onLoggedIn : Msg }
loginTranslationDictionary =
    { onInternalMessage = LoginMsg
    , onLoggedIn = LoggedIn
    }


loginTranslator : States.Login.Translator Msg
loginTranslator =
    States.Login.translator loginTranslationDictionary


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
                        ( { model | activeState = EditDoc editDocState }, Cmd.map EditDocMsg editDocCmds )

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
                            -- TODO: move this stuff into the EditDoc module? Some
                            -- routes we may be able to just go to, others we may
                            -- want to forbid users from just jumping to them (e.g.
                            -- filling out clauses before the details), that logic
                            -- has to live somewhere when we implement it
                            ( editDocState, editDocCmd ) =
                                case model.activeState of
                                    EditDoc state ->
                                        ( state, Cmd.none )

                                    _ ->
                                        (States.EditDoc.init Doc.Model.emptyDoc)

                            newActiveState =
                                EditDoc { editDocState | activeRoute = route' }
                        in
                            ( { model | activeState = newActiveState }, Cmd.map EditDocMsg editDocCmd )

        LoggedIn ->
            let
                ( editDocState, editDocCmd ) =
                    (States.EditDoc.init Doc.Model.emptyDoc)
            in
                ( { model
                    | activeState = EditDoc editDocState
                    , isLoggedIn = True
                  }
                , Cmd.map EditDocMsg editDocCmd
                )
