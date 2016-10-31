module Inputs.DateSelector
    exposing
        ( Model
        , Msg
        , Internal
        , Tagger
        , Dictionary
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


type Outgoing
    = SelectOut Date


type Internal
    = Select Date
    | Toggle
    | Init Date
    | NoOp


type Msg
    = InMsg Internal
    | OutMsg Outgoing


type alias Dictionary msg =
    { onInternalMessage : Internal -> msg
    , onDateSelected : Date -> msg
    }


type alias Tagger parentMsg =
    Msg -> parentMsg


translator : Dictionary parentMsg -> Tagger parentMsg
translator { onInternalMessage, onDateSelected } msg =
    case msg of
        InMsg internal ->
            onInternalMessage internal

        OutMsg (SelectOut date) ->
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
    , Util.performFailproof (InMsg << Init) Date.now
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


update : Internal -> Model -> ( Model, Cmd Msg )
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
                                    Util.msgToCmd (InMsg <| Select today)

                                Run cmd' ->
                                    Util.performFailproof
                                        (InMsg
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
                    let
                        clampedDate =
                            Date.clamp state.minimumDate state.maximumDate date
                    in
                        ( { model | state = Running { state | selected = Just clampedDate } }, Util.msgToCmd (OutMsg <| SelectOut clampedDate) )

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
                (InMsg <| Toggle)
                (InMsg << Select)
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
        , onClick (InMsg <| Toggle)
        ]
        []
