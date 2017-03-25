module Pages.ViewBigbit.Update exposing (..)

import Api
import Array
import DefaultServices.Util as Util exposing (maybeMapWithDefault)
import Elements.Editor as Editor
import Elements.FileStructure as FS
import Models.Completed as Completed
import Models.Bigbit as Bigbit
import Models.Range as Range
import Models.Route as Route
import Models.User as User
import Models.ViewerRelevantHC as ViewerRelevantHC
import Models.TidbitPointer as TidbitPointer
import Pages.Model exposing (Shared)
import Pages.ViewBigbit.Messages exposing (Msg(..))
import Pages.ViewBigbit.Model exposing (..)
import Ports


{-| `ViewBigbit` update.
-}
update : Msg -> Model -> Shared -> ( Model, Shared, Cmd Msg )
update msg model shared =
    let
        doNothing =
            ( model, shared, Cmd.none )

        justSetModel newModel =
            ( newModel, shared, Cmd.none )

        justSetShared newShared =
            ( model, newShared, Cmd.none )

        justProduceCmd newCmd =
            ( model, shared, newCmd )

        justUpdateModel modelUpdater =
            ( modelUpdater model, shared, Cmd.none )

        withCmd : Cmd Msg -> ( Model, Shared, Cmd Msg ) -> ( Model, Shared, Cmd Msg )
        withCmd withCmd ( newModel, newShared, newCmd ) =
            ( newModel, newShared, Cmd.batch [ newCmd, withCmd ] )

        -- For when you need to do multiple things all which change model/shared/cmd.
        handleAll : List (( Model, Shared ) -> ( Model, Shared, Cmd Msg )) -> ( Model, Shared, Cmd Msg )
        handleAll =
            let
                go ( lastModel, lastShared, lastCmd ) listOfThingsToHandle =
                    case listOfThingsToHandle of
                        [] ->
                            ( lastModel, lastShared, lastCmd )

                        handleCurrent :: xs ->
                            go (withCmd lastCmd (handleCurrent ( lastModel, lastShared ))) xs
            in
                go ( model, shared, Cmd.none )
    in
        case msg of
            NoOp ->
                doNothing

            GoTo route ->
                ( model, shared, Route.navigateTo route )

            OnRouteHit route ->
                let
                    {- Get's data for viewing bigbit as required:
                          - May need to fetch tidbit itself
                          - May need to fetch story
                          - May need to fetch if the tidbit is completed by the user.

                       TODO ISSUE#99 Update to check cache if it is expired.
                    -}
                    fetchOrRenderViewBigbitData mongoID =
                        let
                            currentTidbitPointer =
                                TidbitPointer.TidbitPointer
                                    TidbitPointer.Bigbit
                                    mongoID

                            -- Handle getting bigbit if needed.
                            handleGetBigbit ( model, shared ) =
                                let
                                    getBigbit mongoID =
                                        ( setViewingBigbit Nothing model
                                        , shared
                                        , Api.getBigbit mongoID OnGetBigbitFailure OnGetBigbitSuccess
                                        )
                                in
                                    case model.viewingBigbit of
                                        Nothing ->
                                            getBigbit mongoID

                                        Just bigbit ->
                                            if bigbit.id == mongoID then
                                                ( setViewingBigbitRelevantHC Nothing model
                                                , shared
                                                , createViewBigbitCodeEditor bigbit shared
                                                )
                                            else
                                                getBigbit mongoID

                            -- Handle getting bigbit is-completed if needed.
                            handleGetBigbitIsCompleted ( model, shared ) =
                                let
                                    doNothing =
                                        ( model, shared, Cmd.none )

                                    -- Command for fetching the `isCompleted`
                                    getBigbitIsCompleted userID =
                                        ( setViewingBigbitIsCompleted Nothing model
                                        , shared
                                        , Api.postCheckCompletedWrapper
                                            (Completed.Completed currentTidbitPointer userID)
                                            ViewBigbitGetCompletedFailure
                                            ViewBigbitGetCompletedSuccess
                                        )
                                in
                                    case ( shared.user, model.viewingBigbitIsCompleted ) of
                                        ( Just user, Just currentCompleted ) ->
                                            if currentCompleted.tidbitPointer == currentTidbitPointer then
                                                doNothing
                                            else
                                                getBigbitIsCompleted user.id

                                        ( Just user, Nothing ) ->
                                            getBigbitIsCompleted user.id

                                        _ ->
                                            doNothing

                            handleGetStoryForBigbit : ( Model, Shared ) -> ( Model, Shared, Cmd Msg )
                            handleGetStoryForBigbit ( model, shared ) =
                                let
                                    doNothing =
                                        ( model, shared, Cmd.none )

                                    maybeViewingStoryID =
                                        Maybe.map .id shared.viewingStory

                                    getStory storyID =
                                        Api.getExpandedStoryWithCompleted
                                            storyID
                                            ViewBigbitGetExpandedStoryFailure
                                            ViewBigbitGetExpandedStorySuccess
                                in
                                    case Route.getFromStoryQueryParamOnViewBigbitRoute shared.route of
                                        Just fromStoryID ->
                                            if Just fromStoryID == maybeViewingStoryID then
                                                doNothing
                                            else
                                                ( model
                                                , { shared
                                                    | viewingStory = Nothing
                                                  }
                                                , getStory fromStoryID
                                                )

                                        _ ->
                                            ( model
                                            , { shared
                                                | viewingStory = Nothing
                                              }
                                            , Cmd.none
                                            )
                        in
                            handleAll
                                [ handleGetBigbit
                                , handleGetBigbitIsCompleted
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
                                |> withCmd
                                    (case ( shared.user, model.viewingBigbitIsCompleted ) of
                                        ( Just user, Just isCompleted ) ->
                                            let
                                                completed =
                                                    Completed.completedFromIsCompleted isCompleted user.id
                                            in
                                                if isCompleted.complete == False then
                                                    Api.postAddCompletedWrapper completed ViewBigbitMarkAsCompleteFailure ViewBigbitMarkAsCompleteSuccess
                                                else
                                                    Cmd.none

                                        _ ->
                                            Cmd.none
                                    )

                        _ ->
                            doNothing

            OnGetBigbitFailure apiError ->
                -- TODO handle get bigbit failure.
                doNothing

            OnGetBigbitSuccess bigbit ->
                ( Util.multipleUpdates
                    [ setViewingBigbit <| Just bigbit
                    , setViewingBigbitRelevantHC Nothing
                    ]
                    model
                , shared
                , createViewBigbitCodeEditor bigbit shared
                )

            ViewBigbitToggleFS ->
                let
                    -- We have a `not` because we toggle the fs state.
                    fsJustOpened =
                        model.viewingBigbit
                            |> Maybe.map (not << Bigbit.isFSOpen << .fs)
                            |> Maybe.withDefault False
                in
                    ( Util.multipleUpdates
                        [ updateViewingBigbit
                            (\currentViewingBigbit ->
                                { currentViewingBigbit
                                    | fs = Bigbit.toggleFS currentViewingBigbit.fs
                                }
                            )
                        , setViewingBigbitRelevantHC Nothing
                        ]
                        model
                    , shared
                    , if fsJustOpened then
                        Route.navigateToSameUrlWithFilePath
                            (Maybe.andThen
                                (Bigbit.viewPageCurrentActiveFile shared.route)
                                model.viewingBigbit
                            )
                            shared.route
                      else
                        Route.navigateToSameUrlWithFilePath Nothing shared.route
                    )

            ViewBigbitSelectFile absolutePath ->
                justProduceCmd <|
                    Route.navigateToSameUrlWithFilePath (Just absolutePath) shared.route

            ViewBigbitToggleFolder absolutePath ->
                justUpdateModel <|
                    updateViewingBigbit <|
                        (\currentViewingBigbit ->
                            { currentViewingBigbit
                                | fs =
                                    Bigbit.toggleFSFolder absolutePath currentViewingBigbit.fs
                            }
                        )

            ViewBigbitRangeSelected selectedRange ->
                case model.viewingBigbit of
                    Nothing ->
                        doNothing

                    Just aBigbit ->
                        if Range.isEmptyRange selectedRange then
                            justUpdateModel <|
                                setViewingBigbitRelevantHC Nothing
                        else
                            aBigbit.highlightedComments
                                |> Array.indexedMap (,)
                                |> Array.filter
                                    (\hc ->
                                        (Tuple.second hc |> .range |> Range.overlappingRanges selectedRange)
                                            && (Tuple.second hc |> .file |> Just |> (==) (Bigbit.viewPageCurrentActiveFile shared.route aBigbit))
                                    )
                                |> (\relevantHC ->
                                        justUpdateModel <|
                                            setViewingBigbitRelevantHC <|
                                                Just
                                                    { currentHC = Nothing
                                                    , relevantHC = relevantHC
                                                    }
                                   )

            ViewBigbitBrowseRelevantHC ->
                let
                    newModel =
                        updateViewingBigbitRelevantHC
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
                        newModel.viewingBigbit
                        newModel.viewingBigbitRelevantHC
                        shared.user
                    )

            ViewBigbitCancelBrowseRelevantHC ->
                ( setViewingBigbitRelevantHC Nothing model
                , shared
                  -- Trigger route hook again, `modify` because we don't want to
                  -- have the same page twice in the history.
                , Route.modifyTo shared.route
                )

            ViewBigbitNextRelevantHC ->
                let
                    newModel =
                        updateViewingBigbitRelevantHC
                            ViewerRelevantHC.goToNextFrame
                            model
                in
                    ( newModel
                    , shared
                    , createViewBigbitHCCodeEditor
                        newModel.viewingBigbit
                        newModel.viewingBigbitRelevantHC
                        shared.user
                    )

            ViewBigbitPreviousRelevantHC ->
                let
                    newModel =
                        updateViewingBigbitRelevantHC
                            ViewerRelevantHC.goToPreviousFrame
                            model
                in
                    ( newModel
                    , shared
                    , createViewBigbitHCCodeEditor
                        newModel.viewingBigbit
                        newModel.viewingBigbitRelevantHC
                        shared.user
                    )

            ViewBigbitJumpToFrame route ->
                ( Util.multipleUpdates
                    [ updateViewingBigbit
                        (\currentViewingBigbit ->
                            { currentViewingBigbit
                                | fs = Bigbit.closeFS currentViewingBigbit.fs
                            }
                        )
                    , setViewingBigbitRelevantHC Nothing
                    ]
                    model
                , shared
                , Route.navigateTo route
                )

            ViewBigbitGetCompletedSuccess isCompleted ->
                justUpdateModel <|
                    setViewingBigbitIsCompleted <|
                        Just isCompleted

            ViewBigbitGetCompletedFailure apiError ->
                -- TODO handle error.
                doNothing

            ViewBigbitMarkAsComplete completed ->
                justProduceCmd <|
                    Api.postAddCompletedWrapper
                        completed
                        ViewBigbitMarkAsCompleteFailure
                        ViewBigbitMarkAsCompleteSuccess

            ViewBigbitMarkAsCompleteSuccess isCompleted ->
                justUpdateModel <|
                    setViewingBigbitIsCompleted <|
                        Just isCompleted

            ViewBigbitMarkAsCompleteFailure apiError ->
                -- TODO handle error.
                doNothing

            ViewBigbitMarkAsIncomplete completed ->
                justProduceCmd <|
                    Api.postRemoveCompletedWrapper
                        completed
                        ViewBigbitMarkAsIncompleteFailure
                        ViewBigbitMarkAsIncompleteSuccess

            ViewBigbitMarkAsIncompleteSuccess isCompleted ->
                justUpdateModel <|
                    setViewingBigbitIsCompleted <|
                        Just isCompleted

            ViewBigbitMarkAsIncompleteFailure apiError ->
                -- TODO handle error.
                doNothing

            ViewBigbitGetExpandedStorySuccess story ->
                justSetShared
                    { shared
                        | viewingStory = Just story
                    }

            ViewBigbitGetExpandedStoryFailure apiError ->
                -- TODO handle error
                doNothing


{-| Creates the code editor for the bigbit when browsing relevant HC.

This will only create the editor if the state of the model (the `Maybe`s) makes
it appropriate to render the editor.
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
