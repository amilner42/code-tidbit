module Pages.Browse.View exposing (..)

import DefaultServices.Util as Util
import Elements.ContentBox exposing (contentBox)
import Html exposing (Html, div, text, button)
import Html.Attributes exposing (class, hidden, classList)
import Html.Events exposing (onClick)
import Pages.Browse.Messages exposing (..)
import Pages.Browse.Model exposing (..)
import Pages.Model exposing (Shared)


{-| `Browse` view.
-}
view : Model -> Shared -> Html Msg
view model shared =
    case model.content of
        Nothing ->
            Util.hiddenDiv

        Just content ->
            div
                [ class "browse-page" ]
                [ div
                    [ class "all-content" ]
                    ((List.map
                        (contentBox { goToMsg = GoTo, darkenBox = False, forStory = Nothing })
                        content
                     )
                        ++ Util.emptyFlexBoxesForAlignment
                    )
                , button
                    [ classList
                        [ ( "load-more-content-button", True )
                        , ( "hidden", model.noMoreContent )
                        ]
                    , onClick LoadMoreContent
                    ]
                    [ text "load more" ]
                , div
                    [ classList
                        [ ( "no-more-results-message", True )
                        , ( "hidden", not model.noMoreContent )
                        ]
                    ]
                    [ text "no more results" ]
                ]
