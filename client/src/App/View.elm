module App.View exposing (..)

import App.Model exposing (..)
import App.Update exposing (..)
import Html exposing (..)
import Html.App as Html
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import States.EditDoc
import States.Login
import States.PageNotFound


view : Model -> Html Msg
view model =
    div []
        [ viewHeader model
        , viewState model
        , viewFooter model
        ]


viewHeader : Model -> Html Msg
viewHeader model =
    case model.activeState of
        Login _ ->
            div [] []

        _ ->
            div [ class "app-header", attribute "role" "banner" ]
                [ div [ class "logo pull-left" ]
                    [ em [ class "logo-text" ]
                        [ a [ href "/" ]
                            [ span [ class "app-name" ] [ text "AssemblyWorks" ]
                            , text "City of Chicago Commemorative Resolutions"
                            ]
                        ]
                    ]
                , div [ class "new-button pull-right" ]
                    [ button [ class "usa-button usa-button-gray", onClick NewDoc ] [ text "New Resolution" ]
                    ]
                ]


viewState : Model -> Html Msg
viewState model =
    case model.activeState of
        Login state ->
            Html.map loginTranslator <| States.Login.view state

        EditDoc state ->
            Html.map editDocTranslator <| States.EditDoc.view state

        PageNotFound ->
            Html.map (always NoOp) <| States.PageNotFound.view


viewFooter : Model -> Html Msg
viewFooter model =
    footer [ class "app-footer", attribute "role" "contentinfo" ]
        [ div [ class "pull-right" ]
            [ text "Built by "
            , a
                [ href "https://opengovfoundation.org"
                ]
                [ text "The OpenGov Foundation" ]
            ]
        ]
