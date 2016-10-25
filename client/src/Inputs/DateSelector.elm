module Inputs.DateSelector
    exposing
        ( Model
        , Msg
        , InternalMsg
        , Translator
        , TranslationDictionary
        , DefaultTo(..)
        , translator
        , init
        , update
        , view
        , defaultConfig
        , usConfig
        )

import Date exposing (Date)
import Date.Extra as Date exposing (Interval(..))
import DateSelectorDropdown
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Task exposing (Task)
import Util


type alias Model =
    { config : Config
    , state : State
    }


type alias Config =
    { defaultTo : DefaultTo
    , inputName : String
    , dateDisplayFormat : String
    , minDate : Date -> Date
    , maxDate : Date -> Date
    }


type DefaultTo
    = Now
    | Run (Task Never (Maybe Date))


type State
    = Uninitialized
    | Running
        { dropdownOpen : Bool
        , now : Date
        , minimumDate : Date
        , maximumDate : Date
        , selected : Maybe Date
        }


type OutMsg
    = SelectOut Date


type InternalMsg
    = Select Date
    | Toggle
    | Init Date
    | NoOp


type Msg
    = ForSelf InternalMsg
    | ForParent OutMsg


type alias TranslationDictionary msg =
    { onInternalMessage : InternalMsg -> msg
    , onDateSelected : Date -> msg
    }


type alias Translator parentMsg =
    Msg -> parentMsg


translator : TranslationDictionary parentMsg -> Translator parentMsg
translator { onInternalMessage, onDateSelected } msg =
    case msg of
        ForSelf internal ->
            onInternalMessage internal

        ForParent (SelectOut date) ->
            onDateSelected date


defaultConfig : Config
defaultConfig =
    { defaultTo = Now
    , inputName = "date-selector"
    , dateDisplayFormat = "yyyy-MM-dd"
    , minDate = identity
    , maxDate = identity
    }


usConfig : Config
usConfig =
    { defaultConfig | dateDisplayFormat = "MM/dd/yyyy" }


init : Config -> ( Model, Cmd Msg )
init conf =
    ( { config = conf, state = Uninitialized }
    , Util.performFailproof (ForSelf << Init) Date.now
    )


initRunning : Model -> Date -> Model
initRunning model now =
    let
        today =
            Date.floor Day now

        runningState =
            Running
                { dropdownOpen = False
                , now = now
                , minimumDate = model.config.minDate today
                , maximumDate = model.config.maxDate today
                , selected = Nothing
                }
    in
        { model | state = runningState }


update : InternalMsg -> Model -> ( Model, Cmd Msg )
update msg model =
    case model.state of
        Uninitialized ->
            case msg of
                Init now ->
                    let
                        today =
                            Date.floor Day now

                        cmdForSelected =
                            case model.config.defaultTo of
                                Now ->
                                    Util.msgToCmd (ForSelf <| Select today)

                                Run cmd' ->
                                    Util.performFailproof
                                        (ForSelf
                                            << Select
                                            << Maybe.withDefault today
                                        )
                                        cmd'
                    in
                        ( initRunning model now, cmdForSelected )

                _ ->
                    ( model, Cmd.none )

        Running state ->
            case msg of
                Select date ->
                    ( { model | state = Running { state | selected = Just date } }, Util.msgToCmd (ForParent <| SelectOut date) )

                Toggle ->
                    ( { model | state = Running { state | dropdownOpen = not state.dropdownOpen } }, Cmd.none )

                _ ->
                    ( model, Cmd.none )


view : Model -> Html Msg
view model =
    case model.state of
        Uninitialized ->
            div [] []

        Running state ->
            DateSelectorDropdown.viewWithButton
                (viewDateSelectorInput model.config)
                (ForSelf <| Toggle)
                (ForSelf << Select)
                state.dropdownOpen
                state.minimumDate
                state.maximumDate
                state.selected


viewDateSelectorInput : Config -> Bool -> Maybe Date -> Html Msg
viewDateSelectorInput config isOpen selected =
    input
        [ value (selected |> Maybe.map (Date.toFormattedString config.dateDisplayFormat) |> Maybe.withDefault "")
        , name config.inputName
        , readonly True
        , autocomplete False
        , onClick (ForSelf <| Toggle)
        ]
        []
