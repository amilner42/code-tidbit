module Elements.Tags exposing (..)

import Html exposing (Html, div, button, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)


{-| Creates a list of cancelable tabs.
-}
tags : (String -> msg) -> List String -> Html msg
tags closeTagMsg tags =
    div
        [ class "current-tags" ]
        (List.map
            (\tagName ->
                div
                    [ class "tag" ]
                    [ text tagName
                    , button
                        [ onClick <| closeTagMsg tagName ]
                        [ text "X" ]
                    ]
            )
            tags
        )
