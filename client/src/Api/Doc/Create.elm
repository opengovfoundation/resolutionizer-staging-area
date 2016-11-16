module Api.Doc.Create exposing (..)

import Dict exposing (Dict)
import Doc
import Exts.Date
import Exts.Http
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline as Decode
import Json.Encode as Encode
import Regex
import RemoteData
import String


type alias Request =
    RemoteData.WebData ResponseData


type alias ResponseData =
    { id : Int
    , title : String
    , urls : ResponseUrls
    }


type alias ResponseUrls =
    { preview : String
    , original : String
    }


responseDataDecoder : Decode.Decoder ResponseData
responseDataDecoder =
    Decode.decode ResponseData
        |> Decode.required "id" Decode.int
        |> Decode.required "title" Decode.string
        |> Decode.required "urls" responseUrlsDecoder


responseUrlsDecoder : Decode.Decoder ResponseUrls
responseUrlsDecoder =
    Decode.decode ResponseUrls
        |> Decode.required "preview" Decode.string
        |> Decode.required "original" Decode.string


cmd : (Request -> msg) -> Doc.Model -> Cmd msg
cmd msg doc =
    Exts.Http.postJson (Decode.at [ "document" ] responseDataDecoder) "/api/v1/document" (Http.string <| encodeDocForRequest doc)
        |> RemoteData.asCmd
        |> Cmd.map msg


encodeDocForRequest : Doc.Model -> String
encodeDocForRequest doc =
    Encode.encode 0 <|
        Encode.object
            [ ( "document", encodeDoc doc )
            ]



-- General Document encoding functions


encodeDoc : Doc.Model -> Encode.Value
encodeDoc doc =
    Encode.object
        [ ( "template_name", Encode.string "Resolution" )
        , ( "title", Encode.string doc.title )
        , ( "data", encodeDocData doc )
        ]


encodeDocData : Doc.Model -> Encode.Value
encodeDocData doc =
    Encode.object
        [ ( "sponsors", Encode.list <| List.map (Encode.string << .name) <| List.sortBy .pos <| Dict.values doc.sponsors )
        , ( "meeting_date", Encode.string <| Maybe.withDefault "1970-01-01" <| Maybe.map Exts.Date.toRFC3339 doc.meetingDate )
        , ( "clauses"
          , Dict.values doc.clauses
                |> List.filter (not << String.isEmpty << String.trim << .content)
                |> List.sortBy .pos
                |> List.map (encodeDocClause doc)
                |> Encode.list
          )
        ]


encodeDocClause : Doc.Model -> Doc.Clause -> Encode.Value
encodeDocClause doc clause =
    Encode.object
        [ ( "type", Encode.string <| Doc.getDisplayNameForClauseType doc clause.ctype )
        , ( "content", Encode.string (sanitizeClauseContent doc clause.content) )
        ]


sanitizeClauseContent : Doc.Model -> String -> String
sanitizeClauseContent doc content =
    content
        |> String.trim
        |> stripClausePreface doc
        |> capitalizeFirstLetter
        |> stripTrailingJoinPhrase


stripClausePreface : Doc.Model -> String -> String
stripClausePreface doc clauseText =
    let
        replaceRegexStr =
            "^(" ++ (String.join "|" <| List.map .displayName <| Dict.values doc.validClauseTypes) ++ "), "

        replaceRegex =
            Regex.caseInsensitive (Regex.regex replaceRegexStr)
    in
        Regex.replace (Regex.AtMost 1) replaceRegex (\_ -> "") clauseText


capitalizeFirstLetter : String -> String
capitalizeFirstLetter string =
    String.toUpper (String.slice 0 1 string) ++ String.dropLeft 1 string


stripTrailingJoinPhrase : String -> String
stripTrailingJoinPhrase clauseText =
    let
        joinPhrases =
            [ "; and"
            , "; now, therefore"
            ]

        joinPhraseRegexStr =
            "(" ++ (String.join "|" joinPhrases) ++ ")$"

        joinPhraseRegex =
            Regex.caseInsensitive (Regex.regex joinPhraseRegexStr)
    in
        Regex.replace (Regex.AtMost 1) joinPhraseRegex (\_ -> "") clauseText
