module Pages.ViewBigbit.View exposing (..)

import Array
import DefaultServices.Util as Util exposing (maybeMapWithDefault)
import Elements.ProgressBar exposing (progressBar)
import Elements.Editor as Editor
import Elements.FileStructure as FS
import Elements.Markdown exposing (githubMarkdown)
import Html exposing (Html, div, button, text, i)
import Html.Attributes exposing (class, classList, hidden)
import Html.Events exposing (onClick)
import Models.Bigbit as Bigbit
import Models.Completed as Completed
import Models.Route as Route
import Models.ViewerRelevantHC as ViewerRelevantHC
import Models.Story as Story
import Pages.ViewBigbit.Model exposing (..)
import Pages.ViewBigbit.Messages exposing (..)
import Pages.Model exposing (Shared)


{-| `ViewBigbit` view.
-}
view : Model -> Shared -> Html Msg
view model shared =
    let
        -- They can be on the FS or browsing RHC.
        notGoingThroughTutorial =
            not <|
                isViewBigbitTutorialTabOpen
                    model.viewingBigbit
                    model.viewingBigbitRelevantHC
    in
        div
            [ class "view-bigbit-page" ]
            [ div
                [ class "sub-bar" ]
                [ case ( shared.viewingStory, model.viewingBigbit ) of
                    ( Just story, Just bigbit ) ->
                        case Story.getPreviousTidbitRoute bigbit.id story.id story.tidbits of
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
                , case ( shared.viewingStory, model.viewingBigbit ) of
                    ( Just story, Just bigbit ) ->
                        case Story.getNextTidbitRoute bigbit.id story.id story.tidbits of
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
                        [ ( "sub-bar-button explore-fs", True )
                        , ( "hidden"
                          , (isViewBigbitRHCTabOpen model.viewingBigbitRelevantHC)
                                && (not <| isViewBigbitFSOpen model.viewingBigbit)
                          )
                        ]
                    , onClick <| ViewBigbitToggleFS
                    ]
                    [ text <|
                        if isViewBigbitFSOpen model.viewingBigbit then
                            "Resume Tutorial"
                        else
                            "Explore File Structure"
                    ]
                , button
                    [ classList
                        [ ( "sub-bar-button view-relevant-ranges", True )
                        , ( "hidden"
                          , not <|
                                maybeMapWithDefault
                                    ViewerRelevantHC.hasFramesButNotBrowsing
                                    False
                                    model.viewingBigbitRelevantHC
                          )
                        ]
                    , onClick ViewBigbitBrowseRelevantHC
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
                                    model.viewingBigbitRelevantHC
                          )
                        ]
                    , onClick ViewBigbitCancelBrowseRelevantHC
                    ]
                    [ text "Close Related Frames" ]
                , case ( shared.user, model.viewingBigbitIsCompleted ) of
                    ( Just user, Just ({ complete } as isCompleted) ) ->
                        if complete then
                            button
                                [ classList [ ( "sub-bar-button complete-button", True ) ]
                                , onClick <| ViewBigbitMarkAsIncomplete <| Completed.completedFromIsCompleted isCompleted user.id
                                ]
                                [ text "Mark Bigbit as Incomplete" ]
                        else
                            button
                                [ classList [ ( "sub-bar-button complete-button", True ) ]
                                , onClick <| ViewBigbitMarkAsComplete <| Completed.completedFromIsCompleted isCompleted user.id
                                ]
                                [ text "Mark Bigbit as Complete" ]

                    _ ->
                        Util.hiddenDiv
                ]
            , case model.viewingBigbit of
                Nothing ->
                    Util.hiddenDiv

                Just bigbit ->
                    div
                        [ class "viewer" ]
                        [ div
                            [ class "viewer-navbar" ]
                            [ i
                                [ classList
                                    [ ( "material-icons action-button", True )
                                    , ( "disabled-icon"
                                      , if notGoingThroughTutorial then
                                            True
                                        else
                                            case shared.route of
                                                Route.ViewBigbitIntroductionPage _ _ _ ->
                                                    True

                                                _ ->
                                                    False
                                      )
                                    ]
                                , onClick <|
                                    if notGoingThroughTutorial then
                                        NoOp
                                    else
                                        case shared.route of
                                            Route.ViewBigbitConclusionPage fromStoryID mongoID _ ->
                                                ViewBigbitJumpToFrame <| Route.ViewBigbitFramePage fromStoryID mongoID (Array.length bigbit.highlightedComments) Nothing

                                            Route.ViewBigbitFramePage fromStoryID mongoID frameNumber _ ->
                                                ViewBigbitJumpToFrame <| Route.ViewBigbitFramePage fromStoryID mongoID (frameNumber - 1) Nothing

                                            _ ->
                                                NoOp
                                ]
                                [ text "arrow_back" ]
                            , div
                                [ onClick <|
                                    if notGoingThroughTutorial then
                                        NoOp
                                    else
                                        ViewBigbitJumpToFrame <|
                                            Route.ViewBigbitIntroductionPage
                                                (Route.getFromStoryQueryParamOnViewBigbitRoute shared.route)
                                                bigbit.id
                                                Nothing
                                , classList
                                    [ ( "viewer-navbar-item", True )
                                    , ( "selected"
                                      , case shared.route of
                                            Route.ViewBigbitIntroductionPage _ _ _ ->
                                                True

                                            _ ->
                                                False
                                      )
                                    , ( "disabled", notGoingThroughTutorial )
                                    ]
                                ]
                                [ text "Introduction" ]
                            , progressBar
                                (case shared.route of
                                    Route.ViewBigbitFramePage _ _ frameNumber _ ->
                                        Just (frameNumber - 1)

                                    Route.ViewBigbitConclusionPage _ _ _ ->
                                        Just <| Array.length bigbit.highlightedComments

                                    _ ->
                                        Nothing
                                )
                                (Array.length bigbit.highlightedComments)
                                notGoingThroughTutorial
                            , div
                                [ onClick <|
                                    if notGoingThroughTutorial then
                                        NoOp
                                    else
                                        ViewBigbitJumpToFrame <|
                                            Route.ViewBigbitConclusionPage
                                                (Route.getFromStoryQueryParamOnViewBigbitRoute shared.route)
                                                bigbit.id
                                                Nothing
                                , classList
                                    [ ( "viewer-navbar-item", True )
                                    , ( "selected"
                                      , case shared.route of
                                            Route.ViewBigbitConclusionPage _ _ _ ->
                                                True

                                            _ ->
                                                False
                                      )
                                    , ( "disabled", notGoingThroughTutorial )
                                    ]
                                ]
                                [ text "Conclusion" ]
                            , i
                                [ classList
                                    [ ( "material-icons action-button", True )
                                    , ( "disabled-icon"
                                      , if notGoingThroughTutorial then
                                            True
                                        else
                                            case shared.route of
                                                Route.ViewBigbitConclusionPage _ _ _ ->
                                                    True

                                                _ ->
                                                    False
                                      )
                                    ]
                                , onClick <|
                                    if notGoingThroughTutorial then
                                        NoOp
                                    else
                                        case shared.route of
                                            Route.ViewBigbitIntroductionPage fromStoryID mongoID _ ->
                                                ViewBigbitJumpToFrame <|
                                                    Route.ViewBigbitFramePage fromStoryID mongoID 1 Nothing

                                            Route.ViewBigbitFramePage fromStoryID mongoID frameNumber _ ->
                                                ViewBigbitJumpToFrame <|
                                                    Route.ViewBigbitFramePage fromStoryID mongoID (frameNumber + 1) Nothing

                                            _ ->
                                                NoOp
                                ]
                                [ text "arrow_forward" ]
                            ]
                        , Editor.editor "view-bigbit-code-editor"
                        , viewBigbitCommentBox bigbit model.viewingBigbitRelevantHC shared.route
                        ]
            ]


{-| Gets the comment box for the view bigbit page, can be the markdown for the
intro/conclusion/frame, the FS, or the markdown with a few extra buttons for a
selected range.
-}
viewBigbitCommentBox : Bigbit.Bigbit -> Maybe ViewingBigbitRelevantHC -> Route.Route -> Html Msg
viewBigbitCommentBox bigbit maybeRHC route =
    let
        rhcTabOpen =
            isViewBigbitRHCTabOpen maybeRHC

        fsTabOpen =
            isViewBigbitFSTabOpen (Just bigbit) maybeRHC

        tutorialOpen =
            isViewBigbitTutorialTabOpen (Just bigbit) maybeRHC
    in
        div
            [ class "comment-block" ]
            [ div
                [ class "above-editor-text" ]
                [ text <|
                    case Bigbit.viewPageCurrentActiveFile route bigbit of
                        Nothing ->
                            "No File Selected"

                        Just activeFile ->
                            activeFile
                ]
            , githubMarkdown [ hidden <| not <| tutorialOpen ] <|
                case route of
                    Route.ViewBigbitIntroductionPage _ _ _ ->
                        bigbit.introduction

                    Route.ViewBigbitConclusionPage _ _ _ ->
                        bigbit.conclusion

                    Route.ViewBigbitFramePage _ _ frameNumber _ ->
                        (Array.get
                            (frameNumber - 1)
                            bigbit.highlightedComments
                        )
                            |> Maybe.map .comment
                            |> Maybe.withDefault ""

                    _ ->
                        ""
            , div
                [ class "view-bigbit-fs"
                , hidden <| not <| fsTabOpen
                ]
                [ FS.fileStructure
                    { isFileSelected =
                        (\absolutePath ->
                            Bigbit.viewPageCurrentActiveFile route bigbit
                                |> Maybe.map (FS.isSameFilePath absolutePath)
                                |> Maybe.withDefault False
                        )
                    , fileSelectedMsg = ViewBigbitSelectFile
                    , folderSelectedMsg = ViewBigbitToggleFolder
                    }
                    bigbit.fs
                ]
            , div
                [ class "view-relevant-hc"
                , hidden <| not <| rhcTabOpen
                ]
                (case maybeRHC of
                    Nothing ->
                        [ Util.hiddenDiv ]

                    Just rhc ->
                        case rhc.currentHC of
                            Nothing ->
                                [ Util.hiddenDiv ]

                            Just index ->
                                [ case ViewerRelevantHC.currentFramePair rhc of
                                    Nothing ->
                                        Util.hiddenDiv

                                    Just currentFramePair ->
                                        ViewerRelevantHC.relevantHCTextAboveFrameSpecifyingPosition currentFramePair
                                , githubMarkdown
                                    []
                                    (Array.get index rhc.relevantHC
                                        |> maybeMapWithDefault (Tuple.second >> .comment) ""
                                    )
                                , div
                                    [ classList
                                        [ ( "above-comment-block-button", True )
                                        , ( "disabled", ViewerRelevantHC.onFirstFrame rhc )
                                        ]
                                    , onClick ViewBigbitPreviousRelevantHC
                                    ]
                                    [ text "Previous" ]
                                , div
                                    [ classList
                                        [ ( "above-comment-block-button go-to-frame-button", True ) ]
                                    , onClick
                                        (Array.get index rhc.relevantHC
                                            |> maybeMapWithDefault
                                                (ViewBigbitJumpToFrame
                                                    << (\frameNumber ->
                                                            Route.ViewBigbitFramePage
                                                                (Route.getFromStoryQueryParamOnViewBigbitRoute route)
                                                                bigbit.id
                                                                frameNumber
                                                                Nothing
                                                       )
                                                    << ((+) 1)
                                                    << Tuple.first
                                                )
                                                NoOp
                                        )
                                    ]
                                    [ text "Jump To Frame" ]
                                , div
                                    [ classList
                                        [ ( "above-comment-block-button next-button", True )
                                        , ( "disabled", ViewerRelevantHC.onLastFrame rhc )
                                        ]
                                    , onClick ViewBigbitNextRelevantHC
                                    ]
                                    [ text "Next" ]
                                ]
                )
            ]
