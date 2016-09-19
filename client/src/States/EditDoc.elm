module States.EditDoc exposing (InternalMsg, Route(..), State, stateToUrl, locationToRoute, translator, update, init, view)

import Doc.Model
import Dict
import Html.Lazy exposing (lazy, lazy2)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Keyed as Keyed
import Navigation exposing (Location)
import RouteUrl exposing (HistoryEntry(..), UrlChange)


type Route
    = Meta
    | Clauses


type alias State =
    { doc : Doc.Model.Model
    , selectedNewSponsor : String
    , selectedNewClauseType : Doc.Model.ClauseType
    , uid : Int
    , activeRoute : Route
    , urlPrefix : String
    }


type OutMsg
    = SetUrl String


type InternalMsg
    = SetSelectedClauseType Doc.Model.ClauseType
    | UpdateTitle String
    | NewClause
    | UpdateClause Int String
    | DeleteClause Int
    | SetActiveRoute Route
    | NewSponsor
    | UpdateSponsor Int String
    | SetSelectedSponsor String
    | NoOp


type Msg
    = ForSelf InternalMsg
    | ForParent OutMsg


type alias TranslationDictionary msg =
    { onInternalMessage : InternalMsg -> msg
    , onSetUrl : String -> msg
    }


type alias Translator parentMsg =
    Msg -> parentMsg


translator : TranslationDictionary parentMsg -> Translator parentMsg
translator { onInternalMessage, onSetUrl } msg =
    case msg of
        ForSelf internal ->
            onInternalMessage internal

        ForParent (SetUrl url) ->
            onSetUrl url


init : Doc.Model.Model -> State
init doc =
    { doc = doc
    , selectedNewSponsor = ""
    , selectedNewClauseType = doc.defaultClauseType
    , uid = 0
    , activeRoute = Meta
    , urlPrefix = "/new"
    }


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


update : InternalMsg -> State -> ( State, Cmd Msg )
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
                doc =
                    state.doc

                newDoc =
                    { doc | clauses = Dict.insert state.uid (Doc.Model.newClause state.uid ((Dict.size doc.clauses) + 1) state.selectedNewClauseType "") doc.clauses }
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

                newDoc =
                    { doc | sponsors = Dict.insert state.uid (Doc.Model.newSponsor ((Dict.size doc.sponsors) + 1) state.selectedNewSponsor) doc.sponsors }
            in
                ( { state
                    | uid = state.uid + 1
                    , doc = newDoc
                  }
                , Cmd.none
                )

        UpdateSponsor id sponsorName ->
            let
                updateSponsor =
                    Maybe.map (\s -> { s | name = sponsorName })

                doc =
                    state.doc

                newDoc =
                    { doc | sponsors = Dict.update id updateSponsor state.doc.sponsors }
            in
                ( { state | doc = newDoc }, Cmd.none )

        NoOp ->
            ( state, Cmd.none )


view : State -> Html Msg
view state =
    div []
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
        [ text "Enter the details of the Commemorative Resolution below"
        , viewMeta state
        , button [ onClick (ForSelf <| SetActiveRoute Clauses) ] [ text "Continue" ]
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
    div []
        [ label [ for "title" ] [ text "Resolution Title" ]
        , textarea [ id "title", value state.doc.title, onInput (ForSelf << UpdateTitle) ] []
        , viewSponsors state
        ]


viewSponsors : State -> Html Msg
viewSponsors state =
    fieldset []
        [ legend [] [ text "Sponsors" ]
        , viewSponsorSelectors state.doc
        , div [ class "add-selector" ]
            [ sponsorSelect state.doc state.selectedNewSponsor (ForSelf << SetSelectedSponsor)
            , button [ class "usa-button-plain add", onClick (ForSelf NewSponsor) ] []
            ]
        ]


viewSponsorSelectors : Doc.Model.Model -> Html Msg
viewSponsorSelectors doc =
    div [] <|
        List.map (\sponsor -> sponsorSelect doc sponsor.name (ForSelf << UpdateSponsor sponsor.pos)) <|
            List.sortBy .pos <|
                Dict.values <|
                    doc.sponsors


sponsorSelect : Doc.Model.Model -> String -> (String -> Msg) -> Html Msg
sponsorSelect doc selectedSponsor toMsg =
    select [] <|
        List.map
            (\sponsor ->
                option
                    [ selected (sponsor == selectedSponsor)
                    , onClick (toMsg sponsor)
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
                    , onClick (ForSelf <| DeleteClause clause.id)
                    ]
                    []
                , Keyed.node "textarea"
                    [ id clauseId
                    , value clause.content
                    , onInput (ForSelf << UpdateClause clause.id)
                    ]
                    []
                ]
            ]


viewClauseTypeSelector : Doc.Model.Model -> Doc.Model.ClauseType -> Html Msg
viewClauseTypeSelector doc selectedNewClauseType =
    div [ class "add-selector" ]
        [ clauseTypeSelect doc selectedNewClauseType
        , button [ class "usa-button-plain add", onClick (ForSelf NewClause) ] []
        ]


clauseTypeSelect : Doc.Model.Model -> Doc.Model.ClauseType -> Html Msg
clauseTypeSelect doc selectedClauseType =
    select [] <|
        List.map
            (\clauseType ->
                option
                    [ selected (clauseType == selectedClauseType)
                    , onClick (ForSelf <| SetSelectedClauseType clauseType)
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
