module States.Login exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Task


type alias State =
    { username : String
    , password : String
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
                ( state, if validCredentials then Task.perform identity identity (Task.succeed (ForParent LoggedIn)) else Cmd.none )


view : State -> Html Msg
view state =
    div []
        [ Html.form [ class "usa-form", onSubmit (ForSelf TryLogin) ]
            [ fieldset []
                [ legend [] [ text "Sign In" ]
                , label [ for "username" ] [ text "Username" ]
                , input [ id "username", name "username", type' "text", onInput (ForSelf << UpdateUsername) ] []
                , label [ for "password" ] [ text "Password" ]
                , input [ id "password", name "password", type' "password", onInput (ForSelf << UpdatePassword) ] []
                , button [ ] [ text "Login" ]
                ]
            ]
        ]
