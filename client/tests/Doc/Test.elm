module Doc.Test exposing (..)

import Dict
import Doc
import Doc.Fixtures
import Expect
import Test exposing (..)


all : Test
all =
    describe "Doc Tests"
        [ autoSortedClauses
        , replaceClauses
        ]


autoSortedClauses : Test
autoSortedClauses =
    let
        addDocClause a b c =
            fst << Doc.addNewClause a b c
    in
        test "New clauses are sorted properly" <|
            \() ->
                Doc.Fixtures.emptyDoc
                    |> addDocClause 1 "End" "The End"
                    |> addDocClause 2 "Beginning" "The Beginning"
                    |> addDocClause 3 "Middle" "The Middle"
                    |> (List.map .content << List.sortBy .pos << Dict.values << .clauses)
                    |> Expect.equal [ "The Beginning", "The Middle", "The End" ]


replaceClauses : Test
replaceClauses =
    let
        emptyDoc =
            Doc.Fixtures.emptyDoc

        doc =
            { emptyDoc
                | clauses =
                    Dict.fromList
                        [ ( 1
                          , { ctype = "Whereas"
                            , content = "This is a test"
                            , id = 1
                            , pos = 1
                            }
                          )
                        ]
            }
    in
        test "Replaces clauses work" <|
            \() ->
                doc
                    |> (fst
                            << Doc.replaceClauses 5
                                [ { ctype = "End", content = "Last clause" }
                                , { ctype = "Beginning", content = "New clause" }
                                , { ctype = "Beginning", content = "Another clause" }
                                , { ctype = "Middle", content = "Towards the end" }
                                ]
                       )
                    |> (List.map .content << List.sortBy .pos << Dict.values << .clauses)
                    |> Expect.equal [ "New clause", "Another clause", "Towards the end", "Last clause" ]
