module Components.Home.Update exposing (update, filterLanguagesByQuery)

import Array
import Api
import Autocomplete as AC
import Components.Home.Init as HomeInit
import Components.Home.Messages exposing (Msg(..))
import Components.Home.Model exposing (Model)
import Components.Model exposing (Shared)
import Dom
import Dict
import DefaultModel exposing (defaultShared)
import DefaultServices.Util as Util
import Elements.Editor as Editor
import Json.Decode as Decode
import Models.Bigbit as Bigbit
import Elements.FileStructure as FS
import Models.Snipbit as Snipbit
import Models.Range as Range
import Models.Route as Route
import Models.User as User
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

                    getBigbit mongoID =
                        ( { model
                            | viewingBigbit = Nothing
                          }
                        , shared
                        , Api.getBigbit mongoID OnGetBigbitFailure OnGetBigbitSuccess
                        )

                    renderSnipbit codeEditorConfig =
                        ( model
                        , shared
                        , Ports.createCodeEditor codeEditorConfig
                        )

                    -- If we already have the bigbit, renders, otherwise fetches
                    -- it from the db.
                    fetchOrRenderBigbit mongoID =
                        case model.viewingBigbit of
                            Nothing ->
                                getBigbit mongoID

                            Just bigbit ->
                                if bigbit.id == mongoID then
                                    ( model
                                    , shared
                                    , createViewBigbitCodeEditor bigbit shared
                                    )
                                else
                                    getBigbit mongoID

                    createBigbitEditorForCurrentFile maybeRange maybeFilePath backupRoute =
                        case maybeFilePath of
                            Nothing ->
                                Ports.createCodeEditor
                                    { id = "create-bigbit-code-editor"
                                    , lang = ""
                                    , theme = User.getTheme shared.user
                                    , value = ""
                                    , range = Nothing
                                    , readOnly = True
                                    }

                            Just filePath ->
                                case FS.getFile currentBigbitCreateData.fs filePath of
                                    Nothing ->
                                        Route.navigateTo backupRoute

                                    Just (FS.File content { language }) ->
                                        Ports.createCodeEditor
                                            { id = "create-bigbit-code-editor"
                                            , lang = Editor.aceLanguageLocation language
                                            , theme = User.getTheme shared.user
                                            , value = content
                                            , range = maybeRange
                                            , readOnly = False
                                            }
                in
                    case shared.route of
                        Route.HomeComponentViewSnipbitIntroduction mongoID ->
                            case model.viewingSnipbit of
                                Nothing ->
                                    getSnipbit mongoID

                                Just aSnipbit ->
                                    if aSnipbit.id == mongoID then
                                        renderSnipbit
                                            { id = "view-snipbit-code-editor"
                                            , lang = Editor.aceLanguageLocation aSnipbit.language
                                            , theme = User.getTheme shared.user
                                            , value = aSnipbit.code
                                            , range = Nothing
                                            , readOnly = True
                                            }
                                    else
                                        getSnipbit mongoID

                        Route.HomeComponentViewSnipbitFrame mongoID frameNumber ->
                            case model.viewingSnipbit of
                                Nothing ->
                                    getSnipbit mongoID

                                Just aSnipbit ->
                                    if aSnipbit.id == mongoID then
                                        -- Make sure frame is in range, if not
                                        -- redirect to intro/conclusion depending
                                        -- on if it's beneath/above range respectively.
                                        if frameNumber - 1 >= Array.length aSnipbit.highlightedComments then
                                            ( model
                                            , shared
                                            , Route.navigateTo <|
                                                Route.HomeComponentViewSnipbitConclusion mongoID
                                            )
                                        else if frameNumber < 1 then
                                            ( model
                                            , shared
                                            , Route.navigateTo <|
                                                Route.HomeComponentViewSnipbitIntroduction mongoID
                                            )
                                        else
                                            renderSnipbit
                                                { id = "view-snipbit-code-editor"
                                                , lang = Editor.aceLanguageLocation aSnipbit.language
                                                , theme = User.getTheme shared.user
                                                , value = aSnipbit.code
                                                , range =
                                                    Array.get
                                                        (frameNumber - 1)
                                                        aSnipbit.highlightedComments
                                                        |> Maybe.map .range
                                                , readOnly = True
                                                }
                                    else
                                        getSnipbit mongoID

                        Route.HomeComponentViewSnipbitConclusion mongoID ->
                            case model.viewingSnipbit of
                                Nothing ->
                                    getSnipbit mongoID

                                Just aSnipbit ->
                                    if aSnipbit.id == mongoID then
                                        renderSnipbit
                                            { id = "view-snipbit-code-editor"
                                            , lang = Editor.aceLanguageLocation aSnipbit.language
                                            , theme = User.getTheme shared.user
                                            , value = aSnipbit.code
                                            , range = Nothing
                                            , readOnly = True
                                            }
                                    else
                                        getSnipbit mongoID

                        Route.HomeComponentViewBigbitIntroduction mongoID _ ->
                            fetchOrRenderBigbit mongoID

                        Route.HomeComponentViewBigbitFrame mongoID _ _ ->
                            fetchOrRenderBigbit mongoID

                        Route.HomeComponentViewBigbitConclusion mongoID _ ->
                            fetchOrRenderBigbit mongoID

                        Route.HomeComponentCreateBigbitCodeIntroduction maybeFilePath ->
                            ( model
                            , shared
                            , createBigbitEditorForCurrentFile Nothing maybeFilePath (Route.HomeComponentCreateBigbitCodeIntroduction Nothing)
                            )

                        Route.HomeComponentCreateBigbitCodeFrame frameNumber maybeFilePath ->
                            if frameNumber < 1 || frameNumber > (Array.length currentBigbitHighlightedComments) then
                                ( model, shared, Route.navigateTo <| Route.HomeComponentCreateBigbitCodeIntroduction Nothing )
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
                                                                                            { range = Nothing
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
                                    , createBigbitEditorForCurrentFile maybeRangeToHighlight maybeFilePath (Route.HomeComponentCreateBigbitCodeFrame frameNumber Nothing)
                                    )

                        Route.HomeComponentCreateBigbitCodeConclusion maybeFilePath ->
                            ( model
                            , shared
                            , createBigbitEditorForCurrentFile Nothing maybeFilePath (Route.HomeComponentCreateBigbitCodeConclusion Nothing)
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
                                toString aLanguage

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

                                        newSnipbitCreateData =
                                            { currentSnipbitCreateData
                                                | highlightedComments = newHighlightedComments
                                            }

                                        newModel =
                                            updateSnipbitCreateData
                                                newSnipbitCreateData
                                    in
                                        ( newModel, shared, Cmd.none )

                    -- Should never really happen (highlighting when not on
                    -- the editor pages).
                    _ ->
                        doNothing

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
            SnipbitUpdateCode newCode ->
                let
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
                                                    Range.newValidRange aRange newCode
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

            OnSnipbitPublishSuccess { newID } ->
                ( { model
                    | snipbitCreateData = .snipbitCreateData HomeInit.init
                  }
                , shared
                , Route.navigateTo <| Route.HomeComponentViewSnipbitIntroduction newID
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
                  }
                , shared
                , Ports.createCodeEditor
                    { id = "view-snipbit-code-editor"
                    , lang = Editor.aceLanguageLocation snipbit.language
                    , theme = User.getTheme shared.user
                    , value = snipbit.code
                    , range =
                        case shared.route of
                            Route.HomeComponentViewSnipbitFrame _ frameNumber ->
                                (Array.get
                                    (frameNumber - 1)
                                    snipbit.highlightedComments
                                )
                                    |> Maybe.map .range

                            _ ->
                                Nothing
                    , readOnly = True
                    }
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
                                Route.navigateTo <| Route.HomeComponentCreateBigbitCodeIntroduction Nothing

                            redirectIfFileRemoved =
                                case Bigbit.createPageCurrentActiveFile shared.route of
                                    Nothing ->
                                        Cmd.none

                                    Just filePath ->
                                        if FS.hasFile filePath newFS then
                                            Cmd.none
                                        else
                                            Route.navigateTo <|
                                                Route.HomeComponentCreateBigbitCodeIntroduction Nothing
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
            BigbitUpdateCode newCode ->
                case Bigbit.createPageCurrentActiveFile shared.route of
                    Nothing ->
                        doNothing

                    Just filePath ->
                        ( updateBigbitCreateData
                            { currentBigbitCreateData
                                | fs =
                                    currentBigbitCreateData.fs
                                        |> FS.updateFile
                                            filePath
                                            (\(FS.File content fileMetadata) ->
                                                FS.File
                                                    newCode
                                                    fileMetadata
                                            )
                                , highlightedComments =
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
                                                                            , range = Just <| Range.newValidRange aRange newCode
                                                                            }
                                                                }
                                                    else
                                                        comment
                                        )
                                        currentBigbitHighlightedComments
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
                            Maybe.map Route.navigateTo newRoute
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

            OnBigbitPublishFailure apiError ->
                -- TODO Handle bigbit publish failures.
                doNothing

            OnBigbitPublishSuccess { newID } ->
                ( { model
                    | bigbitCreateData = .bigbitCreateData HomeInit.init
                  }
                , shared
                , Route.navigateTo <| Route.HomeComponentViewBigbitIntroduction newID Nothing
                )

            OnGetBigbitFailure apiError ->
                -- TODO handle get bigbit failure.
                doNothing

            OnGetBigbitSuccess bigbit ->
                ( { model
                    | viewingBigbit = Just bigbit
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
                    ( updateViewingBigbit
                        (\currentViewingBigbit ->
                            { currentViewingBigbit
                                | fs = Bigbit.toggleFS currentViewingBigbit.fs
                            }
                        )
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


{-| Based on the maybePath and the bigbit creates the editor.

Will handle redirects if file path is invalid or frameNumber is invalid.
-}
createViewBigbitCodeEditor : Bigbit.Bigbit -> Shared -> Cmd msg
createViewBigbitCodeEditor bigbit { route, user } =
    let
        blankEditor =
            Ports.createCodeEditor
                { id = "view-bigbit-code-editor"
                , lang = ""
                , theme = User.getTheme user
                , value = ""
                , range = Nothing
                , readOnly = True
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
                                , lang = Editor.aceLanguageLocation language
                                , theme = User.getTheme user
                                , value = content
                                , range = Nothing
                                , readOnly = True
                                }
    in
        case route of
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
                                            , lang = Editor.aceLanguageLocation language
                                            , theme = User.getTheme user
                                            , value = content
                                            , range = Just hc.range
                                            , readOnly = True
                                            }

                            Just absolutePath ->
                                loadFileWithNoHighlight maybePath

            Route.HomeComponentViewBigbitConclusion mongoID maybePath ->
                loadFileWithNoHighlight maybePath

            _ ->
                Cmd.none


{-| Filters the languages based on `query`.
-}
filterLanguagesByQuery : String -> List ( Editor.Language, String ) -> List ( Editor.Language, String )
filterLanguagesByQuery query languages =
    List.filter
        (String.contains (String.toLower query) << Tuple.second)
        languages


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
