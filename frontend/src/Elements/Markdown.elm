module Elements.Markdown exposing (..)

import Html exposing (Html, Attribute, div)
import Html.Attributes exposing (class)
import Markdown


{-| Because our markdown is from user-input, we need to sanitize the HTML.
Additionally, we keep everything github-styled.
-}
safeOptions =
    { githubFlavored = Just { tables = True, breaks = True }
    , defaultHighlighting = Nothing
    , sanitize = True
    , smartypants = True
    }


{-| Generates sanitized-github-style-markdown with the standard css classes for
the comment box.
-}
githubMarkdown : List (Attribute msg) -> String -> Html msg
githubMarkdown extraAttr markdownText =
    div
        ([ class "markdown-box" ] ++ extraAttr)
        [ Markdown.toHtmlWith
            safeOptions
            [ class "markdown-text" ]
            markdownText
        ]
