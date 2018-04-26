module Pages.ViewSnipbit.Update exposing (..)

import Array
import DefaultServices.CommonSubPageUtil exposing (CommonSubPageUtil(..), commonSubPageUtil)
import DefaultServices.Editable as Editable
import DefaultServices.InfixFunctions exposing (..)
import DefaultServices.TextFields as TextFields
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
import Models.RequestTracker as RT
import Models.Route as Route
import Models.Snipbit as Snipbit
import Models.TidbitPointer as TidbitPointer
import Models.User as User
import Models.ViewerRelevantHC as ViewerRelevantHC
import Pages.Model exposing (Shared)
import Pages.ViewSnipbit.Messages exposing (Msg(..))
import Pages.ViewSnipbit.Model exposing (..)
import Ports
import Set


{-| `ViewSnipbit` update.
-}
update : CommonSubPageUtil Model Shared Msg -> Msg -> Model -> Shared -> ( Model, Shared, Cmd Msg )
update (Common common) msg model shared =
    case msg of
        NoOp ->
            common.doNothing

        GoTo route ->
            common.justProduceCmd <| Route.navigateTo route

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
                Route.ViewSnipbitFramePage maybeStoryID snipbitID _ ->
                    common.handleAll [ navigateToAskQuestionWithRange maybeStoryID snipbitID tutorialCodePointer ]

                Route.ViewSnipbitQuestionsPage maybeStoryID snipbitID ->
                    common.handleAll
                        [ navigateToAskQuestionWithRange maybeStoryID snipbitID (browseCodePointer snipbitID)
                        , clearBrowseCodePointer snipbitID
                        ]

                _ ->
                    common.doNothing

        GoToBrowseQuestionsWithCodePointer maybeCodePointer ->
            case Route.getViewingContentID shared.route of
                Just snipbitID ->
                    ( { model | qaState = QA.setBrowsingCodePointer snipbitID maybeCodePointer model.qaState }
                    , shared
                    , Route.navigateTo <|
                        Route.ViewSnipbitQuestionsPage
                            (Route.getFromStoryQueryParamOnViewSnipbitRoute shared.route)
                            snipbitID
                    )

                Nothing ->
                    common.doNothing

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

                clearDeletingComments snipbitID (Common common) ( model, shared ) =
                    common.justSetModel
                        { model | qaState = model.qaState |> QA.updateDeletingComments snipbitID (always Set.empty) }

                clearDeletingAnswers snipbitID (Common common) ( model, shared ) =
                    common.justSetModel
                        { model | qaState = model.qaState |> QA.updateDeletingAnswers snipbitID (always Set.empty) }

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
                                        (OnGetOpinionSuccess << Opinion.PossibleOpinion contentPointer)
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
                                    if Just storyID == maybeViewingStoryID then
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
                Route.ViewSnipbitFramePage _ snipbitID frameNumber ->
                    common.handleAll
                        [ clearStateOnRouteHit
                        , \(Common common) ( model, shared ) ->
                            common.justSetModel { model | bookmark = frameNumber }
                        , fetchOrRenderViewSnipbitData snipbitID False
                        , \(Common common) ( model, shared ) ->
                            common.justProduceCmd <|
                                case ( shared.user, model.isCompleted ) of
                                    ( Just user, Just isCompleted ) ->
                                        let
                                            completed =
                                                Completed.completedFromIsCompleted
                                                    isCompleted
                                                    user.id

                                            -- We consider a snipbit complete if you are on the last frame.
                                            onLastFrame =
                                                model.snipbit
                                                    ||> .highlightedComments
                                                    ||> Array.length
                                                    ||> (==) frameNumber
                                                    ?> False
                                        in
                                        if isCompleted.complete == False && onLastFrame then
                                            common.api.post.addCompleted
                                                completed
                                                OnMarkAsCompleteFailure
                                                (always <|
                                                    OnMarkAsCompleteSuccess <|
                                                        Completed.IsCompleted completed.tidbitPointer True
                                                )
                                        else
                                            Cmd.none

                                    _ ->
                                        Cmd.none
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
                        , clearDeletingAnswers snipbitID
                        ]

                Route.ViewSnipbitQuestionCommentsPage _ _ snipbitID _ _ ->
                    common.handleAll
                        [ clearStateOnRouteHit
                        , fetchOrRenderViewSnipbitData snipbitID True
                        , clearDeletingComments snipbitID
                        ]

                Route.ViewSnipbitAnswerCommentsPage _ _ snipbitID _ _ ->
                    common.handleAll
                        [ clearStateOnRouteHit
                        , fetchOrRenderViewSnipbitData snipbitID True
                        , clearDeletingComments snipbitID
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
            let
                addOpinionAction =
                    common.justProduceCmd <|
                        common.api.post.addOpinion opinion OnAddOpinionFailure (always <| OnAddOpinionSuccess opinion)
            in
            common.makeSingletonRequest (RT.AddOrRemoveOpinion ContentPointer.Snipbit) addOpinionAction

        OnAddOpinionSuccess opinion ->
            common.justSetModel { model | possibleOpinion = Just (Opinion.toPossibleOpinion opinion) }
                |> common.andFinishRequest (RT.AddOrRemoveOpinion ContentPointer.Snipbit)

        OnAddOpinionFailure apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest (RT.AddOrRemoveOpinion ContentPointer.Snipbit)

        RemoveOpinion opinion ->
            let
                removeOpinionAction =
                    common.justProduceCmd <|
                        common.api.post.removeOpinion
                            opinion
                            OnRemoveOpinionFailure
                            (always <| OnRemoveOpinionSuccess opinion)
            in
            common.makeSingletonRequest (RT.AddOrRemoveOpinion ContentPointer.Snipbit) removeOpinionAction

        {- Currently it doesn't matter what opinion we removed because you can only have 1, but it may change in the
           future where we have multiple opinions, then use the `opinion` to figure out which to remove.
        -}
        OnRemoveOpinionSuccess { contentPointer, rating } ->
            common.justSetModel { model | possibleOpinion = Just { contentPointer = contentPointer, rating = Nothing } }
                |> common.andFinishRequest (RT.AddOrRemoveOpinion ContentPointer.Snipbit)

        OnRemoveOpinionFailure apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest (RT.AddOrRemoveOpinion ContentPointer.Snipbit)

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
                                            >> Range.overlappingRanges selectedRange
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
                Route.ViewSnipbitFramePage _ _ _ ->
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
                    case model.qa |||> .questions >> QA.getQuestion questionID of
                        Just question ->
                            common.justSetModel
                                { model
                                    | qaState =
                                        QA.updateQuestionEdit
                                            snipbitID
                                            questionID
                                            (\maybeQuestionEdit ->
                                                maybeQuestionEdit
                                                    ?> QA.questionEditFromQuestion question
                                                    |> (\questionEdit ->
                                                            { questionEdit
                                                                | codePointer =
                                                                    Editable.setBuffer
                                                                        questionEdit.codePointer
                                                                        selectedRange
                                                            }
                                                       )
                                                    |> Just
                                            )
                                            model.qaState
                                }

                        Nothing ->
                            common.doNothing

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

        OnMarkAsCompleteSuccess isCompleted ->
            common.justUpdateModel <| setViewingSnipbitIsCompleted <| Just isCompleted

        OnMarkAsCompleteFailure apiError ->
            common.justSetModalError apiError

        AskQuestion snipbitID codePointer questionText ->
            let
                askQuestionAction =
                    common.justProduceCmd <|
                        common.api.post.askQuestionOnSnipbit
                            snipbitID
                            questionText
                            codePointer
                            OnAskQuestionFailure
                            (OnAskQuestionSuccess snipbitID)
            in
            common.makeSingletonRequest (RT.AskQuestion TidbitPointer.Snipbit) askQuestionAction

        OnAskQuestionSuccess snipbitID question ->
            (case model.qa of
                Just qa ->
                    ( { model
                        | qa = Just { qa | questions = QA.sortRateableContent <| question :: qa.questions }
                        , qaState = QA.updateNewQuestion snipbitID (always QA.defaultNewQuestion) model.qaState
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
            )
                |> common.andFinishRequest (RT.AskQuestion TidbitPointer.Snipbit)

        OnAskQuestionFailure apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest (RT.AskQuestion TidbitPointer.Snipbit)

        EditQuestion snipbitID questionID questionText range ->
            let
                editQuestionAction =
                    common.justProduceCmd <|
                        common.api.post.editQuestionOnSnipbit
                            snipbitID
                            questionID
                            questionText
                            range
                            OnEditQuestionFailure
                            (OnEditQuestionSuccess snipbitID questionID questionText range)
            in
            common.makeSingletonRequest (RT.UpdateQuestion TidbitPointer.Snipbit) editQuestionAction

        OnEditQuestionSuccess snipbitID questionID questionText range lastModified ->
            ( { model
                | -- Get rid of question edit.
                  qaState = QA.updateQuestionEdit snipbitID questionID (always Nothing) model.qaState

                -- Update question in QA.
                , qa =
                    model.qa
                        ||> QA.updateQuestion
                                questionID
                                (\question ->
                                    { question
                                        | questionText = questionText
                                        , codePointer = range
                                        , lastModified = lastModified
                                    }
                                )
              }
            , shared
            , Route.navigateTo <|
                Route.ViewSnipbitQuestionPage
                    (Route.getFromStoryQueryParamOnViewSnipbitRoute shared.route)
                    Nothing
                    snipbitID
                    questionID
            )
                |> common.andFinishRequest (RT.UpdateQuestion TidbitPointer.Snipbit)

        OnEditQuestionFailure apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest (RT.UpdateQuestion TidbitPointer.Snipbit)

        AnswerQuestion snipbitID questionID answerText ->
            let
                answerQuestionAction =
                    common.justProduceCmd <|
                        common.api.post.answerQuestion
                            { tidbitType = TidbitPointer.Snipbit, targetID = snipbitID }
                            questionID
                            answerText
                            OnAnswerFailure
                            (OnAnswerQuestionSuccess snipbitID questionID)
            in
            common.makeSingletonRequest (RT.AnswerQuestion TidbitPointer.Snipbit) answerQuestionAction

        OnAnswerQuestionSuccess snipbitID questionID answer ->
            ( { model
                | -- Add the answer to the published answer list (and re-sort).
                  qa = model.qa ||> (\qa -> { qa | answers = QA.sortRateableContent <| answer :: qa.answers })

                -- Clear the new answer from the QAState.
                , qaState = model.qaState |> QA.updateNewAnswer snipbitID questionID (always Nothing)
              }
            , shared
            , Route.navigateTo <|
                Route.ViewSnipbitAnswerPage
                    (Route.getFromStoryQueryParamOnViewSnipbitRoute shared.route)
                    Nothing
                    snipbitID
                    answer.id
            )
                |> common.andFinishRequest (RT.AnswerQuestion TidbitPointer.Snipbit)

        OnAnswerFailure apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest (RT.AnswerQuestion TidbitPointer.Snipbit)

        EditAnswer snipbitID questionID answerID answerText ->
            let
                updateAnswerAction =
                    common.justProduceCmd <|
                        common.api.post.editAnswer
                            { tidbitType = TidbitPointer.Snipbit, targetID = snipbitID }
                            answerID
                            answerText
                            OnEditAnswerFailure
                            (OnEditAnswerSuccess snipbitID questionID answerID answerText)
            in
            common.makeSingletonRequest (RT.UpdateAnswer TidbitPointer.Snipbit) updateAnswerAction

        OnEditAnswerSuccess snipbitID questionID answerID answerText lastModified ->
            ( { model
                | -- Remove answer edit from QAState.
                  qaState = model.qaState |> QA.updateAnswerEdit snipbitID answerID (always Nothing)

                -- Update answer in QA.
                , qa =
                    model.qa
                        ||> QA.updateAnswer
                                answerID
                                (\answer ->
                                    Just { answer | answerText = answerText, lastModified = lastModified }
                                )
              }
            , shared
            , Route.navigateTo <|
                Route.ViewSnipbitAnswerPage
                    (Route.getFromStoryQueryParamOnViewSnipbitRoute shared.route)
                    Nothing
                    snipbitID
                    answerID
            )
                |> common.andFinishRequest (RT.UpdateAnswer TidbitPointer.Snipbit)

        OnEditAnswerFailure apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest (RT.UpdateAnswer TidbitPointer.Snipbit)

        DeleteAnswer snipbitID questionID answerID ->
            let
                deleteAnswerAction =
                    common.justProduceCmd <|
                        common.api.post.deleteAnswer
                            { tidbitType = TidbitPointer.Snipbit, targetID = snipbitID }
                            answerID
                            OnDeleteAnswerFailure
                            (always <| OnDeleteAnswerSuccess snipbitID questionID answerID)
            in
            common.makeSingletonRequest (RT.DeleteAnswer TidbitPointer.Snipbit) deleteAnswerAction

        OnDeleteAnswerSuccess snipbitID questionID answerID ->
            (case model.qa of
                Nothing ->
                    common.doNothing

                Just qa ->
                    let
                        -- Delete answer and answer comments.
                        updatedQA =
                            qa
                                |> QA.updateAnswer answerID (always Nothing)
                                |> QA.deleteAnswerCommentsForAnswer answerID

                        -- Delete possible answer edit and answer-comment edits.
                        updatedQAState =
                            model.qaState
                                |> QA.updateAnswerEdit snipbitID answerID (always Nothing)
                                |> QA.deleteOldAnswerCommentEdits snipbitID updatedQA.answerComments
                    in
                    ( { model
                        | qa = Just updatedQA
                        , qaState = updatedQAState
                      }
                    , shared
                    , Route.navigateTo <|
                        Route.ViewSnipbitAnswersPage
                            (Route.getFromStoryQueryParamOnViewSnipbitRoute shared.route)
                            (Route.getTouringQuestionsQueryParamOnViewSnipbitQARoute shared.route)
                            snipbitID
                            questionID
                    )
            )
                |> common.andFinishRequest (RT.DeleteAnswer TidbitPointer.Snipbit)

        OnDeleteAnswerFailure apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest (RT.DeleteAnswer TidbitPointer.Snipbit)

        RateQuestion snipbitID questionID maybeVote ->
            let
                rateQuestionAction =
                    case maybeVote of
                        Nothing ->
                            common.justProduceCmd <|
                                common.api.post.removeQuestionRating
                                    { tidbitType = TidbitPointer.Snipbit, targetID = snipbitID }
                                    questionID
                                    OnRateQuestionFailure
                                    (always <| OnRateQuestionSuccess questionID maybeVote)

                        Just vote ->
                            common.justProduceCmd <|
                                common.api.post.rateQuestion
                                    { tidbitType = TidbitPointer.Snipbit, targetID = snipbitID }
                                    questionID
                                    vote
                                    OnRateQuestionFailure
                                    (always <| OnRateQuestionSuccess questionID maybeVote)
            in
            common.makeSingletonRequest (RT.RateQuestion TidbitPointer.Snipbit) rateQuestionAction

        OnRateQuestionSuccess questionID maybeVote ->
            common.justSetModel { model | qa = model.qa ||> QA.rateQuestion questionID maybeVote }
                |> common.andFinishRequest (RT.RateQuestion TidbitPointer.Snipbit)

        OnRateQuestionFailure apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest (RT.RateQuestion TidbitPointer.Snipbit)

        RateAnswer snipbitID answerID maybeVote ->
            let
                rateAnswerAction =
                    case maybeVote of
                        Nothing ->
                            common.justProduceCmd <|
                                common.api.post.removeAnswerRating
                                    { tidbitType = TidbitPointer.Snipbit, targetID = snipbitID }
                                    answerID
                                    OnRateAnswerFailure
                                    (always <| OnRateAnswerSuccess answerID maybeVote)

                        Just vote ->
                            common.justProduceCmd <|
                                common.api.post.rateAnswer
                                    { tidbitType = TidbitPointer.Snipbit, targetID = snipbitID }
                                    answerID
                                    vote
                                    OnRateAnswerFailure
                                    (always <| OnRateAnswerSuccess answerID maybeVote)
            in
            if RT.isNotMakingRequest shared.apiRequestTracker (RT.DeleteAnswer TidbitPointer.Snipbit) then
                common.makeSingletonRequest (RT.RateAnswer TidbitPointer.Snipbit) rateAnswerAction
            else
                common.doNothing

        OnRateAnswerSuccess answerID maybeVote ->
            common.justSetModel { model | qa = model.qa ||> QA.rateAnswer answerID maybeVote }
                |> common.andFinishRequest (RT.RateAnswer TidbitPointer.Snipbit)

        OnRateAnswerFailure apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest (RT.RateAnswer TidbitPointer.Snipbit)

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
                    QA.getQuestionEdit snipbitID question.id model.qaState
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
                    QA.getNewAnswer snipbitID question.id model.qaState
                        |> Maybe.withDefault QA.defaultNewAnswer

                ( newAnswerQuestionModel, newAnswerQuestionMsg ) =
                    AnswerQuestion.update answerQuestionMsg answerQuestionModel
            in
            ( { model
                | qaState =
                    QA.updateNewAnswer
                        snipbitID
                        question.id
                        (always <| Just newAnswerQuestionModel)
                        model.qaState
              }
            , shared
            , Cmd.map (AnswerQuestionMsg snipbitID question) newAnswerQuestionMsg
            )

        EditAnswerMsg snipbitID answerID answer editAnswerMsg ->
            let
                editAnswerModel =
                    QA.getAnswerEdit snipbitID answerID model.qaState
                        |> Maybe.withDefault (QA.answerEditFromAnswer answer)

                ( newEditAnswerModel, newEditAnswerMsg ) =
                    EditAnswer.update editAnswerMsg editAnswerModel
            in
            ( { model
                | qaState =
                    QA.updateAnswerEdit
                        snipbitID
                        answerID
                        (always <| Just newEditAnswerModel)
                        model.qaState
              }
            , shared
            , Cmd.map (EditAnswerMsg snipbitID answerID answer) newEditAnswerMsg
            )

        PinQuestion snipbitID questionID pinQuestion ->
            let
                pinQuestionAction =
                    common.justProduceCmd <|
                        common.api.post.pinQuestion
                            { targetID = snipbitID, tidbitType = TidbitPointer.Snipbit }
                            questionID
                            pinQuestion
                            OnPinQuestionFailure
                            (always <| OnPinQuestionSuccess questionID pinQuestion)
            in
            common.makeSingletonRequest (RT.PinQuestion TidbitPointer.Snipbit) pinQuestionAction

        OnPinQuestionSuccess questionID pinQuestion ->
            common.justSetModel { model | qa = model.qa ||> QA.pinQuestion questionID pinQuestion }
                |> common.andFinishRequest (RT.PinQuestion TidbitPointer.Snipbit)

        OnPinQuestionFailure apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest (RT.PinQuestion TidbitPointer.Snipbit)

        PinAnswer snipbitID answerID pinAnswer ->
            let
                pinAnswerAction =
                    common.justProduceCmd <|
                        common.api.post.pinAnswer
                            { targetID = snipbitID, tidbitType = TidbitPointer.Snipbit }
                            answerID
                            pinAnswer
                            OnPinAnswerFailure
                            (always <| OnPinAnswerSuccess answerID pinAnswer)
            in
            if RT.isNotMakingRequest shared.apiRequestTracker (RT.DeleteAnswer TidbitPointer.Snipbit) then
                common.makeSingletonRequest (RT.PinAnswer TidbitPointer.Snipbit) pinAnswerAction
            else
                common.doNothing

        OnPinAnswerSuccess answerID pinAnswer ->
            common.justSetModel { model | qa = model.qa ||> QA.pinAnswer answerID pinAnswer }
                |> common.andFinishRequest (RT.PinAnswer TidbitPointer.Snipbit)

        OnPinAnswerFailure apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest (RT.PinAnswer TidbitPointer.Snipbit)

        ViewQuestionMsg snipbitID questionID viewQuestionMsg ->
            let
                viewQuestionModel =
                    { questionCommentEdits = QA.getQuestionCommentEdits snipbitID model.qaState
                    , newQuestionComment = QA.getNewQuestionComment snipbitID questionID model.qaState
                    , answerCommentEdits = QA.getAnswerCommentEdits snipbitID model.qaState
                    , newAnswerComments = QA.getNewAnswerComments snipbitID model.qaState
                    , deletingComments = QA.getDeletingComments snipbitID model.qaState
                    , deletingAnswers = QA.getDeletingAnswers snipbitID model.qaState
                    }

                ( newViewQuestionModel, newViewQuestionMsg ) =
                    ViewQuestion.update viewQuestionMsg viewQuestionModel
            in
            ( { model
                | qaState =
                    model.qaState
                        |> QA.updateQuestionCommentEdits snipbitID (always newViewQuestionModel.questionCommentEdits)
                        |> QA.setNewQuestionComment snipbitID questionID (Just newViewQuestionModel.newQuestionComment)
                        |> QA.updateAnswerCommentEdits snipbitID (always newViewQuestionModel.answerCommentEdits)
                        |> QA.updateNewAnswerComments snipbitID (always newViewQuestionModel.newAnswerComments)
                        |> QA.updateDeletingComments snipbitID (always newViewQuestionModel.deletingComments)
                        |> QA.updateDeletingAnswers snipbitID (always newViewQuestionModel.deletingAnswers)
              }
            , shared
            , Cmd.map (ViewQuestionMsg snipbitID questionID) newViewQuestionMsg
            )

        SubmitCommentOnQuestion snipbitID questionID commentText ->
            let
                submitQuestionCommentAction =
                    common.justProduceCmd <|
                        common.api.post.commentOnQuestion
                            { tidbitType = TidbitPointer.Snipbit, targetID = snipbitID }
                            questionID
                            commentText
                            OnSubmitCommentOnQuestionFailure
                            (OnSubmitCommentOnQuestionSuccess snipbitID questionID)
            in
            common.makeSingletonRequest (RT.SubmitQuestionComment TidbitPointer.Snipbit) submitQuestionCommentAction

        OnSubmitCommentOnQuestionSuccess snipbitID questionID questionComment ->
            ( { model
                | qa = model.qa ||> QA.addQuestionComment questionComment
                , qaState = model.qaState |> QA.setNewQuestionComment snipbitID questionID Nothing
              }
            , { shared | textFieldKeyTracker = TextFields.changeKey shared.textFieldKeyTracker "new-comment" }
            , Cmd.none
            )
                |> common.andFinishRequest (RT.SubmitQuestionComment TidbitPointer.Snipbit)

        OnSubmitCommentOnQuestionFailure apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest (RT.SubmitQuestionComment TidbitPointer.Snipbit)

        SubmitCommentOnAnswer snipbitID questionID answerID commentText ->
            let
                submitAnswerCommentAction =
                    common.justProduceCmd <|
                        common.api.post.commentOnAnswer
                            { tidbitType = TidbitPointer.Snipbit, targetID = snipbitID }
                            questionID
                            answerID
                            commentText
                            SubmitCommentOnAnswerFailure
                            (SubmitCommentOnAnswerSuccess snipbitID questionID answerID)
            in
            common.makeSingletonRequest (RT.SubmitAnswerComment TidbitPointer.Snipbit) submitAnswerCommentAction

        SubmitCommentOnAnswerSuccess snipbitID questionID answerID answerComment ->
            ( { model
                | qa = model.qa ||> QA.addAnswerComment answerComment
                , qaState = model.qaState |> QA.updateNewAnswerComments snipbitID (Dict.remove answerID)
              }
            , { shared | textFieldKeyTracker = TextFields.changeKey shared.textFieldKeyTracker "new-comment" }
            , Cmd.none
            )
                |> common.andFinishRequest (RT.SubmitAnswerComment TidbitPointer.Snipbit)

        SubmitCommentOnAnswerFailure apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest (RT.SubmitAnswerComment TidbitPointer.Snipbit)

        DeleteCommentOnQuestion snipbitID commentID ->
            let
                deleteQuestionCommentAction =
                    common.justProduceCmd <|
                        common.api.post.deleteQuestionComment
                            { tidbitType = TidbitPointer.Snipbit, targetID = snipbitID }
                            commentID
                            (OnDeleteCommentOnQuestionFailure commentID)
                            (always <| OnDeleteCommentOnQuestionSuccess snipbitID commentID)
            in
            common.makeSingletonRequest
                (RT.DeleteQuestionComment TidbitPointer.Snipbit commentID)
                deleteQuestionCommentAction

        OnDeleteCommentOnQuestionSuccess snipbitID commentID ->
            common.justSetModel
                { model
                    | qa = model.qa ||> QA.deleteQuestionComment commentID
                    , qaState = model.qaState |> QA.updateQuestionCommentEdits snipbitID (Dict.remove commentID)
                }
                |> common.andFinishRequest (RT.DeleteQuestionComment TidbitPointer.Snipbit commentID)

        OnDeleteCommentOnQuestionFailure commentID apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest (RT.DeleteQuestionComment TidbitPointer.Snipbit commentID)

        DeleteCommentOnAnswer snipbitID commentID ->
            let
                deleteAnswerCommentAction =
                    common.justProduceCmd <|
                        common.api.post.deleteAnswerComment
                            { tidbitType = TidbitPointer.Snipbit, targetID = snipbitID }
                            commentID
                            (OnDeleteCommentOnAnswerFailure commentID)
                            (always <| OnDeleteCommentOnAnswerSuccess snipbitID commentID)
            in
            common.makeSingletonRequest
                (RT.DeleteAnswerComment TidbitPointer.Snipbit commentID)
                deleteAnswerCommentAction

        OnDeleteCommentOnAnswerSuccess snipbitID commentID ->
            common.justSetModel
                { model
                    | qa = model.qa ||> QA.deleteAnswerComment commentID
                    , qaState = QA.updateAnswerCommentEdits snipbitID (Dict.remove commentID) model.qaState
                }
                |> common.andFinishRequest (RT.DeleteAnswerComment TidbitPointer.Snipbit commentID)

        OnDeleteCommentOnAnswerFailure commentID apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest (RT.DeleteAnswerComment TidbitPointer.Snipbit commentID)

        EditCommentOnQuestion snipbitID commentID commentText ->
            let
                editQuestionCommentAction =
                    common.justProduceCmd <|
                        common.api.post.editQuestionComment
                            { tidbitType = TidbitPointer.Snipbit, targetID = snipbitID }
                            commentID
                            commentText
                            (OnEditCommentOnQuestionFailure commentID)
                            (OnEditCommentOnQuestionSuccess snipbitID commentID commentText)
            in
            common.makeSingletonRequest
                (RT.EditQuestionComment TidbitPointer.Snipbit commentID)
                editQuestionCommentAction

        OnEditCommentOnQuestionSuccess snipbitID commentID commentText lastModified ->
            common.justSetModel
                { model
                    | qa = model.qa ||> QA.editQuestionComment commentID commentText lastModified
                    , qaState =
                        model.qaState
                            |> QA.updateQuestionCommentEdits snipbitID (Dict.remove commentID)
                            |> QA.updateDeletingComments snipbitID (Set.remove commentID)
                }
                |> common.andFinishRequest (RT.EditQuestionComment TidbitPointer.Snipbit commentID)

        OnEditCommentOnQuestionFailure commentID apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest (RT.EditQuestionComment TidbitPointer.Snipbit commentID)

        EditCommentOnAnswer snipbitID commentID commentText ->
            let
                editAnswerCommentAction =
                    common.justProduceCmd <|
                        common.api.post.editAnswerComment
                            { tidbitType = TidbitPointer.Snipbit, targetID = snipbitID }
                            commentID
                            commentText
                            (OnEditCommentOnAnswerFailure commentID)
                            (OnEditCommentOnAnswerSuccess snipbitID commentID commentText)
            in
            common.makeSingletonRequest
                (RT.EditAnswerComment TidbitPointer.Snipbit commentID)
                editAnswerCommentAction

        OnEditCommentOnAnswerSuccess snipbitID commentID commentText lastModified ->
            common.justSetModel
                { model
                    | qa = model.qa ||> QA.editAnswerComment commentID commentText lastModified
                    , qaState =
                        model.qaState
                            |> QA.updateAnswerCommentEdits snipbitID (Dict.remove commentID)
                            |> QA.updateDeletingComments snipbitID (Set.remove commentID)
                }
                |> common.andFinishRequest (RT.EditAnswerComment TidbitPointer.Snipbit commentID)

        OnEditCommentOnAnswerFailure commentID apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest (RT.EditAnswerComment TidbitPointer.Snipbit commentID)

        SetUserNeedsAuthModal message ->
            common.justSetUserNeedsAuthModal message


{-| Creates the editor for the snipbit.

Will handle redirects if bad path and highlighting code.

-}
createViewSnipbitCodeEditor : Snipbit.Snipbit -> Shared -> Cmd msg
createViewSnipbitCodeEditor snipbit { route, user } =
    let
        editorWithRange range =
            snipbitEditor snipbit user True True range
    in
    Cmd.batch
        [ case route of
            Route.ViewSnipbitFramePage fromStoryID mongoID frameNumber ->
                if frameNumber > Array.length snipbit.highlightedComments then
                    Route.modifyTo <|
                        Route.ViewSnipbitFramePage fromStoryID mongoID (Array.length snipbit.highlightedComments)
                else if frameNumber < 1 then
                    Route.modifyTo <| Route.ViewSnipbitFramePage fromStoryID mongoID 1
                else
                    Array.get
                        (frameNumber - 1)
                        snipbit.highlightedComments
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
    -> Int
    -> Shared
    -> Cmd msg
createViewSnipbitQACodeEditor ( snipbit, qa, qaState ) bookmark { route, user } =
    let
        editorWithRange { selectAllowed, useMarker } range =
            snipbitEditor snipbit user selectAllowed useMarker range

        redirectToTutorial maybeStoryID =
            Route.modifyTo <| routeForBookmark maybeStoryID snipbit.id bookmark

        -- Create the editor for the given question or redirect if the question doesn't exist.
        createEditorForQuestionID maybeStoryID questionID =
            QA.getQuestion questionID qa.questions
                ||> (.codePointer >> Just >> editorWithRange { selectAllowed = False, useMarker = True })
                ?> redirectToTutorial maybeStoryID

        -- Create the editor for the given answer or redirect if the answer doesn't exist.
        createEditorForAnswerID maybeStoryID answerID =
            QA.getQuestionByAnswerID answerID qa
                ||> (.codePointer >> Just >> editorWithRange { selectAllowed = False, useMarker = True })
                ?> redirectToTutorial maybeStoryID
    in
    Cmd.batch
        [ case route of
            -- Highlight browsingCodePointer or Nothing.
            Route.ViewSnipbitQuestionsPage _ snipbitID ->
                Dict.get snipbitID qaState
                    |||> .browsingCodePointer
                    |> editorWithRange { selectAllowed = True, useMarker = False }

            Route.ViewSnipbitQuestionPage maybeStoryID _ _ questionID ->
                createEditorForQuestionID maybeStoryID questionID

            Route.ViewSnipbitAnswersPage maybeStoryID _ _ questionID ->
                createEditorForQuestionID maybeStoryID questionID

            Route.ViewSnipbitAnswerPage maybeStoryID _ _ answerID ->
                createEditorForAnswerID maybeStoryID answerID

            Route.ViewSnipbitQuestionCommentsPage maybeStoryID _ _ questionID _ ->
                createEditorForQuestionID maybeStoryID questionID

            Route.ViewSnipbitAnswerCommentsPage maybeStoryID _ _ answerID _ ->
                createEditorForAnswerID maybeStoryID answerID

            -- Higlight newQuestion codePointer or Nothing.
            Route.ViewSnipbitAskQuestion maybeStoryID snipbitID ->
                Dict.get snipbitID qaState
                    ||> .newQuestion
                    |||> .codePointer
                    |> editorWithRange { selectAllowed = True, useMarker = False }

            Route.ViewSnipbitAnswerQuestion maybeStoryID _ questionID ->
                createEditorForQuestionID maybeStoryID questionID

            -- Highlight questionEdit codePointer or original question codePointer.
            Route.ViewSnipbitEditQuestion maybeStoryID snipbitID questionID ->
                case QA.getQuestion questionID qa.questions of
                    Nothing ->
                        redirectToTutorial maybeStoryID

                    Just { authorID, codePointer } ->
                        if Util.maybeMapWithDefault (.id >> (==) authorID) False user then
                            QA.getQuestionEdit snipbitID questionID qaState
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
                            redirectToTutorial maybeStoryID

            Route.ViewSnipbitEditAnswer maybeStoryID snipbitID answerID ->
                let
                    isAuthor =
                        QA.getAnswer answerID qa.answers
                            |||>
                                (\{ authorID } ->
                                    user
                                        ||> .id
                                        ||> (==) authorID
                                )
                            ?> False
                in
                if isAuthor then
                    createEditorForAnswerID maybeStoryID answerID
                else
                    redirectToTutorial maybeStoryID

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
                            (snipbitEditor snipbit user False True << Just << .range << Tuple.second)
                            Cmd.none

        _ ->
            Cmd.none


{-| Wrapper around the port for creating an editor with the view-snipbit-settings pre-filled.
-}
snipbitEditor : Snipbit.Snipbit -> Maybe User.User -> Bool -> Bool -> Maybe Range.Range -> Cmd msg
snipbitEditor snipbit user selectAllowed useMarker range =
    Ports.createCodeEditor
        { id = "view-snipbit-code-editor"
        , fileID = ""
        , lang = Editor.aceLanguageLocation snipbit.language
        , theme = User.getTheme user
        , value = snipbit.code
        , range = range
        , useMarker = useMarker
        , readOnly = True
        , selectAllowed = selectAllowed
        }
