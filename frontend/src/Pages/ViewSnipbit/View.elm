module Pages.ViewSnipbit.View exposing (..)

import Array
import DefaultServices.Util as Util exposing (maybeMapWithDefault)
import Elements.Editor as Editor
import Elements.Markdown exposing (githubMarkdown)
import Elements.ProgressBar exposing (progressBar)
import Html exposing (Html, div, text, button, i)
import Html.Attributes exposing (class, classList, disabled, hidden, id)
import Html.Events exposing (onClick)
import Pages.Model exposing (Shared)
import Pages.ViewSnipbit.Model exposing (..)
import Pages.ViewSnipbit.Messages exposing (Msg(..))
import Models.Completed as Completed
import Models.Story as Story
import Models.Snipbit as Snipbit
import Models.Route as Route
import Models.ViewerRelevantHC as ViewerRelevantHC


{-| `ViewSnipbit` view.
-}
view : Model -> Shared -> Html Msg
view model shared =
    div
        [ class "view-snipbit-page" ]
        [ div
            [ class "sub-bar" ]
            [ case ( shared.viewingStory, model.viewingSnipbit ) of
                ( Just story, Just snipbit ) ->
                    case Story.getPreviousTidbitRoute snipbit.id story.id story.tidbits of
                        Just previousTidbitRoute ->
                            button
                                [ class "sub-bar-button traverse-tidbit-button"
                                , onClick <| GoTo previousTidbitRoute
                                ]
                                [ text "Previous Tidbit" ]

                        _ ->
                            Util.hiddenDiv

                _ ->
                    Util.hiddenDiv
            , case shared.viewingStory of
                Just story ->
                    button
                        [ class "sub-bar-button back-to-story-button"
                        , onClick <| GoTo <| Route.ViewStoryPage story.id
                        ]
                        [ text "View Story" ]

                _ ->
                    Util.hiddenDiv
            , case ( shared.viewingStory, model.viewingSnipbit ) of
                ( Just story, Just snipbit ) ->
                    case Story.getNextTidbitRoute snipbit.id story.id story.tidbits of
                        Just nextTidbitRoute ->
                            button
                                [ class "sub-bar-button traverse-tidbit-button"
                                , onClick <| GoTo nextTidbitRoute
                                ]
                                [ text "Next Tidbit" ]

                        _ ->
                            Util.hiddenDiv

                _ ->
                    Util.hiddenDiv
            , button
                [ classList
                    [ ( "sub-bar-button view-relevant-ranges", True )
                    , ( "hidden"
                      , not <|
                            maybeMapWithDefault
                                ViewerRelevantHC.hasFramesButNotBrowsing
                                False
                                model.viewingSnipbitRelevantHC
                      )
                    ]
                , onClick <| ViewSnipbitBrowseRelevantHC
                ]
                [ text "Browse Related Frames" ]
            , button
                [ classList
                    [ ( "sub-bar-button view-relevant-ranges", True )
                    , ( "hidden"
                      , not <|
                            maybeMapWithDefault
                                ViewerRelevantHC.browsingFrames
                                False
                                model.viewingSnipbitRelevantHC
                      )
                    ]
                , onClick <| ViewSnipbitCancelBrowseRelevantHC
                ]
                [ text "Close Related Frames" ]
            , case ( shared.user, model.viewingSnipbitIsCompleted ) of
                ( Just user, Just ({ complete } as isCompleted) ) ->
                    if complete then
                        button
                            [ class "sub-bar-button complete-button"
                            , onClick <| ViewSnipbitMarkAsIncomplete <| Completed.completedFromIsCompleted isCompleted user.id
                            ]
                            [ text "Mark Snipbit as Incomplete" ]
                    else
                        button
                            [ class "sub-bar-button complete-button"
                            , onClick <| ViewSnipbitMarkAsComplete <| Completed.completedFromIsCompleted isCompleted user.id
                            ]
                            [ text "Mark Snipbit as Complete" ]

                _ ->
                    Util.hiddenDiv
            ]
        , case model.viewingSnipbit of
            Nothing ->
                Util.hiddenDiv

            Just snipbit ->
                div
                    [ class "viewer" ]
                    [ div
                        [ class "viewer-navbar" ]
                        [ i
                            [ classList
                                [ ( "material-icons action-button", True )
                                , ( "disabled-icon"
                                  , (case shared.route of
                                        Route.ViewSnipbitIntroductionPage _ _ ->
                                            True

                                        _ ->
                                            False
                                    )
                                        || (isViewSnipbitRHCTabOpen model)
                                  )
                                ]
                            , onClick <|
                                if isViewSnipbitRHCTabOpen model then
                                    NoOp
                                else
                                    case shared.route of
                                        Route.ViewSnipbitConclusionPage fromStoryID mongoID ->
                                            ViewSnipbitJumpToFrame <|
                                                Route.ViewSnipbitFramePage
                                                    fromStoryID
                                                    mongoID
                                                    (Array.length snipbit.highlightedComments)

                                        Route.ViewSnipbitFramePage fromStoryID mongoID frameNumber ->
                                            ViewSnipbitJumpToFrame <|
                                                Route.ViewSnipbitFramePage
                                                    fromStoryID
                                                    mongoID
                                                    (frameNumber - 1)

                                        _ ->
                                            NoOp
                            ]
                            [ text "arrow_back" ]
                        , div
                            [ onClick <|
                                if isViewSnipbitRHCTabOpen model then
                                    NoOp
                                else
                                    GoTo <|
                                        Route.ViewSnipbitIntroductionPage
                                            (Route.getFromStoryQueryParamOnViewSnipbitRoute shared.route)
                                            snipbit.id
                            , classList
                                [ ( "viewer-navbar-item", True )
                                , ( "selected"
                                  , case shared.route of
                                        Route.ViewSnipbitIntroductionPage _ _ ->
                                            True

                                        _ ->
                                            False
                                  )
                                , ( "disabled", isViewSnipbitRHCTabOpen model )
                                ]
                            ]
                            [ text "Introduction" ]
                        , progressBar
                            (case shared.route of
                                Route.ViewSnipbitFramePage _ _ frameNumber ->
                                    Just (frameNumber - 1)

                                Route.ViewSnipbitConclusionPage _ _ ->
                                    Just <| Array.length snipbit.highlightedComments

                                _ ->
                                    Nothing
                            )
                            (Array.length snipbit.highlightedComments)
                            (isViewSnipbitRHCTabOpen model)
                        , div
                            [ onClick <|
                                if isViewSnipbitRHCTabOpen model then
                                    NoOp
                                else
                                    GoTo <|
                                        Route.ViewSnipbitConclusionPage
                                            (Route.getFromStoryQueryParamOnViewSnipbitRoute shared.route)
                                            snipbit.id
                            , classList
                                [ ( "viewer-navbar-item", True )
                                , ( "selected"
                                  , case shared.route of
                                        Route.ViewSnipbitConclusionPage _ _ ->
                                            True

                                        _ ->
                                            False
                                  )
                                , ( "disabled", isViewSnipbitRHCTabOpen model )
                                ]
                            ]
                            [ text "Conclusion" ]
                        , i
                            [ classList
                                [ ( "material-icons action-button", True )
                                , ( "disabled-icon"
                                  , (case shared.route of
                                        Route.ViewSnipbitConclusionPage _ _ ->
                                            True

                                        _ ->
                                            False
                                    )
                                        || (isViewSnipbitRHCTabOpen model)
                                  )
                                ]
                            , onClick <|
                                if (isViewSnipbitRHCTabOpen model) then
                                    NoOp
                                else
                                    case shared.route of
                                        Route.ViewSnipbitIntroductionPage fromStoryID mongoID ->
                                            ViewSnipbitJumpToFrame <|
                                                Route.ViewSnipbitFramePage
                                                    fromStoryID
                                                    mongoID
                                                    1

                                        Route.ViewSnipbitFramePage fromStoryID mongoID frameNumber ->
                                            ViewSnipbitJumpToFrame <|
                                                Route.ViewSnipbitFramePage
                                                    fromStoryID
                                                    mongoID
                                                    (frameNumber + 1)

                                        _ ->
                                            NoOp
                            ]
                            [ text "arrow_forward" ]
                        ]
                    , Editor.editor "view-snipbit-code-editor"
                    , div
                        [ class "comment-block" ]
                        [ commentBox
                            snipbit
                            model.viewingSnipbitRelevantHC
                            shared.route
                        ]
                    ]
        ]


{-| Gets the comment box for the view snipbit page, can be the markdown for the
intro/conclusion/frame or the markdown with a few extra buttons for a selected
range.
-}
commentBox : Snipbit.Snipbit -> Maybe ViewingSnipbitRelevantHC -> Route.Route -> Html Msg
commentBox snipbit relevantHC route =
    let
        -- To display if no relevant HC.
        htmlIfNoRelevantHC =
            githubMarkdown [] <|
                case route of
                    Route.ViewSnipbitIntroductionPage _ _ ->
                        snipbit.introduction

                    Route.ViewSnipbitConclusionPage _ _ ->
                        snipbit.conclusion

                    Route.ViewSnipbitFramePage _ _ frameNumber ->
                        (Array.get
                            (frameNumber - 1)
                            snipbit.highlightedComments
                        )
                            |> Maybe.map .comment
                            |> Maybe.withDefault ""

                    _ ->
                        ""
    in
        case relevantHC of
            Nothing ->
                htmlIfNoRelevantHC

            Just ({ currentHC, relevantHC } as viewerRelevantHC) ->
                case currentHC of
                    Nothing ->
                        htmlIfNoRelevantHC

                    Just index ->
                        div
                            [ class "view-relevant-hc" ]
                            [ case ViewerRelevantHC.currentFramePair viewerRelevantHC of
                                Nothing ->
                                    Util.hiddenDiv

                                Just currentFramePair ->
                                    ViewerRelevantHC.relevantHCTextAboveFrameSpecifyingPosition
                                        currentFramePair
                            , div
                                [ classList
                                    [ ( "above-comment-block-button", True )
                                    , ( "disabled"
                                      , ViewerRelevantHC.onFirstFrame viewerRelevantHC
                                      )
                                    ]
                                , onClick ViewSnipbitPreviousRelevantHC
                                ]
                                [ text "Previous" ]
                            , div
                                [ classList
                                    [ ( "above-comment-block-button go-to-frame-button", True ) ]
                                , onClick
                                    (Array.get index relevantHC
                                        |> Maybe.map
                                            (ViewSnipbitJumpToFrame
                                                << Route.ViewSnipbitFramePage
                                                    (Route.getFromStoryQueryParamOnViewSnipbitRoute route)
                                                    snipbit.id
                                                << ((+) 1)
                                                << Tuple.first
                                            )
                                        |> Maybe.withDefault NoOp
                                    )
                                ]
                                [ text "Jump To Frame" ]
                            , div
                                [ classList
                                    [ ( "above-comment-block-button next-button", True )
                                    , ( "disabled"
                                      , ViewerRelevantHC.onLastFrame viewerRelevantHC
                                      )
                                    ]
                                , onClick ViewSnipbitNextRelevantHC
                                ]
                                [ text "Next" ]
                            , githubMarkdown
                                []
                                (Array.get index relevantHC
                                    |> Maybe.map (Tuple.second >> .comment)
                                    |> Maybe.withDefault ""
                                )
                            ]