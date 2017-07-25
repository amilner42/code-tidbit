module Elements.Simple.Markdown exposing (..)

import Html exposing (Attribute, Html, div)
import Html.Attributes exposing (class)
import Markdown


view : List (Attribute msg) -> String -> Html msg
view extraAttr markdownText =
    div
        ([ class "markdown-box" ] ++ extraAttr)
        [ Markdown.toHtmlWith safeOptions [ class "markdown-text" ] markdownText ]


{-| Because our markdown is from user-input, we need to sanitize the HTML. Additionally, we keep everything
github-styled.
-}
safeOptions : Markdown.Options
safeOptions =
    { githubFlavored = Just { tables = True, breaks = True }
    , defaultHighlighting = Nothing
    , sanitize = True
    , smartypants = True
    }
