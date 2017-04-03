module Elements.ContentBox exposing (..)

import Html exposing (Html, div, text)
import Html.Attributes exposing (class, classList)
import Html.Events exposing (onClick)
import Models.Content exposing (..)
import Models.Route as Route


{-| A fully-styled content box.
-}
contentBox : (Route.Route -> msg) -> Content -> Html msg
contentBox goToMsg content =
    div
        [ classList
            [ ( "content-box", True )
            , ( "snipbit", isSnipbit content )
            , ( "bigbit", isBigbit content )
            , ( "story", isStory content )
            ]
        , onClick <| goToMsg <| getRouteForViewing content
        ]
        [ div
            [ class "name" ]
            [ div
                [ class "vertically-centered-text" ]
                [ text <| getName content ]
            ]
        , div
            [ class "description" ]
            [ text <| getDescription content ]
        ]
