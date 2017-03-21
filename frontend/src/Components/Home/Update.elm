module Components.Home.Update exposing (update, filterLanguagesByQuery)

import Array
import Api
import Autocomplete as AC
import Components.Home.Init as HomeInit
import Components.Home.Messages exposing (Msg(..))
import Components.Home.Model as Model exposing (Model)
import Components.Model exposing (Shared)
import Dom
import Dict
import DefaultModel exposing (defaultShared)
import DefaultServices.ArrayExtra as ArrayExtra
import DefaultServices.Util as Util exposing (maybeMapWithDefault)
import DefaultServices.Editable as Editable
import Elements.Editor as Editor
import Elements.FileStructure as FS
import Json.Decode as Decode
import JSON.Language as JSONLanguage
import Models.Bigbit as Bigbit
import Models.Completed as Completed
import Models.Snipbit as Snipbit
import Models.Range as Range
import Models.Route as Route
import Models.ProfileData as ProfileData
import Models.NewStoryData as NewStoryData
import Models.Story as Story
import Models.StoryData as StoryData
import Models.Tidbit as Tidbit
import Models.TidbitPointer as TidbitPointer
import Models.User as User exposing (defaultUserUpdateRecord)
import Models.CreateData as CreateData
import Models.ViewSnipbitData as ViewSnipbitData
import Models.ViewBigbitData as ViewBigbitData
import Models.ViewerRelevantHC as ViewerRelevantHC
import Ports
import Task


{-| Home Component Update.
-}
update : Msg -> Model -> Shared -> ( Model, Shared, Cmd Msg )
update msg model shared =
    let
        doNothing =
            ( model, shared, Cmd.none )

        justUpdateModel : Model -> ( Model, Shared, Cmd Msg )
        justUpdateModel newModel =
            ( newModel, shared, Cmd.none )

        justUpdateShared : Shared -> ( Model, Shared, Cmd Msg )
        justUpdateShared newShared =
            ( model, newShared, Cmd.none )

        justProduceCmd : Cmd Msg -> ( Model, Shared, Cmd Msg )
        justProduceCmd cmd =
            ( model, shared, cmd )

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

        updateSnipbitCreateData : Snipbit.SnipbitCreateData -> Model
        updateSnipbitCreateData newSnipbitCreateData =
            { model
                | snipbitCreateData = newSnipbitCreateData
            }

        currentSnipbitCreateData : Snipbit.SnipbitCreateData
        currentSnipbitCreateData =
            model.snipbitCreateData

        currentHighlightedComments =
            currentSnipbitCreateData.highlightedComments

        updateBigbitCreateData : Bigbit.BigbitCreateData -> Model
        updateBigbitCreateData newBigbitCreateData =
            { model
                | bigbitCreateData = newBigbitCreateData
            }

        currentBigbitCreateData : Bigbit.BigbitCreateData
        currentBigbitCreateData =
            model.bigbitCreateData

        currentBigbitHighlightedComments : Array.Array Bigbit.BigbitHighlightedCommentForCreate
        currentBigbitHighlightedComments =
            currentBigbitCreateData.highlightedComments

        updateViewBigbitData : (ViewBigbitData.ViewBigbitData -> ViewBigbitData.ViewBigbitData) -> Model
        updateViewBigbitData viewBigbitDataUpdater =
            { model
                | viewBigbitData = viewBigbitDataUpdater model.viewBigbitData
            }

        updateViewSnipbitData : (ViewSnipbitData.ViewSnipbitData -> ViewSnipbitData.ViewSnipbitData) -> Model
        updateViewSnipbitData viewSnipbitDataUpdater =
            { model
                | viewSnipbitData = viewSnipbitDataUpdater model.viewSnipbitData
            }

        updateCreateData : (CreateData.CreateData -> CreateData.CreateData) -> Model
        updateCreateData updater =
            { model
                | createData = updater model.createData
            }

        updateProfileData : (ProfileData.ProfileData -> ProfileData.ProfileData) -> Model
        updateProfileData updater =
            { model
                | profileData = updater model.profileData
            }

        updateNewStoryData : (NewStoryData.NewStoryData -> NewStoryData.NewStoryData) -> Model
        updateNewStoryData updater =
            { model
                | newStoryData = updater model.newStoryData
            }

        updateStoryData : (StoryData.StoryData -> StoryData.StoryData) -> Model
        updateStoryData updater =
            { model
                | storyData = updater model.storyData
            }
    in
        case msg of
            NoOp ->
                doNothing

            -- Recieves route hits from the router and handles the logic of the
            -- route hooks.
            OnRouteHit ->
                let
                    {- Get's data for viewing snipbit as required:
                          - May need to fetch tidbit itself
                          - May need to fetch story
                          - May need to fetch if the tidbit is completed by the user.

                       TODO ISSUE#99 Update to check cache if it is expired.
                    -}
                    fetchOrRenderViewSnipbitData mongoID =
                        let
                            currentTidbitPointer =
                                TidbitPointer.TidbitPointer
                                    TidbitPointer.Snipbit
                                    mongoID

                            -- Handle getting snipbit if needed.
                            handleGetSnipbit : ( Model, Shared ) -> ( Model, Shared, Cmd Msg )
                            handleGetSnipbit ( model, shared ) =
                                let
                                    getSnipbit mongoID =
                                        ( updateViewSnipbitData <|
                                            ViewSnipbitData.setViewingSnipbit Nothing
                                        , shared
                                        , Api.getSnipbit mongoID OnGetSnipbitFailure OnGetSnipbitSuccess
                                        )
                                in
                                    case model.viewSnipbitData.viewingSnipbit of
                                        Nothing ->
                                            getSnipbit mongoID

                                        Just snipbit ->
                                            if snipbit.id == mongoID then
                                                ( updateViewSnipbitData <|
                                                    ViewSnipbitData.setViewingSnipbitRelevantHC Nothing
                                                , shared
                                                , createViewSnipbitCodeEditor snipbit shared
                                                )
                                            else
                                                getSnipbit mongoID

                            -- Handle getting snipbit is-completed if needed.
                            handleGetSnipbitIsCompleted : ( Model, Shared ) -> ( Model, Shared, Cmd Msg )
                            handleGetSnipbitIsCompleted ( model, shared ) =
                                let
                                    doNothing =
                                        ( model, shared, Cmd.none )

                                    getSnipbitIsCompleted userID =
                                        ( updateViewSnipbitData <|
                                            ViewSnipbitData.setViewingSnipbitIsCompleted Nothing
                                        , shared
                                        , Api.postCheckCompletedWrapper
                                            (Completed.Completed currentTidbitPointer userID)
                                            ViewSnipbitGetCompletedFailure
                                            ViewSnipbitGetCompletedSuccess
                                        )
                                in
                                    case ( shared.user, model.viewSnipbitData.viewingSnipbitIsCompleted ) of
                                        ( Just user, Nothing ) ->
                                            getSnipbitIsCompleted user.id

                                        ( Just user, Just currentCompleted ) ->
                                            if currentCompleted.tidbitPointer == currentTidbitPointer then
                                                doNothing
                                            else
                                                getSnipbitIsCompleted user.id

                                        _ ->
                                            doNothing

                            -- Handle getting story if viewing snipbit from story.
                            handleGetStoryForSnipbit : ( Model, Shared ) -> ( Model, Shared, Cmd Msg )
                            handleGetStoryForSnipbit ( model, shared ) =
                                let
                                    doNothing =
                                        ( model, shared, Cmd.none )

                                    maybeViewingStoryID =
                                        Maybe.map .id shared.viewingStory

                                    getStory storyID =
                                        Api.getExpandedStoryWithCompleted
                                            storyID
                                            ViewSnipbitGetExpandedStoryFailure
                                            ViewSnipbitGetExpandedStorySuccess
                                in
                                    case Route.getFromStoryQueryParamOnViewSnipbitRoute shared.route of
                                        Just storyID ->
                                            if (Just storyID) == maybeViewingStoryID then
                                                doNothing
                                            else
                                                ( model
                                                , { shared
                                                    | viewingStory = Nothing
                                                  }
                                                , getStory storyID
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
                                [ handleGetSnipbit
                                , handleGetSnipbitIsCompleted
                                , handleGetStoryForSnipbit
                                ]

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
                                        ( updateViewBigbitData <| ViewBigbitData.setViewingBigbit Nothing
                                        , shared
                                        , Api.getBigbit mongoID OnGetBigbitFailure OnGetBigbitSuccess
                                        )
                                in
                                    case model.viewBigbitData.viewingBigbit of
                                        Nothing ->
                                            getBigbit mongoID

                                        Just bigbit ->
                                            if bigbit.id == mongoID then
                                                ( updateViewBigbitData <|
                                                    ViewBigbitData.setViewingBigbitRelevantHC Nothing
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
                                        ( updateViewBigbitData <|
                                            ViewBigbitData.setViewingBigbitIsCompleted Nothing
                                        , shared
                                        , Api.postCheckCompletedWrapper
                                            (Completed.Completed currentTidbitPointer userID)
                                            ViewBigbitGetCompletedFailure
                                            ViewBigbitGetCompletedSuccess
                                        )
                                in
                                    case ( shared.user, model.viewBigbitData.viewingBigbitIsCompleted ) of
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

                    -- TODO ISSUE#99 Update to check cache if it is expired.
                    fetchOrRenderStory mongoID ( model, shared ) =
                        ( model
                        , { shared
                            | viewingStory = Nothing
                          }
                        , Cmd.batch
                            [ smoothScrollToSubBar
                            , Api.getExpandedStoryWithCompleted mongoID ViewStoryGetExpandedStoryFailure ViewStoryGetExpandedStorySuccess
                            ]
                        )

                    createCreateBigbitEditorForCurrentFile maybeRange maybeFilePath backupRoute =
                        Cmd.batch
                            [ case maybeFilePath of
                                Nothing ->
                                    Ports.createCodeEditor
                                        { id = "create-bigbit-code-editor"
                                        , fileID = ""
                                        , lang = ""
                                        , theme = User.getTheme shared.user
                                        , value = ""
                                        , range = Nothing
                                        , readOnly = True
                                        , selectAllowed = True
                                        }

                                Just filePath ->
                                    case FS.getFile currentBigbitCreateData.fs filePath of
                                        Nothing ->
                                            Route.navigateTo backupRoute

                                        Just (FS.File content { language }) ->
                                            Ports.createCodeEditor
                                                { id = "create-bigbit-code-editor"
                                                , fileID = FS.uniqueFilePath filePath
                                                , lang = Editor.aceLanguageLocation language
                                                , theme = User.getTheme shared.user
                                                , value = content
                                                , range = maybeRange
                                                , readOnly = False
                                                , selectAllowed = True
                                                }
                            , smoothScrollToBottom
                            ]

                    createCreateSnipbitEditor aceRange =
                        let
                            aceLang =
                                maybeMapWithDefault
                                    Editor.aceLanguageLocation
                                    ""
                                    model.snipbitCreateData.language
                        in
                            Cmd.batch
                                [ Ports.createCodeEditor
                                    { id = "create-snipbit-code-editor"
                                    , fileID = ""
                                    , lang = aceLang
                                    , theme = User.getTheme shared.user
                                    , value = model.snipbitCreateData.code
                                    , range = aceRange
                                    , readOnly = False
                                    , selectAllowed = True
                                    }
                                , smoothScrollToBottom
                                ]

                    focusOn theID =
                        justProduceCmd <|
                            Util.domFocus (\_ -> NoOp) theID

                    -- If the ID of the current editingStory is different, we
                    -- need to get the info of the story that we are editing.
                    -- TODO ISSUE#99 Update to check cache if it is expired.
                    getEditingStoryAndFocusOn theID qpEditingStory =
                        justProduceCmd <|
                            Cmd.batch
                                [ Util.domFocus (\_ -> NoOp) theID
                                , case qpEditingStory of
                                    Nothing ->
                                        Cmd.none

                                    Just storyID ->
                                        -- We already loaded the story we want to edit.
                                        if storyID == model.newStoryData.editingStory.id then
                                            Cmd.none
                                        else
                                            Api.getStory storyID NewStoryGetEditingStoryFailure NewStoryGetEditingStorySuccess
                                ]
                in
                    case shared.route of
                        Route.HomeComponentCreate ->
                            case shared.user of
                                -- Should never happen.
                                Nothing ->
                                    doNothing

                                Just user ->
                                    if Util.isNothing shared.userStories then
                                        justProduceCmd <|
                                            Api.getStories
                                                [ ( "author", Just user.id ) ]
                                                GetAccountStoriesFailure
                                                GetAccountStoriesSuccess
                                    else
                                        doNothing

                        Route.HomeComponentViewSnipbitIntroduction _ mongoID ->
                            fetchOrRenderViewSnipbitData mongoID

                        Route.HomeComponentViewSnipbitFrame _ mongoID _ ->
                            fetchOrRenderViewSnipbitData mongoID

                        Route.HomeComponentViewSnipbitConclusion _ mongoID ->
                            fetchOrRenderViewSnipbitData mongoID
                                |> withCmd
                                    (case ( shared.user, model.viewSnipbitData.viewingSnipbitIsCompleted ) of
                                        ( Just user, Just isCompleted ) ->
                                            let
                                                completed =
                                                    Completed.completedFromIsCompleted isCompleted user.id
                                            in
                                                if isCompleted.complete == False then
                                                    Api.postAddCompletedWrapper completed ViewSnipbitMarkAsCompleteFailure ViewSnipbitMarkAsCompleteSuccess
                                                else
                                                    Cmd.none

                                        _ ->
                                            Cmd.none
                                    )

                        Route.HomeComponentViewBigbitIntroduction _ mongoID _ ->
                            fetchOrRenderViewBigbitData mongoID

                        Route.HomeComponentViewBigbitFrame _ mongoID _ _ ->
                            fetchOrRenderViewBigbitData mongoID

                        Route.HomeComponentViewBigbitConclusion _ mongoID _ ->
                            fetchOrRenderViewBigbitData mongoID
                                |> withCmd
                                    (case ( shared.user, model.viewBigbitData.viewingBigbitIsCompleted ) of
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

                        Route.HomeComponentViewStory mongoID ->
                            fetchOrRenderStory mongoID ( model, shared )

                        Route.HomeComponentCreateBigbitName ->
                            focusOn "name-input"

                        Route.HomeComponentCreateBigbitDescription ->
                            focusOn "description-input"

                        Route.HomeComponentCreateBigbitTags ->
                            focusOn "tags-input"

                        Route.HomeComponentCreateSnipbitName ->
                            focusOn "name-input"

                        Route.HomeComponentCreateSnipbitDescription ->
                            focusOn "description-input"

                        Route.HomeComponentCreateSnipbitLanguage ->
                            focusOn "language-query-input"

                        Route.HomeComponentCreateSnipbitTags ->
                            focusOn "tags-input"

                        Route.HomeComponentCreateSnipbitCodeIntroduction ->
                            justProduceCmd <|
                                Cmd.batch
                                    [ createCreateSnipbitEditor Nothing
                                    , Util.domFocus (\_ -> NoOp) "introduction-input"
                                    ]

                        Route.HomeComponentCreateSnipbitCodeFrame frameNumber ->
                            let
                                -- 0 based indexing.
                                frameIndex =
                                    frameNumber - 1

                                frameIndexTooHigh =
                                    frameIndex >= (Array.length model.snipbitCreateData.highlightedComments)

                                frameIndexTooLow =
                                    frameIndex < 0
                            in
                                if frameIndexTooLow then
                                    justProduceCmd <|
                                        Route.modifyTo
                                            Route.HomeComponentCreateSnipbitCodeIntroduction
                                else if frameIndexTooHigh then
                                    justProduceCmd <|
                                        Route.modifyTo
                                            Route.HomeComponentCreateSnipbitCodeConclusion
                                else
                                    let
                                        -- Either the existing range, the range from
                                        -- the previous frame collapsed, or Nothing.
                                        newHCRange =
                                            ((Array.get
                                                frameIndex
                                                model.snipbitCreateData.highlightedComments
                                             )
                                                |> Maybe.andThen .range
                                                |> (\maybeRange ->
                                                        case maybeRange of
                                                            Nothing ->
                                                                Snipbit.previousFrameRange model.snipbitCreateData shared.route
                                                                    |> Maybe.map Range.collapseRange

                                                            Just range ->
                                                                Just range
                                                   )
                                            )
                                    in
                                        ( updateSnipbitCreateData
                                            { currentSnipbitCreateData
                                                | highlightedComments =
                                                    ArrayExtra.update
                                                        frameIndex
                                                        (\currentHC ->
                                                            { currentHC
                                                                | range = newHCRange
                                                            }
                                                        )
                                                        currentSnipbitCreateData.highlightedComments
                                            }
                                        , shared
                                        , Cmd.batch
                                            [ createCreateSnipbitEditor newHCRange
                                            , Util.domFocus (\_ -> NoOp) "frame-input"
                                            ]
                                        )

                        Route.HomeComponentCreateSnipbitCodeConclusion ->
                            justProduceCmd <|
                                Cmd.batch
                                    [ createCreateSnipbitEditor Nothing
                                    , Util.domFocus (\_ -> NoOp) "conclusion-input"
                                    ]

                        Route.HomeComponentCreateBigbitCodeIntroduction maybeFilePath ->
                            justProduceCmd <|
                                Cmd.batch
                                    [ createCreateBigbitEditorForCurrentFile
                                        Nothing
                                        maybeFilePath
                                        (Route.HomeComponentCreateBigbitCodeIntroduction Nothing)
                                    , Util.domFocus (\_ -> NoOp) "introduction-input"
                                    ]

                        Route.HomeComponentCreateBigbitCodeFrame frameNumber maybeFilePath ->
                            if frameNumber < 1 then
                                justProduceCmd <|
                                    Route.modifyTo <|
                                        Route.HomeComponentCreateBigbitCodeIntroduction Nothing
                            else if frameNumber > (Array.length currentBigbitHighlightedComments) then
                                justProduceCmd <|
                                    Route.modifyTo <|
                                        Route.HomeComponentCreateBigbitCodeConclusion Nothing
                            else
                                let
                                    newModel =
                                        case maybeFilePath of
                                            Nothing ->
                                                case Array.get (frameNumber - 1) currentBigbitHighlightedComments of
                                                    Nothing ->
                                                        model

                                                    Just currentHighlightedComment ->
                                                        updateBigbitCreateData
                                                            { currentBigbitCreateData
                                                                | highlightedComments =
                                                                    Array.set
                                                                        (frameNumber - 1)
                                                                        { currentHighlightedComment
                                                                            | fileAndRange = Nothing
                                                                        }
                                                                        currentBigbitHighlightedComments
                                                            }

                                            Just filePath ->
                                                case Array.get (frameNumber - 1) currentBigbitHighlightedComments of
                                                    Nothing ->
                                                        model

                                                    Just currentHighlightedComment ->
                                                        updateBigbitCreateData
                                                            { currentBigbitCreateData
                                                                | highlightedComments =
                                                                    Array.set
                                                                        (frameNumber - 1)
                                                                        (case currentHighlightedComment.fileAndRange of
                                                                            Nothing ->
                                                                                { currentHighlightedComment
                                                                                    | fileAndRange =
                                                                                        Just
                                                                                            { range =
                                                                                                case Bigbit.previousFrameRange model.bigbitCreateData shared.route of
                                                                                                    Nothing ->
                                                                                                        Nothing

                                                                                                    Just ( _, range ) ->
                                                                                                        Just <|
                                                                                                            Range.collapseRange range
                                                                                            , file = filePath
                                                                                            }
                                                                                }

                                                                            Just fileAndRange ->
                                                                                if FS.isSameFilePath fileAndRange.file filePath then
                                                                                    currentHighlightedComment
                                                                                else
                                                                                    { currentHighlightedComment
                                                                                        | fileAndRange =
                                                                                            Just
                                                                                                { range = Nothing
                                                                                                , file = filePath
                                                                                                }
                                                                                    }
                                                                        )
                                                                        currentBigbitHighlightedComments
                                                            }

                                    maybeRangeToHighlight =
                                        Array.get (frameNumber - 1) newModel.bigbitCreateData.highlightedComments
                                            |> Maybe.andThen .fileAndRange
                                            |> Maybe.andThen .range
                                in
                                    ( newModel
                                    , shared
                                    , Cmd.batch
                                        [ createCreateBigbitEditorForCurrentFile
                                            maybeRangeToHighlight
                                            maybeFilePath
                                            (Route.HomeComponentCreateBigbitCodeFrame frameNumber Nothing)
                                        , Util.domFocus (\_ -> NoOp) "frame-input"
                                        ]
                                    )

                        Route.HomeComponentCreateBigbitCodeConclusion maybeFilePath ->
                            justProduceCmd <|
                                Cmd.batch
                                    [ createCreateBigbitEditorForCurrentFile
                                        Nothing
                                        maybeFilePath
                                        (Route.HomeComponentCreateBigbitCodeConclusion Nothing)
                                    , Util.domFocus (\_ -> NoOp) "conclusion-input"
                                    ]

                        Route.HomeComponentCreateNewStoryName qpEditingStory ->
                            getEditingStoryAndFocusOn "name-input" qpEditingStory

                        Route.HomeComponentCreateNewStoryDescription qpEditingStory ->
                            getEditingStoryAndFocusOn "description-input" qpEditingStory

                        Route.HomeComponentCreateNewStoryTags qpEditingStory ->
                            getEditingStoryAndFocusOn "tags-input" qpEditingStory

                        Route.HomeComponentCreateStory storyID ->
                            (if maybeMapWithDefault (.id >> ((==) storyID)) False model.storyData.currentStory then
                                doNothing
                             else
                                ( updateStoryData <|
                                    (\storyData ->
                                        { storyData
                                            | currentStory = Nothing
                                            , tidbitsToAdd = []
                                        }
                                    )
                                , shared
                                , Api.getExpandedStory storyID CreateStoryGetStoryFailure (CreateStoryGetStorySuccess False)
                                )
                            )
                                |> withCmd
                                    (Cmd.batch
                                        [ case ( Util.isNothing shared.userTidbits, shared.user ) of
                                            ( True, Just user ) ->
                                                Api.getTidbits
                                                    [ ( "forUser", Just user.id ) ]
                                                    CreateStoryGetTidbitsFailure
                                                    CreateStoryGetTidbitsSuccess

                                            _ ->
                                                Cmd.none
                                        , Ports.doScrolling
                                            { querySelector = "#story-tidbits-title"
                                            , duration = 500
                                            , extraScroll = -60
                                            }
                                        ]
                                    )

                        _ ->
                            doNothing

            GoTo route ->
                justProduceCmd <| Route.navigateTo route

            LogOut ->
                justProduceCmd <| Api.getLogOut OnLogOutFailure OnLogOutSuccess

            OnLogOutFailure apiError ->
                justUpdateModel <|
                    updateProfileData <|
                        (\currentProfileData ->
                            { currentProfileData
                                | logOutError = Just apiError
                            }
                        )

            OnLogOutSuccess basicResponse ->
                ( HomeInit.init
                , defaultShared
                , Route.navigateTo Route.WelcomeComponentRegister
                )

            ShowInfoFor maybeTidbitType ->
                justUpdateModel <|
                    updateCreateData <|
                        CreateData.setShowInfoFor maybeTidbitType

            SnipbitGoToCodeTab ->
                ( updateSnipbitCreateData
                    { currentSnipbitCreateData
                        | previewMarkdown = False
                    }
                , shared
                , Route.navigateTo Route.HomeComponentCreateSnipbitCodeIntroduction
                )

            SnipbitUpdateLanguageQuery newLanguageQuery ->
                justUpdateModel <|
                    updateSnipbitCreateData
                        { currentSnipbitCreateData
                            | languageQuery = newLanguageQuery
                        }

            SnipbitUpdateACState acMsg ->
                let
                    ( newACState, maybeMsg ) =
                        AC.update
                            acUpdateConfig
                            acMsg
                            currentSnipbitCreateData.languageListHowManyToShow
                            currentSnipbitCreateData.languageQueryACState
                            (filterLanguagesByQuery
                                currentSnipbitCreateData.languageQuery
                                shared.languages
                            )

                    newModel =
                        updateSnipbitCreateData
                            { currentSnipbitCreateData
                                | languageQueryACState = newACState
                            }
                in
                    case maybeMsg of
                        Nothing ->
                            justUpdateModel <| newModel

                        Just updateMsg ->
                            update updateMsg newModel shared

            SnipbitUpdateACWrap toTop ->
                let
                    newSnipbitCreateData =
                        { currentSnipbitCreateData
                            | languageQueryACState =
                                (if toTop then
                                    AC.resetToLastItem
                                 else
                                    AC.resetToFirstItem
                                )
                                    acUpdateConfig
                                    (filterLanguagesByQuery
                                        model.snipbitCreateData.languageQuery
                                        shared.languages
                                    )
                                    currentSnipbitCreateData.languageListHowManyToShow
                                    currentSnipbitCreateData.languageQueryACState
                        }

                    newModel =
                        updateSnipbitCreateData newSnipbitCreateData
                in
                    justUpdateModel newModel

            SnipbitSelectLanguage maybeEncodedLang ->
                let
                    language =
                        case maybeEncodedLang of
                            -- Erasing the selected language.
                            Nothing ->
                                Nothing

                            -- Selecting a language.
                            Just encodedLang ->
                                Util.quote
                                    >> Decode.decodeString JSONLanguage.decoder
                                    >> Result.toMaybe
                                <|
                                    encodedLang

                    -- If the user wants to select a new language, we help them
                    -- by focussing the input box.
                    newCmd =
                        if Util.isNothing language then
                            Util.domFocus (always NoOp) "language-query-input"
                        else
                            Cmd.none

                    newLanguageQuery =
                        case language of
                            Nothing ->
                                ""

                            Just aLanguage ->
                                Editor.getHumanReadableName aLanguage

                    newSnipbitCreateData =
                        { currentSnipbitCreateData
                            | language = language
                            , languageQuery = newLanguageQuery
                        }

                    newModel =
                        updateSnipbitCreateData newSnipbitCreateData
                in
                    ( newModel, shared, newCmd )

            SnipbitReset ->
                let
                    newModel =
                        updateSnipbitCreateData <| .snipbitCreateData HomeInit.init
                in
                    ( newModel, shared, Route.navigateTo Route.HomeComponentCreateSnipbitName )

            SnipbitUpdateName newName ->
                justUpdateModel <|
                    updateSnipbitCreateData
                        { currentSnipbitCreateData
                            | name = newName
                        }

            SnipbitUpdateDescription newDescription ->
                justUpdateModel <|
                    updateSnipbitCreateData
                        { currentSnipbitCreateData
                            | description = newDescription
                        }

            SnipbitUpdateTagInput newTagInput ->
                if String.endsWith " " newTagInput then
                    let
                        newTag =
                            String.dropRight 1 newTagInput

                        newTags =
                            Util.addUniqueNonEmptyString
                                newTag
                                currentSnipbitCreateData.tags
                    in
                        justUpdateModel <|
                            updateSnipbitCreateData
                                { currentSnipbitCreateData
                                    | tagInput = ""
                                    , tags = newTags
                                }
                else
                    justUpdateModel <|
                        updateSnipbitCreateData
                            { currentSnipbitCreateData
                                | tagInput = newTagInput
                            }

            SnipbitRemoveTag tagName ->
                justUpdateModel <|
                    updateSnipbitCreateData
                        { currentSnipbitCreateData
                            | tags =
                                List.filter
                                    (\aTag -> aTag /= tagName)
                                    currentSnipbitCreateData.tags
                        }

            SnipbitAddTag tagName ->
                justUpdateModel <|
                    updateSnipbitCreateData
                        { currentSnipbitCreateData
                            | tags =
                                Util.addUniqueNonEmptyString
                                    tagName
                                    currentSnipbitCreateData.tags
                            , tagInput = ""
                        }

            SnipbitNewRangeSelected newRange ->
                case shared.route of
                    Route.HomeComponentCreateSnipbitCodeIntroduction ->
                        doNothing

                    Route.HomeComponentCreateSnipbitCodeConclusion ->
                        doNothing

                    Route.HomeComponentCreateSnipbitCodeFrame frameNumber ->
                        let
                            frameIndex =
                                frameNumber - 1
                        in
                            case (Array.get frameIndex currentHighlightedComments) of
                                Nothing ->
                                    doNothing

                                Just currentFrameHighlightedComment ->
                                    let
                                        newFrame =
                                            { currentFrameHighlightedComment
                                                | range = Just newRange
                                            }

                                        newHighlightedComments =
                                            Array.set
                                                frameIndex
                                                newFrame
                                                currentHighlightedComments
                                    in
                                        justUpdateModel <|
                                            updateSnipbitCreateData
                                                { currentSnipbitCreateData
                                                    | highlightedComments = newHighlightedComments
                                                }

                    -- Should never really happen (highlighting when not on
                    -- the editor pages).
                    _ ->
                        doNothing

            SnipbitTogglePreviewMarkdown ->
                justUpdateModel <|
                    updateSnipbitCreateData <|
                        togglePreviewMarkdown currentSnipbitCreateData

            SnipbitAddFrame ->
                let
                    newSnipbitCreateData =
                        { currentSnipbitCreateData
                            | highlightedComments =
                                (Array.push
                                    { range = Nothing, comment = Nothing }
                                    currentHighlightedComments
                                )
                        }

                    newModel =
                        updateSnipbitCreateData newSnipbitCreateData

                    newMsg =
                        GoTo <|
                            Route.HomeComponentCreateSnipbitCodeFrame <|
                                Array.length
                                    newModel.snipbitCreateData.highlightedComments
                in
                    update newMsg newModel shared

            SnipbitRemoveFrame ->
                let
                    newHighlightedComments =
                        Array.slice
                            0
                            (Array.length currentHighlightedComments - 1)
                            currentHighlightedComments

                    newModel =
                        updateSnipbitCreateData
                            { currentSnipbitCreateData
                                | highlightedComments =
                                    newHighlightedComments
                            }
                in
                    case shared.route of
                        Route.HomeComponentCreateSnipbitCodeIntroduction ->
                            justUpdateModel <| newModel

                        Route.HomeComponentCreateSnipbitCodeConclusion ->
                            justUpdateModel <| newModel

                        -- We need to go "down" a tab if the user was on the
                        -- last tab and they removed a tab.
                        Route.HomeComponentCreateSnipbitCodeFrame frameNumber ->
                            let
                                frameIndex =
                                    frameNumber - 1
                            in
                                if frameIndex >= (Array.length newHighlightedComments) then
                                    update
                                        (GoTo <|
                                            Route.HomeComponentCreateSnipbitCodeFrame <|
                                                Array.length newHighlightedComments
                                        )
                                        newModel
                                        shared
                                else
                                    justUpdateModel <| newModel

                        -- Should never happen.
                        _ ->
                            justUpdateModel <| newModel

            SnipbitUpdateFrameComment index newComment ->
                case Array.get index currentHighlightedComments of
                    Nothing ->
                        doNothing

                    Just highlightComment ->
                        let
                            newHighlightComment =
                                { highlightComment
                                    | comment = Just newComment
                                }

                            newHighlightedComments =
                                Array.set
                                    index
                                    newHighlightComment
                                    currentHighlightedComments
                        in
                            justUpdateModel <|
                                updateSnipbitCreateData
                                    { currentSnipbitCreateData
                                        | highlightedComments = newHighlightedComments
                                    }

            SnipbitUpdateIntroduction newIntro ->
                justUpdateModel <|
                    updateSnipbitCreateData
                        { currentSnipbitCreateData
                            | introduction = newIntro
                        }

            SnipbitUpdateConclusion newConclusion ->
                justUpdateModel <|
                    updateSnipbitCreateData
                        { currentSnipbitCreateData
                            | conclusion = newConclusion
                        }

            -- On top of updating the code, we need to check that no highlights
            -- are now out of range. If highlights are now out of range we
            -- minimize them to the greatest size they can be whilst still being
            -- in range.
            SnipbitUpdateCode { newCode, action, deltaRange } ->
                let
                    currentCode =
                        currentSnipbitCreateData.code

                    newHighlightedComments =
                        Array.map
                            (\comment ->
                                case comment.range of
                                    Nothing ->
                                        comment

                                    Just aRange ->
                                        { comment
                                            | range =
                                                Just <|
                                                    Range.getNewRangeAfterDelta
                                                        currentCode
                                                        newCode
                                                        action
                                                        deltaRange
                                                        aRange
                                        }
                            )
                            currentHighlightedComments
                in
                    justUpdateModel <|
                        updateSnipbitCreateData
                            { currentSnipbitCreateData
                                | code = newCode
                                , highlightedComments = newHighlightedComments
                            }

            SnipbitPublish snipbit ->
                justProduceCmd <|
                    Api.postCreateSnipbit
                        snipbit
                        OnSnipbitPublishFailure
                        OnSnipbitPublishSuccess

            SnipbitJumpToLineFromPreviousFrame ->
                case shared.route of
                    Route.HomeComponentCreateSnipbitCodeFrame frameNumber ->
                        ( updateSnipbitCreateData <|
                            { currentSnipbitCreateData
                                | highlightedComments =
                                    ArrayExtra.update
                                        (frameNumber - 1)
                                        (\hc ->
                                            { hc
                                                | range = Nothing
                                            }
                                        )
                                        currentSnipbitCreateData.highlightedComments
                            }
                        , shared
                        , Route.modifyTo shared.route
                        )

                    _ ->
                        doNothing

            OnSnipbitPublishSuccess { targetID } ->
                ( { model
                    | snipbitCreateData = .snipbitCreateData HomeInit.init
                  }
                , { shared
                    | userTidbits = Nothing
                  }
                , Route.navigateTo <| Route.HomeComponentViewSnipbitIntroduction Nothing targetID
                )

            OnSnipbitPublishFailure apiError ->
                -- TODO Handle Publish Failures.
                doNothing

            OnGetSnipbitFailure apiFailure ->
                -- TODO Handle get snipbit failure.
                doNothing

            OnGetSnipbitSuccess snipbit ->
                ( updateViewSnipbitData <|
                    Util.multipleUpdates
                        [ ViewSnipbitData.setViewingSnipbit <| Just snipbit
                        , ViewSnipbitData.setViewingSnipbitRelevantHC Nothing
                        ]
                , shared
                , createViewSnipbitCodeEditor snipbit shared
                )

            ViewSnipbitRangeSelected selectedRange ->
                case model.viewSnipbitData.viewingSnipbit of
                    Nothing ->
                        doNothing

                    Just aSnipbit ->
                        if Range.isEmptyRange selectedRange then
                            justUpdateModel <|
                                updateViewSnipbitData <|
                                    ViewSnipbitData.setViewingSnipbitRelevantHC Nothing
                        else
                            aSnipbit.highlightedComments
                                |> Array.indexedMap (,)
                                |> Array.filter (Tuple.second >> .range >> (Range.overlappingRanges selectedRange))
                                |> (\relevantHC ->
                                        justUpdateModel <|
                                            updateViewSnipbitData <|
                                                ViewSnipbitData.setViewingSnipbitRelevantHC <|
                                                    Just
                                                        { currentHC = Nothing
                                                        , relevantHC = relevantHC
                                                        }
                                   )

            ViewSnipbitBrowseRelevantHC ->
                let
                    newModel =
                        (updateViewSnipbitData << ViewSnipbitData.updateViewingSnipbitRelevantHC)
                            (\currentRelevantHC ->
                                { currentRelevantHC
                                    | currentHC = Just 0
                                }
                            )
                in
                    ( newModel
                    , shared
                    , createViewSnipbitHCCodeEditor newModel.viewSnipbitData.viewingSnipbit newModel.viewSnipbitData.viewingSnipbitRelevantHC shared.user
                    )

            ViewSnipbitCancelBrowseRelevantHC ->
                ( updateViewSnipbitData <|
                    ViewSnipbitData.setViewingSnipbitRelevantHC Nothing
                , shared
                  -- Trigger route hook again, `modify` because we don't want to
                  -- have the same page twice in the history.
                , Route.modifyTo shared.route
                )

            ViewSnipbitNextRelevantHC ->
                let
                    newModel =
                        (updateViewSnipbitData << ViewSnipbitData.updateViewingSnipbitRelevantHC)
                            ViewerRelevantHC.goToNextFrame
                in
                    ( newModel
                    , shared
                    , createViewSnipbitHCCodeEditor
                        newModel.viewSnipbitData.viewingSnipbit
                        newModel.viewSnipbitData.viewingSnipbitRelevantHC
                        shared.user
                    )

            ViewSnipbitPreviousRelevantHC ->
                let
                    newModel =
                        (updateViewSnipbitData << ViewSnipbitData.updateViewingSnipbitRelevantHC)
                            ViewerRelevantHC.goToPreviousFrame
                in
                    ( newModel
                    , shared
                    , createViewSnipbitHCCodeEditor
                        newModel.viewSnipbitData.viewingSnipbit
                        newModel.viewSnipbitData.viewingSnipbitRelevantHC
                        shared.user
                    )

            ViewSnipbitJumpToFrame route ->
                ( updateViewSnipbitData <|
                    ViewSnipbitData.setViewingSnipbitRelevantHC Nothing
                , shared
                , Route.navigateTo route
                )

            ViewSnipbitGetCompletedSuccess isCompleted ->
                justUpdateModel <|
                    updateViewSnipbitData <|
                        ViewSnipbitData.setViewingSnipbitIsCompleted <|
                            Just isCompleted

            ViewSnipbitGetCompletedFailure apiError ->
                -- TODO handle error.
                doNothing

            ViewSnipbitMarkAsComplete completed ->
                justProduceCmd <|
                    Api.postAddCompletedWrapper
                        completed
                        ViewSnipbitMarkAsCompleteFailure
                        ViewSnipbitMarkAsCompleteSuccess

            ViewSnipbitMarkAsCompleteSuccess isCompleted ->
                justUpdateModel <|
                    updateViewSnipbitData <|
                        ViewSnipbitData.setViewingSnipbitIsCompleted <|
                            Just isCompleted

            ViewSnipbitMarkAsCompleteFailure apiError ->
                -- TODO handle error.
                doNothing

            ViewSnipbitMarkAsIncomplete completed ->
                justProduceCmd <|
                    Api.postRemoveCompletedWrapper
                        completed
                        ViewSnipbitMarkAsIncompleteFailure
                        ViewSnipbitMarkAsIncompleteSuccess

            ViewSnipbitMarkAsIncompleteSuccess isCompleted ->
                justUpdateModel <|
                    updateViewSnipbitData <|
                        ViewSnipbitData.setViewingSnipbitIsCompleted <|
                            Just isCompleted

            ViewSnipbitMarkAsIncompleteFailure apiError ->
                -- TODO handle error.
                doNothing

            ViewSnipbitGetExpandedStoryFailure apiError ->
                -- TODO handle error.
                doNothing

            ViewSnipbitGetExpandedStorySuccess expandedStory ->
                justUpdateShared
                    { shared
                        | viewingStory = Just expandedStory
                    }

            BigbitGoToCodeTab ->
                ( updateBigbitCreateData
                    { currentBigbitCreateData
                        | previewMarkdown = False
                        , fs =
                            currentBigbitCreateData.fs
                                |> FS.updateFSMetadata
                                    (\fsMetadata ->
                                        { fsMetadata
                                            | openFS = False
                                        }
                                    )
                    }
                , shared
                , Route.navigateTo <| Route.HomeComponentCreateBigbitCodeIntroduction Nothing
                )

            BigbitReset ->
                ( updateBigbitCreateData <| .bigbitCreateData HomeInit.init
                , shared
                , Route.navigateTo Route.HomeComponentCreateBigbitName
                )

            BigbitUpdateName newName ->
                justUpdateModel <|
                    updateBigbitCreateData <|
                        { currentBigbitCreateData
                            | name = newName
                        }

            BigbitUpdateDescription newDescription ->
                justUpdateModel <|
                    updateBigbitCreateData <|
                        { currentBigbitCreateData
                            | description = newDescription
                        }

            BigbitUpdateTagInput newTagInput ->
                if String.endsWith " " newTagInput then
                    let
                        newTag =
                            String.dropRight 1 newTagInput

                        newTags =
                            Util.addUniqueNonEmptyString
                                newTag
                                currentBigbitCreateData.tags
                    in
                        justUpdateModel <|
                            updateBigbitCreateData
                                { currentBigbitCreateData
                                    | tags = newTags
                                    , tagInput = ""
                                }
                else
                    justUpdateModel <|
                        updateBigbitCreateData
                            { currentBigbitCreateData
                                | tagInput = newTagInput
                            }

            BigbitAddTag tagName ->
                let
                    newTags =
                        Util.addUniqueNonEmptyString
                            tagName
                            currentBigbitCreateData.tags
                in
                    justUpdateModel <|
                        updateBigbitCreateData
                            { currentBigbitCreateData
                                | tags = newTags
                                , tagInput = ""
                            }

            BigbitRemoveTag tagName ->
                let
                    newTags =
                        List.filter
                            (\tag -> tag /= tagName)
                            currentBigbitCreateData.tags
                in
                    justUpdateModel <|
                        updateBigbitCreateData
                            { currentBigbitCreateData
                                | tags = newTags
                            }

            BigbitUpdateIntroduction newIntro ->
                justUpdateModel <|
                    updateBigbitCreateData
                        { currentBigbitCreateData
                            | introduction = newIntro
                        }

            BigbitUpdateConclusion newConclusion ->
                justUpdateModel <|
                    updateBigbitCreateData
                        { currentBigbitCreateData
                            | conclusion = newConclusion
                        }

            BigbitToggleFS ->
                justUpdateModel <|
                    updateBigbitCreateData
                        { currentBigbitCreateData
                            | fs = Bigbit.toggleFS currentBigbitCreateData.fs
                        }

            BigbitFSToggleFolder folderPath ->
                justUpdateModel <|
                    updateBigbitCreateData
                        { currentBigbitCreateData
                            | fs = Bigbit.toggleFSFolder folderPath currentBigbitCreateData.fs
                        }

            BigbitTogglePreviewMarkdown ->
                justUpdateModel <|
                    updateBigbitCreateData <|
                        togglePreviewMarkdown currentBigbitCreateData

            BigbitUpdateActionButtonState newActionState ->
                ( updateBigbitCreateData
                    { currentBigbitCreateData
                        | fs =
                            currentBigbitCreateData.fs
                                |> FS.updateFSMetadata
                                    (\currentMetadata ->
                                        { currentMetadata
                                            | actionButtonState =
                                                if currentMetadata.actionButtonState == newActionState then
                                                    Nothing
                                                else
                                                    newActionState
                                            , actionButtonSubmitConfirmed = False
                                        }
                                    )
                    }
                , shared
                , Util.domFocus (always NoOp) "fs-action-input-box"
                )

            BigbitUpdateActionInput newActionButtonInput ->
                justUpdateModel <|
                    updateBigbitCreateData
                        { currentBigbitCreateData
                            | fs =
                                currentBigbitCreateData.fs
                                    |> FS.updateFSMetadata
                                        (\currentMetadata ->
                                            { currentMetadata
                                                | actionButtonInput = newActionButtonInput
                                                , actionButtonSubmitConfirmed = False
                                            }
                                        )
                        }

            BigbitSubmitActionInput ->
                let
                    fs =
                        model.bigbitCreateData.fs

                    absolutePath =
                        fs
                            |> FS.getFSMetadata
                            |> .actionButtonInput

                    maybeCurrentActionState =
                        fs
                            |> FS.getFSMetadata
                            |> .actionButtonState

                    {- Filters the highlighted comments to make sure non of them
                       point to non-existant files. Used when removing
                       files/folders.

                       NOTE: If all comments are filtered out, adds a blank one
                             because we always want at least one comment.
                    -}
                    getNewHighlightedComments hc newFS =
                        (Array.filter
                            (\hc ->
                                case hc.fileAndRange of
                                    Nothing ->
                                        True

                                    Just { file, range } ->
                                        FS.hasFile file newFS
                            )
                            currentBigbitHighlightedComments
                        )
                            |> (\remainingArray ->
                                    if Array.length remainingArray == 0 then
                                        Array.fromList
                                            [ Bigbit.emptyBigbitHighlightCommentForCreate ]
                                    else
                                        remainingArray
                               )

                    {- After removing files/folders the current URL can become
                       invalid, this function redirects to intro if needed.
                    -}
                    navigateIfRouteNowInvalid newFS newHighlightedComments =
                        let
                            redirectToIntro =
                                Route.modifyTo <| Route.HomeComponentCreateBigbitCodeIntroduction Nothing

                            redirectIfFileRemoved =
                                case Bigbit.createPageCurrentActiveFile shared.route of
                                    Nothing ->
                                        Cmd.none

                                    Just filePath ->
                                        if FS.hasFile filePath newFS then
                                            Cmd.none
                                        else
                                            redirectToIntro
                        in
                            case shared.route of
                                Route.HomeComponentCreateBigbitCodeFrame frameNumber _ ->
                                    if frameNumber > (Array.length newHighlightedComments) then
                                        redirectToIntro
                                    else
                                        redirectIfFileRemoved

                                _ ->
                                    redirectIfFileRemoved

                    ( newModel, newCmd ) =
                        case maybeCurrentActionState of
                            -- Should never happen.
                            Nothing ->
                                ( model, Cmd.none )

                            Just currentActionState ->
                                case currentActionState of
                                    Bigbit.AddingFile ->
                                        case Bigbit.isValidAddFileInput absolutePath fs of
                                            Err _ ->
                                                ( model, Cmd.none )

                                            Ok language ->
                                                let
                                                    ( newModel, _, newCmd ) =
                                                        update (BigbitAddFile absolutePath language) model shared
                                                in
                                                    ( newModel, newCmd )

                                    Bigbit.AddingFolder ->
                                        case Bigbit.isValidAddFolderInput absolutePath fs of
                                            Err _ ->
                                                ( model, Cmd.none )

                                            Ok _ ->
                                                ( updateBigbitCreateData
                                                    { currentBigbitCreateData
                                                        | fs =
                                                            fs
                                                                |> FS.addFolder
                                                                    { overwriteExisting = False
                                                                    , forceCreateDirectories = Just <| always Bigbit.defaultEmptyFolder
                                                                    }
                                                                    absolutePath
                                                                    (FS.Folder Dict.empty Dict.empty { isExpanded = True })
                                                                |> Bigbit.clearActionButtonInput
                                                    }
                                                , Cmd.none
                                                )

                                    Bigbit.RemovingFile ->
                                        case Bigbit.isValidRemoveFileInput absolutePath fs of
                                            Err _ ->
                                                ( model, Cmd.none )

                                            Ok _ ->
                                                if .actionButtonSubmitConfirmed <| FS.getFSMetadata fs then
                                                    let
                                                        newFS =
                                                            fs
                                                                |> FS.removeFile absolutePath
                                                                |> Bigbit.clearActionButtonInput

                                                        newHighlightedComments =
                                                            getNewHighlightedComments currentBigbitHighlightedComments newFS
                                                    in
                                                        ( updateBigbitCreateData
                                                            { currentBigbitCreateData
                                                                | fs = newFS
                                                                , highlightedComments = newHighlightedComments
                                                            }
                                                        , navigateIfRouteNowInvalid newFS newHighlightedComments
                                                        )
                                                else
                                                    ( updateBigbitCreateData
                                                        { currentBigbitCreateData
                                                            | fs =
                                                                fs
                                                                    |> Bigbit.setActionButtonSubmitConfirmed True
                                                        }
                                                    , Cmd.none
                                                    )

                                    Bigbit.RemovingFolder ->
                                        case Bigbit.isValidRemoveFolderInput absolutePath fs of
                                            Err _ ->
                                                ( model, Cmd.none )

                                            Ok _ ->
                                                if .actionButtonSubmitConfirmed <| FS.getFSMetadata fs then
                                                    let
                                                        newFS =
                                                            fs
                                                                |> FS.removeFolder absolutePath
                                                                |> Bigbit.clearActionButtonInput

                                                        newHighlightedComments =
                                                            getNewHighlightedComments currentBigbitHighlightedComments newFS
                                                    in
                                                        ( updateBigbitCreateData
                                                            { currentBigbitCreateData
                                                                | fs = newFS
                                                                , highlightedComments = newHighlightedComments
                                                            }
                                                        , navigateIfRouteNowInvalid newFS newHighlightedComments
                                                        )
                                                else
                                                    ( updateBigbitCreateData
                                                        { currentBigbitCreateData
                                                            | fs =
                                                                fs
                                                                    |> Bigbit.setActionButtonSubmitConfirmed True
                                                        }
                                                    , Cmd.none
                                                    )
                in
                    ( newModel
                    , shared
                    , newCmd
                    )

            BigbitAddFile absolutePath language ->
                justUpdateModel <|
                    updateBigbitCreateData
                        { currentBigbitCreateData
                            | fs =
                                currentBigbitCreateData.fs
                                    |> (FS.addFile
                                            { overwriteExisting = False
                                            , forceCreateDirectories = Just <| always Bigbit.defaultEmptyFolder
                                            }
                                            absolutePath
                                            (FS.emptyFile { language = language })
                                       )
                                    |> Bigbit.clearActionButtonInput
                        }

            -- Update the code and also check if any ranges are out of range
            -- and update those ranges.
            BigbitUpdateCode { newCode, action, deltaRange } ->
                case Bigbit.createPageCurrentActiveFile shared.route of
                    Nothing ->
                        doNothing

                    Just filePath ->
                        let
                            currentCode =
                                FS.getFile currentBigbitCreateData.fs filePath
                                    |> maybeMapWithDefault
                                        (\(FS.File content _) ->
                                            content
                                        )
                                        ""

                            newFS =
                                currentBigbitCreateData.fs
                                    |> FS.updateFile
                                        filePath
                                        (\(FS.File content fileMetadata) ->
                                            FS.File
                                                newCode
                                                fileMetadata
                                        )

                            newHC =
                                Array.map
                                    (\comment ->
                                        case comment.fileAndRange of
                                            Nothing ->
                                                comment

                                            Just { file, range } ->
                                                if FS.isSameFilePath file filePath then
                                                    case range of
                                                        Nothing ->
                                                            comment

                                                        Just aRange ->
                                                            { comment
                                                                | fileAndRange =
                                                                    Just
                                                                        { file = file
                                                                        , range =
                                                                            Just <|
                                                                                Range.getNewRangeAfterDelta
                                                                                    currentCode
                                                                                    newCode
                                                                                    action
                                                                                    deltaRange
                                                                                    aRange
                                                                        }
                                                            }
                                                else
                                                    comment
                                    )
                                    currentBigbitHighlightedComments
                        in
                            justUpdateModel <|
                                updateBigbitCreateData
                                    { currentBigbitCreateData
                                        | fs = newFS
                                        , highlightedComments = newHC
                                    }

            BigbitFileSelected absolutePath ->
                justProduceCmd <|
                    Route.navigateToSameUrlWithFilePath (Just absolutePath) shared.route

            BigbitAddFrame ->
                let
                    currentPath =
                        Bigbit.createPageCurrentActiveFile shared.route

                    newModel =
                        updateBigbitCreateData
                            { currentBigbitCreateData
                                | highlightedComments =
                                    (Array.push
                                        Bigbit.emptyBigbitHighlightCommentForCreate
                                        currentBigbitHighlightedComments
                                    )
                            }

                    newCmd =
                        Route.navigateTo <|
                            Route.HomeComponentCreateBigbitCodeFrame
                                (Array.length newModel.bigbitCreateData.highlightedComments)
                                currentPath
                in
                    ( newModel, shared, newCmd )

            BigbitRemoveFrame ->
                if Array.length currentBigbitHighlightedComments == 1 then
                    doNothing
                else
                    let
                        newHighlightedComments =
                            Array.slice
                                0
                                (Array.length currentBigbitHighlightedComments - 1)
                                currentBigbitHighlightedComments

                        newModel =
                            updateBigbitCreateData
                                { currentBigbitCreateData
                                    | highlightedComments = newHighlightedComments
                                }

                        -- Have to make sure if they are on the last frame it pushes
                        -- them down one frame.
                        newRoute =
                            case shared.route of
                                Route.HomeComponentCreateBigbitCodeFrame frameNumber filePath ->
                                    Just <|
                                        Route.HomeComponentCreateBigbitCodeFrame
                                            (if frameNumber == (Array.length currentBigbitHighlightedComments) then
                                                (frameNumber - 1)
                                             else
                                                frameNumber
                                            )
                                            filePath

                                _ ->
                                    Nothing

                        newCmd =
                            Maybe.map Route.modifyTo newRoute
                                |> Maybe.withDefault Cmd.none
                    in
                        ( newModel, shared, newCmd )

            BigbitUpdateFrameComment frameNumber newComment ->
                case Array.get (frameNumber - 1) currentBigbitHighlightedComments of
                    Nothing ->
                        doNothing

                    Just highlightedComment ->
                        let
                            newHighlightedComment =
                                { highlightedComment
                                    | comment = newComment
                                }

                            newHighlightedComments =
                                Array.set (frameNumber - 1)
                                    newHighlightedComment
                                    currentBigbitHighlightedComments
                        in
                            justUpdateModel <|
                                updateBigbitCreateData
                                    { currentBigbitCreateData
                                        | highlightedComments = newHighlightedComments
                                    }

            BigbitNewRangeSelected newRange ->
                case shared.route of
                    Route.HomeComponentCreateBigbitCodeFrame frameNumber currentPath ->
                        case Array.get (frameNumber - 1) currentBigbitHighlightedComments of
                            Nothing ->
                                doNothing

                            Just highlightedComment ->
                                case highlightedComment.fileAndRange of
                                    Nothing ->
                                        doNothing

                                    Just fileAndRange ->
                                        justUpdateModel <|
                                            updateBigbitCreateData
                                                { currentBigbitCreateData
                                                    | highlightedComments =
                                                        Array.set
                                                            (frameNumber - 1)
                                                            { highlightedComment
                                                                | fileAndRange =
                                                                    Just
                                                                        { fileAndRange
                                                                            | range = Just newRange
                                                                        }
                                                            }
                                                            currentBigbitHighlightedComments
                                                }

                    _ ->
                        doNothing

            BigbitPublish bigbit ->
                justProduceCmd <|
                    Api.postCreateBigbit
                        bigbit
                        OnBigbitPublishFailure
                        OnBigbitPublishSuccess

            BigbitJumpToLineFromPreviousFrame filePath ->
                case shared.route of
                    Route.HomeComponentCreateBigbitCodeFrame frameNumber _ ->
                        ( updateBigbitCreateData <|
                            Bigbit.updateCreateDataHCAtIndex
                                currentBigbitCreateData
                                (frameNumber - 1)
                                (\hcAtIndex ->
                                    { hcAtIndex
                                        | fileAndRange = Nothing
                                    }
                                )
                        , shared
                        , Route.modifyTo <|
                            Route.HomeComponentCreateBigbitCodeFrame frameNumber (Just filePath)
                        )

                    _ ->
                        doNothing

            OnBigbitPublishFailure apiError ->
                -- TODO Handle bigbit publish failures.
                doNothing

            OnBigbitPublishSuccess { targetID } ->
                ( { model
                    | bigbitCreateData = .bigbitCreateData HomeInit.init
                  }
                , { shared
                    | userTidbits = Nothing
                  }
                , Route.navigateTo <|
                    Route.HomeComponentViewBigbitIntroduction Nothing targetID Nothing
                )

            OnGetBigbitFailure apiError ->
                -- TODO handle get bigbit failure.
                doNothing

            OnGetBigbitSuccess bigbit ->
                ( updateViewBigbitData <|
                    Util.multipleUpdates
                        [ ViewBigbitData.setViewingBigbit <| Just bigbit
                        , ViewBigbitData.setViewingBigbitRelevantHC Nothing
                        ]
                , shared
                , createViewBigbitCodeEditor bigbit shared
                )

            ViewBigbitToggleFS ->
                let
                    -- We have a `not` because we toggle the fs state.
                    fsJustOpened =
                        model.viewBigbitData.viewingBigbit
                            |> Maybe.map (not << Bigbit.isFSOpen << .fs)
                            |> Maybe.withDefault False
                in
                    ( updateViewBigbitData <|
                        Util.multipleUpdates
                            [ ViewBigbitData.updateViewingBigbit
                                (\currentViewingBigbit ->
                                    { currentViewingBigbit
                                        | fs = Bigbit.toggleFS currentViewingBigbit.fs
                                    }
                                )
                            , ViewBigbitData.setViewingBigbitRelevantHC Nothing
                            ]
                    , shared
                    , if fsJustOpened then
                        Route.navigateToSameUrlWithFilePath
                            (Maybe.andThen
                                (Bigbit.viewPageCurrentActiveFile shared.route)
                                model.viewBigbitData.viewingBigbit
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
                    updateViewBigbitData <|
                        ViewBigbitData.updateViewingBigbit <|
                            (\currentViewingBigbit ->
                                { currentViewingBigbit
                                    | fs =
                                        Bigbit.toggleFSFolder absolutePath currentViewingBigbit.fs
                                }
                            )

            ViewBigbitRangeSelected selectedRange ->
                case model.viewBigbitData.viewingBigbit of
                    Nothing ->
                        doNothing

                    Just aBigbit ->
                        if Range.isEmptyRange selectedRange then
                            justUpdateModel <|
                                updateViewBigbitData <|
                                    ViewBigbitData.setViewingBigbitRelevantHC Nothing
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
                                            updateViewBigbitData <|
                                                ViewBigbitData.setViewingBigbitRelevantHC <|
                                                    Just
                                                        { currentHC = Nothing
                                                        , relevantHC = relevantHC
                                                        }
                                   )

            ViewBigbitBrowseRelevantHC ->
                let
                    newModel =
                        updateViewBigbitData <|
                            ViewBigbitData.updateViewingBigbitRelevantHC <|
                                (\currentRelevantHC ->
                                    { currentRelevantHC
                                        | currentHC = Just 0
                                    }
                                )
                in
                    ( newModel
                    , shared
                    , createViewBigbitHCCodeEditor
                        newModel.viewBigbitData.viewingBigbit
                        newModel.viewBigbitData.viewingBigbitRelevantHC
                        shared.user
                    )

            ViewBigbitCancelBrowseRelevantHC ->
                ( updateViewBigbitData <|
                    ViewBigbitData.setViewingBigbitRelevantHC Nothing
                , shared
                  -- Trigger route hook again, `modify` because we don't want to
                  -- have the same page twice in the history.
                , Route.modifyTo shared.route
                )

            ViewBigbitNextRelevantHC ->
                let
                    newModel =
                        updateViewBigbitData <|
                            ViewBigbitData.updateViewingBigbitRelevantHC <|
                                ViewerRelevantHC.goToNextFrame
                in
                    ( newModel
                    , shared
                    , createViewBigbitHCCodeEditor
                        newModel.viewBigbitData.viewingBigbit
                        newModel.viewBigbitData.viewingBigbitRelevantHC
                        shared.user
                    )

            ViewBigbitPreviousRelevantHC ->
                let
                    newModel =
                        updateViewBigbitData <|
                            ViewBigbitData.updateViewingBigbitRelevantHC <|
                                ViewerRelevantHC.goToPreviousFrame
                in
                    ( newModel
                    , shared
                    , createViewBigbitHCCodeEditor
                        newModel.viewBigbitData.viewingBigbit
                        newModel.viewBigbitData.viewingBigbitRelevantHC
                        shared.user
                    )

            ViewBigbitJumpToFrame route ->
                ( updateViewBigbitData <|
                    Util.multipleUpdates
                        [ ViewBigbitData.updateViewingBigbit
                            (\currentViewingBigbit ->
                                { currentViewingBigbit
                                    | fs = Bigbit.closeFS currentViewingBigbit.fs
                                }
                            )
                        , ViewBigbitData.setViewingBigbitRelevantHC Nothing
                        ]
                , shared
                , Route.navigateTo route
                )

            ViewBigbitGetCompletedSuccess isCompleted ->
                justUpdateModel <|
                    updateViewBigbitData <|
                        ViewBigbitData.setViewingBigbitIsCompleted <|
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
                    updateViewBigbitData <|
                        ViewBigbitData.setViewingBigbitIsCompleted <|
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
                    updateViewBigbitData <|
                        ViewBigbitData.setViewingBigbitIsCompleted <|
                            Just isCompleted

            ViewBigbitMarkAsIncompleteFailure apiError ->
                -- TODO handle error.
                doNothing

            ViewBigbitGetExpandedStorySuccess story ->
                justUpdateShared <|
                    { shared
                        | viewingStory = Just story
                    }

            ViewBigbitGetExpandedStoryFailure apiError ->
                -- TODO handle error
                doNothing

            ViewStoryGetExpandedStoryFailure apiError ->
                -- TODO handle error.
                doNothing

            ViewStoryGetExpandedStorySuccess expandedStory ->
                justUpdateShared <|
                    { shared
                        | viewingStory = Just expandedStory
                    }

            ProfileCancelEditName ->
                justUpdateModel <| updateProfileData ProfileData.cancelEditingName

            ProfileUpdateName originalName newName ->
                justUpdateModel <| updateProfileData (ProfileData.setName originalName newName)

            ProfileSaveEditName ->
                case model.profileData.accountName of
                    Nothing ->
                        doNothing

                    Just editableName ->
                        justProduceCmd <|
                            Api.postUpdateUser
                                { defaultUserUpdateRecord
                                    | name = Just <| Editable.getBuffer editableName
                                }
                                ProfileSaveNameFailure
                                ProfileSaveNameSuccess

            ProfileSaveNameFailure apiError ->
                -- TODO handle failure.
                doNothing

            ProfileSaveNameSuccess updatedUser ->
                ( updateProfileData ProfileData.setAccountNameToNothing
                , { shared
                    | user = Just updatedUser
                  }
                , Cmd.none
                )

            ProfileCancelEditBio ->
                justUpdateModel <| updateProfileData ProfileData.cancelEditingBio

            ProfileUpdateBio originalBio newBio ->
                justUpdateModel <|
                    updateProfileData (ProfileData.setBio originalBio newBio)

            ProfileSaveEditBio ->
                case model.profileData.accountBio of
                    Nothing ->
                        doNothing

                    Just editableBio ->
                        justProduceCmd <|
                            Api.postUpdateUser
                                { defaultUserUpdateRecord
                                    | bio = Just <| Editable.getBuffer editableBio
                                }
                                ProfileSaveBioFailure
                                ProfileSaveBioSuccess

            ProfileSaveBioFailure apiError ->
                -- TODO handle error.
                doNothing

            ProfileSaveBioSuccess updatedUser ->
                ( updateProfileData ProfileData.setAccountBioToNothing
                , { shared
                    | user = Just updatedUser
                  }
                , Cmd.none
                )

            GetAccountStoriesFailure apiError ->
                -- TODO handle error.
                doNothing

            GetAccountStoriesSuccess userStories ->
                justUpdateShared <|
                    { shared
                        | userStories = Just userStories
                    }

            NewStoryUpdateName newName ->
                justUpdateModel <|
                    updateNewStoryData <|
                        NewStoryData.updateName newName

            NewStoryEditingUpdateName newName ->
                justUpdateModel <|
                    updateNewStoryData <|
                        NewStoryData.updateEditName newName

            NewStoryUpdateDescription newDescription ->
                justUpdateModel <|
                    updateNewStoryData <|
                        NewStoryData.updateDescription newDescription

            NewStoryEditingUpdateDescription newDescription ->
                justUpdateModel <|
                    updateNewStoryData <|
                        NewStoryData.updateEditDescription newDescription

            NewStoryUpdateTagInput newTagInput ->
                justUpdateModel <|
                    updateNewStoryData <|
                        if String.endsWith " " newTagInput then
                            NewStoryData.newTag <|
                                String.dropRight 1 newTagInput
                        else
                            NewStoryData.updateTagInput newTagInput

            NewStoryEditingUpdateTagInput newTagInput ->
                justUpdateModel <|
                    updateNewStoryData <|
                        if String.endsWith " " newTagInput then
                            NewStoryData.newEditTag <|
                                String.dropRight 1 newTagInput
                        else
                            NewStoryData.updateEditTagInput newTagInput

            NewStoryAddTag tagName ->
                justUpdateModel <|
                    updateNewStoryData <|
                        NewStoryData.newTag tagName

            NewStoryEditingAddTag tagName ->
                justUpdateModel <|
                    updateNewStoryData <|
                        NewStoryData.newEditTag tagName

            NewStoryRemoveTag tagName ->
                justUpdateModel <|
                    updateNewStoryData <|
                        NewStoryData.removeTag tagName

            NewStoryEditingRemoveTag tagName ->
                justUpdateModel <|
                    updateNewStoryData <|
                        NewStoryData.removeEditTag tagName

            NewStoryReset ->
                ( updateNewStoryData <| always NewStoryData.defaultNewStoryData
                , shared
                  -- The reset button only exists when there is no `qpEditingStory`.
                , Route.navigateTo <| Route.HomeComponentCreateNewStoryName Nothing
                )

            NewStoryPublish ->
                if NewStoryData.newStoryDataReadyForPublication model.newStoryData then
                    justProduceCmd <|
                        Api.postCreateNewStory
                            model.newStoryData.newStory
                            NewStoryPublishFailure
                            NewStoryPublishSuccess
                else
                    doNothing

            NewStoryPublishFailure apiError ->
                -- TODO handle error.
                doNothing

            NewStoryPublishSuccess { targetID } ->
                ( { model
                    | newStoryData = NewStoryData.defaultNewStoryData
                  }
                , { shared
                    | userStories = Nothing
                  }
                , Route.navigateTo <| Route.HomeComponentCreateStory targetID
                )

            NewStoryGetEditingStoryFailure apiError ->
                -- TODO handle error.
                doNothing

            NewStoryGetEditingStorySuccess story ->
                case shared.user of
                    Nothing ->
                        doNothing

                    Just user ->
                        if story.author == user.id then
                            justUpdateModel <|
                                updateNewStoryData <|
                                    NewStoryData.updateEditStory (always story)
                        else
                            justProduceCmd <|
                                Route.modifyTo <|
                                    Route.HomeComponentCreate

            NewStoryCancelEdits storyID ->
                ( updateNewStoryData <|
                    NewStoryData.updateEditStory (always Story.blankStory)
                , shared
                , Route.navigateTo <| Route.HomeComponentCreateStory storyID
                )

            NewStorySaveEdits storyID ->
                let
                    editingStory =
                        model.newStoryData.editingStory

                    editingStoryInformation =
                        { name = editingStory.name
                        , description = editingStory.description
                        , tags = editingStory.tags
                        }
                in
                    justProduceCmd <|
                        Api.postUpdateStoryInformation
                            storyID
                            editingStoryInformation
                            NewStorySaveEditsFailure
                            NewStorySaveEditsSuccess

            NewStorySaveEditsFailure apiError ->
                -- TODO handle error.
                doNothing

            NewStorySaveEditsSuccess { targetID } ->
                ( model
                , { shared
                    | userStories = Nothing
                  }
                , Route.navigateTo <| Route.HomeComponentCreateStory targetID
                )

            CreateStoryGetStoryFailure apiError ->
                -- TODO handle error
                doNothing

            CreateStoryGetStorySuccess resetUserStories expandedStory ->
                let
                    -- Resets stories if needed.
                    newShared =
                        if resetUserStories then
                            { shared
                                | userStories = Nothing
                            }
                        else
                            shared
                in
                    case shared.user of
                        -- Should never happen.
                        Nothing ->
                            doNothing

                        Just user ->
                            -- If this is indeed the author, then stay on page,
                            -- otherwise redirect.
                            if user.id == expandedStory.author then
                                ( updateStoryData <| StoryData.setCurrentStory expandedStory
                                , newShared
                                , Cmd.none
                                )
                            else
                                ( model
                                , newShared
                                , Route.modifyTo Route.HomeComponentCreate
                                )

            CreateStoryGetTidbitsFailure apiError ->
                -- Handle error.
                doNothing

            CreateStoryGetTidbitsSuccess tidbits ->
                justUpdateShared <|
                    { shared
                        | userTidbits = Just tidbits
                    }

            CreateStoryAddTidbit tidbit ->
                justUpdateModel <|
                    updateStoryData <|
                        StoryData.addTidbit tidbit

            CreateStoryRemoveTidbit tidbit ->
                justUpdateModel <|
                    updateStoryData <|
                        StoryData.removeTidbit tidbit

            CreateStoryPublishAddedTidbits storyID tidbits ->
                if List.length tidbits > 0 then
                    justProduceCmd <|
                        Api.postAddTidbitsToStory
                            storyID
                            (List.map Tidbit.compressTidbit tidbits)
                            CreateStoryPublishAddedTidbitsFailure
                            (CreateStoryGetStorySuccess True)
                else
                    -- Should never happen.
                    doNothing

            CreateStoryPublishAddedTidbitsFailure apiError ->
                -- TODO handle error.
                doNothing


{-| Creates the code editor for the bigbit when browsing relevant HC.

This will only create the editor if the state of the model (the `Maybe`s) makes
it appropriate to render the editor.
-}
createViewBigbitHCCodeEditor : Maybe Bigbit.Bigbit -> Maybe ViewBigbitData.ViewingBigbitRelevantHC -> Maybe User.User -> Cmd msg
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


{-| Creates the code editor for the snipbit when browsing the relevant HC.

This will only create the editor if the state of the model (the `Maybe`s) makes
it appropriate to render the editor.
-}
createViewSnipbitHCCodeEditor : Maybe Snipbit.Snipbit -> Maybe ViewSnipbitData.ViewingSnipbitRelevantHC -> Maybe User.User -> Cmd msg
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
                Route.HomeComponentViewSnipbitIntroduction _ _ ->
                    editorWithRange Nothing

                Route.HomeComponentViewSnipbitConclusion _ _ ->
                    editorWithRange Nothing

                Route.HomeComponentViewSnipbitFrame fromStoryID mongoID frameNumber ->
                    if frameNumber > Array.length snipbit.highlightedComments then
                        Route.modifyTo <|
                            Route.HomeComponentViewSnipbitConclusion fromStoryID mongoID
                    else if frameNumber < 1 then
                        Route.modifyTo <|
                            Route.HomeComponentViewSnipbitIntroduction fromStoryID mongoID
                    else
                        (Array.get
                            (frameNumber - 1)
                            snipbit.highlightedComments
                        )
                            |> Maybe.map .range
                            |> editorWithRange

                _ ->
                    Cmd.none
            , smoothScrollToBottom
            ]


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
                            Route.modifyTo <| Route.HomeComponentViewBigbitIntroduction fromStoryID bigbit.id Nothing

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
                Route.HomeComponentViewBigbitIntroduction fromStoryID mongoID maybePath ->
                    loadFileWithNoHighlight fromStoryID maybePath

                Route.HomeComponentViewBigbitFrame fromStoryID mongoID frameNumber maybePath ->
                    case Array.get (frameNumber - 1) bigbit.highlightedComments of
                        Nothing ->
                            if frameNumber > (Array.length bigbit.highlightedComments) then
                                Route.modifyTo <| Route.HomeComponentViewBigbitConclusion fromStoryID bigbit.id Nothing
                            else
                                Route.modifyTo <| Route.HomeComponentViewBigbitIntroduction fromStoryID bigbit.id Nothing

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

                Route.HomeComponentViewBigbitConclusion fromStoryID mongoID maybePath ->
                    loadFileWithNoHighlight fromStoryID maybePath

                _ ->
                    Cmd.none
            , smoothScrollToBottom
            ]


{-| Filters the languages based on `query`.
-}
filterLanguagesByQuery : String -> List ( Editor.Language, String ) -> List ( Editor.Language, String )
filterLanguagesByQuery query =
    let
        -- Ignores case.
        containsQuery =
            String.toLower >> String.contains (String.toLower query)
    in
        List.filter
            (\langPair ->
                (containsQuery <| Tuple.second langPair)
                    || (containsQuery <| toString <| Tuple.first langPair)
            )


{-| Config for language-list auto-complete (used in snipbit creation).
-}
acUpdateConfig : AC.UpdateConfig Msg ( Editor.Language, String )
acUpdateConfig =
    let
        downKeyCode =
            38

        upKeyCode =
            40

        enterKeyCode =
            13
    in
        AC.updateConfig
            { toId = (toString << Tuple.first)
            , onKeyDown =
                \keyCode maybeID ->
                    if keyCode == downKeyCode || keyCode == upKeyCode then
                        Nothing
                    else if keyCode == enterKeyCode then
                        if Util.isNothing maybeID then
                            Nothing
                        else
                            Just <| SnipbitSelectLanguage maybeID
                    else
                        Nothing
            , onTooLow = Just <| SnipbitUpdateACWrap False
            , onTooHigh = Just <| SnipbitUpdateACWrap True
            , onMouseClick =
                \id ->
                    Just <| SnipbitSelectLanguage <| Just id
            , onMouseLeave = \_ -> Nothing
            , onMouseEnter = \_ -> Nothing
            , separateSelections = False
            }


{-| Helper for flipping the previewMarkdown field of any record.
-}
togglePreviewMarkdown : { a | previewMarkdown : Bool } -> { a | previewMarkdown : Bool }
togglePreviewMarkdown record =
    { record
        | previewMarkdown = not record.previewMarkdown
    }


{-| Smooth-scrolls to the bottom.
-}
smoothScrollToBottom : Cmd msg
smoothScrollToBottom =
    Ports.doScrolling { querySelector = ".invisible-bottom", duration = 500, extraScroll = 0 }


{-| Smooth-scrolls to the subbar, effectively hiding the top navbar.
-}
smoothScrollToSubBar : Cmd msg
smoothScrollToSubBar =
    Ports.doScrolling { querySelector = ".sub-bar", duration = 500, extraScroll = 0 }
