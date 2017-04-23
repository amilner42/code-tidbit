module Pages.ViewBigbit.View exposing (..)

import Array
import DefaultServices.Util as Util exposing (maybeMapWithDefault)
import Elements.Editor as Editor
import Elements.FileStructure as FS
import Elements.Markdown exposing (githubMarkdown)
import Elements.ProgressBar exposing (TextFormat(Custom), State(..), progressBar)
import Html exposing (Html, div, button, text, i)
import Html.Attributes exposing (class, classList, hidden)
import Html.Events exposing (onClick)
import Models.Bigbit as Bigbit
import Models.Completed as Completed
import Models.Route as Route
import Models.Story as Story
import Models.ViewerRelevantHC as ViewerRelevantHC
import Pages.Model exposing (Shared)
import Pages.ViewBigbit.Messages exposing (..)
import Pages.ViewBigbit.Model exposing (..)


{-| `ViewBigbit` view.
-}
view : Model -> Shared -> Html Msg
view model shared =
    let
        notGoingThroughTutorial =
            isBigbitRHCTabOpen model.relevantHC

        fsOpen =
            maybeMapWithDefault Bigbit.isFSOpen False (Maybe.map .fs model.bigbit)

        currentRoute =
            shared.route
    in
        div
            [ classList
                [ ( "view-bigbit-page", True )
                , ( "fs-closed", not <| fsOpen )
                ]
            ]
            [ div
                [ class "sub-bar" ]
                [ case ( shared.viewingStory, model.bigbit ) of
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
                , case ( shared.viewingStory, model.bigbit ) of
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
                        [ ( "sub-bar-button view-relevant-ranges", True )
                        , ( "hidden"
                          , not <|
                                maybeMapWithDefault
                                    ViewerRelevantHC.hasFramesButNotBrowsing
                                    False
                                    model.relevantHC
                          )
                        ]
                    , onClick BrowseRelevantHC
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
                                    model.relevantHC
                          )
                        ]
                    , onClick CancelBrowseRelevantHC
                    ]
                    [ text "Close Related Frames" ]
                , case ( shared.user, model.isCompleted ) of
                    ( Just user, Just ({ complete } as isCompleted) ) ->
                        if complete then
                            button
                                [ classList [ ( "sub-bar-button complete-button", True ) ]
                                , onClick <| MarkAsIncomplete <| Completed.completedFromIsCompleted isCompleted user.id
                                ]
                                [ text "Mark Bigbit as Incomplete" ]
                        else
                            button
                                [ classList [ ( "sub-bar-button complete-button", True ) ]
                                , onClick <| MarkAsComplete <| Completed.completedFromIsCompleted isCompleted user.id
                                ]
                                [ text "Mark Bigbit as Complete" ]

                    _ ->
                        Util.hiddenDiv
                ]
            , case model.bigbit of
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
                                            case currentRoute of
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
                                        case currentRoute of
                                            Route.ViewBigbitConclusionPage fromStoryID mongoID _ ->
                                                JumpToFrame <|
                                                    Route.ViewBigbitFramePage
                                                        fromStoryID
                                                        mongoID
                                                        (Array.length bigbit.highlightedComments)
                                                        Nothing

                                            Route.ViewBigbitFramePage fromStoryID mongoID frameNumber _ ->
                                                JumpToFrame <|
                                                    Route.ViewBigbitFramePage
                                                        fromStoryID
                                                        mongoID
                                                        (frameNumber - 1)
                                                        Nothing

                                            _ ->
                                                NoOp
                                ]
                                [ text "arrow_back" ]
                            , div
                                [ onClick <|
                                    if notGoingThroughTutorial then
                                        NoOp
                                    else
                                        JumpToFrame <|
                                            Route.ViewBigbitIntroductionPage
                                                (Route.getFromStoryQueryParamOnViewBigbitRoute currentRoute)
                                                bigbit.id
                                                Nothing
                                , classList
                                    [ ( "viewer-navbar-item", True )
                                    , ( "selected"
                                      , case currentRoute of
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
                                { state =
                                    case currentRoute of
                                        Route.ViewBigbitFramePage _ _ frameNumber _ ->
                                            Started frameNumber

                                        Route.ViewBigbitConclusionPage _ _ _ ->
                                            Completed

                                        _ ->
                                            NotStarted
                                , maxPosition = Array.length bigbit.highlightedComments
                                , disabledStyling = notGoingThroughTutorial
                                , onClickMsg = BackToTutorialSpot
                                , allowClick =
                                    (not <| notGoingThroughTutorial)
                                        && (case shared.route of
                                                Route.ViewBigbitFramePage _ _ _ _ ->
                                                    True

                                                _ ->
                                                    False
                                           )
                                , textFormat =
                                    Custom
                                        { notStarted = "Not Started"
                                        , started = (\frameNumber -> "Frame " ++ (toString frameNumber))
                                        , done = "Complete"
                                        }
                                , shiftLeft = True
                                }
                            , div
                                [ onClick <|
                                    if notGoingThroughTutorial then
                                        NoOp
                                    else
                                        JumpToFrame <|
                                            Route.ViewBigbitConclusionPage
                                                (Route.getFromStoryQueryParamOnViewBigbitRoute currentRoute)
                                                bigbit.id
                                                Nothing
                                , classList
                                    [ ( "viewer-navbar-item", True )
                                    , ( "selected"
                                      , case currentRoute of
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
                                            case currentRoute of
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
                                        case currentRoute of
                                            Route.ViewBigbitIntroductionPage fromStoryID mongoID _ ->
                                                JumpToFrame <|
                                                    Route.ViewBigbitFramePage fromStoryID mongoID 1 Nothing

                                            Route.ViewBigbitFramePage fromStoryID mongoID frameNumber _ ->
                                                JumpToFrame <|
                                                    Route.ViewBigbitFramePage
                                                        fromStoryID
                                                        mongoID
                                                        (frameNumber + 1)
                                                        Nothing

                                            _ ->
                                                NoOp
                                ]
                                [ text "arrow_forward" ]
                            ]
                        , div
                            [ class "view-bigbit-fs" ]
                            [ FS.fileStructure
                                { isFileSelected =
                                    (\absolutePath ->
                                        Route.viewBigbitPageCurrentActiveFile currentRoute bigbit
                                            |> Maybe.map (FS.isSameFilePath absolutePath)
                                            |> Maybe.withDefault False
                                    )
                                , fileSelectedMsg = SelectFile
                                , folderSelectedMsg = ToggleFolder
                                }
                                bigbit.fs
                            , i
                                [ class "close-fs-icon material-icons"
                                , onClick ToggleFS
                                ]
                                [ text "close" ]
                            , div
                                [ class "above-editor-text"
                                , onClick <|
                                    if fsOpen then
                                        NoOp
                                    else
                                        ToggleFS
                                ]
                                [ text <|
                                    case Route.viewBigbitPageCurrentActiveFile currentRoute bigbit of
                                        Nothing ->
                                            "No File Selected"

                                        Just activeFile ->
                                            activeFile
                                ]
                            ]
                        , Editor.editor "view-bigbit-code-editor"
                        , viewBigbitCommentBox bigbit model.relevantHC currentRoute
                        ]
            ]


{-| Gets the comment box for the view bigbit page, can be the markdown for the intro/conclusion/frame, the FS, or the
markdown with a few extra buttons for a selected range.
-}
viewBigbitCommentBox : Bigbit.Bigbit -> Maybe ViewingBigbitRelevantHC -> Route.Route -> Html Msg
viewBigbitCommentBox bigbit maybeRHC route =
    let
        rhcTabOpen =
            isBigbitRHCTabOpen maybeRHC

        tutorialOpen =
            not <| rhcTabOpen
    in
        div
            [ class "comment-block" ]
            [ githubMarkdown [ hidden <| not <| tutorialOpen ] <|
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
                                    , onClick PreviousRelevantHC
                                    ]
                                    [ text "Previous" ]
                                , div
                                    [ classList
                                        [ ( "above-comment-block-button go-to-frame-button", True ) ]
                                    , onClick
                                        (Array.get index rhc.relevantHC
                                            |> maybeMapWithDefault
                                                (JumpToFrame
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
                                    , onClick NextRelevantHC
                                    ]
                                    [ text "Next" ]
                                ]
                )
            ]
