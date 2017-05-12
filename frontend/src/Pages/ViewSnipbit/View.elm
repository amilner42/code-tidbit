module Pages.ViewSnipbit.View exposing (..)

import Array
import DefaultServices.Editable as Editable
import DefaultServices.Util as Util exposing (maybeMapWithDefault)
import Elements.Editor as Editor
import Elements.Markdown exposing (githubMarkdown)
import Elements.ProgressBar as ProgressBar exposing (TextFormat(Custom), State(..), progressBar)
import Html exposing (Html, div, text, button, i, textarea)
import Html.Attributes exposing (class, classList, disabled, hidden, id, placeholder, value)
import Html.Events exposing (onClick, onInput)
import Models.Completed as Completed
import Models.QA as QA
import Models.Range as Range
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
                        , onClick <| GoToAskQuestion
                        ]
                        [ text "Ask Question" ]

                ( Just snipbitID, False, Just _ ) ->
                    button
                        [ class "sub-bar-button view-relevant-questions"
                        , onClick <| GoToBrowseQuestions
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
commentBox snipbit { relevantHC, qaState, qa } { route } =
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

            Route.ViewSnipbitQuestionsPage maybeStoryID snipbitID ->
                -- TODO
                Util.hiddenDiv

            Route.ViewSnipbitQuestionPage maybeStoryID snipbitID questionID maybeAnswerID ->
                -- TODO
                Util.hiddenDiv

            Route.ViewSnipbitQuestionFrame maybeStoryID snipbitID frameNumber maybeAnswerID ->
                -- TODO
                Util.hiddenDiv

            Route.ViewSnipbitAskQuestion maybeStoryID snipbitID ->
                let
                    tidbitQAState =
                        QA.getNewQuestion snipbitID qaState

                    previewingMarkdown =
                        tidbitQAState |> Util.maybeMapWithDefault .previewMarkdown False

                    questionText =
                        tidbitQAState |> Util.maybeMapWithDefault .questionText ""

                    maybeReadyQuestion =
                        QA.getNewQuestion snipbitID qaState
                            |> Maybe.andThen
                                (\{ codePointer, questionText } ->
                                    case
                                        ( Maybe.andThen Range.nonEmptyRangeOrNothing codePointer
                                        , Util.justNonBlankString questionText
                                        )
                                    of
                                        ( Just range, Just questionText ) ->
                                            Just { codePointer = range, questionText = questionText }

                                        _ ->
                                            Nothing
                                )

                    isQuestionReady =
                        Util.isNotNothing maybeReadyQuestion
                in
                    div
                        [ class "ask-question" ]
                        [ div
                            [ class "preview-markdown"
                            , onClick <| AskQuestionTogglePreviewMarkdown snipbitID
                            ]
                            [ text <|
                                if previewingMarkdown then
                                    "Close Preview"
                                else
                                    "Markdown Preview"
                            ]
                        , if previewingMarkdown then
                            githubMarkdown [] questionText
                          else
                            textarea
                                [ placeholder "Highlight code and ask your question"
                                , onInput <| OnAskQuestionTextInput snipbitID
                                , value questionText
                                ]
                                []
                        , div
                            [ classList
                                [ ( "ask-question-submit", True )
                                , ( "not-ready", not isQuestionReady )
                                , ( "hidden", previewingMarkdown )
                                ]
                            , onClick <|
                                case maybeReadyQuestion of
                                    Just { codePointer, questionText } ->
                                        AskQuestion snipbitID codePointer questionText

                                    Nothing ->
                                        NoOp
                            ]
                            [ text "Ask Question" ]
                        ]

            Route.ViewSnipbitAnswerQuestion maybeStoryID snipbitID questionID ->
                case Maybe.andThen (QA.getQuestionByID questionID) (Maybe.map .questions qa) of
                    Just question ->
                        let
                            newAnswer =
                                QA.getNewAnswer snipbitID questionID qaState

                            previewMarkdown =
                                Util.maybeMapWithDefault .previewMarkdown False newAnswer

                            showQuestion =
                                Util.maybeMapWithDefault .showQuestion True newAnswer

                            answerText =
                                Util.maybeMapWithDefault .answerText "" newAnswer

                            maybeReadyAnswer =
                                Util.justNonBlankString answerText

                            isAnswerReady =
                                Util.isNotNothing maybeReadyAnswer
                        in
                            div
                                [ class "answer-question" ]
                                [ div
                                    [ classList
                                        [ ( "display-question", True )
                                        , ( "hidden", previewMarkdown )
                                        ]
                                    , onClick <| NewAnswerToggleShowQuestion snipbitID questionID
                                    ]
                                    [ text <|
                                        if showQuestion then
                                            "Hide Question"
                                        else
                                            "Show Question"
                                    ]
                                , githubMarkdown
                                    [ classList
                                        [ ( "question", True )
                                        , ( "hidden", previewMarkdown || not showQuestion )
                                        ]
                                    ]
                                    question.questionText
                                , div
                                    [ classList
                                        [ ( "preview-markdown", True )
                                        , ( "previewing-markdown", previewMarkdown )
                                        , ( "hiding-question", not showQuestion )
                                        ]
                                    , onClick <| NewAnswerTogglePreviewMarkdown snipbitID questionID
                                    ]
                                    [ text <|
                                        if previewMarkdown then
                                            "Close Preview"
                                        else
                                            "Markdown Preview"
                                    ]
                                , Util.markdownOr
                                    previewMarkdown
                                    answerText
                                    (textarea
                                        [ classList [ ( "hiding-question", not showQuestion ) ]
                                        , placeholder "Answer Question"
                                        , onInput <| OnNewAnswerTextInput snipbitID questionID
                                        , value answerText
                                        ]
                                        []
                                    )
                                , div
                                    [ classList
                                        [ ( "answer-question-submit", True )
                                        , ( "hidden", previewMarkdown )
                                        , ( "not-ready", not isAnswerReady )
                                        ]
                                    , onClick <|
                                        case maybeReadyAnswer of
                                            Just answerText ->
                                                AnswerQuestion snipbitID questionID answerText

                                            Nothing ->
                                                NoOp
                                    ]
                                    [ text "Submit Answer" ]
                                ]

                    -- Will never happen, if the question doesn't exist we will redirect.
                    Nothing ->
                        Util.hiddenDiv

            Route.ViewSnipbitEditQuestion maybeStoryID snipbitID questionID ->
                case Maybe.andThen (QA.getQuestionByID questionID) (Maybe.map .questions qa) of
                    Just question ->
                        let
                            maybeQuestionEdit =
                                QA.getQuestionEditByID snipbitID questionID qaState

                            questionText =
                                maybeQuestionEdit
                                    |> Maybe.map (.questionText >> Editable.getBuffer)
                                    |> Maybe.withDefault question.questionText

                            codePointer =
                                maybeQuestionEdit
                                    |> Maybe.map (.codePointer >> Editable.getBuffer)
                                    |> Maybe.withDefault question.codePointer

                            maybeReadyQuestion =
                                case ( Range.nonEmptyRangeOrNothing codePointer, Util.justNonBlankString questionText ) of
                                    ( Just range, Just questionText ) ->
                                        Just { codePointer = range, questionText = questionText }

                                    _ ->
                                        Nothing

                            isQuestionReady =
                                Util.isNotNothing maybeReadyQuestion

                            previewMarkdown =
                                maybeQuestionEdit
                                    |> Util.maybeMapWithDefault .previewMarkdown False
                        in
                            div
                                [ class "edit-question" ]
                                [ div
                                    [ class "preview-markdown"
                                    , onClick <| EditQuestionTogglePreviewMarkdown snipbitID questionID question
                                    ]
                                    [ text <|
                                        if previewMarkdown then
                                            "Close Preview"
                                        else
                                            "Markdown Preview"
                                    ]
                                , Util.markdownOr
                                    previewMarkdown
                                    questionText
                                    (textarea
                                        [ placeholder "Edit Question Text"
                                        , value questionText
                                        , onInput <| OnEditQuestionTextInput snipbitID questionID question
                                        ]
                                        []
                                    )
                                , div
                                    [ classList
                                        [ ( "edit-question-submit", True )
                                        , ( "not-ready", not isQuestionReady )
                                        , ( "hidden", previewMarkdown )
                                        ]
                                    , onClick <|
                                        case maybeReadyQuestion of
                                            Just { codePointer, questionText } ->
                                                EditQuestion snipbitID questionID questionText codePointer

                                            Nothing ->
                                                NoOp
                                    ]
                                    [ text "Update Question" ]
                                ]

                    -- This will never happen, if the question doesn't exist we will have redirected URLs.
                    _ ->
                        Util.hiddenDiv

            Route.ViewSnipbitEditAnswer maybeStoryID snipbitID answerID ->
                case
                    ( Maybe.andThen (QA.getAnswerByID answerID) (Maybe.map .answers qa)
                    , Maybe.andThen (QA.getQuestionByAnswerID snipbitID answerID) qa
                    )
                of
                    ( Just answer, Just question ) ->
                        let
                            maybeAnswerEdit =
                                QA.getAnswerEdit snipbitID answerID qaState

                            answerText =
                                maybeAnswerEdit
                                    |> Maybe.map (.answerText >> Editable.getBuffer)
                                    |> Maybe.withDefault answer.answerText

                            previewMarkdown =
                                maybeAnswerEdit
                                    |> Util.maybeMapWithDefault .previewMarkdown False

                            showQuestion =
                                maybeAnswerEdit
                                    |> Util.maybeMapWithDefault .showQuestion True

                            maybeReadyAnswer =
                                Util.justNonBlankString answerText

                            isAnswerReady =
                                Util.isNotNothing maybeReadyAnswer
                        in
                            div
                                [ class "edit-answer" ]
                                [ div
                                    [ classList
                                        [ ( "display-question", True )
                                        , ( "hidden", previewMarkdown )
                                        ]
                                    , onClick <| EditAnswerToggleShowQuestion snipbitID answerID answer
                                    ]
                                    [ text <|
                                        if showQuestion then
                                            "Hide Question"
                                        else
                                            "Show Question"
                                    ]
                                , githubMarkdown
                                    [ classList
                                        [ ( "question", True )
                                        , ( "hidden", previewMarkdown || not showQuestion )
                                        ]
                                    ]
                                    question.questionText
                                , div
                                    [ classList
                                        [ ( "preview-markdown", True )
                                        , ( "previewing-markdown", previewMarkdown )
                                        , ( "hiding-question", not showQuestion )
                                        ]
                                    , onClick <| EditAnswerTogglePreviewMarkdown snipbitID answerID answer
                                    ]
                                    [ text <|
                                        if previewMarkdown then
                                            "Close Preview"
                                        else
                                            "Markdown Preview"
                                    ]
                                , Util.markdownOr
                                    previewMarkdown
                                    answerText
                                    (textarea
                                        [ classList [ ( "hiding-question", not showQuestion ) ]
                                        , placeholder "Edit Answer Text"
                                        , value answerText
                                        , onInput <| OnEditAnswerTextInput snipbitID answerID answer
                                        ]
                                        []
                                    )
                                , div
                                    [ classList
                                        [ ( "edit-answer-submit", True )
                                        , ( "not-ready", not isAnswerReady )
                                        , ( "hidden", previewMarkdown )
                                        ]
                                    , onClick <|
                                        case maybeReadyAnswer of
                                            Just answerText ->
                                                EditAnswer snipbitID question.id answerID answerText

                                            Nothing ->
                                                NoOp
                                    ]
                                    [ text "Update Answer" ]
                                ]

                    _ ->
                        Util.hiddenDiv

            _ ->
                Util.hiddenDiv
