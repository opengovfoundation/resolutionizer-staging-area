module Inputs.DateSelector exposing (Model, Msg, init, update, view)

import Date exposing (Date)
import Date.Extra as Date exposing (Interval(..))
import DateSelectorDropdown
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Util


type Model
    = Uninitialized
    | Running
        { dropdownOpen : Bool
        , now : Date
        , minimumDate : Date
        , maximumDate : Date
        , selected : Maybe Date
        }


type Msg
    = Select Date
    | Toggle
    | Init Date
    | NoOp


init : ( Model, Cmd Msg )
init =
    ( Uninitialized, Util.performFailproof Init Date.now )


initRunning : Date -> Model
initRunning now =
    let
        today =
            Date.floor Day now
    in
        Running
            { dropdownOpen = False
            , now = now
            , minimumDate = today
            , maximumDate = Date.add Year 1 today
            , selected = Just today
            }


update : Msg -> Model -> ( Model, Cmd Msg, Maybe Date )
update msg model =
    case model of
        Uninitialized ->
            case msg of
                Init date ->
                    -- After getting the running state, we send a NoOp message
                    -- to emit the correct selected date
                    ( initRunning date, Util.msgToCmd NoOp, Nothing )

                _ ->
                    ( model, Cmd.none, Nothing )

        Running state ->
            case msg of
                Select date ->
                    ( Running { state | selected = Just date }, Cmd.none, Just date )

                Toggle ->
                    ( Running { state | dropdownOpen = not state.dropdownOpen }, Cmd.none, state.selected )

                _ ->
                    ( model, Cmd.none, state.selected )


view : Model -> Html Msg
view model =
    case model of
        Uninitialized ->
            div [] []

        Running state ->
            DateSelectorDropdown.viewWithButton
                viewDateSelectorInput
                Toggle
                Select
                state.dropdownOpen
                state.minimumDate
                state.maximumDate
                state.selected


viewDateSelectorInput : Bool -> Maybe Date -> Html Msg
viewDateSelectorInput isOpen selected =
    input
        [ value (selected |> Maybe.map (Date.toFormattedString "MM/dd/yyyy") |> Maybe.withDefault "")
        , name "meeting-date"
        , readonly True
        , autocomplete False
        , onClick Toggle
        ]
        []
