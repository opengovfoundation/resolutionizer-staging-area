module States.Login exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Util


type alias State =
    { username : String
    , password : String
    , error : Bool
    }


type OutMsg
    = LoggedIn


type InternalMsg
    = NoOp
    | UpdateUsername String
    | UpdatePassword String
    | TryLogin


type Msg
    = ForSelf InternalMsg
    | ForParent OutMsg


type alias TranslationDictionary msg =
    { onInternalMessage : InternalMsg -> msg
    , onLoggedIn : msg
    }


type alias Translator parentMsg =
    Msg -> parentMsg


translator : TranslationDictionary parentMsg -> Translator parentMsg
translator { onInternalMessage, onLoggedIn } msg =
    case msg of
        ForSelf internal ->
            onInternalMessage internal

        ForParent LoggedIn ->
            onLoggedIn


init : State
init =
    { username = ""
    , password = ""
    , error = False
    }


update : InternalMsg -> State -> ( State, Cmd Msg )
update msg state =
    case msg of
        NoOp ->
            ( state, Cmd.none )

        UpdateUsername username ->
            ( { state | username = username }, Cmd.none )

        UpdatePassword password ->
            ( { state | password = password }, Cmd.none )

        TryLogin ->
            let
                validCredentials =
                    state.username == "hello" && state.password == "world"
            in
                ( { state | error = not validCredentials }
                , if validCredentials then
                    Util.msgToCmd (ForParent LoggedIn)
                  else
                    Cmd.none
                )


view : State -> Html Msg
view state =
    div [ class "login" ]
        [ div [ class "seal center-block" ]
            [ img [ src "/assets/img/chicago-seal.png", alt "City of Chicago Seal", class "img-responsive center-block" ] []
            ]
        , div [ class "text-center title" ]
            [ h1 [] [ text "City of Chicago" ]
            , h2 [] [ text "Commemorative Resolution Generator" ]
            ]
        , div []
            (if state.error then
                [ div [ class "usa-alert usa-alert-error" ]
                    [ div [ class "usa-alert-body" ]
                        [ div [ class "usa-alert-heading" ] [ text "Login Error" ]
                        , div [ class "usa-alert-text" ] [ text "Username and/or password is incorrect." ]
                        ]
                    ]
                ]
             else
                []
            )
        , Html.form [ class "usa-form center-block", onSubmit (ForSelf TryLogin) ]
            [ fieldset []
                [ legend [] [ text "Login" ]
                , label [ for "username" ] [ text "Username" ]
                , input [ id "username", name "username", type' "text", onInput (ForSelf << UpdateUsername) ] []
                , label [ for "password" ] [ text "Password" ]
                , input [ id "password", name "password", type' "password", onInput (ForSelf << UpdatePassword) ] []
                , button
                    [ classList
                        [ ( "usa-button-disabled", state.username == "" || state.password == "" ) ]
                    ]
                    [ text "Login" ]
                ]
            ]
        ]
