module Pages.Home.View exposing (..)

import Array
import Autocomplete as AC
import Pages.Home.Messages exposing (Msg(..))
import Pages.Home.Model as Model exposing (Model)
import Pages.Home.Update exposing (filterLanguagesByQuery)
import Pages.Model exposing (Shared, kkUpdateWrapper)
import DefaultServices.Util as Util exposing (maybeMapWithDefault)
import DefaultServices.Editable as Editable
import Dict
import Elements.Editor as Editor
import Html exposing (Html, div, text, textarea, button, input, h1, h3, img, hr, i)
import Html.Attributes exposing (class, classList, disabled, placeholder, value, hidden, id, src, style)
import Html.Events exposing (onClick, onInput)
import Models.Bigbit as Bigbit
import Elements.FileStructure as FS
import Elements.Markdown exposing (githubMarkdown)
import Keyboard.Extra as KK
import Models.Completed as Completed
import Models.Range as Range
import Models.Route as Route
import Models.Snipbit as Snipbit
import Models.ProfileData as ProfileData
import Models.NewStoryData as NewStoryData
import Models.StoryData as StoryData
import Models.Tidbit as Tidbit
import Models.Story as Story
import Models.ViewSnipbitData as ViewSnipbitData
import Models.ViewBigbitData as ViewBigbitData
import Models.ViewerRelevantHC as ViewerRelevantHC
import Models.TidbitType exposing (TidbitType(..))


{-| A google-material-design check-icon.
-}
checkIcon : Html msg
checkIcon =
    i
        [ class "material-icons check-icon" ]
        [ text "check" ]


{-| Home Component View.
-}
view : Model -> Shared -> Html Msg
view model shared =
    div
        [ class "home-component-wrapper" ]
        [ div
            [ class "home-component" ]
            [ navbar shared
            , displayViewForRoute model shared
            ]
        ]


{-| Helper function for creating the HTML tags in the tag-tab. Currently used
in both snipbits and bigbits.
-}
makeHTMLTags : (String -> Msg) -> List String -> Html Msg
makeHTMLTags closeTagMsg tags =
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


{-| Renders markdown if condition is true, otherwise the backup html.
-}
markdownOr : Bool -> String -> Html msg -> Html msg
markdownOr condition markdownText backUpHtml =
    if condition then
        githubMarkdown [] markdownText
    else
        backUpHtml


{-| Builds a progress bar

NOTE: If position is `Nothing`, it is assumed 0% is complete.
-}
progressBar : Maybe Int -> Int -> Bool -> Html Msg
progressBar maybePosition maxPosition isDisabled =
    let
        percentComplete =
            case maybePosition of
                Nothing ->
                    0

                Just currentFrame ->
                    100 * (toFloat currentFrame) / (toFloat maxPosition)
    in
        div
            [ classList
                [ ( "progress-bar", True )
                , ( "selected", Util.isNotNothing maybePosition )
                , ( "disabled", isDisabled )
                ]
            ]
            [ div
                [ classList
                    [ ( "progress-bar-completion-bar", True )
                    , ( "disabled", isDisabled )
                    ]
                , style [ ( "width", (toString <| round <| percentComplete * 1.6) ++ "px" ) ]
                ]
                []
            , div
                [ class "progress-bar-percent" ]
                [ text <| (toString <| round <| percentComplete) ++ "%" ]
            ]


{-| Helper for creating the text above the RHC specifying how many found and
what RHC we are on currently.
-}
relevantHCTextAboveFrameSpecifyingPosition : ( Int, Int ) -> Html msg
relevantHCTextAboveFrameSpecifyingPosition ( current, total ) =
    div
        [ class "above-comment-block-text" ]
        [ if total == 1 then
            text "Only this frame is related to your selection"
          else
            text <| "On frame " ++ (toString current) ++ " of the " ++ (toString total) ++ " frames that are related to your selection"
        ]


{-| Gets the comment box for the view snipbit page, can be the markdown for the
intro/conclusion/frame or the markdown with a few extra buttons for a selected
range.
-}
viewSnipbitCommentBox : Snipbit.Snipbit -> Maybe ViewSnipbitData.ViewingSnipbitRelevantHC -> Route.Route -> Html Msg
viewSnipbitCommentBox snipbit relevantHC route =
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
                                    relevantHCTextAboveFrameSpecifyingPosition currentFramePair
                            , div
                                [ classList
                                    [ ( "above-comment-block-button", True )
                                    , ( "disabled", ViewerRelevantHC.onFirstFrame viewerRelevantHC )
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
                                    , ( "disabled", ViewerRelevantHC.onLastFrame viewerRelevantHC )
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


{-| The view for viewing a snipbit.
-}
viewSnipbitView : Model -> Shared -> Html Msg
viewSnipbitView model shared =
    div
        [ class "view-snipbit-page" ]
        [ div
            [ class "sub-bar" ]
            [ case ( shared.viewingStory, model.viewSnipbitData.viewingSnipbit ) of
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
            , case ( shared.viewingStory, model.viewSnipbitData.viewingSnipbit ) of
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
                                model.viewSnipbitData.viewingSnipbitRelevantHC
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
                                model.viewSnipbitData.viewingSnipbitRelevantHC
                      )
                    ]
                , onClick <| ViewSnipbitCancelBrowseRelevantHC
                ]
                [ text "Close Related Frames" ]
            , case ( shared.user, model.viewSnipbitData.viewingSnipbitIsCompleted ) of
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
        , case model.viewSnipbitData.viewingSnipbit of
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
                                        || (ViewSnipbitData.isViewSnipbitRHCTabOpen model.viewSnipbitData)
                                  )
                                ]
                            , onClick <|
                                if ViewSnipbitData.isViewSnipbitRHCTabOpen model.viewSnipbitData then
                                    NoOp
                                else
                                    case shared.route of
                                        Route.ViewSnipbitConclusionPage fromStoryID mongoID ->
                                            ViewSnipbitJumpToFrame <| Route.ViewSnipbitFramePage fromStoryID mongoID (Array.length snipbit.highlightedComments)

                                        Route.ViewSnipbitFramePage fromStoryID mongoID frameNumber ->
                                            ViewSnipbitJumpToFrame <| Route.ViewSnipbitFramePage fromStoryID mongoID (frameNumber - 1)

                                        _ ->
                                            NoOp
                            ]
                            [ text "arrow_back" ]
                        , div
                            [ onClick <|
                                if ViewSnipbitData.isViewSnipbitRHCTabOpen model.viewSnipbitData then
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
                                , ( "disabled", ViewSnipbitData.isViewSnipbitRHCTabOpen model.viewSnipbitData )
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
                            (ViewSnipbitData.isViewSnipbitRHCTabOpen model.viewSnipbitData)
                        , div
                            [ onClick <|
                                if ViewSnipbitData.isViewSnipbitRHCTabOpen model.viewSnipbitData then
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
                                , ( "disabled", ViewSnipbitData.isViewSnipbitRHCTabOpen model.viewSnipbitData )
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
                                        || (ViewSnipbitData.isViewSnipbitRHCTabOpen model.viewSnipbitData)
                                  )
                                ]
                            , onClick <|
                                if (ViewSnipbitData.isViewSnipbitRHCTabOpen model.viewSnipbitData) then
                                    NoOp
                                else
                                    case shared.route of
                                        Route.ViewSnipbitIntroductionPage fromStoryID mongoID ->
                                            ViewSnipbitJumpToFrame <| Route.ViewSnipbitFramePage fromStoryID mongoID 1

                                        Route.ViewSnipbitFramePage fromStoryID mongoID frameNumber ->
                                            ViewSnipbitJumpToFrame <| Route.ViewSnipbitFramePage fromStoryID mongoID (frameNumber + 1)

                                        _ ->
                                            NoOp
                            ]
                            [ text "arrow_forward" ]
                        ]
                    , Editor.editor "view-snipbit-code-editor"
                    , div
                        [ class "comment-block" ]
                        [ viewSnipbitCommentBox
                            snipbit
                            model.viewSnipbitData.viewingSnipbitRelevantHC
                            shared.route
                        ]
                    ]
        ]


{-| Gets the comment box for the view bigbit page, can be the markdown for the
intro/conclusion/frame, the FS, or the markdown with a few extra buttons for a
selected range.
-}
viewBigbitCommentBox : Bigbit.Bigbit -> Maybe ViewBigbitData.ViewingBigbitRelevantHC -> Route.Route -> Html Msg
viewBigbitCommentBox bigbit maybeRHC route =
    let
        rhcTabOpen =
            ViewBigbitData.isViewBigbitRHCTabOpen maybeRHC

        fsTabOpen =
            ViewBigbitData.isViewBigbitFSTabOpen (Just bigbit) maybeRHC

        tutorialOpen =
            ViewBigbitData.isViewBigbitTutorialTabOpen (Just bigbit) maybeRHC
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
                                        relevantHCTextAboveFrameSpecifyingPosition currentFramePair
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


{-| The view for viewing a bigbit.
-}
viewBigbitView : Model -> Shared -> Html Msg
viewBigbitView model shared =
    let
        -- They can be on the FS or browsing RHC.
        notGoingThroughTutorial =
            not <|
                ViewBigbitData.isViewBigbitTutorialTabOpen
                    model.viewBigbitData.viewingBigbit
                    model.viewBigbitData.viewingBigbitRelevantHC
    in
        div
            [ class "view-bigbit-page" ]
            [ div
                [ class "sub-bar" ]
                [ case ( shared.viewingStory, model.viewBigbitData.viewingBigbit ) of
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
                , case ( shared.viewingStory, model.viewBigbitData.viewingBigbit ) of
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
                          , (ViewBigbitData.isViewBigbitRHCTabOpen model.viewBigbitData.viewingBigbitRelevantHC)
                                && (not <| ViewBigbitData.isViewBigbitFSOpen model.viewBigbitData.viewingBigbit)
                          )
                        ]
                    , onClick <| ViewBigbitToggleFS
                    ]
                    [ text <|
                        if ViewBigbitData.isViewBigbitFSOpen model.viewBigbitData.viewingBigbit then
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
                                    model.viewBigbitData.viewingBigbitRelevantHC
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
                                    model.viewBigbitData.viewingBigbitRelevantHC
                          )
                        ]
                    , onClick ViewBigbitCancelBrowseRelevantHC
                    ]
                    [ text "Close Related Frames" ]
                , case ( shared.user, model.viewBigbitData.viewingBigbitIsCompleted ) of
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
            , case model.viewBigbitData.viewingBigbit of
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
                        , viewBigbitCommentBox bigbit model.viewBigbitData.viewingBigbitRelevantHC shared.route
                        ]
            ]


{-| The view for viewing a story.
-}
viewStoryView : Model -> Shared -> Html Msg
viewStoryView model shared =
    case shared.viewingStory of
        Nothing ->
            Util.hiddenDiv

        Just story ->
            let
                completedListForLoggedInUser : Maybe (List Bool)
                completedListForLoggedInUser =
                    case ( shared.user, shared.viewingStory |> Maybe.andThen .userHasCompleted ) of
                        ( Just user, Just hasCompletedList ) ->
                            Just hasCompletedList

                        _ ->
                            Nothing

                nextTidbitInStory : Maybe ( Int, Route.Route )
                nextTidbitInStory =
                    completedListForLoggedInUser
                        |> Maybe.andThen Util.indexOfFirstFalse
                        |> Maybe.andThen
                            (\index ->
                                Util.getAt story.tidbits index
                                    |> Maybe.map (Tidbit.getTidbitRoute (Just story.id) >> (,) index)
                            )
            in
                div
                    [ class "view-story-page" ]
                    [ case nextTidbitInStory of
                        Just _ ->
                            Util.keyedDiv
                                [ class "sub-bar" ]
                                [ ( "view-story-next-tidbit-button"
                                  , case nextTidbitInStory of
                                        Just ( index, routeForViewingTidbit ) ->
                                            button
                                                [ class "sub-bar-button next-tidbit-button"
                                                , onClick <| GoTo routeForViewingTidbit
                                                ]
                                                [ text <| "Continue on Tidbit " ++ (toString <| index + 1) ]

                                        _ ->
                                            Util.hiddenDiv
                                  )
                                ]

                        _ ->
                            Util.hiddenDiv
                    , case nextTidbitInStory of
                        Just _ ->
                            Util.keyedDiv
                                [ class "sub-bar-ghost hidden" ]
                                []

                        _ ->
                            Util.hiddenDiv
                    , div
                        [ class "view-story-page-content" ]
                        [ div
                            [ class "story-name" ]
                            [ text story.name ]
                        , case ( completedListForLoggedInUser, story.tidbits ) of
                            ( Just hasCompletedList, h :: xs ) ->
                                div
                                    []
                                    [ div
                                        [ classList [ ( "progress-bar-title", True ) ]
                                        ]
                                        [ text "you've completed" ]
                                    , div
                                        [ classList [ ( "story-progress-bar-bar", True ) ]
                                        ]
                                        [ progressBar
                                            (Just <|
                                                List.foldl
                                                    (\currentBool totalComplete ->
                                                        if currentBool then
                                                            totalComplete + 1
                                                        else
                                                            totalComplete
                                                    )
                                                    0
                                                    hasCompletedList
                                            )
                                            (List.length hasCompletedList)
                                            False
                                        ]
                                    ]

                            _ ->
                                Util.hiddenDiv
                        , case story.tidbits of
                            [] ->
                                div
                                    [ class "no-tidbit-text" ]
                                    [ text "This story has no tidbits yet!" ]

                            _ ->
                                div
                                    [ class "flex-box space-between" ]
                                    ((List.indexedMap
                                        (\index tidbit ->
                                            div
                                                [ classList
                                                    [ ( "tidbit-box", True )
                                                    , ( "completed"
                                                      , case shared.viewingStory |> Maybe.andThen .userHasCompleted of
                                                            Nothing ->
                                                                False

                                                            Just hasCompletedList ->
                                                                Maybe.withDefault False (Util.getAt hasCompletedList index)
                                                      )
                                                    ]
                                                ]
                                                [ div
                                                    [ class "tidbit-box-name" ]
                                                    [ text <| Tidbit.getName tidbit ]
                                                , div
                                                    [ class "tidbit-box-page-number" ]
                                                    [ text <| toString <| index + 1 ]
                                                , button
                                                    [ class "view-button"
                                                    , onClick <| GoTo <| Tidbit.getTidbitRoute (Just story.id) tidbit
                                                    ]
                                                    [ text "VIEW"
                                                    ]
                                                , div
                                                    [ class "completed-icon-div" ]
                                                    [ i
                                                        [ class "material-icons completed-icon" ]
                                                        [ text "check" ]
                                                    ]
                                                ]
                                        )
                                        story.tidbits
                                     )
                                        ++ emptyFlexBoxesForAlignment
                                    )
                        ]
                    ]


{-| Displays the correct view based on the model.
-}
displayViewForRoute : Model -> Shared -> Html Msg
displayViewForRoute model shared =
    case shared.route of
        Route.BrowsePage ->
            browseView model

        Route.ViewSnipbitIntroductionPage _ _ ->
            viewSnipbitView model shared

        Route.ViewSnipbitConclusionPage _ _ ->
            viewSnipbitView model shared

        Route.ViewSnipbitFramePage _ _ _ ->
            viewSnipbitView model shared

        Route.ViewBigbitIntroductionPage _ _ _ ->
            viewBigbitView model shared

        Route.ViewBigbitFramePage _ _ _ _ ->
            viewBigbitView model shared

        Route.ViewBigbitConclusionPage _ _ _ ->
            viewBigbitView model shared

        Route.ViewStoryPage _ ->
            viewStoryView model shared

        Route.CreatePage ->
            createView model shared

        Route.CreateSnipbitNamePage ->
            createSnipbitView model shared

        Route.CreateSnipbitDescriptionPage ->
            createSnipbitView model shared

        Route.CreateSnipbitLanguagePage ->
            createSnipbitView model shared

        Route.CreateSnipbitTagsPage ->
            createSnipbitView model shared

        Route.CreateSnipbitCodeIntroductionPage ->
            createSnipbitView model shared

        Route.CreateSnipbitCodeFramePage _ ->
            createSnipbitView model shared

        Route.CreateSnipbitCodeConclusionPage ->
            createSnipbitView model shared

        Route.CreateBigbitNamePage ->
            createBigbitView model shared

        Route.CreateBigbitDescriptionPage ->
            createBigbitView model shared

        Route.CreateBigbitTagsPage ->
            createBigbitView model shared

        Route.CreateBigbitCodeIntroductionPage _ ->
            createBigbitView model shared

        Route.CreateBigbitCodeFramePage _ _ ->
            createBigbitView model shared

        Route.CreateBigbitCodeConclusionPage _ ->
            createBigbitView model shared

        Route.ProfilePage ->
            profileView model shared

        Route.CreateStoryNamePage _ ->
            createNewStoryView model shared

        Route.CreateStoryDescriptionPage _ ->
            createNewStoryView model shared

        Route.CreateStoryTagsPage _ ->
            createNewStoryView model shared

        Route.DevelopStoryPage _ ->
            createStoryView model shared

        -- This should never happen.
        _ ->
            browseView model


{-| Horizontal navbar to go above the views.
-}
navbar : Shared -> Html Msg
navbar shared =
    let
        browseViewSelected =
            case shared.route of
                Route.BrowsePage ->
                    True

                Route.ViewSnipbitIntroductionPage _ _ ->
                    True

                Route.ViewSnipbitFramePage _ _ _ ->
                    True

                Route.ViewSnipbitConclusionPage _ _ ->
                    True

                Route.ViewBigbitIntroductionPage _ _ _ ->
                    True

                Route.ViewBigbitFramePage _ _ _ _ ->
                    True

                Route.ViewBigbitConclusionPage _ _ _ ->
                    True

                Route.ViewStoryPage _ ->
                    True

                _ ->
                    False

        profileViewSelected =
            shared.route == Route.ProfilePage

        createViewSelected =
            case shared.route of
                Route.CreateSnipbitCodeFramePage _ ->
                    True

                Route.CreateBigbitCodeFramePage _ _ ->
                    True

                Route.CreateBigbitCodeIntroductionPage _ ->
                    True

                Route.CreateBigbitCodeConclusionPage _ ->
                    True

                Route.DevelopStoryPage _ ->
                    True

                Route.CreateStoryNamePage _ ->
                    True

                Route.CreateStoryDescriptionPage _ ->
                    True

                Route.CreateStoryTagsPage _ ->
                    True

                _ ->
                    (List.member
                        shared.route
                        [ Route.CreatePage
                        , Route.CreateSnipbitNamePage
                        , Route.CreateSnipbitDescriptionPage
                        , Route.CreateSnipbitLanguagePage
                        , Route.CreateSnipbitTagsPage
                        , Route.CreateSnipbitCodeIntroductionPage
                        , Route.CreateSnipbitCodeConclusionPage
                        , Route.CreateBigbitNamePage
                        , Route.CreateBigbitDescriptionPage
                        , Route.CreateBigbitTagsPage
                        ]
                    )
    in
        div [ class "nav" ]
            [ img
                [ class "logo"
                , src "assets/ct-logo.png"
                ]
                []
            , div
                [ classList
                    [ ( "nav-btn left code-tidbit", True )
                    , ( "hidden", Util.isNotNothing shared.user )
                    ]
                ]
                [ text "Code Tidbit" ]
            , div
                [ classList
                    [ ( "nav-btn left", True )
                    , ( "hidden", Util.isNothing shared.user )
                    , ( "selected", browseViewSelected )
                    ]
                , onClick <| GoTo Route.BrowsePage
                ]
                [ text "Browse" ]
            , div
                [ classList
                    [ ( "nav-btn left", True )
                    , ( "hidden", Util.isNothing shared.user )
                    , ( "selected", createViewSelected )
                    ]
                , onClick <| GoTo Route.CreatePage
                ]
                [ text "Create" ]
            , div
                [ classList
                    [ ( "nav-btn right", True )
                    , ( "hidden", Util.isNothing shared.user )
                    , ( "selected", profileViewSelected )
                    ]
                , onClick <| GoTo Route.ProfilePage
                ]
                [ text "Profile" ]
            , div
                [ classList
                    [ ( "nav-btn sign-up right", True )
                    , ( "hidden", Util.isNotNothing shared.user )
                    ]
                , onClick <| GoTo Route.RegisterPage
                ]
                [ text "Sign Up" ]
            , div
                [ classList
                    [ ( "nav-btn login right", True )
                    , ( "hidden", Util.isNotNothing shared.user )
                    ]
                , onClick <| GoTo Route.LoginPage
                ]
                [ text "Login" ]
            ]


{-| The view for working on a story (adding tidbits).
-}
createStoryView : Model -> Shared -> Html Msg
createStoryView model shared =
    case ( model.storyData.currentStory, shared.userTidbits ) of
        ( Just story, Just userTidbits ) ->
            div
                [ class "create-story-page" ]
                [ Util.keyedDiv
                    [ class "sub-bar" ]
                    [ ( "create-story-page-sub-bar-view-story-button"
                      , button
                            [ class "sub-bar-button "
                            , onClick <| GoTo <| Route.ViewStoryPage story.id
                            ]
                            [ text "View Story" ]
                      )
                    , ( "create-story-page-sub-bar-edit-info-button"
                      , button
                            [ class "sub-bar-button edit-information"
                            , onClick <| GoTo <| Route.CreateStoryNamePage <| Just story.id
                            ]
                            [ text "Edit Information" ]
                      )
                    , ( "create-story-page-sub-bar-add-tidbits-button"
                      , case model.storyData.tidbitsToAdd of
                            [] ->
                                button
                                    [ class "disabled-publish-button" ]
                                    [ text "Add Tidbits" ]

                            tidbits ->
                                button
                                    [ class "publish-button"
                                    , onClick <| CreateStoryPublishAddedTidbits story.id tidbits
                                    ]
                                    [ text "Add Tidbits" ]
                      )
                    ]
                , Util.keyedDiv
                    [ class "sub-bar-ghost hidden" ]
                    []
                , div
                    [ class "create-story-page-content" ]
                    [ div
                        [ class "page-content-bar" ]
                        [ div
                            [ class "page-content-bar-title"
                            , id "story-tidbits-title"
                            ]
                            [ text "Story Tidbits" ]
                        , div
                            [ class "page-content-bar-line" ]
                            []
                        , div
                            [ class "flex-box space-between" ]
                            ((List.indexedMap
                                (\index tidbit ->
                                    div
                                        [ class "tidbit-box" ]
                                        [ div
                                            [ class "tidbit-box-name" ]
                                            [ text <| Tidbit.getName tidbit ]
                                        , div
                                            [ class "tidbit-box-type-name" ]
                                            [ text <| Tidbit.getTypeName tidbit ]
                                        , div
                                            [ class "tidbit-box-page-number" ]
                                            [ text <| toString <| index + 1 ]
                                        , button
                                            [ class "full-view-button"
                                            , onClick <| GoTo <| Tidbit.getTidbitRoute Nothing tidbit
                                            ]
                                            [ text "VIEW" ]
                                        ]
                                )
                                story.tidbits
                             )
                                ++ (List.map
                                        (\tidbit ->
                                            div
                                                [ class "tidbit-box not-yet-added" ]
                                                [ div
                                                    [ class "tidbit-box-name" ]
                                                    [ text <| Tidbit.getName tidbit ]
                                                , div
                                                    [ class "tidbit-box-type-name" ]
                                                    [ text <| Tidbit.getTypeName tidbit ]
                                                , button
                                                    [ class "remove-button"
                                                    , onClick <| CreateStoryRemoveTidbit tidbit
                                                    ]
                                                    [ text "REMOVE" ]
                                                ]
                                        )
                                        model.storyData.tidbitsToAdd
                                   )
                                ++ emptyFlexBoxesForAlignment
                            )
                        ]
                    , div
                        [ class "page-content-bar" ]
                        [ div
                            [ class "page-content-bar-title" ]
                            [ text "Your Tidbits" ]
                        , div
                            [ class "page-content-bar-line" ]
                            []
                        , div
                            [ class "flex-box space-between" ]
                            ((List.map
                                (\tidbit ->
                                    div
                                        [ class "tidbit-box" ]
                                        [ div
                                            [ class "tidbit-box-name" ]
                                            [ text <| Tidbit.getName tidbit ]
                                        , div
                                            [ class "tidbit-box-type-name" ]
                                            [ text <| Tidbit.getTypeName tidbit ]
                                        , button
                                            [ class "view-tidbit"
                                            , onClick <| GoTo <| Tidbit.getTidbitRoute Nothing tidbit
                                            ]
                                            [ text "VIEW" ]
                                        , button
                                            [ class "add-tidbit"
                                            , onClick <| CreateStoryAddTidbit tidbit
                                            ]
                                            [ text "ADD" ]
                                        ]
                                )
                                (userTidbits
                                    |> StoryData.remainingTidbits (story.tidbits ++ model.storyData.tidbitsToAdd)
                                    |> Util.sortByDate Tidbit.getLastModified
                                    |> List.reverse
                                )
                             )
                                ++ emptyFlexBoxesForAlignment
                            )
                        ]
                    ]
                ]

        _ ->
            Util.hiddenDiv


{-| The view for creating a new story.
-}
createNewStoryView : Model -> Shared -> Html Msg
createNewStoryView model shared =
    let
        currentRoute =
            shared.route

        editingStoryQueryParam =
            Route.getEditingStoryQueryParamOnCreateNewStoryRoute shared.route

        isEditingStory =
            Util.isNotNothing editingStoryQueryParam

        editingStoryLoaded =
            (Just model.newStoryData.editingStory.id == editingStoryQueryParam)
    in
        div
            [ class "new-story-page"
            , hidden <| isEditingStory && not editingStoryLoaded
            ]
            [ div
                [ class "sub-bar" ]
                (case editingStoryQueryParam of
                    Nothing ->
                        [ button
                            [ class "sub-bar-button"
                            , onClick NewStoryReset
                            ]
                            [ text "Reset" ]
                        , button
                            [ classList
                                [ ( "continue-button", True )
                                , ( "publish-button", NewStoryData.newStoryDataReadyForPublication model.newStoryData )
                                , ( "disabled-publish-button", not <| NewStoryData.newStoryDataReadyForPublication model.newStoryData )
                                ]
                            , onClick NewStoryPublish
                            ]
                            [ text "Proceed to Tidbit Selection" ]
                        ]

                    Just storyID ->
                        [ button
                            [ class "sub-bar-button"
                            , onClick <| NewStoryCancelEdits storyID
                            ]
                            [ text "Cancel" ]
                        , button
                            [ classList
                                [ ( "sub-bar-button save-changes", True )
                                , ( "publish-button", NewStoryData.editingStoryDataReadyForSave model.newStoryData )
                                , ( "disabled-publish-button", not <| NewStoryData.editingStoryDataReadyForSave model.newStoryData )
                                ]
                            , onClick <| NewStorySaveEdits storyID
                            ]
                            [ text "Save Changes" ]
                        ]
                )
            , div
                [ class "create-tidbit-navbar" ]
                [ div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
                          , case currentRoute of
                                Route.CreateStoryNamePage _ ->
                                    True

                                _ ->
                                    False
                          )
                        , ( "filled-in"
                          , if isEditingStory then
                                NewStoryData.editingNameTabFilledIn model.newStoryData
                            else
                                NewStoryData.nameTabFilledIn model.newStoryData
                          )
                        ]
                    , onClick <| GoTo <| Route.CreateStoryNamePage editingStoryQueryParam
                    ]
                    [ text "Name" ]
                , div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
                          , case currentRoute of
                                Route.CreateStoryDescriptionPage _ ->
                                    True

                                _ ->
                                    False
                          )
                        , ( "filled-in"
                          , if isEditingStory then
                                NewStoryData.editingDescriptionTabFilledIn model.newStoryData
                            else
                                NewStoryData.descriptionTabFilledIn model.newStoryData
                          )
                        ]
                    , onClick <| GoTo <| Route.CreateStoryDescriptionPage editingStoryQueryParam
                    ]
                    [ text "Description" ]
                , div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
                          , case currentRoute of
                                Route.CreateStoryTagsPage _ ->
                                    True

                                _ ->
                                    False
                          )
                        , ( "filled-in"
                          , if isEditingStory then
                                NewStoryData.editingTagsTabFilledIn model.newStoryData
                            else
                                NewStoryData.tagsTabFilledIn model.newStoryData
                          )
                        ]
                    , onClick <| GoTo <| Route.CreateStoryTagsPage editingStoryQueryParam
                    ]
                    [ text "Tags" ]
                ]
            , case currentRoute of
                Route.CreateStoryNamePage qpEditingStory ->
                    div
                        [ class "create-new-story-name" ]
                        [ case qpEditingStory of
                            Nothing ->
                                input
                                    [ placeholder "Name"
                                    , id "name-input"
                                    , onInput NewStoryUpdateName
                                    , value model.newStoryData.newStory.name
                                    , Util.onKeydownPreventDefault
                                        (\key ->
                                            if key == KK.Tab then
                                                Just NoOp
                                            else
                                                Nothing
                                        )
                                    ]
                                    []

                            _ ->
                                input
                                    [ placeholder "Edit Story Name"
                                    , id "name-input"
                                    , onInput NewStoryEditingUpdateName
                                    , value model.newStoryData.editingStory.name
                                    , Util.onKeydownPreventDefault
                                        (\key ->
                                            if key == KK.Tab then
                                                Just NoOp
                                            else
                                                Nothing
                                        )
                                    ]
                                    []
                        ]

                Route.CreateStoryDescriptionPage qpEditingStory ->
                    div
                        [ class "create-new-story-description" ]
                        [ case qpEditingStory of
                            Nothing ->
                                textarea
                                    [ placeholder "Description"
                                    , id "description-input"
                                    , onInput NewStoryUpdateDescription
                                    , value model.newStoryData.newStory.description
                                    , Util.onKeydownPreventDefault
                                        (\key ->
                                            if key == KK.Tab then
                                                Just NoOp
                                            else
                                                Nothing
                                        )
                                    ]
                                    []

                            Just editingStory ->
                                textarea
                                    [ placeholder "Edit Story Description"
                                    , id "description-input"
                                    , onInput NewStoryEditingUpdateDescription
                                    , value model.newStoryData.editingStory.description
                                    , Util.onKeydownPreventDefault
                                        (\key ->
                                            if key == KK.Tab then
                                                Just NoOp
                                            else
                                                Nothing
                                        )
                                    ]
                                    []
                        ]

                Route.CreateStoryTagsPage qpEditingStory ->
                    div
                        [ class "create-new-story-tags" ]
                        (case qpEditingStory of
                            Nothing ->
                                [ input
                                    [ placeholder "Tags"
                                    , id "tags-input"
                                    , onInput NewStoryUpdateTagInput
                                    , value model.newStoryData.tagInput
                                    , Util.onKeydownPreventDefault
                                        (\key ->
                                            if key == KK.Enter then
                                                Just <| NewStoryAddTag model.newStoryData.tagInput
                                            else if key == KK.Tab then
                                                Just <| NoOp
                                            else
                                                Nothing
                                        )
                                    ]
                                    []
                                , makeHTMLTags
                                    NewStoryRemoveTag
                                    model.newStoryData.newStory.tags
                                ]

                            Just _ ->
                                [ input
                                    [ placeholder "Edit Story Tags"
                                    , id "tags-input"
                                    , onInput NewStoryEditingUpdateTagInput
                                    , value model.newStoryData.editingStoryTagInput
                                    , Util.onKeydownPreventDefault
                                        (\key ->
                                            if key == KK.Enter then
                                                Just <|
                                                    NewStoryEditingAddTag model.newStoryData.editingStoryTagInput
                                            else if key == KK.Tab then
                                                Just <| NoOp
                                            else
                                                Nothing
                                        )
                                    ]
                                    []
                                , makeHTMLTags
                                    NewStoryEditingRemoveTag
                                    model.newStoryData.editingStory.tags
                                ]
                        )

                _ ->
                    Util.hiddenDiv
            ]


{-| The profile view.
-}
profileView : Model -> Shared -> Html Msg
profileView model shared =
    case shared.user of
        Nothing ->
            Util.hiddenDiv

        Just user ->
            div [ class "profile-page" ]
                [ div
                    [ class "profile-panel" ]
                    [ div
                        [ class "profile-card account-card" ]
                        [ div
                            [ class "profile-card-title" ]
                            [ text "Account" ]
                        , div
                            [ class "profile-card-sub-box" ]
                            [ div
                                [ class "profile-card-sub-box-title" ]
                                [ text "Email" ]
                            , div [ class "profile-card-sub-box-gap" ] []
                            , div
                                [ class "profile-card-sub-box-content email-display" ]
                                [ text user.email ]
                            ]
                        , div
                            [ class "profile-card-sub-box" ]
                            [ div
                                [ class "profile-card-sub-box-title" ]
                                [ text "Name" ]
                            , div [ class "profile-card-sub-box-gap" ] []
                            , input
                                [ class "profile-card-sub-box-content"
                                , placeholder "Preferred Name"
                                , value <| ProfileData.getNameWithDefault model.profileData user.name
                                , onInput <| ProfileUpdateName user.name
                                ]
                                []
                            , i
                                [ classList
                                    [ ( "material-icons", True )
                                    , ( "hidden", not <| ProfileData.isEditingName model.profileData )
                                    ]
                                , onClick ProfileCancelEditName
                                ]
                                [ text "cancel" ]
                            , i
                                [ classList
                                    [ ( "material-icons", True )
                                    , ( "hidden", not <| ProfileData.isEditingName model.profileData )
                                    ]
                                , onClick ProfileSaveEditName
                                ]
                                [ text "check_circle" ]
                            ]
                        , div
                            [ class "profile-card-sub-box" ]
                            [ div
                                [ class "profile-card-sub-box-title" ]
                                [ text "Bio" ]
                            , div
                                [ class "profile-card-sub-box-gap" ]
                                []
                            , textarea
                                [ class "profile-card-sub-box-content bio-textarea"
                                , placeholder "Tell everyone about yourself..."
                                , value <| ProfileData.getBioWithDefault model.profileData user.bio
                                , onInput <| ProfileUpdateBio user.bio
                                ]
                                []
                            , div
                                [ class "bio-icons-box" ]
                                [ i
                                    [ classList
                                        [ ( "material-icons", True )
                                        , ( "hidden", not <| ProfileData.isEditingBio model.profileData )
                                        ]
                                    , onClick ProfileCancelEditBio
                                    ]
                                    [ text "cancel" ]
                                , i
                                    [ classList
                                        [ ( "material-icons", True )
                                        , ( "hidden", not <| ProfileData.isEditingBio model.profileData )
                                        ]
                                    , onClick ProfileSaveEditBio
                                    ]
                                    [ text "check_circle" ]
                                ]
                            ]
                        , button
                            [ class "logout-button"
                            , onClick LogOut
                            ]
                            [ text "Log Out" ]
                        , div
                            [ hidden <| Util.isNothing model.profileData.logOutError ]
                            [ text "Cannot log out right now, try again shortly." ]
                        ]
                    , div
                        [ class "profile-card editor-card" ]
                        [ div
                            [ class "profile-card-title" ]
                            [ text "Editor" ]
                        ]
                    , div
                        [ class "profile-card" ]
                        [ div
                            [ class "profile-card-title" ]
                            [ text "App" ]
                        ]
                    ]
                ]


{-| The browse view.
-}
browseView : Model -> Html Msg
browseView model =
    div []
        []


{-| The create view.
-}
createView : Model -> Shared -> Html Msg
createView model shared =
    let
        snipBitDescription : String
        snipBitDescription =
            """SnipBits are uni-language snippets of code that are
            targetted at explaining simple individual concepts or
            answering questions.

            You highlight chunks of the code with attached comments,
            taking your viewers through your code explaining everything
            one step at a time.
            """

        bigBitInfo : String
        bigBitInfo =
            """BigBits are multi-language projects of code targetted at
            simplifying larger tutorials which require their own file structure.

            You highlight chunks of code and attach comments automatically
            taking your user through all the files and folders in a directed
            fashion while still letting them explore themselves.
            """

        makeTidbitTypeBox : String -> String -> String -> Msg -> TidbitType -> Html Msg
        makeTidbitTypeBox title subTitle description onClickMsg tidbitType =
            div
                [ class "create-select-tidbit-type" ]
                (if model.createData.showInfoFor == (Just tidbitType) then
                    [ div
                        [ class "description-text" ]
                        [ text description ]
                    , button
                        [ class "back-button"
                        , onClick <| ShowInfoFor Nothing
                        ]
                        [ text "Back" ]
                    ]
                 else
                    [ div
                        [ class "create-select-tidbit-type-title" ]
                        [ text title ]
                    , div
                        [ class "create-select-tidbit-type-sub-title" ]
                        [ text subTitle ]
                    , i
                        [ class "material-icons info-icon"
                        , onClick <| ShowInfoFor <| Just tidbitType
                        ]
                        [ text "help_outline" ]
                    , button
                        [ class "select-button"
                        , onClick onClickMsg
                        ]
                        [ text "CREATE" ]
                    ]
                )

        yourStoriesHtml : Html Msg
        yourStoriesHtml =
            case shared.userStories of
                -- Should never happen.
                Nothing ->
                    Util.hiddenDiv

                Just userStories ->
                    div
                        [ class "develop-stories" ]
                        [ div
                            [ classList [ ( "boxes flex-box space-between", True ) ]
                            ]
                            ([ div
                                [ class "create-story-box"
                                , onClick <| GoTo <| Route.CreateStoryNamePage Nothing
                                ]
                                [ i
                                    [ class "material-icons add-story-box-icon" ]
                                    [ text "add" ]
                                ]
                             ]
                                ++ (List.map
                                        (\story ->
                                            div
                                                [ class "story-box" ]
                                                [ div
                                                    [ class "story-box-name" ]
                                                    [ text story.name ]
                                                , button
                                                    [ class "continue-story-button"
                                                    , onClick <| GoTo <| Route.DevelopStoryPage story.id
                                                    ]
                                                    [ text "CONTINUE" ]
                                                ]
                                        )
                                        (List.reverse <| Util.sortByDate .lastModified userStories)
                                   )
                                ++ emptyFlexBoxesForAlignment
                            )
                        ]
    in
        div
            [ class "create-page" ]
            [ div
                [ class "title-banner" ]
                [ text "CREATE TIDBIT" ]
            , div
                [ class "make-tidbits" ]
                [ makeTidbitTypeBox
                    "SnipBit"
                    "Explain a chunk of code"
                    snipBitDescription
                    (GoTo Route.CreateSnipbitNamePage)
                    SnipBit
                , makeTidbitTypeBox
                    "BigBit"
                    "Explain a full project"
                    bigBitInfo
                    (GoTo Route.CreateBigbitNamePage)
                    BigBit
                , div
                    [ class "create-select-tidbit-type-coming-soon" ]
                    [ div
                        [ class "coming-soon-text" ]
                        [ text "More Coming Soon" ]
                    , div
                        [ class "coming-soon-sub-text" ]
                        [ text "We are working on it" ]
                    ]
                ]
            , div
                [ class "title-banner story-banner" ]
                [ text "DEVELOP STORY" ]
            , yourStoriesHtml
            ]


{-| View for creating a bigbit.
-}
createBigbitView : Model -> Shared -> Html Msg
createBigbitView model shared =
    let
        currentRoute =
            shared.route

        {- It should be disabled unles everything is filled out. -}
        publishButton =
            case Bigbit.createDataToPublicationData model.bigbitCreateData of
                Nothing ->
                    button
                        [ class "create-bigbit-disabled-publish-button"
                        , disabled True
                        ]
                        [ text "Publish" ]

                Just bigbitForPublicaton ->
                    button
                        [ class "create-bigbit-publish-button"
                        , onClick <| BigbitPublish bigbitForPublicaton
                        ]
                        [ text "Publish" ]

        createBigbitNavbar : Html Msg
        createBigbitNavbar =
            div
                [ classList [ ( "create-tidbit-navbar", True ) ] ]
                [ div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
                          , currentRoute == Route.CreateBigbitNamePage
                          )
                        , ( "filled-in", Util.isNotNothing <| Bigbit.createDataNameFilledIn model.bigbitCreateData )
                        ]
                    , onClick <| GoTo Route.CreateBigbitNamePage
                    ]
                    [ text "Name"
                    , checkIcon
                    ]
                , div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
                          , currentRoute == Route.CreateBigbitDescriptionPage
                          )
                        , ( "filled-in", Util.isNotNothing <| Bigbit.createDataDescriptionFilledIn model.bigbitCreateData )
                        ]
                    , onClick <| GoTo Route.CreateBigbitDescriptionPage
                    ]
                    [ text "Description"
                    , checkIcon
                    ]
                , div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
                          , currentRoute == Route.CreateBigbitTagsPage
                          )
                        , ( "filled-in", Util.isNotNothing <| Bigbit.createDataTagsFilledIn model.bigbitCreateData )
                        ]
                    , onClick <| GoTo Route.CreateBigbitTagsPage
                    ]
                    [ text "Tags"
                    , checkIcon
                    ]
                , div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
                          , case currentRoute of
                                Route.CreateBigbitCodeFramePage _ _ ->
                                    True

                                Route.CreateBigbitCodeIntroductionPage _ ->
                                    True

                                Route.CreateBigbitCodeConclusionPage _ ->
                                    True

                                _ ->
                                    False
                          )
                        , ( "filled-in", Bigbit.createDataCodeTabFilledIn model.bigbitCreateData )
                        ]
                    , onClick <| BigbitGoToCodeTab
                    ]
                    [ text "Code"
                    , checkIcon
                    ]
                ]

        bigbitCodeTab =
            let
                currentActiveFile =
                    Bigbit.createPageCurrentActiveFile shared.route

                viewingFile absolutePath =
                    Maybe.map (FS.isSameFilePath absolutePath) currentActiveFile
                        |> Maybe.withDefault False

                ( introTab, conclusionTab, frameTab ) =
                    case shared.route of
                        Route.CreateBigbitCodeIntroductionPage _ ->
                            ( True, False, Nothing )

                        Route.CreateBigbitCodeFramePage frameNumber _ ->
                            ( False, False, Just frameNumber )

                        Route.CreateBigbitCodeConclusionPage _ ->
                            ( False, True, Nothing )

                        _ ->
                            ( False, False, Nothing )

                bigbitEditor =
                    div
                        [ class "bigbit-editor" ]
                        [ div
                            [ class "current-file" ]
                            [ text <|
                                if introTab then
                                    "Bigbit introductions do not link to files or highlights, but you can browse and edit your code"
                                else if conclusionTab then
                                    "Bigbit conclusions do not link to files or highlights, but you can browse and edit your code"
                                else
                                    Maybe.withDefault "No File Selected" currentActiveFile
                            ]
                        , div
                            [ class "create-tidbit-code" ]
                            [ Editor.editor "create-bigbit-code-editor"
                            ]
                        ]

                bigbitCommentBox =
                    let
                        fsMetadata =
                            FS.getFSMetadata <| model.bigbitCreateData.fs

                        maybeActionState =
                            fsMetadata.actionButtonState

                        actionInput =
                            fsMetadata.actionButtonInput

                        validFileInputResult =
                            Bigbit.isValidAddFileInput
                                actionInput
                                model.bigbitCreateData.fs

                        validFileInput =
                            Util.resultToBool validFileInputResult

                        validRemoveFileInputResult =
                            Bigbit.isValidRemoveFileInput actionInput model.bigbitCreateData.fs

                        validRemoveFileInput =
                            Util.resultToBool validRemoveFileInputResult

                        validRemoveFolderInputResult =
                            Bigbit.isValidRemoveFolderInput actionInput model.bigbitCreateData.fs

                        validRemoveFolderInput =
                            Util.resultToBool validRemoveFolderInputResult

                        validFolderInputResult =
                            Bigbit.isValidAddFolderInput
                                actionInput
                                model.bigbitCreateData.fs

                        validFolderInput =
                            Util.resultToBool validFolderInputResult

                        fsOpen =
                            Bigbit.isFSOpen model.bigbitCreateData.fs

                        markdownOpen =
                            model.bigbitCreateData.previewMarkdown

                        fs =
                            div
                                [ class "file-structure"
                                , hidden <| not <| fsOpen
                                ]
                                [ FS.fileStructure
                                    { isFileSelected = viewingFile
                                    , fileSelectedMsg = BigbitFileSelected
                                    , folderSelectedMsg = BigbitFSToggleFolder
                                    }
                                    model.bigbitCreateData.fs
                                , div
                                    [ class "fs-action-input"
                                    , hidden <| Util.isNothing <| maybeActionState
                                    ]
                                    [ div
                                        [ class "fs-action-input-text" ]
                                        [ case maybeActionState of
                                            Nothing ->
                                                Util.hiddenDiv

                                            Just actionState ->
                                                case actionState of
                                                    Bigbit.AddingFolder ->
                                                        case validFolderInputResult of
                                                            Ok _ ->
                                                                text "Create folder and parent directories"

                                                            Err err ->
                                                                text <|
                                                                    case err of
                                                                        Bigbit.FolderAlreadyExists ->
                                                                            "That folder already exists"

                                                                        Bigbit.FolderHasDoubleSlash ->
                                                                            "You cannot have two slashes in a row"

                                                                        Bigbit.FolderHasInvalidCharacters ->
                                                                            "You are using invalid characters"

                                                                        Bigbit.FolderIsEmpty ->
                                                                            ""

                                                    Bigbit.AddingFile ->
                                                        case validFileInputResult of
                                                            Ok _ ->
                                                                text "Create file and parent directories"

                                                            Err err ->
                                                                case err of
                                                                    Bigbit.FileAlreadyExists ->
                                                                        text "That file already exists"

                                                                    Bigbit.FileEndsInSlash ->
                                                                        text "Files cannot end in a slash"

                                                                    Bigbit.FileHasDoubleSlash ->
                                                                        text "You cannot have two slashes in a row"

                                                                    Bigbit.FileHasInvalidCharacters ->
                                                                        text "You are using invalid characters"

                                                                    Bigbit.FileHasInvalidExtension ->
                                                                        text "You must have a valid file extension"

                                                                    Bigbit.FileIsEmpty ->
                                                                        text ""

                                                                    Bigbit.FileLanguageIsAmbiguous languages ->
                                                                        div
                                                                            [ class "fs-action-input-select-language-text" ]
                                                                            [ text "Select language to create file: "
                                                                            , div
                                                                                [ class "language-options" ]
                                                                                (languages
                                                                                    |> List.sortBy toString
                                                                                    |> List.map
                                                                                        (\language ->
                                                                                            button
                                                                                                [ onClick <| BigbitAddFile actionInput language ]
                                                                                                [ text <| toString language ]
                                                                                        )
                                                                                )
                                                                            ]

                                                    Bigbit.RemovingFolder ->
                                                        case validRemoveFolderInputResult of
                                                            Ok _ ->
                                                                if .actionButtonSubmitConfirmed <| FS.getFSMetadata model.bigbitCreateData.fs then
                                                                    text "Are you sure? This will also delete all linked frames!"
                                                                else
                                                                    text "Remove folder"

                                                            Err err ->
                                                                case err of
                                                                    Bigbit.RemoveFolderIsEmpty ->
                                                                        text ""

                                                                    Bigbit.RemoveFolderIsRootFolder ->
                                                                        text "You cannot remove the root directory"

                                                                    Bigbit.RemoveFolderDoesNotExist ->
                                                                        text "Folder doesn't exist"

                                                    Bigbit.RemovingFile ->
                                                        case validRemoveFileInputResult of
                                                            Ok _ ->
                                                                if .actionButtonSubmitConfirmed <| FS.getFSMetadata model.bigbitCreateData.fs then
                                                                    text "Are you sure? This will also delete all linked frames!"
                                                                else
                                                                    text "Remove file"

                                                            Err err ->
                                                                case err of
                                                                    Bigbit.RemoveFileIsEmpty ->
                                                                        text ""

                                                                    Bigbit.RemoveFileDoesNotExist ->
                                                                        text "File doesn't exist"
                                        ]
                                    , input
                                        [ id "fs-action-input-box"
                                        , placeholder "Absolute Path"
                                        , onInput BigbitUpdateActionInput
                                        , Util.onKeydown
                                            (\key ->
                                                if key == KK.Enter then
                                                    Just BigbitSubmitActionInput
                                                else
                                                    Nothing
                                            )
                                        , value
                                            (model.bigbitCreateData.fs
                                                |> FS.getFSMetadata
                                                |> .actionButtonInput
                                            )
                                        ]
                                        []
                                    , case maybeActionState of
                                        Nothing ->
                                            Util.hiddenDiv

                                        Just actionState ->
                                            let
                                                showSubmitIconIf condition isPlus =
                                                    if condition then
                                                        i
                                                            [ classList
                                                                [ ( "material-icons action-button-submit-icon", True )
                                                                , ( "arrow-confirmed"
                                                                  , model.bigbitCreateData.fs
                                                                        |> FS.getFSMetadata
                                                                        |> .actionButtonSubmitConfirmed
                                                                  )
                                                                ]
                                                            , onClick <| BigbitSubmitActionInput
                                                            ]
                                                            [ text <|
                                                                if isPlus then
                                                                    "add_box"
                                                                else
                                                                    "indeterminate_check_box"
                                                            ]
                                                    else
                                                        Util.hiddenDiv
                                            in
                                                case actionState of
                                                    Bigbit.AddingFile ->
                                                        showSubmitIconIf validFileInput True

                                                    Bigbit.AddingFolder ->
                                                        showSubmitIconIf validFolderInput True

                                                    Bigbit.RemovingFile ->
                                                        showSubmitIconIf validRemoveFileInput False

                                                    Bigbit.RemovingFolder ->
                                                        showSubmitIconIf validRemoveFolderInput False
                                    ]
                                , button
                                    [ classList
                                        [ ( "add-file", True )
                                        , ( "selected-action-button"
                                          , Bigbit.fsActionStateEquals (Just Bigbit.AddingFile) model.bigbitCreateData.fs
                                          )
                                        ]
                                    , onClick <| BigbitUpdateActionButtonState <| Just Bigbit.AddingFile
                                    ]
                                    [ text "Add File" ]
                                , button
                                    [ classList
                                        [ ( "add-folder", True )
                                        , ( "selected-action-button"
                                          , Bigbit.fsActionStateEquals (Just Bigbit.AddingFolder) model.bigbitCreateData.fs
                                          )
                                        ]
                                    , onClick <| BigbitUpdateActionButtonState <| Just Bigbit.AddingFolder
                                    ]
                                    [ text "Add Folder" ]
                                , button
                                    [ classList
                                        [ ( "remove-file", True )
                                        , ( "selected-action-button"
                                          , Bigbit.fsActionStateEquals (Just Bigbit.RemovingFile) model.bigbitCreateData.fs
                                          )
                                        ]
                                    , onClick <| BigbitUpdateActionButtonState <| Just Bigbit.RemovingFile
                                    ]
                                    [ text "Remove File" ]
                                , button
                                    [ classList
                                        [ ( "remove-folder", True )
                                        , ( "selected-action-button"
                                          , Bigbit.fsActionStateEquals (Just Bigbit.RemovingFolder) model.bigbitCreateData.fs
                                          )
                                        ]
                                    , onClick <| BigbitUpdateActionButtonState <| Just Bigbit.RemovingFolder
                                    ]
                                    [ text "Remove Folder" ]
                                ]

                        body =
                            div
                                [ class "comment-body" ]
                                [ fs
                                , div
                                    [ class "expand-file-structure"
                                    , onClick BigbitToggleFS
                                    , hidden markdownOpen
                                    ]
                                    [ if fsOpen then
                                        text "Close File Structure"
                                      else
                                        text "View File Structure"
                                    ]
                                , div
                                    [ class "preview-markdown"
                                    , onClick BigbitTogglePreviewMarkdown
                                    , hidden fsOpen
                                    ]
                                    [ if markdownOpen then
                                        text "Close Preview"
                                      else
                                        text "Preview Markdown"
                                    ]
                                , case shared.route of
                                    Route.CreateBigbitCodeIntroductionPage _ ->
                                        markdownOr
                                            markdownOpen
                                            model.bigbitCreateData.introduction
                                            (textarea
                                                [ placeholder "Introduction"
                                                , id "introduction-input"
                                                , onInput <| BigbitUpdateIntroduction
                                                , hidden <| Bigbit.isFSOpen model.bigbitCreateData.fs
                                                , value model.bigbitCreateData.introduction
                                                , Util.onKeydownPreventDefault
                                                    (\key ->
                                                        let
                                                            newKeysDown =
                                                                kkUpdateWrapper (KK.Down <| KK.toCode key) shared.keysDown
                                                        in
                                                            if key == KK.Tab then
                                                                if newKeysDown == shared.keysDown then
                                                                    Just NoOp
                                                                else if KK.isOneKeyPressed KK.Tab newKeysDown then
                                                                    Just <|
                                                                        GoTo <|
                                                                            Route.CreateBigbitCodeFramePage
                                                                                1
                                                                                (Bigbit.createPageGetActiveFileForFrame 1 model.bigbitCreateData)
                                                                else if KK.isTwoKeysPressed KK.Tab KK.Shift newKeysDown then
                                                                    Just <| GoTo <| Route.CreateBigbitTagsPage
                                                                else
                                                                    Nothing
                                                            else
                                                                Nothing
                                                    )
                                                ]
                                                []
                                            )

                                    Route.CreateBigbitCodeFramePage frameNumber _ ->
                                        let
                                            frameText =
                                                (Array.get
                                                    (frameNumber - 1)
                                                    model.bigbitCreateData.highlightedComments
                                                )
                                                    |> Maybe.map .comment
                                                    |> Maybe.withDefault ""
                                        in
                                            markdownOr
                                                markdownOpen
                                                frameText
                                                (textarea
                                                    [ placeholder <| "Frame " ++ (toString frameNumber)
                                                    , id "frame-input"
                                                    , onInput <| BigbitUpdateFrameComment frameNumber
                                                    , value frameText
                                                    , hidden <| fsOpen
                                                    , Util.onKeydownPreventDefault
                                                        (\key ->
                                                            let
                                                                newKeysDown =
                                                                    kkUpdateWrapper (KK.Down <| KK.toCode key) shared.keysDown
                                                            in
                                                                if key == KK.Tab then
                                                                    if newKeysDown == shared.keysDown then
                                                                        Just NoOp
                                                                    else if KK.isOneKeyPressed KK.Tab newKeysDown then
                                                                        Just <|
                                                                            GoTo <|
                                                                                Route.CreateBigbitCodeFramePage
                                                                                    (frameNumber + 1)
                                                                                    (Bigbit.createPageGetActiveFileForFrame
                                                                                        (frameNumber + 1)
                                                                                        model.bigbitCreateData
                                                                                    )
                                                                    else if KK.isTwoKeysPressed KK.Tab KK.Shift newKeysDown then
                                                                        Just <|
                                                                            GoTo <|
                                                                                Route.CreateBigbitCodeFramePage
                                                                                    (frameNumber - 1)
                                                                                    (Bigbit.createPageGetActiveFileForFrame
                                                                                        (frameNumber - 1)
                                                                                        model.bigbitCreateData
                                                                                    )
                                                                    else
                                                                        Nothing
                                                                else
                                                                    Nothing
                                                        )
                                                    ]
                                                    []
                                                )

                                    Route.CreateBigbitCodeConclusionPage _ ->
                                        markdownOr
                                            markdownOpen
                                            model.bigbitCreateData.conclusion
                                            (textarea
                                                [ placeholder "Conclusion"
                                                , id "conclusion-input"
                                                , onInput BigbitUpdateConclusion
                                                , hidden <| fsOpen
                                                , value model.bigbitCreateData.conclusion
                                                , Util.onKeydownPreventDefault
                                                    (\key ->
                                                        let
                                                            newKeysDown =
                                                                kkUpdateWrapper (KK.Down <| KK.toCode key) shared.keysDown
                                                        in
                                                            if key == KK.Tab then
                                                                if newKeysDown == shared.keysDown then
                                                                    Just NoOp
                                                                else if KK.isOneKeyPressed KK.Tab newKeysDown then
                                                                    Just <| NoOp
                                                                else if KK.isTwoKeysPressed KK.Tab KK.Shift newKeysDown then
                                                                    Just <|
                                                                        GoTo <|
                                                                            Route.CreateBigbitCodeFramePage
                                                                                (Array.length model.bigbitCreateData.highlightedComments)
                                                                                (Bigbit.createPageGetActiveFileForFrame
                                                                                    (Array.length model.bigbitCreateData.highlightedComments)
                                                                                    model.bigbitCreateData
                                                                                )
                                                                else
                                                                    Nothing
                                                            else
                                                                Nothing
                                                    )
                                                ]
                                                []
                                            )

                                    _ ->
                                        -- Should never happen.
                                        Util.hiddenDiv
                                ]

                        tabBar =
                            let
                                dynamicFrameButtons =
                                    div
                                        [ class "frame-buttons-box" ]
                                        ((Array.indexedMap
                                            (\index highlightedComment ->
                                                button
                                                    [ classList [ ( "selected-frame", (Just <| index + 1) == frameTab ) ]
                                                    , onClick <|
                                                        GoTo <|
                                                            Route.CreateBigbitCodeFramePage
                                                                (index + 1)
                                                                (Bigbit.createPageGetActiveFileForFrame
                                                                    (index + 1)
                                                                    model.bigbitCreateData
                                                                )
                                                    ]
                                                    [ text <| toString <| index + 1 ]
                                            )
                                            model.bigbitCreateData.highlightedComments
                                         )
                                            |> Array.toList
                                        )
                            in
                                div
                                    [ class "comment-body-bottom-buttons"
                                    , hidden <| fsOpen || markdownOpen
                                    ]
                                    [ button
                                        [ onClick <| GoTo <| Route.CreateBigbitCodeIntroductionPage Nothing
                                        , classList
                                            [ ( "introduction-button", True )
                                            , ( "selected-frame", introTab )
                                            ]
                                        ]
                                        [ text "Introduction" ]
                                    , button
                                        [ onClick <| GoTo <| Route.CreateBigbitCodeConclusionPage Nothing
                                        , classList
                                            [ ( "conclusion-button", True )
                                            , ( "selected-frame", conclusionTab )
                                            ]
                                        ]
                                        [ text "Conclusion" ]
                                    , button
                                        [ class "add-or-remove-frame-button"
                                        , onClick <| BigbitAddFrame
                                        ]
                                        [ text "+" ]
                                    , button
                                        [ class "add-or-remove-frame-button"
                                        , onClick <| BigbitRemoveFrame
                                        , disabled <|
                                            Array.length model.bigbitCreateData.highlightedComments
                                                <= 1
                                        ]
                                        [ text "-" ]
                                    , hr [] []
                                    , dynamicFrameButtons
                                    ]
                    in
                        div
                            []
                            [ div
                                [ class "comment-creator" ]
                                [ body
                                , tabBar
                                ]
                            ]
            in
                div
                    [ class "create-bigbit-code" ]
                    [ bigbitEditor
                    , bigbitCommentBox
                    ]
    in
        div
            [ class "create-bigbit" ]
            [ div
                [ class "sub-bar" ]
                [ button
                    [ class "sub-bar-button"
                    , onClick <| BigbitReset
                    ]
                    [ text "Reset" ]
                , case Bigbit.previousFrameRange model.bigbitCreateData shared.route of
                    Nothing ->
                        Util.hiddenDiv

                    Just ( filePath, _ ) ->
                        button
                            [ class "sub-bar-button previous-frame-location"
                            , onClick <| BigbitJumpToLineFromPreviousFrame filePath
                            ]
                            [ text "Previous Frame Location" ]
                , publishButton
                ]
            , createBigbitNavbar
            , case shared.route of
                Route.CreateBigbitNamePage ->
                    div
                        [ class "create-bigbit-name" ]
                        [ input
                            [ placeholder "Name"
                            , id "name-input"
                            , onInput BigbitUpdateName
                            , value model.bigbitCreateData.name
                            , Util.onKeydownPreventDefault
                                (\key ->
                                    if key == KK.Tab then
                                        Just NoOp
                                    else
                                        Nothing
                                )
                            ]
                            []
                        ]

                Route.CreateBigbitDescriptionPage ->
                    div
                        [ class "create-bigbit-description" ]
                        [ textarea
                            [ placeholder "Description"
                            , id "description-input"
                            , onInput BigbitUpdateDescription
                            , value model.bigbitCreateData.description
                            , Util.onKeydownPreventDefault
                                (\key ->
                                    if key == KK.Tab then
                                        Just NoOp
                                    else
                                        Nothing
                                )
                            ]
                            []
                        ]

                Route.CreateBigbitTagsPage ->
                    div
                        [ class "create-tidbit-tags" ]
                        [ input
                            [ placeholder "Tags"
                            , id "tags-input"
                            , onInput BigbitUpdateTagInput
                            , value model.bigbitCreateData.tagInput
                            , Util.onKeydownPreventDefault
                                (\key ->
                                    if key == KK.Enter then
                                        Just <| BigbitAddTag model.bigbitCreateData.tagInput
                                    else if key == KK.Tab then
                                        Just <| NoOp
                                    else
                                        Nothing
                                )
                            ]
                            []
                        , makeHTMLTags BigbitRemoveTag model.bigbitCreateData.tags
                        ]

                Route.CreateBigbitCodeIntroductionPage _ ->
                    bigbitCodeTab

                Route.CreateBigbitCodeFramePage frameNumber _ ->
                    bigbitCodeTab

                Route.CreateBigbitCodeConclusionPage _ ->
                    bigbitCodeTab

                -- Should never happen
                _ ->
                    Util.hiddenDiv
            ]


{-| View for creating a snipbit.
-}
createSnipbitView : Model -> Shared -> Html Msg
createSnipbitView model shared =
    let
        currentRoute : Route.Route
        currentRoute =
            shared.route

        viewMenu : Html Msg
        viewMenu =
            div
                [ classList
                    [ ( "hidden"
                      , String.isEmpty model.snipbitCreateData.languageQuery
                            || Util.isNotNothing
                                model.snipbitCreateData.language
                      )
                    ]
                ]
                [ Html.map
                    SnipbitUpdateACState
                    (AC.view
                        acViewConfig
                        model.snipbitCreateData.languageListHowManyToShow
                        model.snipbitCreateData.languageQueryACState
                        (filterLanguagesByQuery
                            model.snipbitCreateData.languageQuery
                            shared.languages
                        )
                    )
                ]

        acViewConfig : AC.ViewConfig ( Editor.Language, String )
        acViewConfig =
            let
                customizedLi keySelected mouseSelected languagePair =
                    { attributes =
                        [ classList
                            [ ( "lang-select-ac-item", True )
                            , ( "key-selected", keySelected || mouseSelected )
                            ]
                        ]
                    , children = [ Html.text (Tuple.second languagePair) ]
                    }
            in
                AC.viewConfig
                    { toId = (toString << Tuple.first)
                    , ul = [ class "lang-select-ac" ]
                    , li = customizedLi
                    }

        createSnipbitNavbar : Html Msg
        createSnipbitNavbar =
            div
                [ classList [ ( "create-tidbit-navbar", True ) ] ]
                [ div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
                          , currentRoute == Route.CreateSnipbitNamePage
                          )
                        , ( "filled-in", Util.isNotNothing <| Snipbit.createDataNameFilledIn model.snipbitCreateData )
                        ]
                    , onClick <| GoTo Route.CreateSnipbitNamePage
                    ]
                    [ text "Name"
                    , checkIcon
                    ]
                , div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
                          , currentRoute == Route.CreateSnipbitDescriptionPage
                          )
                        , ( "filled-in", Util.isNotNothing <| Snipbit.createDataDescriptionFilledIn model.snipbitCreateData )
                        ]
                    , onClick <| GoTo Route.CreateSnipbitDescriptionPage
                    ]
                    [ text "Description"
                    , checkIcon
                    ]
                , div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
                          , currentRoute == Route.CreateSnipbitLanguagePage
                          )
                        , ( "filled-in", Util.isNotNothing <| model.snipbitCreateData.language )
                        ]
                    , onClick <| GoTo Route.CreateSnipbitLanguagePage
                    ]
                    [ text "Language"
                    , checkIcon
                    ]
                , div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
                          , currentRoute == Route.CreateSnipbitTagsPage
                          )
                        , ( "filled-in", Util.isNotNothing <| Snipbit.createDataTagsFilledIn model.snipbitCreateData )
                        ]
                    , onClick <| GoTo Route.CreateSnipbitTagsPage
                    ]
                    [ text "Tags"
                    , checkIcon
                    ]
                , div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
                          , case currentRoute of
                                Route.CreateSnipbitCodeIntroductionPage ->
                                    True

                                Route.CreateSnipbitCodeConclusionPage ->
                                    True

                                Route.CreateSnipbitCodeFramePage _ ->
                                    True

                                _ ->
                                    False
                          )
                        , ( "filled-in", Snipbit.createDataCodeTabFilledIn model.snipbitCreateData )
                        ]
                    , onClick <| SnipbitGoToCodeTab
                    ]
                    [ text "Code"
                    , checkIcon
                    ]
                ]

        nameView : Html Msg
        nameView =
            div
                [ class "create-snipbit-name" ]
                [ input
                    [ placeholder "Name"
                    , id "name-input"
                    , onInput SnipbitUpdateName
                    , value model.snipbitCreateData.name
                    , Util.onKeydownPreventDefault
                        (\key ->
                            if key == KK.Tab then
                                Just NoOp
                            else
                                Nothing
                        )
                    ]
                    []
                ]

        descriptionView : Html Msg
        descriptionView =
            div
                [ class "create-snipbit-description" ]
                [ textarea
                    [ class "create-snipbit-description-box"
                    , placeholder "Description"
                    , id "description-input"
                    , onInput SnipbitUpdateDescription
                    , value model.snipbitCreateData.description
                    , Util.onKeydownPreventDefault
                        (\key ->
                            if key == KK.Tab then
                                Just NoOp
                            else
                                Nothing
                        )
                    ]
                    []
                ]

        languageView : Html Msg
        languageView =
            div
                [ class "create-snipbit-language" ]
                [ input
                    [ placeholder "Language"
                    , id "language-query-input"
                    , onInput SnipbitUpdateLanguageQuery
                    , value model.snipbitCreateData.languageQuery
                    , disabled <|
                        Util.isNotNothing
                            model.snipbitCreateData.language
                    , Util.onKeydownPreventDefault
                        (\key ->
                            if key == KK.Tab then
                                Just NoOp
                            else
                                Nothing
                        )
                    ]
                    []
                , viewMenu
                , button
                    [ onClick <| SnipbitSelectLanguage Nothing
                    , classList
                        [ ( "hidden"
                          , Util.isNothing
                                model.snipbitCreateData.language
                          )
                        ]
                    ]
                    [ text "change language" ]
                ]

        tagsView : Html Msg
        tagsView =
            div
                [ class "create-tidbit-tags" ]
                [ input
                    [ placeholder "Tags"
                    , id "tags-input"
                    , onInput SnipbitUpdateTagInput
                    , value model.snipbitCreateData.tagInput
                    , Util.onKeydownPreventDefault
                        (\key ->
                            if key == KK.Enter then
                                Just <| SnipbitAddTag model.snipbitCreateData.tagInput
                            else if key == KK.Tab then
                                Just <| NoOp
                            else
                                Nothing
                        )
                    ]
                    []
                , makeHTMLTags SnipbitRemoveTag model.snipbitCreateData.tags
                ]

        tidbitView : Html Msg
        tidbitView =
            let
                markdownOpen =
                    model.snipbitCreateData.previewMarkdown

                body =
                    div
                        [ class "comment-body" ]
                        [ div
                            [ class "preview-markdown"
                            , onClick SnipbitTogglePreviewMarkdown
                            ]
                            [ if markdownOpen then
                                text "Close Preview"
                              else
                                text "Markdown Preview"
                            ]
                        , case shared.route of
                            Route.CreateSnipbitCodeIntroductionPage ->
                                markdownOr
                                    markdownOpen
                                    model.snipbitCreateData.introduction
                                    (textarea
                                        [ placeholder "Introduction"
                                        , id "introduction-input"
                                        , onInput <| SnipbitUpdateIntroduction
                                        , value model.snipbitCreateData.introduction
                                        , Util.onKeydownPreventDefault
                                            (\key ->
                                                let
                                                    newKeysDown =
                                                        kkUpdateWrapper (KK.Down <| KK.toCode key) shared.keysDown
                                                in
                                                    if key == KK.Tab then
                                                        if newKeysDown == shared.keysDown then
                                                            Just NoOp
                                                        else if KK.isOneKeyPressed KK.Tab newKeysDown then
                                                            Just <| GoTo <| Route.CreateSnipbitCodeFramePage 1
                                                        else if KK.isTwoKeysPressed KK.Tab KK.Shift newKeysDown then
                                                            Just <| GoTo <| Route.CreateSnipbitTagsPage
                                                        else
                                                            Nothing
                                                    else
                                                        Nothing
                                            )
                                        ]
                                        []
                                    )

                            Route.CreateSnipbitCodeFramePage frameNumber ->
                                let
                                    frameIndex =
                                        frameNumber - 1

                                    frameText =
                                        (Array.get
                                            frameIndex
                                            model.snipbitCreateData.highlightedComments
                                        )
                                            |> Maybe.andThen .comment
                                            |> Maybe.withDefault ""
                                in
                                    markdownOr
                                        markdownOpen
                                        frameText
                                        (textarea
                                            [ placeholder <|
                                                "Frame "
                                                    ++ (toString frameNumber)
                                            , id "frame-input"
                                            , onInput <|
                                                SnipbitUpdateFrameComment frameIndex
                                            , value <| frameText
                                            , Util.onKeydownPreventDefault
                                                (\key ->
                                                    let
                                                        newKeysDown =
                                                            kkUpdateWrapper (KK.Down <| KK.toCode key) shared.keysDown
                                                    in
                                                        if key == KK.Tab then
                                                            if newKeysDown == shared.keysDown then
                                                                Just NoOp
                                                            else if KK.isOneKeyPressed KK.Tab newKeysDown then
                                                                Just <| GoTo <| Route.CreateSnipbitCodeFramePage (frameNumber + 1)
                                                            else if KK.isTwoKeysPressed KK.Tab KK.Shift newKeysDown then
                                                                Just <| GoTo <| Route.CreateSnipbitCodeFramePage (frameNumber - 1)
                                                            else
                                                                Nothing
                                                        else
                                                            Nothing
                                                )
                                            ]
                                            []
                                        )

                            Route.CreateSnipbitCodeConclusionPage ->
                                markdownOr
                                    markdownOpen
                                    model.snipbitCreateData.conclusion
                                    (textarea
                                        [ placeholder "Conclusion"
                                        , id "conclusion-input"
                                        , onInput <| SnipbitUpdateConclusion
                                        , value model.snipbitCreateData.conclusion
                                        , Util.onKeydownPreventDefault
                                            (\key ->
                                                let
                                                    newKeysDown =
                                                        kkUpdateWrapper (KK.Down <| KK.toCode key) shared.keysDown
                                                in
                                                    if key == KK.Tab then
                                                        if newKeysDown == shared.keysDown then
                                                            Just NoOp
                                                        else if KK.isOneKeyPressed KK.Tab newKeysDown then
                                                            Just NoOp
                                                        else if KK.isTwoKeysPressed KK.Tab KK.Shift newKeysDown then
                                                            Just <|
                                                                GoTo <|
                                                                    Route.CreateSnipbitCodeFramePage
                                                                        (Array.length model.snipbitCreateData.highlightedComments)
                                                        else
                                                            Nothing
                                                    else
                                                        Nothing
                                            )
                                        ]
                                        []
                                    )

                            -- Should never happen.
                            _ ->
                                div
                                    []
                                    []
                        ]

                tabBar =
                    let
                        dynamicFrameButtons =
                            div
                                [ class "frame-buttons-box" ]
                                (Array.toList <|
                                    Array.indexedMap
                                        (\index maybeHighlightedComment ->
                                            button
                                                [ onClick <|
                                                    GoTo <|
                                                        Route.CreateSnipbitCodeFramePage
                                                            (index + 1)
                                                , classList
                                                    [ ( "selected-frame"
                                                      , shared.route
                                                            == (Route.CreateSnipbitCodeFramePage <|
                                                                    index
                                                                        + 1
                                                               )
                                                      )
                                                    ]
                                                ]
                                                [ text <| toString <| index + 1 ]
                                        )
                                        model.snipbitCreateData.highlightedComments
                                )
                    in
                        div
                            [ class "comment-body-bottom-buttons"
                            , hidden <| markdownOpen
                            ]
                            [ button
                                [ onClick <|
                                    GoTo Route.CreateSnipbitCodeIntroductionPage
                                , classList
                                    [ ( "selected-frame"
                                      , shared.route
                                            == Route.CreateSnipbitCodeIntroductionPage
                                      )
                                    , ( "introduction-button", True )
                                    ]
                                ]
                                [ text "Introduction" ]
                            , button
                                [ onClick <|
                                    GoTo Route.CreateSnipbitCodeConclusionPage
                                , classList
                                    [ ( "selected-frame"
                                      , shared.route
                                            == Route.CreateSnipbitCodeConclusionPage
                                      )
                                    , ( "conclusion-button", True )
                                    ]
                                ]
                                [ text "Conclusion" ]
                            , button
                                [ class "add-or-remove-frame-button"
                                , onClick <| SnipbitAddFrame
                                ]
                                [ text "+" ]
                            , button
                                [ class "add-or-remove-frame-button"
                                , onClick <| SnipbitRemoveFrame
                                , disabled <|
                                    Array.length
                                        model.snipbitCreateData.highlightedComments
                                        <= 1
                                ]
                                [ text "-" ]
                            , hr [] []
                            , dynamicFrameButtons
                            ]
            in
                div
                    [ class "create-snipbit-code" ]
                    [ Editor.editor "create-snipbit-code-editor"
                    , div
                        [ class "comment-creator" ]
                        [ div
                            [ class "above-editor-text" ]
                            [ text <|
                                if currentRoute == Route.CreateSnipbitCodeIntroductionPage then
                                    "Snipbit introductions do not link to highlights, but you can browse and edit your code"
                                else if currentRoute == Route.CreateSnipbitCodeConclusionPage then
                                    "Snipbit conclusions do not link to highlights, but you can browse and edit your code"
                                else
                                    ""
                            ]
                        , body
                        , tabBar
                        ]
                    ]

        viewForTab : Html Msg
        viewForTab =
            case currentRoute of
                Route.CreateSnipbitNamePage ->
                    nameView

                Route.CreateSnipbitDescriptionPage ->
                    descriptionView

                Route.CreateSnipbitLanguagePage ->
                    languageView

                Route.CreateSnipbitTagsPage ->
                    tagsView

                Route.CreateSnipbitCodeIntroductionPage ->
                    tidbitView

                Route.CreateSnipbitCodeConclusionPage ->
                    tidbitView

                Route.CreateSnipbitCodeFramePage _ ->
                    tidbitView

                -- Default to name view.
                _ ->
                    nameView

        {- It should be disabled unles everything is filled out. -}
        publishButton =
            case Snipbit.createDataToPublicationData model.snipbitCreateData of
                Nothing ->
                    button
                        [ class "create-snipbit-disabled-publish-button"
                        , disabled True
                        ]
                        [ text "Publish" ]

                Just publicationData ->
                    button
                        [ classList
                            [ ( "create-snipbit-publish-button", True )
                            ]
                        , onClick <| SnipbitPublish publicationData
                        ]
                        [ text "Publish" ]
    in
        div
            [ class "create-snipbit" ]
            [ div
                [ class "sub-bar" ]
                [ button
                    [ class "create-snipbit-reset-button"
                    , onClick <| SnipbitReset
                    ]
                    [ text "Reset" ]
                , publishButton
                , case Snipbit.previousFrameRange model.snipbitCreateData shared.route of
                    Nothing ->
                        Util.hiddenDiv

                    Just _ ->
                        button
                            [ class "sub-bar-button previous-frame-location"
                            , onClick SnipbitJumpToLineFromPreviousFrame
                            ]
                            [ text "Previous Frame Location" ]
                ]
            , div
                []
                [ createSnipbitNavbar
                , viewForTab
                ]
            ]


{-| A semi-hack for flex-box justify-center but align-left.

@REFER http://stackoverflow.com/questions/18744164/flex-box-align-last-row-to-grid
-}
emptyFlexBoxesForAlignment : List (Html Msg)
emptyFlexBoxesForAlignment =
    (List.repeat 10 <|
        div [ class "empty-tidbit-box-for-flex-align" ] []
    )
