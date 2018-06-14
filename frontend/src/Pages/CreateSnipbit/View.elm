module Pages.CreateSnipbit.View exposing (..)

import Array
import Autocomplete as AC
import DefaultServices.TextFields as TextFields
import DefaultServices.Util as Util
import Elements.Simple.Editor as Editor
import ExplanatoryBlurbs exposing (markdownFramePlaceholder)
import Html exposing (Html, button, div, hr, i, text)
import Html.Attributes exposing (class, classList, defaultValue, disabled, hidden, id, placeholder)
import Html.Events exposing (onClick, onInput)
import Keyboard.Extra as KK
import Models.RequestTracker as RT
import Models.Route as Route
import Pages.CreateSnipbit.Messages exposing (..)
import Pages.CreateSnipbit.Model exposing (..)
import Pages.Messages as BaseMessage
import Pages.Model exposing (Shared)


{-| `CreateSnipbit` view.
-}
view : (Msg -> BaseMessage.Msg) -> Model -> Shared -> Html BaseMessage.Msg
view subMsg model shared =
    let
        currentRoute : Route.Route
        currentRoute =
            shared.route

        viewMenu : Html BaseMessage.Msg
        viewMenu =
            div
                [ classList [ ( "hidden", not <| languageACActive shared.route model ) ]
                ]
                [ Html.map
                    (subMsg << OnUpdateACState)
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

        createSnipbitNavbar : Html BaseMessage.Msg
        createSnipbitNavbar =
            div
                [ classList [ ( "create-tidbit-navbar", True ) ] ]
                [ div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab", currentRoute == Route.CreateSnipbitInfoPage )
                        , ( "filled-in", Util.isNotNothing <| nameFilledIn model )
                        ]
                    , onClick <| BaseMessage.GoTo { wipeModalError = False } Route.CreateSnipbitInfoPage
                    ]
                    [ text "Info" ]
                , div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
                          , case currentRoute of
                                Route.CreateSnipbitCodeFramePage _ ->
                                    True

                                _ ->
                                    False
                          )
                        , ( "filled-in", codeTabFilledIn model )
                        ]
                    , onClick <| subMsg GoToCodeTab
                    ]
                    [ text "Code" ]
                , div
                    [ classList
                        [ ( "create-tidbit-tab", True )

                        -- TODO Change
                        , ( "create-tidbit-selected-tab", False )
                        , ( "filled-in", False )
                        ]
                    ]
                    [ text "Quiz" ]
                ]

        infoView : Html BaseMessage.Msg
        infoView =
            div
                [ class "create-snipbit-name" ]
                [ TextFields.input
                    shared.textFieldKeyTracker
                    "create-snipbit-name"
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

        tidbitView : Html BaseMessage.Msg
        tidbitView =
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
                                text "Markdown Preview"
                            ]
                        , case shared.route of
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
                                        [ placeholder <| markdownFramePlaceholder frameNumber
                                        , id "frame-input"
                                        , onInput <| subMsg << OnUpdateFrameComment frameIndex
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
                                                                      , if
                                                                            frameNumber
                                                                                == Array.length
                                                                                    model.highlightedComments
                                                                        then
                                                                            BaseMessage.NoOp
                                                                        else
                                                                            BaseMessage.GoTo
                                                                                { wipeModalError = False }
                                                                            <|
                                                                                Route.CreateSnipbitCodeFramePage
                                                                                    (frameNumber + 1)
                                                                      )
                                                                    , ( [ KK.Tab, KK.Shift ]
                                                                      , BaseMessage.GoTo { wipeModalError = False } <|
                                                                            Route.CreateSnipbitCodeFramePage
                                                                                (frameNumber - 1)
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
                                                [ onClick <|
                                                    BaseMessage.GoTo { wipeModalError = False } <|
                                                        Route.CreateSnipbitCodeFramePage (index + 1)
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
                            [ class "add-or-remove-frame-button"
                            , onClick <| subMsg <| AddFrame
                            ]
                            [ text "+" ]
                        , button
                            [ classList
                                [ ( "add-or-remove-frame-button", True )
                                , ( "confirmed", model.confirmedRemoveFrame )
                                ]
                            , onClick <| subMsg <| RemoveFrame
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
                    [ classList [ ( "lock-icon", True ) ]
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
                    [ class "comment-creator" ]
                    [ body
                    , tabBar
                    ]
                ]

        viewForTab : Html BaseMessage.Msg
        viewForTab =
            case currentRoute of
                Route.CreateSnipbitInfoPage ->
                    infoView

                Route.CreateSnipbitCodeFramePage _ ->
                    tidbitView

                -- Default to name view.
                _ ->
                    infoView

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
                        , onClick <| subMsg <| Publish publicationData
                        ]
                        [ text "Publish" ]
    in
    div
        [ class "create-snipbit" ]
        [ div
            [ class "sub-bar" ]
            [ button
                [ classList [ ( "create-snipbit-reset-button", True ), ( "confirmed", model.confirmedReset ) ]
                , onClick <| subMsg <| Reset
                ]
                [ text "Reset" ]
            , publishButton
            , case previousFrameRange model shared.route of
                Nothing ->
                    Util.hiddenDiv

                Just _ ->
                    button
                        [ class "sub-bar-button previous-frame-location"
                        , onClick <| subMsg JumpToLineFromPreviousFrame
                        ]
                        [ text "Previous Frame Location" ]
            ]
        , div
            []
            [ createSnipbitNavbar
            , viewForTab
            ]
        ]
