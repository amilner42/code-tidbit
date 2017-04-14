module Elements.ContentBox exposing (..)

import Html exposing (Html, div, text)
import Html.Attributes exposing (class, classList)
import Html.Events exposing (onClick)
import Models.Content exposing (..)
import Models.Route as Route


{-| All the config for rendering some content.
-}
type alias RenderConfig msg =
    { goToMsg : Route.Route -> msg
    , darkenBox : Bool
    , forStory : Maybe String
    }


{-| A fully-styled content box.
-}
contentBox : RenderConfig msg -> Content -> Html msg
contentBox { goToMsg, darkenBox, forStory } content =
    div
        [ classList
            [ ( "content-box", True )
            , ( "snipbit", isSnipbit content )
            , ( "bigbit", isBigbit content )
            , ( "story", isStory content )
            ]
        , onClick <| goToMsg <| getRouteForViewing content forStory
        ]
        [ div [ classList [ ( "darkener", darkenBox ) ] ] []
        , div
            [ class "name" ]
            [ div
                [ class "vertically-centered-text" ]
                [ text <| getName content ]
            ]
        , div
            [ class "description" ]
            [ text <| getDescription content ]
        ]
