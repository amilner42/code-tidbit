module Pages.CreateBigbit.Update exposing (..)

import Api
import Array
import DefaultServices.Util as Util exposing (maybeMapWithDefault, togglePreviewMarkdown)
import Dict
import Elements.Editor as Editor
import Elements.FileStructure as FS
import Models.Bigbit as Bigbit
import Models.Range as Range
import Models.Route as Route exposing (createBigbitPageCurrentActiveFile)
import Models.User as User
import Pages.CreateBigbit.Init exposing (..)
import Pages.CreateBigbit.Messages exposing (..)
import Pages.CreateBigbit.Model exposing (..)
import Pages.Model exposing (Shared)
import Ports


{-| `CreateBigbit` update.
-}
update : Msg -> Model -> Shared -> ( Model, Shared, Cmd Msg )
update msg model shared =
    let
        doNothing =
            ( model, shared, Cmd.none )

        justUpdateModel modelUpdater =
            ( modelUpdater model, shared, Cmd.none )

        justSetModel newModel =
            ( newModel, shared, Cmd.none )

        justUpdateShared newShared =
            ( model, newShared, Cmd.none )

        justProduceCmd cmd =
            ( model, shared, cmd )

        withCmd : Cmd Msg -> ( Model, Shared, Cmd Msg ) -> ( Model, Shared, Cmd Msg )
        withCmd withCmd ( newModel, newShared, newCmd ) =
            ( newModel, newShared, Cmd.batch [ newCmd, withCmd ] )

        currentBigbitHighlightedComments =
            model.highlightedComments
    in
        case msg of
            NoOp ->
                doNothing

            GoTo route ->
                justProduceCmd <| Route.navigateTo route

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
                                                , readOnly = False
                                                , selectAllowed = True
                                                }
                            , Ports.smoothScrollToBottom
                            ]

                    focusOn theID =
                        justProduceCmd <| Util.domFocus (\_ -> NoOp) theID
                in
                    case route of
                        Route.CreateBigbitNamePage ->
                            focusOn "name-input"

                        Route.CreateBigbitDescriptionPage ->
                            focusOn "description-input"

                        Route.CreateBigbitTagsPage ->
                            focusOn "tags-input"

                        Route.CreateBigbitCodeIntroductionPage maybeFilePath ->
                            justProduceCmd <|
                                Cmd.batch
                                    [ createCreateBigbitEditorForCurrentFile
                                        Nothing
                                        maybeFilePath
                                        (Route.CreateBigbitCodeIntroductionPage Nothing)
                                    , Util.domFocus (\_ -> NoOp) "introduction-input"
                                    ]

                        Route.CreateBigbitCodeFramePage frameNumber maybeFilePath ->
                            if frameNumber < 1 then
                                justProduceCmd <| Route.modifyTo <| Route.CreateBigbitCodeIntroductionPage Nothing
                            else if frameNumber > (Array.length currentBigbitHighlightedComments) then
                                justProduceCmd <| Route.modifyTo <| Route.CreateBigbitCodeConclusionPage Nothing
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
                                        , Util.domFocus (\_ -> NoOp) "frame-input"
                                        ]
                                    )

                        Route.CreateBigbitCodeConclusionPage maybeFilePath ->
                            justProduceCmd <|
                                Cmd.batch
                                    [ createCreateBigbitEditorForCurrentFile
                                        Nothing
                                        maybeFilePath
                                        (Route.CreateBigbitCodeConclusionPage Nothing)
                                    , Util.domFocus (\_ -> NoOp) "conclusion-input"
                                    ]

                        _ ->
                            doNothing

            -- Update the code and also check if any ranges are out of range and update those ranges.
            OnUpdateCode { newCode, action, deltaRange } ->
                case createBigbitPageCurrentActiveFile shared.route of
                    Nothing ->
                        doNothing

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
                            justSetModel
                                { model
                                    | fs = newFS
                                    , highlightedComments = newHC
                                }

            OnRangeSelected newRange ->
                case shared.route of
                    Route.CreateBigbitCodeFramePage frameNumber currentPath ->
                        case Array.get (frameNumber - 1) currentBigbitHighlightedComments of
                            Nothing ->
                                doNothing

                            Just highlightedComment ->
                                case highlightedComment.fileAndRange of
                                    Nothing ->
                                        doNothing

                                    Just fileAndRange ->
                                        justSetModel
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
                        doNothing

            GoToCodeTab ->
                ( { model
                    | previewMarkdown = False
                    , fs = model.fs |> FS.updateFSMetadata (\fsMetadata -> { fsMetadata | openFS = False })
                  }
                , shared
                , Route.navigateTo <| Route.CreateBigbitCodeIntroductionPage Nothing
                )

            Reset ->
                ( init
                , shared
                , Route.navigateTo Route.CreateBigbitNamePage
                )

            AddFrame ->
                let
                    currentPath =
                        createBigbitPageCurrentActiveFile shared.route

                    newModel =
                        { model
                            | highlightedComments =
                                Array.push emptyHighlightCommentForCreate currentBigbitHighlightedComments
                        }

                    newCmd =
                        Route.navigateTo <|
                            Route.CreateBigbitCodeFramePage (Array.length newModel.highlightedComments) currentPath
                in
                    ( newModel, shared, newCmd )

            RemoveFrame ->
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
                            { model | highlightedComments = newHighlightedComments }

                        -- Have to make sure if they are on the last frame it pushes them down one frame.
                        newRoute =
                            case shared.route of
                                Route.CreateBigbitCodeFramePage frameNumber filePath ->
                                    Just <|
                                        Route.CreateBigbitCodeFramePage
                                            (if frameNumber == (Array.length currentBigbitHighlightedComments) then
                                                (frameNumber - 1)
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
                justSetModel { model | fs = Bigbit.toggleFS model.fs }

            ToggleFolder folderPath ->
                justSetModel { model | fs = Bigbit.toggleFSFolder folderPath model.fs }

            SelectFile absolutePath ->
                justProduceCmd <| Route.navigateToSameUrlWithFilePath (Just absolutePath) shared.route

            TogglePreviewMarkdown ->
                justUpdateModel togglePreviewMarkdown

            AddFile absolutePath language ->
                justSetModel <|
                    { model
                        | fs =
                            model.fs
                                |> (FS.addFile
                                        { overwriteExisting = False
                                        , forceCreateDirectories = Just <| always defaultEmptyFolder
                                        }
                                        absolutePath
                                        (FS.emptyFile { language = language })
                                   )
                                |> clearActionButtonInput
                    }

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
                        doNothing

            OnUpdateName newName ->
                justSetModel { model | name = newName }

            OnUpdateDescription newDescription ->
                justSetModel { model | description = newDescription }

            OnUpdateTagInput newTagInput ->
                if String.endsWith " " newTagInput then
                    let
                        newTag =
                            String.dropRight 1 newTagInput

                        newTags =
                            Util.addUniqueNonEmptyString newTag model.tags
                    in
                        justSetModel
                            { model
                                | tags = newTags
                                , tagInput = ""
                            }
                else
                    justSetModel { model | tagInput = newTagInput }

            AddTag tagName ->
                justSetModel
                    { model
                        | tags = Util.addUniqueNonEmptyString tagName model.tags
                        , tagInput = ""
                    }

            RemoveTag tagName ->
                justSetModel { model | tags = List.filter (\tag -> tag /= tagName) model.tags }

            OnUpdateIntroduction newIntro ->
                justSetModel { model | introduction = newIntro }

            OnUpdateFrameComment frameNumber newComment ->
                case Array.get (frameNumber - 1) currentBigbitHighlightedComments of
                    Nothing ->
                        doNothing

                    Just highlightedComment ->
                        justSetModel
                            { model
                                | highlightedComments =
                                    Array.set
                                        (frameNumber - 1)
                                        { highlightedComment | comment = newComment }
                                        currentBigbitHighlightedComments
                            }

            OnUpdateConclusion newConclusion ->
                justSetModel { model | conclusion = newConclusion }

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
                , Util.domFocus (always NoOp) "fs-action-input-box"
                )

            OnUpdateActionInput newActionButtonInput ->
                justSetModel
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
                                            [ emptyHighlightCommentForCreate ]
                                    else
                                        remainingArray
                               )

                    {- After removing files/folders the current URL can become invalid, this function redirects to
                       intro if needed.
                    -}
                    navigateIfRouteNowInvalid newFS newHighlightedComments =
                        let
                            redirectToIntro =
                                Route.modifyTo <| Route.CreateBigbitCodeIntroductionPage Nothing

                            redirectIfFileRemoved =
                                case createBigbitPageCurrentActiveFile shared.route of
                                    Nothing ->
                                        Cmd.none

                                    Just filePath ->
                                        if FS.hasFile filePath newFS then
                                            Cmd.none
                                        else
                                            redirectToIntro
                        in
                            case shared.route of
                                Route.CreateBigbitCodeFramePage frameNumber _ ->
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
                                    AddingFile ->
                                        case isValidAddFileInput absolutePath fs of
                                            Err _ ->
                                                ( model, Cmd.none )

                                            Ok language ->
                                                let
                                                    ( newModel, _, newCmd ) =
                                                        update (AddFile absolutePath language) model shared
                                                in
                                                    ( newModel, newCmd )

                                    AddingFolder ->
                                        case isValidAddFolderInput absolutePath fs of
                                            Err _ ->
                                                ( model, Cmd.none )

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
                                                , Cmd.none
                                                )

                                    RemovingFile ->
                                        case isValidRemoveFileInput absolutePath fs of
                                            Err _ ->
                                                ( model, Cmd.none )

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
                                                        , navigateIfRouteNowInvalid newFS newHighlightedComments
                                                        )
                                                else
                                                    ( { model | fs = fs |> setActionButtonSubmitConfirmed True }
                                                    , Cmd.none
                                                    )

                                    RemovingFolder ->
                                        case isValidRemoveFolderInput absolutePath fs of
                                            Err _ ->
                                                ( model, Cmd.none )

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
                                                        , navigateIfRouteNowInvalid newFS newHighlightedComments
                                                        )
                                                else
                                                    ( { model | fs = fs |> setActionButtonSubmitConfirmed True }
                                                    , Cmd.none
                                                    )
                in
                    ( newModel, shared, newCmd )

            Publish bigbit ->
                justProduceCmd <| Api.postCreateBigbit bigbit OnPublishFailure OnPublishSuccess

            OnPublishSuccess { targetID } ->
                ( init
                , { shared | userTidbits = Nothing }
                , Route.navigateTo <| Route.ViewBigbitIntroductionPage Nothing targetID Nothing
                )

            OnPublishFailure apiError ->
                -- TODO Handle bigbit publish failures.
                doNothing
