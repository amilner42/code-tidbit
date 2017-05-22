module Pages.ViewSnipbit.Update exposing (..)

import Array
import DefaultServices.CommonSubPageUtil exposing (CommonSubPageUtil(..), commonSubPageUtil)
import DefaultServices.Editable as Editable
import DefaultServices.InfixFunctions exposing (..)
import DefaultServices.Util as Util exposing (maybeMapWithDefault)
import Dict
import Elements.Complex.AnswerQuestion as AnswerQuestion
import Elements.Complex.AskQuestion as AskQuestion
import Elements.Complex.EditAnswer as EditAnswer
import Elements.Complex.EditQuestion as EditQuestion
import Elements.Complex.ViewQuestion as ViewQuestion
import Elements.Simple.Editor as Editor
import Models.Completed as Completed
import Models.ContentPointer as ContentPointer
import Models.Opinion as Opinion
import Models.QA as QA
import Models.Range as Range
import Models.Route as Route
import Models.Snipbit as Snipbit
import Models.TidbitPointer as TidbitPointer
import Models.TutorialBookmark as TB
import Models.User as User
import Models.ViewerRelevantHC as ViewerRelevantHC
import Models.Vote as Vote
import Pages.Model exposing (Shared)
import Pages.ViewSnipbit.Messages exposing (Msg(..))
import Pages.ViewSnipbit.Model exposing (..)
import Ports


{-| `ViewSnipbit` update.
-}
update : CommonSubPageUtil Model Shared Msg -> Msg -> Model -> Shared -> ( Model, Shared, Cmd Msg )
update (Common common) msg model shared =
    case msg of
        NoOp ->
            common.doNothing

        GoTo route ->
            common.justProduceCmd <| Route.navigateTo route

        OnRouteHit route ->
            let
                {- Clears state that isn't meant to persist on route changes. -}
                clearStateOnRouteHit (Common common) ( model, shared ) =
                    common.justSetModel
                        { model
                            | relevantHC = Nothing
                            , relevantQuestions = Nothing
                            , tutorialCodePointer = Nothing
                        }

                {- Get's data for viewing snipbit as required:
                    - May need to fetch tidbit itself                             [Cache level: localStorage]
                    - May need to fetch story                                     [Cache level: browserModel]
                    - May need to fetch if the tidbit is completed by the user.   [Cache level: browserModel]
                    - May need to fetch the users opinion on the tidbit.          [Cache level: browserModel]
                    - May need to fetch QA                                        [Cache level: browserModel]

                   Depending on `requireLoadingQAPreRender`, it will either wait for both the snipbit and the QA to load
                   and then render the editor or it will render the editor just after the snipbit is loaded.
                -}
                fetchOrRenderViewSnipbitData mongoID requireLoadingQAPreRender (Common common) ( model, shared ) =
                    let
                        currentTidbitPointer =
                            TidbitPointer.TidbitPointer TidbitPointer.Snipbit mongoID

                        -- Handle getting snipbit if needed.
                        handleGetSnipbit (Common common) ( model, shared ) =
                            let
                                getSnipbit mongoID =
                                    ( setViewingSnipbit Nothing model
                                    , shared
                                    , common.api.get.snipbit
                                        mongoID
                                        OnGetSnipbitFailure
                                        (OnGetSnipbitSuccess requireLoadingQAPreRender)
                                    )
                            in
                                case model.snipbit of
                                    Nothing ->
                                        getSnipbit mongoID

                                    Just snipbit ->
                                        if snipbit.id == mongoID then
                                            common.justProduceCmd <|
                                                if not requireLoadingQAPreRender then
                                                    createViewSnipbitCodeEditor snipbit shared
                                                else
                                                    case model.qa of
                                                        Nothing ->
                                                            Cmd.none

                                                        Just qa ->
                                                            createViewSnipbitQACodeEditor
                                                                ( snipbit, qa, model.qaState )
                                                                model.bookmark
                                                                shared
                                        else
                                            getSnipbit mongoID

                        -- Handle getting snipbit is-completed if needed.
                        handleGetSnipbitIsCompleted (Common common) ( model, shared ) =
                            let
                                getSnipbitIsCompleted userID =
                                    ( setViewingSnipbitIsCompleted Nothing model
                                    , shared
                                    , common.api.post.checkCompleted
                                        (Completed.Completed currentTidbitPointer userID)
                                        OnGetCompletedFailure
                                        (OnGetCompletedSuccess << Completed.IsCompleted currentTidbitPointer)
                                    )
                            in
                                case ( shared.user, model.isCompleted ) of
                                    ( Just user, Nothing ) ->
                                        getSnipbitIsCompleted user.id

                                    ( Just user, Just currentCompleted ) ->
                                        if currentCompleted.tidbitPointer == currentTidbitPointer then
                                            common.doNothing
                                        else
                                            getSnipbitIsCompleted user.id

                                    _ ->
                                        common.doNothing

                        handleGetSnipbitOpinion (Common common) ( model, shared ) =
                            let
                                contentPointer =
                                    { contentType = ContentPointer.Snipbit
                                    , contentID = mongoID
                                    }

                                getOpinion =
                                    ( { model | possibleOpinion = Nothing }
                                    , shared
                                    , common.api.get.opinion
                                        contentPointer
                                        OnGetOpinionFailure
                                        (OnGetOpinionSuccess << (Opinion.PossibleOpinion contentPointer))
                                    )
                            in
                                case ( shared.user, model.possibleOpinion ) of
                                    ( Just user, Just { contentPointer, rating } ) ->
                                        if contentPointer.contentID == mongoID then
                                            common.doNothing
                                        else
                                            getOpinion

                                    ( Just user, Nothing ) ->
                                        getOpinion

                                    _ ->
                                        common.doNothing

                        -- Handle getting story if viewing snipbit from story.
                        handleGetStoryForSnipbit (Common common) ( model, shared ) =
                            let
                                maybeViewingStoryID =
                                    Maybe.map .id shared.viewingStory

                                getStory storyID =
                                    common.api.get.expandedStoryWithCompleted
                                        storyID
                                        OnGetExpandedStoryFailure
                                        OnGetExpandedStorySuccess
                            in
                                case Route.getFromStoryQueryParamOnViewSnipbitRoute shared.route of
                                    Just storyID ->
                                        if (Just storyID) == maybeViewingStoryID then
                                            common.doNothing
                                        else
                                            ( model
                                            , { shared | viewingStory = Nothing }
                                            , getStory storyID
                                            )

                                    _ ->
                                        common.justSetShared { shared | viewingStory = Nothing }

                        handleGetQA (Common common) ( model, shared ) =
                            let
                                getQA =
                                    ( { model | qa = Nothing }
                                    , shared
                                    , common.api.get.snipbitQA
                                        mongoID
                                        OnGetQAFailure
                                        (OnGetQASuccess requireLoadingQAPreRender)
                                    )
                            in
                                case model.qa of
                                    Nothing ->
                                        getQA

                                    Just qa ->
                                        if qa.tidbitID == mongoID then
                                            common.justProduceCmd <|
                                                if not requireLoadingQAPreRender then
                                                    Cmd.none
                                                else
                                                    case model.snipbit of
                                                        Nothing ->
                                                            Cmd.none

                                                        Just snipbit ->
                                                            createViewSnipbitQACodeEditor
                                                                ( snipbit, qa, model.qaState )
                                                                model.bookmark
                                                                shared
                                        else
                                            getQA
                    in
                        common.handleAll
                            [ handleGetSnipbit
                            , handleGetSnipbitIsCompleted
                            , handleGetSnipbitOpinion
                            , handleGetStoryForSnipbit
                            , handleGetQA
                            ]
            in
                case route of
                    Route.ViewSnipbitIntroductionPage _ snipbitID ->
                        common.handleAll
                            [ clearStateOnRouteHit
                            , (\(Common common) ( model, shared ) ->
                                common.justSetModel { model | bookmark = TB.Introduction }
                              )
                            , fetchOrRenderViewSnipbitData snipbitID False
                            ]

                    Route.ViewSnipbitFramePage _ snipbitID frameNumber ->
                        common.handleAll
                            [ clearStateOnRouteHit
                            , (\(Common common) ( model, shared ) ->
                                common.justSetModel { model | bookmark = TB.FrameNumber frameNumber }
                              )
                            , fetchOrRenderViewSnipbitData snipbitID False
                            ]

                    Route.ViewSnipbitConclusionPage _ snipbitID ->
                        common.handleAll
                            [ clearStateOnRouteHit
                            , (\(Common common) ( model, shared ) ->
                                common.justSetModel { model | bookmark = TB.Conclusion }
                              )
                            , fetchOrRenderViewSnipbitData snipbitID False
                            , (\(Common common) ( model, shared ) ->
                                common.justProduceCmd <|
                                    case ( shared.user, model.isCompleted ) of
                                        ( Just user, Just isCompleted ) ->
                                            let
                                                completed =
                                                    Completed.completedFromIsCompleted
                                                        isCompleted
                                                        user.id
                                            in
                                                if isCompleted.complete == False then
                                                    common.api.post.addCompleted
                                                        completed
                                                        OnMarkAsCompleteFailure
                                                        (always <|
                                                            OnMarkAsCompleteSuccess <|
                                                                (Completed.IsCompleted completed.tidbitPointer True)
                                                        )
                                                else
                                                    Cmd.none

                                        _ ->
                                            Cmd.none
                              )
                            ]

                    Route.ViewSnipbitQuestionsPage _ snipbitID ->
                        common.handleAll
                            [ clearStateOnRouteHit
                            , fetchOrRenderViewSnipbitData snipbitID True
                            ]

                    Route.ViewSnipbitQuestionPage _ _ snipbitID _ ->
                        common.handleAll
                            [ clearStateOnRouteHit
                            , fetchOrRenderViewSnipbitData snipbitID True
                            ]

                    Route.ViewSnipbitAnswersPage _ _ snipbitID _ ->
                        common.handleAll
                            [ clearStateOnRouteHit
                            , fetchOrRenderViewSnipbitData snipbitID True
                            ]

                    Route.ViewSnipbitAnswerPage _ _ snipbitID _ ->
                        common.handleAll
                            [ clearStateOnRouteHit
                            , fetchOrRenderViewSnipbitData snipbitID True
                            ]

                    Route.ViewSnipbitQuestionCommentsPage _ _ snipbitID _ _ ->
                        common.handleAll
                            [ clearStateOnRouteHit
                            , fetchOrRenderViewSnipbitData snipbitID True
                            ]

                    Route.ViewSnipbitAnswerCommentsPage _ _ snipbitID _ _ ->
                        common.handleAll
                            [ clearStateOnRouteHit
                            , fetchOrRenderViewSnipbitData snipbitID True
                            ]

                    Route.ViewSnipbitAskQuestion _ snipbitID ->
                        common.handleAll
                            [ clearStateOnRouteHit
                            , fetchOrRenderViewSnipbitData snipbitID True
                            ]

                    Route.ViewSnipbitAnswerQuestion _ snipbitID _ ->
                        common.handleAll
                            [ clearStateOnRouteHit
                            , fetchOrRenderViewSnipbitData snipbitID True
                            ]

                    Route.ViewSnipbitEditQuestion _ snipbitID _ ->
                        common.handleAll
                            [ clearStateOnRouteHit
                            , fetchOrRenderViewSnipbitData snipbitID True
                            ]

                    Route.ViewSnipbitEditAnswer _ snipbitID _ ->
                        common.handleAll
                            [ clearStateOnRouteHit
                            , fetchOrRenderViewSnipbitData snipbitID True
                            ]

                    _ ->
                        common.doNothing

        OnGetCompletedSuccess isCompleted ->
            common.justUpdateModel <| setViewingSnipbitIsCompleted <| Just isCompleted

        OnGetCompletedFailure apiError ->
            common.justSetModalError apiError

        OnGetSnipbitSuccess requireLoadingQAPreRender snipbit ->
            ( Util.multipleUpdates
                [ setViewingSnipbit <| Just snipbit
                , setViewingSnipbitRelevantHC Nothing
                ]
                model
            , shared
            , if not requireLoadingQAPreRender then
                createViewSnipbitCodeEditor snipbit shared
              else
                case model.qa of
                    Nothing ->
                        Cmd.none

                    Just qa ->
                        createViewSnipbitQACodeEditor ( snipbit, qa, model.qaState ) model.bookmark shared
            )

        OnGetSnipbitFailure apiError ->
            common.justSetModalError apiError

        OnGetOpinionSuccess possibleOpinion ->
            common.justSetModel { model | possibleOpinion = Just possibleOpinion }

        OnGetOpinionFailure apiError ->
            common.justSetModalError apiError

        OnGetQAFailure apiError ->
            common.justSetModalError apiError

        OnGetQASuccess requireLoadingQAPreRender qa ->
            ( { model
                | qa =
                    Just
                        { qa
                            | questions = QA.sortRateableContent qa.questions
                            , answers = QA.sortRateableContent qa.answers
                        }
                , relevantQuestions = Nothing
              }
            , shared
            , if not requireLoadingQAPreRender then
                Cmd.none
              else
                case model.snipbit of
                    Nothing ->
                        Cmd.none

                    Just snipbit ->
                        createViewSnipbitQACodeEditor ( snipbit, qa, model.qaState ) model.bookmark shared
            )

        AddOpinion opinion ->
            common.justProduceCmd <|
                common.api.post.addOpinion opinion OnAddOpinionFailure (always <| OnAddOpinionSuccess opinion)

        OnAddOpinionSuccess opinion ->
            common.justSetModel { model | possibleOpinion = Just (Opinion.toPossibleOpinion opinion) }

        OnAddOpinionFailure apiError ->
            common.justSetModalError apiError

        RemoveOpinion opinion ->
            common.justProduceCmd <|
                common.api.post.removeOpinion opinion OnRemoveOpinionFailure (always <| OnRemoveOpinionSuccess opinion)

        {- Currently it doesn't matter what opinion we removed because you can only have 1, but it may change in the
           future where we have multiple opinions, then use the `opinion` to figure out which to remove.
        -}
        OnRemoveOpinionSuccess { contentPointer, rating } ->
            common.justSetModel
                { model
                    | possibleOpinion = Just { contentPointer = contentPointer, rating = Nothing }
                }

        OnRemoveOpinionFailure apiError ->
            common.justSetModalError apiError

        OnGetExpandedStorySuccess expandedStory ->
            common.justSetShared { shared | viewingStory = Just expandedStory }

        OnGetExpandedStoryFailure apiError ->
            common.justSetModalError apiError

        OnRangeSelected selectedRange ->
            let
                handleSetTutorialCodePointer (Common common) ( model, shared ) =
                    common.justSetModel { model | tutorialCodePointer = Just selectedRange }

                handleFindRelevantFrames (Common common) ( model, shared ) =
                    case model.snipbit of
                        Nothing ->
                            common.doNothing

                        Just aSnipbit ->
                            if Range.isEmptyRange selectedRange then
                                common.justUpdateModel <| setViewingSnipbitRelevantHC Nothing
                            else
                                aSnipbit.highlightedComments
                                    |> Array.indexedMap (,)
                                    |> Array.filter
                                        (Tuple.second
                                            >> .range
                                            >> (Range.overlappingRanges selectedRange)
                                        )
                                    |> (\relevantHC ->
                                            common.justUpdateModel <|
                                                setViewingSnipbitRelevantHC <|
                                                    Just
                                                        { currentHC = Nothing
                                                        , relevantHC = relevantHC
                                                        }
                                       )

                handleFindRelevantQuestions (Common common) ( model, shared ) =
                    case model.qa of
                        Nothing ->
                            common.doNothing

                        Just { questions } ->
                            if Range.isEmptyRange selectedRange then
                                common.justSetModel { model | relevantQuestions = Nothing }
                            else
                                questions
                                    |> List.filter (\{ codePointer } -> Range.overlappingRanges codePointer selectedRange)
                                    |> (\relevantQuestions ->
                                            common.justSetModel { model | relevantQuestions = Just relevantQuestions }
                                       )
            in
                case shared.route of
                    Route.ViewSnipbitIntroductionPage _ _ ->
                        common.handleAll
                            [ handleSetTutorialCodePointer
                            , handleFindRelevantFrames
                            , handleFindRelevantQuestions
                            ]

                    Route.ViewSnipbitFramePage _ _ _ ->
                        common.handleAll
                            [ handleSetTutorialCodePointer
                            , handleFindRelevantFrames
                            , handleFindRelevantQuestions
                            ]

                    Route.ViewSnipbitConclusionPage _ _ ->
                        common.handleAll
                            [ handleSetTutorialCodePointer
                            , handleFindRelevantFrames
                            , handleFindRelevantQuestions
                            ]

                    Route.ViewSnipbitQuestionsPage _ snipbitID ->
                        common.justSetModel
                            { model | qaState = QA.setBrowsingCodePointer snipbitID (Just selectedRange) model.qaState }

                    Route.ViewSnipbitAskQuestion _ snipbitID ->
                        common.justSetModel
                            { model
                                | qaState =
                                    QA.updateNewQuestion
                                        snipbitID
                                        (\newQuestion -> { newQuestion | codePointer = Just selectedRange })
                                        model.qaState
                            }

                    Route.ViewSnipbitEditQuestion _ snipbitID questionID ->
                        case Maybe.andThen (.questions >> QA.getQuestionByID questionID) model.qa of
                            Nothing ->
                                common.doNothing

                            Just question ->
                                common.justSetModel
                                    { model
                                        | qaState =
                                            QA.updateQuestionEdit
                                                snipbitID
                                                questionID
                                                (\maybeQuestionEdit ->
                                                    Just <|
                                                        case maybeQuestionEdit of
                                                            Nothing ->
                                                                { questionText =
                                                                    Editable.newEditing question.questionText
                                                                , codePointer =
                                                                    Editable.newEditing selectedRange
                                                                , previewMarkdown = False
                                                                }

                                                            Just questionEdit ->
                                                                { questionEdit
                                                                    | codePointer =
                                                                        Editable.setBuffer
                                                                            questionEdit.codePointer
                                                                            selectedRange
                                                                }
                                                )
                                                model.qaState
                                    }

                    _ ->
                        common.doNothing

        BrowseRelevantHC ->
            let
                newModel =
                    updateViewingSnipbitRelevantHC
                        (\currentRelevantHC -> { currentRelevantHC | currentHC = Just 0 })
                        model
            in
                ( newModel
                , shared
                , createViewSnipbitHCCodeEditor
                    newModel.snipbit
                    newModel.relevantHC
                    shared.user
                )

        CancelBrowseRelevantHC ->
            common.justProduceCmd <|
                Route.modifyTo shared.route

        NextRelevantHC ->
            let
                newModel =
                    updateViewingSnipbitRelevantHC ViewerRelevantHC.goToNextFrame model
            in
                ( newModel
                , shared
                , createViewSnipbitHCCodeEditor
                    newModel.snipbit
                    newModel.relevantHC
                    shared.user
                )

        PreviousRelevantHC ->
            let
                newModel =
                    updateViewingSnipbitRelevantHC ViewerRelevantHC.goToPreviousFrame model
            in
                ( newModel
                , shared
                , createViewSnipbitHCCodeEditor
                    newModel.snipbit
                    newModel.relevantHC
                    shared.user
                )

        JumpToFrame route ->
            ( setViewingSnipbitRelevantHC Nothing model
            , shared
            , Route.navigateTo route
            )

        OnMarkAsCompleteSuccess isCompleted ->
            common.justUpdateModel <| setViewingSnipbitIsCompleted <| Just isCompleted

        OnMarkAsCompleteFailure apiError ->
            common.justSetModalError apiError

        -- Handles going to `AskQuestion` from different routes individually.
        GoToAskQuestion ->
            let
                tutorialCodePointer =
                    Maybe.withDefault Range.zeroRange model.tutorialCodePointer

                browseCodePointer snipbitID =
                    Maybe.withDefault
                        Range.zeroRange
                        (QA.getBrowseCodePointer snipbitID model.qaState)

                navigateToAskQuestionWithRange maybeStoryID snipbitID codePointer (Common common) ( model, shared ) =
                    ( { model
                        | qaState =
                            QA.updateNewQuestion
                                snipbitID
                                (\newQuestion ->
                                    { newQuestion
                                        | codePointer = Just codePointer
                                        , questionText = ""
                                    }
                                )
                                model.qaState
                      }
                    , shared
                    , Route.navigateTo <| Route.ViewSnipbitAskQuestion maybeStoryID snipbitID
                    )

                clearBrowseCodePointer snipbitID (Common common) ( model, shared ) =
                    common.justSetModel
                        { model | qaState = QA.setBrowsingCodePointer snipbitID Nothing model.qaState }
            in
                case shared.route of
                    Route.ViewSnipbitIntroductionPage maybeStoryID snipbitID ->
                        common.handleAll [ navigateToAskQuestionWithRange maybeStoryID snipbitID tutorialCodePointer ]

                    Route.ViewSnipbitFramePage maybeStoryID snipbitID _ ->
                        common.handleAll [ navigateToAskQuestionWithRange maybeStoryID snipbitID tutorialCodePointer ]

                    Route.ViewSnipbitConclusionPage maybeStoryID snipbitID ->
                        common.handleAll [ navigateToAskQuestionWithRange maybeStoryID snipbitID tutorialCodePointer ]

                    Route.ViewSnipbitQuestionsPage maybeStoryID snipbitID ->
                        common.handleAll
                            [ navigateToAskQuestionWithRange maybeStoryID snipbitID (browseCodePointer snipbitID)
                            , clearBrowseCodePointer snipbitID
                            ]

                    _ ->
                        common.doNothing

        GoToBrowseQuestions ->
            let
                codePointer =
                    Maybe.withDefault Range.zeroRange model.tutorialCodePointer
            in
                case (Route.getViewingContentID shared.route) of
                    Just snipbitID ->
                        ( { model | qaState = QA.setBrowsingCodePointer snipbitID (Just codePointer) model.qaState }
                        , shared
                        , Route.navigateTo <|
                            Route.ViewSnipbitQuestionsPage
                                (Route.getFromStoryQueryParamOnViewSnipbitRoute shared.route)
                                snipbitID
                        )

                    Nothing ->
                        common.doNothing

        AskQuestion snipbitID codePointer questionText ->
            common.justProduceCmd <|
                common.api.post.askQuestionOnSnipbit
                    snipbitID
                    questionText
                    codePointer
                    OnAskQuestionFailure
                    (OnAskQuestionSuccess snipbitID)

        OnAskQuestionSuccess snipbitID question ->
            case model.qa of
                Just qa ->
                    ( { model
                        | qa = Just { qa | questions = QA.sortRateableContent <| question :: qa.questions }
                        , qaState =
                            QA.updateNewQuestion
                                snipbitID
                                (always { codePointer = Nothing, questionText = "", previewMarkdown = False })
                                model.qaState
                      }
                    , shared
                    , Route.navigateTo <|
                        Route.ViewSnipbitQuestionPage
                            (Route.getFromStoryQueryParamOnViewSnipbitRoute shared.route)
                            Nothing
                            snipbitID
                            question.id
                    )

                Nothing ->
                    common.doNothing

        OnAskQuestionFailure apiError ->
            common.justSetModalError apiError

        EditQuestion snipbitID questionID questionText range ->
            common.justProduceCmd <|
                common.api.post.editQuestionOnSnipbit
                    snipbitID
                    questionID
                    questionText
                    range
                    OnEditQuestionFailure
                    (OnEditQuestionSuccess snipbitID questionID questionText range)

        OnEditQuestionSuccess snipbitID questionID questionText range date ->
            ( { model
                | -- Get rid of question edit.
                  qaState = QA.updateQuestionEdit snipbitID questionID (always Nothing) model.qaState

                -- Update question in QA.
                , qa =
                    Maybe.map
                        (QA.updateQuestion
                            questionID
                            (\question ->
                                { question | questionText = questionText, codePointer = range, lastModified = date }
                            )
                        )
                        model.qa
              }
            , shared
            , Route.navigateTo <|
                Route.ViewSnipbitQuestionPage
                    (Route.getFromStoryQueryParamOnViewSnipbitRoute shared.route)
                    Nothing
                    snipbitID
                    questionID
            )

        OnEditQuestionFailure apiError ->
            common.justSetModalError apiError

        AnswerQuestion snipbitID questionID answerText ->
            common.justProduceCmd <|
                common.api.post.answerQuestion
                    { tidbitType = TidbitPointer.Snipbit, targetID = snipbitID }
                    questionID
                    answerText
                    OnAnswerFailure
                    (OnAnswerQuestionSuccess snipbitID questionID)

        OnAnswerQuestionSuccess snipbitID questionID answer ->
            ( { model
                | -- Add the answer to the published answer list (and re-sort).
                  qa = Maybe.map (\qa -> { qa | answers = QA.sortRateableContent <| answer :: qa.answers }) model.qa

                -- Clear the new answer from the QAState.
                , qaState = QA.updateNewAnswer snipbitID questionID (always Nothing) model.qaState
              }
            , shared
            , Route.navigateTo <|
                Route.ViewSnipbitAnswerPage
                    (Route.getFromStoryQueryParamOnViewSnipbitRoute shared.route)
                    Nothing
                    snipbitID
                    answer.id
            )

        OnAnswerFailure apiError ->
            common.justSetModalError apiError

        EditAnswer snipbitID questionID answerID answerText ->
            common.justProduceCmd <|
                common.api.post.editAnswer
                    { tidbitType = TidbitPointer.Snipbit, targetID = snipbitID }
                    answerID
                    answerText
                    OnEditAnswerFailure
                    (OnEditAnswerSuccess snipbitID questionID answerID answerText)

        OnEditAnswerSuccess snipbitID questionID answerID answerText date ->
            ( { model
                | -- Remove answer edit from QAState.
                  qaState =
                    QA.updateAnswerEdit snipbitID answerID (always Nothing) model.qaState

                -- Update answer in QA.
                , qa =
                    Maybe.map
                        (QA.updateAnswer
                            answerID
                            (\answer ->
                                { answer | answerText = answerText, lastModified = date }
                            )
                        )
                        model.qa
              }
            , shared
            , Route.navigateTo <|
                Route.ViewSnipbitAnswerPage
                    (Route.getFromStoryQueryParamOnViewSnipbitRoute shared.route)
                    Nothing
                    snipbitID
                    answerID
            )

        OnEditAnswerFailure apiError ->
            common.justSetModalError apiError

        OnClickUpvoteQuestion snipbitID questionID ->
            common.justProduceCmd <|
                common.api.post.rateQuestion
                    { tidbitType = TidbitPointer.Snipbit, targetID = snipbitID }
                    questionID
                    Vote.Upvote
                    OnUpvoteQuestionFailure
                    (always <| OnUpvoteQuestionSuccess questionID)

        OnClickRemoveQuestionUpvote snipbitID questionID ->
            common.justProduceCmd <|
                common.api.post.removeQuestionRating
                    { tidbitType = TidbitPointer.Snipbit, targetID = snipbitID }
                    questionID
                    OnRemoveQuestionUpvoteFailure
                    (always <| OnRemoveQuestionUpvoteSuccess questionID)

        OnClickDownvoteQuestion snipbitID questionID ->
            common.justProduceCmd <|
                common.api.post.rateQuestion
                    { tidbitType = TidbitPointer.Snipbit, targetID = snipbitID }
                    questionID
                    Vote.Downvote
                    OnDownvoteQuestionFailure
                    (always <| OnDownvoteQuestionSuccess questionID)

        OnClickRemoveQuestionDownvote snipbitID questionID ->
            common.justProduceCmd <|
                common.api.post.removeQuestionRating
                    { tidbitType = TidbitPointer.Snipbit, targetID = snipbitID }
                    questionID
                    OnRemoveQuestionDownvoteFailure
                    (always <| OnRemoveQuestionDownvoteSuccess questionID)

        OnUpvoteQuestionSuccess questionID ->
            common.justSetModel { model | qa = Maybe.map (QA.rateQuestion questionID <| Just Vote.Upvote) model.qa }

        OnUpvoteQuestionFailure apiError ->
            common.justSetModalError apiError

        OnRemoveQuestionUpvoteSuccess questionID ->
            common.justSetModel { model | qa = Maybe.map (QA.rateQuestion questionID <| Nothing) model.qa }

        OnRemoveQuestionUpvoteFailure apiError ->
            common.justSetModalError apiError

        OnDownvoteQuestionSuccess questionID ->
            common.justSetModel { model | qa = Maybe.map (QA.rateQuestion questionID <| Just Vote.Downvote) model.qa }

        OnDownvoteQuestionFailure apiError ->
            common.justSetModalError apiError

        OnRemoveQuestionDownvoteSuccess questionID ->
            common.justSetModel { model | qa = Maybe.map (QA.rateQuestion questionID <| Nothing) model.qa }

        OnRemoveQuestionDownvoteFailure apiError ->
            common.justSetModalError apiError

        OnClickUpvoteAnswer snipbitID answerID ->
            common.justProduceCmd <|
                common.api.post.rateAnswer
                    { tidbitType = TidbitPointer.Snipbit, targetID = snipbitID }
                    answerID
                    Vote.Upvote
                    OnUpvoteAnswerFailure
                    (always <| OnUpvoteAnswerSuccess answerID)

        OnClickRemoveAnswerUpvote snipbitID answerID ->
            common.justProduceCmd <|
                common.api.post.removeAnswerRating
                    { tidbitType = TidbitPointer.Snipbit, targetID = snipbitID }
                    answerID
                    OnRemoveAnswerUpvoteFailure
                    (always <| OnRemoveAnswerUpvoteSuccess answerID)

        OnClickDownvoteAnswer snipbitID answerID ->
            common.justProduceCmd <|
                common.api.post.rateAnswer
                    { tidbitType = TidbitPointer.Snipbit, targetID = snipbitID }
                    answerID
                    Vote.Downvote
                    OnDownvoteAnswerFailure
                    (always <| OnDownvoteAnswerSuccess answerID)

        OnClickRemoveAnswerDownvote snipbitID answerID ->
            common.justProduceCmd <|
                common.api.post.removeAnswerRating
                    { tidbitType = TidbitPointer.Snipbit, targetID = snipbitID }
                    answerID
                    OnRemoveAnswerDownvoteFailure
                    (always <| OnRemoveAnswerDownvoteSuccess answerID)

        OnUpvoteAnswerSuccess answerID ->
            common.justSetModel { model | qa = Maybe.map (QA.rateAnswer answerID <| Just Vote.Upvote) model.qa }

        OnUpvoteAnswerFailure apiError ->
            common.justSetModalError apiError

        OnRemoveAnswerUpvoteSuccess answerID ->
            common.justSetModel { model | qa = Maybe.map (QA.rateAnswer answerID Nothing) model.qa }

        OnRemoveAnswerUpvoteFailure apiError ->
            common.justSetModalError apiError

        OnDownvoteAnswerSuccess answerID ->
            common.justSetModel { model | qa = Maybe.map (QA.rateAnswer answerID <| Just Vote.Downvote) model.qa }

        OnDownvoteAnswerFailure apiError ->
            common.justSetModalError apiError

        OnRemoveAnswerDownvoteSuccess answerID ->
            common.justSetModel { model | qa = Maybe.map (QA.rateAnswer answerID Nothing) model.qa }

        OnRemoveAnswerDownvoteFailure apiError ->
            common.justSetModalError apiError

        AskQuestionMsg snipbitID askQuestionMsg ->
            let
                askQuestionModel =
                    QA.getNewQuestion snipbitID model.qaState
                        |> Maybe.withDefault QA.defaultNewQuestion

                ( newAskQuestionModel, newAskQuestionMsg ) =
                    AskQuestion.update askQuestionMsg askQuestionModel
            in
                ( { model | qaState = QA.updateNewQuestion snipbitID (always newAskQuestionModel) model.qaState }
                , shared
                , Cmd.map (AskQuestionMsg snipbitID) newAskQuestionMsg
                )

        EditQuestionMsg snipbitID question editQuestionMsg ->
            let
                editQuestionModel =
                    QA.getQuestionEditByID snipbitID question.id model.qaState
                        |> Maybe.withDefault (QA.questionEditFromQuestion question)

                ( newEditQuestionModel, newEditQuestionMsg ) =
                    EditQuestion.update editQuestionMsg editQuestionModel
            in
                ( { model
                    | qaState =
                        QA.updateQuestionEdit
                            snipbitID
                            question.id
                            (always <| Just newEditQuestionModel)
                            model.qaState
                  }
                , shared
                , Cmd.map (EditQuestionMsg snipbitID question) newEditQuestionMsg
                )

        AnswerQuestionMsg snipbitID question answerQuestionMsg ->
            let
                answerQuestionModel =
                    { newAnswer =
                        QA.getNewAnswer snipbitID question.id model.qaState
                            |> Maybe.withDefault QA.defaultNewAnswer
                    , forQuestion =
                        question
                    }

                ( newAnswerQuestionModel, newAnswerQuestionMsg ) =
                    AnswerQuestion.update answerQuestionMsg answerQuestionModel
            in
                ( { model
                    | qaState =
                        QA.updateNewAnswer
                            snipbitID
                            question.id
                            (always <| Just newAnswerQuestionModel.newAnswer)
                            model.qaState
                  }
                , shared
                , Cmd.map (AnswerQuestionMsg snipbitID question) newAnswerQuestionMsg
                )

        EditAnswerMsg snipbitID answerID question answer editAnswerMsg ->
            let
                editAnswerModel =
                    { answerEdit =
                        QA.getAnswerEdit snipbitID answerID model.qaState
                            |> Maybe.withDefault (QA.answerEditFromAnswer answer)
                    , forQuestion =
                        question
                    }

                ( newEditAnswerModel, newEditAnswerMsg ) =
                    EditAnswer.update editAnswerMsg editAnswerModel
            in
                ( { model
                    | qaState =
                        QA.updateAnswerEdit
                            snipbitID
                            answerID
                            (always <| Just newEditAnswerModel.answerEdit)
                            model.qaState
                  }
                , shared
                , Cmd.map (EditAnswerMsg snipbitID answerID question answer) newEditAnswerMsg
                )

        PinQuestion snipbitID questionID ->
            common.justProduceCmd <|
                common.api.post.pinQuestion
                    { targetID = snipbitID, tidbitType = TidbitPointer.Snipbit }
                    questionID
                    True
                    OnPinQuestionFailure
                    (always <| OnPinQuestionSuccess snipbitID questionID)

        OnPinQuestionSuccess snipbitID questionID ->
            common.justSetModel <| { model | qa = model.qa ||> QA.pinQuestion questionID True }

        OnPinQuestionFailure apiError ->
            common.justSetModalError apiError

        UnpinQuestion snipbitID questionID ->
            common.justProduceCmd <|
                common.api.post.pinQuestion
                    { targetID = snipbitID, tidbitType = TidbitPointer.Snipbit }
                    questionID
                    False
                    OnUnpinQuestionFailure
                    (always <| OnUnpinQuestionSuccess snipbitID questionID)

        OnUnpinQuestionSuccess snipbitID questionID ->
            common.justSetModel <| { model | qa = model.qa ||> QA.pinQuestion questionID False }

        OnUnpinQuestionFailure apiError ->
            common.justSetModalError apiError

        PinAnswer snipbitID answerID ->
            common.justProduceCmd <|
                common.api.post.pinAnswer
                    { targetID = snipbitID, tidbitType = TidbitPointer.Snipbit }
                    answerID
                    True
                    OnPinAnswerFailure
                    (always <| OnPinAnswerSuccess snipbitID answerID)

        OnPinAnswerSuccess snipbitID answerID ->
            common.justSetModel { model | qa = model.qa ||> QA.pinAnswer answerID True }

        OnPinAnswerFailure apiError ->
            common.justSetModalError apiError

        UnpinAnswer snipbitID answerID ->
            common.justProduceCmd <|
                common.api.post.pinAnswer
                    { targetID = snipbitID, tidbitType = TidbitPointer.Snipbit }
                    answerID
                    False
                    OnUnpinAnswerFailure
                    (always <| OnUnpinAnswerSuccess snipbitID answerID)

        OnUnpinAnswerSuccess snipbitID answerID ->
            common.justSetModel { model | qa = model.qa ||> QA.pinAnswer answerID False }

        OnUnpinAnswerFailure apiError ->
            common.justSetModalError apiError

        ViewQuestionMsg snipbitID questionID viewQuestionMsg ->
            let
                viewQuestionModel =
                    { questionCommentEdits = QA.getQuestionCommentEdits snipbitID model.qaState
                    , newQuestionComment = QA.getNewQuestionComment snipbitID questionID model.qaState
                    , answerCommentEdits = QA.getAnswerCommentEdits snipbitID model.qaState
                    , newAnswerComments = QA.getNewAnswerComments snipbitID model.qaState
                    }

                ( newViewQuestionModel, newViewQuestionMsg ) =
                    ViewQuestion.update viewQuestionMsg viewQuestionModel
            in
                ( { model
                    | qaState =
                        model.qaState
                            |> QA.setQuestionCommentEdits snipbitID newViewQuestionModel.questionCommentEdits
                            |> QA.setNewQuestionComment snipbitID questionID (Just newViewQuestionModel.newQuestionComment)
                            |> QA.setAnswerCommentEdits snipbitID newViewQuestionModel.answerCommentEdits
                            |> QA.updateNewAnswerComments snipbitID (always newViewQuestionModel.newAnswerComments)
                  }
                , shared
                , Cmd.map (ViewQuestionMsg snipbitID questionID) newViewQuestionMsg
                )

        SubmitCommentOnQuestion snipbitID questionID commentText ->
            common.justProduceCmd <|
                common.api.post.commentOnQuestion
                    { tidbitType = TidbitPointer.Snipbit, targetID = snipbitID }
                    questionID
                    commentText
                    OnSubmitCommentOnQuestionFailure
                    (OnSubmitCommentOnQuestionSuccess snipbitID questionID)

        OnSubmitCommentOnQuestionSuccess snipbitID questionID questionComment ->
            common.justSetModel
                { model
                    | qa = QA.addQuestionComment questionComment <|| model.qa
                    , qaState = QA.setNewQuestionComment snipbitID questionID Nothing model.qaState
                }

        OnSubmitCommentOnQuestionFailure apiError ->
            common.justSetModalError apiError

        SubmitCommentOnAnswer snipbitID questionID answerID commentText ->
            common.justProduceCmd <|
                common.api.post.commentOnAnswer
                    { tidbitType = TidbitPointer.Snipbit, targetID = snipbitID }
                    questionID
                    answerID
                    commentText
                    SubmitCommentOnAnswerFailure
                    (SubmitCommentOnAnswerSuccess snipbitID questionID answerID)

        SubmitCommentOnAnswerSuccess snipbitID questionID answerID answerComment ->
            common.justSetModel
                { model
                    | qa = QA.addAnswerComment answerComment <|| model.qa
                    , qaState = QA.updateNewAnswerComments snipbitID (Dict.remove answerID) model.qaState
                }

        SubmitCommentOnAnswerFailure apiError ->
            common.justSetModalError apiError


{-| Creates the editor for the snipbit.

Will handle redirects if bad path and highlighting code.
-}
createViewSnipbitCodeEditor : Snipbit.Snipbit -> Shared -> Cmd msg
createViewSnipbitCodeEditor snipbit { route, user } =
    let
        editorWithRange range =
            snipbitEditor snipbit user True True True range
    in
        Cmd.batch
            [ case route of
                Route.ViewSnipbitIntroductionPage _ _ ->
                    editorWithRange Nothing

                Route.ViewSnipbitConclusionPage _ _ ->
                    editorWithRange Nothing

                Route.ViewSnipbitFramePage fromStoryID mongoID frameNumber ->
                    if frameNumber > Array.length snipbit.highlightedComments then
                        Route.modifyTo <|
                            Route.ViewSnipbitConclusionPage fromStoryID mongoID
                    else if frameNumber < 1 then
                        Route.modifyTo <|
                            Route.ViewSnipbitIntroductionPage fromStoryID mongoID
                    else
                        (Array.get
                            (frameNumber - 1)
                            snipbit.highlightedComments
                        )
                            |> Maybe.map .range
                            |> editorWithRange

                _ ->
                    Cmd.none
            , Ports.smoothScrollToBottom
            ]


{-| Creates the code editor for the routes when both the snipbit and the QA are required.

Will handle redirects if required (for example the content doesn't exist or if the user tries editing content that isn't
theirs). Will redirect to the appropriate route based on the bookmark (same as resuming the tutorial).
-}
createViewSnipbitQACodeEditor :
    ( Snipbit.Snipbit, QA.SnipbitQA, QA.SnipbitQAState )
    -> TB.TutorialBookmark
    -> Shared
    -> Cmd msg
createViewSnipbitQACodeEditor ( snipbit, qa, qaState ) bookmark { route, user } =
    let
        editorWithRange { selectAllowed, useMarker } range =
            snipbitEditor snipbit user True selectAllowed useMarker range

        redirectToTutorial maybeStoryID snipbitID =
            Route.modifyTo <| routeForBookmark maybeStoryID snipbitID bookmark
    in
        Cmd.batch
            [ case route of
                -- Highlight browsingCodePointer or Nothing.
                Route.ViewSnipbitQuestionsPage _ snipbitID ->
                    Dict.get snipbitID qaState
                        |> Maybe.andThen .browsingCodePointer
                        |> editorWithRange { selectAllowed = True, useMarker = False }

                -- Highlight question codePointer.
                Route.ViewSnipbitQuestionPage maybeStoryID _ snipbitID questionID ->
                    case QA.getQuestionByID questionID qa.questions of
                        Nothing ->
                            redirectToTutorial maybeStoryID snipbitID

                        Just { codePointer } ->
                            editorWithRange { selectAllowed = False, useMarker = True } <| Just codePointer

                Route.ViewSnipbitAnswersPage maybeStoryID _ snipbitID questionID ->
                    case QA.getQuestionByID questionID qa.questions of
                        Nothing ->
                            redirectToTutorial maybeStoryID snipbitID

                        Just { codePointer } ->
                            editorWithRange { selectAllowed = False, useMarker = True } <| Just codePointer

                Route.ViewSnipbitAnswerPage maybeStoryID _ snipbitID answerID ->
                    case QA.getQuestionByAnswerID snipbitID answerID qa of
                        Nothing ->
                            redirectToTutorial maybeStoryID snipbitID

                        Just { codePointer } ->
                            editorWithRange { selectAllowed = False, useMarker = True } <| Just codePointer

                Route.ViewSnipbitQuestionCommentsPage maybeStoryID _ snipbitID questionID maybeCommentID ->
                    case QA.getQuestionByID questionID qa.questions of
                        Nothing ->
                            redirectToTutorial maybeStoryID snipbitID

                        Just { codePointer } ->
                            editorWithRange { selectAllowed = False, useMarker = True } <| Just codePointer

                Route.ViewSnipbitAnswerCommentsPage maybeStoryID _ snipbitID answerID maybeCommentID ->
                    case QA.getQuestionByAnswerID snipbitID answerID qa of
                        Nothing ->
                            redirectToTutorial maybeStoryID snipbitID

                        Just { codePointer } ->
                            editorWithRange { selectAllowed = False, useMarker = True } <| Just codePointer

                -- Higlight newQuestion codePointer or Nothing.
                Route.ViewSnipbitAskQuestion maybeStoryID snipbitID ->
                    Dict.get snipbitID qaState
                        |> Maybe.map .newQuestion
                        |> Maybe.andThen .codePointer
                        |> editorWithRange { selectAllowed = True, useMarker = False }

                -- Highlight question codePointer.
                Route.ViewSnipbitAnswerQuestion maybeStoryID snipbitID questionID ->
                    case QA.getQuestionByID questionID qa.questions of
                        Nothing ->
                            redirectToTutorial maybeStoryID snipbitID

                        Just { codePointer } ->
                            editorWithRange { selectAllowed = False, useMarker = True } <| Just codePointer

                -- Highlight questionEdit codePointer or original question codePointer.
                Route.ViewSnipbitEditQuestion maybeStoryID snipbitID questionID ->
                    case QA.getQuestionByID questionID qa.questions of
                        Nothing ->
                            redirectToTutorial maybeStoryID snipbitID

                        Just { authorID, codePointer } ->
                            if Util.maybeMapWithDefault (.id >> (==) authorID) False user then
                                QA.getQuestionEditByID snipbitID questionID qaState
                                    |> (\maybeEdit ->
                                            case maybeEdit of
                                                Nothing ->
                                                    editorWithRange
                                                        { selectAllowed = True, useMarker = False }
                                                        (Just codePointer)

                                                Just { codePointer } ->
                                                    editorWithRange
                                                        { selectAllowed = True, useMarker = False }
                                                        (Just <| Editable.getBuffer codePointer)
                                       )
                            else
                                redirectToTutorial maybeStoryID snipbitID

                -- Highlight question codePointer.
                Route.ViewSnipbitEditAnswer maybeStoryID snipbitID answerID ->
                    case QA.getQuestionByAnswerID snipbitID answerID qa of
                        Nothing ->
                            redirectToTutorial maybeStoryID snipbitID

                        Just { codePointer } ->
                            editorWithRange { selectAllowed = False, useMarker = True } <| Just codePointer

                _ ->
                    Cmd.none
            , Ports.smoothScrollToBottom
            ]


{-| Creates the code editor for the snipbit when browsing the relevant HC.

This will only create the editor if the state of the model (the `Maybe`s) makes it appropriate to render the editor.
-}
createViewSnipbitHCCodeEditor : Maybe Snipbit.Snipbit -> Maybe ViewingSnipbitRelevantHC -> Maybe User.User -> Cmd msg
createViewSnipbitHCCodeEditor maybeSnipbit maybeRHC user =
    case ( maybeSnipbit, maybeRHC ) of
        ( Just snipbit, Just { currentHC, relevantHC } ) ->
            case currentHC of
                Nothing ->
                    Cmd.none

                Just index ->
                    Array.get index relevantHC
                        |> maybeMapWithDefault
                            (snipbitEditor snipbit user True False True << Just << .range << Tuple.second)
                            Cmd.none

        _ ->
            Cmd.none


{-| Wrapper around the port for creating an editor with the view-snipbit-settings pre-filled.
-}
snipbitEditor : Snipbit.Snipbit -> Maybe User.User -> Bool -> Bool -> Bool -> Maybe Range.Range -> Cmd msg
snipbitEditor snipbit user readOnly selectAllowed useMarker range =
    Ports.createCodeEditor
        { id = "view-snipbit-code-editor"
        , fileID = ""
        , lang = Editor.aceLanguageLocation snipbit.language
        , theme = User.getTheme user
        , value = snipbit.code
        , range = range
        , useMarker = useMarker
        , readOnly = readOnly
        , selectAllowed = selectAllowed
        }
