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
import Json.Decode as Decode
import Elements.FileStructure as FS
import Models.Bigbit as Bigbit
import Models.Completed as Completed
import Models.Snipbit as Snipbit
import Models.Range as Range
import Models.Route as Route
import Models.ProfileData as ProfileData
import Models.NewStoryData as NewStoryData
import Models.Story as Story
import Models.StoryData as StoryData
import Models.ViewStoryData as ViewStoryData
import Models.Tidbit as Tidbit
import Models.TidbitPointer as TidbitPointer
import Models.User as User exposing (defaultUserUpdateRecord)
import Task
import Ports


{-| Home Component Update.
-}
update : Msg -> Model -> Shared -> ( Model, Shared, Cmd Msg )
update msg model shared =
    let
        doNothing =
            ( model, shared, Cmd.none )

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

        updateViewingBigbit : (Bigbit.Bigbit -> Bigbit.Bigbit) -> Model
        updateViewingBigbit bigbitUpdater =
            { model
                | viewingBigbit =
                    Maybe.map bigbitUpdater model.viewingBigbit
            }

        updateViewingBigbitReturningBigbit : (Bigbit.Bigbit -> Bigbit.Bigbit) -> Maybe Bigbit.Bigbit
        updateViewingBigbitReturningBigbit updater =
            Maybe.map updater model.viewingBigbit

        updateViewingBigbitRelevantHC : (Model.ViewingBigbitRelevantHC -> Model.ViewingBigbitRelevantHC) -> Model
        updateViewingBigbitRelevantHC updater =
            { model
                | viewingBigbitRelevantHC = Maybe.map updater model.viewingBigbitRelevantHC
            }

        updateViewingSnipbitRelevantHC : (Model.ViewingSnipbitRelevantHC -> Model.ViewingSnipbitRelevantHC) -> Model
        updateViewingSnipbitRelevantHC updater =
            { model
                | viewingSnipbitRelevantHC = Maybe.map updater model.viewingSnipbitRelevantHC
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

        updateViewStoryData : (ViewStoryData.ViewStoryData -> ViewStoryData.ViewStoryData) -> Model
        updateViewStoryData updater =
            { model
                | viewStoryData = updater model.viewStoryData
            }
    in
        case msg of
            NoOp ->
                doNothing

            -- Recieves route hits from the router and handles the logic of the
            -- route hooks.
            OnRouteHit ->
                let
                    getSnipbit mongoID =
                        ( { model
                            | viewingSnipbit = Nothing
                          }
                        , shared
                        , Api.getSnipbit mongoID OnGetSnipbitFailure OnGetSnipbitSuccess
                        )

                    -- If we already have the snipbit, renders, otherwise fetches
                    -- it from the db.
                    -- TODO ISSUE#99 Update to check cache if it is expired.
                    fetchOrRenderSnipbit mongoID =
                        let
                            currentTidbitPointer =
                                TidbitPointer.TidbitPointer
                                    TidbitPointer.Snipbit
                                    mongoID

                            ( newModel, newShared, newCmd ) =
                                case model.viewingSnipbit of
                                    Nothing ->
                                        getSnipbit mongoID

                                    Just snipbit ->
                                        if snipbit.id == mongoID then
                                            ( { model
                                                | viewingSnipbitRelevantHC = Nothing
                                              }
                                            , shared
                                            , createViewSnipbitCodeEditor snipbit shared
                                            )
                                        else
                                            getSnipbit mongoID

                            getSnipbitIsCompleted userID =
                                Api.postCheckCompleted (Completed.Completed currentTidbitPointer userID) ViewSnipbitGetCompletedFailure ViewSnipbitGetCompletedSuccess
                        in
                            ( newModel
                            , newShared
                            , Cmd.batch
                                [ newCmd
                                , case ( shared.user, model.viewingSnipbitIsCompleted ) of
                                    ( Just user, Nothing ) ->
                                        getSnipbitIsCompleted user.id

                                    ( Just user, Just currentCompleted ) ->
                                        if currentCompleted.tidbitPointer == currentTidbitPointer then
                                            Cmd.none
                                        else
                                            getSnipbitIsCompleted user.id

                                    _ ->
                                        Cmd.none
                                ]
                            )

                    getBigbit mongoID =
                        ( { model
                            | viewingBigbit = Nothing
                          }
                        , shared
                        , Api.getBigbit mongoID OnGetBigbitFailure OnGetBigbitSuccess
                        )

                    -- If we already have the bigbit, renders, otherwise fetches
                    -- it from the db.
                    -- TODO ISSUE#99 Update to check cache if it is expired.
                    fetchOrRenderBigbit mongoID =
                        let
                            currentTidbitPointer =
                                TidbitPointer.TidbitPointer
                                    TidbitPointer.Bigbit
                                    mongoID

                            -- Handle getting bigbit if needed.
                            ( newModel, newShared, newCmd ) =
                                case model.viewingBigbit of
                                    Nothing ->
                                        getBigbit mongoID

                                    Just bigbit ->
                                        if bigbit.id == mongoID then
                                            ( { model
                                                | viewingBigbitRelevantHC = Nothing
                                              }
                                            , shared
                                            , createViewBigbitCodeEditor bigbit shared
                                            )
                                        else
                                            getBigbit mongoID

                            -- Command for fetching the `isCompleted`
                            getBigbitIsCompleted userID =
                                Api.postCheckCompleted (Completed.Completed currentTidbitPointer userID) ViewBigbitGetCompletedFailure ViewBigbitGetCompletedSuccess
                        in
                            ( newModel
                            , newShared
                            , Cmd.batch
                                [ newCmd
                                  -- Handle getting bigbitCompleted if needed.
                                , case ( shared.user, model.viewingBigbitIsCompleted ) of
                                    -- CONTINUE
                                    ( Just user, Just currentCompleted ) ->
                                        if currentCompleted.tidbitPointer == currentTidbitPointer then
                                            Cmd.none
                                        else
                                            getBigbitIsCompleted user.id

                                    ( Just user, Nothing ) ->
                                        getBigbitIsCompleted user.id

                                    _ ->
                                        Cmd.none
                                ]
                            )

                    -- TODO ISSUE#99 Update to check cache if it is expired.
                    fetchOrRenderStory mongoID =
                        ( model
                        , shared
                        , Cmd.batch
                            [ smoothScrollToSubBar
                            , Api.getExpandedStory mongoID ViewStoryGetExpandedStoryFailure ViewStoryGetExpandedStorySuccess
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
                        ( model
                        , shared
                        , Util.domFocus (\_ -> NoOp) theID
                        )

                    -- If the ID of the current editingStory is different, we
                    -- need to get the info of the story that we are editing.
                    -- TODO ISSUE#99 Update to check cache if it is expired.
                    getEditingStoryAndFocusOn theID qpEditingStory =
                        ( model
                        , shared
                        , Cmd.batch
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
                        )
                in
                    case shared.route of
                        Route.HomeComponentCreate ->
                            case shared.user of
                                -- Should never happen.
                                Nothing ->
                                    doNothing

                                Just user ->
                                    if Util.isNothing shared.userStories then
                                        ( model
                                        , shared
                                        , Api.getStories
                                            [ ( "author", Just user.id ) ]
                                            GetAccountStoriesFailure
                                            GetAccountStoriesSuccess
                                        )
                                    else
                                        doNothing

                        Route.HomeComponentViewSnipbitIntroduction mongoID ->
                            fetchOrRenderSnipbit mongoID

                        Route.HomeComponentViewSnipbitFrame mongoID _ ->
                            fetchOrRenderSnipbit mongoID

                        Route.HomeComponentViewSnipbitConclusion mongoID ->
                            let
                                ( newModel, newShared, newCmd ) =
                                    fetchOrRenderSnipbit mongoID
                            in
                                ( newModel
                                , newShared
                                , Cmd.batch
                                    [ newCmd
                                    , case ( newShared.user, model.viewingSnipbitIsCompleted ) of
                                        ( Just user, Just isCompleted ) ->
                                            let
                                                completed =
                                                    Completed.completedFromIsCompleted isCompleted user.id
                                            in
                                                if isCompleted.complete == False then
                                                    Api.wrapPostAddCompleted completed ViewSnipbitMarkAsCompleteFailure ViewSnipbitMarkAsCompleteSuccess
                                                else
                                                    Cmd.none

                                        _ ->
                                            Cmd.none
                                    ]
                                )

                        Route.HomeComponentViewBigbitIntroduction mongoID _ ->
                            fetchOrRenderBigbit mongoID

                        Route.HomeComponentViewBigbitFrame mongoID _ _ ->
                            fetchOrRenderBigbit mongoID

                        Route.HomeComponentViewBigbitConclusion mongoID _ ->
                            let
                                ( newModel, newShared, newCmd ) =
                                    fetchOrRenderBigbit mongoID
                            in
                                ( newModel
                                , newShared
                                , Cmd.batch
                                    [ newCmd
                                    , case ( newShared.user, model.viewingBigbitIsCompleted ) of
                                        ( Just user, Just isCompleted ) ->
                                            let
                                                completed =
                                                    Completed.completedFromIsCompleted isCompleted user.id
                                            in
                                                if isCompleted.complete == False then
                                                    Api.wrapPostAddCompleted completed ViewBigbitMarkAsCompleteFailure ViewBigbitMarkAsCompleteSuccess
                                                else
                                                    Cmd.none

                                        _ ->
                                            Cmd.none
                                    ]
                                )

                        Route.HomeComponentViewStory mongoID ->
                            fetchOrRenderStory mongoID

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
                            ( model
                            , shared
                            , Cmd.batch
                                [ createCreateSnipbitEditor Nothing
                                , Util.domFocus (\_ -> NoOp) "introduction-input"
                                ]
                            )

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
                                    ( model
                                    , shared
                                    , Route.modifyTo
                                        Route.HomeComponentCreateSnipbitCodeIntroduction
                                    )
                                else if frameIndexTooHigh then
                                    ( model
                                    , shared
                                    , Route.modifyTo
                                        Route.HomeComponentCreateSnipbitCodeConclusion
                                    )
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
                            ( model
                            , shared
                            , Cmd.batch
                                [ createCreateSnipbitEditor Nothing
                                , Util.domFocus (\_ -> NoOp) "conclusion-input"
                                ]
                            )

                        Route.HomeComponentCreateBigbitCodeIntroduction maybeFilePath ->
                            ( model
                            , shared
                            , Cmd.batch
                                [ createCreateBigbitEditorForCurrentFile
                                    Nothing
                                    maybeFilePath
                                    (Route.HomeComponentCreateBigbitCodeIntroduction Nothing)
                                , Util.domFocus (\_ -> NoOp) "introduction-input"
                                ]
                            )

                        Route.HomeComponentCreateBigbitCodeFrame frameNumber maybeFilePath ->
                            if frameNumber < 1 then
                                ( model, shared, Route.modifyTo <| Route.HomeComponentCreateBigbitCodeIntroduction Nothing )
                            else if frameNumber > (Array.length currentBigbitHighlightedComments) then
                                ( model, shared, Route.modifyTo <| Route.HomeComponentCreateBigbitCodeConclusion Nothing )
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
                            ( model
                            , shared
                            , Cmd.batch
                                [ createCreateBigbitEditorForCurrentFile
                                    Nothing
                                    maybeFilePath
                                    (Route.HomeComponentCreateBigbitCodeConclusion Nothing)
                                , Util.domFocus (\_ -> NoOp) "conclusion-input"
                                ]
                            )

                        Route.HomeComponentCreateNewStoryName qpEditingStory ->
                            getEditingStoryAndFocusOn "name-input" qpEditingStory

                        Route.HomeComponentCreateNewStoryDescription qpEditingStory ->
                            getEditingStoryAndFocusOn "description-input" qpEditingStory

                        Route.HomeComponentCreateNewStoryTags qpEditingStory ->
                            getEditingStoryAndFocusOn "tags-input" qpEditingStory

                        Route.HomeComponentCreateStory storyID ->
                            let
                                -- Handle logic for getting story if not loaded.
                                ( newModel, _, newCmd ) =
                                    if maybeMapWithDefault (.id >> ((==) storyID)) False model.storyData.currentStory then
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
                            in
                                ( newModel
                                , shared
                                , Cmd.batch
                                    [ newCmd
                                    , case ( Util.isNothing shared.userTidbits, shared.user ) of
                                        ( True, Just user ) ->
                                            Api.getTidbits [ ( "forUser", Just user.id ) ] CreateStoryGetTidbitsFailure CreateStoryGetTidbitsSuccess

                                        _ ->
                                            Cmd.none
                                    , Ports.doScrolling { querySelector = "#story-tidbits-title", duration = 750, extraScroll = -60 }
                                    ]
                                )

                        _ ->
                            doNothing

            GoTo route ->
                ( model
                , shared
                , Route.navigateTo route
                )

            LogOut ->
                ( model, shared, Api.getLogOut OnLogOutFailure OnLogOutSuccess )

            OnLogOutFailure apiError ->
                let
                    newModel =
                        { model
                            | logOutError = Just apiError
                        }
                in
                    ( newModel, shared, Cmd.none )

            OnLogOutSuccess basicResponse ->
                ( HomeInit.init
                , defaultShared
                , Route.navigateTo Route.WelcomeComponentRegister
                )

            ShowInfoFor maybeTidbitType ->
                ( { model | showInfoFor = maybeTidbitType }, shared, Cmd.none )

            SnipbitGoToCodeTab ->
                ( updateSnipbitCreateData
                    { currentSnipbitCreateData
                        | previewMarkdown = False
                    }
                , shared
                , Route.navigateTo Route.HomeComponentCreateSnipbitCodeIntroduction
                )

            SnipbitUpdateLanguageQuery newLanguageQuery ->
                let
                    newSnipbitCreateData =
                        { currentSnipbitCreateData
                            | languageQuery = newLanguageQuery
                        }
                in
                    ( updateSnipbitCreateData newSnipbitCreateData
                    , shared
                    , Cmd.none
                    )

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
                            ( newModel, shared, Cmd.none )

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
                    ( newModel, shared, Cmd.none )

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
                                    >> Decode.decodeString Editor.languageCacheDecoder
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
                let
                    newSnipbitCreateData =
                        { currentSnipbitCreateData
                            | name = newName
                        }

                    newModel =
                        updateSnipbitCreateData newSnipbitCreateData
                in
                    ( newModel, shared, Cmd.none )

            SnipbitUpdateDescription newDescription ->
                let
                    newSnipbitCreateData =
                        { currentSnipbitCreateData
                            | description = newDescription
                        }

                    newModel =
                        updateSnipbitCreateData newSnipbitCreateData
                in
                    ( newModel, shared, Cmd.none )

            SnipbitUpdateTagInput newTagInput ->
                if String.endsWith " " newTagInput then
                    let
                        newTag =
                            String.dropRight 1 newTagInput

                        newTags =
                            if
                                String.isEmpty newTag
                                    || List.member
                                        newTag
                                        currentSnipbitCreateData.tags
                            then
                                currentSnipbitCreateData.tags
                            else
                                currentSnipbitCreateData.tags ++ [ newTag ]

                        newSnipbitCreateData =
                            { currentSnipbitCreateData
                                | tagInput = ""
                                , tags = newTags
                            }

                        newModel =
                            updateSnipbitCreateData newSnipbitCreateData
                    in
                        ( newModel, shared, Cmd.none )
                else
                    let
                        newSnipbitCreateData =
                            { currentSnipbitCreateData
                                | tagInput = newTagInput
                            }

                        newModel =
                            updateSnipbitCreateData newSnipbitCreateData
                    in
                        ( newModel, shared, Cmd.none )

            SnipbitRemoveTag tagName ->
                let
                    newTags =
                        List.filter
                            (\aTag -> aTag /= tagName)
                            currentSnipbitCreateData.tags

                    newSnipbitCreateData =
                        { currentSnipbitCreateData
                            | tags = newTags
                        }

                    newModel =
                        updateSnipbitCreateData newSnipbitCreateData
                in
                    ( newModel, shared, Cmd.none )

            SnipbitAddTag tagName ->
                let
                    newTags =
                        if
                            String.isEmpty tagName
                                || List.member
                                    tagName
                                    currentSnipbitCreateData.tags
                        then
                            currentSnipbitCreateData.tags
                        else
                            currentSnipbitCreateData.tags ++ [ tagName ]

                    newSnipbitCreateData =
                        { currentSnipbitCreateData
                            | tags = newTags
                            , tagInput = ""
                        }

                    newModel =
                        updateSnipbitCreateData newSnipbitCreateData
                in
                    ( newModel, shared, Cmd.none )

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

                                        newModel =
                                            updateSnipbitCreateData
                                                { currentSnipbitCreateData
                                                    | highlightedComments = newHighlightedComments
                                                }
                                    in
                                        ( newModel, shared, Cmd.none )

                    -- Should never really happen (highlighting when not on
                    -- the editor pages).
                    _ ->
                        doNothing

            SnipbitTogglePreviewMarkdown ->
                ( updateSnipbitCreateData <|
                    togglePreviewMarkdown currentSnipbitCreateData
                , shared
                , Cmd.none
                )

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

                    newSnipbitCreateData =
                        { currentSnipbitCreateData
                            | highlightedComments =
                                newHighlightedComments
                        }

                    newModel =
                        updateSnipbitCreateData newSnipbitCreateData

                    result =
                        ( newModel, shared, Cmd.none )
                in
                    case shared.route of
                        Route.HomeComponentCreateSnipbitCodeIntroduction ->
                            result

                        Route.HomeComponentCreateSnipbitCodeConclusion ->
                            result

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
                                    result

                        -- Should never happen.
                        _ ->
                            result

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

                            newSnipbitCreateData =
                                { currentSnipbitCreateData
                                    | highlightedComments = newHighlightedComments
                                }

                            newModel =
                                updateSnipbitCreateData newSnipbitCreateData
                        in
                            ( newModel, shared, Cmd.none )

            SnipbitUpdateIntroduction newIntro ->
                let
                    newSnipbitCreateData =
                        { currentSnipbitCreateData
                            | introduction = newIntro
                        }

                    newModel =
                        updateSnipbitCreateData newSnipbitCreateData
                in
                    ( newModel, shared, Cmd.none )

            SnipbitUpdateConclusion newConclusion ->
                let
                    newSnipbitCreateData =
                        { currentSnipbitCreateData
                            | conclusion = newConclusion
                        }

                    newModel =
                        updateSnipbitCreateData newSnipbitCreateData
                in
                    ( newModel, shared, Cmd.none )

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
                                                    Range.getNewRangeAfterDelta currentCode newCode action deltaRange aRange
                                        }
                            )
                            currentHighlightedComments

                    newSnipbitCreateData =
                        { currentSnipbitCreateData
                            | code = newCode
                            , highlightedComments = newHighlightedComments
                        }

                    newModel =
                        updateSnipbitCreateData newSnipbitCreateData
                in
                    ( newModel, shared, Cmd.none )

            SnipbitPublish snipbit ->
                ( model
                , shared
                , Api.postCreateSnipbit
                    snipbit
                    OnSnipbitPublishFailure
                    OnSnipbitPublishSuccess
                )

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
                , Route.navigateTo <| Route.HomeComponentViewSnipbitIntroduction targetID
                )

            OnSnipbitPublishFailure apiError ->
                -- TODO Handle Publish Failures.
                doNothing

            OnGetSnipbitFailure apiFailure ->
                -- TODO Handle get snipbit failure.
                doNothing

            OnGetSnipbitSuccess snipbit ->
                ( { model
                    | viewingSnipbit = Just snipbit
                    , viewingSnipbitRelevantHC = Nothing
                  }
                , shared
                , createViewSnipbitCodeEditor snipbit shared
                )

            ViewSnipbitRangeSelected selectedRange ->
                case model.viewingSnipbit of
                    Nothing ->
                        doNothing

                    Just aSnipbit ->
                        if Range.isEmptyRange selectedRange then
                            ( { model
                                | viewingSnipbitRelevantHC = Nothing
                              }
                            , shared
                            , Cmd.none
                            )
                        else
                            aSnipbit.highlightedComments
                                |> Array.indexedMap (,)
                                |> Array.filter (Tuple.second >> .range >> (Range.overlappingRanges selectedRange))
                                |> (\relevantHC ->
                                        ( { model
                                            | viewingSnipbitRelevantHC =
                                                Just
                                                    { currentHC = Nothing
                                                    , relevantHC =
                                                        relevantHC
                                                    }
                                          }
                                        , shared
                                        , Cmd.none
                                        )
                                   )

            ViewSnipbitBrowseRelevantHC ->
                let
                    newModel =
                        updateViewingSnipbitRelevantHC
                            (\currentRelevantHC ->
                                { currentRelevantHC
                                    | currentHC = Just 0
                                }
                            )
                in
                    ( newModel
                    , shared
                    , createViewSnipbitHCCodeEditor newModel.viewingSnipbit newModel.viewingSnipbitRelevantHC shared.user
                    )

            ViewSnipbitCancelBrowseRelevantHC ->
                ( { model
                    | viewingSnipbitRelevantHC = Nothing
                  }
                , shared
                  -- Trigger route hook again, `modify` because we don't want to
                  -- have the same page twice in the history.
                , Route.modifyTo shared.route
                )

            ViewSnipbitNextRelevantHC ->
                let
                    newModel =
                        updateViewingSnipbitRelevantHC Model.viewerRelevantHCGoToNextFrame
                in
                    ( newModel
                    , shared
                    , createViewSnipbitHCCodeEditor newModel.viewingSnipbit newModel.viewingSnipbitRelevantHC shared.user
                    )

            ViewSnipbitPreviousRelevantHC ->
                let
                    newModel =
                        updateViewingSnipbitRelevantHC Model.viewerRelevantHCGoToPreviousFrame
                in
                    ( newModel
                    , shared
                    , createViewSnipbitHCCodeEditor newModel.viewingSnipbit newModel.viewingSnipbitRelevantHC shared.user
                    )

            ViewSnipbitJumpToFrame route ->
                ( { model
                    | viewingSnipbitRelevantHC = Nothing
                  }
                , shared
                , Route.navigateTo route
                )

            ViewSnipbitGetCompletedSuccess isCompleted ->
                ( { model
                    | viewingSnipbitIsCompleted = Just isCompleted
                  }
                , shared
                , Cmd.none
                )

            ViewSnipbitGetCompletedFailure apiError ->
                -- TODO handle error.
                doNothing

            ViewSnipbitMarkAsComplete completed ->
                ( model
                , shared
                , Api.wrapPostAddCompleted completed ViewSnipbitMarkAsCompleteFailure ViewSnipbitMarkAsCompleteSuccess
                )

            ViewSnipbitMarkAsCompleteSuccess isCompleted ->
                ( { model
                    | viewingSnipbitIsCompleted = Just isCompleted
                  }
                , shared
                , Cmd.none
                )

            ViewSnipbitMarkAsCompleteFailure apiError ->
                -- TODO handle error.
                doNothing

            ViewSnipbitMarkAsIncomplete completed ->
                ( model
                , shared
                , Api.wrapPostRemoveCompleted completed ViewSnipbitMarkAsIncompleteFailure ViewSnipbitMarkAsIncompleteSuccess
                )

            ViewSnipbitMarkAsIncompleteSuccess isCompleted ->
                ( { model
                    | viewingSnipbitIsCompleted = Just isCompleted
                  }
                , shared
                , Cmd.none
                )

            ViewSnipbitMarkAsIncompleteFailure apiError ->
                -- TODO handle error.
                doNothing

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
                ( updateBigbitCreateData <|
                    { currentBigbitCreateData
                        | name = newName
                    }
                , shared
                , Cmd.none
                )

            BigbitUpdateDescription newDescription ->
                ( updateBigbitCreateData <|
                    { currentBigbitCreateData
                        | description = newDescription
                    }
                , shared
                , Cmd.none
                )

            BigbitUpdateTagInput newTagInput ->
                if String.endsWith " " newTagInput then
                    let
                        newTag =
                            String.dropRight 1 newTagInput

                        newTags =
                            if
                                String.isEmpty newTag
                                    || List.member
                                        newTag
                                        currentBigbitCreateData.tags
                            then
                                currentBigbitCreateData.tags
                            else
                                currentBigbitCreateData.tags ++ [ newTag ]
                    in
                        ( updateBigbitCreateData
                            { currentBigbitCreateData
                                | tags = newTags
                                , tagInput = ""
                            }
                        , shared
                        , Cmd.none
                        )
                else
                    ( updateBigbitCreateData
                        { currentBigbitCreateData
                            | tagInput = newTagInput
                        }
                    , shared
                    , Cmd.none
                    )

            BigbitAddTag tagName ->
                let
                    newTags =
                        if
                            String.isEmpty tagName
                                || List.member
                                    tagName
                                    currentBigbitCreateData.tags
                        then
                            currentBigbitCreateData.tags
                        else
                            currentBigbitCreateData.tags ++ [ tagName ]
                in
                    ( updateBigbitCreateData
                        { currentBigbitCreateData
                            | tags = newTags
                            , tagInput = ""
                        }
                    , shared
                    , Cmd.none
                    )

            BigbitRemoveTag tagName ->
                let
                    newTags =
                        List.filter
                            (\tag -> tag /= tagName)
                            currentBigbitCreateData.tags
                in
                    ( updateBigbitCreateData
                        { currentBigbitCreateData
                            | tags = newTags
                        }
                    , shared
                    , Cmd.none
                    )

            BigbitUpdateIntroduction newIntro ->
                ( updateBigbitCreateData
                    { currentBigbitCreateData
                        | introduction = newIntro
                    }
                , shared
                , Cmd.none
                )

            BigbitUpdateConclusion newConclusion ->
                ( updateBigbitCreateData
                    { currentBigbitCreateData
                        | conclusion = newConclusion
                    }
                , shared
                , Cmd.none
                )

            BigbitToggleFS ->
                ( updateBigbitCreateData
                    { currentBigbitCreateData
                        | fs = Bigbit.toggleFS currentBigbitCreateData.fs
                    }
                , shared
                , Cmd.none
                )

            BigbitFSToggleFolder folderPath ->
                ( updateBigbitCreateData
                    { currentBigbitCreateData
                        | fs = Bigbit.toggleFSFolder folderPath currentBigbitCreateData.fs
                    }
                , shared
                , Cmd.none
                )

            BigbitTogglePreviewMarkdown ->
                ( updateBigbitCreateData <|
                    togglePreviewMarkdown currentBigbitCreateData
                , shared
                , Cmd.none
                )

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
                ( updateBigbitCreateData
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
                , shared
                , Cmd.none
                )

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
                ( updateBigbitCreateData
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
                , shared
                , Cmd.none
                )

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
                            ( updateBigbitCreateData
                                { currentBigbitCreateData
                                    | fs = newFS
                                    , highlightedComments = newHC
                                }
                            , shared
                            , Cmd.none
                            )

            BigbitFileSelected absolutePath ->
                ( model
                , shared
                , Route.navigateToSameUrlWithFilePath (Just absolutePath) shared.route
                )

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
                            ( updateBigbitCreateData
                                { currentBigbitCreateData
                                    | highlightedComments = newHighlightedComments
                                }
                            , shared
                            , Cmd.none
                            )

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
                                        ( updateBigbitCreateData
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
                                        , shared
                                        , Cmd.none
                                        )

                    _ ->
                        doNothing

            BigbitPublish bigbit ->
                ( model
                , shared
                , Api.postCreateBigbit
                    bigbit
                    OnBigbitPublishFailure
                    OnBigbitPublishSuccess
                )

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
                        , Route.modifyTo <| Route.HomeComponentCreateBigbitCodeFrame frameNumber (Just filePath)
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
                , Route.navigateTo <| Route.HomeComponentViewBigbitIntroduction targetID Nothing
                )

            OnGetBigbitFailure apiError ->
                -- TODO handle get bigbit failure.
                doNothing

            OnGetBigbitSuccess bigbit ->
                ( { model
                    | viewingBigbit = Just bigbit
                    , viewingBigbitRelevantHC = Nothing
                  }
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
                    ( { model
                        | viewingBigbit =
                            updateViewingBigbitReturningBigbit
                                (\currentViewingBigbit ->
                                    { currentViewingBigbit
                                        | fs = Bigbit.toggleFS currentViewingBigbit.fs
                                    }
                                )
                        , viewingBigbitRelevantHC = Nothing
                      }
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
                ( model
                , shared
                , Route.navigateToSameUrlWithFilePath (Just absolutePath) shared.route
                )

            ViewBigbitToggleFolder absolutePath ->
                ( updateViewingBigbit
                    (\currentViewingBigbit ->
                        { currentViewingBigbit
                            | fs =
                                Bigbit.toggleFSFolder absolutePath currentViewingBigbit.fs
                        }
                    )
                , shared
                , Cmd.none
                )

            ViewBigbitRangeSelected selectedRange ->
                case model.viewingBigbit of
                    Nothing ->
                        doNothing

                    Just aBigbit ->
                        if Range.isEmptyRange selectedRange then
                            ( { model
                                | viewingBigbitRelevantHC = Nothing
                              }
                            , shared
                            , Cmd.none
                            )
                        else
                            aBigbit.highlightedComments
                                |> Array.indexedMap (,)
                                |> Array.filter
                                    (\hc ->
                                        (Tuple.second hc |> .range |> Range.overlappingRanges selectedRange)
                                            && (Tuple.second hc |> .file |> Just |> (==) (Bigbit.viewPageCurrentActiveFile shared.route aBigbit))
                                    )
                                |> (\relevantHC ->
                                        ( { model
                                            | viewingBigbitRelevantHC =
                                                Just
                                                    { currentHC = Nothing
                                                    , relevantHC = relevantHC
                                                    }
                                          }
                                        , shared
                                        , Cmd.none
                                        )
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
                in
                    ( newModel
                    , shared
                    , createViewBigbitHCCodeEditor
                        newModel.viewingBigbit
                        newModel.viewingBigbitRelevantHC
                        shared.user
                    )

            ViewBigbitCancelBrowseRelevantHC ->
                ( { model
                    | viewingBigbitRelevantHC = Nothing
                  }
                , shared
                  -- Trigger route hook again, `modify` because we don't want to
                  -- have the same page twice in the history.
                , Route.modifyTo shared.route
                )

            ViewBigbitNextRelevantHC ->
                let
                    newModel =
                        updateViewingBigbitRelevantHC Model.viewerRelevantHCGoToNextFrame
                in
                    ( newModel
                    , shared
                    , createViewBigbitHCCodeEditor newModel.viewingBigbit newModel.viewingBigbitRelevantHC shared.user
                    )

            ViewBigbitPreviousRelevantHC ->
                let
                    newModel =
                        updateViewingBigbitRelevantHC Model.viewerRelevantHCGoToPreviousFrame
                in
                    ( newModel
                    , shared
                    , createViewBigbitHCCodeEditor newModel.viewingBigbit newModel.viewingBigbitRelevantHC shared.user
                    )

            ViewBigbitJumpToFrame route ->
                ( { model
                    | viewingBigbitRelevantHC = Nothing
                    , viewingBigbit =
                        updateViewingBigbitReturningBigbit
                            (\currentViewingBigbit ->
                                { currentViewingBigbit
                                    | fs = Bigbit.closeFS currentViewingBigbit.fs
                                }
                            )
                  }
                , shared
                , Route.navigateTo route
                )

            ViewBigbitGetCompletedSuccess isCompleted ->
                ( { model
                    | viewingBigbitIsCompleted = Just isCompleted
                  }
                , shared
                , Cmd.none
                )

            ViewBigbitGetCompletedFailure apiError ->
                -- TODO handle error.
                doNothing

            ViewBigbitMarkAsComplete completed ->
                ( model
                , shared
                , Api.wrapPostAddCompleted completed ViewBigbitMarkAsCompleteFailure ViewBigbitMarkAsCompleteSuccess
                )

            ViewBigbitMarkAsCompleteSuccess isCompleted ->
                ( { model
                    | viewingBigbitIsCompleted = Just isCompleted
                  }
                , shared
                , Cmd.none
                )

            ViewBigbitMarkAsCompleteFailure apiError ->
                -- TODO handle error.
                doNothing

            ViewBigbitMarkAsIncomplete completed ->
                ( model
                , shared
                , Api.wrapPostRemoveCompleted completed ViewBigbitMarkAsIncompleteFailure ViewBigbitMarkAsIncompleteSuccess
                )

            ViewBigbitMarkAsIncompleteSuccess isCompleted ->
                ( { model
                    | viewingBigbitIsCompleted = Just isCompleted
                  }
                , shared
                , Cmd.none
                )

            ViewBigbitMarkAsIncompleteFailure apiError ->
                -- TODO handle error.
                doNothing

            ViewStoryGetExpandedStoryFailure apiError ->
                -- TODO handle error.
                doNothing

            ViewStoryGetExpandedStorySuccess expandedStory ->
                ( updateViewStoryData <|
                    ViewStoryData.setCurrentStory (Just expandedStory)
                , shared
                , Cmd.none
                )

            ProfileCancelEditName ->
                let
                    newModel =
                        updateProfileData ProfileData.cancelEditingName
                in
                    ( newModel, shared, Cmd.none )

            ProfileUpdateName originalName newName ->
                let
                    newModel =
                        updateProfileData (ProfileData.setName originalName newName)
                in
                    ( newModel, shared, Cmd.none )

            ProfileSaveEditName ->
                case model.profileData.accountName of
                    Nothing ->
                        doNothing

                    Just editableName ->
                        ( model
                        , shared
                        , Api.postUpdateUser
                            { defaultUserUpdateRecord
                                | name = Just <| Editable.getBuffer editableName
                            }
                            ProfileSaveNameFailure
                            ProfileSaveNameSuccess
                        )

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
                let
                    newModel =
                        updateProfileData ProfileData.cancelEditingBio
                in
                    ( newModel, shared, Cmd.none )

            ProfileUpdateBio originalBio newBio ->
                let
                    newModel =
                        updateProfileData (ProfileData.setBio originalBio newBio)
                in
                    ( newModel, shared, Cmd.none )

            ProfileSaveEditBio ->
                case model.profileData.accountBio of
                    Nothing ->
                        doNothing

                    Just editableBio ->
                        ( model
                        , shared
                        , Api.postUpdateUser
                            { defaultUserUpdateRecord
                                | bio = Just <| Editable.getBuffer editableBio
                            }
                            ProfileSaveBioFailure
                            ProfileSaveBioSuccess
                        )

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
                ( model
                , { shared
                    | userStories = Just userStories
                  }
                , Cmd.none
                )

            NewStoryUpdateName isEditing newName ->
                if isEditing then
                    ( updateNewStoryData <| NewStoryData.updateEditName newName
                    , shared
                    , Cmd.none
                    )
                else
                    ( updateNewStoryData <| NewStoryData.updateName newName
                    , shared
                    , Cmd.none
                    )

            NewStoryUpdateDescription isEditing newDescription ->
                if isEditing then
                    ( updateNewStoryData <| NewStoryData.updateEditDescription newDescription
                    , shared
                    , Cmd.none
                    )
                else
                    ( updateNewStoryData <| NewStoryData.updateDescription newDescription
                    , shared
                    , Cmd.none
                    )

            NewStoryUpdateTagInput isEditing newTagInput ->
                if isEditing then
                    ( updateNewStoryData <| NewStoryData.updateEditTagInput newTagInput
                    , shared
                    , Cmd.none
                    )
                else
                    ( updateNewStoryData <| NewStoryData.updateTagInput newTagInput
                    , shared
                    , Cmd.none
                    )

            NewStoryAddTag isEditing tagName ->
                if isEditing then
                    ( updateNewStoryData <| NewStoryData.newEditTag tagName
                    , shared
                    , Cmd.none
                    )
                else
                    ( updateNewStoryData <| NewStoryData.newTag tagName
                    , shared
                    , Cmd.none
                    )

            NewStoryRemoveTag isEditing tagName ->
                if isEditing then
                    ( updateNewStoryData <| NewStoryData.removeEditTag tagName
                    , shared
                    , Cmd.none
                    )
                else
                    ( updateNewStoryData <| NewStoryData.removeTag tagName
                    , shared
                    , Cmd.none
                    )

            NewStoryReset ->
                ( updateNewStoryData <| always NewStoryData.defaultNewStoryData
                , shared
                  -- The reset button only exists when there is no `qpEditingStory`.
                , Route.navigateTo <| Route.HomeComponentCreateNewStoryName Nothing
                )

            NewStoryPublish ->
                if NewStoryData.newStoryDataReadyForPublication model.newStoryData then
                    ( model
                    , shared
                    , Api.postCreateNewStory model.newStoryData.newStory NewStoryPublishFailure NewStoryPublishSuccess
                    )
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
                            ( updateNewStoryData <|
                                NewStoryData.updateEditStory (always story)
                            , shared
                            , Cmd.none
                            )
                        else
                            ( model
                            , shared
                            , Route.modifyTo <| Route.HomeComponentCreate
                            )

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
                    ( model
                    , shared
                    , Api.postUpdateStoryInformation storyID editingStoryInformation NewStorySaveEditsFailure NewStorySaveEditsSuccess
                    )

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
                ( model
                , { shared
                    | userTidbits = Just tidbits
                  }
                , Cmd.none
                )

            CreateStoryAddTidbit tidbit ->
                ( updateStoryData <|
                    StoryData.addTidbit tidbit
                , shared
                , Cmd.none
                )

            CreateStoryRemoveTidbit tidbit ->
                ( updateStoryData <|
                    StoryData.removeTidbit tidbit
                , shared
                , Cmd.none
                )

            CreateStoryPublishAddedTidbits storyID tidbits ->
                if List.length tidbits > 0 then
                    ( model
                    , shared
                    , Api.postAddTidbitsToStory storyID (List.map Tidbit.compressTidbit tidbits) CreateStoryPublishAddedTidbitsFailure (CreateStoryGetStorySuccess True)
                    )
                else
                    -- Should never happen.
                    doNothing

            CreateStoryPublishAddedTidbitsFailure apiError ->
                -- TODO handle error.
                doNothing

            CreateStoryToggleShowAllStories ->
                ( updateStoryData <|
                    (\storyData ->
                        { storyData
                            | showAllStories = not storyData.showAllStories
                        }
                    )
                , shared
                , Cmd.none
                )


{-| Creates the code editor for the bigbit when browsing relevant HC.

This will only create the editor if the state of the model (the `Maybe`s) makes
it appropriate to render the editor.
-}
createViewBigbitHCCodeEditor : Maybe Bigbit.Bigbit -> Maybe Model.ViewingBigbitRelevantHC -> Maybe User.User -> Cmd msg
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
createViewSnipbitHCCodeEditor : Maybe Snipbit.Snipbit -> Maybe Model.ViewingSnipbitRelevantHC -> Maybe User.User -> Cmd msg
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
                Route.HomeComponentViewSnipbitIntroduction _ ->
                    editorWithRange Nothing

                Route.HomeComponentViewSnipbitConclusion _ ->
                    editorWithRange Nothing

                Route.HomeComponentViewSnipbitFrame mongoID frameNumber ->
                    if frameNumber > Array.length snipbit.highlightedComments then
                        Route.modifyTo <|
                            Route.HomeComponentViewSnipbitConclusion mongoID
                    else if frameNumber < 1 then
                        Route.modifyTo <|
                            Route.HomeComponentViewSnipbitIntroduction mongoID
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

        loadFileWithNoHighlight maybePath =
            case maybePath of
                Nothing ->
                    blankEditor

                Just somePath ->
                    case FS.getFile bigbit.fs somePath of
                        Nothing ->
                            Route.modifyTo <| Route.HomeComponentViewBigbitIntroduction bigbit.id Nothing

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
                Route.HomeComponentViewBigbitIntroduction mongoID maybePath ->
                    loadFileWithNoHighlight maybePath

                Route.HomeComponentViewBigbitFrame mongoID frameNumber maybePath ->
                    case Array.get (frameNumber - 1) bigbit.highlightedComments of
                        Nothing ->
                            if frameNumber > (Array.length bigbit.highlightedComments) then
                                Route.modifyTo <| Route.HomeComponentViewBigbitConclusion bigbit.id Nothing
                            else
                                Route.modifyTo <| Route.HomeComponentViewBigbitIntroduction bigbit.id Nothing

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
                                    loadFileWithNoHighlight maybePath

                Route.HomeComponentViewBigbitConclusion mongoID maybePath ->
                    loadFileWithNoHighlight maybePath

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
    Ports.doScrolling { querySelector = ".invisible-bottom", duration = 750, extraScroll = 0 }


{-| Smooth-scrolls to the subbar, effectively hiding the top navbar.
-}
smoothScrollToSubBar : Cmd msg
smoothScrollToSubBar =
    Ports.doScrolling { querySelector = ".sub-bar", duration = 750, extraScroll = 0 }
