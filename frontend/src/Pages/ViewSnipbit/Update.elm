module Pages.ViewSnipbit.Update exposing (..)

import Array
import DefaultServices.Editable as Editable
import DefaultServices.CommonSubPageUtil exposing (CommonSubPageUtil(..), commonSubPageUtil)
import DefaultServices.Util as Util exposing (maybeMapWithDefault)
import Dict
import Elements.Editor as Editor
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
                            , tutorialHighlight = Nothing
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
                                    , common.api.post.checkCompletedWrapper
                                        (Completed.Completed currentTidbitPointer userID)
                                        OnGetCompletedFailure
                                        OnGetCompletedSuccess
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
                                    , common.api.get.opinionWrapper
                                        contentPointer
                                        OnGetOpinionFailure
                                        OnGetOpinionSuccess
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
                                                    common.api.post.addCompletedWrapper
                                                        completed
                                                        OnMarkAsCompleteFailure
                                                        OnMarkAsCompleteSuccess
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

                    Route.ViewSnipbitQuestionPage _ snipbitID _ _ ->
                        common.handleAll
                            [ clearStateOnRouteHit
                            , fetchOrRenderViewSnipbitData snipbitID True
                            ]

                    Route.ViewSnipbitQuestionFrame _ snipbitID _ _ ->
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
            ( { model | qa = Just qa, relevantQuestions = Nothing }
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
                common.api.post.addOpinionWrapper opinion OnAddOpinionFailure OnAddOpinionSuccess

        OnAddOpinionSuccess opinion ->
            common.justSetModel { model | possibleOpinion = Just (Opinion.toPossibleOpinion opinion) }

        OnAddOpinionFailure apiError ->
            common.justSetModalError apiError

        RemoveOpinion opinion ->
            common.justProduceCmd <|
                common.api.post.removeOpinionWrapper opinion OnRemoveOpinionFailure OnRemoveOpinionSuccess

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
                handleSetTutorialHighlight (Common common) ( model, shared ) =
                    common.justSetModel { model | tutorialHighlight = Just selectedRange }

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
                            [ handleSetTutorialHighlight
                            , handleFindRelevantFrames
                            , handleFindRelevantQuestions
                            ]

                    Route.ViewSnipbitFramePage _ _ _ ->
                        common.handleAll
                            [ handleSetTutorialHighlight
                            , handleFindRelevantFrames
                            , handleFindRelevantQuestions
                            ]

                    Route.ViewSnipbitConclusionPage _ _ ->
                        common.handleAll
                            [ handleSetTutorialHighlight
                            , handleFindRelevantFrames
                            , handleFindRelevantQuestions
                            ]

                    Route.ViewSnipbitQuestionsPage _ snipbitID ->
                        common.justSetModel
                            { model | qaState = QA.setBrowsingCodePointer snipbitID selectedRange model.qaState }

                    Route.ViewSnipbitAskQuestion _ snipbitID ->
                        common.justSetModel
                            { model | qaState = QA.setNewQuestionCodePointer snipbitID selectedRange model.qaState }

                    Route.ViewSnipbitEditQuestion _ snipbitID questionID ->
                        case Maybe.andThen (.questions >> QA.getQuestionByID questionID) model.qa of
                            Nothing ->
                                common.doNothing

                            Just question ->
                                common.justSetModel
                                    { model
                                        | qaState =
                                            QA.setEditQuestionCodePointer
                                                snipbitID
                                                questionID
                                                selectedRange
                                                question
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
        editorWithRange range =
            snipbitEditor snipbit user True True range

        redirectToTutorial maybeStoryID snipbitID =
            Route.modifyTo <| routeForBookmark maybeStoryID snipbitID bookmark
    in
        Cmd.batch
            [ case route of
                -- Highlight browsingCodePointer or Nothing.
                Route.ViewSnipbitQuestionsPage _ snipbitID ->
                    Dict.get snipbitID qaState
                        |> Maybe.andThen .browsingCodePointer
                        |> editorWithRange

                -- Highlight question codePointer.
                Route.ViewSnipbitQuestionPage maybeStoryID snipbitID questionID _ ->
                    case QA.getQuestionByID questionID qa.questions of
                        Nothing ->
                            redirectToTutorial maybeStoryID snipbitID

                        Just { codePointer } ->
                            editorWithRange <| Just codePointer

                -- Highlight question codePointer for given frameNumber.
                Route.ViewSnipbitQuestionFrame maybeStoryID snipbitID frameNumber _ ->
                    case Util.getAt qa.questions (frameNumber - 1) of
                        Nothing ->
                            redirectToTutorial maybeStoryID snipbitID

                        Just { codePointer } ->
                            editorWithRange <| Just codePointer

                -- Higlight newQuestion codePointer or Nothing.
                Route.ViewSnipbitAskQuestion maybeStoryID snipbitID ->
                    Dict.get snipbitID qaState
                        |> Maybe.map .newQuestion
                        |> Maybe.andThen .codePointer
                        |> editorWithRange

                -- Highlight question codePointer.
                Route.ViewSnipbitAnswerQuestion maybeStoryID snipbitID questionID ->
                    case QA.getQuestionByID questionID qa.questions of
                        Nothing ->
                            redirectToTutorial maybeStoryID snipbitID

                        Just { codePointer } ->
                            editorWithRange <| Just codePointer

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
                                                    editorWithRange (Just codePointer)

                                                Just { codePointer } ->
                                                    editorWithRange <| Just <| Editable.getBuffer codePointer
                                       )
                            else
                                redirectToTutorial maybeStoryID snipbitID

                -- Highlight question codePointer.
                Route.ViewSnipbitEditAnswer maybeStoryID snipbitID answerID ->
                    case QA.getQuestionByAnswerID snipbitID answerID qa of
                        Nothing ->
                            redirectToTutorial maybeStoryID snipbitID

                        Just { codePointer } ->
                            editorWithRange <| Just codePointer

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
                            (snipbitEditor snipbit user True False << Just << .range << Tuple.second)
                            Cmd.none

        _ ->
            Cmd.none


{-| Wrapper around the port for creating an editor with the view-snipbit-settings pre-filled.
-}
snipbitEditor : Snipbit.Snipbit -> Maybe User.User -> Bool -> Bool -> Maybe Range.Range -> Cmd msg
snipbitEditor snipbit user readOnly selectAllowed range =
    Ports.createCodeEditor
        { id = "view-snipbit-code-editor"
        , fileID = ""
        , lang = Editor.aceLanguageLocation snipbit.language
        , theme = User.getTheme user
        , value = snipbit.code
        , range = range
        , readOnly = readOnly
        , selectAllowed = selectAllowed
        }
