module Elements.ContentBox exposing (..)

import Html exposing (Html, div, text)
import Html.Attributes exposing (class, classList)
import Models.Content exposing (..)


{-| A fully-styled content box.
-}
contentBox : Content -> Html msg
contentBox content =
    div
        [ classList
            [ ( "content-box", True )
            , ( "snipbit", isSnipbit content )
            , ( "bigbit", isBigbit content )
            , ( "story", isStory content )
            ]
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
