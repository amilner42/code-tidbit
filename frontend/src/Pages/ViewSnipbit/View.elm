module Pages.ViewSnipbit.View exposing (..)

import Array
import DefaultServices.InfixFunctions exposing (..)
import DefaultServices.Util as Util exposing (maybeMapWithDefault)
import Elements.Complex.AnswerQuestion as AnswerQuestion
import Elements.Complex.AskQuestion as AskQuestion
import Elements.Complex.EditAnswer as EditAnswer
import Elements.Complex.EditQuestion as EditQuestion
import Elements.Complex.ViewQuestion as ViewQuestion
import Elements.Simple.Editor as Editor
import Elements.Simple.Markdown as Markdown
import Elements.Simple.ProgressBar as ProgressBar exposing (State(..), TextFormat(Custom))
import Elements.Simple.QuestionList as QuestionList
import Html exposing (Html, a, button, div, i, text, textarea)
import Html.Attributes exposing (class, classList, disabled, hidden, href, id, placeholder, value)
import Html.Events exposing (onClick, onInput)
import Models.ContentPointer as ContentPointer
import Models.QA as QA
import Models.Range as Range
import Models.Rating as Rating
import Models.RequestTracker as RT
import Models.Route as Route
import Models.Snipbit as Snipbit
import Models.Story as Story
import Models.TidbitPointer as TidbitPointer
import Models.TutorialBookmark as TB
import Models.ViewerRelevantHC as ViewerRelevantHC
import Models.Vote as Vote
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
                                    , "Love It"
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
                        [ classList
                            [ ( "sub-bar-button heart-button", True )
                            , ( "cursor-progress"
                              , RT.isMakingRequest
                                    shared.apiRequestTracker
                                    (RT.AddOrRemoveOpinion ContentPointer.Snipbit)
                              )
                            ]
                        , onClick <| newMsg
                        ]
                        [ text buttonText ]

                ( Nothing, _ ) ->
                    button
                        [ class "sub-bar-button heart-button"
                        , onClick <| SetUserNeedsAuthModal "We want your feedback, sign up for free and get access to all of CodeTidbit in seconds!"
                        ]
                        [ text "Love It" ]

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
            , case
                ( Route.getViewingContentID shared.route
                , Route.isOnViewSnipbitTutorialRoute shared.route
                , isViewSnipbitRHCTabOpen model
                , model.relevantQuestions
                )
              of
                ( Just snipbitID, True, False, Just [] ) ->
                    button
                        [ class "sub-bar-button ask-question"
                        , onClick <|
                            case shared.user of
                                Just _ ->
                                    GoToAskQuestion

                                Nothing ->
                                    SetUserNeedsAuthModal
                                        ("We want to answer your question, sign up for free and get access to all of"
                                            ++ " CodeTidbit in seconds!"
                                        )
                        ]
                        [ text "Ask Question" ]

                ( Just snipbitID, True, False, Just _ ) ->
                    button
                        [ class "sub-bar-button view-relevant-questions"
                        , onClick <| GoToBrowseQuestionsWithCodePointer model.tutorialCodePointer
                        ]
                        [ text "Browse Related Questions" ]

                ( Just snipbitID, True, False, Nothing ) ->
                    Route.navigationNode
                        (Just
                            ( Route.Route <|
                                Route.ViewSnipbitQuestionsPage
                                    (Route.getFromStoryQueryParamOnViewSnipbitRoute shared.route)
                                    snipbitID
                            , GoToBrowseQuestionsWithCodePointer model.tutorialCodePointer
                            )
                        )
                        []
                        [ button
                            [ class "sub-bar-button view-all-questions" ]
                            [ text "Browse All Questions" ]
                        ]

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
            , case Route.getViewingContentID shared.route of
                Just snipbitID ->
                    button
                        [ classList
                            [ ( "sub-bar-button view-relevant-questions", True )
                            , ( "hidden"
                              , not <| Route.isOnViewSnipbitQARoute shared.route || isViewSnipbitRHCTabOpen model
                              )
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
                let
                    inTutorial =
                        not <| isViewSnipbitRHCTabOpen model || Route.isOnViewSnipbitQARoute shared.route

                    previousFrameRoute : Maybe Route.Route
                    previousFrameRoute =
                        case ( shared.route, not inTutorial ) of
                            ( Route.ViewSnipbitConclusionPage fromStoryID mongoID, False ) ->
                                Just <|
                                    Route.ViewSnipbitFramePage
                                        fromStoryID
                                        mongoID
                                        (Array.length snipbit.highlightedComments)

                            ( Route.ViewSnipbitFramePage fromStoryID mongoID frameNumber, False ) ->
                                Just <|
                                    Route.ViewSnipbitFramePage
                                        fromStoryID
                                        mongoID
                                        (frameNumber - 1)

                            _ ->
                                Nothing

                    nextFrameRoute : Maybe Route.Route
                    nextFrameRoute =
                        case ( shared.route, not inTutorial ) of
                            ( Route.ViewSnipbitIntroductionPage fromStoryID mongoID, False ) ->
                                Just <| Route.ViewSnipbitFramePage fromStoryID mongoID 1

                            ( Route.ViewSnipbitFramePage fromStoryID mongoID frameNumber, False ) ->
                                Just <| Route.ViewSnipbitFramePage fromStoryID mongoID (frameNumber + 1)

                            _ ->
                                Nothing

                    arrowBack =
                        Route.navigationNode
                            (previousFrameRoute ||> (\route -> ( Route.Route route, GoTo route )))
                            []
                            [ i
                                [ classList
                                    [ ( "material-icons action-button", True )
                                    , ( "disabled-icon", Util.isNothing previousFrameRoute )
                                    ]
                                ]
                                [ text "arrow_back" ]
                            ]

                    arrowForward =
                        Route.navigationNode
                            (nextFrameRoute ||> (\route -> ( Route.Route route, GoTo route )))
                            []
                            [ i
                                [ classList
                                    [ ( "material-icons action-button", True )
                                    , ( "disabled-icon", Util.isNothing nextFrameRoute )
                                    ]
                                ]
                                [ text "arrow_forward" ]
                            ]

                    introduction =
                        Route.navigationNode
                            (if inTutorial then
                                let
                                    route =
                                        Route.ViewSnipbitIntroductionPage
                                            (Route.getFromStoryQueryParamOnViewSnipbitRoute shared.route)
                                            snipbit.id
                                in
                                Just ( Route.Route route, GoTo route )
                             else
                                Nothing
                            )
                            []
                            [ div
                                [ classList
                                    [ ( "viewer-navbar-item", True )
                                    , ( "selected"
                                      , case shared.route of
                                            Route.ViewSnipbitIntroductionPage _ _ ->
                                                True

                                            _ ->
                                                False
                                      )
                                    , ( "disabled", not inTutorial )
                                    ]
                                ]
                                [ text "Introduction" ]
                            ]

                    conclusion =
                        Route.navigationNode
                            (if inTutorial then
                                let
                                    route =
                                        Route.ViewSnipbitConclusionPage
                                            (Route.getFromStoryQueryParamOnViewSnipbitRoute shared.route)
                                            snipbit.id
                                in
                                Just ( Route.Route route, GoTo route )
                             else
                                Nothing
                            )
                            []
                            [ div
                                [ classList
                                    [ ( "viewer-navbar-item", True )
                                    , ( "selected"
                                      , case shared.route of
                                            Route.ViewSnipbitConclusionPage _ _ ->
                                                True

                                            _ ->
                                                False
                                      )
                                    , ( "disabled", not inTutorial )
                                    ]
                                ]
                                [ text "Conclusion" ]
                            ]

                    progressBar =
                        ProgressBar.view
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
                                    && maybeMapWithDefault
                                        (not << ViewerRelevantHC.browsingFrames)
                                        True
                                        model.relevantHC
                            , textFormat =
                                Custom
                                    { notStarted = "0%"
                                    , started = \frameNumber -> "Frame " ++ toString frameNumber
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
                in
                div
                    [ class "viewer" ]
                    [ div
                        [ class "viewer-navbar" ]
                        [ arrowBack
                        , introduction
                        , progressBar
                        , conclusion
                        , arrowForward
                        ]
                    , Editor.view "view-snipbit-code-editor"
                    , div
                        [ class "comment-block" ]
                        [ commentBox snipbit model shared ]
                    ]
        ]


{-| Gets the comment box for the view snipbit page, can be the markdown for the intro/conclusion/frame or the markdown
with a few extra buttons for a selected range.
-}
commentBox : Snipbit.Snipbit -> Model -> Shared -> Html Msg
commentBox snipbit model shared =
    let
        -- To display if no relevant HC.
        htmlIfNoRelevantHC =
            Markdown.view [] <|
                case shared.route of
                    Route.ViewSnipbitIntroductionPage _ _ ->
                        snipbit.introduction

                    Route.ViewSnipbitConclusionPage _ _ ->
                        snipbit.conclusion

                    Route.ViewSnipbitFramePage _ _ frameNumber ->
                        Array.get
                            (frameNumber - 1)
                            snipbit.highlightedComments
                            |> Maybe.map .comment
                            |> Maybe.withDefault ""

                    _ ->
                        ""

        -- On the tutorial routes we display the tutorial or the relevantHC.
        tutorialRoute =
            case model.relevantHC of
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
                                                (GoTo
                                                    << Route.ViewSnipbitFramePage
                                                        (Route.getFromStoryQueryParamOnViewSnipbitRoute shared.route)
                                                        snipbit.id
                                                    << (+) 1
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
                                , Markdown.view
                                    []
                                    (Array.get index relevantHC
                                        |> Maybe.map (Tuple.second >> .comment)
                                        |> Maybe.withDefault ""
                                    )
                                ]

        viewQuestionView qa qaState tab question =
            ViewQuestion.view
                { msgTagger = ViewQuestionMsg snipbit.id question.id
                , textFieldKeyTracker = shared.textFieldKeyTracker
                , userID = shared.user ||> .id
                , tidbitAuthorID = qa.tidbitAuthor
                , tab = tab
                , question = question
                , answers = List.filter (.questionID >> (==) question.id) qa.answers
                , questionComments = List.filter (.questionID >> (==) question.id) qa.questionComments
                , answerComments = List.filter (.questionID >> (==) question.id) qa.answerComments
                , rateQuestionRequestInProgress =
                    RT.isMakingRequest shared.apiRequestTracker (RT.RateQuestion TidbitPointer.Snipbit)
                , rateAnswerRequestInProgress =
                    RT.isMakingRequest shared.apiRequestTracker (RT.RateAnswer TidbitPointer.Snipbit)
                , pinQuestionRequestInProgress =
                    RT.isMakingRequest shared.apiRequestTracker (RT.PinQuestion TidbitPointer.Snipbit)
                , pinAnswerRequestInProgress =
                    RT.isMakingRequest shared.apiRequestTracker (RT.PinAnswer TidbitPointer.Snipbit)
                , submitQuestionCommentRequestInProgress =
                    RT.isMakingRequest shared.apiRequestTracker (RT.SubmitQuestionComment TidbitPointer.Snipbit)
                , submitAnswerCommentRequestInProgress =
                    RT.isMakingRequest shared.apiRequestTracker (RT.SubmitAnswerComment TidbitPointer.Snipbit)
                , deleteAnswerRequestInProgress =
                    RT.isMakingRequest shared.apiRequestTracker (RT.DeleteAnswer TidbitPointer.Snipbit)
                , deleteAnswerCommentRequestInProgress =
                    RT.DeleteAnswerComment TidbitPointer.Snipbit >> RT.isMakingRequest shared.apiRequestTracker
                , deleteQuestionCommentRequestInProgress =
                    RT.DeleteQuestionComment TidbitPointer.Snipbit >> RT.isMakingRequest shared.apiRequestTracker
                , editAnswerCommentRequestInProgress =
                    RT.EditAnswerComment TidbitPointer.Snipbit >> RT.isMakingRequest shared.apiRequestTracker
                , editQuestionCommentRequestInProgress =
                    RT.EditQuestionComment TidbitPointer.Snipbit >> RT.isMakingRequest shared.apiRequestTracker
                , goToBrowseAllQuestions =
                    GoTo <|
                        Route.ViewSnipbitQuestionsPage
                            (Route.getFromStoryQueryParamOnViewSnipbitRoute shared.route)
                            snipbit.id
                , goToQuestionTab =
                    GoTo <|
                        Route.ViewSnipbitQuestionPage
                            (Route.getFromStoryQueryParamOnViewSnipbitRoute shared.route)
                            (Route.getTouringQuestionsQueryParamOnViewSnipbitQARoute shared.route)
                            snipbit.id
                            question.id
                , goToAnswersTab =
                    GoTo <|
                        Route.ViewSnipbitAnswersPage
                            (Route.getFromStoryQueryParamOnViewSnipbitRoute shared.route)
                            (Route.getTouringQuestionsQueryParamOnViewSnipbitQARoute shared.route)
                            snipbit.id
                            question.id
                , goToQuestionCommentsTab =
                    GoTo <|
                        Route.ViewSnipbitQuestionCommentsPage
                            (Route.getFromStoryQueryParamOnViewSnipbitRoute shared.route)
                            (Route.getTouringQuestionsQueryParamOnViewSnipbitQARoute shared.route)
                            snipbit.id
                            question.id
                            Nothing
                , goToAnswerTab =
                    \answer ->
                        GoTo <|
                            Route.ViewSnipbitAnswerPage
                                (Route.getFromStoryQueryParamOnViewSnipbitRoute shared.route)
                                (Route.getTouringQuestionsQueryParamOnViewSnipbitQARoute shared.route)
                                snipbit.id
                                answer.id
                , goToAnswerCommentsTab =
                    \answer ->
                        GoTo <|
                            Route.ViewSnipbitAnswerCommentsPage
                                (Route.getFromStoryQueryParamOnViewSnipbitRoute shared.route)
                                (Route.getTouringQuestionsQueryParamOnViewSnipbitQARoute shared.route)
                                snipbit.id
                                answer.id
                                Nothing
                , goToQuestionComment =
                    \questionComment ->
                        GoTo <|
                            Route.ViewSnipbitQuestionCommentsPage
                                (Route.getFromStoryQueryParamOnViewSnipbitRoute shared.route)
                                (Route.getTouringQuestionsQueryParamOnViewSnipbitQARoute shared.route)
                                snipbit.id
                                questionComment.questionID
                                (Just questionComment.id)
                , goToAnswerComment =
                    \answerComment ->
                        GoTo <|
                            Route.ViewSnipbitAnswerCommentsPage
                                (Route.getFromStoryQueryParamOnViewSnipbitRoute shared.route)
                                (Route.getTouringQuestionsQueryParamOnViewSnipbitQARoute shared.route)
                                snipbit.id
                                answerComment.answerID
                                (Just answerComment.id)
                , goToAnswerQuestion =
                    case shared.user of
                        Just _ ->
                            GoTo <|
                                Route.ViewSnipbitAnswerQuestion
                                    (Route.getFromStoryQueryParamOnViewSnipbitRoute shared.route)
                                    snipbit.id
                                    question.id

                        Nothing ->
                            SetUserNeedsAuthModal
                                ("Want to share your knowledge? Sign up for free and get access to all of CodeTidbit"
                                    ++ " in seconds!"
                                )
                , goToEditQuestion =
                    GoTo <|
                        Route.ViewSnipbitEditQuestion
                            (Route.getFromStoryQueryParamOnViewSnipbitRoute shared.route)
                            snipbit.id
                            question.id
                , goToEditAnswer =
                    GoTo
                        << Route.ViewSnipbitEditAnswer
                            (Route.getFromStoryQueryParamOnViewSnipbitRoute shared.route)
                            snipbit.id
                        << .id
                , upvoteQuestion = RateQuestion snipbit.id question.id (Just Vote.Upvote)
                , removeUpvoteQuestion = RateQuestion snipbit.id question.id Nothing
                , downvoteQuestion = RateQuestion snipbit.id question.id (Just Vote.Downvote)
                , removeDownvoteQuestion = RateQuestion snipbit.id question.id Nothing
                , upvoteAnswer = \answer -> RateAnswer snipbit.id answer.id (Just Vote.Upvote)
                , removeUpvoteAnswer = \answer -> RateAnswer snipbit.id answer.id Nothing
                , downvoteAnswer = \answer -> RateAnswer snipbit.id answer.id (Just Vote.Downvote)
                , removeDownvoteAnswer = \answer -> RateAnswer snipbit.id answer.id Nothing
                , pinQuestion = PinQuestion snipbit.id question.id True
                , unpinQuestion = PinQuestion snipbit.id question.id False
                , pinAnswer = \answer -> PinAnswer snipbit.id answer.id True
                , unpinAnswer = \answer -> PinAnswer snipbit.id answer.id False
                , deleteAnswer = .id >> DeleteAnswer snipbit.id question.id
                , commentOnQuestion = SubmitCommentOnQuestion snipbit.id question.id
                , commentOnAnswer = SubmitCommentOnAnswer snipbit.id question.id
                , deleteQuestionComment = DeleteCommentOnQuestion snipbit.id
                , deleteAnswerComment = DeleteCommentOnAnswer snipbit.id
                , editQuestionComment = EditCommentOnQuestion snipbit.id
                , editAnswerComment = EditCommentOnAnswer snipbit.id
                , handleUnauthAction = SetUserNeedsAuthModal
                }
                { questionCommentEdits = QA.getQuestionCommentEdits snipbit.id qaState
                , newQuestionComment = QA.getNewQuestionComment snipbit.id question.id qaState
                , answerCommentEdits = QA.getAnswerCommentEdits snipbit.id qaState
                , newAnswerComments = QA.getNewAnswerComments snipbit.id qaState
                , deletingComments = QA.getDeletingComments snipbit.id qaState
                , deletingAnswers = QA.getDeletingAnswers snipbit.id qaState
                }
    in
    case shared.route of
        Route.ViewSnipbitIntroductionPage _ _ ->
            tutorialRoute

        Route.ViewSnipbitConclusionPage _ _ ->
            tutorialRoute

        Route.ViewSnipbitFramePage _ _ _ ->
            tutorialRoute

        Route.ViewSnipbitQuestionsPage maybeStoryID snipbitID ->
            case model.qa of
                Just { questions } ->
                    let
                        ( isHighlighting, remainingQuestions ) =
                            case QA.getBrowseCodePointer snipbitID model.qaState of
                                Nothing ->
                                    ( False, questions )

                                Just codePointer ->
                                    if Range.isEmptyRange codePointer then
                                        ( False, questions )
                                    else
                                        ( True
                                        , List.filter
                                            (.codePointer >> Range.overlappingRanges codePointer)
                                            questions
                                        )
                    in
                    div
                        [ class "view-questions" ]
                        [ QuestionList.view
                            { questionBoxRenderConfig =
                                { onClickQuestionBox =
                                    \question ->
                                        GoTo <|
                                            Route.ViewSnipbitQuestionPage
                                                (Route.getFromStoryQueryParamOnViewSnipbitRoute shared.route)
                                                Nothing
                                                snipbitID
                                                question.id
                                }
                            , isHighlighting = isHighlighting
                            , allQuestionText = "All Questions"
                            , noQuestionsDuringSearchText = "None found"
                            , noQuestionsNotDuringSearchText = "Be the first to ask a question"
                            , askQuestion =
                                case shared.user of
                                    Just _ ->
                                        GoToAskQuestion

                                    Nothing ->
                                        SetUserNeedsAuthModal
                                            ("We want to answer your question, sign up for free and get access"
                                                ++ " to all of CodeTidbit in seconds!"
                                            )
                            }
                            remainingQuestions
                        ]

                Nothing ->
                    Util.hiddenDiv

        Route.ViewSnipbitQuestionPage maybeStoryID maybeTouringQuestions snipbitID questionID ->
            case model.qa of
                Just qa ->
                    case QA.getQuestion questionID qa.questions of
                        Just question ->
                            viewQuestionView qa model.qaState ViewQuestion.QuestionTab question

                        Nothing ->
                            Util.hiddenDiv

                Nothing ->
                    Util.hiddenDiv

        Route.ViewSnipbitAnswersPage maybeStoryID maybeTouringQuestions snipbitID questionID ->
            case model.qa of
                Just qa ->
                    case QA.getQuestion questionID qa.questions of
                        Just question ->
                            viewQuestionView qa model.qaState ViewQuestion.AnswersTab question

                        Nothing ->
                            Util.hiddenDiv

                Nothing ->
                    Util.hiddenDiv

        Route.ViewSnipbitAnswerPage maybeStoryID maybeTouringQuestions snipbitID answerID ->
            case model.qa of
                Just qa ->
                    case QA.getQuestionByAnswerID answerID qa of
                        Just question ->
                            viewQuestionView qa model.qaState (ViewQuestion.AnswerTab answerID) question

                        Nothing ->
                            Util.hiddenDiv

                Nothing ->
                    Util.hiddenDiv

        Route.ViewSnipbitQuestionCommentsPage maybeStoryID maybeTouringQuestions snipbitID questionID maybeCommentID ->
            case model.qa of
                Just qa ->
                    case QA.getQuestion questionID qa.questions of
                        Just question ->
                            viewQuestionView qa model.qaState (ViewQuestion.QuestionCommentsTab maybeCommentID) question

                        Nothing ->
                            Util.hiddenDiv

                Nothing ->
                    Util.hiddenDiv

        Route.ViewSnipbitAnswerCommentsPage maybeStoryID maybeTouringQuestions snipbitID answerID maybeCommentID ->
            case model.qa of
                Just qa ->
                    case QA.getQuestionByAnswerID answerID qa of
                        Just question ->
                            viewQuestionView qa model.qaState (ViewQuestion.AnswerCommentsTab answerID maybeCommentID) question

                        Nothing ->
                            Util.hiddenDiv

                Nothing ->
                    Util.hiddenDiv

        Route.ViewSnipbitAskQuestion maybeStoryID snipbitID ->
            let
                newQuestion =
                    QA.getNewQuestion snipbitID model.qaState
                        |> Maybe.withDefault QA.defaultNewQuestion
            in
            AskQuestion.view
                { msgTagger = AskQuestionMsg snipbitID
                , textFieldKeyTracker = shared.textFieldKeyTracker
                , askQuestionRequestInProgress =
                    RT.isMakingRequest shared.apiRequestTracker (RT.AskQuestion TidbitPointer.Snipbit)
                , askQuestion = AskQuestion snipbitID
                , isReadyCodePointer = not << Range.isEmptyRange
                , goToAllQuestions =
                    GoToBrowseQuestionsWithCodePointer <|
                        (QA.getNewQuestion snipbitID model.qaState |||> .codePointer)
                }
                newQuestion

        Route.ViewSnipbitAnswerQuestion maybeStoryID snipbitID questionID ->
            case model.qa ||> .questions |||> QA.getQuestion questionID of
                Just question ->
                    AnswerQuestion.view
                        { msgTagger = AnswerQuestionMsg snipbitID question
                        , textFieldKeyTracker = shared.textFieldKeyTracker
                        , forQuestion = question
                        , answerQuestionRequestInProgress =
                            RT.isMakingRequest
                                shared.apiRequestTracker
                                (RT.AnswerQuestion TidbitPointer.Snipbit)
                        , answerQuestion = AnswerQuestion snipbitID questionID
                        , goToAllAnswers =
                            GoTo <|
                                Route.ViewSnipbitAnswersPage
                                    (Route.getFromStoryQueryParamOnViewSnipbitRoute shared.route)
                                    (Route.getTouringQuestionsQueryParamOnViewSnipbitQARoute shared.route)
                                    snipbitID
                                    questionID
                        }
                        (QA.getNewAnswer snipbitID questionID model.qaState
                            ?> QA.defaultNewAnswer
                        )

                -- Will never happen, if the question doesn't exist we will redirect.
                Nothing ->
                    Util.hiddenDiv

        Route.ViewSnipbitEditQuestion maybeStoryID snipbitID questionID ->
            case model.qa ||> .questions |||> QA.getQuestion questionID of
                Just question ->
                    let
                        questionEdit =
                            QA.getQuestionEdit snipbitID questionID model.qaState
                                ?> QA.questionEditFromQuestion question
                    in
                    EditQuestion.view
                        { msgTagger = EditQuestionMsg snipbitID question
                        , textFieldKeyTracker = shared.textFieldKeyTracker
                        , editQuestionRequestInProgress =
                            RT.isMakingRequest
                                shared.apiRequestTracker
                                (RT.UpdateQuestion TidbitPointer.Snipbit)
                        , isReadyCodePointer = not << Range.isEmptyRange
                        , editQuestion = EditQuestion snipbitID questionID
                        }
                        questionEdit

                -- This will never happen, if the question doesn't exist we will have redirected URLs.
                _ ->
                    Util.hiddenDiv

        Route.ViewSnipbitEditAnswer maybeStoryID snipbitID answerID ->
            case
                ( model.qa ||> .answers |||> QA.getAnswer answerID
                , model.qa |||> QA.getQuestionByAnswerID answerID
                )
            of
                ( Just answer, Just question ) ->
                    EditAnswer.view
                        { msgTagger = EditAnswerMsg snipbitID answerID answer
                        , textFieldKeyTracker = shared.textFieldKeyTracker
                        , editAnswerRequestInProgress =
                            RT.isMakingRequest shared.apiRequestTracker (RT.UpdateAnswer TidbitPointer.Snipbit)
                        , editAnswer = EditAnswer snipbitID question.id answerID
                        , forQuestion = question
                        }
                        (QA.getAnswerEdit snipbitID answerID model.qaState
                            ?> QA.answerEditFromAnswer answer
                        )

                -- Will never happen, if answer/question don't exist we will redirect.
                _ ->
                    Util.hiddenDiv

        _ ->
            Util.hiddenDiv
