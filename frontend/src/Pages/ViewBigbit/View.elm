module Pages.ViewBigbit.View exposing (..)

import Array
import DefaultServices.InfixFunctions exposing (..)
import DefaultServices.Util as Util exposing (maybeMapWithDefault)
import Elements.Complex.AskQuestion as AskQuestion
import Elements.Complex.EditQuestion as EditQuestion
import Elements.Simple.Editor as Editor
import Elements.Simple.FileStructure as FS
import Elements.Simple.Markdown as Markdown
import Elements.Simple.ProgressBar as ProgressBar exposing (TextFormat(Custom), State(..))
import Elements.Simple.QuestionList as QuestionList
import Html exposing (Html, div, button, text, i)
import Html.Attributes exposing (class, classList, hidden)
import Html.Events exposing (onClick)
import Models.Bigbit as Bigbit
import Models.Completed as Completed
import Models.QA as QA
import Models.Range as Range
import Models.Rating as Rating
import Models.Route as Route
import Models.Story as Story
import Models.TutorialBookmark as TB
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
            (isBigbitRHCTabOpen model.relevantHC) || (not <| Route.isOnViewBigbitTutorialRoute shared.route)

        fsOpen =
            maybeMapWithDefault Bigbit.isFSOpen False (Maybe.map .fs model.bigbit)

        onRouteWithFS =
            Route.isOnViewBigbitRouteWithFS shared.route

        currentRoute =
            shared.route

        userDoneBigbit =
            case ( shared.user, model.isCompleted ) of
                ( Just _, Just { complete } ) ->
                    complete

                _ ->
                    False
    in
        div
            [ classList
                [ ( "view-bigbit-page", True )
                , ( "fs-closed", not <| fsOpen && onRouteWithFS )
                ]
            ]
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
                , case ( shared.viewingStory, model.bigbit ) of
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
                            , ProgressBar.view
                                { state =
                                    case model.bookmark of
                                        TB.Introduction ->
                                            NotStarted

                                        TB.FrameNumber frameNumber ->
                                            Started frameNumber

                                        TB.Conclusion ->
                                            Completed
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
                                        { notStarted = "0%"
                                        , started = (\frameNumber -> "Frame " ++ (toString frameNumber))
                                        , done = "100%"
                                        }
                                , shiftLeft = True
                                , alreadyComplete = { complete = userDoneBigbit, for = ProgressBar.Tidbit }
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
                            [ FS.view
                                { isFileSelected =
                                    (\absolutePath ->
                                        Route.viewBigbitPageCurrentActiveFile currentRoute bigbit model.qa model.qaState
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
                                    if fsOpen || (not onRouteWithFS) then
                                        NoOp
                                    else
                                        ToggleFS
                                ]
                                [ text <|
                                    case
                                        Route.viewBigbitPageCurrentActiveFile currentRoute bigbit model.qa model.qaState
                                    of
                                        Nothing ->
                                            "No File Selected"

                                        Just activeFile ->
                                            activeFile
                                ]
                            ]
                        , Editor.view "view-bigbit-code-editor"
                        , div
                            [ class "comment-block" ]
                            [ viewBigbitCommentBox bigbit model.relevantHC currentRoute model.qa model.qaState ]
                        ]
            ]


{-| Gets the comment box for the view bigbit page, can be the markdown for the intro/conclusion/frame, the FS, or the
markdown with a few extra buttons for a selected range.
-}
viewBigbitCommentBox :
    Bigbit.Bigbit
    -> Maybe ViewingBigbitRelevantHC
    -> Route.Route
    -> Maybe QA.BigbitQA
    -> QA.BigbitQAState
    -> Html Msg
viewBigbitCommentBox bigbit maybeRHC route maybeQA qaState =
    let
        tutorialRoute =
            let
                rhcTabOpen =
                    isBigbitRHCTabOpen maybeRHC

                tutorialOpen =
                    not <| rhcTabOpen
            in
                div
                    []
                    [ Markdown.view [ hidden <| not <| tutorialOpen ] <|
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
                                        , Markdown.view
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
    in
        case route of
            Route.ViewBigbitIntroductionPage _ _ _ ->
                tutorialRoute

            Route.ViewBigbitFramePage _ _ _ _ ->
                tutorialRoute

            Route.ViewBigbitConclusionPage _ _ _ ->
                tutorialRoute

            Route.ViewBigbitQuestionsPage _ bigbitID ->
                case maybeQA of
                    Just qa ->
                        let
                            browseCodePointer =
                                qaState |> QA.getBrowseCodePointer bigbitID

                            ( isHighlighting, remainingQuestions ) =
                                case browseCodePointer of
                                    Nothing ->
                                        ( False, qa.questions )

                                    Just ({ file, range } as codePointer) ->
                                        if Range.isEmptyRange range then
                                            ( False, qa.questions )
                                        else
                                            ( True
                                            , qa.questions
                                                |> List.filter
                                                    (.codePointer >> QA.isBigbitCodePointerOverlap codePointer)
                                            )
                        in
                            div
                                [ class "view-questions" ]
                                [ QuestionList.view
                                    { questionBoxRenderConfig =
                                        { onClickQuestionBox =
                                            (\question ->
                                                GoTo <|
                                                    Route.ViewBigbitQuestionPage
                                                        (Route.getFromStoryQueryParamOnViewBigbitRoute route)
                                                        (Route.getTouringQuestionsQueryParamOnViewBigbitQARoute route)
                                                        bigbitID
                                                        question.id
                                            )
                                        }
                                    , onClickAskQuestion = GoToAskQuestionWithCodePointer bigbitID browseCodePointer
                                    , isHighlighting = isHighlighting
                                    }
                                    remainingQuestions
                                ]

                    Nothing ->
                        Util.hiddenDiv

            Route.ViewBigbitAskQuestion maybeStoryID bigbitID ->
                AskQuestion.view
                    { msgTagger = AskQuestionMsg bigbitID
                    , askQuestion = AskQuestion bigbitID
                    , isReadyCodePointer = .range >> Range.isEmptyRange >> not
                    , goToAllQuestions = GoTo <| Route.ViewBigbitQuestionsPage maybeStoryID bigbitID
                    }
                    (QA.getNewQuestion bigbitID qaState ?> QA.defaultNewQuestion)

            Route.ViewBigbitEditQuestion maybeStoryID bigbitID questionID ->
                case maybeQA ||> .questions |||> QA.getQuestionByID questionID of
                    Just question ->
                        let
                            questionEdit =
                                QA.getQuestionEditByID bigbitID questionID qaState
                                    ?> QA.questionEditFromQuestion question
                        in
                            EditQuestion.view
                                { msgTagger = EditQuestionMsg bigbitID question
                                , isReadyCodePointer = .range >> Range.isEmptyRange >> not
                                , editQuestion = EditQuestion bigbitID questionID
                                }
                                questionEdit

                    Nothing ->
                        Util.hiddenDiv

            _ ->
                Util.hiddenDiv
