module Doc.Test exposing (..)

import Test exposing (..)
import Expect
import Doc
import Doc.Fixtures
import Dict


all : Test
all =
    describe "Doc Tests"
        [ test "New clauses are sorted properly" <|
            \() ->
                Doc.Fixtures.emptyDoc
                    |> Doc.addNewClause 1 "End" "The End"
                    |> Doc.addNewClause 2 "Beginning" "The Beginning"
                    |> Doc.addNewClause 3 "Middle" "The Middle"
                    |> (List.map .content << List.sortBy .pos << Dict.values << .clauses)
                    |> Expect.equal ["The Beginning", "The Middle", "The End"]
        ]
