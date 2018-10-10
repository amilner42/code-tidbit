module Pages.ViewBigbit.Update exposing (..)

import Api exposing (api)
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
import Elements.Simple.FileStructure as FS
import Models.Bigbit as Bigbit
import Models.Completed as Completed
import Models.ContentPointer as ContentPointer
import Models.Opinion as Opinion
import Models.QA as QA exposing (defaultNewQuestion)
import Models.Range as Range
import Models.RequestTracker as RT
import Models.Route as Route
import Models.TidbitPointer as TidbitPointer
import Models.User as User
import Models.ViewerRelevantHC as ViewerRelevantHC
import Pages.Messages as BaseMessage
import Pages.Model exposing (Shared)
import Pages.ViewBigbit.Messages exposing (..)
import Pages.ViewBigbit.Model exposing (..)
import Ports
import Set


{-| `ViewBigbit` update.
-}
update : CommonSubPageUtil Model Shared Msg BaseMessage.Msg -> Msg -> Model -> Shared -> ( Model, Shared, Cmd BaseMessage.Msg )
update (Common common) msg model shared =
    case msg of
        GoToAskQuestionWithCodePointer bigbitID maybeCodePointer ->
            ( { model
                | qaState =
                    model.qaState
                        |> QA.updateNewQuestion
                            bigbitID
                            (always { defaultNewQuestion | codePointer = maybeCodePointer })
              }
            , shared
            , Route.navigateTo <|
                Route.ViewBigbitAskQuestion
                    (Route.getFromStoryQueryParamOnViewBigbitRoute shared.route)
                    bigbitID
            )

        GoToBrowseQuestionsWithCodePointer bigbitID maybeCodePointer ->
            ( { model
                | qaState =
                    model.qaState
                        |> QA.setBrowsingCodePointer bigbitID maybeCodePointer
              }
            , shared
            , Route.navigateTo <|
                Route.ViewBigbitQuestionsPage
                    (Route.getFromStoryQueryParamOnViewBigbitRoute shared.route)
                    bigbitID
            )

        OnRouteHit route ->
            let
                clearStateOnRouteHit (Common common) ( model, shared ) =
                    common.justSetModel
                        { model
                            | relevantHC = Nothing
                            , relevantQuestions = Nothing
                            , tutorialCodePointer = Nothing
                        }

                clearDeletingComments bigbitID (Common common) ( model, shared ) =
                    common.justSetModel
                        { model | qaState = model.qaState |> QA.updateDeletingComments bigbitID (always Set.empty) }

                clearDeletingAnswers bigbitID (Common common) ( model, shared ) =
                    common.justSetModel
                        { model | qaState = model.qaState |> QA.updateDeletingAnswers bigbitID (always Set.empty) }

                setBookmark bookMarkedFrameNumber (Common common) ( model, shared ) =
                    common.justSetModel
                        { model | bookmark = bookMarkedFrameNumber }

                {- Get's data for viewing bigbit as required:
                   - May need to fetch tidbit itself                                    [Cache level: localStorage]
                   - May need to fetch story                                            [Cache level: browserModel]
                   - May need to fetch if the tidbit is completed by the user.          [Cache level: browserModel]
                   - May need to fetch the users opinion on the tidbit.                 [Cache level: browserModel]
                   - May need to fetch QA                                               [Cache level: browserModel]

                    Depending on `requireLoadingQAPreRender`, it will either wait for both the bigbit and the QA to load
                    and then render the editor or it will render the editor just after the bigbit is loaded.
                -}
                fetchOrRenderViewBigbitData requireLoadingQAPreRender bigbitID (Common common) ( model, shared ) =
                    let
                        currentTidbitPointer =
                            TidbitPointer.TidbitPointer TidbitPointer.Bigbit bigbitID

                        -- Handle getting bigbit if needed.
                        handleGetBigbit (Common common) ( model, shared ) =
                            let
                                getBigbit =
                                    ( setBigbit Nothing model
                                    , shared
                                    , api.get.bigbit
                                        bigbitID
                                        (common.subMsg << OnGetBigbitFailure)
                                        (common.subMsg << OnGetBigbitSuccess requireLoadingQAPreRender)
                                    )
                            in
                            case model.bigbit of
                                Nothing ->
                                    getBigbit

                                Just bigbit ->
                                    if bigbit.id == bigbitID then
                                        common.justProduceCmd <|
                                            if not requireLoadingQAPreRender then
                                                createViewBigbitCodeEditor bigbit shared
                                            else
                                                case model.qa of
                                                    Nothing ->
                                                        Cmd.none

                                                    Just qa ->
                                                        createViewBigbitQACodeEditor
                                                            ( bigbit, qa, model.qaState )
                                                            model.bookmark
                                                            shared
                                    else
                                        getBigbit

                        -- Handle getting bigbit is-completed if needed.
                        handleGetBigbitIsCompleted (Common common) ( model, shared ) =
                            let
                                -- Command for fetching the `isCompleted`
                                getBigbitIsCompleted userID =
                                    ( setIsCompleted Nothing model
                                    , shared
                                    , api.post.checkCompleted
                                        (Completed.Completed currentTidbitPointer userID)
                                        (common.subMsg << OnGetCompletedFailure)
                                        (common.subMsg << OnGetCompletedSuccess << Completed.IsCompleted currentTidbitPointer)
                                    )
                            in
                            case ( shared.user, model.isCompleted ) of
                                ( Just user, Just currentCompleted ) ->
                                    if currentCompleted.tidbitPointer == currentTidbitPointer then
                                        common.doNothing
                                    else
                                        getBigbitIsCompleted user.id

                                ( Just user, Nothing ) ->
                                    getBigbitIsCompleted user.id

                                _ ->
                                    common.doNothing

                        handleGetBigbitOpinion (Common common) ( model, shared ) =
                            let
                                contentPointer =
                                    { contentType = ContentPointer.Bigbit
                                    , contentID = bigbitID
                                    }

                                getOpinion =
                                    ( { model | possibleOpinion = Nothing }
                                    , shared
                                    , api.get.opinion
                                        contentPointer
                                        (common.subMsg << OnGetOpinionFailure)
                                        (common.subMsg << OnGetOpinionSuccess << Opinion.PossibleOpinion contentPointer)
                                    )
                            in
                            case ( shared.user, model.possibleOpinion ) of
                                ( Just user, Just { contentPointer, rating } ) ->
                                    if contentPointer.contentID == bigbitID then
                                        common.doNothing
                                    else
                                        getOpinion

                                ( Just user, Nothing ) ->
                                    getOpinion

                                _ ->
                                    common.doNothing

                        handleGetStoryForBigbit (Common common) ( model, shared ) =
                            let
                                maybeViewingStoryID =
                                    Maybe.map .id shared.viewingStory

                                getStory storyID =
                                    api.get.expandedStoryWithCompleted
                                        storyID
                                        (common.subMsg << OnGetExpandedStoryFailure)
                                        (common.subMsg << OnGetExpandedStorySuccess)
                            in
                            case Route.getFromStoryQueryParamOnViewBigbitRoute shared.route of
                                Just fromStoryID ->
                                    if Just fromStoryID == maybeViewingStoryID then
                                        common.doNothing
                                    else
                                        ( model
                                        , { shared | viewingStory = Nothing }
                                        , getStory fromStoryID
                                        )

                                _ ->
                                    common.justSetShared { shared | viewingStory = Nothing }

                        handleGetQA (Common common) ( model, shared ) =
                            let
                                getQA =
                                    ( { model | qa = Nothing }
                                    , shared
                                    , api.get.bigbitQA
                                        bigbitID
                                        (common.subMsg << OnGetQAFailure)
                                        (common.subMsg << OnGetQASuccess requireLoadingQAPreRender)
                                    )
                            in
                            case model.qa of
                                Nothing ->
                                    getQA

                                Just qa ->
                                    if qa.tidbitID == bigbitID then
                                        common.justProduceCmd <|
                                            if not requireLoadingQAPreRender then
                                                Cmd.none
                                            else
                                                case model.bigbit of
                                                    Nothing ->
                                                        Cmd.none

                                                    Just bigbit ->
                                                        createViewBigbitQACodeEditor
                                                            ( bigbit, qa, model.qaState )
                                                            model.bookmark
                                                            shared
                                    else
                                        getQA
                    in
                    common.handleAll
                        [ handleGetBigbit
                        , handleGetBigbitIsCompleted
                        , handleGetBigbitOpinion
                        , handleGetStoryForBigbit
                        , handleGetQA
                        ]
            in
            case route of
                Route.ViewBigbitFramePage _ bigbitID frameNumber _ ->
                    common.handleAll
                        [ clearStateOnRouteHit
                        , setBookmark frameNumber
                        , fetchOrRenderViewBigbitData False bigbitID

                        -- Setting completed if not already complete.
                        , \(Common common) ( model, shared ) ->
                            common.justProduceCmd <|
                                case ( shared.user, model.isCompleted ) of
                                    ( Just user, Just isCompleted ) ->
                                        let
                                            completed =
                                                Completed.completedFromIsCompleted isCompleted user.id

                                            isLastFrame =
                                                model.bigbit
                                                    ||> .highlightedComments
                                                    ||> Array.length
                                                    ||> (==) frameNumber
                                                    ?> False
                                        in
                                        if isCompleted.complete == False && isLastFrame then
                                            api.post.addCompleted
                                                completed
                                                (common.subMsg << OnMarkAsCompleteFailure)
                                                (always <|
                                                    common.subMsg <|
                                                        OnMarkAsCompleteSuccess <|
                                                            Completed.IsCompleted completed.tidbitPointer True
                                                )
                                        else
                                            Cmd.none

                                    _ ->
                                        Cmd.none
                        ]

                Route.ViewBigbitQuestionsPage _ bigbitID ->
                    common.handleAll
                        [ clearStateOnRouteHit
                        , fetchOrRenderViewBigbitData True bigbitID
                        ]

                Route.ViewBigbitQuestionPage _ _ bigbitID _ ->
                    common.handleAll
                        [ clearStateOnRouteHit
                        , fetchOrRenderViewBigbitData True bigbitID
                        ]

                Route.ViewBigbitAnswersPage _ _ bigbitID _ ->
                    common.handleAll
                        [ clearStateOnRouteHit
                        , fetchOrRenderViewBigbitData True bigbitID
                        ]

                Route.ViewBigbitAnswerPage _ _ bigbitID _ ->
                    common.handleAll
                        [ clearStateOnRouteHit
                        , fetchOrRenderViewBigbitData True bigbitID
                        , clearDeletingAnswers bigbitID
                        ]

                Route.ViewBigbitQuestionCommentsPage _ _ bigbitID _ _ ->
                    common.handleAll
                        [ clearStateOnRouteHit
                        , fetchOrRenderViewBigbitData True bigbitID
                        , clearDeletingComments bigbitID
                        ]

                Route.ViewBigbitAnswerCommentsPage _ _ bigbitID _ _ ->
                    common.handleAll
                        [ clearStateOnRouteHit
                        , fetchOrRenderViewBigbitData True bigbitID
                        , clearDeletingComments bigbitID
                        ]

                Route.ViewBigbitAskQuestion _ bigbitID ->
                    common.handleAll
                        [ clearStateOnRouteHit
                        , fetchOrRenderViewBigbitData True bigbitID
                        ]

                Route.ViewBigbitEditQuestion _ bigbitID _ ->
                    common.handleAll
                        [ clearStateOnRouteHit
                        , fetchOrRenderViewBigbitData True bigbitID
                        ]

                Route.ViewBigbitAnswerQuestion _ bigbitID _ ->
                    common.handleAll
                        [ clearStateOnRouteHit
                        , fetchOrRenderViewBigbitData True bigbitID
                        ]

                Route.ViewBigbitEditAnswer _ bigbitID _ ->
                    common.handleAll
                        [ clearStateOnRouteHit
                        , fetchOrRenderViewBigbitData True bigbitID
                        ]

                _ ->
                    common.doNothing

        OnRangeSelected selectedRange ->
            let
                maybeCurrentActiveFile =
                    model.bigbit
                        |||>
                            (\bigbit ->
                                Route.viewBigbitPageCurrentActiveFile shared.route bigbit model.qa model.qaState
                            )

                handleSetTutorialCodePointer currentActiveFile (Common common) ( model, shared ) =
                    common.justSetModel
                        { model | tutorialCodePointer = Just { file = currentActiveFile, range = selectedRange } }

                handleFindRelevantFrames currentActiveFile (Common common) ( model, shared ) =
                    case model.bigbit of
                        Just aBigbit ->
                            common.justUpdateModel <|
                                setRelevantHC <|
                                    if Range.isEmptyRange selectedRange then
                                        Nothing
                                    else
                                        aBigbit.highlightedComments
                                            |> Array.indexedMap (,)
                                            |> Array.filter
                                                (\( _, { file, range } ) ->
                                                    QA.isBigbitCodePointerOverlap
                                                        { file = currentActiveFile, range = selectedRange }
                                                        { file = file, range = range }
                                                )
                                            |> (\relevantHC ->
                                                    Just
                                                        { currentHC = Nothing
                                                        , relevantHC = relevantHC
                                                        }
                                               )

                        Nothing ->
                            common.doNothing

                handleFindRelevantQuestions currentActiveFile (Common common) ( model, shared ) =
                    case model.qa of
                        Just { questions } ->
                            if Range.isEmptyRange selectedRange then
                                common.justSetModel { model | relevantQuestions = Nothing }
                            else
                                questions
                                    |> List.filter
                                        (.codePointer
                                            >> QA.isBigbitCodePointerOverlap
                                                { file = currentActiveFile, range = selectedRange }
                                        )
                                    |> (\relevantQuestions ->
                                            common.justSetModel
                                                { model
                                                    | relevantQuestions = Just relevantQuestions
                                                }
                                       )

                        Nothing ->
                            common.doNothing
            in
            case ( maybeCurrentActiveFile, shared.route ) of
                ( Just currentActiveFile, Route.ViewBigbitFramePage _ _ _ _ ) ->
                    common.handleAll
                        [ handleSetTutorialCodePointer currentActiveFile
                        , handleFindRelevantFrames currentActiveFile
                        , handleFindRelevantQuestions currentActiveFile
                        ]

                ( Just _, Route.ViewBigbitQuestionsPage _ bigbitID ) ->
                    case QA.getBrowseCodePointer bigbitID model.qaState of
                        Just codePointer ->
                            common.justSetModel
                                { model
                                    | qaState =
                                        QA.setBrowsingCodePointer
                                            bigbitID
                                            (Just { codePointer | range = selectedRange })
                                            model.qaState
                                }

                        -- No active file (impossible, outer case checks for file).
                        Nothing ->
                            common.doNothing

                ( Just _, Route.ViewBigbitAskQuestion _ bigbitID ) ->
                    case QA.getNewQuestion bigbitID model.qaState |||> .codePointer of
                        Just codePointer ->
                            common.justSetModel
                                { model
                                    | qaState =
                                        QA.updateNewQuestion
                                            bigbitID
                                            (\newQuestion ->
                                                { newQuestion
                                                    | codePointer = Just { codePointer | range = selectedRange }
                                                }
                                            )
                                            model.qaState
                                }

                        -- No active file (impossible, outer case checks for file).
                        Nothing ->
                            common.doNothing

                ( Just _, Route.ViewBigbitEditQuestion _ bigbitID questionID ) ->
                    case model.qa ||> .questions |||> QA.getQuestion questionID of
                        Just question ->
                            common.justSetModel
                                { model
                                    | qaState =
                                        QA.updateQuestionEdit
                                            bigbitID
                                            questionID
                                            (\maybeQuestionEdit ->
                                                maybeQuestionEdit
                                                    ?> QA.questionEditFromQuestion question
                                                    |> (\questionEdit ->
                                                            { questionEdit
                                                                | codePointer =
                                                                    Editable.updateBuffer
                                                                        questionEdit.codePointer
                                                                        (\codePointer ->
                                                                            { codePointer | range = selectedRange }
                                                                        )
                                                            }
                                                       )
                                                    |> Just
                                            )
                                            model.qaState
                                }

                        -- Means that editing a non-existant question, should never happen (will have redirected).
                        _ ->
                            common.doNothing

                _ ->
                    common.doNothing

        OnGetBigbitSuccess requireLoadingQAPreRender bigbit ->
            ( Util.multipleUpdates
                [ setBigbit <| Just bigbit
                , setRelevantHC Nothing
                ]
                model
            , shared
            , if not requireLoadingQAPreRender then
                createViewBigbitCodeEditor bigbit shared
              else
                case model.qa of
                    Nothing ->
                        Cmd.none

                    Just qa ->
                        createViewBigbitQACodeEditor ( bigbit, qa, model.qaState ) model.bookmark shared
            )

        OnGetBigbitFailure apiError ->
            common.justSetModalError apiError

        OnGetCompletedSuccess isCompleted ->
            common.justUpdateModel <| setIsCompleted <| Just isCompleted

        OnGetCompletedFailure apiError ->
            common.justSetModalError apiError

        OnGetOpinionSuccess possibleOpinion ->
            common.justSetModel { model | possibleOpinion = Just possibleOpinion }

        OnGetOpinionFailure apiError ->
            common.justSetModalError apiError

        AddOpinion opinion ->
            let
                addOpinionAction =
                    common.justProduceCmd <|
                        api.post.addOpinion
                            opinion
                            (common.subMsg << OnAddOpinionFailure)
                            (always <| common.subMsg <| OnAddOpinionSuccess opinion)
            in
            common.makeSingletonRequest (RT.AddOrRemoveOpinion ContentPointer.Bigbit) addOpinionAction

        OnAddOpinionSuccess opinion ->
            common.justSetModel { model | possibleOpinion = Just (Opinion.toPossibleOpinion opinion) }
                |> common.andFinishRequest (RT.AddOrRemoveOpinion ContentPointer.Bigbit)

        OnAddOpinionFailure apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest (RT.AddOrRemoveOpinion ContentPointer.Bigbit)

        RemoveOpinion opinion ->
            let
                removeOpinionAction =
                    common.justProduceCmd <|
                        api.post.removeOpinion
                            opinion
                            (common.subMsg << OnRemoveOpinionFailure)
                            (always <| common.subMsg <| OnRemoveOpinionSuccess opinion)
            in
            common.makeSingletonRequest (RT.AddOrRemoveOpinion ContentPointer.Bigbit) removeOpinionAction

        {- Currently it doesn't matter what opinion we removed because you can only have 1, but it may change in the
           future where we have multiple opinions, then use the `opinion` to figure out which to remove.
        -}
        OnRemoveOpinionSuccess { contentPointer, rating } ->
            common.justSetModel { model | possibleOpinion = Just { contentPointer = contentPointer, rating = Nothing } }
                |> common.andFinishRequest (RT.AddOrRemoveOpinion ContentPointer.Bigbit)

        OnRemoveOpinionFailure apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest (RT.AddOrRemoveOpinion ContentPointer.Bigbit)

        OnGetExpandedStorySuccess story ->
            common.justSetShared { shared | viewingStory = Just story }

        OnGetExpandedStoryFailure apiError ->
            common.justSetModalError apiError

        ToggleFS ->
            common.justUpdateModel <|
                updateBigbit
                    (\currentViewingBigbit ->
                        { currentViewingBigbit
                            | fs = Bigbit.toggleFS currentViewingBigbit.fs
                        }
                    )

        SelectFile absolutePath ->
            let
                handleFileSelectOnTutorialRoute =
                    let
                        tutorialFile =
                            case shared.route of
                                Route.ViewBigbitFramePage _ _ frameNumber _ ->
                                    Maybe.andThen (Bigbit.getHighlightedComment frameNumber) model.bigbit
                                        |> Maybe.map .file

                                _ ->
                                    Nothing
                    in
                    if Just absolutePath == tutorialFile then
                        common.justProduceCmd <|
                            Route.navigateToSameUrlWithFilePath Nothing shared.route
                    else
                        common.justProduceCmd <|
                            Route.navigateToSameUrlWithFilePath (Just absolutePath) shared.route

                refreshCmd =
                    Route.modifyTo shared.route
            in
            case shared.route of
                Route.ViewBigbitFramePage _ _ _ _ ->
                    handleFileSelectOnTutorialRoute

                Route.ViewBigbitQuestionsPage _ bigbitID ->
                    ( { model
                        | qaState =
                            QA.setBrowsingCodePointer
                                bigbitID
                                (Just { file = absolutePath, range = Range.zeroRange })
                                model.qaState
                      }
                    , shared
                    , refreshCmd
                    )

                Route.ViewBigbitAskQuestion _ bigbitID ->
                    ( { model
                        | qaState =
                            QA.updateNewQuestion
                                bigbitID
                                (\newQuestion ->
                                    { newQuestion
                                        | codePointer = Just { file = absolutePath, range = Range.zeroRange }
                                    }
                                )
                                model.qaState
                      }
                    , shared
                    , refreshCmd
                    )

                Route.ViewBigbitEditQuestion _ bigbitID questionID ->
                    case model.qa ||> .questions |||> QA.getQuestion questionID of
                        Just question ->
                            ( { model
                                | qaState =
                                    QA.updateQuestionEdit
                                        bigbitID
                                        questionID
                                        (\maybeQuestionEdit ->
                                            maybeQuestionEdit
                                                ?> QA.questionEditFromQuestion question
                                                |> (\questionEdit ->
                                                        { questionEdit
                                                            | codePointer =
                                                                Editable.setBuffer
                                                                    questionEdit.codePointer
                                                                    { file = absolutePath
                                                                    , range = Range.zeroRange
                                                                    }
                                                        }
                                                   )
                                                |> Just
                                        )
                                        model.qaState
                              }
                            , shared
                            , refreshCmd
                            )

                        -- Should never happen (will have redirected).
                        Nothing ->
                            common.doNothing

                _ ->
                    common.doNothing

        ToggleFolder absolutePath ->
            common.justUpdateModel <|
                updateBigbit <|
                    \currentViewingBigbit ->
                        { currentViewingBigbit
                            | fs =
                                Bigbit.toggleFSFolder absolutePath currentViewingBigbit.fs
                        }

        BrowseRelevantHC ->
            let
                newModel =
                    updateRelevantHC
                        (\currentRelevantHC ->
                            { currentRelevantHC
                                | currentHC = Just 0
                            }
                        )
                        model
            in
            ( newModel
            , shared
            , createViewBigbitHCCodeEditor
                newModel.bigbit
                newModel.relevantHC
                shared.user
            )

        NextRelevantHC ->
            let
                newModel =
                    updateRelevantHC ViewerRelevantHC.goToNextFrame model
            in
            ( newModel
            , shared
            , createViewBigbitHCCodeEditor
                newModel.bigbit
                newModel.relevantHC
                shared.user
            )

        PreviousRelevantHC ->
            let
                newModel =
                    updateRelevantHC ViewerRelevantHC.goToPreviousFrame model
            in
            ( newModel
            , shared
            , createViewBigbitHCCodeEditor
                newModel.bigbit
                newModel.relevantHC
                shared.user
            )

        OnMarkAsCompleteSuccess isCompleted ->
            common.justUpdateModel <| setIsCompleted <| Just isCompleted

        OnMarkAsCompleteFailure apiError ->
            common.justSetModalError apiError

        BackToTutorialSpot ->
            case shared.route of
                Route.ViewBigbitFramePage _ _ _ _ ->
                    common.justProduceCmd <| Route.navigateToSameUrlWithFilePath Nothing shared.route

                _ ->
                    common.doNothing

        OnGetQASuccess requireLoadingQAPreRender qa ->
            ( { model
                | qa =
                    Just
                        { qa
                            | questions = QA.sortRateableContent qa.questions
                            , answers = QA.sortRateableContent qa.answers
                        }
              }
            , shared
            , if not requireLoadingQAPreRender then
                Cmd.none
              else
                case model.bigbit of
                    Nothing ->
                        Cmd.none

                    Just bigbit ->
                        createViewBigbitQACodeEditor ( bigbit, qa, model.qaState ) model.bookmark shared
            )

        OnGetQAFailure apiError ->
            common.justSetModalError apiError

        AskQuestionMsg bigbitID askQuestionMsg ->
            let
                askQuestionModel =
                    { qaState = model.qaState, apiRequestTracker = shared.apiRequestTracker }

                ( newAskQuestionModel, newAskQuestionMsg ) =
                    AskQuestion.update askQuestionMsg askQuestionModel
            in
            ( { model | qaState = newAskQuestionModel.qaState }
            , { shared | apiRequestTracker = newAskQuestionModel.apiRequestTracker }
            , Cmd.map (common.subMsg << AskQuestionMsg bigbitID) newAskQuestionMsg
            )

        EditQuestionMsg bigbitID question editQuestionMsg ->
            let
                editQuestionModel =
                    QA.getQuestionEdit bigbitID question.id model.qaState
                        ?> QA.questionEditFromQuestion question

                ( newEditQuestionModel, newQuestionEditMsg ) =
                    EditQuestion.update editQuestionMsg editQuestionModel
            in
            ( { model
                | qaState =
                    QA.updateQuestionEdit
                        bigbitID
                        question.id
                        (always <| Just newEditQuestionModel)
                        model.qaState
              }
            , shared
            , Cmd.map (common.subMsg << EditQuestionMsg bigbitID question) newQuestionEditMsg
            )

        EditQuestion bigbitID questionID questionText codePointer ->
            let
                editQuestionAction =
                    common.justProduceCmd <|
                        api.post.editQuestionOnBigbit
                            bigbitID
                            questionID
                            questionText
                            codePointer
                            (common.subMsg << OnEditQuestionFailure)
                            (common.subMsg << OnEditQuestionSuccess bigbitID questionID questionText codePointer)
            in
            common.makeSingletonRequest (RT.UpdateQuestion TidbitPointer.Bigbit) editQuestionAction

        OnEditQuestionSuccess bigbitID questionID questionText codePointer lastModified ->
            (case model.qa of
                Just qa ->
                    ( { model
                        | qa =
                            qa
                                |> QA.updateQuestion
                                    questionID
                                    (\question ->
                                        { question
                                            | codePointer = codePointer
                                            , questionText = questionText
                                            , lastModified = lastModified
                                        }
                                    )
                                |> Just
                        , qaState =
                            model.qaState
                                |> QA.updateQuestionEdit
                                    bigbitID
                                    questionID
                                    (always Nothing)
                      }
                    , shared
                    , Route.navigateTo <|
                        Route.ViewBigbitQuestionPage
                            (Route.getFromStoryQueryParamOnViewBigbitRoute shared.route)
                            (Route.getTouringQuestionsQueryParamOnViewBigbitQARoute shared.route)
                            bigbitID
                            questionID
                    )

                Nothing ->
                    common.doNothing
            )
                |> common.andFinishRequest (RT.UpdateQuestion TidbitPointer.Bigbit)

        OnEditQuestionFailure apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest (RT.UpdateQuestion TidbitPointer.Bigbit)

        AnswerQuestionMsg qa bigbitID answerQuestionMsg ->
            let
                answerQuestionModel =
                    { qa = qa, qaState = model.qaState, apiRequestTracker = shared.apiRequestTracker }

                ( newAnswerQuestionModel, newAnswerQuestionMsg ) =
                    AnswerQuestion.update answerQuestionMsg answerQuestionModel
            in
            ( { model
                | qaState = newAnswerQuestionModel.qaState
                , qa = Just newAnswerQuestionModel.qa
              }
            , { shared | apiRequestTracker = newAnswerQuestionModel.apiRequestTracker }
            , Cmd.map (common.subMsg << AnswerQuestionMsg newAnswerQuestionModel.qa bigbitID) newAnswerQuestionMsg
            )

        EditAnswerMsg bigbitID answer editAnswerMsg ->
            let
                editAnswerModel =
                    model.qaState
                        |> QA.getAnswerEdit bigbitID answer.id
                        ?> QA.answerEditFromAnswer answer

                ( newEditAnswerModel, newEditAnswerMsg ) =
                    EditAnswer.update editAnswerMsg editAnswerModel
            in
            ( { model
                | qaState =
                    model.qaState
                        |> QA.updateAnswerEdit bigbitID answer.id (always <| Just <| newEditAnswerModel)
              }
            , shared
            , Cmd.map (common.subMsg << EditAnswerMsg bigbitID answer) newEditAnswerMsg
            )

        EditAnswer bigbitID answerID answerText ->
            let
                updateAnswerAction =
                    common.justProduceCmd <|
                        api.post.editAnswer
                            { tidbitType = TidbitPointer.Bigbit, targetID = bigbitID }
                            answerID
                            answerText
                            (common.subMsg << OnEditAnswerFailure)
                            (common.subMsg << OnEditAnswerSuccess bigbitID answerID answerText)
            in
            common.makeSingletonRequest (RT.UpdateAnswer TidbitPointer.Bigbit) updateAnswerAction

        OnEditAnswerSuccess bigbitID answerID answerText lastModified ->
            (case model.qa of
                Just qa ->
                    ( { model
                        | qa =
                            qa
                                |> QA.updateAnswer
                                    answerID
                                    (\answer -> Just { answer | answerText = answerText, lastModified = lastModified })
                                |> Just
                        , qaState = model.qaState |> QA.updateAnswerEdit bigbitID answerID (always Nothing)
                      }
                    , shared
                    , Route.navigateTo <|
                        Route.ViewBigbitAnswerPage
                            (Route.getFromStoryQueryParamOnViewBigbitRoute shared.route)
                            (Route.getTouringQuestionsQueryParamOnViewBigbitQARoute shared.route)
                            bigbitID
                            answerID
                    )

                Nothing ->
                    common.doNothing
            )
                |> common.andFinishRequest (RT.UpdateAnswer TidbitPointer.Bigbit)

        OnEditAnswerFailure apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest (RT.UpdateAnswer TidbitPointer.Bigbit)

        ViewQuestionMsg bigbitID questionID viewQuestionMsg ->
            let
                viewQuestionModel =
                    { questionCommentEdits = QA.getQuestionCommentEdits bigbitID model.qaState
                    , newQuestionComment = QA.getNewQuestionComment bigbitID questionID model.qaState
                    , answerCommentEdits = QA.getAnswerCommentEdits bigbitID model.qaState
                    , newAnswerComments = QA.getNewAnswerComments bigbitID model.qaState
                    , deletingComments = QA.getDeletingComments bigbitID model.qaState
                    , deletingAnswers = QA.getDeletingAnswers bigbitID model.qaState
                    }

                ( newViewQuestionModel, newViewQuestionMsg ) =
                    ViewQuestion.update viewQuestionMsg viewQuestionModel
            in
            ( { model
                | qaState =
                    model.qaState
                        |> QA.updateQuestionCommentEdits bigbitID (always newViewQuestionModel.questionCommentEdits)
                        |> QA.setNewQuestionComment bigbitID questionID (Just newViewQuestionModel.newQuestionComment)
                        |> QA.updateAnswerCommentEdits bigbitID (always newViewQuestionModel.answerCommentEdits)
                        |> QA.updateNewAnswerComments bigbitID (always newViewQuestionModel.newAnswerComments)
                        |> QA.updateDeletingComments bigbitID (always newViewQuestionModel.deletingComments)
                        |> QA.updateDeletingAnswers bigbitID (always newViewQuestionModel.deletingAnswers)
              }
            , shared
            , Cmd.map (common.subMsg << ViewQuestionMsg bigbitID questionID) newViewQuestionMsg
            )

        RateQuestion bigbitID questionID maybeVote ->
            let
                rateQuestionAction =
                    common.justProduceCmd <|
                        case maybeVote of
                            Nothing ->
                                api.post.removeQuestionRating
                                    { tidbitType = TidbitPointer.Bigbit, targetID = bigbitID }
                                    questionID
                                    (common.subMsg << OnRateQuestionFailure)
                                    (always <| common.subMsg <| OnRateQuestionSuccess questionID maybeVote)

                            Just vote ->
                                api.post.rateQuestion
                                    { tidbitType = TidbitPointer.Bigbit, targetID = bigbitID }
                                    questionID
                                    vote
                                    (common.subMsg << OnRateQuestionFailure)
                                    (always <| common.subMsg <| OnRateQuestionSuccess questionID maybeVote)
            in
            common.makeSingletonRequest (RT.RateQuestion TidbitPointer.Bigbit) rateQuestionAction

        OnRateQuestionSuccess questionID maybeVote ->
            common.justSetModel { model | qa = model.qa ||> QA.rateQuestion questionID maybeVote }
                |> common.andFinishRequest (RT.RateQuestion TidbitPointer.Bigbit)

        OnRateQuestionFailure apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest (RT.RateQuestion TidbitPointer.Bigbit)

        RateAnswer bigbitID answerID maybeVote ->
            let
                rateAnswerAction =
                    common.justProduceCmd <|
                        case maybeVote of
                            Nothing ->
                                api.post.removeAnswerRating
                                    { tidbitType = TidbitPointer.Bigbit, targetID = bigbitID }
                                    answerID
                                    (common.subMsg << OnRateAnswerFailure)
                                    (always <| common.subMsg <| OnRateAnswerSuccess answerID maybeVote)

                            Just vote ->
                                api.post.rateAnswer
                                    { tidbitType = TidbitPointer.Bigbit, targetID = bigbitID }
                                    answerID
                                    vote
                                    (common.subMsg << OnRateAnswerFailure)
                                    (always <| common.subMsg <| OnRateAnswerSuccess answerID maybeVote)
            in
            if RT.isNotMakingRequest shared.apiRequestTracker (RT.DeleteAnswer TidbitPointer.Bigbit) then
                common.makeSingletonRequest (RT.RateAnswer TidbitPointer.Bigbit) rateAnswerAction
            else
                common.doNothing

        OnRateAnswerSuccess answerID maybeVote ->
            common.justSetModel { model | qa = model.qa ||> QA.rateAnswer answerID maybeVote }
                |> common.andFinishRequest (RT.RateAnswer TidbitPointer.Bigbit)

        OnRateAnswerFailure apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest (RT.RateAnswer TidbitPointer.Bigbit)

        PinQuestion bigbitID questionID pinQuestion ->
            let
                pinQuestionAction =
                    common.justProduceCmd <|
                        api.post.pinQuestion
                            { tidbitType = TidbitPointer.Bigbit, targetID = bigbitID }
                            questionID
                            pinQuestion
                            (common.subMsg << OnPinQuestionFailure)
                            (always <| common.subMsg <| OnPinQuestionSuccess questionID pinQuestion)
            in
            common.makeSingletonRequest (RT.PinQuestion TidbitPointer.Bigbit) pinQuestionAction

        OnPinQuestionSuccess questionID pinQuestion ->
            common.justSetModel { model | qa = model.qa ||> QA.pinQuestion questionID pinQuestion }
                |> common.andFinishRequest (RT.PinQuestion TidbitPointer.Bigbit)

        OnPinQuestionFailure apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest (RT.PinQuestion TidbitPointer.Bigbit)

        PinAnswer bigbitID answerID pinAnswer ->
            let
                pinAnswerAction =
                    common.justProduceCmd <|
                        api.post.pinAnswer
                            { tidbitType = TidbitPointer.Bigbit, targetID = bigbitID }
                            answerID
                            pinAnswer
                            (common.subMsg << OnPinAnswerFailure)
                            (always <| common.subMsg <| OnPinAnswerSuccess answerID pinAnswer)
            in
            if RT.isNotMakingRequest shared.apiRequestTracker (RT.DeleteAnswer TidbitPointer.Bigbit) then
                common.makeSingletonRequest (RT.PinAnswer TidbitPointer.Bigbit) pinAnswerAction
            else
                common.doNothing

        OnPinAnswerSuccess answerID pinAnswer ->
            common.justSetModel { model | qa = model.qa ||> QA.pinAnswer answerID pinAnswer }
                |> common.andFinishRequest (RT.PinAnswer TidbitPointer.Bigbit)

        OnPinAnswerFailure apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest (RT.PinAnswer TidbitPointer.Bigbit)

        DeleteAnswer bigbitID questionID answerID ->
            let
                deleteAnswerAction =
                    common.justProduceCmd <|
                        api.post.deleteAnswer
                            { tidbitType = TidbitPointer.Bigbit, targetID = bigbitID }
                            answerID
                            (common.subMsg << OnDeleteAnswerFailure)
                            (always <| common.subMsg <| OnDeleteAnswerSuccess bigbitID questionID answerID)
            in
            common.makeSingletonRequest (RT.DeleteAnswer TidbitPointer.Bigbit) deleteAnswerAction

        OnDeleteAnswerSuccess bigbitID questionID answerID ->
            (case model.qa of
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
                                |> QA.updateAnswerEdit bigbitID answerID (always Nothing)
                                |> QA.deleteOldAnswerCommentEdits bigbitID updatedQA.answerComments
                    in
                    ( { model
                        | qa = Just updatedQA
                        , qaState = updatedQAState
                      }
                    , shared
                    , Route.navigateTo <|
                        Route.ViewBigbitAnswersPage
                            (Route.getFromStoryQueryParamOnViewBigbitRoute shared.route)
                            (Route.getTouringQuestionsQueryParamOnViewBigbitQARoute shared.route)
                            bigbitID
                            questionID
                    )

                Nothing ->
                    common.doNothing
            )
                |> common.andFinishRequest (RT.DeleteAnswer TidbitPointer.Bigbit)

        OnDeleteAnswerFailure apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest (RT.DeleteAnswer TidbitPointer.Bigbit)

        SubmitCommentOnQuestion bigbitID questionID commentText ->
            let
                submitQuestionCommentAction =
                    common.justProduceCmd <|
                        api.post.commentOnQuestion
                            { tidbitType = TidbitPointer.Bigbit, targetID = bigbitID }
                            questionID
                            commentText
                            (common.subMsg << OnSubmitCommentOnQuestionFailure)
                            (common.subMsg << OnSubmitCommentOnQuestionSuccess bigbitID questionID)
            in
            common.makeSingletonRequest (RT.SubmitQuestionComment TidbitPointer.Bigbit) submitQuestionCommentAction

        OnSubmitCommentOnQuestionSuccess bigbitID questionID questionComment ->
            ( { model
                | qa = model.qa ||> QA.addQuestionComment questionComment
                , qaState = model.qaState |> QA.setNewQuestionComment bigbitID questionID Nothing
              }
            , { shared | textFieldKeyTracker = TextFields.changeKey shared.textFieldKeyTracker "new-comment" }
            , Cmd.none
            )
                |> common.andFinishRequest (RT.SubmitQuestionComment TidbitPointer.Bigbit)

        OnSubmitCommentOnQuestionFailure apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest (RT.SubmitQuestionComment TidbitPointer.Bigbit)

        SubmitCommentOnAnswer bigbitID questionID answerID commentText ->
            let
                submitAnswerCommentAction =
                    common.justProduceCmd <|
                        api.post.commentOnAnswer
                            { tidbitType = TidbitPointer.Bigbit, targetID = bigbitID }
                            questionID
                            answerID
                            commentText
                            (common.subMsg << OnSubmitCommentOnAnswerFailure)
                            (common.subMsg << OnSubmitCommentOnAnswerSuccess bigbitID questionID answerID)
            in
            common.makeSingletonRequest (RT.SubmitAnswerComment TidbitPointer.Bigbit) submitAnswerCommentAction

        OnSubmitCommentOnAnswerSuccess bigbitID questionID answerID answerComment ->
            ( { model
                | qa = model.qa ||> QA.addAnswerComment answerComment
                , qaState = model.qaState |> QA.updateNewAnswerComments bigbitID (Dict.remove answerID)
              }
            , { shared | textFieldKeyTracker = TextFields.changeKey shared.textFieldKeyTracker "new-comment" }
            , Cmd.none
            )
                |> common.andFinishRequest (RT.SubmitAnswerComment TidbitPointer.Bigbit)

        OnSubmitCommentOnAnswerFailure apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest (RT.SubmitAnswerComment TidbitPointer.Bigbit)

        DeleteCommentOnQuestion bigbitID commentID ->
            let
                deleteQuestionCommentAction =
                    common.justProduceCmd <|
                        api.post.deleteQuestionComment
                            { tidbitType = TidbitPointer.Bigbit, targetID = bigbitID }
                            commentID
                            (common.subMsg << OnDeleteCommentOnQuestionFailure commentID)
                            (always <| common.subMsg <| OnDeleteCommentOnQuestionSuccess bigbitID commentID)
            in
            common.makeSingletonRequest
                (RT.DeleteQuestionComment TidbitPointer.Bigbit commentID)
                deleteQuestionCommentAction

        OnDeleteCommentOnQuestionSuccess bigbitID commentID ->
            common.justSetModel
                { model
                    | qa = model.qa ||> QA.deleteQuestionComment commentID
                    , qaState = model.qaState |> QA.updateQuestionCommentEdits bigbitID (Dict.remove commentID)
                }
                |> common.andFinishRequest (RT.DeleteQuestionComment TidbitPointer.Bigbit commentID)

        OnDeleteCommentOnQuestionFailure commentID apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest (RT.DeleteQuestionComment TidbitPointer.Bigbit commentID)

        DeleteCommentOnAnswer bigbitID commentID ->
            let
                deleteAnswerCommentAction =
                    common.justProduceCmd <|
                        api.post.deleteAnswerComment
                            { tidbitType = TidbitPointer.Bigbit, targetID = bigbitID }
                            commentID
                            (common.subMsg << OnDeleteCommentOnAnswerFailure commentID)
                            (always <| common.subMsg <| OnDeleteCommentOnAnswerSuccess bigbitID commentID)
            in
            common.makeSingletonRequest
                (RT.DeleteAnswerComment TidbitPointer.Bigbit commentID)
                deleteAnswerCommentAction

        OnDeleteCommentOnAnswerSuccess bigbitID commentID ->
            common.justSetModel
                { model
                    | qa = model.qa ||> QA.deleteAnswerComment commentID
                    , qaState = model.qaState |> QA.updateAnswerCommentEdits bigbitID (Dict.remove commentID)
                }
                |> common.andFinishRequest (RT.DeleteAnswerComment TidbitPointer.Bigbit commentID)

        OnDeleteCommentOnAnswerFailure commentID apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest (RT.DeleteAnswerComment TidbitPointer.Bigbit commentID)

        EditCommentOnQuestion bigbitID commentID commentText ->
            let
                editQuestionCommentAction =
                    common.justProduceCmd <|
                        api.post.editQuestionComment
                            { tidbitType = TidbitPointer.Bigbit, targetID = bigbitID }
                            commentID
                            commentText
                            (common.subMsg << OnEditCommentOnQuestionFailure commentID)
                            (common.subMsg << OnEditCommentOnQuestionSuccess bigbitID commentID commentText)
            in
            common.makeSingletonRequest
                (RT.EditQuestionComment TidbitPointer.Bigbit commentID)
                editQuestionCommentAction

        OnEditCommentOnQuestionSuccess bigbitID commentID commentText lastModified ->
            common.justSetModel
                { model
                    | qa = model.qa ||> QA.editQuestionComment commentID commentText lastModified
                    , qaState =
                        model.qaState
                            |> QA.updateQuestionCommentEdits bigbitID (Dict.remove commentID)
                            |> QA.updateDeletingComments bigbitID (Set.remove commentID)
                }
                |> common.andFinishRequest (RT.EditQuestionComment TidbitPointer.Bigbit commentID)

        OnEditCommentOnQuestionFailure commentID apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest (RT.EditQuestionComment TidbitPointer.Bigbit commentID)

        EditCommentOnAnswer bigbitID commentID commentText ->
            let
                editAnswerCommentAction =
                    common.justProduceCmd <|
                        api.post.editAnswerComment
                            { tidbitType = TidbitPointer.Bigbit, targetID = bigbitID }
                            commentID
                            commentText
                            (common.subMsg << OnEditCommentOnAnswerFailure commentID)
                            (common.subMsg << OnEditCommentOnAnswerSuccess bigbitID commentID commentText)
            in
            common.makeSingletonRequest
                (RT.EditAnswerComment TidbitPointer.Bigbit commentID)
                editAnswerCommentAction

        OnEditCommentOnAnswerSuccess bigbitID commentID commentText lastModified ->
            common.justSetModel
                { model
                    | qa = model.qa ||> QA.editAnswerComment commentID commentText lastModified
                    , qaState =
                        model.qaState
                            |> QA.updateAnswerCommentEdits bigbitID (Dict.remove commentID)
                            |> QA.updateDeletingComments bigbitID (Set.remove commentID)
                }
                |> common.andFinishRequest (RT.EditAnswerComment TidbitPointer.Bigbit commentID)

        OnEditCommentOnAnswerFailure commentID apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest (RT.EditAnswerComment TidbitPointer.Bigbit commentID)


{-| Creates the code editor for the bigbit when browsing relevant HC.

This will only create the editor if the state of the model (the `Maybe`s) makes it appropriate to render the editor.

-}
createViewBigbitHCCodeEditor : Maybe Bigbit.Bigbit -> Maybe ViewingBigbitRelevantHC -> Maybe User.User -> Cmd msg
createViewBigbitHCCodeEditor maybeBigbit maybeRHC user =
    case ( maybeBigbit, maybeRHC ) of
        ( Just bigbit, Just { currentHC, relevantHC } ) ->
            let
                editorWithRange range language code =
                    bigbitEditor "" (Just language) user code (Just range) { useMarker = True, selectAllowed = False }
            in
            case currentHC of
                Nothing ->
                    Cmd.none

                Just index ->
                    Array.get index relevantHC
                        |> maybeMapWithDefault
                            (Tuple.second
                                >> (\{ range, file } ->
                                        FS.getFile bigbit.fs file
                                            |> maybeMapWithDefault
                                                (\(FS.File content metadata) ->
                                                    editorWithRange
                                                        range
                                                        metadata.language
                                                        content
                                                )
                                                Cmd.none
                                   )
                            )
                            Cmd.none

        _ ->
            Cmd.none


{-| Based on the maybePath and the bigbit creates the editor.

Will handle redirects if file path is invalid or frameNumber is invalid.

-}
createViewBigbitCodeEditor : Bigbit.Bigbit -> Shared -> Cmd msg
createViewBigbitCodeEditor bigbit { route, user } =
    let
        loadFileWithNoHighlight fromStoryID maybePath =
            case maybePath of
                Nothing ->
                    blankEditor user

                Just somePath ->
                    case FS.getFile bigbit.fs somePath of
                        Nothing ->
                            Route.modifyTo <| Route.ViewBigbitFramePage fromStoryID bigbit.id 1 Nothing

                        Just (FS.File content { language }) ->
                            bigbitEditor
                                somePath
                                (Just language)
                                user
                                content
                                Nothing
                                { useMarker = True, selectAllowed = True }
    in
    Cmd.batch
        [ case route of
            Route.ViewBigbitFramePage fromStoryID _ frameNumber maybePath ->
                case Array.get (frameNumber - 1) bigbit.highlightedComments of
                    Nothing ->
                        Route.modifyTo <|
                            Route.ViewBigbitFramePage
                                fromStoryID
                                bigbit.id
                                (if frameNumber > Array.length bigbit.highlightedComments then
                                    Array.length bigbit.highlightedComments
                                 else
                                    1
                                )
                                Nothing

                    Just hc ->
                        case maybePath of
                            Nothing ->
                                case FS.getFile bigbit.fs hc.file of
                                    -- Should never happen, comments should always be pointing to valid files.
                                    Nothing ->
                                        Cmd.none

                                    Just (FS.File content { language }) ->
                                        bigbitEditor
                                            hc.file
                                            (Just language)
                                            user
                                            content
                                            (Just hc.range)
                                            { useMarker = True, selectAllowed = True }

                            Just absolutePath ->
                                loadFileWithNoHighlight fromStoryID maybePath

            _ ->
                Cmd.none
        , Ports.smoothScrollToBottom
        ]


{-| Creates the code editor for routes which require both the bigbit and the QA.

Will handle redirects if required (for example the content doesn't exist or if the user tries editing content that isn't
theirs). Will redirect to the appropriate route based on the bookmark (same as resuming the tutorial).

-}
createViewBigbitQACodeEditor :
    ( Bigbit.Bigbit, QA.BigbitQA, QA.BigbitQAState )
    -> Int
    -> Shared
    -> Cmd msg
createViewBigbitQACodeEditor ( bigbit, qa, qaState ) bookmark { user, route } =
    let
        redirectToTutorial maybeStoryID =
            Route.modifyTo <| routeForBookmark maybeStoryID bigbit.id bookmark

        -- Will attempt to get the question based on the questionID (redirecting if the questionID doesn't point to a
        -- a question) and then will `createEditorForQuestion`.
        createEditorForQuestionID maybeStoryID questionID { useMarker, selectAllowed } =
            qa.questions
                |> QA.getQuestion questionID
                ||> createEditorForQuestion maybeStoryID { useMarker = useMarker, selectAllowed = selectAllowed }
                ?> redirectToTutorial maybeStoryID

        -- Will attempt to get the question based on the answerID (redirecting if the answerID isn't valid or if the
        -- answer doesn't point to a valid question) and then will `createEditorForQuestion`.
        createEditorForAnswerID maybeStoryID answerID { useMarker, selectAllowed } =
            qa
                |> QA.getQuestionByAnswerID answerID
                ||> createEditorForQuestion maybeStoryID { useMarker = useMarker, selectAllowed = selectAllowed }
                ?> redirectToTutorial maybeStoryID

        -- Will get the filePath/fileContent/range/language for the given question and create the editor, if unable
        -- to then it will `redirectToTutorial` (eg. if question points to a non-existant file, shouldn't happen).
        createEditorForQuestion maybeStoryID { useMarker, selectAllowed } question =
            question.codePointer
                |> (\{ file, range } ->
                        FS.getFile bigbit.fs file
                            ||> (\(FS.File content { language }) ->
                                    bigbitEditor
                                        file
                                        (Just language)
                                        user
                                        content
                                        (Just range)
                                        { useMarker = useMarker, selectAllowed = selectAllowed }
                                )
                            ?> redirectToTutorial maybeStoryID
                   )

        -- Handles creating the correct editor based on the current route.
        createEditorForRoute =
            case route of
                Route.ViewBigbitQuestionsPage maybeStoryID bigbitID ->
                    qaState
                        |> QA.getBrowseCodePointer bigbitID
                        ||> (\{ file, range } ->
                                FS.getFile bigbit.fs file
                                    ||> (\(FS.File content { language }) ->
                                            bigbitEditor
                                                file
                                                (Just language)
                                                user
                                                content
                                                (Just range)
                                                { useMarker = False, selectAllowed = True }
                                        )
                                    ?> redirectToTutorial maybeStoryID
                            )
                        ?> blankEditor user

                Route.ViewBigbitQuestionPage maybeStoryID _ _ questionID ->
                    createEditorForQuestionID maybeStoryID questionID { useMarker = True, selectAllowed = False }

                Route.ViewBigbitAnswersPage maybeStoryID _ _ questionID ->
                    createEditorForQuestionID maybeStoryID questionID { useMarker = True, selectAllowed = False }

                Route.ViewBigbitAnswerPage maybeStoryID _ _ answerID ->
                    createEditorForAnswerID maybeStoryID answerID { useMarker = True, selectAllowed = False }

                Route.ViewBigbitQuestionCommentsPage maybeStoryID _ _ questionID _ ->
                    createEditorForQuestionID maybeStoryID questionID { useMarker = True, selectAllowed = False }

                Route.ViewBigbitAnswerCommentsPage maybeStoryID _ _ answerID _ ->
                    createEditorForAnswerID maybeStoryID answerID { useMarker = True, selectAllowed = False }

                Route.ViewBigbitAskQuestion maybeStoryID bigbitID ->
                    qaState
                        |> QA.getNewQuestion bigbitID
                        |||> .codePointer
                        ||> (\{ file, range } ->
                                FS.getFile bigbit.fs file
                                    ||> (\(FS.File content { language }) ->
                                            bigbitEditor
                                                file
                                                (Just language)
                                                user
                                                content
                                                (Just range)
                                                { useMarker = False, selectAllowed = True }
                                        )
                                    ?> redirectToTutorial maybeStoryID
                            )
                        ?> blankEditor user

                Route.ViewBigbitEditQuestion maybeStoryID bigbitID questionID ->
                    let
                        isAuthor =
                            user
                                ||> .id
                                ||> (\userID ->
                                        QA.getQuestion questionID qa.questions
                                            ||> .authorID
                                            ||> (==) userID
                                            ?> False
                                    )
                                ?> False
                    in
                    if isAuthor then
                        qaState
                            |> QA.getQuestionEdit bigbitID questionID
                            ||> (.codePointer >> Editable.getBuffer)
                            ||> (\{ file, range } ->
                                    FS.getFile bigbit.fs file
                                        ||> (\(FS.File content { language }) ->
                                                bigbitEditor
                                                    file
                                                    (Just language)
                                                    user
                                                    content
                                                    (Just range)
                                                    { useMarker = False, selectAllowed = True }
                                            )
                                        ?> redirectToTutorial maybeStoryID
                                )
                            ?> createEditorForQuestionID
                                maybeStoryID
                                questionID
                                { useMarker = False, selectAllowed = True }
                    else
                        redirectToTutorial maybeStoryID

                Route.ViewBigbitAnswerQuestion maybeStoryID _ questionID ->
                    createEditorForQuestionID maybeStoryID questionID { useMarker = True, selectAllowed = False }

                Route.ViewBigbitEditAnswer maybeStoryID _ answerID ->
                    let
                        isAuthor =
                            QA.getAnswer answerID qa.answers
                                |||> (\{ authorID } -> user ||> .id ||> (==) authorID)
                                ?> False
                    in
                    if isAuthor then
                        createEditorForAnswerID maybeStoryID answerID { useMarker = True, selectAllowed = False }
                    else
                        redirectToTutorial maybeStoryID

                _ ->
                    Cmd.none
    in
    Cmd.batch
        [ createEditorForRoute
        , Ports.smoothScrollToBottom
        ]


{-| Wrapper for creating a blank editor.
-}
blankEditor : Maybe User.User -> Cmd msg
blankEditor user =
    bigbitEditor "" Nothing user "" Nothing { useMarker = False, selectAllowed = False }


{-| Wrapper around the port for creating an editor with the view-bigbit-settings pre-filled.
-}
bigbitEditor :
    FS.Path
    -> Maybe Editor.Language
    -> Maybe User.User
    -> FS.Content
    -> Maybe Range.Range
    -> { useMarker : Bool, selectAllowed : Bool }
    -> Cmd msg
bigbitEditor filePath maybeLanguage maybeUser content maybeRange { useMarker, selectAllowed } =
    Ports.createCodeEditor
        { id = "view-bigbit-code-editor"
        , fileID = FS.uniqueFilePath filePath
        , lang = Util.maybeMapWithDefault Editor.aceLanguageLocation "" maybeLanguage
        , theme = User.getTheme maybeUser
        , value = content
        , range = maybeRange
        , useMarker = useMarker
        , readOnly = True
        , selectAllowed = selectAllowed
        }
