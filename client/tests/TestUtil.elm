module TestUtil exposing (..)

import String


{-|
Taken from https://github.com/rtfeldman/elm-css/blob/master/tests/TestUtil.elm
-}
outdented : String -> String
outdented str =
    str
        |> String.split "\n"
        |> List.map String.trim
        |> String.join ""
        |> String.trim
