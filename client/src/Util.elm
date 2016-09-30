module Util exposing (..)

import Task exposing (Task)


{-| Sometimes you need to emit a Msg inside an `update` function. Generally to
send a message to a parent or to kickoff some other behavior in the same module.
The later is generally better served just calling the `update` function
recursively (the [elm-update-extra
package](http://package.elm-lang.org/packages/ccapndave/elm-update-extra/2.0.0/Update-Extra)
can help make this nicer), but you could use this instead.
-}
msgToCmd : msg -> Cmd msg
msgToCmd msg =
    Task.perform (always msg) (always msg) (Task.succeed ())


{-| Command the runtime system to perform a task that is guaranteed to
not fail. The most important argument is the
[`Task`](http://package.elm-lang.org/packages/elm-lang/core/latest/Task#Task)
which describes what you want to happen. But you also need to provide
a function to tag the success outcome, so as to have a message to feed
back into your application. Unlike with the standard
[`perform`](http://package.elm-lang.org/packages/elm-lang/core/latest/Task#perform),
you need not provide a function to tag a failing outcome, because the
[`Never`](http://package.elm-lang.org/packages/elm-lang/core/latest/Basics#Never)
in the type `Task Never a` expresses that no possibly failing task is
allowed in that place anyway.
A typical use of the function is `Date.now |> performFailproof CurrentDate`.

Taken from http://package.elm-lang.org/packages/NoRedInk/elm-task-extra
-}
performFailproof : (a -> msg) -> Task Never a -> Cmd msg
performFailproof =
    -- from http://package.elm-lang.org/packages/NoRedInk/elm-task-extra
    Task.perform never


{-| The empty function.
This converts a value of type
[`Never`](http://package.elm-lang.org/packages/elm-lang/core/latest/Basics#Never)
into a value of any type, which is safe because there are no values of
type `Never`. Useful in certain situations as argument to
[`Task.perform`](http://package.elm-lang.org/packages/elm-lang/core/latest/Task#perform)
and
[`Html.App.map`](http://package.elm-lang.org/packages/elm-lang/html/latest/Html-App#map).
*Note:* To use this function, its argument need not be literally of type
`Never`.
It suffices if it is a fully polymorphic value. For example, this works:
`Process.sleep >> Task.perform never (\() -> ...)`, because the output of
[`Process.sleep`](http://package.elm-lang.org/packages/elm-lang/core/latest/Process#sleep)
is fully polymorphic in the `x` of `Task x ()`.

Taken from http://package.elm-lang.org/packages/elm-community/basics-extra
-}
never : Never -> a
never n =
    never n
