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
