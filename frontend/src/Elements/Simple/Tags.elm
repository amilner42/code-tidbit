module Elements.Simple.Tags exposing (..)

import Html exposing (Html, button, div, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)


view : (String -> msg) -> List String -> Html msg
view closeTagMsg tags =
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
