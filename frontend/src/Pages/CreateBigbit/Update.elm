module Pages.CreateBigbit.Update exposing (..)

import Array
import DefaultServices.CommonSubPageUtil exposing (CommonSubPageUtil(..), commonSubPageUtil)
import DefaultServices.TextFields as TextFields
import DefaultServices.Util as Util exposing (maybeMapWithDefault, togglePreviewMarkdown)
import Dict
import Elements.Simple.Editor as Editor
import Elements.Simple.FileStructure as FS
import Models.Bigbit as Bigbit
import Models.Range as Range
import Models.RequestTracker as RT
import Models.Route as Route exposing (createBigbitPageCurrentActiveFile)
import Models.User as User
import Pages.CreateBigbit.Init exposing (..)
import Pages.CreateBigbit.Messages exposing (..)
import Pages.CreateBigbit.Model exposing (..)
import Pages.Model exposing (Shared)
import Ports


{-| `CreateBigbit` update.
-}
update : CommonSubPageUtil Model Shared Msg -> Msg -> Model -> Shared -> ( Model, Shared, Cmd Msg )
update (Common common) msg model shared =
    let
        currentBigbitHighlightedComments =
            model.highlightedComments

        focusOn =
            Util.domFocus (always NoOp)

        focusOnActionInputBox =
            focusOn "fs-action-input-box"
    in
    case msg of
        NoOp ->
            common.doNothing

        GoTo route ->
            common.justProduceCmd <| Route.navigateTo route

        OnRouteHit route ->
            let
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
                                    , useMarker = True -- Doesn't matter, no range.
                                    , readOnly = True
                                    , selectAllowed = True
                                    }

                            Just filePath ->
                                case FS.getFile model.fs filePath of
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
                                            , useMarker = False
                                            , readOnly = model.codeLocked
                                            , selectAllowed = True
                                            }
                        , Ports.smoothScrollToBottom
                        ]
            in
            case route of
                Route.CreateBigbitNamePage ->
                    ( resetConfirmState model, shared, focusOn "name-input" )

                Route.CreateBigbitDescriptionPage ->
                    ( resetConfirmState model, shared, focusOn "description-input" )

                Route.CreateBigbitTagsPage ->
                    ( resetConfirmState model, shared, focusOn "tags-input" )

                Route.CreateBigbitCodeFramePage frameNumber maybeFilePath ->
                    if frameNumber < 1 then
                        ( resetConfirmState model
                        , shared
                        , Route.modifyTo <| Route.CreateBigbitCodeFramePage 1 Nothing
                        )
                    else if frameNumber > Array.length currentBigbitHighlightedComments then
                        ( resetConfirmState model
                        , shared
                        , Route.modifyTo <|
                            Route.CreateBigbitCodeFramePage (Array.length currentBigbitHighlightedComments) Nothing
                        )
                    else
                        let
                            -- Update the HC if the route has a file path.
                            hcUpdaterIfOnFilePath currentHighlightedComment filePath =
                                case currentHighlightedComment.fileAndRange of
                                    -- Brand new frame, attempting to use range of previous frame.
                                    Nothing ->
                                        { currentHighlightedComment
                                            | fileAndRange =
                                                Just
                                                    { range =
                                                        case previousFrameRange model shared.route of
                                                            Nothing ->
                                                                Nothing

                                                            Just ( prevFilePath, range ) ->
                                                                if FS.isSameFilePath filePath prevFilePath then
                                                                    Just <| Range.collapseRange range
                                                                else
                                                                    Nothing
                                                    , file = filePath
                                                    }
                                        }

                                    -- Refreshed/changed file path for current frame.
                                    Just fileAndRange ->
                                        if FS.isSameFilePath fileAndRange.file filePath then
                                            currentHighlightedComment
                                        else
                                            { currentHighlightedComment
                                                | fileAndRange = Just { range = Nothing, file = filePath }
                                            }

                            -- Update the HC depending on the `maybeFilePath`.
                            hcUpdater currentHighlightedComment =
                                case maybeFilePath of
                                    Nothing ->
                                        { currentHighlightedComment | fileAndRange = Nothing }

                                    Just filePath ->
                                        hcUpdaterIfOnFilePath currentHighlightedComment filePath

                            newModel =
                                updateHCAtIndex model (frameNumber - 1) hcUpdater
                                    |> resetConfirmState

                            maybeRangeToHighlight =
                                Array.get (frameNumber - 1) newModel.highlightedComments
                                    |> Maybe.andThen .fileAndRange
                                    |> Maybe.andThen .range
                        in
                        ( newModel
                        , shared
                        , Cmd.batch
                            [ createCreateBigbitEditorForCurrentFile
                                maybeRangeToHighlight
                                maybeFilePath
                                (Route.CreateBigbitCodeFramePage frameNumber Nothing)
                            , focusOn "frame-input"
                            ]
                        )

                _ ->
                    common.doNothing

        -- Update the code and also check if any ranges are out of range and update those ranges.
        OnUpdateCode { newCode, action, deltaRange } ->
            case createBigbitPageCurrentActiveFile shared.route of
                Nothing ->
                    common.doNothing

                Just filePath ->
                    let
                        currentCode =
                            FS.getFile model.fs filePath
                                |> maybeMapWithDefault (\(FS.File content _) -> content) ""

                        newFS =
                            model.fs
                                |> FS.updateFile
                                    filePath
                                    (\(FS.File content fileMetadata) -> FS.File newCode fileMetadata)

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
                    common.justSetModel
                        { model
                            | fs = newFS
                            , highlightedComments = newHC
                        }

        OnRangeSelected newRange ->
            case shared.route of
                Route.CreateBigbitCodeFramePage frameNumber currentPath ->
                    case Array.get (frameNumber - 1) currentBigbitHighlightedComments of
                        Nothing ->
                            common.doNothing

                        Just highlightedComment ->
                            case highlightedComment.fileAndRange of
                                Nothing ->
                                    common.doNothing

                                Just fileAndRange ->
                                    common.justSetModel
                                        { model
                                            | highlightedComments =
                                                Array.set
                                                    (frameNumber - 1)
                                                    { highlightedComment
                                                        | fileAndRange =
                                                            Just { fileAndRange | range = Just newRange }
                                                    }
                                                    currentBigbitHighlightedComments
                                        }

                _ ->
                    common.doNothing

        GoToCodeTab ->
            ( { model | previewMarkdown = False }
            , shared
            , Route.navigateTo <| Route.CreateBigbitCodeFramePage 1 Nothing
            )

        Reset ->
            if model.confirmedReset then
                ( init
                , { shared | textFieldKeyTracker = TextFields.changeKey shared.textFieldKeyTracker "create-bigbit-name" }
                , Route.navigateTo Route.CreateBigbitNamePage
                )
            else
                common.justSetModel { model | confirmedReset = True }

        AddFrame ->
            let
                currentPath =
                    createBigbitPageCurrentActiveFile shared.route

                newModel =
                    { model
                        | highlightedComments =
                            Array.push emptyHighlightCommentForCreate currentBigbitHighlightedComments
                        , confirmedRemoveFrame = False
                    }

                newCmd =
                    Route.navigateTo <|
                        Route.CreateBigbitCodeFramePage (Array.length newModel.highlightedComments) currentPath
            in
            ( newModel, shared, newCmd )

        RemoveFrame ->
            if Array.length currentBigbitHighlightedComments == 1 then
                common.doNothing
            else if not model.confirmedRemoveFrame then
                common.justSetModel { model | confirmedRemoveFrame = True }
            else
                let
                    newHighlightedComments =
                        Array.slice
                            0
                            (Array.length currentBigbitHighlightedComments - 1)
                            currentBigbitHighlightedComments

                    newModel =
                        { model | highlightedComments = newHighlightedComments, confirmedRemoveFrame = False }

                    -- Have to make sure if they are on the last frame it pushes them down one frame.
                    newRoute =
                        case shared.route of
                            Route.CreateBigbitCodeFramePage frameNumber filePath ->
                                Just <|
                                    Route.CreateBigbitCodeFramePage
                                        (if frameNumber == Array.length currentBigbitHighlightedComments then
                                            frameNumber - 1
                                         else
                                            frameNumber
                                        )
                                        filePath

                            _ ->
                                Nothing

                    newCmd =
                        maybeMapWithDefault Route.modifyTo Cmd.none newRoute
                in
                ( newModel, shared, newCmd )

        ToggleFS ->
            common.justSetModel { model | fs = Bigbit.toggleFS model.fs }

        ToggleFolder folderPath ->
            common.justSetModel { model | fs = Bigbit.toggleFSFolder folderPath model.fs }

        SelectFile absolutePath ->
            common.justProduceCmd <| Route.navigateToSameUrlWithFilePath (Just absolutePath) shared.route

        TogglePreviewMarkdown ->
            common.justUpdateModel togglePreviewMarkdown

        AddFile absolutePath language ->
            ( { model
                | fs =
                    model.fs
                        |> FS.addFile
                            { overwriteExisting = False
                            , forceCreateDirectories = Just <| always defaultEmptyFolder
                            }
                            absolutePath
                            (FS.emptyFile { language = language })
                        |> clearActionButtonInput
              }
            , { shared
                | textFieldKeyTracker =
                    TextFields.changeKey
                        shared.textFieldKeyTracker
                        "create-bigbit-fs-action-input-box"
              }
            , focusOnActionInputBox
            )

        JumpToLineFromPreviousFrame filePath ->
            case shared.route of
                Route.CreateBigbitCodeFramePage frameNumber _ ->
                    ( updateHCAtIndex
                        model
                        (frameNumber - 1)
                        (\hcAtIndex -> { hcAtIndex | fileAndRange = Nothing })
                    , shared
                    , Route.modifyTo <| Route.CreateBigbitCodeFramePage frameNumber (Just filePath)
                    )

                _ ->
                    common.doNothing

        OnUpdateName newName ->
            common.justSetModel { model | name = newName }

        OnUpdateDescription newDescription ->
            common.justSetModel { model | description = newDescription }

        OnUpdateTagInput newTagInput ->
            common.justSetModel { model | tagInput = newTagInput }

        AddTag tagName ->
            ( { model
                | tags = Util.addUniqueNonEmptyString tagName model.tags
                , tagInput = ""
              }
            , { shared | textFieldKeyTracker = TextFields.changeKey shared.textFieldKeyTracker "create-bigbit-tags" }
            , focusOn "tags-input"
            )

        RemoveTag tagName ->
            common.justSetModel { model | tags = List.filter (\tag -> tag /= tagName) model.tags }

        OnUpdateFrameComment frameNumber newComment ->
            case Array.get (frameNumber - 1) currentBigbitHighlightedComments of
                Nothing ->
                    common.doNothing

                Just highlightedComment ->
                    common.justSetModel
                        { model
                            | highlightedComments =
                                Array.set
                                    (frameNumber - 1)
                                    { highlightedComment | comment = newComment }
                                    currentBigbitHighlightedComments
                        }

        UpdateActionButtonState newActionState ->
            ( { model
                | fs =
                    model.fs
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
            , focusOn "fs-action-input-box"
            )

        OnUpdateActionInput newActionButtonInput ->
            common.justSetModel
                { model
                    | fs =
                        model.fs
                            |> FS.updateFSMetadata
                                (\currentMetadata ->
                                    { currentMetadata
                                        | actionButtonInput = newActionButtonInput
                                        , actionButtonSubmitConfirmed = False
                                    }
                                )
                }

        SubmitActionInput ->
            let
                fs =
                    model.fs

                absolutePath =
                    fs
                        |> FS.getFSMetadata
                        |> .actionButtonInput

                maybeCurrentActionState =
                    fs
                        |> FS.getFSMetadata
                        |> .actionButtonState

                {- Filters the highlighted comments to make sure non of them point to non-existant files. Used
                   when removing files/folders.

                   NOTE: If all comments are filtered out, adds a blank one because we always want at least one
                         comment.
                -}
                getNewHighlightedComments hc newFS =
                    Array.filter
                        (\hc ->
                            case hc.fileAndRange of
                                Nothing ->
                                    True

                                Just { file, range } ->
                                    FS.hasFile file newFS
                        )
                        currentBigbitHighlightedComments
                        |> (\remainingArray ->
                                if Array.length remainingArray == 0 then
                                    Array.fromList
                                        [ emptyHighlightCommentForCreate ]
                                else
                                    remainingArray
                           )

                {- After removing files/folders the current URL can become invalid, this function redirects to
                   the first frame if needed.
                -}
                navigateIfRouteNowInvalid newFS newHighlightedComments =
                    let
                        redirectToFirstFrame =
                            Route.modifyTo <| Route.CreateBigbitCodeFramePage 1 Nothing

                        redirectIfFileRemoved =
                            case createBigbitPageCurrentActiveFile shared.route of
                                Nothing ->
                                    Cmd.none

                                Just filePath ->
                                    if FS.hasFile filePath newFS then
                                        Cmd.none
                                    else
                                        redirectToFirstFrame
                    in
                    case shared.route of
                        Route.CreateBigbitCodeFramePage frameNumber _ ->
                            if frameNumber > Array.length newHighlightedComments then
                                redirectToFirstFrame
                            else
                                redirectIfFileRemoved

                        _ ->
                            redirectIfFileRemoved

                sharedWithTextFieldKeyChanged =
                    { shared
                        | textFieldKeyTracker =
                            TextFields.changeKey
                                shared.textFieldKeyTracker
                                "create-bigbit-fs-action-input-box"
                    }
            in
            case maybeCurrentActionState of
                -- Should never happen.
                Nothing ->
                    common.doNothing

                Just currentActionState ->
                    case currentActionState of
                        AddingFile ->
                            case isValidAddFileInput absolutePath fs of
                                Err _ ->
                                    common.doNothing

                                Ok language ->
                                    update
                                        (commonSubPageUtil model shared)
                                        (AddFile absolutePath language)
                                        model
                                        shared

                        AddingFolder ->
                            case isValidAddFolderInput absolutePath fs of
                                Err _ ->
                                    common.doNothing

                                Ok _ ->
                                    ( { model
                                        | fs =
                                            fs
                                                |> FS.addFolder
                                                    { overwriteExisting = False
                                                    , forceCreateDirectories =
                                                        Just <| always defaultEmptyFolder
                                                    }
                                                    absolutePath
                                                    (FS.Folder Dict.empty Dict.empty { isExpanded = True })
                                                |> clearActionButtonInput
                                      }
                                    , sharedWithTextFieldKeyChanged
                                    , focusOnActionInputBox
                                    )

                        RemovingFile ->
                            case isValidRemoveFileInput absolutePath fs of
                                Err _ ->
                                    common.doNothing

                                Ok _ ->
                                    if .actionButtonSubmitConfirmed <| FS.getFSMetadata fs then
                                        let
                                            newFS =
                                                fs
                                                    |> FS.removeFile absolutePath
                                                    |> clearActionButtonInput

                                            newHighlightedComments =
                                                getNewHighlightedComments
                                                    currentBigbitHighlightedComments
                                                    newFS
                                        in
                                        ( { model
                                            | fs = newFS
                                            , highlightedComments = newHighlightedComments
                                          }
                                        , sharedWithTextFieldKeyChanged
                                        , Cmd.batch
                                            [ navigateIfRouteNowInvalid newFS newHighlightedComments
                                            , focusOnActionInputBox
                                            ]
                                        )
                                    else
                                        common.justSetModel { model | fs = fs |> setActionButtonSubmitConfirmed True }

                        RemovingFolder ->
                            case isValidRemoveFolderInput absolutePath fs of
                                Err _ ->
                                    common.doNothing

                                Ok _ ->
                                    if .actionButtonSubmitConfirmed <| FS.getFSMetadata fs then
                                        let
                                            newFS =
                                                fs
                                                    |> FS.removeFolder absolutePath
                                                    |> clearActionButtonInput

                                            newHighlightedComments =
                                                getNewHighlightedComments
                                                    currentBigbitHighlightedComments
                                                    newFS
                                        in
                                        ( { model
                                            | fs = newFS
                                            , highlightedComments = newHighlightedComments
                                          }
                                        , sharedWithTextFieldKeyChanged
                                        , Cmd.batch
                                            [ navigateIfRouteNowInvalid newFS newHighlightedComments
                                            , focusOnActionInputBox
                                            ]
                                        )
                                    else
                                        common.justSetModel { model | fs = fs |> setActionButtonSubmitConfirmed True }

        Publish bigbit ->
            let
                publishBigbitAction =
                    common.justProduceCmd <| common.api.post.createBigbit bigbit OnPublishFailure OnPublishSuccess
            in
            common.makeSingletonRequest RT.PublishBigbit publishBigbitAction

        OnPublishSuccess { targetID } ->
            ( init
            , { shared | userTidbits = Nothing }
            , Route.navigateTo <| Route.ViewBigbitFramePage Nothing targetID 1 Nothing
            )
                |> common.andFinishRequest RT.PublishBigbit

        OnPublishFailure apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest RT.PublishBigbit

        ToggleLockCode ->
            ( { model | codeLocked = not model.codeLocked }, shared, Route.modifyTo shared.route )
