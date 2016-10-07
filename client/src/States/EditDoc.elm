module States.EditDoc exposing (Msg, Route(..), State, stateToUrl, locationToRoute, update, init, view)

import Dict exposing (Dict)
import Doc.Model
import Exts.Date
import Exts.Dict
import Exts.Html.Events
import Exts.Http
import Exts.RemoteData as RemoteData
import Html exposing (..)
import Html.App as Html
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Keyed as Keyed
import Html.Lazy exposing (lazy, lazy2)
import Http
import Inputs.DateSelector
import Json.Decode as Decode
import Json.Decode.Pipeline as Decode
import Json.Encode as Encode
import Navigation exposing (Location)
import RouteUrl exposing (HistoryEntry(..), UrlChange)
import String
import Util
import Validate exposing (Validator)


type Route
    = Meta
    | Clauses
    | Preview


type alias State =
    { doc : Doc.Model.Model
    , dateSelector : Inputs.DateSelector.Model
    , selectedNewSponsor : Maybe String
    , selectedNewClauseType : Doc.Model.ClauseType
    , uid : Int
    , activeRoute : Route
    , urlPrefix : String
    , previewRequest : RemoteData.WebData DocumentCreateResponse
    }


type alias DocumentCreateResponse =
    { id : Int
    , title : String
    , urls : Dict String String
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
    | RequestPdf
    | DoPreview
    | PreviewResponse (RemoteData.WebData DocumentCreateResponse)


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
          , previewRequest = RemoteData.NotAsked
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
        else if locationMatch "/preview" then
            Just Preview
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

        DoPreview ->
            ( state, Cmd.batch <| List.map Util.msgToCmd [ SetActiveRoute Preview, RequestPdf ] )

        RequestPdf ->
            let
                -- TODO: all of this should be broken out into a Api.Document module or similar
                body =
                    Encode.encode 0 <|
                        Encode.object
                            [ ( "document", encodeDoc state.doc )
                            ]

                encodeDoc doc =
                    Encode.object
                        [ ( "template_name", Encode.string "Resolution" )
                        , ( "title", Encode.string doc.title )
                        , ( "data", encodeDocData doc )
                        ]

                encodeDocData doc =
                    Encode.object
                        [ ( "sponsors", Encode.list <| List.map (Encode.string << .name) <| List.sortBy .pos <| Dict.values doc.sponsors )
                        , ( "meeting_date", Encode.string <| Maybe.withDefault "1970-01-01" <| Maybe.map Exts.Date.toRFC3339 doc.meetingDate )
                        , ( "clauses", Encode.list <| List.map (encodeDocClause doc) <| List.sortBy .pos <| Dict.values doc.clauses )
                        ]

                encodeDocClause doc clause =
                    Encode.object
                        [ ( "type", Encode.string <| getDisplayNameForClauseType doc clause.ctype )
                        , ( "content", Encode.string clause.content )
                        ]

                cmd =
                    Exts.Http.postJson (Decode.at [ "document" ] documentCreateResponseDecoder) "/api/v1/document" (Http.string body)
                        |> RemoteData.asCmd
                        |> Cmd.map PreviewResponse
            in
                ( state, cmd )

        PreviewResponse data ->
            { state | previewRequest = data } ! []


documentCreateResponseDecoder : Decode.Decoder DocumentCreateResponse
documentCreateResponseDecoder =
    Decode.decode DocumentCreateResponse
        |> Decode.required "id" Decode.int
        |> Decode.required "title" Decode.string
        |> Decode.required "urls" (Decode.dict Decode.string)


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

        Preview ->
            viewPreviewRoute state


viewMetaRoute : State -> Html Msg
viewMetaRoute state =
    div []
        [ p [] [ text "Enter the details of the Commemorative Resolution below" ]
        , viewMeta state
        , lazy (viewNextButton validateMeta (SetActiveRoute Clauses) "Continue") state.doc
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
        , lazy viewClauses state.doc
        , lazy2 viewClauseTypeSelector state.doc state.selectedNewClauseType
        , lazy (viewNextButton validateClauses DoPreview "Preview") state.doc
        ]


viewPreviewRoute : State -> Html Msg
viewPreviewRoute state =
    div []
        [ viewPreviewRequest state.previewRequest
        ]


viewPreviewRequest : RemoteData.WebData DocumentCreateResponse -> Html Msg
viewPreviewRequest request =
    case request of
        RemoteData.NotAsked ->
            text "Processing..."

        RemoteData.Loading ->
            text "Loading..."

        RemoteData.Failure err ->
            text "Failed"

        RemoteData.Success { id, urls } ->
            div []
                [ img [ class "document-preview-image img-responsive", src (Maybe.withDefault "" <| Dict.get "preview" urls) ] []
                , a [ class "usa-button", href (Maybe.withDefault "" <| Dict.get "original" urls) ] [ text "Download PDF" ]
                ]


viewMeta : State -> Html Msg
viewMeta state =
    div [ class "form-horizontal" ]
        [ div [ class "usa-grid-full" ]
            [ label [ for "title", class "usa-width-one-sixth" ] [ text "Resolution Title" ]
            , textarea [ id "title", value state.doc.title, onInput UpdateTitle, class "usa-width-five-sixths" ] []
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
    text <| getDisplayNameForClauseType doc clauseType


getDisplayNameForClauseType : Doc.Model.Model -> Doc.Model.ClauseType -> String
getDisplayNameForClauseType doc clauseType =
    Maybe.withDefault "ERROR" <|
        Maybe.map .displayName <|
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


viewNextButton : Validator String Doc.Model.Model -> Msg -> String -> Doc.Model.Model -> Html Msg
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


validateMeta : Validator String Doc.Model.Model
validateMeta =
    Validate.all
        [ .title >> Validate.ifBlank "Please enter a title."
        , .meetingDate >> Validate.ifNothing "Please choose a meeting date."
        , .sponsors >> Validate.ifEmptyDict "Please choose at least one sponsor."
        ]


validateClauses : Validator String Doc.Model.Model
validateClauses =
    Validate.all
        [ .clauses >> Validate.ifInvalid (not << validateClauseTypes) "Please enter at least one of each clause type."
        ]


validateClauseTypes : Dict comparable Doc.Model.Clause -> Bool
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
