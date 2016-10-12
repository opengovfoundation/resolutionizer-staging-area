module Api.Doc exposing (..)

import Dict exposing (Dict)
import Doc.Model
import Http
import Exts.Date
import Exts.Http
import Exts.RemoteData as RemoteData
import Json.Decode as Decode
import Json.Decode.Pipeline as Decode
import Json.Encode as Encode


type alias CreateResponse =
    { id : Int
    , title : String
    , urls : CreateResponseUrls
    }


type alias CreateResponseUrls =
    { preview : String
    , original : String
    }


createResponseDecoder : Decode.Decoder CreateResponse
createResponseDecoder =
    Decode.decode CreateResponse
        |> Decode.required "id" Decode.int
        |> Decode.required "title" Decode.string
        |> Decode.required "urls" createResponseUrlsDecoder


createResponseUrlsDecoder : Decode.Decoder CreateResponseUrls
createResponseUrlsDecoder =
    Decode.decode CreateResponseUrls
        |> Decode.required "preview" Decode.string
        |> Decode.required "original" Decode.string


create : (RemoteData.WebData CreateResponse -> msg) -> Doc.Model.Model -> Cmd msg
create msg doc =
    Exts.Http.postJson (Decode.at [ "document" ] createResponseDecoder) "/api/v1/document" (Http.string <| encodeDocForCreate doc)
        |> RemoteData.asCmd
        |> Cmd.map msg


encodeDocForCreate : Doc.Model.Model -> String
encodeDocForCreate doc =
    Encode.encode 0 <|
        Encode.object
            [ ( "document", encodeDoc doc )
            ]


encodeDoc : Doc.Model.Model -> Encode.Value
encodeDoc doc =
    Encode.object
        [ ( "template_name", Encode.string "Resolution" )
        , ( "title", Encode.string doc.title )
        , ( "data", encodeDocData doc )
        ]


encodeDocData : Doc.Model.Model -> Encode.Value
encodeDocData doc =
    Encode.object
        [ ( "sponsors", Encode.list <| List.map (Encode.string << .name) <| List.sortBy .pos <| Dict.values doc.sponsors )
        , ( "meeting_date", Encode.string <| Maybe.withDefault "1970-01-01" <| Maybe.map Exts.Date.toRFC3339 doc.meetingDate )
        , ( "clauses", Encode.list <| List.map (encodeDocClause doc) <| List.sortBy .pos <| Dict.values doc.clauses )
        ]


encodeDocClause : Doc.Model.Model -> Doc.Model.Clause -> Encode.Value
encodeDocClause doc clause =
    Encode.object
        [ ( "type", Encode.string <| Doc.Model.getDisplayNameForClauseType doc clause.ctype )
        , ( "content", Encode.string clause.content )
        ]
