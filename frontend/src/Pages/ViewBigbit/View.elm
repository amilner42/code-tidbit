module Pages.ViewBigbit.View exposing (..)

import Api
import Array
import DefaultServices.InfixFunctions exposing (..)
import DefaultServices.Util as Util exposing (maybeMapWithDefault)
import Elements.Complex.AnswerQuestion as AnswerQuestion
import Elements.Complex.AskQuestion as AskQuestion
import Elements.Complex.EditAnswer as EditAnswer
import Elements.Complex.EditQuestion as EditQuestion
import Elements.Complex.ViewQuestion as ViewQuestion
import Elements.Simple.Editor as Editor
import Elements.Simple.FileStructure as FS
import Elements.Simple.Markdown as Markdown
import Elements.Simple.ProgressBar as ProgressBar exposing (State(..), TextFormat(Custom))
import Elements.Simple.QuestionList as QuestionList
import ExplanatoryBlurbs
import Html exposing (Html, button, div, i, text)
import Html.Attributes exposing (class, classList, hidden)
import Html.Events exposing (onClick)
import Models.Bigbit as Bigbit
import Models.ContentPointer as ContentPointer
import Models.QA as QA
import Models.Range as Range
import Models.Rating as Rating
import Models.RequestTracker as RT
import Models.Route as Route
import Models.Story as Story
import Models.TidbitPointer as TidbitPointer
import Models.ViewerRelevantHC as ViewerRelevantHC
import Models.Vote as Vote
import Pages.Messages as BaseMessage
import Pages.Model exposing (Shared)
import Pages.ViewBigbit.Messages exposing (..)
import Pages.ViewBigbit.Model exposing (..)


{-| `ViewBigbit` view.
-}
view : (Msg -> BaseMessage.Msg) -> Model -> Shared -> Html BaseMessage.Msg
view subMsg model shared =
    let
        rhcTabOpen =
            isBigbitRHCTabOpen model.relevantHC

        goingThroughTutorial =
            Route.isOnViewBigbitTutorialRoute shared.route && not rhcTabOpen

        fsOpen =
            fsAllowed && (model.bigbit ||> .fs ||> Bigbit.isFSOpen ?> False)

        fsAllowed =
            Route.isOnViewBigbitQARouteWithFS shared.route || goingThroughTutorial

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
            , ( "fs-closed", not <| fsOpen )
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
                              , RT.isMakingRequest shared.apiRequestTracker <|
                                    RT.AddOrRemoveOpinion ContentPointer.Bigbit
                              )
                            ]
                        , onClick <| subMsg newMsg
                        ]
                        [ text buttonText ]

                ( Nothing, _ ) ->
                    button
                        [ class "sub-bar-button heart-button"
                        , onClick <| BaseMessage.SetUserNeedsAuthModal ExplanatoryBlurbs.needAuthSignUpMessage
                        ]
                        [ text "Love It" ]

                _ ->
                    Util.hiddenDiv
            , case ( shared.viewingStory, model.bigbit ) of
                ( Just story, Just bigbit ) ->
                    case Story.getPreviousTidbitRoute bigbit.id story.id story.tidbits of
                        Just previousTidbitRoute ->
                            button
                                [ class "sub-bar-button traverse-tidbit-button"
                                , onClick <| BaseMessage.GoTo { wipeModalError = False } previousTidbitRoute
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
                        , onClick <| BaseMessage.GoTo { wipeModalError = False } <| Route.ViewStoryPage story.id
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
                                , onClick <| BaseMessage.GoTo { wipeModalError = False } nextTidbitRoute
                                ]
                                [ text "Next Tidbit" ]

                        _ ->
                            Util.hiddenDiv

                _ ->
                    Util.hiddenDiv
            , case
                ( model.bigbit
                , Route.isOnViewBigbitTutorialRoute shared.route
                , isBigbitRHCTabOpen model.relevantHC
                , model.relevantQuestions
                )
              of
                ( Just bigbit, True, False, Just [] ) ->
                    button
                        [ class "sub-bar-button ask-question"
                        , onClick <|
                            case shared.user of
                                Just _ ->
                                    subMsg <|
                                        GoToAskQuestionWithCodePointer bigbit.id model.tutorialCodePointer

                                Nothing ->
                                    BaseMessage.SetUserNeedsAuthModal <|
                                        "We want to answer your question, sign up for free and get access to all of"
                                            ++ " CodeTidbit in seconds!"
                        ]
                        [ text "Ask Question" ]

                ( Just bigbit, True, False, Just _ ) ->
                    button
                        [ class "sub-bar-button view-relevant-questions"
                        , onClick <| subMsg <| GoToBrowseQuestionsWithCodePointer bigbit.id model.tutorialCodePointer
                        ]
                        [ text "Browse Related Questions" ]

                ( Just bigbit, True, False, Nothing ) ->
                    Route.navigationNode
                        (Just
                            ( Route.Route <|
                                Route.ViewBigbitQuestionsPage
                                    (Route.getFromStoryQueryParamOnViewBigbitRoute shared.route)
                                    bigbit.id
                              -- We keep the codePointer the same, and if their is no codePointer, we make sure to
                              -- load the same file if they are looking at a file.
                            , subMsg <|
                                GoToBrowseQuestionsWithCodePointer
                                    bigbit.id
                                    (case model.tutorialCodePointer of
                                        Just _ ->
                                            model.tutorialCodePointer

                                        Nothing ->
                                            case
                                                Route.viewBigbitPageCurrentActiveFile
                                                    shared.route
                                                    bigbit
                                                    model.qa
                                                    model.qaState
                                            of
                                                Just file ->
                                                    Just { file = file, range = Range.zeroRange }

                                                Nothing ->
                                                    Nothing
                                    )
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
                , onClick <| subMsg BrowseRelevantHC
                ]
                [ text "Browse Related Frames" ]
            , case Route.getViewingContentID shared.route of
                Just bigbitID ->
                    button
                        [ classList
                            [ ( "sub-bar-button view-relevant-questions", True )
                            , ( "hidden"
                              , not <| Route.isOnViewBigbitQARoute shared.route || rhcTabOpen
                              )
                            ]
                        , onClick <|
                            BaseMessage.GoTo { wipeModalError = False } <|
                                routeForBookmark
                                    (Route.getFromStoryQueryParamOnViewBigbitRoute shared.route)
                                    bigbitID
                                    model.bookmark
                        ]
                        [ text "Resume Tutorial" ]

                Nothing ->
                    Util.hiddenDiv
            ]
        , case model.bigbit of
            Nothing ->
                Util.hiddenDiv

            Just bigbit ->
                let
                    previousFrameRoute =
                        case ( currentRoute, goingThroughTutorial ) of
                            ( Route.ViewBigbitFramePage fromStoryID mongoID frameNumber _, True ) ->
                                if frameNumber == 1 then
                                    Nothing
                                else
                                    Just <|
                                        Route.ViewBigbitFramePage
                                            fromStoryID
                                            mongoID
                                            (frameNumber - 1)
                                            Nothing

                            _ ->
                                Nothing

                    nextFrameRoute =
                        case ( currentRoute, goingThroughTutorial ) of
                            ( Route.ViewBigbitFramePage fromStoryID mongoID frameNumber _, True ) ->
                                if frameNumber == Array.length bigbit.highlightedComments then
                                    Nothing
                                else
                                    Just <| Route.ViewBigbitFramePage fromStoryID mongoID (frameNumber + 1) Nothing

                            _ ->
                                Nothing

                    arrowBack =
                        Route.navigationNode
                            (previousFrameRoute
                                ||> (\route ->
                                        ( Route.Route route
                                        , BaseMessage.GoTo { wipeModalError = False } route
                                        )
                                    )
                            )
                            []
                            [ i
                                [ classList
                                    [ ( "material-icons action-button", True )
                                    , ( "disabled-icon", Util.isNothing previousFrameRoute )
                                    ]
                                ]
                                [ text "arrow_back" ]
                            ]

                    progressBar =
                        ProgressBar.view
                            { state = Started model.bookmark
                            , maxPosition = Array.length bigbit.highlightedComments
                            , disabledStyling = not goingThroughTutorial
                            , onClickMsg = subMsg BackToTutorialSpot
                            , allowClick =
                                goingThroughTutorial
                                    && (case shared.route of
                                            Route.ViewBigbitFramePage _ _ _ _ ->
                                                True

                                            _ ->
                                                False
                                       )
                            , textFormat =
                                Custom
                                    { notStarted = "0%"
                                    , started = \frameNumber -> "Frame " ++ toString frameNumber
                                    , done = "100%"
                                    }
                            , shiftLeft = False
                            , alreadyComplete = { complete = userDoneBigbit, for = ProgressBar.Tidbit }
                            }

                    arrowForward =
                        Route.navigationNode
                            (nextFrameRoute
                                ||> (\route ->
                                        ( Route.Route route
                                        , BaseMessage.GoTo { wipeModalError = False } route
                                        )
                                    )
                            )
                            []
                            [ i
                                [ classList
                                    [ ( "material-icons action-button", True )
                                    , ( "disabled-icon", Util.isNothing nextFrameRoute )
                                    ]
                                ]
                                [ text "arrow_forward" ]
                            ]
                in
                div
                    [ class "viewer" ]
                    [ div
                        [ class "viewer-navbar" ]
                        [ arrowBack
                        , progressBar
                        , arrowForward
                        ]
                    , div
                        [ class "view-bigbit-fs" ]
                        [ FS.view
                            { isFileSelected =
                                \absolutePath ->
                                    Route.viewBigbitPageCurrentActiveFile currentRoute bigbit model.qa model.qaState
                                        |> Maybe.map (FS.isSameFilePath absolutePath)
                                        |> Maybe.withDefault False
                            , fileSelectedMsg = subMsg << SelectFile
                            , folderSelectedMsg = subMsg << ToggleFolder
                            }
                            bigbit.fs
                        , i
                            [ class "close-fs-icon material-icons"
                            , onClick <| subMsg ToggleFS
                            ]
                            [ text "close" ]
                        , div
                            [ classList
                                [ ( "above-editor-text", True )
                                , ( "cursor-not-allowed", not fsAllowed )
                                , ( "cursor-default", fsOpen )
                                ]
                            , onClick <|
                                if fsOpen || not fsAllowed then
                                    BaseMessage.NoOp
                                else
                                    subMsg <| ToggleFS
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
                        [ viewBigbitCommentBox subMsg bigbit model shared ]
                    ]
        ]


{-| Gets the comment box for the view bigbit page, can be the markdown for the code frame, the FS, or the
markdown with a few extra buttons for a selected range.
-}
viewBigbitCommentBox : (Msg -> BaseMessage.Msg) -> Bigbit.Bigbit -> Model -> Shared -> Html BaseMessage.Msg
viewBigbitCommentBox subMsg bigbit model shared =
    let
        tutorialRoute =
            let
                rhcTabOpen =
                    isBigbitRHCTabOpen model.relevantHC

                tutorialOpen =
                    not <| rhcTabOpen
            in
            div
                []
                [ Markdown.view [ hidden <| not <| tutorialOpen ] <|
                    case shared.route of
                        Route.ViewBigbitFramePage _ _ frameNumber _ ->
                            Array.get (frameNumber - 1) bigbit.highlightedComments
                                ||> .comment
                                ?> ""

                        _ ->
                            ""
                , div
                    [ class "view-relevant-hc"
                    , hidden <| not <| rhcTabOpen
                    ]
                    (case model.relevantHC of
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
                                        , onClick <| subMsg PreviousRelevantHC
                                        ]
                                        [ text "Previous" ]
                                    , Route.navigationNode
                                        (Array.get index rhc.relevantHC
                                            ||> Tuple.first
                                            ||> (+) 1
                                            ||> (\frameNumber ->
                                                    Route.ViewBigbitFramePage
                                                        (Route.getFromStoryQueryParamOnViewBigbitRoute shared.route)
                                                        bigbit.id
                                                        frameNumber
                                                        Nothing
                                                )
                                            ||> (\route ->
                                                    ( Route.Route route
                                                    , BaseMessage.GoTo { wipeModalError = False } route
                                                    )
                                                )
                                        )
                                        []
                                        [ div
                                            [ class "above-comment-block-button go-to-frame-button" ]
                                            [ text "Jump To Frame" ]
                                        ]
                                    , div
                                        [ classList
                                            [ ( "above-comment-block-button next-button", True )
                                            , ( "disabled", ViewerRelevantHC.onLastFrame rhc )
                                            ]
                                        , onClick <| subMsg NextRelevantHC
                                        ]
                                        [ text "Next" ]
                                    ]
                    )
                ]

        viewQuestionView qa qaState tab question =
            ViewQuestion.view
                { subMsg = subMsg << ViewQuestionMsg bigbit.id question.id
                , textFieldKeyTracker = shared.textFieldKeyTracker
                , userID = shared.user ||> .id
                , tidbitAuthorID = bigbit.author
                , tab = tab
                , question = question
                , answers = List.filter (.questionID >> (==) question.id) qa.answers
                , questionComments = List.filter (.questionID >> (==) question.id) qa.questionComments
                , answerComments = List.filter (.questionID >> (==) question.id) qa.answerComments
                , rateQuestionRequestInProgress =
                    RT.isMakingRequest shared.apiRequestTracker (RT.RateQuestion TidbitPointer.Bigbit)
                , rateAnswerRequestInProgress =
                    RT.isMakingRequest shared.apiRequestTracker (RT.RateAnswer TidbitPointer.Bigbit)
                , pinQuestionRequestInProgress =
                    RT.isMakingRequest shared.apiRequestTracker (RT.PinQuestion TidbitPointer.Bigbit)
                , pinAnswerRequestInProgress =
                    RT.isMakingRequest shared.apiRequestTracker (RT.PinAnswer TidbitPointer.Bigbit)
                , submitQuestionCommentRequestInProgress =
                    RT.isMakingRequest shared.apiRequestTracker (RT.SubmitQuestionComment TidbitPointer.Bigbit)
                , submitAnswerCommentRequestInProgress =
                    RT.isMakingRequest shared.apiRequestTracker (RT.SubmitAnswerComment TidbitPointer.Bigbit)
                , deleteAnswerRequestInProgress =
                    RT.isMakingRequest shared.apiRequestTracker (RT.DeleteAnswer TidbitPointer.Bigbit)
                , deleteAnswerCommentRequestInProgress =
                    RT.DeleteAnswerComment TidbitPointer.Bigbit >> RT.isMakingRequest shared.apiRequestTracker
                , deleteQuestionCommentRequestInProgress =
                    RT.DeleteQuestionComment TidbitPointer.Bigbit >> RT.isMakingRequest shared.apiRequestTracker
                , editAnswerCommentRequestInProgress =
                    RT.EditAnswerComment TidbitPointer.Bigbit >> RT.isMakingRequest shared.apiRequestTracker
                , editQuestionCommentRequestInProgress =
                    RT.EditQuestionComment TidbitPointer.Bigbit >> RT.isMakingRequest shared.apiRequestTracker
                , allQuestionsND =
                    ( Route.Route <|
                        Route.ViewBigbitQuestionsPage
                            (Route.getFromStoryQueryParamOnViewBigbitRoute shared.route)
                            bigbit.id
                    , subMsg <|
                        GoToBrowseQuestionsWithCodePointer
                            bigbit.id
                            (Route.viewBigbitPageCurrentActiveFile shared.route bigbit (Just qa) qaState
                                ||> (\file -> { file = file, range = Range.zeroRange })
                            )
                    )
                , questionND =
                    Route.ViewBigbitQuestionPage
                        (Route.getFromStoryQueryParamOnViewBigbitRoute shared.route)
                        (Route.getTouringQuestionsQueryParamOnViewBigbitQARoute shared.route)
                        bigbit.id
                        question.id
                        |> (\route -> ( Route.Route route, BaseMessage.GoTo { wipeModalError = False } route ))
                , allAnswersND =
                    Route.ViewBigbitAnswersPage
                        (Route.getFromStoryQueryParamOnViewBigbitRoute shared.route)
                        (Route.getTouringQuestionsQueryParamOnViewBigbitQARoute shared.route)
                        bigbit.id
                        question.id
                        |> (\route -> ( Route.Route route, BaseMessage.GoTo { wipeModalError = False } route ))
                , questionCommentsND =
                    Route.ViewBigbitQuestionCommentsPage
                        (Route.getFromStoryQueryParamOnViewBigbitRoute shared.route)
                        (Route.getTouringQuestionsQueryParamOnViewBigbitQARoute shared.route)
                        bigbit.id
                        question.id
                        Nothing
                        |> (\route -> ( Route.Route route, BaseMessage.GoTo { wipeModalError = False } route ))
                , answerND =
                    \answer ->
                        let
                            route =
                                Route.ViewBigbitAnswerPage
                                    (Route.getFromStoryQueryParamOnViewBigbitRoute shared.route)
                                    (Route.getTouringQuestionsQueryParamOnViewBigbitQARoute shared.route)
                                    bigbit.id
                                    answer.id
                        in
                        ( Route.Route route, BaseMessage.GoTo { wipeModalError = False } route )
                , answerCommentsND =
                    \answer ->
                        let
                            route =
                                Route.ViewBigbitAnswerCommentsPage
                                    (Route.getFromStoryQueryParamOnViewBigbitRoute shared.route)
                                    (Route.getTouringQuestionsQueryParamOnViewBigbitQARoute shared.route)
                                    bigbit.id
                                    answer.id
                                    Nothing
                        in
                        ( Route.Route route, BaseMessage.GoTo { wipeModalError = False } route )
                , goToQuestionComment =
                    \questionComment ->
                        BaseMessage.GoTo { wipeModalError = False } <|
                            Route.ViewBigbitQuestionCommentsPage
                                (Route.getFromStoryQueryParamOnViewBigbitRoute shared.route)
                                (Route.getTouringQuestionsQueryParamOnViewBigbitQARoute shared.route)
                                bigbit.id
                                question.id
                                (Just questionComment.id)
                , goToAnswerComment =
                    \answerComment ->
                        BaseMessage.GoTo { wipeModalError = False } <|
                            Route.ViewBigbitAnswerCommentsPage
                                (Route.getFromStoryQueryParamOnViewBigbitRoute shared.route)
                                (Route.getTouringQuestionsQueryParamOnViewBigbitQARoute shared.route)
                                bigbit.id
                                answerComment.answerID
                                (Just answerComment.id)
                , goToAnswerQuestion =
                    case shared.user of
                        Just _ ->
                            BaseMessage.GoTo { wipeModalError = False } <|
                                Route.ViewBigbitAnswerQuestion
                                    (Route.getFromStoryQueryParamOnViewBigbitRoute shared.route)
                                    bigbit.id
                                    question.id

                        Nothing ->
                            BaseMessage.SetUserNeedsAuthModal
                                ("Want to share your knowledge? Sign up for free and get access to all of CodeTidbit"
                                    ++ " in seconds!"
                                )
                , goToEditQuestion =
                    BaseMessage.GoTo { wipeModalError = False } <|
                        Route.ViewBigbitEditQuestion
                            (Route.getFromStoryQueryParamOnViewBigbitRoute shared.route)
                            bigbit.id
                            question.id
                , goToEditAnswer =
                    \answer ->
                        BaseMessage.GoTo { wipeModalError = False } <|
                            Route.ViewBigbitEditAnswer
                                (Route.getFromStoryQueryParamOnViewBigbitRoute shared.route)
                                bigbit.id
                                answer.id
                , upvoteQuestion = subMsg <| RateQuestion bigbit.id question.id (Just Vote.Upvote)
                , removeUpvoteQuestion = subMsg <| RateQuestion bigbit.id question.id Nothing
                , downvoteQuestion = subMsg <| RateQuestion bigbit.id question.id (Just Vote.Downvote)
                , removeDownvoteQuestion = subMsg <| RateQuestion bigbit.id question.id Nothing
                , upvoteAnswer = \answer -> subMsg <| RateAnswer bigbit.id answer.id (Just Vote.Upvote)
                , removeUpvoteAnswer = \answer -> subMsg <| RateAnswer bigbit.id answer.id Nothing
                , downvoteAnswer = \answer -> subMsg <| RateAnswer bigbit.id answer.id (Just Vote.Downvote)
                , removeDownvoteAnswer = \answer -> subMsg <| RateAnswer bigbit.id answer.id Nothing
                , pinQuestion = subMsg <| PinQuestion bigbit.id question.id True
                , unpinQuestion = subMsg <| PinQuestion bigbit.id question.id False
                , pinAnswer = \answer -> subMsg <| PinAnswer bigbit.id answer.id True
                , unpinAnswer = \answer -> subMsg <| PinAnswer bigbit.id answer.id False
                , deleteAnswer = .id >> DeleteAnswer bigbit.id question.id >> subMsg
                , commentOnQuestion = subMsg << SubmitCommentOnQuestion bigbit.id question.id
                , commentOnAnswer = subMsg <<< SubmitCommentOnAnswer bigbit.id question.id
                , deleteQuestionComment = subMsg << DeleteCommentOnQuestion bigbit.id
                , deleteAnswerComment = subMsg << DeleteCommentOnAnswer bigbit.id
                , editQuestionComment = subMsg <<< EditCommentOnQuestion bigbit.id
                , editAnswerComment = subMsg <<< EditCommentOnAnswer bigbit.id
                , handleUnauthAction = BaseMessage.SetUserNeedsAuthModal
                }
                { questionCommentEdits = QA.getQuestionCommentEdits bigbit.id qaState
                , newQuestionComment = QA.getNewQuestionComment bigbit.id question.id qaState
                , answerCommentEdits = QA.getAnswerCommentEdits bigbit.id qaState
                , newAnswerComments = QA.getNewAnswerComments bigbit.id qaState
                , deletingComments = QA.getDeletingComments bigbit.id qaState
                , deletingAnswers = QA.getDeletingAnswers bigbit.id qaState
                }
    in
    case shared.route of
        Route.ViewBigbitFramePage _ _ _ _ ->
            tutorialRoute

        Route.ViewBigbitQuestionsPage _ bigbitID ->
            case model.qa of
                Just qa ->
                    let
                        browseCodePointer =
                            model.qaState |> QA.getBrowseCodePointer bigbitID

                        ( isHighlighting, remainingQuestions ) =
                            case browseCodePointer of
                                Nothing ->
                                    ( False, qa.questions )

                                Just ({ file, range } as codePointer) ->
                                    if Range.isEmptyRange range then
                                        ( False
                                        , qa.questions
                                            |> List.filter (.codePointer >> .file >> FS.isSameFilePath file)
                                        )
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
                                { questionND =
                                    \question ->
                                        let
                                            route =
                                                Route.ViewBigbitQuestionPage
                                                    (Route.getFromStoryQueryParamOnViewBigbitRoute shared.route)
                                                    (Route.getTouringQuestionsQueryParamOnViewBigbitQARoute shared.route)
                                                    bigbitID
                                                    question.id
                                        in
                                        ( Route.Route route, BaseMessage.GoTo { wipeModalError = False } route )
                                }
                            , isHighlighting = isHighlighting
                            , allQuestionText =
                                case browseCodePointer of
                                    Just _ ->
                                        "Questions in File"

                                    Nothing ->
                                        "All Questions"
                            , noQuestionsDuringSearchText = "None found"
                            , noQuestionsNotDuringSearchText =
                                case browseCodePointer of
                                    Nothing ->
                                        "Be the first to ask a question"

                                    Just _ ->
                                        "None found"
                            , askQuestion =
                                case shared.user of
                                    Nothing ->
                                        BaseMessage.SetUserNeedsAuthModal <|
                                            "We want to answer your question, sign up for free and get access"
                                                ++ " to all of CodeTidbit in seconds!"

                                    Just _ ->
                                        subMsg <| GoToAskQuestionWithCodePointer bigbitID browseCodePointer
                            }
                            remainingQuestions
                        ]

                Nothing ->
                    Util.hiddenDiv

        Route.ViewBigbitAskQuestion maybeStoryID bigbitID ->
            AskQuestion.view
                { subMsg = subMsg << AskQuestionMsg bigbitID
                , textFieldKeyTracker = shared.textFieldKeyTracker
                , askQuestionRequestInProgress =
                    RT.isMakingRequest shared.apiRequestTracker (RT.AskQuestion TidbitPointer.Bigbit)
                , askQuestion = subMsg <<< AskQuestion bigbitID
                , isReadyCodePointer = .range >> Range.isEmptyRange >> not
                , allQuestionsND =
                    ( Route.Route <| Route.ViewBigbitQuestionsPage maybeStoryID bigbitID
                    , subMsg <|
                        GoToBrowseQuestionsWithCodePointer
                            bigbitID
                            (QA.getNewQuestion bigbitID model.qaState |||> .codePointer)
                    )
                }
                (QA.getNewQuestion bigbitID model.qaState ?> QA.defaultNewQuestion)

        Route.ViewBigbitEditQuestion _ bigbitID questionID ->
            case model.qa ||> .questions |||> QA.getQuestion questionID of
                Just question ->
                    let
                        questionEdit =
                            QA.getQuestionEdit bigbitID questionID model.qaState
                                ?> QA.questionEditFromQuestion question
                    in
                    EditQuestion.view
                        { subMsg = subMsg << EditQuestionMsg bigbitID question
                        , textFieldKeyTracker = shared.textFieldKeyTracker
                        , editQuestionRequestInProgress =
                            RT.isMakingRequest shared.apiRequestTracker (RT.UpdateQuestion TidbitPointer.Bigbit)
                        , isReadyCodePointer = .range >> Range.isEmptyRange >> not
                        , editQuestion = subMsg <<< EditQuestion bigbitID questionID
                        }
                        questionEdit

                Nothing ->
                    Util.hiddenDiv

        Route.ViewBigbitAnswerQuestion maybeStoryID bigbitID questionID ->
            let
                api =
                    Api.api shared.flags.apiBaseUrl

                answerQuestionQuery =
                    api.post.answerQuestion
                        { tidbitType = TidbitPointer.Bigbit, targetID = bigbitID }
                        questionID
            in
            case model.qa of
                Just qa ->
                    AnswerQuestion.view
                        { subMsg = subMsg << AnswerQuestionMsg qa bigbitID
                        , textFieldKeyTracker = shared.textFieldKeyTracker
                        , tidbitID = bigbitID
                        , questionID = questionID
                        , answerQuestionRequestInProgress =
                            RT.isMakingRequest
                                shared.apiRequestTracker
                                (RT.AnswerQuestion TidbitPointer.Bigbit)
                        , allAnswersND =
                            Route.ViewBigbitAnswersPage maybeStoryID Nothing bigbitID questionID
                                |> (\route -> ( Route.Route route, BaseMessage.GoTo { wipeModalError = False } route ))
                        , answerQuestion = ( answerQuestionQuery, RT.AnswerQuestion TidbitPointer.Bigbit )
                        , answerRoute =
                            Route.ViewBigbitAnswerPage
                                (Route.getFromStoryQueryParamOnViewBigbitRoute shared.route)
                                (Route.getTouringQuestionsQueryParamOnViewBigbitQARoute shared.route)
                                bigbitID
                        }
                        { qa = qa, qaState = model.qaState, apiRequestTracker = shared.apiRequestTracker }

                Nothing ->
                    Util.hiddenDiv

        Route.ViewBigbitEditAnswer _ bigbitID answerID ->
            case
                ( model.qa ||> .answers |||> QA.getAnswer answerID
                , model.qa |||> QA.getQuestionByAnswerID answerID
                )
            of
                ( Just answer, Just question ) ->
                    let
                        answerEdit =
                            model.qaState
                                |> QA.getAnswerEdit bigbitID answerID
                                ?> QA.answerEditFromAnswer answer
                    in
                    EditAnswer.view
                        { subMsg = subMsg << EditAnswerMsg bigbitID answer
                        , textFieldKeyTracker = shared.textFieldKeyTracker
                        , editAnswerRequestInProgress =
                            RT.isMakingRequest shared.apiRequestTracker (RT.UpdateAnswer TidbitPointer.Bigbit)
                        , editAnswer = subMsg << EditAnswer bigbitID answerID
                        , forQuestion = question
                        }
                        answerEdit

                _ ->
                    Util.hiddenDiv

        Route.ViewBigbitQuestionPage _ _ _ questionID ->
            case model.qa of
                Just qa ->
                    case QA.getQuestion questionID qa.questions of
                        Just question ->
                            viewQuestionView qa model.qaState ViewQuestion.QuestionTab question

                        Nothing ->
                            Util.hiddenDiv

                Nothing ->
                    Util.hiddenDiv

        Route.ViewBigbitQuestionCommentsPage _ _ _ questionID maybeCommentID ->
            case model.qa of
                Just qa ->
                    case QA.getQuestion questionID qa.questions of
                        Just question ->
                            viewQuestionView
                                qa
                                model.qaState
                                (ViewQuestion.QuestionCommentsTab maybeCommentID)
                                question

                        Nothing ->
                            Util.hiddenDiv

                Nothing ->
                    Util.hiddenDiv

        Route.ViewBigbitAnswersPage _ _ _ questionID ->
            case model.qa of
                Just qa ->
                    case QA.getQuestion questionID qa.questions of
                        Just question ->
                            viewQuestionView
                                qa
                                model.qaState
                                ViewQuestion.AnswersTab
                                question

                        Nothing ->
                            Util.hiddenDiv

                Nothing ->
                    Util.hiddenDiv

        Route.ViewBigbitAnswerPage _ _ _ answerID ->
            case model.qa of
                Just qa ->
                    case QA.getQuestionByAnswerID answerID qa of
                        Just question ->
                            viewQuestionView
                                qa
                                model.qaState
                                (ViewQuestion.AnswerTab answerID)
                                question

                        Nothing ->
                            Util.hiddenDiv

                Nothing ->
                    Util.hiddenDiv

        Route.ViewBigbitAnswerCommentsPage _ _ _ answerID maybeCommentID ->
            case model.qa of
                Just qa ->
                    case QA.getQuestionByAnswerID answerID qa of
                        Just question ->
                            viewQuestionView
                                qa
                                model.qaState
                                (ViewQuestion.AnswerCommentsTab answerID maybeCommentID)
                                question

                        Nothing ->
                            Util.hiddenDiv

                Nothing ->
                    Util.hiddenDiv

        _ ->
            Util.hiddenDiv
