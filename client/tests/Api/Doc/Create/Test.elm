module Api.Doc.Create.Test exposing (all)

import Api.Doc.Create
import Dict
import Doc
import Doc.Fixtures
import Expect
import Json.Decode as Decode
import Test exposing (..)
import TestUtil exposing (outdented)


all : Test
all =
    describe "Api Doc Create Tests"
        [ encodesDoc
        , decodesResponse
        ]


encodesDoc : Test
encodesDoc =
    test "Encodes correctly for create request" <|
        \() ->
            Doc.Fixtures.emptyDoc
                |> (\doc -> { doc | title = "Test" })
                |> (\doc -> { doc | sponsors = Dict.insert 1 (Doc.newSponsor 1 "Tester") doc.sponsors })
                |> (fst << Doc.addNewClause 2 "Beginning" "Test phrase")
                |> Api.Doc.Create.encodeDocForRequest
                |> Expect.equal (outdented """
                      {
                        "document":
                          {
                            "template_name":"Resolution",
                            "title":"Test",
                            "data":
                            {
                              "sponsors":["Tester"],
                              "meeting_date":"1970-01-01",
                              "clauses":
                              [
                                {
                                  "type":"The Beginning",
                                  "content":"Test phrase"
                                }
                              ]
                            }
                          }
                      }
                    """)


decodesResponse : Test
decodesResponse =
    let
        input =
            """
              { "id": 5
              , "title": "Test"
              , "urls":
                { "preview": "https://example.com/preview"
                , "original": "https://example.com/original"
                }
              }
            """

        output =
            { id = 5
            , title = "Test"
            , urls =
                { preview = "https://example.com/preview"
                , original = "https://example.com/original"
                }
            }
    in
        test "Decodes correctly for create response" <|
            \() ->
                input
                    |> Decode.decodeString Api.Doc.Create.responseDecoder
                    |> Expect.equal (Ok output)
