module Pages.ViewBigbit.Update exposing (..)

import Array
import DefaultServices.CommonSubPageUtil exposing (CommonSubPageUtil(..), commonSubPageUtil)
import DefaultServices.Util as Util exposing (maybeMapWithDefault)
import Elements.Editor as Editor
import Elements.FileStructure as FS
import Models.Bigbit as Bigbit
import Models.Completed as Completed
import Models.ContentPointer as ContentPointer
import Models.Opinion as Opinion
import Models.Range as Range
import Models.Route as Route
import Models.TidbitPointer as TidbitPointer
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

        OnRouteHit route ->
            let
                {- Get's data for viewing bigbit as required:
                   - May need to fetch tidbit itself
                   - May need to fetch story
                   - May need to fetch if the tidbit is completed by the user.
                   - may need to fetch the users opinion on the tidbit.

                   If any of the 4 datums above are already cached, assumes that they are up-to-date. The bigbit itself
                   basically never changes, the `isCompleted` will change a lot but it's unlikely the user completes
                   that exact tidbit in another browser at the same time. The story itself changes frequently but it
                   doesn't make sense to constantly update it, so we only update the story when we are on the
                   `viewStory` page. The same reasoning for `isComplete` applies to `possibleOpinion`, it's unlikely to be
                   done in another browser at the same time, so we cache it in the browser, but not in localStorage.
                -}
                fetchOrRenderViewBigbitData mongoID =
                    let
                        currentTidbitPointer =
                            TidbitPointer.TidbitPointer TidbitPointer.Bigbit mongoID

                        -- Handle getting bigbit if needed.
                        handleGetBigbit (Common common) ( model, shared ) =
                            let
                                getBigbit mongoID =
                                    ( setBigbit Nothing model
                                    , shared
                                    , common.api.get.bigbit mongoID OnGetBigbitFailure OnGetBigbitSuccess
                                    )
                            in
                                case model.bigbit of
                                    Nothing ->
                                        getBigbit mongoID

                                    Just bigbit ->
                                        if bigbit.id == mongoID then
                                            ( setRelevantHC Nothing model
                                            , shared
                                            , createViewBigbitCodeEditor bigbit shared
                                            )
                                        else
                                            getBigbit mongoID

                        -- Handle getting bigbit is-completed if needed.
                        handleGetBigbitIsCompleted (Common common) ( model, shared ) =
                            let
                                -- Command for fetching the `isCompleted`
                                getBigbitIsCompleted userID =
                                    ( setIsCompleted Nothing model
                                    , shared
                                    , common.api.post.checkCompletedWrapper
                                        (Completed.Completed currentTidbitPointer userID)
                                        OnGetCompletedFailure
                                        OnGetCompletedSuccess
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
                    in
                        common.handleAll
                            [ handleGetBigbit
                            , handleGetBigbitIsCompleted
                            , handleGetBigbitOpinion
                            , handleGetStoryForBigbit
                            ]
            in
                case route of
                    Route.ViewBigbitIntroductionPage _ mongoID _ ->
                        fetchOrRenderViewBigbitData mongoID

                    Route.ViewBigbitFramePage _ mongoID _ _ ->
                        fetchOrRenderViewBigbitData mongoID

                    Route.ViewBigbitConclusionPage _ mongoID _ ->
                        fetchOrRenderViewBigbitData mongoID
                            |> common.withCmd
                                (case ( shared.user, model.isCompleted ) of
                                    ( Just user, Just isCompleted ) ->
                                        let
                                            completed =
                                                Completed.completedFromIsCompleted isCompleted user.id
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

                    _ ->
                        common.doNothing

        OnRangeSelected selectedRange ->
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
                                                |> (==) (Route.viewBigbitPageCurrentActiveFile shared.route aBigbit)
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

        OnGetBigbitSuccess bigbit ->
            ( Util.multipleUpdates
                [ setBigbit <| Just bigbit
                , setRelevantHC Nothing
                ]
                model
            , shared
            , createViewBigbitCodeEditor bigbit shared
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
                tutorialFile =
                    case shared.route of
                        Route.ViewBigbitFramePage _ _ frameNumber _ ->
                            Maybe.andThen (Bigbit.getHighlightedComment frameNumber) model.bigbit
                                |> Maybe.map .file

                        _ ->
                            Nothing
            in
                if Just absolutePath == tutorialFile then
                    common.justProduceCmd <| Route.navigateToSameUrlWithFilePath Nothing shared.route
                else
                    common.justProduceCmd <| Route.navigateToSameUrlWithFilePath (Just absolutePath) shared.route

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


{-| Creates the code editor for the bigbit when browsing relevant HC.

This will only create the editor if the state of the model (the `Maybe`s) makes it appropriate to render the editor.
-}
createViewBigbitHCCodeEditor : Maybe Bigbit.Bigbit -> Maybe ViewingBigbitRelevantHC -> Maybe User.User -> Cmd msg
createViewBigbitHCCodeEditor maybeBigbit maybeRHC user =
    case ( maybeBigbit, maybeRHC ) of
        ( Just bigbit, Just { currentHC, relevantHC } ) ->
            let
                editorWithRange range language code =
                    Ports.createCodeEditor
                        { id = "view-bigbit-code-editor"
                        , fileID = ""
                        , lang = Editor.aceLanguageLocation language
                        , theme = User.getTheme user
                        , value = code
                        , range = Just range
                        , useMarker = True
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
        blankEditor =
            Ports.createCodeEditor
                { id = "view-bigbit-code-editor"
                , fileID = ""
                , lang = ""
                , theme = User.getTheme user
                , value = ""
                , range = Nothing
                , useMarker = True
                , readOnly = True
                , selectAllowed = True
                }

        loadFileWithNoHighlight fromStoryID maybePath =
            case maybePath of
                Nothing ->
                    blankEditor

                Just somePath ->
                    case FS.getFile bigbit.fs somePath of
                        Nothing ->
                            Route.modifyTo <| Route.ViewBigbitIntroductionPage fromStoryID bigbit.id Nothing

                        Just (FS.File content { language }) ->
                            Ports.createCodeEditor
                                { id = "view-bigbit-code-editor"
                                , fileID = FS.uniqueFilePath somePath
                                , lang = Editor.aceLanguageLocation language
                                , theme = User.getTheme user
                                , value = content
                                , range = Nothing
                                , useMarker = True
                                , readOnly = True
                                , selectAllowed = True
                                }
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
                                            Ports.createCodeEditor
                                                { id = "view-bigbit-code-editor"
                                                , fileID = FS.uniqueFilePath hc.file
                                                , lang = Editor.aceLanguageLocation language
                                                , theme = User.getTheme user
                                                , value = content
                                                , range = Just hc.range
                                                , useMarker = True
                                                , readOnly = True
                                                , selectAllowed = True
                                                }

                                Just absolutePath ->
                                    loadFileWithNoHighlight fromStoryID maybePath

                Route.ViewBigbitConclusionPage fromStoryID mongoID maybePath ->
                    loadFileWithNoHighlight fromStoryID maybePath

                _ ->
                    Cmd.none
            , Ports.smoothScrollToBottom
            ]
