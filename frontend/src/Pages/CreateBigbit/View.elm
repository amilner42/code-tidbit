module Pages.CreateBigbit.View exposing (..)

import Array
import DefaultServices.TextFields as TextFields
import DefaultServices.Util as Util exposing (maybeMapWithDefault, togglePreviewMarkdown)
import Elements.Simple.Editor as Editor
import Elements.Simple.FileStructure as FS
import Elements.Simple.Tags as Tags
import ExplanatoryBlurbs exposing (markdownFramePlaceholder)
import Html exposing (Html, button, div, h1, h3, hr, i, img, text)
import Html.Attributes exposing (class, classList, defaultValue, disabled, hidden, id, placeholder, src, style)
import Html.Events exposing (onClick, onInput)
import Keyboard.Extra as KK
import Models.Bigbit as Bigbit
import Models.RequestTracker as RT
import Models.Route as Route exposing (createBigbitPageCurrentActiveFile)
import Pages.CreateBigbit.Messages exposing (..)
import Pages.CreateBigbit.Model exposing (..)
import Pages.Messages as BaseMessage
import Pages.Model exposing (Shared)


{-| `CreateBigbit` view.
-}
view : (Msg -> BaseMessage.Msg) -> Model -> Shared -> Html BaseMessage.Msg
view subMsg model shared =
    let
        currentRoute =
            shared.route

        fsOpen =
            Bigbit.isFSOpen model.fs

        {- It should be disabled unles everything is filled out. -}
        publishButton =
            case toPublicationData model of
                Nothing ->
                    button
                        [ class "create-bigbit-disabled-publish-button"
                        , disabled True
                        ]
                        [ text "Publish" ]

                Just bigbitForPublicaton ->
                    button
                        [ classList
                            [ ( "create-bigbit-publish-button", True )
                            , ( "cursor-progress", RT.isMakingRequest shared.apiRequestTracker RT.PublishBigbit )
                            ]
                        , onClick <| subMsg <| Publish bigbitForPublicaton
                        ]
                        [ text "Publish" ]

        createBigbitNavbar : Html BaseMessage.Msg
        createBigbitNavbar =
            div
                [ classList [ ( "create-tidbit-navbar", True ) ] ]
                [ div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
                          , currentRoute == Route.CreateBigbitNamePage
                          )
                        , ( "filled-in", Util.isNotNothing <| nameFilledIn model )
                        ]
                    , onClick <| BaseMessage.GoTo { wipeModalError = False } Route.CreateBigbitNamePage
                    ]
                    [ text "Name" ]
                , div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
                          , currentRoute == Route.CreateBigbitDescriptionPage
                          )
                        , ( "filled-in", Util.isNotNothing <| descriptionFilledIn model )
                        ]
                    , onClick <| BaseMessage.GoTo { wipeModalError = False } Route.CreateBigbitDescriptionPage
                    ]
                    [ text "Description" ]
                , div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
                          , currentRoute == Route.CreateBigbitTagsPage
                          )
                        , ( "filled-in", Util.isNotNothing <| tagsFilledIn model )
                        ]
                    , onClick <| BaseMessage.GoTo { wipeModalError = False } Route.CreateBigbitTagsPage
                    ]
                    [ text "Tags" ]
                , div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
                          , case currentRoute of
                                Route.CreateBigbitCodeFramePage _ _ ->
                                    True

                                _ ->
                                    False
                          )
                        , ( "filled-in", codeTabFilledIn model )
                        ]
                    , onClick <| subMsg <| GoToCodeTab
                    ]
                    [ text "Code" ]
                ]

        bigbitCodeTab =
            let
                currentActiveFile =
                    createBigbitPageCurrentActiveFile shared.route

                viewingFile absolutePath =
                    Maybe.map (FS.isSameFilePath absolutePath) currentActiveFile
                        |> Maybe.withDefault False

                frameTab =
                    case shared.route of
                        Route.CreateBigbitCodeFramePage frameNumber _ ->
                            Just frameNumber

                        _ ->
                            Nothing

                bigbitFS =
                    let
                        fsMetadata =
                            FS.getFSMetadata <| model.fs

                        maybeActionState =
                            fsMetadata.actionButtonState

                        actionInput =
                            fsMetadata.actionButtonInput

                        validFileInputResult =
                            isValidAddFileInput
                                actionInput
                                model.fs

                        validFileInput =
                            Util.resultToBool validFileInputResult

                        validRemoveFileInputResult =
                            isValidRemoveFileInput actionInput model.fs

                        validRemoveFileInput =
                            Util.resultToBool validRemoveFileInputResult

                        validRemoveFolderInputResult =
                            isValidRemoveFolderInput actionInput model.fs

                        validRemoveFolderInput =
                            Util.resultToBool validRemoveFolderInputResult

                        validFolderInputResult =
                            isValidAddFolderInput
                                actionInput
                                model.fs

                        validFolderInput =
                            Util.resultToBool validFolderInputResult

                        fs =
                            div
                                [ class "file-structure" ]
                                [ FS.view
                                    { isFileSelected = viewingFile
                                    , fileSelectedMsg = subMsg << SelectFile
                                    , folderSelectedMsg = subMsg << ToggleFolder
                                    }
                                    model.fs
                                , div
                                    [ class "fs-action-input"
                                    , hidden <| Util.isNothing <| maybeActionState
                                    ]
                                    [ div
                                        [ class "fs-action-input-text" ]
                                        [ case maybeActionState of
                                            Nothing ->
                                                Util.hiddenDiv

                                            Just actionState ->
                                                case actionState of
                                                    AddingFolder ->
                                                        case validFolderInputResult of
                                                            Ok _ ->
                                                                text "Create folder and parent directories"

                                                            Err err ->
                                                                text <|
                                                                    case err of
                                                                        FolderAlreadyExists ->
                                                                            "That folder already exists"

                                                                        FolderHasDoubleSlash ->
                                                                            "You cannot have two slashes in a row"

                                                                        FolderHasInvalidCharacters ->
                                                                            "You are using invalid characters"

                                                                        FolderIsEmpty ->
                                                                            ""

                                                    AddingFile ->
                                                        case validFileInputResult of
                                                            Ok _ ->
                                                                text "Create file and parent directories"

                                                            Err err ->
                                                                case err of
                                                                    FileAlreadyExists ->
                                                                        text "That file already exists"

                                                                    FileEndsInSlash ->
                                                                        text "Files cannot end in a slash"

                                                                    FileHasDoubleSlash ->
                                                                        text "You cannot have two slashes in a row"

                                                                    FileHasInvalidCharacters ->
                                                                        text "You are using invalid characters"

                                                                    FileHasInvalidExtension ->
                                                                        text "You must have a valid file extension"

                                                                    FileIsEmpty ->
                                                                        text ""

                                                                    FileLanguageIsAmbiguous languages ->
                                                                        div
                                                                            [ class "fs-action-input-select-language-text" ]
                                                                            [ text "Select language to create file: "
                                                                            , div
                                                                                [ class "language-options" ]
                                                                                (languages
                                                                                    |> List.sortBy toString
                                                                                    |> List.map
                                                                                        (\language ->
                                                                                            button
                                                                                                [ onClick <| subMsg <| AddFile actionInput language ]
                                                                                                [ text <| toString language ]
                                                                                        )
                                                                                )
                                                                            ]

                                                    RemovingFolder ->
                                                        case validRemoveFolderInputResult of
                                                            Ok _ ->
                                                                if .actionButtonSubmitConfirmed <| FS.getFSMetadata model.fs then
                                                                    text "Are you sure? This will also delete all linked frames!"
                                                                else
                                                                    text "Remove folder"

                                                            Err err ->
                                                                case err of
                                                                    RemoveFolderIsEmpty ->
                                                                        text ""

                                                                    RemoveFolderIsRootFolder ->
                                                                        text "You cannot remove the root directory"

                                                                    RemoveFolderDoesNotExist ->
                                                                        text "Folder doesn't exist"

                                                    RemovingFile ->
                                                        case validRemoveFileInputResult of
                                                            Ok _ ->
                                                                if .actionButtonSubmitConfirmed <| FS.getFSMetadata model.fs then
                                                                    text "Are you sure? This will also delete all linked frames!"
                                                                else
                                                                    text "Remove file"

                                                            Err err ->
                                                                case err of
                                                                    RemoveFileIsEmpty ->
                                                                        text ""

                                                                    RemoveFileDoesNotExist ->
                                                                        text "File doesn't exist"
                                        ]
                                    , TextFields.input
                                        shared.textFieldKeyTracker
                                        "create-bigbit-fs-action-input-box"
                                        [ id "fs-action-input-box"
                                        , placeholder "Absolute Path"
                                        , onInput <| subMsg << OnUpdateActionInput
                                        , Util.onKeydown
                                            (\key ->
                                                if key == KK.Enter then
                                                    Just <| subMsg SubmitActionInput
                                                else
                                                    Nothing
                                            )
                                        , defaultValue
                                            (model.fs
                                                |> FS.getFSMetadata
                                                |> .actionButtonInput
                                            )
                                        ]
                                    , case maybeActionState of
                                        Nothing ->
                                            Util.hiddenDiv

                                        Just actionState ->
                                            let
                                                showSubmitIconIf condition isPlus =
                                                    if condition then
                                                        i
                                                            [ classList
                                                                [ ( "material-icons action-button-submit-icon", True )
                                                                , ( "arrow-confirmed"
                                                                  , model.fs
                                                                        |> FS.getFSMetadata
                                                                        |> .actionButtonSubmitConfirmed
                                                                  )
                                                                ]
                                                            , onClick <| subMsg SubmitActionInput
                                                            ]
                                                            [ text <|
                                                                if isPlus then
                                                                    "add_box"
                                                                else
                                                                    "indeterminate_check_box"
                                                            ]
                                                    else
                                                        Util.hiddenDiv
                                            in
                                            case actionState of
                                                AddingFile ->
                                                    showSubmitIconIf validFileInput True

                                                AddingFolder ->
                                                    showSubmitIconIf validFolderInput True

                                                RemovingFile ->
                                                    showSubmitIconIf validRemoveFileInput False

                                                RemovingFolder ->
                                                    showSubmitIconIf validRemoveFolderInput False
                                    ]
                                , button
                                    [ classList
                                        [ ( "add-file", True )
                                        , ( "selected-action-button"
                                          , fsActionStateEquals (Just AddingFile) model.fs
                                          )
                                        ]
                                    , onClick <| subMsg <| UpdateActionButtonState <| Just AddingFile
                                    ]
                                    [ text "Add File" ]
                                , button
                                    [ classList
                                        [ ( "add-folder", True )
                                        , ( "selected-action-button"
                                          , fsActionStateEquals (Just AddingFolder) model.fs
                                          )
                                        ]
                                    , onClick <| subMsg <| UpdateActionButtonState <| Just AddingFolder
                                    ]
                                    [ text "Add Folder" ]
                                , button
                                    [ classList
                                        [ ( "remove-file", True )
                                        , ( "selected-action-button"
                                          , fsActionStateEquals (Just RemovingFile) model.fs
                                          )
                                        ]
                                    , onClick <| subMsg <| UpdateActionButtonState <| Just RemovingFile
                                    ]
                                    [ text "Remove File" ]
                                , button
                                    [ classList
                                        [ ( "remove-folder", True )
                                        , ( "selected-action-button"
                                          , fsActionStateEquals (Just RemovingFolder) model.fs
                                          )
                                        ]
                                    , onClick <| subMsg <| UpdateActionButtonState <| Just RemovingFolder
                                    ]
                                    [ text "Remove Folder" ]
                                ]
                    in
                    div
                        [ class "bigbit-fs" ]
                        [ div [ hidden <| not fsOpen ] [ fs ]
                        , i
                            [ classList
                                [ ( "close-fs material-icons", True )
                                , ( "hidden", not fsOpen )
                                ]
                            , onClick <| subMsg ToggleFS
                            ]
                            [ text "close" ]
                        ]

                bigbitEditor =
                    div
                        [ class "bigbit-editor" ]
                        [ div
                            [ class "current-file"
                            , onClick <|
                                if not fsOpen then
                                    subMsg ToggleFS
                                else
                                    BaseMessage.NoOp
                            ]
                            [ text <| Maybe.withDefault "No File Selected" currentActiveFile ]
                        , div
                            [ classList [ ( "lock-icon", True ), ( "hidden", Util.isNothing currentActiveFile ) ]
                            , onClick <| subMsg ToggleLockCode
                            ]
                            [ i [ class "material-icons" ]
                                [ text <|
                                    if model.codeLocked then
                                        "lock_outline"
                                    else
                                        "lock_open"
                                ]
                            ]
                        , div
                            [ class "create-tidbit-code" ]
                            [ Editor.view "create-bigbit-code-editor"
                            ]
                        ]

                bigbitCommentBox =
                    let
                        markdownOpen =
                            model.previewMarkdown

                        body =
                            div
                                [ class "comment-body" ]
                                [ div
                                    [ class "preview-markdown"
                                    , onClick <| subMsg TogglePreviewMarkdown
                                    ]
                                    [ if markdownOpen then
                                        text "Close Preview"
                                      else
                                        text "Preview Markdown"
                                    ]
                                , case shared.route of
                                    Route.CreateBigbitCodeFramePage frameNumber _ ->
                                        let
                                            frameText =
                                                Array.get
                                                    (frameNumber - 1)
                                                    model.highlightedComments
                                                    |> Maybe.map .comment
                                                    |> Maybe.withDefault ""
                                        in
                                        Util.markdownOr
                                            markdownOpen
                                            frameText
                                            (TextFields.textarea
                                                shared.textFieldKeyTracker
                                                ("create-bigbit-frame-" ++ toString frameNumber)
                                                [ placeholder <| markdownFramePlaceholder frameNumber
                                                , id "frame-input"
                                                , onInput <| subMsg << OnUpdateFrameComment frameNumber
                                                , defaultValue frameText
                                                , Util.onKeydownPreventDefault
                                                    (\key ->
                                                        let
                                                            newKeysDown =
                                                                KK.update (KK.Down <| KK.toCode key) shared.keysDown

                                                            action =
                                                                if key == KK.Tab then
                                                                    if newKeysDown == shared.keysDown then
                                                                        Just BaseMessage.NoOp
                                                                    else
                                                                        KK.getHotkeyAction
                                                                            [ ( [ KK.Tab ]
                                                                              , if Array.length model.highlightedComments == frameNumber then
                                                                                    BaseMessage.NoOp
                                                                                else
                                                                                    BaseMessage.GoTo { wipeModalError = False } <|
                                                                                        Route.CreateBigbitCodeFramePage
                                                                                            (frameNumber + 1)
                                                                                            (getActiveFileForFrame
                                                                                                (frameNumber + 1)
                                                                                                model
                                                                                            )
                                                                              )
                                                                            , ( [ KK.Tab, KK.Shift ]
                                                                              , BaseMessage.GoTo { wipeModalError = False } <|
                                                                                    if frameNumber == 1 then
                                                                                        Route.CreateBigbitTagsPage
                                                                                    else
                                                                                        Route.CreateBigbitCodeFramePage
                                                                                            (frameNumber - 1)
                                                                                            (getActiveFileForFrame
                                                                                                (frameNumber - 1)
                                                                                                model
                                                                                            )
                                                                              )
                                                                            ]
                                                                            newKeysDown
                                                                else
                                                                    Nothing
                                                        in
                                                        action
                                                    )
                                                ]
                                            )

                                    _ ->
                                        -- Should never happen.
                                        Util.hiddenDiv
                                ]

                        tabBar =
                            let
                                dynamicFrameButtons =
                                    div
                                        [ class "frame-buttons-box" ]
                                        (Array.indexedMap
                                            (\index highlightedComment ->
                                                button
                                                    [ classList [ ( "selected-frame", (Just <| index + 1) == frameTab ) ]
                                                    , onClick <|
                                                        BaseMessage.GoTo { wipeModalError = False } <|
                                                            Route.CreateBigbitCodeFramePage
                                                                (index + 1)
                                                                (getActiveFileForFrame
                                                                    (index + 1)
                                                                    model
                                                                )
                                                    ]
                                                    [ text <| toString <| index + 1 ]
                                            )
                                            model.highlightedComments
                                            |> Array.toList
                                        )
                            in
                            div
                                [ class "comment-body-bottom-buttons"
                                , hidden markdownOpen
                                ]
                                [ button
                                    [ class "add-or-remove-frame-button"
                                    , onClick <| subMsg AddFrame
                                    ]
                                    [ text "+" ]
                                , button
                                    [ classList [ ( "add-or-remove-frame-button", True ), ( "confirmed", model.confirmedRemoveFrame ) ]
                                    , onClick <| subMsg RemoveFrame
                                    , disabled <|
                                        Array.length model.highlightedComments
                                            <= 1
                                    ]
                                    [ text "-" ]
                                , hr [] []
                                , dynamicFrameButtons
                                ]
                    in
                    div
                        []
                        [ div
                            [ class "comment-creator" ]
                            [ body
                            , tabBar
                            ]
                        ]
            in
            div
                [ class "create-bigbit-code" ]
                [ div
                    [ class "bigbit-extended-view" ]
                    [ bigbitFS
                    , bigbitEditor
                    , bigbitCommentBox
                    ]
                ]
    in
    div
        [ classList
            [ ( "create-bigbit", True )
            , ( "fs-closed", not fsOpen )
            , ( "viewing-fs-open"
              , case shared.route of
                    Route.CreateBigbitCodeFramePage _ _ ->
                        fsOpen

                    _ ->
                        False
              )
            ]
        ]
        [ div
            [ class "sub-bar" ]
            [ button
                [ classList [ ( "sub-bar-button", True ), ( "confirmed", model.confirmedReset ) ]
                , onClick <| subMsg Reset
                ]
                [ text "Reset" ]
            , case previousFrameRange model shared.route of
                Nothing ->
                    Util.hiddenDiv

                Just ( filePath, _ ) ->
                    button
                        [ class "sub-bar-button previous-frame-location"
                        , onClick <| subMsg <| JumpToLineFromPreviousFrame filePath
                        ]
                        [ text "Previous Frame Location" ]
            , publishButton
            ]
        , createBigbitNavbar
        , case shared.route of
            Route.CreateBigbitNamePage ->
                div
                    [ class "create-bigbit-name" ]
                    [ TextFields.input
                        shared.textFieldKeyTracker
                        "create-bigbit-name"
                        [ placeholder "Name"
                        , id "name-input"
                        , onInput <| subMsg << OnUpdateName
                        , defaultValue model.name
                        , Util.onKeydownPreventDefault
                            (\key ->
                                if key == KK.Tab then
                                    Just BaseMessage.NoOp
                                else
                                    Nothing
                            )
                        ]
                    , Util.limitCharsText 50 model.name
                    ]

            Route.CreateBigbitDescriptionPage ->
                div
                    [ class "create-bigbit-description" ]
                    [ TextFields.textarea
                        shared.textFieldKeyTracker
                        "create-bigbit-description"
                        [ placeholder "Description"
                        , id "description-input"
                        , onInput <| subMsg << OnUpdateDescription
                        , defaultValue model.description
                        , Util.onKeydownPreventDefault
                            (\key ->
                                if key == KK.Tab then
                                    Just BaseMessage.NoOp
                                else
                                    Nothing
                            )
                        ]
                    , Util.limitCharsText 300 model.description
                    ]

            Route.CreateBigbitTagsPage ->
                div
                    [ class "create-tidbit-tags" ]
                    [ TextFields.input
                        shared.textFieldKeyTracker
                        "create-bigbit-tags"
                        [ placeholder "Tags"
                        , id "tags-input"
                        , onInput <| subMsg << OnUpdateTagInput
                        , defaultValue model.tagInput
                        , Util.onKeydownPreventDefault
                            (\key ->
                                if key == KK.Enter || key == KK.Space then
                                    Just <| subMsg <| AddTag model.tagInput
                                else if key == KK.Tab then
                                    Just BaseMessage.NoOp
                                else
                                    Nothing
                            )
                        ]
                    , Tags.view (subMsg << RemoveTag) model.tags
                    ]

            Route.CreateBigbitCodeFramePage _ _ ->
                bigbitCodeTab

            -- Should never happen
            _ ->
                Util.hiddenDiv
        ]
