module Components.Home.View exposing (..)

import Array
import Autocomplete as AC
import Components.Home.Messages exposing (Msg(..))
import Components.Home.Model exposing (Model, TidbitType(..))
import Components.Home.Update exposing (filterLanguagesByQuery)
import Components.Model exposing (Shared)
import DefaultServices.Util as Util
import Dict
import Elements.Editor as Editor
import Html exposing (Html, div, text, textarea, button, input, h1, h3, img, hr, i)
import Html.Attributes exposing (class, classList, disabled, placeholder, value, hidden, id, src, style)
import Html.Events exposing (onClick, onInput)
import Models.Bigbit as Bigbit
import Elements.FileStructure as FS
import Models.Range as Range
import Models.Route as Route
import Models.Snipbit as Snipbit


{-| A google-material-design check-icon.
-}
checkIcon : Html msg
checkIcon =
    i
        [ class "material-icons check-icon" ]
        [ text "check" ]


{-| Home Component View.
-}
view : Model -> Shared -> Html Msg
view model shared =
    div
        [ class "home-component-wrapper" ]
        [ div
            [ class "home-component" ]
            [ navbar shared
            , displayViewForRoute model shared
            ]
        ]


{-| Helper function for creating the HTML tags in the tag-tab. Currently used
in both snipbits and bigbits.
-}
makeHTMLTags : (String -> Msg) -> List String -> Html Msg
makeHTMLTags closeTagMsg tags =
    div
        [ class "current-tags" ]
        (List.map
            (\tagName ->
                div
                    [ class "tag" ]
                    [ text tagName
                    , button
                        [ onClick <| closeTagMsg tagName ]
                        [ text "X" ]
                    ]
            )
            tags
        )


{-| Builds a progress bar.

NOTE: Progress bar subtracts 1 from current frame, so to get 100% completion
maybeCurrentFrame must be one bigger than maxFrame (eg, 11 / 10). This is done
because we don't wanna count the current frame as complete.
-}
progressBar : Maybe Int -> Int -> Bool -> Html Msg
progressBar maybeCurrentFrame maxFrame isDisabled =
    let
        percentComplete =
            case maybeCurrentFrame of
                Nothing ->
                    0

                Just currentFrame ->
                    if (currentFrame - 1) == 0 then
                        0
                    else
                        100 * (toFloat (currentFrame - 1)) / (toFloat maxFrame)
    in
        div
            [ classList
                [ ( "progress-bar", True )
                , ( "selected", Util.isNotNothing maybeCurrentFrame )
                , ( "disabled", isDisabled )
                ]
            ]
            [ div
                [ classList
                    [ ( "progress-bar-completion-bar", True )
                    , ( "disabled", isDisabled )
                    ]
                , style [ ( "width", (toString <| round <| percentComplete * 1.6) ++ "px" ) ]
                ]
                []
            , div
                [ class "progress-bar-percent" ]
                [ text <| (toString <| round <| percentComplete) ++ "%" ]
            ]


{-| The view for viewing a snipbit.
-}
viewSnipbitView : Model -> Shared -> Html Msg
viewSnipbitView model shared =
    div
        [ class "view-snipbit" ]
        (case model.viewingSnipbit of
            Nothing ->
                [ text "LOADING" ]

            Just snipbit ->
                [ div
                    [ class "viewer" ]
                    [ div
                        [ class "viewer-navbar" ]
                        [ i
                            [ classList
                                [ ( "material-icons action-button", True )
                                , ( "disabled-icon"
                                  , case shared.route of
                                        Route.HomeComponentViewSnipbitIntroduction _ ->
                                            True

                                        _ ->
                                            False
                                  )
                                ]
                            , onClick <|
                                case shared.route of
                                    Route.HomeComponentViewSnipbitConclusion mongoID ->
                                        GoTo <| Route.HomeComponentViewSnipbitFrame mongoID (Array.length snipbit.highlightedComments)

                                    Route.HomeComponentViewSnipbitFrame mongoID frameNumber ->
                                        GoTo <| Route.HomeComponentViewSnipbitFrame mongoID (frameNumber - 1)

                                    _ ->
                                        NoOp
                            ]
                            [ text "arrow_back" ]
                        , div
                            [ onClick <| GoTo <| Route.HomeComponentViewSnipbitIntroduction snipbit.id
                            , classList
                                [ ( "viewer-navbar-item", True )
                                , ( "selected"
                                  , case shared.route of
                                        Route.HomeComponentViewSnipbitIntroduction _ ->
                                            True

                                        _ ->
                                            False
                                  )
                                ]
                            ]
                            [ text "Introduction" ]
                        , progressBar
                            (case shared.route of
                                Route.HomeComponentViewSnipbitFrame _ frameNumber ->
                                    Just frameNumber

                                Route.HomeComponentViewSnipbitConclusion _ ->
                                    Just <| Array.length snipbit.highlightedComments + 1

                                _ ->
                                    Nothing
                            )
                            (Array.length snipbit.highlightedComments)
                            False
                        , div
                            [ onClick <| GoTo <| Route.HomeComponentViewSnipbitConclusion snipbit.id
                            , classList
                                [ ( "viewer-navbar-item", True )
                                , ( "selected"
                                  , case shared.route of
                                        Route.HomeComponentViewSnipbitConclusion _ ->
                                            True

                                        _ ->
                                            False
                                  )
                                ]
                            ]
                            [ text "Conclusion" ]
                        , i
                            [ classList
                                [ ( "material-icons action-button", True )
                                , ( "disabled-icon"
                                  , case shared.route of
                                        Route.HomeComponentViewSnipbitConclusion _ ->
                                            True

                                        _ ->
                                            False
                                  )
                                ]
                            , onClick <|
                                case shared.route of
                                    Route.HomeComponentViewSnipbitIntroduction mongoID ->
                                        GoTo <| Route.HomeComponentViewSnipbitFrame mongoID 1

                                    Route.HomeComponentViewSnipbitFrame mongoID frameNumber ->
                                        GoTo <| Route.HomeComponentViewSnipbitFrame mongoID (frameNumber + 1)

                                    _ ->
                                        NoOp
                            ]
                            [ text "arrow_forward" ]
                        ]
                    , Editor.editor "view-snipbit-code-editor"
                    , div
                        [ class "comment-block" ]
                        [ textarea
                            [ disabled True
                            , value <|
                                case shared.route of
                                    Route.HomeComponentViewSnipbitIntroduction _ ->
                                        snipbit.introduction

                                    Route.HomeComponentViewSnipbitConclusion _ ->
                                        snipbit.conclusion

                                    Route.HomeComponentViewSnipbitFrame _ frameNumber ->
                                        (Array.get
                                            (frameNumber - 1)
                                            snipbit.highlightedComments
                                        )
                                            |> Maybe.map .comment
                                            |> Maybe.withDefault ""

                                    _ ->
                                        ""
                            ]
                            []
                        ]
                    ]
                ]
        )


{-| The view for viewing a bigbit.
-}
viewBigbitView : Model -> Shared -> Html Msg
viewBigbitView model shared =
    div
        [ class "view-bigbit" ]
        [ case model.viewingBigbit of
            Nothing ->
                div
                    []
                    [ text "LOADING" ]

            Just bigbit ->
                div
                    [ class "viewer" ]
                    [ div
                        [ class "viewer-navbar" ]
                        [ i
                            [ classList
                                [ ( "material-icons action-button", True )
                                , ( "disabled-icon"
                                  , if Bigbit.isFSOpen bigbit.fs then
                                        True
                                    else
                                        case shared.route of
                                            Route.HomeComponentViewBigbitIntroduction _ _ ->
                                                True

                                            _ ->
                                                False
                                  )
                                ]
                            , onClick <|
                                if Bigbit.isFSOpen bigbit.fs then
                                    NoOp
                                else
                                    case shared.route of
                                        Route.HomeComponentViewBigbitConclusion mongoID _ ->
                                            GoTo <| Route.HomeComponentViewBigbitFrame mongoID (Array.length bigbit.highlightedComments) Nothing

                                        Route.HomeComponentViewBigbitFrame mongoID frameNumber _ ->
                                            GoTo <| Route.HomeComponentViewBigbitFrame mongoID (frameNumber - 1) Nothing

                                        _ ->
                                            NoOp
                            ]
                            [ text "arrow_back" ]
                        , div
                            [ onClick <|
                                if Bigbit.isFSOpen bigbit.fs then
                                    NoOp
                                else
                                    GoTo <| Route.HomeComponentViewBigbitIntroduction bigbit.id Nothing
                            , classList
                                [ ( "viewer-navbar-item", True )
                                , ( "selected"
                                  , case shared.route of
                                        Route.HomeComponentViewBigbitIntroduction _ _ ->
                                            True

                                        _ ->
                                            False
                                  )
                                , ( "disabled", Bigbit.isFSOpen bigbit.fs )
                                ]
                            ]
                            [ text "Introduction" ]
                        , progressBar
                            (case shared.route of
                                Route.HomeComponentViewBigbitFrame _ frameNumber _ ->
                                    Just frameNumber

                                Route.HomeComponentViewBigbitConclusion _ _ ->
                                    Just <| Array.length bigbit.highlightedComments + 1

                                _ ->
                                    Nothing
                            )
                            (Array.length bigbit.highlightedComments)
                            (Bigbit.isFSOpen bigbit.fs)
                        , div
                            [ onClick <|
                                if Bigbit.isFSOpen bigbit.fs then
                                    NoOp
                                else
                                    GoTo <| Route.HomeComponentViewBigbitConclusion bigbit.id Nothing
                            , classList
                                [ ( "viewer-navbar-item", True )
                                , ( "selected"
                                  , case shared.route of
                                        Route.HomeComponentViewBigbitConclusion _ _ ->
                                            True

                                        _ ->
                                            False
                                  )
                                , ( "disabled", Bigbit.isFSOpen bigbit.fs )
                                ]
                            ]
                            [ text "Conclusion" ]
                        , i
                            [ classList
                                [ ( "material-icons action-button", True )
                                , ( "disabled-icon"
                                  , if Bigbit.isFSOpen bigbit.fs then
                                        True
                                    else
                                        case shared.route of
                                            Route.HomeComponentViewBigbitConclusion _ _ ->
                                                True

                                            _ ->
                                                False
                                  )
                                ]
                            , onClick <|
                                if Bigbit.isFSOpen bigbit.fs then
                                    NoOp
                                else
                                    case shared.route of
                                        Route.HomeComponentViewBigbitIntroduction mongoID _ ->
                                            GoTo <| Route.HomeComponentViewBigbitFrame mongoID 1 Nothing

                                        Route.HomeComponentViewBigbitFrame mongoID frameNumber _ ->
                                            GoTo <| Route.HomeComponentViewBigbitFrame mongoID (frameNumber + 1) Nothing

                                        _ ->
                                            NoOp
                            ]
                            [ text "arrow_forward" ]
                        ]
                    , Editor.editor "view-bigbit-code-editor"
                    , div
                        [ class "comment-block" ]
                        [ div
                            [ class "view-bigbit-toggle-fs"
                            , onClick <| ViewBigbitToggleFS
                            ]
                            [ text <|
                                case Bigbit.isFSOpen bigbit.fs of
                                    True ->
                                        "Resume Tutorial"

                                    False ->
                                        "Explore File Structure"
                            ]
                        , div
                            [ class "above-editor-text" ]
                            [ text <|
                                case Bigbit.viewPageCurrentActiveFile shared.route bigbit of
                                    Nothing ->
                                        "No File Selected"

                                    Just activeFile ->
                                        activeFile
                            ]
                        , textarea
                            [ disabled True
                            , hidden <|
                                Bigbit.isFSOpen bigbit.fs
                            , value <|
                                case shared.route of
                                    Route.HomeComponentViewBigbitIntroduction _ _ ->
                                        bigbit.introduction

                                    Route.HomeComponentViewBigbitConclusion _ _ ->
                                        bigbit.conclusion

                                    Route.HomeComponentViewBigbitFrame _ frameNumber _ ->
                                        (Array.get
                                            (frameNumber - 1)
                                            bigbit.highlightedComments
                                        )
                                            |> Maybe.map .comment
                                            |> Maybe.withDefault ""

                                    _ ->
                                        ""
                            ]
                            []
                        , div
                            [ class "view-bigbit-fs"
                            , hidden <| not <| Bigbit.isFSOpen bigbit.fs
                            ]
                            [ FS.fileStructure
                                { isFileSelected =
                                    (\absolutePath ->
                                        Bigbit.viewPageCurrentActiveFile shared.route bigbit
                                            |> Maybe.map (FS.isSameFilePath absolutePath)
                                            |> Maybe.withDefault False
                                    )
                                , fileSelectedMsg = ViewBigbitSelectFile
                                , folderSelectedMsg = ViewBigbitToggleFolder
                                }
                                bigbit.fs
                            ]
                        ]
                    ]
        ]


{-| Displays the correct view based on the model.
-}
displayViewForRoute : Model -> Shared -> Html Msg
displayViewForRoute model shared =
    case shared.route of
        Route.HomeComponentBrowse ->
            browseView model

        Route.HomeComponentViewSnipbitIntroduction _ ->
            viewSnipbitView model shared

        Route.HomeComponentViewSnipbitConclusion _ ->
            viewSnipbitView model shared

        Route.HomeComponentViewSnipbitFrame _ _ ->
            viewSnipbitView model shared

        Route.HomeComponentViewBigbitIntroduction _ _ ->
            viewBigbitView model shared

        Route.HomeComponentViewBigbitFrame _ _ _ ->
            viewBigbitView model shared

        Route.HomeComponentViewBigbitConclusion _ _ ->
            viewBigbitView model shared

        Route.HomeComponentCreate ->
            createView model shared

        Route.HomeComponentCreateSnipbitName ->
            createSnipbitView model shared

        Route.HomeComponentCreateSnipbitDescription ->
            createSnipbitView model shared

        Route.HomeComponentCreateSnipbitLanguage ->
            createSnipbitView model shared

        Route.HomeComponentCreateSnipbitTags ->
            createSnipbitView model shared

        Route.HomeComponentCreateSnipbitCodeIntroduction ->
            createSnipbitView model shared

        Route.HomeComponentCreateSnipbitCodeFrame _ ->
            createSnipbitView model shared

        Route.HomeComponentCreateSnipbitCodeConclusion ->
            createSnipbitView model shared

        Route.HomeComponentCreateBigbitName ->
            createBigbitView model shared

        Route.HomeComponentCreateBigbitDescription ->
            createBigbitView model shared

        Route.HomeComponentCreateBigbitTags ->
            createBigbitView model shared

        Route.HomeComponentCreateBigbitCodeIntroduction _ ->
            createBigbitView model shared

        Route.HomeComponentCreateBigbitCodeFrame _ _ ->
            createBigbitView model shared

        Route.HomeComponentCreateBigbitCodeConclusion _ ->
            createBigbitView model shared

        Route.HomeComponentProfile ->
            profileView model

        -- This should never happen.
        _ ->
            browseView model


{-| Horizontal navbar to go above the views.
-}
navbar : Shared -> Html Msg
navbar shared =
    let
        browseViewSelected =
            case shared.route of
                Route.HomeComponentBrowse ->
                    True

                Route.HomeComponentViewSnipbitIntroduction _ ->
                    True

                Route.HomeComponentViewSnipbitFrame _ _ ->
                    True

                Route.HomeComponentViewSnipbitConclusion _ ->
                    True

                Route.HomeComponentViewBigbitIntroduction _ _ ->
                    True

                Route.HomeComponentViewBigbitFrame _ _ _ ->
                    True

                Route.HomeComponentViewBigbitConclusion _ _ ->
                    True

                _ ->
                    False

        profileViewSelected =
            shared.route == Route.HomeComponentProfile

        createViewSelected =
            case shared.route of
                Route.HomeComponentCreateSnipbitCodeFrame _ ->
                    True

                Route.HomeComponentCreateBigbitCodeFrame _ _ ->
                    True

                Route.HomeComponentCreateBigbitCodeIntroduction _ ->
                    True

                Route.HomeComponentCreateBigbitCodeConclusion _ ->
                    True

                _ ->
                    (List.member
                        shared.route
                        [ Route.HomeComponentCreate
                        , Route.HomeComponentCreateSnipbitName
                        , Route.HomeComponentCreateSnipbitDescription
                        , Route.HomeComponentCreateSnipbitLanguage
                        , Route.HomeComponentCreateSnipbitTags
                        , Route.HomeComponentCreateSnipbitCodeIntroduction
                        , Route.HomeComponentCreateSnipbitCodeConclusion
                        , Route.HomeComponentCreateBigbitName
                        , Route.HomeComponentCreateBigbitDescription
                        , Route.HomeComponentCreateBigbitTags
                        ]
                    )
    in
        div [ class "nav" ]
            [ img
                [ class "logo"
                , src "assets/ct-logo.png"
                ]
                []
            , div
                [ classList
                    [ ( "nav-btn left", True )
                    , ( "selected", browseViewSelected )
                    ]
                , onClick <| GoTo Route.HomeComponentBrowse
                ]
                [ text "Browse" ]
            , div
                [ classList
                    [ ( "nav-btn left", True )
                    , ( "selected", createViewSelected )
                    ]
                , onClick <| GoTo Route.HomeComponentCreate
                ]
                [ text "Create" ]
            , div
                [ classList
                    [ ( "nav-btn right", True )
                    , ( "selected", profileViewSelected )
                    ]
                , onClick <| GoTo Route.HomeComponentProfile
                ]
                [ text "Profile" ]
            ]


{-| The profile view.
-}
profileView : Model -> Html Msg
profileView model =
    div []
        [ button
            [ onClick LogOut ]
            [ text "Log out" ]
        , div
            [ hidden <| Util.isNothing model.logOutError ]
            [ text "Cannot log out right now, try again shortly." ]
        ]


{-| The browse view.
-}
browseView : Model -> Html Msg
browseView model =
    div []
        []


{-| The create view.
-}
createView : Model -> Shared -> Html Msg
createView model shared =
    let
        snipBitDescription : String
        snipBitDescription =
            """SnipBits are uni-language snippets of code that are
            targetted at explaining simple individual concepts or
            answering questions.

            You highlight chunks of the code with attached comments,
            taking your viewers through your code explaining everything
            one step at a time.
            """

        bigBitInfo : String
        bigBitInfo =
            """BigBits are multi-language projects of code targetted at
            simplifying larger tutorials which require their own file structure.

            You highlight chunks of code and attach comments automatically
            taking your user through all the files and folders in a directed
            fashion while still letting them explore themselves.
            """

        makeTidbitTypeBox : String -> String -> String -> Msg -> TidbitType -> Html Msg
        makeTidbitTypeBox title subTitle description onClickMsg tidbitType =
            div
                [ class "create-select-tidbit-type" ]
                (if model.showInfoFor == (Just tidbitType) then
                    [ div
                        [ class "description-title" ]
                        [ text <| toString tidbitType ++ " Info" ]
                    , div
                        [ class "description-text" ]
                        [ text description ]
                    , button
                        [ class "back-button"
                        , onClick <| ShowInfoFor Nothing
                        ]
                        [ text "back" ]
                    ]
                 else
                    [ div
                        [ class "create-select-tidbit-type-title" ]
                        [ text title ]
                    , div
                        [ class "create-select-tidbit-type-sub-title" ]
                        [ text subTitle ]
                    , button
                        [ class "info-button"
                        , onClick <| ShowInfoFor <| Just tidbitType
                        ]
                        [ text "more info" ]
                    , button
                        [ class "select-button"
                        , onClick onClickMsg
                        ]
                        [ text "select" ]
                    ]
                )
    in
        div
            []
            [ div
                []
                [ h1
                    [ class "create-select-tidbit-title" ]
                    [ text "Select Tidbit Type" ]
                , div
                    [ class "create-select-tidbit-box" ]
                    [ makeTidbitTypeBox
                        "SnipBit"
                        "Excellent for answering questions"
                        snipBitDescription
                        (GoTo Route.HomeComponentCreateSnipbitName)
                        SnipBit
                    , makeTidbitTypeBox
                        "BigBit"
                        "Designed for larger tutorials"
                        bigBitInfo
                        (GoTo Route.HomeComponentCreateBigbitName)
                        BigBit
                    , div
                        [ class "create-select-tidbit-type-coming-soon" ]
                        [ div
                            [ class "coming-soon-text" ]
                            [ text "More Coming Soon" ]
                        , div
                            [ class "coming-soon-sub-text" ]
                            [ text "We are working on it" ]
                        ]
                    ]
                ]
            ]


{-| View for creating a bigbit.
-}
createBigbitView : Model -> Shared -> Html Msg
createBigbitView model shared =
    let
        currentRoute =
            shared.route

        {- It should be disabled unles everything is filled out. -}
        publishButton =
            case Bigbit.createDataToPublicationData model.bigbitCreateData of
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
                          , currentRoute == Route.HomeComponentCreateBigbitName
                          )
                        , ( "filled-in", Util.isNotNothing <| Bigbit.createDataNameFilledIn model.bigbitCreateData )
                        ]
                    , onClick <| GoTo Route.HomeComponentCreateBigbitName
                    ]
                    [ text "Name"
                    , checkIcon
                    ]
                , div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
                          , currentRoute == Route.HomeComponentCreateBigbitDescription
                          )
                        , ( "filled-in", Util.isNotNothing <| Bigbit.createDataDescriptionFilledIn model.bigbitCreateData )
                        ]
                    , onClick <| GoTo Route.HomeComponentCreateBigbitDescription
                    ]
                    [ text "Description"
                    , checkIcon
                    ]
                , div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
                          , currentRoute == Route.HomeComponentCreateBigbitTags
                          )
                        , ( "filled-in", Util.isNotNothing <| Bigbit.createDataTagsFilledIn model.bigbitCreateData )
                        ]
                    , onClick <| GoTo Route.HomeComponentCreateBigbitTags
                    ]
                    [ text "Tags"
                    , checkIcon
                    ]
                , div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
                          , case currentRoute of
                                Route.HomeComponentCreateBigbitCodeFrame _ _ ->
                                    True

                                Route.HomeComponentCreateBigbitCodeIntroduction _ ->
                                    True

                                Route.HomeComponentCreateBigbitCodeConclusion _ ->
                                    True

                                _ ->
                                    False
                          )
                        , ( "filled-in", Bigbit.createDataCodeTabFilledIn model.bigbitCreateData )
                        ]
                    , onClick <| GoTo <| Route.HomeComponentCreateBigbitCodeIntroduction Nothing
                    ]
                    [ text "Code"
                    , checkIcon
                    ]
                ]

        bigbitCodeTab =
            let
                currentActiveFile =
                    Bigbit.createPageCurrentActiveFile shared.route

                viewingFile absolutePath =
                    Maybe.map (FS.isSameFilePath absolutePath) currentActiveFile
                        |> Maybe.withDefault False

                ( introTab, conclusionTab, frameTab ) =
                    case shared.route of
                        Route.HomeComponentCreateBigbitCodeIntroduction _ ->
                            ( True, False, Nothing )

                        Route.HomeComponentCreateBigbitCodeFrame frameNumber _ ->
                            ( False, False, Just frameNumber )

                        Route.HomeComponentCreateBigbitCodeConclusion _ ->
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
                            FS.getFSMetadata <| model.bigbitCreateData.fs

                        maybeActionState =
                            fsMetadata.actionButtonState

                        actionInput =
                            fsMetadata.actionButtonInput

                        validFileInputResult =
                            Bigbit.isValidAddFileInput
                                actionInput
                                model.bigbitCreateData.fs

                        validFileInput =
                            Util.resultToBool validFileInputResult

                        validRemoveFileInputResult =
                            Bigbit.isValidRemoveFileInput actionInput model.bigbitCreateData.fs

                        validRemoveFileInput =
                            Util.resultToBool validRemoveFileInputResult

                        validRemoveFolderInputResult =
                            Bigbit.isValidRemoveFolderInput actionInput model.bigbitCreateData.fs

                        validRemoveFolderInput =
                            Util.resultToBool validRemoveFolderInputResult

                        validFolderInputResult =
                            Bigbit.isValidAddFolderInput
                                actionInput
                                model.bigbitCreateData.fs

                        validFolderInput =
                            Util.resultToBool validFolderInputResult

                        fs =
                            div
                                [ class "file-structure"
                                , hidden <| not <| Bigbit.isFSOpen model.bigbitCreateData.fs
                                ]
                                [ FS.fileStructure
                                    { isFileSelected = viewingFile
                                    , fileSelectedMsg = BigbitFileSelected
                                    , folderSelectedMsg = BigbitFSToggleFolder
                                    }
                                    model.bigbitCreateData.fs
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
                                                    Bigbit.AddingFolder ->
                                                        case validFolderInputResult of
                                                            Ok _ ->
                                                                text "Create folder and parent directories"

                                                            Err err ->
                                                                text <|
                                                                    case err of
                                                                        Bigbit.FolderAlreadyExists ->
                                                                            "That folder already exists"

                                                                        Bigbit.FolderHasDoubleSlash ->
                                                                            "You cannot have two slashes in a row"

                                                                        Bigbit.FolderHasInvalidCharacters ->
                                                                            "You are using invalid characters"

                                                                        Bigbit.FolderIsEmpty ->
                                                                            ""

                                                    Bigbit.AddingFile ->
                                                        case validFileInputResult of
                                                            Ok _ ->
                                                                text "Create file and parent directories"

                                                            Err err ->
                                                                case err of
                                                                    Bigbit.FileAlreadyExists ->
                                                                        text "That file already exists"

                                                                    Bigbit.FileEndsInSlash ->
                                                                        text "Files cannot end in a slash"

                                                                    Bigbit.FileHasDoubleSlash ->
                                                                        text "You cannot have two slashes in a row"

                                                                    Bigbit.FileHasInvalidCharacters ->
                                                                        text "You are using invalid characters"

                                                                    Bigbit.FileHasInvalidExtension ->
                                                                        text "You must have a valid file extension"

                                                                    Bigbit.FileIsEmpty ->
                                                                        text ""

                                                                    Bigbit.FileLanguageIsAmbiguous languages ->
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

                                                    Bigbit.RemovingFolder ->
                                                        case validRemoveFolderInputResult of
                                                            Ok _ ->
                                                                if .actionButtonSubmitConfirmed <| FS.getFSMetadata model.bigbitCreateData.fs then
                                                                    text "Are you sure? This will also delete all linked frames!"
                                                                else
                                                                    text "Remove folder"

                                                            Err err ->
                                                                case err of
                                                                    Bigbit.RemoveFolderIsEmpty ->
                                                                        text ""

                                                                    Bigbit.RemoveFolderIsRootFolder ->
                                                                        text "You cannot remove the root directory"

                                                                    Bigbit.RemoveFolderDoesNotExist ->
                                                                        text "Folder doesn't exist"

                                                    Bigbit.RemovingFile ->
                                                        case validRemoveFileInputResult of
                                                            Ok _ ->
                                                                if .actionButtonSubmitConfirmed <| FS.getFSMetadata model.bigbitCreateData.fs then
                                                                    text "Are you sure? This will also delete all linked frames!"
                                                                else
                                                                    text "Remove file"

                                                            Err err ->
                                                                case err of
                                                                    Bigbit.RemoveFileIsEmpty ->
                                                                        text ""

                                                                    Bigbit.RemoveFileDoesNotExist ->
                                                                        text "File doesn't exist"
                                        ]
                                    , input
                                        [ id "fs-action-input-box"
                                        , placeholder "Absolute Path"
                                        , onInput BigbitUpdateActionInput
                                        , Util.onEnter <| BigbitSubmitActionInput
                                        , value
                                            (model.bigbitCreateData.fs
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
                                                                  , model.bigbitCreateData.fs
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
                                                    Bigbit.AddingFile ->
                                                        showSubmitIconIf validFileInput True

                                                    Bigbit.AddingFolder ->
                                                        showSubmitIconIf validFolderInput True

                                                    Bigbit.RemovingFile ->
                                                        showSubmitIconIf validRemoveFileInput False

                                                    Bigbit.RemovingFolder ->
                                                        showSubmitIconIf validRemoveFolderInput False
                                    ]
                                , button
                                    [ classList
                                        [ ( "add-file", True )
                                        , ( "selected-action-button"
                                          , Bigbit.fsActionStateEquals (Just Bigbit.AddingFile) model.bigbitCreateData.fs
                                          )
                                        ]
                                    , onClick <| BigbitUpdateActionButtonState <| Just Bigbit.AddingFile
                                    ]
                                    [ text "Add File" ]
                                , button
                                    [ classList
                                        [ ( "add-folder", True )
                                        , ( "selected-action-button"
                                          , Bigbit.fsActionStateEquals (Just Bigbit.AddingFolder) model.bigbitCreateData.fs
                                          )
                                        ]
                                    , onClick <| BigbitUpdateActionButtonState <| Just Bigbit.AddingFolder
                                    ]
                                    [ text "Add Folder" ]
                                , button
                                    [ classList
                                        [ ( "remove-file", True )
                                        , ( "selected-action-button"
                                          , Bigbit.fsActionStateEquals (Just Bigbit.RemovingFile) model.bigbitCreateData.fs
                                          )
                                        ]
                                    , onClick <| BigbitUpdateActionButtonState <| Just Bigbit.RemovingFile
                                    ]
                                    [ text "Remove File" ]
                                , button
                                    [ classList
                                        [ ( "remove-folder", True )
                                        , ( "selected-action-button"
                                          , Bigbit.fsActionStateEquals (Just Bigbit.RemovingFolder) model.bigbitCreateData.fs
                                          )
                                        ]
                                    , onClick <| BigbitUpdateActionButtonState <| Just Bigbit.RemovingFolder
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
                                    ]
                                    [ if Bigbit.isFSOpen model.bigbitCreateData.fs then
                                        text "Close File Structure"
                                      else
                                        text "View File Structure"
                                    ]
                                , case shared.route of
                                    Route.HomeComponentCreateBigbitCodeIntroduction _ ->
                                        textarea
                                            [ placeholder "Introduction"
                                            , onInput <| BigbitUpdateIntroduction
                                            , hidden <| Bigbit.isFSOpen model.bigbitCreateData.fs
                                            , value model.bigbitCreateData.introduction
                                            ]
                                            []

                                    Route.HomeComponentCreateBigbitCodeFrame frameNumber _ ->
                                        textarea
                                            [ placeholder <| "Frame " ++ (toString frameNumber)
                                            , onInput <| BigbitUpdateFrameComment frameNumber
                                            , value <|
                                                ((Array.get
                                                    (frameNumber - 1)
                                                    model.bigbitCreateData.highlightedComments
                                                 )
                                                    |> Maybe.map .comment
                                                    |> Maybe.withDefault ""
                                                )
                                            , hidden <| Bigbit.isFSOpen model.bigbitCreateData.fs
                                            ]
                                            []

                                    Route.HomeComponentCreateBigbitCodeConclusion _ ->
                                        textarea
                                            [ placeholder "Conclusion"
                                            , onInput BigbitUpdateConclusion
                                            , hidden <| Bigbit.isFSOpen model.bigbitCreateData.fs
                                            , value model.bigbitCreateData.conclusion
                                            ]
                                            []

                                    _ ->
                                        -- Should never happen.
                                        Util.hiddenDiv
                                ]

                        tabBar =
                            let
                                dynamicFrameButtons =
                                    (Array.indexedMap
                                        (\index highlightedComment ->
                                            button
                                                [ classList [ ( "selected-frame", (Just <| index + 1) == frameTab ) ]
                                                , onClick <|
                                                    GoTo <|
                                                        Route.HomeComponentCreateBigbitCodeFrame
                                                            (index + 1)
                                                            (Array.get index model.bigbitCreateData.highlightedComments
                                                                |> Maybe.andThen .fileAndRange
                                                                |> Maybe.map .file
                                                            )
                                                ]
                                                [ text <| toString <| index + 1 ]
                                        )
                                        model.bigbitCreateData.highlightedComments
                                    )
                                        |> Array.toList
                            in
                                div
                                    [ class "comment-body-bottom-buttons"
                                    , hidden <| Bigbit.isFSOpen model.bigbitCreateData.fs
                                    ]
                                    ([ button
                                        [ onClick <| GoTo <| Route.HomeComponentCreateBigbitCodeIntroduction Nothing
                                        , classList [ ( "selected-frame", introTab ) ]
                                        ]
                                        [ text "Introduction" ]
                                     , button
                                        [ onClick <| GoTo <| Route.HomeComponentCreateBigbitCodeConclusion Nothing
                                        , classList [ ( "selected-frame", conclusionTab ) ]
                                        ]
                                        [ text "Conclusion" ]
                                     , button
                                        [ class "action-button plus-button"
                                        , onClick <| BigbitAddFrame
                                        ]
                                        [ text "+" ]
                                     , button
                                        [ class "action-button"
                                        , onClick <| BigbitRemoveFrame
                                        , disabled <|
                                            Array.length model.bigbitCreateData.highlightedComments
                                                <= 1
                                        ]
                                        [ text "-" ]
                                     , hr [] []
                                     ]
                                        ++ dynamicFrameButtons
                                    )
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
                [ class "create-tidbit-sub-bar" ]
                [ button
                    [ class "sub-bar-button"
                    , onClick <| GoTo Route.HomeComponentCreate
                    ]
                    [ text "Back" ]
                , button
                    [ class "sub-bar-button"
                    , onClick <| BigbitReset
                    ]
                    [ text "Reset" ]
                , publishButton
                ]
            , createBigbitNavbar
            , case shared.route of
                Route.HomeComponentCreateBigbitName ->
                    div
                        [ class "create-bigbit-name" ]
                        [ input
                            [ placeholder "Name"
                            , onInput BigbitUpdateName
                            , value model.bigbitCreateData.name
                            , Util.onEnter <|
                                if String.isEmpty model.bigbitCreateData.name then
                                    NoOp
                                else
                                    GoTo Route.HomeComponentCreateBigbitDescription
                            ]
                            []
                        ]

                Route.HomeComponentCreateBigbitDescription ->
                    div
                        [ class "create-bigbit-description" ]
                        [ textarea
                            [ placeholder "Description"
                            , onInput BigbitUpdateDescription
                            , value model.bigbitCreateData.description
                            ]
                            []
                        ]

                Route.HomeComponentCreateBigbitTags ->
                    div
                        [ class "create-tidbit-tags" ]
                        [ input
                            [ placeholder "Tags"
                            , onInput BigbitUpdateTagInput
                            , value model.bigbitCreateData.tagInput
                            , Util.onEnter <|
                                BigbitAddTag model.bigbitCreateData.tagInput
                            ]
                            []
                        , makeHTMLTags BigbitRemoveTag model.bigbitCreateData.tags
                        ]

                Route.HomeComponentCreateBigbitCodeIntroduction _ ->
                    bigbitCodeTab

                Route.HomeComponentCreateBigbitCodeFrame frameNumber _ ->
                    bigbitCodeTab

                Route.HomeComponentCreateBigbitCodeConclusion _ ->
                    bigbitCodeTab

                -- Should never happen
                _ ->
                    div [] []
            , div
                [ class "invisible-bottom" ]
                []
            ]


{-| View for creating a snipbit.
-}
createSnipbitView : Model -> Shared -> Html Msg
createSnipbitView model shared =
    let
        currentRoute : Route.Route
        currentRoute =
            shared.route

        viewMenu : Html Msg
        viewMenu =
            div
                [ classList
                    [ ( "hidden"
                      , String.isEmpty model.snipbitCreateData.languageQuery
                            || Util.isNotNothing
                                model.snipbitCreateData.language
                      )
                    ]
                ]
                [ Html.map
                    SnipbitUpdateACState
                    (AC.view
                        acViewConfig
                        model.snipbitCreateData.languageListHowManyToShow
                        model.snipbitCreateData.languageQueryACState
                        (filterLanguagesByQuery
                            model.snipbitCreateData.languageQuery
                            shared.languages
                        )
                    )
                ]

        acViewConfig : AC.ViewConfig ( Editor.Language, String )
        acViewConfig =
            let
                customizedLi keySelected mouseSelected languagePair =
                    { attributes =
                        [ classList
                            [ ( "lang-select-ac-item", True )
                            , ( "key-selected", keySelected || mouseSelected )
                            ]
                        ]
                    , children = [ Html.text (Tuple.second languagePair) ]
                    }
            in
                AC.viewConfig
                    { toId = (toString << Tuple.first)
                    , ul = [ class "lang-select-ac" ]
                    , li = customizedLi
                    }

        createSnipbitNavbar : Html Msg
        createSnipbitNavbar =
            div
                [ classList [ ( "create-tidbit-navbar", True ) ] ]
                [ div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
                          , currentRoute == Route.HomeComponentCreateSnipbitName
                          )
                        , ( "filled-in", Util.isNotNothing <| Snipbit.createDataNameFilledIn model.snipbitCreateData )
                        ]
                    , onClick <| GoTo Route.HomeComponentCreateSnipbitName
                    ]
                    [ text "Name"
                    , checkIcon
                    ]
                , div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
                          , currentRoute == Route.HomeComponentCreateSnipbitDescription
                          )
                        , ( "filled-in", Util.isNotNothing <| Snipbit.createDataDescriptionFilledIn model.snipbitCreateData )
                        ]
                    , onClick <| GoTo Route.HomeComponentCreateSnipbitDescription
                    ]
                    [ text "Description"
                    , checkIcon
                    ]
                , div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
                          , currentRoute == Route.HomeComponentCreateSnipbitLanguage
                          )
                        , ( "filled-in", Util.isNotNothing <| model.snipbitCreateData.language )
                        ]
                    , onClick <| GoTo Route.HomeComponentCreateSnipbitLanguage
                    ]
                    [ text "Language"
                    , checkIcon
                    ]
                , div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
                          , currentRoute == Route.HomeComponentCreateSnipbitTags
                          )
                        , ( "filled-in", Util.isNotNothing <| Snipbit.createDataTagsFilledIn model.snipbitCreateData )
                        ]
                    , onClick <| GoTo Route.HomeComponentCreateSnipbitTags
                    ]
                    [ text "Tags"
                    , checkIcon
                    ]
                , div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
                          , case currentRoute of
                                Route.HomeComponentCreateSnipbitCodeIntroduction ->
                                    True

                                Route.HomeComponentCreateSnipbitCodeConclusion ->
                                    True

                                Route.HomeComponentCreateSnipbitCodeFrame _ ->
                                    True

                                _ ->
                                    False
                          )
                        , ( "filled-in", Snipbit.createDataCodeTabFilledIn model.snipbitCreateData )
                        ]
                    , onClick <| GoTo Route.HomeComponentCreateSnipbitCodeIntroduction
                    ]
                    [ text "Code"
                    , checkIcon
                    ]
                ]

        nameView : Html Msg
        nameView =
            div
                [ class "create-snipbit-name" ]
                [ input
                    [ placeholder "Name"
                    , onInput SnipbitUpdateName
                    , value model.snipbitCreateData.name
                    , Util.onEnter <|
                        if String.isEmpty model.snipbitCreateData.name then
                            NoOp
                        else
                            GoTo Route.HomeComponentCreateSnipbitDescription
                    ]
                    []
                ]

        descriptionView : Html Msg
        descriptionView =
            div
                [ class "create-snipbit-description" ]
                [ textarea
                    [ class "create-snipbit-description-box"
                    , placeholder "Description"
                    , onInput SnipbitUpdateDescription
                    , value model.snipbitCreateData.description
                    ]
                    []
                ]

        languageView : Html Msg
        languageView =
            div
                [ class "create-snipbit-language" ]
                [ input
                    [ placeholder "Language"
                    , id "language-query-input"
                    , onInput SnipbitUpdateLanguageQuery
                    , value model.snipbitCreateData.languageQuery
                    , disabled <|
                        Util.isNotNothing
                            model.snipbitCreateData.language
                    ]
                    []
                , viewMenu
                , button
                    [ onClick <| SnipbitSelectLanguage Nothing
                    , classList
                        [ ( "hidden"
                          , Util.isNothing
                                model.snipbitCreateData.language
                          )
                        ]
                    ]
                    [ text "change language" ]
                ]

        tagsView : Html Msg
        tagsView =
            div
                [ class "create-tidbit-tags" ]
                [ input
                    [ placeholder "Tags"
                    , onInput SnipbitUpdateTagInput
                    , value model.snipbitCreateData.tagInput
                    , Util.onEnter <|
                        SnipbitAddTag
                            model.snipbitCreateData.tagInput
                    ]
                    []
                , makeHTMLTags SnipbitRemoveTag model.snipbitCreateData.tags
                ]

        tidbitView : Html Msg
        tidbitView =
            let
                body =
                    case shared.route of
                        Route.HomeComponentCreateSnipbitCodeIntroduction ->
                            div
                                [ class "comment-body" ]
                                [ textarea
                                    [ placeholder "Introduction"
                                    , onInput <| SnipbitUpdateIntroduction
                                    , value model.snipbitCreateData.introduction
                                    ]
                                    []
                                ]

                        Route.HomeComponentCreateSnipbitCodeFrame frameNumber ->
                            let
                                frameIndex =
                                    frameNumber - 1
                            in
                                div
                                    [ class "comment-body" ]
                                    [ textarea
                                        [ placeholder <|
                                            "Frame "
                                                ++ (toString <| frameNumber)
                                        , onInput <|
                                            SnipbitUpdateFrameComment frameIndex
                                        , value <|
                                            case
                                                (Array.get
                                                    frameIndex
                                                    model.snipbitCreateData.highlightedComments
                                                )
                                            of
                                                Nothing ->
                                                    ""

                                                Just maybeHC ->
                                                    case maybeHC.comment of
                                                        Nothing ->
                                                            ""

                                                        Just comment ->
                                                            comment
                                        ]
                                        []
                                    ]

                        Route.HomeComponentCreateSnipbitCodeConclusion ->
                            div
                                [ class "comment-body" ]
                                [ textarea
                                    [ placeholder "Conclusion"
                                    , onInput <| SnipbitUpdateConclusion
                                    , value model.snipbitCreateData.conclusion
                                    ]
                                    []
                                ]

                        -- Should never happen.
                        _ ->
                            div
                                []
                                []

                tabBar =
                    let
                        dynamicFrameButtons =
                            (Array.toList <|
                                Array.indexedMap
                                    (\index maybeHighlightedComment ->
                                        button
                                            [ onClick <|
                                                GoTo <|
                                                    Route.HomeComponentCreateSnipbitCodeFrame
                                                        (index + 1)
                                            , classList
                                                [ ( "selected-frame"
                                                  , shared.route
                                                        == (Route.HomeComponentCreateSnipbitCodeFrame <|
                                                                index
                                                                    + 1
                                                           )
                                                  )
                                                ]
                                            ]
                                            [ text <| toString <| index + 1 ]
                                    )
                                    model.snipbitCreateData.highlightedComments
                            )
                    in
                        div
                            [ class "comment-body-bottom-buttons" ]
                            (List.concat
                                [ [ button
                                        [ onClick <|
                                            GoTo Route.HomeComponentCreateSnipbitCodeIntroduction
                                        , classList
                                            [ ( "selected-frame"
                                              , shared.route
                                                    == Route.HomeComponentCreateSnipbitCodeIntroduction
                                              )
                                            ]
                                        ]
                                        [ text "Introduction" ]
                                  , button
                                        [ onClick <|
                                            GoTo Route.HomeComponentCreateSnipbitCodeConclusion
                                        , classList
                                            [ ( "selected-frame"
                                              , shared.route
                                                    == Route.HomeComponentCreateSnipbitCodeConclusion
                                              )
                                            ]
                                        ]
                                        [ text "Conclusion" ]
                                  , button
                                        [ class "action-button plus-button"
                                        , onClick <| SnipbitAddFrame
                                        ]
                                        [ text "+" ]
                                  , button
                                        [ class "action-button"
                                        , onClick <| SnipbitRemoveFrame
                                        , disabled <|
                                            Array.length
                                                model.snipbitCreateData.highlightedComments
                                                <= 1
                                        ]
                                        [ text "-" ]
                                  , hr [] []
                                  ]
                                , dynamicFrameButtons
                                ]
                            )
            in
                div
                    [ class "create-snipbit-code" ]
                    [ Editor.editor "create-snipbit-code-editor"
                    , div
                        [ class "comment-creator" ]
                        [ div
                            [ class "above-editor-text" ]
                            [ text <|
                                if currentRoute == Route.HomeComponentCreateSnipbitCodeIntroduction then
                                    "Snipbit introductions do not link to highlights, but you can browse and edit your code"
                                else if currentRoute == Route.HomeComponentCreateSnipbitCodeConclusion then
                                    "Snipbit conclusions do not link to highlights, but you can browse and edit your code"
                                else
                                    ""
                            ]
                        , body
                        , tabBar
                        ]
                    ]

        viewForTab : Html Msg
        viewForTab =
            case currentRoute of
                Route.HomeComponentCreateSnipbitName ->
                    nameView

                Route.HomeComponentCreateSnipbitDescription ->
                    descriptionView

                Route.HomeComponentCreateSnipbitLanguage ->
                    languageView

                Route.HomeComponentCreateSnipbitTags ->
                    tagsView

                Route.HomeComponentCreateSnipbitCodeIntroduction ->
                    tidbitView

                Route.HomeComponentCreateSnipbitCodeConclusion ->
                    tidbitView

                Route.HomeComponentCreateSnipbitCodeFrame _ ->
                    tidbitView

                -- Default to name view.
                _ ->
                    nameView

        {- It should be disabled unles everything is filled out. -}
        publishButton =
            case Snipbit.createDataToPublicationData model.snipbitCreateData of
                Nothing ->
                    button
                        [ class "create-snipbit-disabled-publish-button"
                        , disabled True
                        ]
                        [ text "Publish" ]

                Just publicationData ->
                    button
                        [ classList
                            [ ( "create-snipbit-publish-button", True )
                            ]
                        , onClick <| SnipbitPublish publicationData
                        ]
                        [ text "Publish" ]
    in
        div
            [ class "create-snipbit" ]
            [ div
                [ class "create-tidbit-sub-bar" ]
                [ button
                    [ class "create-snipbit-back-button"
                    , onClick <| GoTo Route.HomeComponentCreate
                    ]
                    [ text "Back" ]
                , button
                    [ class "create-snipbit-reset-button"
                    , onClick <| SnipbitReset
                    ]
                    [ text "Reset" ]
                , publishButton
                ]
            , div
                []
                [ createSnipbitNavbar
                , viewForTab
                ]
            , div
                [ class "invisible-bottom" ]
                []
            ]
