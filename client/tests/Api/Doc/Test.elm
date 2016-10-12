module Api.Doc.Test exposing (all)

import Test exposing (..)
import Expect
import Doc.Model
import Doc.Fixtures
import Api.Doc
import TestUtil exposing (outdented)
import Dict
import Json.Decode as Decode


all : Test
all =
    describe "Api Doc Tests"
        [ encodesForCreate
        , decodesForCreate
        ]


encodesForCreate : Test
encodesForCreate =
    test "Encodes correctly for create request" <|
        \() ->
            Doc.Fixtures.emptyDoc
                |> (\doc -> { doc | title = "Test" })
                |> (\doc -> { doc | sponsors = Dict.insert 1 (Doc.Model.newSponsor 1 "Tester") doc.sponsors })
                |> Doc.Model.addNewClause 2 "Beginning" "Test phrase"
                |> Api.Doc.encodeDocForCreate
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


decodesForCreate : Test
decodesForCreate =
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
                case Decode.decodeString Api.Doc.createResponseDecoder input of
                    Ok value ->
                        Expect.equal output value

                    Err err ->
                        Expect.fail err
