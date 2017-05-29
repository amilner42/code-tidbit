module Pages.ViewBigbit.Update exposing (..)

import Array
import DefaultServices.CommonSubPageUtil exposing (CommonSubPageUtil(..), commonSubPageUtil)
import DefaultServices.Editable as Editable
import DefaultServices.InfixFunctions exposing (..)
import DefaultServices.Util as Util exposing (maybeMapWithDefault)
import Elements.Complex.AnswerQuestion as AnswerQuestion
import Elements.Complex.AskQuestion as AskQuestion
import Elements.Complex.EditQuestion as EditQuestion
import Elements.Simple.Editor as Editor
import Elements.Simple.FileStructure as FS
import Models.Bigbit as Bigbit
import Models.Completed as Completed
import Models.ContentPointer as ContentPointer
import Models.Opinion as Opinion
import Models.QA as QA
import Models.Range as Range
import Models.Route as Route
import Models.TidbitPointer as TidbitPointer
import Models.TutorialBookmark as TB
import Models.User as User
import Models.ViewerRelevantHC as ViewerRelevantHC
import Pages.Model exposing (Shared)
import Pages.ViewBigbit.Messages exposing (..)
import Pages.ViewBigbit.Model exposing (..)
import Ports


{-| `ViewBigbit` update.
-}
update : CommonSubPageUtil Model Shared Msg -> Msg -> Model -> Shared -> ( Model, Shared, Cmd Msg )
update (Common common) msg model shared =
    case msg of
        NoOp ->
            common.doNothing

        GoTo route ->
            ( model, shared, Route.navigateTo route )

        GoToAskQuestionWithCodePointer bigbitID maybeCodePointer ->
            ( { model
                | qaState =
                    model.qaState
                        |> QA.updateNewQuestion
                            bigbitID
                            (always
                                { questionText = ""
                                , codePointer = maybeCodePointer
                                , previewMarkdown = False
                                }
                            )
              }
            , shared
            , Route.navigateTo <|
                Route.ViewBigbitAskQuestion
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

                setBookmark tb (Common common) ( model, shared ) =
                    common.justSetModel
                        { model | bookmark = tb }

                {- Get's data for viewing bigbit as required:
                   - May need to fetch tidbit itself                                    [Cache level: localStorage]
                   - May need to fetch story                                            [Cache level: browserModel]
                   - May need to fetch if the tidbit is completed by the user.          [Cache level: browserModel]
                   - May need to fetch the users opinion on the tidbit.                 [Cache level: browserModel]
                   - May need to fetch QA                                               [Cache level: browserModel]

                    Depending on `requireLoadingQAPreRender`, it will either wait for both the bigbit and the QA to load
                    and then render the editor or it will render the editor just after the bigbit is loaded.
                -}
                fetchOrRenderViewBigbitData requireLoadingQAPreRender mongoID (Common common) ( model, shared ) =
                    let
                        currentTidbitPointer =
                            TidbitPointer.TidbitPointer TidbitPointer.Bigbit mongoID

                        -- Handle getting bigbit if needed.
                        handleGetBigbit (Common common) ( model, shared ) =
                            let
                                getBigbit mongoID =
                                    ( setBigbit Nothing model
                                    , shared
                                    , common.api.get.bigbit mongoID
                                        OnGetBigbitFailure
                                        (OnGetBigbitSuccess requireLoadingQAPreRender)
                                    )
                            in
                                case model.bigbit of
                                    Nothing ->
                                        getBigbit mongoID

                                    Just bigbit ->
                                        if bigbit.id == mongoID then
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
                                            getBigbit mongoID

                        -- Handle getting bigbit is-completed if needed.
                        handleGetBigbitIsCompleted (Common common) ( model, shared ) =
                            let
                                -- Command for fetching the `isCompleted`
                                getBigbitIsCompleted userID =
                                    ( setIsCompleted Nothing model
                                    , shared
                                    , common.api.post.checkCompleted
                                        (Completed.Completed currentTidbitPointer userID)
                                        OnGetCompletedFailure
                                        (OnGetCompletedSuccess << Completed.IsCompleted currentTidbitPointer)
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

                        handleGetStoryForBigbit (Common common) ( model, shared ) =
                            let
                                maybeViewingStoryID =
                                    Maybe.map .id shared.viewingStory

                                getStory storyID =
                                    common.api.get.expandedStoryWithCompleted
                                        storyID
                                        OnGetExpandedStoryFailure
                                        OnGetExpandedStorySuccess
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
                                    , common.api.get.bigbitQA
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
                    Route.ViewBigbitIntroductionPage _ mongoID _ ->
                        common.handleAll
                            [ clearStateOnRouteHit
                            , setBookmark TB.Introduction
                            , fetchOrRenderViewBigbitData False mongoID
                            ]

                    Route.ViewBigbitFramePage _ mongoID frameNumber _ ->
                        common.handleAll
                            [ clearStateOnRouteHit
                            , setBookmark <| TB.FrameNumber frameNumber
                            , fetchOrRenderViewBigbitData False mongoID
                            ]

                    Route.ViewBigbitConclusionPage _ mongoID _ ->
                        common.handleAll
                            [ clearStateOnRouteHit
                            , setBookmark TB.Conclusion
                            , fetchOrRenderViewBigbitData False mongoID

                            -- Setting completed if not already complete.
                            , (\(Common common) ( model, shared ) ->
                                common.justProduceCmd <|
                                    case ( shared.user, model.isCompleted ) of
                                        ( Just user, Just isCompleted ) ->
                                            let
                                                completed =
                                                    Completed.completedFromIsCompleted isCompleted user.id
                                            in
                                                if isCompleted.complete == False then
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
                              )
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
                            ]

                    Route.ViewBigbitQuestionCommentsPage _ _ bigbitID _ _ ->
                        common.handleAll
                            [ clearStateOnRouteHit
                            , fetchOrRenderViewBigbitData True bigbitID
                            ]

                    Route.ViewBigbitAnswerCommentsPage _ _ bigbitID _ _ ->
                        common.handleAll
                            [ clearStateOnRouteHit
                            , fetchOrRenderViewBigbitData True bigbitID
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
                currentActiveFile =
                    model.bigbit
                        |||>
                            (\bigbit ->
                                Route.viewBigbitPageCurrentActiveFile shared.route bigbit model.qa model.qaState
                            )

                handleSetTutorialCodePointer (Common common) ( model, shared ) =
                    case currentActiveFile of
                        Nothing ->
                            common.doNothing

                        Just file ->
                            common.justSetModel
                                { model | tutorialCodePointer = Just { file = file, range = selectedRange } }

                handleFindRelevantFrames (Common common) ( model, shared ) =
                    case model.bigbit of
                        Nothing ->
                            common.doNothing

                        Just aBigbit ->
                            if Range.isEmptyRange selectedRange then
                                common.justUpdateModel <| setRelevantHC Nothing
                            else
                                aBigbit.highlightedComments
                                    |> Array.indexedMap (,)
                                    |> Array.filter
                                        (\hc ->
                                            (Tuple.second hc |> .range |> Range.overlappingRanges selectedRange)
                                                && (Tuple.second hc
                                                        |> .file
                                                        |> Just
                                                        |> (==) currentActiveFile
                                                   )
                                        )
                                    |> (\relevantHC ->
                                            common.justUpdateModel <|
                                                setRelevantHC <|
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
                                    |> List.filter
                                        (\{ codePointer } ->
                                            (Range.overlappingRanges codePointer.range selectedRange)
                                                && (Util.maybeMapWithDefault
                                                        (FS.isSameFilePath codePointer.file)
                                                        False
                                                        currentActiveFile
                                                   )
                                        )
                                    |> (\relevantQuestions ->
                                            common.justSetModel
                                                { model
                                                    | relevantQuestions = Just relevantQuestions
                                                }
                                       )
            in
                case shared.route of
                    Route.ViewBigbitIntroductionPage _ _ _ ->
                        common.handleAll
                            [ handleSetTutorialCodePointer
                            , handleFindRelevantFrames
                            , handleFindRelevantQuestions
                            ]

                    Route.ViewBigbitFramePage _ _ _ _ ->
                        common.handleAll
                            [ handleSetTutorialCodePointer
                            , handleFindRelevantFrames
                            , handleFindRelevantQuestions
                            ]

                    Route.ViewBigbitConclusionPage _ _ _ ->
                        common.handleAll
                            [ handleSetTutorialCodePointer
                            , handleFindRelevantFrames
                            , handleFindRelevantQuestions
                            ]

                    Route.ViewBigbitQuestionsPage _ bigbitID ->
                        case QA.getBrowseCodePointer bigbitID model.qaState of
                            -- No active file.
                            Nothing ->
                                common.doNothing

                            Just codePointer ->
                                common.justSetModel
                                    { model
                                        | qaState =
                                            QA.setBrowsingCodePointer
                                                bigbitID
                                                (Just { codePointer | range = selectedRange })
                                                model.qaState
                                    }

                    Route.ViewBigbitAskQuestion _ bigbitID ->
                        case QA.getNewQuestion bigbitID model.qaState |||> .codePointer of
                            -- No active file.
                            Nothing ->
                                common.doNothing

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

                    Route.ViewBigbitEditQuestion _ bigbitID questionID ->
                        case model.qa ||> .questions |||> QA.getQuestionByID questionID of
                            Just { questionText, codePointer } ->
                                common.justSetModel
                                    { model
                                        | qaState =
                                            QA.updateQuestionEdit
                                                bigbitID
                                                questionID
                                                (\maybeQuestionEdit ->
                                                    Just <|
                                                        case maybeQuestionEdit of
                                                            Nothing ->
                                                                { questionText = Editable.newEditing questionText
                                                                , codePointer =
                                                                    Editable.newEditing
                                                                        { codePointer | range = selectedRange }
                                                                , previewMarkdown = False
                                                                }

                                                            Just questionEdit ->
                                                                { questionEdit
                                                                    | codePointer =
                                                                        Editable.updateBuffer
                                                                            questionEdit.codePointer
                                                                            (\codePointer ->
                                                                                { codePointer | range = selectedRange }
                                                                            )
                                                                }
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
                    Route.ViewBigbitIntroductionPage _ _ _ ->
                        handleFileSelectOnTutorialRoute

                    Route.ViewBigbitFramePage _ _ _ _ ->
                        handleFileSelectOnTutorialRoute

                    Route.ViewBigbitConclusionPage _ _ _ ->
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
                        case model.qa ||> .questions |||> QA.getQuestionByID questionID of
                            Just { questionText } ->
                                ( { model
                                    | qaState =
                                        QA.updateQuestionEdit
                                            bigbitID
                                            questionID
                                            (\maybeQuestionEdit ->
                                                case maybeQuestionEdit of
                                                    Nothing ->
                                                        Just
                                                            { questionText = Editable.newEditing questionText
                                                            , codePointer =
                                                                Editable.newEditing
                                                                    { file = absolutePath
                                                                    , range = Range.zeroRange
                                                                    }
                                                            , previewMarkdown = False
                                                            }

                                                    Just questionEdit ->
                                                        Just
                                                            { questionEdit
                                                                | codePointer =
                                                                    Editable.setBuffer
                                                                        questionEdit.codePointer
                                                                        { file = absolutePath
                                                                        , range = Range.zeroRange
                                                                        }
                                                            }
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
                    (\currentViewingBigbit ->
                        { currentViewingBigbit
                            | fs =
                                Bigbit.toggleFSFolder absolutePath currentViewingBigbit.fs
                        }
                    )

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

        CancelBrowseRelevantHC ->
            ( setRelevantHC Nothing model
            , shared
              -- Trigger route hook again, `modify` because we don't want to have the same page twice in history.
            , Route.modifyTo shared.route
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

        JumpToFrame route ->
            ( setRelevantHC Nothing model
            , shared
            , Route.navigateTo route
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
                    QA.getNewQuestion bigbitID model.qaState ?> QA.defaultNewQuestion

                ( newAskQuestionModel, newAskQuestionMsg ) =
                    AskQuestion.update askQuestionMsg askQuestionModel
            in
                ( { model | qaState = model.qaState |> QA.updateNewQuestion bigbitID (always newAskQuestionModel) }
                , shared
                , Cmd.map (AskQuestionMsg bigbitID) newAskQuestionMsg
                )

        AskQuestion bigbitID codePointer questionText ->
            common.justProduceCmd <|
                common.api.post.askQuestionOnBigbit
                    bigbitID
                    questionText
                    codePointer
                    OnAskQuestionFailure
                    (OnAskQuestionSuccess bigbitID)

        OnAskQuestionSuccess bigbitID question ->
            case model.qa of
                Just qa ->
                    ( { model
                        | qa = Just { qa | questions = QA.sortRateableContent <| question :: qa.questions }
                        , qaState =
                            QA.updateNewQuestion
                                bigbitID
                                (always QA.defaultNewQuestion)
                                model.qaState
                      }
                    , shared
                    , Route.navigateTo <|
                        Route.ViewBigbitQuestionPage
                            (Route.getFromStoryQueryParamOnViewBigbitRoute shared.route)
                            (Route.getTouringQuestionsQueryParamOnViewBigbitQARoute shared.route)
                            bigbitID
                            question.id
                    )

                Nothing ->
                    common.doNothing

        OnAskQuestionFailure apiError ->
            common.justSetModalError apiError

        EditQuestionMsg bigbitID question editQuestionMsg ->
            let
                editQuestionModel =
                    QA.getQuestionEditByID bigbitID question.id model.qaState
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
                , Cmd.map (EditQuestionMsg bigbitID question) newQuestionEditMsg
                )

        EditQuestion bigbitID questionID questionText codePointer ->
            common.justProduceCmd <|
                common.api.post.editQuestionOnBigbit
                    bigbitID
                    questionID
                    questionText
                    codePointer
                    OnEditQuestionFailure
                    (OnEditQuestionSuccess bigbitID questionID questionText codePointer)

        OnEditQuestionSuccess bigbitID questionID questionText codePointer date ->
            case model.qa of
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
                                            , lastModified = date
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

        OnEditQuestionFailure apiError ->
            common.justSetModalError apiError

        AnswerQuestionMsg bigbitID question answerQuestionMsg ->
            let
                answerQuestionModel =
                    { forQuestion = question
                    , newAnswer =
                        QA.getNewAnswer bigbitID question.id model.qaState
                            ?> QA.defaultNewAnswer
                    }

                ( newAnswerQuestionModel, newAnswerQuestionMsg ) =
                    AnswerQuestion.update answerQuestionMsg answerQuestionModel
            in
                ( { model
                    | qaState =
                        model.qaState
                            |> QA.updateNewAnswer
                                bigbitID
                                question.id
                                (always <| Just <| newAnswerQuestionModel.newAnswer)
                  }
                , shared
                , Cmd.map (AnswerQuestionMsg bigbitID question) newAnswerQuestionMsg
                )

        AnswerQuestion bigbitID questionID answerText ->
            common.justProduceCmd <|
                common.api.post.answerQuestion
                    { tidbitType = TidbitPointer.Bigbit, targetID = bigbitID }
                    questionID
                    answerText
                    OnAnswerQuestionFailure
                    (OnAnswerQuestionSuccess bigbitID questionID)

        OnAnswerQuestionSuccess bigbitID questionID answer ->
            case model.qa of
                Just qa ->
                    ( { model
                        | qa = Just { qa | answers = QA.sortRateableContent <| answer :: qa.answers }
                        , qaState = model.qaState |> QA.updateNewAnswer bigbitID questionID (always Nothing)
                      }
                    , shared
                    , Route.navigateTo <|
                        Route.ViewBigbitAnswerPage
                            (Route.getFromStoryQueryParamOnViewBigbitRoute shared.route)
                            (Route.getTouringQuestionsQueryParamOnViewBigbitQARoute shared.route)
                            bigbitID
                            answer.id
                    )

                Nothing ->
                    common.doNothing

        OnAnswerQuestionFailure apiError ->
            common.justSetModalError apiError


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
                            Route.modifyTo <| Route.ViewBigbitIntroductionPage fromStoryID bigbit.id Nothing

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
                Route.ViewBigbitIntroductionPage fromStoryID mongoID maybePath ->
                    loadFileWithNoHighlight fromStoryID maybePath

                Route.ViewBigbitFramePage fromStoryID mongoID frameNumber maybePath ->
                    case Array.get (frameNumber - 1) bigbit.highlightedComments of
                        Nothing ->
                            if frameNumber > (Array.length bigbit.highlightedComments) then
                                Route.modifyTo <| Route.ViewBigbitConclusionPage fromStoryID bigbit.id Nothing
                            else
                                Route.modifyTo <| Route.ViewBigbitIntroductionPage fromStoryID bigbit.id Nothing

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

                Route.ViewBigbitConclusionPage fromStoryID mongoID maybePath ->
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
    -> TB.TutorialBookmark
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
                |> QA.getQuestionByID questionID
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
                    qaState
                        |> QA.getQuestionEditByID bigbitID questionID
                        ||> (.codePointer >> Editable.getBuffer)
                        ||> (\{ file, range } ->
                                let
                                    isAuthor =
                                        user
                                            ||> .id
                                            ||> (\userID ->
                                                    QA.getQuestionByID questionID qa.questions
                                                        ||> .authorID
                                                        ||> (==) userID
                                                        ?> False
                                                )
                                            ?> False
                                in
                                    if isAuthor then
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
                                    else
                                        redirectToTutorial maybeStoryID
                            )
                        ?> createEditorForQuestionID maybeStoryID questionID { useMarker = False, selectAllowed = True }

                Route.ViewBigbitAnswerQuestion maybeStoryID _ questionID ->
                    createEditorForQuestionID maybeStoryID questionID { useMarker = True, selectAllowed = False }

                Route.ViewBigbitEditAnswer maybeStoryID _ answerID ->
                    if
                        QA.getAnswerByID answerID qa.answers
                            |||> (\{ authorID } -> user ||> .id ||> (==) authorID)
                            ?> False
                    then
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
