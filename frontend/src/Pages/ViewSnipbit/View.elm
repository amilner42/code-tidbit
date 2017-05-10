module Pages.ViewSnipbit.View exposing (..)

import Array
import DefaultServices.Util as Util exposing (maybeMapWithDefault)
import Elements.Editor as Editor
import Elements.Markdown exposing (githubMarkdown)
import Elements.ProgressBar as ProgressBar exposing (TextFormat(Custom), State(..), progressBar)
import Html exposing (Html, div, text, button, i)
import Html.Attributes exposing (class, classList, disabled, hidden, id)
import Html.Events exposing (onClick)
import Models.Completed as Completed
import Models.Rating as Rating
import Models.Route as Route
import Models.Snipbit as Snipbit
import Models.Story as Story
import Models.TutorialBookmark as TB
import Models.ViewerRelevantHC as ViewerRelevantHC
import Pages.Model exposing (Shared)
import Pages.ViewSnipbit.Messages exposing (Msg(..))
import Pages.ViewSnipbit.Model exposing (..)


{-| `ViewSnipbit` view.
-}
view : Model -> Shared -> Html Msg
view model shared =
    div
        [ class "view-snipbit-page" ]
        [ div
            [ class "sub-bar" ]
            [ case ( shared.user, model.possibleOpinion ) of
                ( Just user, Just possibleOpinion ) ->
                    let
                        ( newMsg, buttonText ) =
                            case possibleOpinion.rating of
                                Nothing ->
                                    ( AddOpinion
                                        { contentPointer = possibleOpinion.contentPointer
                                        , rating = Rating.Like
                                        }
                                    , "Love it!"
                                    )

                                Just rating ->
                                    ( RemoveOpinion
                                        { contentPointer = possibleOpinion.contentPointer
                                        , rating = rating
                                        }
                                    , "Take Back Love"
                                    )
                    in
                        button
                            [ class "sub-bar-button heart-button"
                            , onClick <| newMsg
                            ]
                            [ text buttonText ]

                _ ->
                    Util.hiddenDiv
            , case ( shared.viewingStory, model.snipbit ) of
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
            , case ( shared.viewingStory, model.snipbit ) of
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
                                model.relevantHC
                      )
                    ]
                , onClick <| BrowseRelevantHC
                ]
                [ text "Browse Related Frames" ]
            , case ( Route.getViewingContentID shared.route, isViewSnipbitRHCTabOpen model, model.relevantQuestions ) of
                ( Just snipbitID, False, Just [] ) ->
                    button
                        [ class "sub-bar-button ask-question"

                        -- TODO Set the askQuestion codePointer then navigate.
                        , onClick <|
                            GoTo <|
                                Route.ViewSnipbitAskQuestion
                                    (Route.getFromStoryQueryParamOnViewSnipbitRoute shared.route)
                                    snipbitID
                        ]
                        [ text "Ask Question" ]

                ( Just snipbitID, False, Just _ ) ->
                    button
                        [ class "sub-bar-button view-relevant-questions"

                        -- TODO Set the browseCodePointer then navigate.
                        , onClick <|
                            GoTo <|
                                Route.ViewSnipbitQuestionsPage
                                    (Route.getFromStoryQueryParamOnViewSnipbitRoute shared.route)
                                    snipbitID
                        ]
                        [ text "Browse Related Questions" ]

                _ ->
                    Util.hiddenDiv
            , button
                [ classList
                    [ ( "sub-bar-button view-relevant-ranges", True )
                    , ( "hidden"
                      , not <|
                            maybeMapWithDefault
                                ViewerRelevantHC.browsingFrames
                                False
                                model.relevantHC
                      )
                    ]
                , onClick <| CancelBrowseRelevantHC
                ]
                [ text "Resume Tutorial" ]
            , case Route.getViewingContentID shared.route of
                Just snipbitID ->
                    button
                        [ classList
                            [ ( "sub-bar-button view-relevant-questions", True )
                            , ( "hidden", not <| Route.isOnViewSnipbitQARoute shared.route )
                            ]
                        , onClick <|
                            GoTo <|
                                routeForBookmark
                                    (Route.getFromStoryQueryParamOnViewSnipbitRoute shared.route)
                                    snipbitID
                                    model.bookmark
                        ]
                        [ text "Resume Tutorial" ]

                _ ->
                    Util.hiddenDiv
            ]
        , case model.snipbit of
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
                                        || Route.isOnViewSnipbitQARoute shared.route
                                  )
                                ]
                            , onClick <|
                                if isViewSnipbitRHCTabOpen model then
                                    NoOp
                                else
                                    case shared.route of
                                        Route.ViewSnipbitConclusionPage fromStoryID mongoID ->
                                            JumpToFrame <|
                                                Route.ViewSnipbitFramePage
                                                    fromStoryID
                                                    mongoID
                                                    (Array.length snipbit.highlightedComments)

                                        Route.ViewSnipbitFramePage fromStoryID mongoID frameNumber ->
                                            JumpToFrame <|
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
                                if isViewSnipbitRHCTabOpen model || Route.isOnViewSnipbitQARoute shared.route then
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
                                , ( "disabled"
                                  , isViewSnipbitRHCTabOpen model || Route.isOnViewSnipbitQARoute shared.route
                                  )
                                ]
                            ]
                            [ text "Introduction" ]
                        , progressBar
                            { state =
                                case model.bookmark of
                                    TB.Introduction ->
                                        NotStarted

                                    TB.FrameNumber frameNumber ->
                                        Started frameNumber

                                    TB.Conclusion ->
                                        Completed
                            , maxPosition = Array.length snipbit.highlightedComments
                            , disabledStyling =
                                isViewSnipbitRHCTabOpen model || Route.isOnViewSnipbitQARoute shared.route
                            , onClickMsg = GoTo shared.route
                            , allowClick =
                                (case shared.route of
                                    Route.ViewSnipbitFramePage _ _ _ ->
                                        True

                                    _ ->
                                        False
                                )
                                    && (maybeMapWithDefault
                                            (not << ViewerRelevantHC.browsingFrames)
                                            True
                                            model.relevantHC
                                       )
                            , textFormat =
                                Custom
                                    { notStarted = "0%"
                                    , started = (\frameNumber -> "Frame " ++ (toString frameNumber))
                                    , done = "100%"
                                    }
                            , shiftLeft = True
                            , alreadyComplete =
                                { for = ProgressBar.Tidbit
                                , complete =
                                    case ( shared.user, model.isCompleted ) of
                                        ( Just _, Just { complete } ) ->
                                            complete

                                        _ ->
                                            False
                                }
                            }
                        , div
                            [ onClick <|
                                if isViewSnipbitRHCTabOpen model || Route.isOnViewSnipbitQARoute shared.route then
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
                                , ( "disabled"
                                  , isViewSnipbitRHCTabOpen model || Route.isOnViewSnipbitQARoute shared.route
                                  )
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
                                        || Route.isOnViewSnipbitQARoute shared.route
                                  )
                                ]
                            , onClick <|
                                if (isViewSnipbitRHCTabOpen model) then
                                    NoOp
                                else
                                    case shared.route of
                                        Route.ViewSnipbitIntroductionPage fromStoryID mongoID ->
                                            JumpToFrame <| Route.ViewSnipbitFramePage fromStoryID mongoID 1

                                        Route.ViewSnipbitFramePage fromStoryID mongoID frameNumber ->
                                            JumpToFrame <|
                                                Route.ViewSnipbitFramePage fromStoryID mongoID (frameNumber + 1)

                                        _ ->
                                            NoOp
                            ]
                            [ text "arrow_forward" ]
                        ]
                    , Editor.editor "view-snipbit-code-editor"
                    , div
                        [ class "comment-block" ]
                        [ commentBox snipbit model shared ]
                    ]
        ]


{-| Gets the comment box for the view snipbit page, can be the markdown for the intro/conclusion/frame or the markdown
with a few extra buttons for a selected range.
-}
commentBox : Snipbit.Snipbit -> Model -> Shared -> Html Msg
commentBox snipbit { relevantHC } { route } =
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

        -- On the tutorial routes we display the tutorial or the relevantHC.
        tutorialRoute =
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
                                        ViewerRelevantHC.relevantHCTextAboveFrameSpecifyingPosition currentFramePair
                                , div
                                    [ classList
                                        [ ( "above-comment-block-button", True )
                                        , ( "disabled", ViewerRelevantHC.onFirstFrame viewerRelevantHC )
                                        ]
                                    , onClick PreviousRelevantHC
                                    ]
                                    [ text "Previous" ]
                                , div
                                    [ classList
                                        [ ( "above-comment-block-button go-to-frame-button", True ) ]
                                    , onClick
                                        (Array.get index relevantHC
                                            |> Maybe.map
                                                (JumpToFrame
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
                                        , ( "disabled", ViewerRelevantHC.onLastFrame viewerRelevantHC )
                                        ]
                                    , onClick NextRelevantHC
                                    ]
                                    [ text "Next" ]
                                , githubMarkdown
                                    []
                                    (Array.get index relevantHC
                                        |> Maybe.map (Tuple.second >> .comment)
                                        |> Maybe.withDefault ""
                                    )
                                ]
    in
        case route of
            Route.ViewSnipbitIntroductionPage _ _ ->
                tutorialRoute

            Route.ViewSnipbitConclusionPage _ _ ->
                tutorialRoute

            Route.ViewSnipbitFramePage _ _ _ ->
                tutorialRoute

            _ ->
                -- TODO CONTINUE Comment Box for QA routes.
                Util.hiddenDiv
