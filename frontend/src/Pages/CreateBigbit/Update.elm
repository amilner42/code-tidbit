module Pages.CreateBigbit.Update exposing (..)

import Array
import Api
import Dict
import DefaultServices.Util as Util exposing (maybeMapWithDefault, togglePreviewMarkdown)
import Elements.Editor as Editor
import Elements.FileStructure as FS
import Models.Bigbit as Bigbit
import Models.Range as Range
import Models.Route as Route
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

            -- Recieves route hits from the router and handles the logic of the
            -- route hooks.
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
                        justProduceCmd <|
                            Util.domFocus (\_ -> NoOp) theID
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
                                justProduceCmd <|
                                    Route.modifyTo <|
                                        Route.CreateBigbitCodeIntroductionPage Nothing
                            else if frameNumber > (Array.length currentBigbitHighlightedComments) then
                                justProduceCmd <|
                                    Route.modifyTo <|
                                        Route.CreateBigbitCodeConclusionPage Nothing
                            else
                                let
                                    newModel =
                                        case maybeFilePath of
                                            Nothing ->
                                                case Array.get (frameNumber - 1) currentBigbitHighlightedComments of
                                                    Nothing ->
                                                        model

                                                    Just currentHighlightedComment ->
                                                        { model
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
                                                        { model
                                                            | highlightedComments =
                                                                Array.set
                                                                    (frameNumber - 1)
                                                                    (case currentHighlightedComment.fileAndRange of
                                                                        Nothing ->
                                                                            { currentHighlightedComment
                                                                                | fileAndRange =
                                                                                    Just
                                                                                        { range =
                                                                                            case previousFrameRange model shared.route of
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

            GoTo route ->
                justProduceCmd <| Route.navigateTo route

            BigbitGoToCodeTab ->
                ( { model
                    | previewMarkdown = False
                    , fs =
                        model.fs
                            |> FS.updateFSMetadata
                                (\fsMetadata ->
                                    { fsMetadata
                                        | openFS = False
                                    }
                                )
                  }
                , shared
                , Route.navigateTo <| Route.CreateBigbitCodeIntroductionPage Nothing
                )

            BigbitReset ->
                ( init
                , shared
                , Route.navigateTo Route.CreateBigbitNamePage
                )

            BigbitUpdateName newName ->
                justSetModel <|
                    { model
                        | name = newName
                    }

            BigbitUpdateDescription newDescription ->
                justSetModel <|
                    { model
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
                                model.tags
                    in
                        justSetModel <|
                            { model
                                | tags = newTags
                                , tagInput = ""
                            }
                else
                    justSetModel <|
                        { model
                            | tagInput = newTagInput
                        }

            BigbitAddTag tagName ->
                let
                    newTags =
                        Util.addUniqueNonEmptyString
                            tagName
                            model.tags
                in
                    justSetModel <|
                        { model
                            | tags = newTags
                            , tagInput = ""
                        }

            BigbitRemoveTag tagName ->
                let
                    newTags =
                        List.filter
                            (\tag -> tag /= tagName)
                            model.tags
                in
                    justSetModel
                        { model
                            | tags = newTags
                        }

            BigbitUpdateIntroduction newIntro ->
                justSetModel
                    { model
                        | introduction = newIntro
                    }

            BigbitUpdateConclusion newConclusion ->
                justSetModel
                    { model
                        | conclusion = newConclusion
                    }

            BigbitToggleFS ->
                justSetModel
                    { model
                        | fs = Bigbit.toggleFS model.fs
                    }

            BigbitFSToggleFolder folderPath ->
                justSetModel
                    { model
                        | fs = Bigbit.toggleFSFolder folderPath model.fs
                    }

            BigbitTogglePreviewMarkdown ->
                justUpdateModel togglePreviewMarkdown

            BigbitUpdateActionButtonState newActionState ->
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

            BigbitUpdateActionInput newActionButtonInput ->
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

            BigbitSubmitActionInput ->
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
                                            [ emptyBigbitHighlightCommentForCreate ]
                                    else
                                        remainingArray
                               )

                    {- After removing files/folders the current URL can become
                       invalid, this function redirects to intro if needed.
                    -}
                    navigateIfRouteNowInvalid newFS newHighlightedComments =
                        let
                            redirectToIntro =
                                Route.modifyTo <| Route.CreateBigbitCodeIntroductionPage Nothing

                            redirectIfFileRemoved =
                                case createPageCurrentActiveFile shared.route of
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
                                                        update (BigbitAddFile absolutePath language) model shared
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
                                                                , forceCreateDirectories = Just <| always defaultEmptyFolder
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
                                                            getNewHighlightedComments currentBigbitHighlightedComments newFS
                                                    in
                                                        ( { model
                                                            | fs = newFS
                                                            , highlightedComments = newHighlightedComments
                                                          }
                                                        , navigateIfRouteNowInvalid newFS newHighlightedComments
                                                        )
                                                else
                                                    ( { model
                                                        | fs =
                                                            fs
                                                                |> setActionButtonSubmitConfirmed True
                                                      }
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
                                                            getNewHighlightedComments currentBigbitHighlightedComments newFS
                                                    in
                                                        ( { model
                                                            | fs = newFS
                                                            , highlightedComments = newHighlightedComments
                                                          }
                                                        , navigateIfRouteNowInvalid newFS newHighlightedComments
                                                        )
                                                else
                                                    ( { model
                                                        | fs =
                                                            fs
                                                                |> setActionButtonSubmitConfirmed True
                                                      }
                                                    , Cmd.none
                                                    )
                in
                    ( newModel
                    , shared
                    , newCmd
                    )

            BigbitAddFile absolutePath language ->
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

            -- Update the code and also check if any ranges are out of range
            -- and update those ranges.
            BigbitUpdateCode { newCode, action, deltaRange } ->
                case createPageCurrentActiveFile shared.route of
                    Nothing ->
                        doNothing

                    Just filePath ->
                        let
                            currentCode =
                                FS.getFile model.fs filePath
                                    |> maybeMapWithDefault
                                        (\(FS.File content _) ->
                                            content
                                        )
                                        ""

                            newFS =
                                model.fs
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
                            justSetModel <|
                                { model
                                    | fs = newFS
                                    , highlightedComments = newHC
                                }

            BigbitFileSelected absolutePath ->
                justProduceCmd <|
                    Route.navigateToSameUrlWithFilePath (Just absolutePath) shared.route

            BigbitAddFrame ->
                let
                    currentPath =
                        createPageCurrentActiveFile shared.route

                    newModel =
                        { model
                            | highlightedComments =
                                (Array.push
                                    emptyBigbitHighlightCommentForCreate
                                    currentBigbitHighlightedComments
                                )
                        }

                    newCmd =
                        Route.navigateTo <|
                            Route.CreateBigbitCodeFramePage
                                (Array.length newModel.highlightedComments)
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
                            { model
                                | highlightedComments = newHighlightedComments
                            }

                        -- Have to make sure if they are on the last frame it pushes
                        -- them down one frame.
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
                            justSetModel <|
                                { model
                                    | highlightedComments = newHighlightedComments
                                }

            BigbitNewRangeSelected newRange ->
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
                    Route.CreateBigbitCodeFramePage frameNumber _ ->
                        ( updateCreateDataHCAtIndex
                            model
                            (frameNumber - 1)
                            (\hcAtIndex ->
                                { hcAtIndex
                                    | fileAndRange = Nothing
                                }
                            )
                        , shared
                        , Route.modifyTo <|
                            Route.CreateBigbitCodeFramePage frameNumber (Just filePath)
                        )

                    _ ->
                        doNothing

            OnBigbitPublishFailure apiError ->
                -- TODO Handle bigbit publish failures.
                doNothing

            OnBigbitPublishSuccess { targetID } ->
                ( init
                , { shared
                    | userTidbits = Nothing
                  }
                , Route.navigateTo <|
                    Route.ViewBigbitIntroductionPage Nothing targetID Nothing
                )
