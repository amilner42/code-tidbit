module Pages.ViewSnipbit.Update exposing (..)

import Array
import DefaultServices.CommonSubPageUtil exposing (CommonSubPageUtil, commonSubPageUtil)
import DefaultServices.Util as Util exposing (maybeMapWithDefault)
import Elements.Editor as Editor
import Models.Completed as Completed
import Models.ContentPointer as ContentPointer
import Models.Opinion as Opinion
import Models.Range as Range
import Models.Route as Route
import Models.Snipbit as Snipbit
import Models.TidbitPointer as TidbitPointer
import Models.User as User
import Models.ViewerRelevantHC as ViewerRelevantHC
import Pages.Model exposing (Shared)
import Pages.ViewSnipbit.Messages exposing (Msg(..))
import Pages.ViewSnipbit.Model exposing (..)
import Ports


{-| `ViewSnipbit` update.
-}
update : CommonSubPageUtil Model Shared Msg -> Msg -> Model -> Shared -> ( Model, Shared, Cmd Msg )
update ({ doNothing, justSetModel, justUpdateModel, justSetShared, justProduceCmd, api } as common) msg model shared =
    case msg of
        NoOp ->
            doNothing

        GoTo route ->
            justProduceCmd <| Route.navigateTo route

        OnRouteHit route ->
            let
                {- Get's data for viewing snipbit as required:
                    - May need to fetch tidbit itself
                    - May need to fetch story
                    - May need to fetch if the tidbit is completed by the user.
                    - may need to fetch the users opinion on the tidbit.

                   If any of the 4 datums above are already cached, assumes that they are up-to-date. The snipbit itself
                   basically never changes, the `isCompleted` will change a lot but it's unlikely the user completes
                   that exact tidbit in another browser at the same time. The story itself changes frequently but it
                   doesn't make sense to constantly update it, so we only update the story when we are on the
                   `viewStory` page. The same reasoning for `isComplete` applies to `maybeOpinion`, it's unlikely to be
                   done in another browser at the same time, so we cache it in the browser, but not in localStorage.
                -}
                fetchOrRenderViewSnipbitData mongoID =
                    let
                        currentTidbitPointer =
                            TidbitPointer.TidbitPointer TidbitPointer.Snipbit mongoID

                        -- Handle getting snipbit if needed.
                        handleGetSnipbit ( model, shared ) =
                            let
                                getSnipbit mongoID =
                                    ( setViewingSnipbit Nothing model
                                    , shared
                                    , api.get.snipbit
                                        mongoID
                                        OnGetSnipbitFailure
                                        OnGetSnipbitSuccess
                                    )
                            in
                                case model.snipbit of
                                    Nothing ->
                                        getSnipbit mongoID

                                    Just snipbit ->
                                        if snipbit.id == mongoID then
                                            ( setViewingSnipbitRelevantHC Nothing model
                                            , shared
                                            , createViewSnipbitCodeEditor snipbit shared
                                            )
                                        else
                                            getSnipbit mongoID

                        -- Handle getting snipbit is-completed if needed.
                        handleGetSnipbitIsCompleted ( model, shared ) =
                            let
                                doNothing =
                                    ( model, shared, Cmd.none )

                                getSnipbitIsCompleted userID =
                                    ( setViewingSnipbitIsCompleted Nothing model
                                    , shared
                                    , api.post.checkCompletedWrapper
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
                                            doNothing
                                        else
                                            getSnipbitIsCompleted user.id

                                    _ ->
                                        doNothing

                        handleGetSnipbitOpinion ( model, shared ) =
                            let
                                { doNothing, justProduceCmd } =
                                    commonSubPageUtil model shared

                                contentPointer =
                                    { contentType = ContentPointer.Snipbit
                                    , contentID = mongoID
                                    }

                                getOpinion =
                                    ( { model | maybeOpinion = Nothing }
                                    , shared
                                    , api.get.opinionWrapper
                                        contentPointer
                                        OnGetOpinionFailure
                                        OnGetOpinionSuccess
                                    )
                            in
                                case ( shared.user, model.maybeOpinion ) of
                                    ( Just user, Just { contentPointer, rating } ) ->
                                        if contentPointer.contentID == mongoID then
                                            doNothing
                                        else
                                            getOpinion

                                    ( Just user, Nothing ) ->
                                        getOpinion

                                    _ ->
                                        doNothing

                        -- Handle getting story if viewing snipbit from story.
                        handleGetStoryForSnipbit ( model, shared ) =
                            let
                                doNothing =
                                    ( model, shared, Cmd.none )

                                maybeViewingStoryID =
                                    Maybe.map .id shared.viewingStory

                                getStory storyID =
                                    api.get.expandedStoryWithCompleted
                                        storyID
                                        OnGetExpandedStoryFailure
                                        OnGetExpandedStorySuccess
                            in
                                case Route.getFromStoryQueryParamOnViewSnipbitRoute shared.route of
                                    Just storyID ->
                                        if (Just storyID) == maybeViewingStoryID then
                                            doNothing
                                        else
                                            ( model
                                            , { shared | viewingStory = Nothing }
                                            , getStory storyID
                                            )

                                    _ ->
                                        ( model
                                        , { shared | viewingStory = Nothing }
                                        , Cmd.none
                                        )
                    in
                        common.handleAll
                            [ handleGetSnipbit
                            , handleGetSnipbitIsCompleted
                            , handleGetSnipbitOpinion
                            , handleGetStoryForSnipbit
                            ]
            in
                case route of
                    Route.ViewSnipbitIntroductionPage _ mongoID ->
                        fetchOrRenderViewSnipbitData mongoID

                    Route.ViewSnipbitFramePage _ mongoID _ ->
                        fetchOrRenderViewSnipbitData mongoID

                    Route.ViewSnipbitConclusionPage _ mongoID ->
                        fetchOrRenderViewSnipbitData mongoID
                            |> common.withCmd
                                (case ( shared.user, model.isCompleted ) of
                                    ( Just user, Just isCompleted ) ->
                                        let
                                            completed =
                                                Completed.completedFromIsCompleted
                                                    isCompleted
                                                    user.id
                                        in
                                            if isCompleted.complete == False then
                                                api.post.addCompletedWrapper
                                                    completed
                                                    OnMarkAsCompleteFailure
                                                    OnMarkAsCompleteSuccess
                                            else
                                                Cmd.none

                                    _ ->
                                        Cmd.none
                                )

                    _ ->
                        doNothing

        OnGetCompletedSuccess isCompleted ->
            justUpdateModel <| setViewingSnipbitIsCompleted <| Just isCompleted

        OnGetCompletedFailure apiError ->
            common.justSetModalError apiError

        OnGetSnipbitSuccess snipbit ->
            ( Util.multipleUpdates
                [ setViewingSnipbit <| Just snipbit
                , setViewingSnipbitRelevantHC Nothing
                ]
                model
            , shared
            , createViewSnipbitCodeEditor snipbit shared
            )

        OnGetSnipbitFailure apiError ->
            common.justSetModalError apiError

        OnGetOpinionSuccess maybeOpinion ->
            justSetModel { model | maybeOpinion = Just maybeOpinion }

        OnGetOpinionFailure apiError ->
            common.justSetModalError apiError

        AddOpinion opinion ->
            justProduceCmd <|
                api.post.addOpinionWrapper opinion OnAddOpinionFailure OnAddOpinionSuccess

        OnAddOpinionSuccess opinion ->
            justSetModel { model | maybeOpinion = Just (Opinion.toMaybeOpinion opinion) }

        OnAddOpinionFailure apiError ->
            common.justSetModalError apiError

        RemoveOpinion opinion ->
            justProduceCmd <|
                api.post.removeOpinionWrapper opinion OnRemoveOpinionFailure OnRemoveOpinionSuccess

        {- Currently it doesn't matter what opinion we removed because you can only have 1, but it may change in the
           future where we have multiple opinions, then use the `opinion` to figure out which to remove.
        -}
        OnRemoveOpinionSuccess { contentPointer, rating } ->
            justSetModel
                { model
                    | maybeOpinion = Just { contentPointer = contentPointer, rating = Nothing }
                }

        OnRemoveOpinionFailure apiError ->
            common.justSetModalError apiError

        OnGetExpandedStorySuccess expandedStory ->
            justSetShared { shared | viewingStory = Just expandedStory }

        OnGetExpandedStoryFailure apiError ->
            common.justSetModalError apiError

        OnRangeSelected selectedRange ->
            case model.snipbit of
                Nothing ->
                    doNothing

                Just aSnipbit ->
                    if Range.isEmptyRange selectedRange then
                        justUpdateModel <| setViewingSnipbitRelevantHC Nothing
                    else
                        aSnipbit.highlightedComments
                            |> Array.indexedMap (,)
                            |> Array.filter
                                (Tuple.second
                                    >> .range
                                    >> (Range.overlappingRanges selectedRange)
                                )
                            |> (\relevantHC ->
                                    justUpdateModel <|
                                        setViewingSnipbitRelevantHC <|
                                            Just
                                                { currentHC = Nothing
                                                , relevantHC = relevantHC
                                                }
                               )

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
            ( setViewingSnipbitRelevantHC Nothing model
            , shared
              -- Trigger route hook again, `modify` because we don't want to have the same page twice in history.
            , Route.modifyTo shared.route
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

        JumpToFrame route ->
            ( setViewingSnipbitRelevantHC Nothing model
            , shared
            , Route.navigateTo route
            )

        MarkAsComplete completed ->
            justProduceCmd <| api.post.addCompletedWrapper completed OnMarkAsCompleteFailure OnMarkAsCompleteSuccess

        OnMarkAsCompleteSuccess isCompleted ->
            justUpdateModel <| setViewingSnipbitIsCompleted <| Just isCompleted

        OnMarkAsCompleteFailure apiError ->
            common.justSetModalError apiError

        MarkAsIncomplete completed ->
            justProduceCmd <|
                api.post.removeCompletedWrapper completed OnMarkAsIncompleteFailure OnMarkAsIncompleteSuccess

        OnMarkAsIncompleteSuccess isCompleted ->
            justUpdateModel <| setViewingSnipbitIsCompleted <| Just isCompleted

        OnMarkAsIncompleteFailure apiError ->
            common.justSetModalError apiError


{-| Creates the editor for the snipbit.

Will handle redirects if bad path and highlighting code.
-}
createViewSnipbitCodeEditor : Snipbit.Snipbit -> Shared -> Cmd msg
createViewSnipbitCodeEditor snipbit { route, user } =
    let
        editorWithRange range =
            Ports.createCodeEditor
                { id = "view-snipbit-code-editor"
                , fileID = ""
                , lang = Editor.aceLanguageLocation snipbit.language
                , theme = User.getTheme user
                , value = snipbit.code
                , range = range
                , readOnly = True
                , selectAllowed = True
                }
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


{-| Creates the code editor for the snipbit when browsing the relevant HC.

This will only create the editor if the state of the model (the `Maybe`s) makes it appropriate to render the editor.
-}
createViewSnipbitHCCodeEditor : Maybe Snipbit.Snipbit -> Maybe ViewingSnipbitRelevantHC -> Maybe User.User -> Cmd msg
createViewSnipbitHCCodeEditor maybeSnipbit maybeRHC user =
    case ( maybeSnipbit, maybeRHC ) of
        ( Just snipbit, Just { currentHC, relevantHC } ) ->
            let
                editorWithRange range =
                    Ports.createCodeEditor
                        { id = "view-snipbit-code-editor"
                        , fileID = ""
                        , lang = Editor.aceLanguageLocation snipbit.language
                        , theme = User.getTheme user
                        , value = snipbit.code
                        , range = Just range
                        , readOnly = True
                        , selectAllowed = False
                        }
            in
                case currentHC of
                    Nothing ->
                        Cmd.none

                    Just index ->
                        Array.get index relevantHC
                            |> maybeMapWithDefault
                                (editorWithRange << .range << Tuple.second)
                                Cmd.none

        _ ->
            Cmd.none
