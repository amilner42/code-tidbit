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
import Html.Attributes exposing (class, classList, disabled, placeholder, value, hidden, id, src)
import Html.Events exposing (onClick, onInput)
import Models.Bigbit as Bigbit
import Models.FileStructure as FS
import Models.Range as Range
import Models.Route as Route
import Models.Snipbit as Snipbit
import Router


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
                        [ class "snipbit-navbar" ]
                        ([ i
                            [ classList
                                [ ( "material-icons action-button", True )
                                , ( "blank-icon"
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
                                [ ( "snipbit-navbar-item", True )
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
                         ]
                            ++ (Array.toList
                                    (Array.indexedMap
                                        (\index _ ->
                                            div
                                                [ onClick <| GoTo <| Route.HomeComponentViewSnipbitFrame snipbit.id (index + 1)
                                                , classList
                                                    [ ( "snipbit-navbar-item", True )
                                                    , ( "selected"
                                                      , case shared.route of
                                                            Route.HomeComponentViewSnipbitFrame _ frameNumber ->
                                                                frameNumber == index + 1

                                                            _ ->
                                                                False
                                                      )
                                                    ]
                                                ]
                                                [ text <| toString <| index + 1 ]
                                        )
                                        snipbit.highlightedComments
                                    )
                               )
                            ++ [ div
                                    [ onClick <| GoTo <| Route.HomeComponentViewSnipbitConclusion snipbit.id
                                    , classList
                                        [ ( "snipbit-navbar-item", True )
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
                                        , ( "blank-icon"
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
                        )
                    , Editor.editor "view-snipbit-code-editor"
                    , div
                        [ class "comment-block" ]
                        [ textarea
                            [ value <|
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

        Route.HomeComponentCreateBigbitCodeIntroduction ->
            createBigbitView model shared

        Route.HomeComponentCreateBigbitCodeFrame _ ->
            createBigbitView model shared

        Route.HomeComponentCreateBigbitCodeConclusion ->
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

                _ ->
                    False

        profileViewSelected =
            shared.route == Route.HomeComponentProfile

        createViewSelected =
            case shared.route of
                Route.HomeComponentCreateSnipbitCodeFrame _ ->
                    True

                Route.HomeComponentCreateBigbitCodeFrame _ ->
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
                        , Route.HomeComponentCreateBigbitCodeIntroduction
                        , Route.HomeComponentCreateBigbitCodeConclusion
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
                        ]
                    , onClick <| GoTo Route.HomeComponentCreateBigbitName
                    ]
                    [ text "Name" ]
                , div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
                          , currentRoute == Route.HomeComponentCreateBigbitDescription
                          )
                        ]
                    , onClick <| GoTo Route.HomeComponentCreateBigbitDescription
                    ]
                    [ text "Description" ]
                , div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
                          , currentRoute == Route.HomeComponentCreateBigbitTags
                          )
                        ]
                    , onClick <| GoTo Route.HomeComponentCreateBigbitTags
                    ]
                    [ text "Tags" ]
                , div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
                          , case currentRoute of
                                Route.HomeComponentCreateBigbitCodeFrame _ ->
                                    True

                                Route.HomeComponentCreateBigbitCodeIntroduction ->
                                    True

                                Route.HomeComponentCreateBigbitCodeConclusion ->
                                    True

                                _ ->
                                    False
                          )
                        ]
                    , onClick <| GoTo Route.HomeComponentCreateBigbitCodeIntroduction
                    ]
                    [ text "Code" ]
                ]

        bigbitCodeTab =
            let
                bigbitEditor =
                    div
                        []
                        [ div
                            [ class "create-tidbit-code" ]
                            [ Editor.editor "create-bigbit-code-editor"
                            ]
                        ]

                bigbitCommentBox =
                    let
                        fs =
                            if Bigbit.isFSOpen model.bigbitCreateData.fs then
                                div
                                    [ class "file-structure" ]
                                    [ i
                                        [ class "material-icons toggle-fs-icon close-fs-icon"
                                        , onClick BigbitToggleFS
                                        ]
                                        [ text "close" ]
                                    , text "File Structure"
                                    , FS.render
                                        { fileStructureClass = "create-bigbit-fs"
                                        , folderAndSubContentClass = "create-bigbit-fs-folder-and-sub-content"
                                        , subContentClass = "create-bigbit-fs-sub-content"
                                        , subFoldersClass = "create-bigbit-fs-sub-folders"
                                        , subFilesClass = "create-bigbit-fs-sub-files"
                                        , renderFile =
                                            (\name absolutePath fileMetadata ->
                                                div
                                                    [ class "create-bigbit-fs-file" ]
                                                    [ i
                                                        [ class "material-icons file-icon" ]
                                                        [ text "insert_drive_file" ]
                                                    , div
                                                        [ class "file-name" ]
                                                        [ text name ]
                                                    ]
                                            )
                                        , renderFolder =
                                            (\name absolutePath folderMetadata ->
                                                div
                                                    [ class "create-bigbit-fs-folder"
                                                    ]
                                                    [ i
                                                        [ class "material-icons folder-icon"
                                                        , onClick <| BigbitFSToggleFolder absolutePath
                                                        ]
                                                        [ if folderMetadata.isExpanded then
                                                            text "folder_open"
                                                          else
                                                            text "folder"
                                                        ]
                                                    , div
                                                        [ class "folder-name"
                                                        , onClick <| BigbitFSToggleFolder absolutePath
                                                        ]
                                                        [ text <| name ++ "/" ]
                                                    ]
                                            )
                                        , expandFolderIf = .isExpanded
                                        }
                                        model.bigbitCreateData.fs
                                    , div
                                        [ class "fs-action-input"
                                        , hidden <| Util.isNothing <| .actionButtonState <| FS.getFSMetadata <| model.bigbitCreateData.fs
                                        ]
                                        [ input
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
                                        , case .actionButtonState <| FS.getFSMetadata <| model.bigbitCreateData.fs of
                                            Nothing ->
                                                Util.hiddenDiv

                                            Just actionState ->
                                                let
                                                    showArrowIf condition =
                                                        if condition then
                                                            i
                                                                [ class "material-icons action-button-arrow"
                                                                , onClick <| BigbitSubmitActionInput
                                                                ]
                                                                [ text "add_box" ]
                                                        else
                                                            Util.hiddenDiv
                                                in
                                                    case actionState of
                                                        Bigbit.AddingFile ->
                                                            showArrowIf <|
                                                                Bigbit.isValidAddFileInput
                                                                    (FS.getFSMetadata model.bigbitCreateData.fs |> .actionButtonInput)
                                                                    model.bigbitCreateData.fs

                                                        Bigbit.AddingFolder ->
                                                            showArrowIf <|
                                                                Bigbit.isValidAddFolderInput
                                                                    (FS.getFSMetadata model.bigbitCreateData.fs |> .actionButtonInput)
                                                                    model.bigbitCreateData.fs

                                                        Bigbit.RemovingFile ->
                                                            div [] []

                                                        Bigbit.RemovingFolder ->
                                                            div [] []
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
                            else
                                i
                                    [ class "material-icons toggle-fs-icon"
                                    , onClick BigbitToggleFS
                                    ]
                                    [ text "view_list" ]

                        body =
                            case shared.route of
                                Route.HomeComponentCreateBigbitCodeIntroduction ->
                                    div
                                        [ class "comment-body" ]
                                        [ fs
                                        , textarea
                                            [ placeholder "Introduction"
                                            , onInput <| BigbitUpdateIntroduction
                                            , hidden <| Bigbit.isFSOpen model.bigbitCreateData.fs
                                            , value model.bigbitCreateData.introduction
                                            ]
                                            []
                                        ]

                                Route.HomeComponentCreateBigbitCodeFrame frameNumber ->
                                    div
                                        []
                                        []

                                Route.HomeComponentCreateBigbitCodeConclusion ->
                                    div
                                        [ class "comment-body" ]
                                        [ fs
                                        , textarea
                                            [ placeholder "Conclusion"
                                            , onInput BigbitUpdateConclusion
                                            , hidden <| Bigbit.isFSOpen model.bigbitCreateData.fs
                                            , value model.bigbitCreateData.conclusion
                                            ]
                                            []
                                        ]

                                -- Should never happen.
                                _ ->
                                    div [] []

                        tabBar =
                            div
                                []
                                []
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

                Route.HomeComponentCreateBigbitCodeIntroduction ->
                    bigbitCodeTab

                Route.HomeComponentCreateBigbitCodeFrame frameNumber ->
                    bigbitCodeTab

                Route.HomeComponentCreateBigbitCodeConclusion ->
                    bigbitCodeTab

                -- Should never happen
                _ ->
                    div [] []
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
                        ]
                    , onClick <| GoTo Route.HomeComponentCreateSnipbitName
                    ]
                    [ text "Name" ]
                , div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
                          , currentRoute == Route.HomeComponentCreateSnipbitDescription
                          )
                        ]
                    , onClick <| GoTo Route.HomeComponentCreateSnipbitDescription
                    ]
                    [ text "Description" ]
                , div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
                          , currentRoute == Route.HomeComponentCreateSnipbitLanguage
                          )
                        ]
                    , onClick <| GoTo Route.HomeComponentCreateSnipbitLanguage
                    ]
                    [ text "Language" ]
                , div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
                          , currentRoute == Route.HomeComponentCreateSnipbitTags
                          )
                        ]
                    , onClick <| GoTo Route.HomeComponentCreateSnipbitTags
                    ]
                    [ text "Tags" ]
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
                        ]
                    , onClick <| GoTo Route.HomeComponentCreateSnipbitCodeIntroduction
                    ]
                    [ text "Code" ]
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
                            []
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
                        [ body
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

        -- Disabled publish button.
        disabledPublishButton =
            button
                [ class "create-snipbit-disabled-publish-button"
                , disabled True
                ]
                [ text "Publish" ]

        {- It should be `disabledPublishButton` unless
           everything is filled out in which case it should be
           the publish button with the info filled for an
           event handler to call the API.
        -}
        currentPublishButton =
            let
                tidbitData =
                    model.snipbitCreateData
            in
                case tidbitData.language of
                    Nothing ->
                        disabledPublishButton

                    Just theLanguage ->
                        if
                            (tidbitData.name /= "")
                                && (tidbitData.description /= "")
                                && (List.length tidbitData.tags > 0)
                                && (tidbitData.code /= "")
                                && (tidbitData.introduction /= "")
                                && (tidbitData.conclusion /= "")
                        then
                            let
                                filledHighlightedComments =
                                    Array.foldr
                                        (\maybeHC previousHC ->
                                            case ( maybeHC.range, maybeHC.comment ) of
                                                ( Just aRange, Just aComment ) ->
                                                    if
                                                        (String.length aComment > 0)
                                                            && (not <| Range.isEmptyRange aRange)
                                                    then
                                                        { range = aRange
                                                        , comment = aComment
                                                        }
                                                            :: previousHC
                                                    else
                                                        previousHC

                                                _ ->
                                                    previousHC
                                        )
                                        []
                                        tidbitData.highlightedComments
                            in
                                if
                                    (List.length filledHighlightedComments)
                                        == (Array.length tidbitData.highlightedComments)
                                then
                                    button
                                        [ classList
                                            [ ( "create-snipbit-publish-button", True )
                                            ]
                                        , onClick <|
                                            SnipbitPublish
                                                { language = theLanguage
                                                , name = tidbitData.name
                                                , description = tidbitData.description
                                                , tags = tidbitData.tags
                                                , code = tidbitData.code
                                                , introduction = tidbitData.introduction
                                                , conclusion = tidbitData.conclusion
                                                , highlightedComments = Array.fromList filledHighlightedComments
                                                }
                                        ]
                                        [ text "Publish" ]
                                else
                                    disabledPublishButton
                        else
                            disabledPublishButton
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
                , currentPublishButton
                ]
            , div
                []
                [ createSnipbitNavbar
                , viewForTab
                ]
            ]
