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


type Outgoing
    = LoggedIn


type Internal
    = NoOp
    | UpdateUsername String
    | UpdatePassword String
    | TryLogin


type Msg
    = InMsg Internal
    | OutMsg Outgoing


type alias Dictionary msg =
    { onInternalMessage : Internal -> msg
    , onLoggedIn : msg
    }


type alias Tagger parentMsg =
    Msg -> parentMsg


translator : Dictionary parentMsg -> Tagger parentMsg
translator { onInternalMessage, onLoggedIn } msg =
    case msg of
        InMsg internal ->
            onInternalMessage internal

        OutMsg LoggedIn ->
            onLoggedIn


init : State
init =
    { username = ""
    , password = ""
    , error = False
    }


update : Internal -> State -> ( State, Cmd Msg )
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
                    state.username == "OpenGovFoundation" && state.password == "AssemblyWorks"
            in
                ( { state | error = not validCredentials }
                , if validCredentials then
                    Util.msgToCmd (OutMsg LoggedIn)
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
        , Html.form [ class "usa-form center-block", onSubmit (InMsg TryLogin) ]
            [ fieldset []
                [ legend [] [ text "Login" ]
                , label [ for "username" ] [ text "Username" ]
                , input [ id "username", name "username", type' "text", onInput (InMsg << UpdateUsername) ] []
                , label [ for "password" ] [ text "Password" ]
                , input [ id "password", name "password", type' "password", onInput (InMsg << UpdatePassword) ] []
                , button
                    [ classList
                        [ ( "usa-button-disabled", state.username == "" || state.password == "" ) ]
                    ]
                    [ text "Login" ]
                ]
            ]
        ]
