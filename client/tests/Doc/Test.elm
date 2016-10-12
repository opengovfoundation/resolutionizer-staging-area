module Doc.Test exposing (..)

import Test exposing (..)
import Expect
import Doc.Model
import Doc.Fixtures
import Dict


all : Test
all =
    describe "Doc Tests"
        [ test "New clauses are sorted properly" <|
            \() ->
                Doc.Fixtures.emptyDoc
                    |> Doc.Model.addNewClause 1 "End" "The End"
                    |> Doc.Model.addNewClause 2 "Beginning" "The Beginning"
                    |> Doc.Model.addNewClause 3 "Middle" "The Middle"
                    |> (List.map .content << List.sortBy .pos << Dict.values << .clauses)
                    |> Expect.equal ["The Beginning", "The Middle", "The End"]
        ]
