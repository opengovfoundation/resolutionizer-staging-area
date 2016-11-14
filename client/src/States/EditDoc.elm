module States.EditDoc
    exposing
        ( Msg
        , Internal
        , Route(..)
        , State
        , stateToUrl
        , locationToRoute
        , doRoute
        , translator
        , Dictionary
        , Tagger
        , update
        , init
        , view
        )

import Api.Doc
import Api.Template.ProcessClauses
import Date exposing (Date)
import Date.Extra as Date exposing (Interval(..))
import Dict exposing (Dict)
import Doc
import Dom
import Exts.Dict
import Exts.Html.Events
import Exts.Maybe
import Html exposing (..)
import Html.App as Html
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Lazy exposing (lazy, lazy2)
import Http
import HttpBuilder
import Inputs.DateSelector
import Json.Decode as Decode
import Navigation exposing (Location)
import RemoteData
import RouteUrl exposing (HistoryEntry(..), UrlChange)
import String
import Task
import Util
import Validate exposing (Validator)


type Route
    = Meta
    | Clauses
    | ClausesBulk
    | Preview


type alias State =
    { doc : Doc.Model
    , dateSelector : Inputs.DateSelector.Model
    , sponsorInputs : Dict Int SponsorInput
    , selectedNewClauseType : Doc.ClauseType
    , uid : Int
    , activeRoute : Route
    , urlPrefix : String
    , previewRequest : RemoteData.WebData Api.Doc.CreateResponse
    , bulkClauseInput : String
    , bulkClauseRequest : RemoteData.RemoteData (HttpBuilder.Error String) (HttpBuilder.Response Api.Template.ProcessClauses.Response)
    }


type alias SponsorInput =
    { value : Maybe String
    , pos : Int
    }


type Outgoing
    = HistoryBack


type Internal
    = SetSelectedClauseType Doc.ClauseType
    | UpdateTitle String
    | NewClause
    | UpdateClause Int String
    | DeleteClause Int
    | SetActiveRoute Route
    | NewSponsorInput
    | SponsorInputChange Int (Maybe String)
    | DateSelectorMsg Inputs.DateSelector.Internal
    | MeetingDateSelected Date
    | NoOp
    | RequestPdf
    | DoPreview
    | PreviewResponse (RemoteData.WebData Api.Doc.CreateResponse)
    | UpdateBulkClauseInput String
    | SubmitBulk
    | BulkResponse (RemoteData.RemoteData (HttpBuilder.Error String) (HttpBuilder.Response Api.Template.ProcessClauses.Response))


type Msg
    = InMsg Internal
    | OutMsg Outgoing


type alias Dictionary msg =
    { onInternalMessage : Internal -> msg
    , onHistoryBack : msg
    }


type alias Tagger parentMsg =
    Msg -> parentMsg


translator : Dictionary parentMsg -> Tagger parentMsg
translator { onInternalMessage, onHistoryBack } msg =
    case msg of
        InMsg internal ->
            onInternalMessage internal

        OutMsg HistoryBack ->
            onHistoryBack


dateSelectorDictionary : Inputs.DateSelector.Dictionary Internal
dateSelectorDictionary =
    { onInternalMessage = DateSelectorMsg
    , onDateSelected = MeetingDateSelected
    }


dateSelectorTagger : Inputs.DateSelector.Tagger Internal
dateSelectorTagger =
    Inputs.DateSelector.translator dateSelectorDictionary


init : Doc.Model -> ( State, Cmd Msg )
init doc =
    let
        lastMeetingDateTask =
            Http.get
                (Decode.at [ "date" ]
                    (Decode.customDecoder Decode.string
                        (Result.fromMaybe "Date parsing error" << Date.fromIsoString)
                    )
                )
                "/api/v1/templates/last_meeting_date"
                |> Task.toMaybe

        dateSelectorBaseConfig =
            Inputs.DateSelector.usConfig

        ( dateSelectorModel, dateSelectorCmd ) =
            Inputs.DateSelector.init
                { dateSelectorBaseConfig
                    | defaultTo =
                        Inputs.DateSelector.Run lastMeetingDateTask
                    , inputName = "meeting-date"
                    , maxDate = Date.add Year 1
                }

        uidAfterDoc =
            Dict.size doc.clauses + Dict.size doc.sponsors

        initSponsorInputs =
            Dict.fromList <|
                List.indexedMap
                    (\idx val ->
                        ( uidAfterDoc + idx, val )
                    )
                    [ { value = Nothing, pos = 1 }
                    ]
    in
        ( { doc = doc
          , dateSelector = dateSelectorModel
          , sponsorInputs = initSponsorInputs
          , selectedNewClauseType = doc.defaultClauseType
          , uid = uidAfterDoc + Dict.size initSponsorInputs
          , activeRoute = Meta
          , urlPrefix = "/new"
          , previewRequest = RemoteData.NotAsked
          , bulkClauseInput = ""
          , bulkClauseRequest = RemoteData.NotAsked
          }
        , Cmd.map (InMsg << dateSelectorTagger) dateSelectorCmd
        )


stateToUrl : State -> Maybe UrlChange
stateToUrl state =
    case state.activeRoute of
        Meta ->
            Just <| UrlChange NewEntry (state.urlPrefix ++ "/meta")

        Clauses ->
            Just <| UrlChange NewEntry (state.urlPrefix ++ "/clauses")

        ClausesBulk ->
            Just <| UrlChange NewEntry (state.urlPrefix ++ "/clauses/bulk")

        Preview ->
            Just <| UrlChange NewEntry (state.urlPrefix ++ "/preview")


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
        else if locationMatch "/clauses/bulk" then
            Just ClausesBulk
        else if locationMatch "/preview" then
            Just Preview
        else
            Nothing


update : Internal -> State -> ( State, Cmd Msg )
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
                ( newDoc, newClause ) =
                    Doc.addNewClause state.uid state.selectedNewClauseType "" state.doc
            in
                ( { state
                    | uid = state.uid + 1
                    , doc = newDoc
                  }
                  -- attempt to move focus to the new input, this could be a
                  -- little race-y, but seems to work in practice, can always
                  -- add a delay to mitigate situations where it doesn't work if
                  -- they come up or actually handle the failure case and retry
                  -- a few times
                , Task.perform (always <| InMsg NoOp) (always <| InMsg NoOp) (Dom.focus (clauseHtmlId newClause))
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

        NewSponsorInput ->
            ( { state
                | uid = state.uid + 1
                , sponsorInputs = Dict.insert state.uid ({ value = Nothing, pos = (Dict.size state.doc.sponsors) + 1 }) state.sponsorInputs
              }
            , Cmd.none
            )

        SponsorInputChange id mSponsorName ->
            let
                updateSponsorInput state =
                    { state | sponsorInputs = Dict.update id (Maybe.map (\s -> { s | value = mSponsorName })) state.sponsorInputs }

                updateDocSponsors state =
                    case mSponsorName of
                        Nothing ->
                            { state | doc = deleteSponsor id state.doc }

                        Just sponsorName ->
                            { state | doc = insertOrUpdateSponsor sponsorName (Dict.get id state.sponsorInputs) state.doc }

                updateSponsor sponsorName =
                    Maybe.map (\s -> { s | name = sponsorName })

                insertOrUpdateSponsor sponsorName mSponsorInput doc =
                    if Dict.member id doc.sponsors then
                        { doc | sponsors = Dict.update id (updateSponsor sponsorName) doc.sponsors }
                    else
                        case mSponsorInput of
                            Nothing ->
                                doc

                            Just sponsorInput ->
                                { doc | sponsors = Dict.insert id (Doc.newSponsor sponsorInput.pos sponsorName) doc.sponsors }

                deleteSponsor id doc =
                    { doc | sponsors = Dict.remove id doc.sponsors }
            in
                ( state
                    |> updateSponsorInput
                    |> updateDocSponsors
                , Cmd.none
                )

        DateSelectorMsg msg' ->
            let
                ( dateSelectorModel, dateSelectorCmd ) =
                    Inputs.DateSelector.update msg' state.dateSelector
            in
                ( { state | dateSelector = dateSelectorModel }, Cmd.map (InMsg << dateSelectorTagger) dateSelectorCmd )

        MeetingDateSelected date ->
            let
                doc =
                    state.doc

                newDoc =
                    { doc | meetingDate = Just date }
            in
                ( { state | doc = newDoc }, Cmd.none )

        NoOp ->
            ( state, Cmd.none )

        DoPreview ->
            ( state, Cmd.map InMsg <| Cmd.batch <| List.map Util.msgToCmd [ SetActiveRoute Preview, RequestPdf ] )

        RequestPdf ->
            ( { state | previewRequest = RemoteData.Loading }, Api.Doc.create (InMsg << PreviewResponse) state.doc )

        PreviewResponse data ->
            { state | previewRequest = data } ! []

        UpdateBulkClauseInput content ->
            { state | bulkClauseInput = content } ! []

        SubmitBulk ->
            ( { state | bulkClauseRequest = RemoteData.Loading }, Api.Template.ProcessClauses.cmd (InMsg << BulkResponse) state.bulkClauseInput )

        BulkResponse data ->
            let
                newClauses =
                    case data of
                        RemoteData.Success resp ->
                            resp.data

                        _ ->
                            []

                ( newDoc, newUid ) =
                    Doc.replaceClauses state.uid newClauses state.doc
            in
                case data of
                    RemoteData.Success _ ->
                        ( { state
                            | uid = newUid
                            , doc = newDoc
                            , bulkClauseRequest = data
                          }
                        , Util.msgToCmd (InMsg <| SetActiveRoute Clauses)
                        )

                    _ ->
                        { state | bulkClauseRequest = data } ! []


doRoute : Route -> Maybe State -> ( State, Cmd Msg )
doRoute route mState =
    case mState of
        Nothing ->
            -- Entering EditDoc from another state
            init Doc.emptyDoc

        Just state ->
            -- Changing routes inside an EditDoc state
            doInternalRouteChange route state


doInternalRouteChange : Route -> State -> ( State, Cmd Msg )
doInternalRouteChange route state =
    let
        allowRouteChange =
            ( { state | activeRoute = route }, Cmd.none )

        rejectRouteChange =
            ( state, Cmd.none )

        allowIf validate =
            if (List.isEmpty <| validate state.doc) then
                allowRouteChange
            else
                rejectRouteChange
    in
        case state.activeRoute of
            Meta ->
                -- You can only go to the clauses from the meta route and only
                -- if the data is valid
                case route of
                    Clauses ->
                        allowIf validateMeta

                    _ ->
                        rejectRouteChange

            Clauses ->
                -- You can go backwards to meta route safely or forward to the
                -- preview route only if the data is valid
                case route of
                    Meta ->
                        allowRouteChange

                    Clauses ->
                        rejectRouteChange

                    ClausesBulk ->
                        allowRouteChange

                    Preview ->
                        allowIf validateClauses

            ClausesBulk ->
                -- You can go backwards to meta route safely or forward to the
                -- preview route only if the data is valid
                case route of
                    Meta ->
                        allowRouteChange

                    Clauses ->
                        allowRouteChange

                    ClausesBulk ->
                        rejectRouteChange

                    Preview ->
                        allowIf validateClauses

            Preview ->
                -- You can navigate to anywhere from the Preview route
                allowRouteChange


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

        ClausesBulk ->
            viewClauseBulkRoute state

        Preview ->
            viewPreviewRoute state


viewMetaRoute : State -> Html Msg
viewMetaRoute state =
    div []
        [ p [] [ text "Enter the details of the Commemorative Resolution below." ]
        , viewMeta state
        , lazy (viewNextButton validateMeta (InMsg <| SetActiveRoute Clauses) "Continue") state.doc
        ]


viewClauseRoute : State -> Html Msg
viewClauseRoute state =
    div []
        [ p [] [ text "Enter the text for the resolution's clauses below." ]
        , p []
            [ text "For each additional clause that is needed, select the type of clause to be added and then enter the text. The clause types are "
            , strong [] [ text "Whereas" ]
            , text ", "
            , strong [] [ text "Be it resolved" ]
            , text ", and "
            , strong [] [ text "Be it further resolved" ]
            , text "."
            ]
        , button [ class "usa-button", onClick (InMsg <| SetActiveRoute ClausesBulk) ] [ text "Bulk import" ]
        , lazy viewClauses state.doc
        , lazy2 viewClauseTypeSelector state.doc state.selectedNewClauseType
        , lazy (viewNextButton validateClauses (InMsg <| DoPreview) "Preview") state.doc
        , viewBackButton
        ]


viewClauseBulkRoute : State -> Html Msg
viewClauseBulkRoute state =
    viewClauseBulkRequest state


viewClauseBulkRequest : State -> Html Msg
viewClauseBulkRequest state =
    let
        viewInput msg =
            div []
                [ p [] [ text "Paste a block of text into the input below then click the submit button" ]
                , p [] [ text msg ]
                , textarea [ id "bulk-input", value state.bulkClauseInput, onInput (InMsg << UpdateBulkClauseInput), class "usa-width-five-sixths" ] []
                , button [ class "usa-button", onClick (InMsg <| SubmitBulk) ] [ text "Submit" ]
                ]
    in
        case state.bulkClauseRequest of
            RemoteData.NotAsked ->
                viewInput ""

            RemoteData.Loading ->
                text "Processing..."

            RemoteData.Failure err ->
                case err of
                    HttpBuilder.BadResponse resp ->
                        viewInput resp.data

                    _ ->
                        viewInput "Having trouble."

            RemoteData.Success _ ->
                viewInput "Success!"


viewPreviewRoute : State -> Html Msg
viewPreviewRoute state =
    div []
        [ viewPreviewRequest state.previewRequest
        ]


viewPreviewRequest : RemoteData.WebData Api.Doc.CreateResponse -> Html Msg
viewPreviewRequest request =
    case request of
        RemoteData.NotAsked ->
            text "Processing..."

        RemoteData.Loading ->
            text "Processing..."

        RemoteData.Failure err ->
            text "Failed"

        RemoteData.Success { id, urls } ->
            div []
                [ img [ class "document-preview-image img-responsive", src urls.preview ] []
                , viewBackButton
                , a [ class "usa-button", href urls.original ] [ text "Download PDF" ]
                ]


viewMeta : State -> Html Msg
viewMeta state =
    div [ class "form-horizontal" ]
        [ div [ class "usa-grid-full" ]
            [ label [ for "title", class "usa-width-one-sixth" ] [ text "Resolution Title" ]
            , textarea [ id "title", value state.doc.title, onInput (InMsg << UpdateTitle), class "usa-width-five-sixths" ] []
            ]
        , div []
            [ label [ for "meeting-date", class "usa-width-one-sixth" ] [ text "Meeting Date" ]
            , Html.map (InMsg << dateSelectorTagger) <| Inputs.DateSelector.view state.dateSelector
            ]
        , viewSponsors state
        ]


viewSponsors : State -> Html Msg
viewSponsors state =
    fieldset [ class "usa-grid-full" ]
        [ legend [ class "usa-width-one-sixth" ] [ text "Sponsors" ]
        , div [ class "usa-width-five-sixths" ]
            [ viewSponsorSelectors state
            , button
                [ class "usa-button-plain add-sponsor"
                , onClick
                    (InMsg <|
                        NewSponsorInput
                    )
                ]
                [ text "Add sponsor" ]
            ]
        ]


viewSponsorSelectors : State -> Html Msg
viewSponsorSelectors state =
    lazy
        (div []
            << List.map (\( id, sponsorInput ) -> sponsorSelect state.doc sponsorInput.value (InMsg << SponsorInputChange id))
            << List.sortBy (.pos << snd)
            << Dict.toList
        )
        state.sponsorInputs


sponsorSelect : Doc.Model -> Maybe String -> (Maybe String -> Msg) -> Html Msg
sponsorSelect doc mSelectedSponsor toMsg =
    let
        alreadyPresentSponsorNames =
            List.map .name <| Dict.values doc.sponsors

        shouldKeepSponsor sponsorName =
            if (Just sponsorName) == mSelectedSponsor then
                -- If this sponsor is the one selected for this input, then of
                -- course, keep them
                True
            else
                -- If this sponsor is *not* the one selected for this input and
                -- is selected elsewhere, then don't allow them
                not <| List.member sponsorName alreadyPresentSponsorNames

        nonDuplicateSponsors =
            List.filter shouldKeepSponsor doc.validSponsors
    in
        select [ Exts.Html.Events.onSelect toMsg ] <|
            (++) [ option [ value "", selected (Exts.Maybe.isNothing mSelectedSponsor) ] [ text "-- Select Sponsor --" ] ] <|
                List.map
                    (\sponsor ->
                        option
                            [ selected ((Just sponsor) == mSelectedSponsor)
                            ]
                            [ text sponsor ]
                    )
                    nonDuplicateSponsors


viewClauses : Doc.Model -> Html Msg
viewClauses doc =
    div [] <|
        List.map (viewClause doc) <|
            List.sortBy .pos <|
                Dict.values <|
                    doc.clauses


viewClause : Doc.Model -> Doc.Clause -> Html Msg
viewClause doc clause =
    let
        clauseId =
            clauseHtmlId clause
    in
        div [ class "clause-wrapper" ]
            [ div [ class "clause" ]
                [ label [ class "clause-label", for clauseId ] [ clauseTypeFormatter doc clause.ctype ]
                , button
                    [ class "usa-button-plain delete"
                    , onClick (InMsg <| DeleteClause clause.id)
                    ]
                    []
                , textarea
                    [ id clauseId
                    , value clause.content
                    , onInput (InMsg << UpdateClause clause.id)
                    ]
                    []
                ]
            ]


viewClauseTypeSelector : Doc.Model -> Doc.ClauseType -> Html Msg
viewClauseTypeSelector doc selectedNewClauseType =
    div [ class "add-selector" ]
        [ clauseTypeSelect doc selectedNewClauseType
        , button [ class "usa-button-plain add", onClick (InMsg <| NewClause) ] []
        ]


clauseTypeSelect : Doc.Model -> Doc.ClauseType -> Html Msg
clauseTypeSelect doc selectedClauseType =
    let
        determineSelectedClauseType =
            Maybe.withDefault doc.defaultClauseType << flip Maybe.andThen (Doc.getClauseTypeFromDisplayName doc)
    in
        select [ Exts.Html.Events.onSelect (InMsg << SetSelectedClauseType << determineSelectedClauseType) ] <|
            List.map
                (\clauseType ->
                    option
                        [ selected (clauseType == selectedClauseType)
                        ]
                        [ clauseTypeFormatter doc clauseType ]
                )
                (Dict.keys doc.validClauseTypes)


clauseTypeFormatter : Doc.Model -> Doc.ClauseType -> Html msg
clauseTypeFormatter doc clauseType =
    text <| Doc.getDisplayNameForClauseType doc clauseType


viewNextButton : Validator String Doc.Model -> Msg -> String -> Doc.Model -> Html Msg
viewNextButton validate onClickValidMsg btnText doc =
    let
        errors =
            validate doc
    in
        button
            [ classList
                [ ( "pull-right", True )
                , ( "usa-button-disabled", not <| List.isEmpty errors )
                ]
            , onClick onClickValidMsg
            ]
            [ text btnText ]


viewBackButton : Html Msg
viewBackButton =
    button
        [ class "pull-left usa-button usa-button-outline"
        , onClick (OutMsg HistoryBack)
        ]
        [ text "Back" ]


validateMeta : Validator String Doc.Model
validateMeta =
    Validate.all
        [ .title >> Validate.ifBlank "Please enter a title."
        , .meetingDate >> Validate.ifNothing "Please choose a meeting date."
        , .sponsors >> Validate.ifEmptyDict "Please choose at least one sponsor."
        ]


validateClauses : Validator String Doc.Model
validateClauses =
    Validate.all
        [ .clauses >> Validate.ifInvalid (not << validateClauseTypes) "Please enter at least one of each clause type."
        ]


validateClauseTypes : Dict comparable Doc.Clause -> Bool
validateClauseTypes clauses =
    let
        foldFunc _ clause acc =
            if Exts.Dict.getWithDefault False clause.ctype acc then
                acc
            else if not (String.isEmpty clause.content) then
                Dict.insert clause.ctype True acc
            else
                acc
    in
        clauses
            |> Dict.foldl foldFunc Dict.empty
            |> dictKeysExist
                [ "Whereas"
                , "BeItResolved"
                ]


dictKeysExist : List comparable -> Dict comparable Bool -> Bool
dictKeysExist requireds dict =
    List.map (flip Dict.member dict) requireds
        |> List.all ((==) True)


clauseHtmlId : Doc.Clause -> String
clauseHtmlId clause =
    "clause-" ++ toString clause.id
