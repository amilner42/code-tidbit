module Pages.CreateBigbit.View exposing (..)

import Array
import Autocomplete as AC
import DefaultServices.Util as Util exposing (maybeMapWithDefault, togglePreviewMarkdown)
import DefaultServices.Editable as Editable
import Dict
import Elements.Editor as Editor
import Elements.ProgressBar exposing (progressBar)
import Elements.Tags exposing (tags)
import Html exposing (Html, div, text, textarea, button, input, h1, h3, img, hr, i)
import Html.Attributes exposing (class, classList, disabled, placeholder, value, hidden, id, src, style)
import Html.Events exposing (onClick, onInput)
import Models.Bigbit as Bigbit
import Elements.FileStructure as FS
import Keyboard.Extra as KK
import Models.Completed as Completed
import Models.Range as Range
import Models.Route as Route
import Models.Snipbit as Snipbit
import Models.Tidbit as Tidbit
import Models.Story as Story
import Models.ViewerRelevantHC as ViewerRelevantHC
import Models.TidbitType exposing (TidbitType(..))
import Pages.CreateBigbit.Messages exposing (..)
import Pages.CreateBigbit.Model exposing (..)
import Pages.Model exposing (Shared, kkUpdateWrapper)


{-| `CreateBigbit` view.
-}
view : Model -> Shared -> Html Msg
view model shared =
    let
        currentRoute =
            shared.route

        {- It should be disabled unles everything is filled out. -}
        publishButton =
            case createDataToPublicationData model of
                Nothing ->
                    button
                        [ class "create-bigbit-disabled-publish-button"
                        , disabled True
                        ]
                        [ text "Publish" ]

                Just bigbitForPublicaton ->
                    button
                        [ class "create-bigbit-publish-button"
                        , onClick <| BigbitPublish bigbitForPublicaton
                        ]
                        [ text "Publish" ]

        createBigbitNavbar : Html Msg
        createBigbitNavbar =
            div
                [ classList [ ( "create-tidbit-navbar", True ) ] ]
                [ div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
                          , currentRoute == Route.CreateBigbitNamePage
                          )
                        , ( "filled-in", Util.isNotNothing <| createDataNameFilledIn model )
                        ]
                    , onClick <| GoTo Route.CreateBigbitNamePage
                    ]
                    [ text "Name"
                    , Util.checkIcon
                    ]
                , div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
                          , currentRoute == Route.CreateBigbitDescriptionPage
                          )
                        , ( "filled-in", Util.isNotNothing <| createDataDescriptionFilledIn model )
                        ]
                    , onClick <| GoTo Route.CreateBigbitDescriptionPage
                    ]
                    [ text "Description"
                    , Util.checkIcon
                    ]
                , div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
                          , currentRoute == Route.CreateBigbitTagsPage
                          )
                        , ( "filled-in", Util.isNotNothing <| createDataTagsFilledIn model )
                        ]
                    , onClick <| GoTo Route.CreateBigbitTagsPage
                    ]
                    [ text "Tags"
                    , Util.checkIcon
                    ]
                , div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
                          , case currentRoute of
                                Route.CreateBigbitCodeFramePage _ _ ->
                                    True

                                Route.CreateBigbitCodeIntroductionPage _ ->
                                    True

                                Route.CreateBigbitCodeConclusionPage _ ->
                                    True

                                _ ->
                                    False
                          )
                        , ( "filled-in", createDataCodeTabFilledIn model )
                        ]
                    , onClick <| BigbitGoToCodeTab
                    ]
                    [ text "Code"
                    , Util.checkIcon
                    ]
                ]

        bigbitCodeTab =
            let
                currentActiveFile =
                    createPageCurrentActiveFile shared.route

                viewingFile absolutePath =
                    Maybe.map (FS.isSameFilePath absolutePath) currentActiveFile
                        |> Maybe.withDefault False

                ( introTab, conclusionTab, frameTab ) =
                    case shared.route of
                        Route.CreateBigbitCodeIntroductionPage _ ->
                            ( True, False, Nothing )

                        Route.CreateBigbitCodeFramePage frameNumber _ ->
                            ( False, False, Just frameNumber )

                        Route.CreateBigbitCodeConclusionPage _ ->
                            ( False, True, Nothing )

                        _ ->
                            ( False, False, Nothing )

                bigbitEditor =
                    div
                        [ class "bigbit-editor" ]
                        [ div
                            [ class "current-file" ]
                            [ text <|
                                if introTab then
                                    "Bigbit introductions do not link to files or highlights, but you can browse and edit your code"
                                else if conclusionTab then
                                    "Bigbit conclusions do not link to files or highlights, but you can browse and edit your code"
                                else
                                    Maybe.withDefault "No File Selected" currentActiveFile
                            ]
                        , div
                            [ class "create-tidbit-code" ]
                            [ Editor.editor "create-bigbit-code-editor"
                            ]
                        ]

                bigbitCommentBox =
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

                        fsOpen =
                            Bigbit.isFSOpen model.fs

                        markdownOpen =
                            model.previewMarkdown

                        fs =
                            div
                                [ class "file-structure"
                                , hidden <| not <| fsOpen
                                ]
                                [ FS.fileStructure
                                    { isFileSelected = viewingFile
                                    , fileSelectedMsg = BigbitFileSelected
                                    , folderSelectedMsg = BigbitFSToggleFolder
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
                                                                                                [ onClick <| BigbitAddFile actionInput language ]
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
                                    , input
                                        [ id "fs-action-input-box"
                                        , placeholder "Absolute Path"
                                        , onInput BigbitUpdateActionInput
                                        , Util.onKeydown
                                            (\key ->
                                                if key == KK.Enter then
                                                    Just BigbitSubmitActionInput
                                                else
                                                    Nothing
                                            )
                                        , value
                                            (model.fs
                                                |> FS.getFSMetadata
                                                |> .actionButtonInput
                                            )
                                        ]
                                        []
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
                                                            , onClick <| BigbitSubmitActionInput
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
                                    , onClick <| BigbitUpdateActionButtonState <| Just AddingFile
                                    ]
                                    [ text "Add File" ]
                                , button
                                    [ classList
                                        [ ( "add-folder", True )
                                        , ( "selected-action-button"
                                          , fsActionStateEquals (Just AddingFolder) model.fs
                                          )
                                        ]
                                    , onClick <| BigbitUpdateActionButtonState <| Just AddingFolder
                                    ]
                                    [ text "Add Folder" ]
                                , button
                                    [ classList
                                        [ ( "remove-file", True )
                                        , ( "selected-action-button"
                                          , fsActionStateEquals (Just RemovingFile) model.fs
                                          )
                                        ]
                                    , onClick <| BigbitUpdateActionButtonState <| Just RemovingFile
                                    ]
                                    [ text "Remove File" ]
                                , button
                                    [ classList
                                        [ ( "remove-folder", True )
                                        , ( "selected-action-button"
                                          , fsActionStateEquals (Just RemovingFolder) model.fs
                                          )
                                        ]
                                    , onClick <| BigbitUpdateActionButtonState <| Just RemovingFolder
                                    ]
                                    [ text "Remove Folder" ]
                                ]

                        body =
                            div
                                [ class "comment-body" ]
                                [ fs
                                , div
                                    [ class "expand-file-structure"
                                    , onClick BigbitToggleFS
                                    , hidden markdownOpen
                                    ]
                                    [ if fsOpen then
                                        text "Close File Structure"
                                      else
                                        text "View File Structure"
                                    ]
                                , div
                                    [ class "preview-markdown"
                                    , onClick BigbitTogglePreviewMarkdown
                                    , hidden fsOpen
                                    ]
                                    [ if markdownOpen then
                                        text "Close Preview"
                                      else
                                        text "Preview Markdown"
                                    ]
                                , case shared.route of
                                    Route.CreateBigbitCodeIntroductionPage _ ->
                                        Util.markdownOr
                                            markdownOpen
                                            model.introduction
                                            (textarea
                                                [ placeholder "Introduction"
                                                , id "introduction-input"
                                                , onInput <| BigbitUpdateIntroduction
                                                , hidden <| Bigbit.isFSOpen model.fs
                                                , value model.introduction
                                                , Util.onKeydownPreventDefault
                                                    (\key ->
                                                        let
                                                            newKeysDown =
                                                                kkUpdateWrapper (KK.Down <| KK.toCode key) shared.keysDown
                                                        in
                                                            if key == KK.Tab then
                                                                if newKeysDown == shared.keysDown then
                                                                    Just NoOp
                                                                else if KK.isOneKeyPressed KK.Tab newKeysDown then
                                                                    Just <|
                                                                        GoTo <|
                                                                            Route.CreateBigbitCodeFramePage
                                                                                1
                                                                                (createPageGetActiveFileForFrame 1 model)
                                                                else if KK.isTwoKeysPressed KK.Tab KK.Shift newKeysDown then
                                                                    Just <| GoTo <| Route.CreateBigbitTagsPage
                                                                else
                                                                    Nothing
                                                            else
                                                                Nothing
                                                    )
                                                ]
                                                []
                                            )

                                    Route.CreateBigbitCodeFramePage frameNumber _ ->
                                        let
                                            frameText =
                                                (Array.get
                                                    (frameNumber - 1)
                                                    model.highlightedComments
                                                )
                                                    |> Maybe.map .comment
                                                    |> Maybe.withDefault ""
                                        in
                                            Util.markdownOr
                                                markdownOpen
                                                frameText
                                                (textarea
                                                    [ placeholder <| "Frame " ++ (toString frameNumber)
                                                    , id "frame-input"
                                                    , onInput <| BigbitUpdateFrameComment frameNumber
                                                    , value frameText
                                                    , hidden <| fsOpen
                                                    , Util.onKeydownPreventDefault
                                                        (\key ->
                                                            let
                                                                newKeysDown =
                                                                    kkUpdateWrapper (KK.Down <| KK.toCode key) shared.keysDown
                                                            in
                                                                if key == KK.Tab then
                                                                    if newKeysDown == shared.keysDown then
                                                                        Just NoOp
                                                                    else if KK.isOneKeyPressed KK.Tab newKeysDown then
                                                                        Just <|
                                                                            GoTo <|
                                                                                Route.CreateBigbitCodeFramePage
                                                                                    (frameNumber + 1)
                                                                                    (createPageGetActiveFileForFrame
                                                                                        (frameNumber + 1)
                                                                                        model
                                                                                    )
                                                                    else if KK.isTwoKeysPressed KK.Tab KK.Shift newKeysDown then
                                                                        Just <|
                                                                            GoTo <|
                                                                                Route.CreateBigbitCodeFramePage
                                                                                    (frameNumber - 1)
                                                                                    (createPageGetActiveFileForFrame
                                                                                        (frameNumber - 1)
                                                                                        model
                                                                                    )
                                                                    else
                                                                        Nothing
                                                                else
                                                                    Nothing
                                                        )
                                                    ]
                                                    []
                                                )

                                    Route.CreateBigbitCodeConclusionPage _ ->
                                        Util.markdownOr
                                            markdownOpen
                                            model.conclusion
                                            (textarea
                                                [ placeholder "Conclusion"
                                                , id "conclusion-input"
                                                , onInput BigbitUpdateConclusion
                                                , hidden <| fsOpen
                                                , value model.conclusion
                                                , Util.onKeydownPreventDefault
                                                    (\key ->
                                                        let
                                                            newKeysDown =
                                                                kkUpdateWrapper (KK.Down <| KK.toCode key) shared.keysDown
                                                        in
                                                            if key == KK.Tab then
                                                                if newKeysDown == shared.keysDown then
                                                                    Just NoOp
                                                                else if KK.isOneKeyPressed KK.Tab newKeysDown then
                                                                    Just <| NoOp
                                                                else if KK.isTwoKeysPressed KK.Tab KK.Shift newKeysDown then
                                                                    Just <|
                                                                        GoTo <|
                                                                            Route.CreateBigbitCodeFramePage
                                                                                (Array.length model.highlightedComments)
                                                                                (createPageGetActiveFileForFrame
                                                                                    (Array.length model.highlightedComments)
                                                                                    model
                                                                                )
                                                                else
                                                                    Nothing
                                                            else
                                                                Nothing
                                                    )
                                                ]
                                                []
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
                                        ((Array.indexedMap
                                            (\index highlightedComment ->
                                                button
                                                    [ classList [ ( "selected-frame", (Just <| index + 1) == frameTab ) ]
                                                    , onClick <|
                                                        GoTo <|
                                                            Route.CreateBigbitCodeFramePage
                                                                (index + 1)
                                                                (createPageGetActiveFileForFrame
                                                                    (index + 1)
                                                                    model
                                                                )
                                                    ]
                                                    [ text <| toString <| index + 1 ]
                                            )
                                            model.highlightedComments
                                         )
                                            |> Array.toList
                                        )
                            in
                                div
                                    [ class "comment-body-bottom-buttons"
                                    , hidden <| fsOpen || markdownOpen
                                    ]
                                    [ button
                                        [ onClick <| GoTo <| Route.CreateBigbitCodeIntroductionPage Nothing
                                        , classList
                                            [ ( "introduction-button", True )
                                            , ( "selected-frame", introTab )
                                            ]
                                        ]
                                        [ text "Introduction" ]
                                    , button
                                        [ onClick <| GoTo <| Route.CreateBigbitCodeConclusionPage Nothing
                                        , classList
                                            [ ( "conclusion-button", True )
                                            , ( "selected-frame", conclusionTab )
                                            ]
                                        ]
                                        [ text "Conclusion" ]
                                    , button
                                        [ class "add-or-remove-frame-button"
                                        , onClick <| BigbitAddFrame
                                        ]
                                        [ text "+" ]
                                    , button
                                        [ class "add-or-remove-frame-button"
                                        , onClick <| BigbitRemoveFrame
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
                    [ bigbitEditor
                    , bigbitCommentBox
                    ]
    in
        div
            [ class "create-bigbit" ]
            [ div
                [ class "sub-bar" ]
                [ button
                    [ class "sub-bar-button"
                    , onClick <| BigbitReset
                    ]
                    [ text "Reset" ]
                , case previousFrameRange model shared.route of
                    Nothing ->
                        Util.hiddenDiv

                    Just ( filePath, _ ) ->
                        button
                            [ class "sub-bar-button previous-frame-location"
                            , onClick <| BigbitJumpToLineFromPreviousFrame filePath
                            ]
                            [ text "Previous Frame Location" ]
                , publishButton
                ]
            , createBigbitNavbar
            , case shared.route of
                Route.CreateBigbitNamePage ->
                    div
                        [ class "create-bigbit-name" ]
                        [ input
                            [ placeholder "Name"
                            , id "name-input"
                            , onInput BigbitUpdateName
                            , value model.name
                            , Util.onKeydownPreventDefault
                                (\key ->
                                    if key == KK.Tab then
                                        Just NoOp
                                    else
                                        Nothing
                                )
                            ]
                            []
                        ]

                Route.CreateBigbitDescriptionPage ->
                    div
                        [ class "create-bigbit-description" ]
                        [ textarea
                            [ placeholder "Description"
                            , id "description-input"
                            , onInput BigbitUpdateDescription
                            , value model.description
                            , Util.onKeydownPreventDefault
                                (\key ->
                                    if key == KK.Tab then
                                        Just NoOp
                                    else
                                        Nothing
                                )
                            ]
                            []
                        ]

                Route.CreateBigbitTagsPage ->
                    div
                        [ class "create-tidbit-tags" ]
                        [ input
                            [ placeholder "Tags"
                            , id "tags-input"
                            , onInput BigbitUpdateTagInput
                            , value model.tagInput
                            , Util.onKeydownPreventDefault
                                (\key ->
                                    if key == KK.Enter then
                                        Just <| BigbitAddTag model.tagInput
                                    else if key == KK.Tab then
                                        Just <| NoOp
                                    else
                                        Nothing
                                )
                            ]
                            []
                        , tags BigbitRemoveTag model.tags
                        ]

                Route.CreateBigbitCodeIntroductionPage _ ->
                    bigbitCodeTab

                Route.CreateBigbitCodeFramePage frameNumber _ ->
                    bigbitCodeTab

                Route.CreateBigbitCodeConclusionPage _ ->
                    bigbitCodeTab

                -- Should never happen
                _ ->
                    Util.hiddenDiv
            ]
