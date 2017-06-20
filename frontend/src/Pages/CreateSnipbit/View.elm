module Pages.CreateSnipbit.View exposing (..)

import Array
import Autocomplete as AC
import DefaultServices.TextFields as TextFields
import DefaultServices.Util as Util
import Elements.Simple.Editor as Editor
import Elements.Simple.Tags as Tags
import Html exposing (Html, button, div, hr, text)
import Html.Attributes exposing (class, classList, defaultValue, disabled, hidden, id, placeholder)
import Html.Events exposing (onClick, onInput)
import Keyboard.Extra as KK
import Models.RequestTracker as RT
import Models.Route as Route
import Pages.CreateSnipbit.Messages exposing (..)
import Pages.CreateSnipbit.Model exposing (..)
import Pages.Model exposing (Shared, kkUpdateWrapper)


{-| `CreateSnipbit` view.
-}
view : Model -> Shared -> Html Msg
view model shared =
    let
        currentRoute : Route.Route
        currentRoute =
            shared.route

        viewMenu : Html Msg
        viewMenu =
            div
                [ classList [ ( "hidden", String.isEmpty model.languageQuery || Util.isNotNothing model.language ) ]
                ]
                [ Html.map
                    OnUpdateACState
                    (AC.view
                        acViewConfig
                        model.languageListHowManyToShow
                        model.languageQueryACState
                        (filterLanguagesByQuery
                            model.languageQuery
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
                { toId = toString << Tuple.first
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
                        , ( "create-tidbit-selected-tab", currentRoute == Route.CreateSnipbitNamePage )
                        , ( "filled-in", Util.isNotNothing <| nameFilledIn model )
                        ]
                    , onClick <| GoTo Route.CreateSnipbitNamePage
                    ]
                    [ text "Name" ]
                , div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab", currentRoute == Route.CreateSnipbitDescriptionPage )
                        , ( "filled-in", Util.isNotNothing <| descriptionFilledIn model )
                        ]
                    , onClick <| GoTo Route.CreateSnipbitDescriptionPage
                    ]
                    [ text "Description" ]
                , div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab", currentRoute == Route.CreateSnipbitLanguagePage )
                        , ( "filled-in", Util.isNotNothing <| model.language )
                        ]
                    , onClick <| GoTo Route.CreateSnipbitLanguagePage
                    ]
                    [ text "Language" ]
                , div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab", currentRoute == Route.CreateSnipbitTagsPage )
                        , ( "filled-in", Util.isNotNothing <| tagsFilledIn model )
                        ]
                    , onClick <| GoTo Route.CreateSnipbitTagsPage
                    ]
                    [ text "Tags" ]
                , div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
                          , case currentRoute of
                                Route.CreateSnipbitCodeIntroductionPage ->
                                    True

                                Route.CreateSnipbitCodeConclusionPage ->
                                    True

                                Route.CreateSnipbitCodeFramePage _ ->
                                    True

                                _ ->
                                    False
                          )
                        , ( "filled-in", codeTabFilledIn model )
                        ]
                    , onClick <| GoToCodeTab
                    ]
                    [ text "Code" ]
                ]

        nameView : Html Msg
        nameView =
            div
                [ class "create-snipbit-name" ]
                [ TextFields.input
                    shared.textFieldKeyTracker
                    "create-snipbit-name"
                    [ placeholder "Name"
                    , id "name-input"
                    , onInput OnUpdateName
                    , defaultValue model.name
                    , Util.onKeydownPreventDefault
                        (\key ->
                            if key == KK.Tab then
                                Just NoOp
                            else
                                Nothing
                        )
                    ]
                , Util.limitCharsText 50 model.name
                ]

        descriptionView : Html Msg
        descriptionView =
            div
                [ class "create-snipbit-description" ]
                [ TextFields.textarea
                    shared.textFieldKeyTracker
                    "create-snipbit-description"
                    [ class "create-snipbit-description-box"
                    , placeholder "Description"
                    , id "description-input"
                    , onInput OnUpdateDescription
                    , defaultValue model.description
                    , Util.onKeydownPreventDefault
                        (\key ->
                            if key == KK.Tab then
                                Just NoOp
                            else
                                Nothing
                        )
                    ]
                , Util.limitCharsText 300 model.description
                ]

        languageView : Html Msg
        languageView =
            div
                [ class "create-snipbit-language" ]
                [ TextFields.input
                    shared.textFieldKeyTracker
                    "create-snipbit-language"
                    [ placeholder "Language"
                    , id "language-query-input"
                    , onInput OnUpdateLanguageQuery
                    , defaultValue model.languageQuery
                    , disabled <|
                        Util.isNotNothing
                            model.language
                    , Util.onKeydownPreventDefault
                        (\key ->
                            if key == KK.Tab then
                                Just NoOp
                            else
                                Nothing
                        )
                    ]
                , viewMenu
                , button
                    [ onClick <| SelectLanguage Nothing
                    , classList [ ( "hidden", Util.isNothing model.language ) ]
                    ]
                    [ text "change language" ]
                ]

        tagsView : Html Msg
        tagsView =
            div
                [ class "create-tidbit-tags" ]
                [ TextFields.input
                    shared.textFieldKeyTracker
                    "create-snipbit-tags"
                    [ placeholder "Tags"
                    , id "tags-input"
                    , onInput OnUpdateTagInput
                    , defaultValue model.tagInput
                    , Util.onKeydownPreventDefault
                        (\key ->
                            if key == KK.Enter then
                                Just <| AddTag model.tagInput
                            else if key == KK.Tab then
                                Just <| NoOp
                            else
                                Nothing
                        )
                    ]
                , Tags.view RemoveTag model.tags
                ]

        tidbitView : Html Msg
        tidbitView =
            let
                markdownOpen =
                    model.previewMarkdown

                body =
                    div
                        [ class "comment-body" ]
                        [ div
                            [ class "preview-markdown"
                            , onClick TogglePreviewMarkdown
                            ]
                            [ if markdownOpen then
                                text "Close Preview"
                              else
                                text "Markdown Preview"
                            ]
                        , case shared.route of
                            Route.CreateSnipbitCodeIntroductionPage ->
                                Util.markdownOr
                                    markdownOpen
                                    model.introduction
                                    (TextFields.textarea
                                        shared.textFieldKeyTracker
                                        "create-snipbit-introduction"
                                        [ placeholder "General Introduction"
                                        , id "introduction-input"
                                        , onInput <| OnUpdateIntroduction
                                        , defaultValue model.introduction
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
                                                        Just <| GoTo <| Route.CreateSnipbitCodeFramePage 1
                                                    else if KK.isTwoKeysPressed KK.Tab KK.Shift newKeysDown then
                                                        Just <| GoTo <| Route.CreateSnipbitTagsPage
                                                    else
                                                        Nothing
                                                else
                                                    Nothing
                                            )
                                        ]
                                    )

                            Route.CreateSnipbitCodeFramePage frameNumber ->
                                let
                                    frameIndex =
                                        frameNumber - 1

                                    frameText =
                                        Array.get frameIndex model.highlightedComments
                                            |> Maybe.andThen .comment
                                            |> Maybe.withDefault ""
                                in
                                Util.markdownOr
                                    markdownOpen
                                    frameText
                                    (TextFields.textarea
                                        shared.textFieldKeyTracker
                                        ("create-snipbit-frame-" ++ toString frameNumber)
                                        [ placeholder <|
                                            "Frame "
                                                ++ toString frameNumber
                                                ++ "\n\n"
                                                ++ "Highlight a chunk of code and explain it..."
                                        , id "frame-input"
                                        , onInput <| OnUpdateFrameComment frameIndex
                                        , defaultValue frameText
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
                                                                Route.CreateSnipbitCodeFramePage
                                                                    (frameNumber + 1)
                                                    else if KK.isTwoKeysPressed KK.Tab KK.Shift newKeysDown then
                                                        Just <|
                                                            GoTo <|
                                                                Route.CreateSnipbitCodeFramePage
                                                                    (frameNumber - 1)
                                                    else
                                                        Nothing
                                                else
                                                    Nothing
                                            )
                                        ]
                                    )

                            Route.CreateSnipbitCodeConclusionPage ->
                                Util.markdownOr
                                    markdownOpen
                                    model.conclusion
                                    (TextFields.textarea
                                        shared.textFieldKeyTracker
                                        "create-snipbit-conclusion"
                                        [ placeholder "General Conclusion"
                                        , id "conclusion-input"
                                        , onInput <| OnUpdateConclusion
                                        , defaultValue model.conclusion
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
                                                        Just NoOp
                                                    else if KK.isTwoKeysPressed KK.Tab KK.Shift newKeysDown then
                                                        Just <|
                                                            GoTo <|
                                                                Route.CreateSnipbitCodeFramePage
                                                                    (Array.length model.highlightedComments)
                                                    else
                                                        Nothing
                                                else
                                                    Nothing
                                            )
                                        ]
                                    )

                            _ ->
                                Util.hiddenDiv
                        ]

                tabBar =
                    let
                        dynamicFrameButtons =
                            div
                                [ class "frame-buttons-box" ]
                                (Array.toList <|
                                    Array.indexedMap
                                        (\index maybeHighlightedComment ->
                                            button
                                                [ onClick <| GoTo <| Route.CreateSnipbitCodeFramePage (index + 1)
                                                , classList
                                                    [ ( "selected-frame"
                                                      , shared.route == (Route.CreateSnipbitCodeFramePage <| index + 1)
                                                      )
                                                    ]
                                                ]
                                                [ text <| toString <| index + 1 ]
                                        )
                                        model.highlightedComments
                                )
                    in
                    div
                        [ class "comment-body-bottom-buttons"
                        , hidden <| markdownOpen
                        ]
                        [ button
                            [ onClick <| GoTo Route.CreateSnipbitCodeIntroductionPage
                            , classList
                                [ ( "selected-frame", shared.route == Route.CreateSnipbitCodeIntroductionPage )
                                , ( "introduction-button", True )
                                ]
                            ]
                            [ text "Introduction" ]
                        , button
                            [ onClick <| GoTo Route.CreateSnipbitCodeConclusionPage
                            , classList
                                [ ( "selected-frame", shared.route == Route.CreateSnipbitCodeConclusionPage )
                                , ( "conclusion-button", True )
                                ]
                            ]
                            [ text "Conclusion" ]
                        , button
                            [ class "add-or-remove-frame-button"
                            , onClick <| AddFrame
                            ]
                            [ text "+" ]
                        , button
                            [ class "add-or-remove-frame-button"
                            , onClick <| RemoveFrame
                            , disabled <| Array.length model.highlightedComments <= 1
                            ]
                            [ text "-" ]
                        , hr [] []
                        , dynamicFrameButtons
                        ]
            in
            div
                [ class "create-snipbit-code" ]
                [ Editor.view "create-snipbit-code-editor"
                , div
                    [ class "comment-creator" ]
                    [ body
                    , tabBar
                    ]
                ]

        viewForTab : Html Msg
        viewForTab =
            case currentRoute of
                Route.CreateSnipbitNamePage ->
                    nameView

                Route.CreateSnipbitDescriptionPage ->
                    descriptionView

                Route.CreateSnipbitLanguagePage ->
                    languageView

                Route.CreateSnipbitTagsPage ->
                    tagsView

                Route.CreateSnipbitCodeIntroductionPage ->
                    tidbitView

                Route.CreateSnipbitCodeConclusionPage ->
                    tidbitView

                Route.CreateSnipbitCodeFramePage _ ->
                    tidbitView

                -- Default to name view.
                _ ->
                    nameView

        {- It should be disabled unles everything is filled out. -}
        publishButton =
            case toPublicationData model of
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
                            , ( "cursor-progress", RT.isMakingRequest shared.apiRequestTracker RT.PublishSnipbit )
                            ]
                        , onClick <| Publish publicationData
                        ]
                        [ text "Publish" ]
    in
    div
        [ class "create-snipbit" ]
        [ div
            [ class "sub-bar" ]
            [ button
                [ class "create-snipbit-reset-button"
                , onClick <| Reset
                ]
                [ text "Reset" ]
            , publishButton
            , case previousFrameRange model shared.route of
                Nothing ->
                    Util.hiddenDiv

                Just _ ->
                    button
                        [ class "sub-bar-button previous-frame-location"
                        , onClick JumpToLineFromPreviousFrame
                        ]
                        [ text "Previous Frame Location" ]
            ]
        , div
            []
            [ createSnipbitNavbar
            , viewForTab
            ]
        ]
