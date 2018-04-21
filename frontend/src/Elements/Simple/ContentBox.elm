module Elements.Simple.ContentBox exposing (..)

import DefaultServices.Util as Util
import Elements.Simple.Editor exposing (prettyPrintLanguages)
import Html exposing (Html, div, i, text)
import Html.Attributes exposing (class, classList)
import Models.Content exposing (..)
import Models.Route as Route


type alias RenderConfig msg =
    { goToMsg : Route.Route -> msg
    , darkenBox : Bool
    , forStory : Maybe String
    }


view : RenderConfig msg -> Content -> Html msg
view { goToMsg, darkenBox, forStory } content =
    let
        contentRoute =
            getRouteForViewing content forStory
    in
    Route.navigationNode
        (Just ( Route.Route contentRoute, goToMsg contentRoute ))
        [ classList
            [ ( "content-box", True )
            , ( "snipbit", isSnipbit content )
            , ( "bigbit", isBigbit content )
            , ( "story", isStory content )
            ]
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
        , div
            [ class "languages" ]
            [ div
                [ class "language-text" ]
                [ text <| prettyPrintLanguages <| getLanguages content ]
            ]
        , case content of
            Story { tidbitPointers } ->
                div
                    [ class "story-tidbit-count" ]
                    [ text <| Util.xThings "tidbit" "s" (List.length tidbitPointers) ]

            _ ->
                Util.hiddenDiv
        , div
            [ class "author" ]
            [ text <| getAuthorEmail content ]
        , div
            [ class "opinions" ]
            [ div
                [ class "likes" ]
                [ i [ class "material-icons" ] [ text "favorite" ]
                , div [ class "like-count" ] [ text <| toString <| getLikes content ]
                ]
            ]
        ]
