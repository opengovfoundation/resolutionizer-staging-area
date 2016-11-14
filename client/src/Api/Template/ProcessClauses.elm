module Api.Template.ProcessClauses exposing (..)

import HttpBuilder
import Json.Decode as Decode
import Json.Decode.Pipeline as Decode
import RemoteData


type alias Response =
    List ResponseClause


type alias ResponseClause =
    { ctype : String
    , content : String
    }


responseDecoder : Decode.Decoder Response
responseDecoder =
    Decode.list responseClauseDecoder


responseClauseDecoder : Decode.Decoder ResponseClause
responseClauseDecoder =
    Decode.decode ResponseClause
        |> Decode.required "type" Decode.string
        |> Decode.required "content" Decode.string


{-| TODO: this should also take a Doc and validate that the clause types received
    are correct
-}
cmd : (RemoteData.RemoteData (HttpBuilder.Error String) (HttpBuilder.Response Response) -> msg) -> String -> Cmd msg
cmd msg content =
    HttpBuilder.post "/api/v1/templates/process_clauses"
        |> HttpBuilder.withStringBody content
        |> HttpBuilder.withHeader "Content-Type" "text/plain"
        |> HttpBuilder.send (HttpBuilder.jsonReader responseDecoder) HttpBuilder.stringReader
        |> RemoteData.asCmd
        |> Cmd.map msg
