module Tests exposing (..)

import Test exposing (..)
import Expect
import String
import Doc.Test
import Api.Doc.Create.Test


all : Test
all =
    describe "All Tests"
        [ Doc.Test.all
        , Api.Doc.Create.Test.all
        ]
