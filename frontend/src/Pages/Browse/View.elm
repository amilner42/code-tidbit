module Pages.Browse.View exposing (..)

import DefaultServices.Util as Util
import Elements.ContentBox exposing (contentBox)
import Html exposing (Html, div, text, button, input, span, i)
import Html.Attributes exposing (class, hidden, classList, placeholder, value, id)
import Html.Events exposing (onClick, onInput)
import Keyboard.Extra as KK
import Pages.Browse.Messages exposing (..)
import Pages.Browse.Model exposing (..)
import Pages.Model exposing (Shared)


{-| `Browse` view.
-}
view : Model -> Shared -> Html Msg
view model shared =
    div
        [ class "browse-page" ]
        [ div
            [ class "search-bar sub-bar"
            ]
            [ input
                [ class "search-input"
                , id "search-bar"
                , placeholder "search"
                , value model.searchQuery
                , onInput OnUpdateSearch
                , Util.onKeydown
                    (\key ->
                        if key == KK.Enter then
                            Just Search
                        else
                            Nothing
                    )
                ]
                []
            , div
                [ class "advanced-search-options-toggle"
                , onClick ToggleAdvancedOptions
                ]
                [ if model.showAdvancedSearchOptions then
                    text "hide advanced search options"
                  else
                    text "show advanced search options"
                ]
            , div
                [ classList
                    [ ( "advanced-options", True )
                    , ( "hidden", not model.showAdvancedSearchOptions )
                    ]
                ]
                [ div
                    [ class "content-filter" ]
                    [ span [ class "content-filter-title" ] [ text "Filter Content Type" ]
                    , contentFilterType model.contentFilterSnipbits "snipbits" ToggleContentFilterSnipbits
                    , contentFilterType model.contentFilterBigbits "bigbits" ToggleContentFilterBigbits
                    , contentFilterType model.contentFilterStories "stories" ToggleContentFilterStories
                    ]
                ]
            ]
        , div [ class "sub-bar-ghost hidden" ] []
        , (case model.content of
            Nothing ->
                Util.hiddenDiv

            Just content ->
                div
                    [ class "browse-page-content" ]
                    [ if model.showNewContentMessage then
                        div [ class "content-title" ] [ text "Newest Content" ]
                      else if Util.maybeMapWithDefault (List.length >> (/=) 0) False model.content then
                        div [ class "content-title" ] [ text "Search Results" ]
                      else
                        Util.hiddenDiv
                    , div
                        [ class "all-content" ]
                        (content
                            |> List.map (contentBox { goToMsg = GoTo, darkenBox = False, forStory = Nothing })
                            |> (flip (++)) Util.emptyFlexBoxesForAlignment
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
                        [ case model.content of
                            Nothing ->
                                Util.hiddenDiv

                            Just content ->
                                if List.isEmpty content then
                                    text "no results found"
                                else
                                    text "no more results"
                        ]
                    ]
          )
        ]


{-| For staying DRY, used in the advanced options.
-}
contentFilterType : Bool -> String -> Msg -> Html Msg
contentFilterType currentlyIncluded name msg =
    div
        [ class <| "content-filter-type " ++ name
        , onClick msg
        ]
        [ i
            [ class "material-icons" ]
            [ if currentlyIncluded then
                text "check_box"
              else
                text "check_box_outline_blank"
            ]
        , span [ class "content-filter-type-text" ] [ text name ]
        ]
