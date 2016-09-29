module States.EditDoc exposing (Msg, Route(..), State, stateToUrl, locationToRoute, update, init, view)

import Doc.Model
import Inputs.DateSelector
import Dict
import Html.Lazy exposing (lazy, lazy2)
import Html exposing (..)
import Html.App as Html
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Keyed as Keyed
import Navigation exposing (Location)
import RouteUrl exposing (HistoryEntry(..), UrlChange)
import Exts.Html.Events


type Route
    = Meta
    | Clauses


type alias State =
    { doc : Doc.Model.Model
    , dateSelector : Inputs.DateSelector.Model
    , selectedNewSponsor : Maybe String
    , selectedNewClauseType : Doc.Model.ClauseType
    , uid : Int
    , activeRoute : Route
    , urlPrefix : String
    }


type Msg
    = SetSelectedClauseType Doc.Model.ClauseType
    | UpdateTitle String
    | NewClause
    | UpdateClause Int String
    | DeleteClause Int
    | SetActiveRoute Route
    | NewSponsor
    | UpdateSponsor Int (Maybe String)
    | SetSelectedSponsor (Maybe String)
    | DateSelectorMsg Inputs.DateSelector.Msg
    | NoOp


init : Doc.Model.Model -> ( State, Cmd Msg )
init doc =
    let
        ( dateSelectorModel, dateSelectorCmd ) =
            Inputs.DateSelector.init
    in
        ( { doc = doc
          , dateSelector = dateSelectorModel
          , selectedNewSponsor = List.head doc.validSponsors
          , selectedNewClauseType = doc.defaultClauseType
          , uid = Dict.size doc.clauses + Dict.size doc.sponsors
          , activeRoute = Meta
          , urlPrefix = "/new"
          }
        , Cmd.map DateSelectorMsg dateSelectorCmd
        )


stateToUrl : State -> Maybe UrlChange
stateToUrl state =
    case state.activeRoute of
        Meta ->
            Just <| UrlChange NewEntry (state.urlPrefix ++ "/meta")

        Clauses ->
            Just <| UrlChange NewEntry (state.urlPrefix ++ "/clauses")


locationToRoute : String -> Location -> Maybe Route
locationToRoute urlPrefix location =
    let
        locationMatch urlFragment =
            location.pathname == (urlPrefix ++ urlFragment)
    in
        if locationMatch "" then
            Just Meta
        else if locationMatch "/meta" then
            Just Meta
        else if locationMatch "/clauses" then
            Just Clauses
        else
            Nothing


update : Msg -> State -> ( State, Cmd Msg )
update msg state =
    case msg of
        SetSelectedClauseType clauseType ->
            ( { state | selectedNewClauseType = clauseType }, Cmd.none )

        UpdateTitle content ->
            let
                doc =
                    state.doc

                newDoc =
                    { doc | title = content }
            in
                { state | doc = newDoc } ! []

        NewClause ->
            let
                newDoc =
                    Doc.Model.addNewClause state.uid state.selectedNewClauseType state.doc
            in
                ( { state
                    | uid = state.uid + 1
                    , doc = newDoc
                  }
                , Cmd.none
                )

        UpdateClause id content' ->
            let
                updateClause =
                    Maybe.map (\c -> { c | content = content' })

                doc =
                    state.doc

                newDoc =
                    { doc | clauses = Dict.update id updateClause state.doc.clauses }
            in
                ( { state | doc = newDoc }, Cmd.none )

        DeleteClause id ->
            let
                doc =
                    state.doc

                newDoc =
                    { doc | clauses = Dict.remove id state.doc.clauses }
            in
                ( { state | doc = newDoc }, Cmd.none )

        SetActiveRoute route ->
            ( { state | activeRoute = route }, Cmd.none )

        SetSelectedSponsor sponsor ->
            ( { state | selectedNewSponsor = sponsor }, Cmd.none )

        NewSponsor ->
            let
                doc =
                    state.doc

                newDoc selectedNewSponsor =
                    -- TODO: display message to user stating the sponsor is
                    -- already present
                    case List.member selectedNewSponsor <| List.map .name <| Dict.values doc.sponsors of
                        True ->
                            doc

                        False ->
                            { doc | sponsors = Dict.insert state.uid (Doc.Model.newSponsor ((Dict.size doc.sponsors) + 1) selectedNewSponsor) doc.sponsors }
            in
                case state.selectedNewSponsor of
                    Nothing ->
                        ( state, Cmd.none )

                    Just selectedNewSponsor ->
                        ( { state
                            | uid = state.uid + 1
                            , doc = newDoc selectedNewSponsor
                          }
                        , Cmd.none
                        )

        UpdateSponsor id mSponsorName ->
            let
                updateSponsor sponsorName =
                    Maybe.map (\s -> { s | name = sponsorName })

                doc =
                    state.doc

                newDoc sponsorName =
                    { doc | sponsors = Dict.update id (updateSponsor sponsorName) state.doc.sponsors }
            in
                case mSponsorName of
                    -- TODO: should this mean delete sponsor?
                    Nothing ->
                        ( state, Cmd.none )

                    Just sponsorName ->
                        ( { state | doc = newDoc sponsorName }, Cmd.none )

        DateSelectorMsg msg' ->
            let
                ( dateSelectorModel, dateSelectorCmd, mSelectedDate ) =
                    Inputs.DateSelector.update msg' state.dateSelector

                doc =
                    state.doc

                newDoc =
                    { doc | meetingDate = mSelectedDate }
            in
                ( { state | doc = newDoc, dateSelector = dateSelectorModel }, Cmd.map DateSelectorMsg dateSelectorCmd )

        NoOp ->
            ( state, Cmd.none )


view : State -> Html Msg
view state =
    div [ class "usa-grid-full" ]
        [ viewRoute state
        ]


viewRoute : State -> Html Msg
viewRoute state =
    case state.activeRoute of
        Meta ->
            viewMetaRoute state

        Clauses ->
            viewClauseRoute state


viewMetaRoute : State -> Html Msg
viewMetaRoute state =
    div []
        [ p [] [ text "Enter the details of the Commemorative Resolution below" ]
        , viewMeta state
        , button [ onClick (SetActiveRoute Clauses), class "pull-right" ] [ text "Continue" ]
        ]


viewClauseRoute : State -> Html Msg
viewClauseRoute state =
    div []
        [ text "Enter the text for the resolution's clauses below."
        , lazy viewClauses state.doc
        , lazy2 viewClauseTypeSelector state.doc state.selectedNewClauseType
        ]


viewMeta : State -> Html Msg
viewMeta state =
    div [ class "form-horizontal" ]
        [ div [ class "usa-grid-full" ]
            [ label [ for "title", class "usa-width-one-sixth" ] [ text "Resolution Title" ]
            , textarea [ id "title", value state.doc.title, onInput (UpdateTitle), class "usa-width-five-sixths" ] []
            ]
        , div []
            [ label [ for "meeting-date", class "usa-width-one-sixth" ] [ text "Meeting Date" ]
            , Html.map DateSelectorMsg <| Inputs.DateSelector.view state.dateSelector
            ]
        , viewSponsors state
        ]


viewSponsors : State -> Html Msg
viewSponsors state =
    fieldset [ class "usa-grid-full" ]
        [ legend [ class "usa-width-one-sixth" ] [ text "Sponsors" ]
        , div [ class "usa-width-five-sixths" ]
            [ viewSponsorSelectors state.doc
            , div [ class "add-selector" ]
                [ sponsorSelect state.doc state.selectedNewSponsor SetSelectedSponsor
                , button [ class "usa-button-plain add", onClick (NewSponsor) ] []
                ]
            ]
        ]


viewSponsorSelectors : Doc.Model.Model -> Html Msg
viewSponsorSelectors doc =
    div [] <|
        List.map (\( id, sponsor ) -> sponsorSelect doc (Just sponsor.name) (UpdateSponsor id)) <|
            List.sortBy (.pos << snd) <|
                Dict.toList <|
                    doc.sponsors


sponsorSelect : Doc.Model.Model -> Maybe String -> (Maybe String -> Msg) -> Html Msg
sponsorSelect doc selectedSponsor toMsg =
    select [ Exts.Html.Events.onSelect toMsg ] <|
        List.map
            (\sponsor ->
                option
                    [ selected ((Just sponsor) == selectedSponsor)
                    ]
                    [ text sponsor ]
            )
            (doc.validSponsors)


viewClauses : Doc.Model.Model -> Html Msg
viewClauses doc =
    div [] <|
        List.map (viewClause doc) <|
            List.sortBy .pos <|
                Dict.values <|
                    doc.clauses


viewClause : Doc.Model.Model -> Doc.Model.Clause -> Html Msg
viewClause doc clause =
    let
        clauseId =
            "clause" ++ toString clause.id
    in
        div [ class "clause-wrapper" ]
            [ div [ class "clause" ]
                [ label [ class "clause-label", for clauseId ] [ clauseTypeFormatter doc clause.ctype ]
                , button
                    [ class "usa-button-plain delete"
                    , onClick (DeleteClause clause.id)
                    ]
                    []
                , Keyed.node "textarea"
                    [ id clauseId
                    , value clause.content
                    , onInput (UpdateClause clause.id)
                    ]
                    []
                ]
            ]


viewClauseTypeSelector : Doc.Model.Model -> Doc.Model.ClauseType -> Html Msg
viewClauseTypeSelector doc selectedNewClauseType =
    div [ class "add-selector" ]
        [ clauseTypeSelect doc selectedNewClauseType
        , button [ class "usa-button-plain add", onClick (NewClause) ] []
        ]


clauseTypeSelect : Doc.Model.Model -> Doc.Model.ClauseType -> Html Msg
clauseTypeSelect doc selectedClauseType =
    let
        determineSelectedClauseType =
            Maybe.withDefault doc.defaultClauseType << flip Maybe.andThen (getClauseTypeFromDisplayName doc)
    in
        select [ Exts.Html.Events.onSelect (SetSelectedClauseType << determineSelectedClauseType) ] <|
            List.map
                (\clauseType ->
                    option
                        [ selected (clauseType == selectedClauseType)
                        ]
                        [ clauseTypeFormatter doc clauseType ]
                )
                (Dict.keys doc.validClauseTypes)


clauseTypeFormatter : Doc.Model.Model -> Doc.Model.ClauseType -> Html msg
clauseTypeFormatter doc clauseType =
    Maybe.withDefault (text "ERROR") <|
        Maybe.map (text << .displayName) <|
            Maybe.oneOf
                [ Dict.get clauseType doc.validClauseTypes
                , Dict.get doc.defaultClauseType doc.validClauseTypes
                ]


getClauseTypeFromDisplayName : Doc.Model.Model -> String -> Maybe Doc.Model.ClauseType
getClauseTypeFromDisplayName doc displayName =
    doc.validClauseTypes
        |> Dict.toList
        |> List.filter (\( _, clauseTypeDesc ) -> clauseTypeDesc.displayName == displayName)
        |> List.map fst
        |> List.head
