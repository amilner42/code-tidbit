module Components.Home.View exposing (..)

import Array
import Autocomplete as AC
import Components.Home.Messages exposing (Msg(..))
import Components.Home.Model exposing (Model)
import Components.Home.Update exposing (filterLanguagesByQuery)
import Components.Model exposing (Shared)
import DefaultServices.Util as Util
import Elements.Editor as Editor
import Html exposing (Html, div, text, textarea, button, input, h1, h3)
import Html.Attributes exposing (class, classList, disabled, placeholder, value, hidden, id)
import Html.Events exposing (onClick, onInput)
import Models.Route as Route
import Models.BasicTidbit as BasicTidbit
import Router


{-| Home Component View.
-}
view : Model -> Shared -> Html Msg
view model shared =
    div
        [ class "home-component-wrapper" ]
        [ div
            [ class "home-component" ]
            [ div []
                [ navbar shared
                , displayViewForRoute model shared
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

        Route.HomeComponentCreate ->
            createView model shared

        Route.HomeComponentCreateBasicName ->
            createBasicTidbitView model shared

        Route.HomeComponentCreateBasicDescription ->
            createBasicTidbitView model shared

        Route.HomeComponentCreateBasicLanguage ->
            createBasicTidbitView model shared

        Route.HomeComponentCreateBasicTags ->
            createBasicTidbitView model shared

        Route.HomeComponentCreateBasicTidbit ->
            createBasicTidbitView model shared

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
            shared.route == Route.HomeComponentBrowse

        profileViewSelected =
            shared.route == Route.HomeComponentProfile

        createViewSelected =
            List.member
                shared.route
                [ Route.HomeComponentCreate
                , Route.HomeComponentCreateBasicName
                , Route.HomeComponentCreateBasicDescription
                , Route.HomeComponentCreateBasicLanguage
                , Route.HomeComponentCreateBasicTags
                , Route.HomeComponentCreateBasicTidbit
                ]
    in
        div [ class "nav" ]
            [ div
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
    div
        []
        [ div
            []
            [ h1
                []
                [ text "Select Tidbit Type" ]
            , button
                [ onClick <| GoTo Route.HomeComponentCreateBasicName ]
                [ text "Basic Tidbit" ]
            ]
        ]


{-| View for creating a basic tidbit.
-}
createBasicTidbitView : Model -> Shared -> Html Msg
createBasicTidbitView model shared =
    let
        currentRoute : Route.Route
        currentRoute =
            shared.route

        viewMenu : Html Msg
        viewMenu =
            div
                [ classList
                    [ ( "hidden"
                      , String.isEmpty model.creatingBasicTidbitData.languageQuery
                            || Util.isNotNothing
                                model.creatingBasicTidbitData.language
                      )
                    ]
                ]
                [ Html.map
                    BasicTidbitUpdateACState
                    (AC.view
                        acViewConfig
                        8
                        model.creatingBasicTidbitData.languageQueryACState
                        (filterLanguagesByQuery
                            model.creatingBasicTidbitData.languageQuery
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

        createBasicTidbitNavbar : Html Msg
        createBasicTidbitNavbar =
            div
                [ classList [ ( "create-basic-tidbit-navbar", True ) ] ]
                [ div
                    [ classList
                        [ ( "create-basic-tidbit-tab", True )
                        , ( "create-basic-tidbit-selected-tab"
                          , currentRoute == Route.HomeComponentCreateBasicName
                          )
                        ]
                    , onClick <| GoTo Route.HomeComponentCreateBasicName
                    ]
                    [ text "Name" ]
                , div
                    [ classList
                        [ ( "create-basic-tidbit-tab", True )
                        , ( "create-basic-tidbit-selected-tab"
                          , currentRoute == Route.HomeComponentCreateBasicDescription
                          )
                        ]
                    , onClick <| GoTo Route.HomeComponentCreateBasicDescription
                    ]
                    [ text "Description" ]
                , div
                    [ classList
                        [ ( "create-basic-tidbit-tab", True )
                        , ( "create-basic-tidbit-selected-tab"
                          , currentRoute == Route.HomeComponentCreateBasicLanguage
                          )
                        ]
                    , onClick <| GoTo Route.HomeComponentCreateBasicLanguage
                    ]
                    [ text "Language" ]
                , div
                    [ classList
                        [ ( "create-basic-tidbit-tab", True )
                        , ( "create-basic-tidbit-selected-tab"
                          , currentRoute == Route.HomeComponentCreateBasicTags
                          )
                        ]
                    , onClick <| GoTo Route.HomeComponentCreateBasicTags
                    ]
                    [ text "Tags" ]
                , div
                    [ classList
                        [ ( "create-basic-tidbit-tab", True )
                        , ( "create-basic-tidbit-selected-tab"
                          , currentRoute == Route.HomeComponentCreateBasicTidbit
                          )
                        ]
                    , onClick <| GoTo Route.HomeComponentCreateBasicTidbit
                    ]
                    [ text "Tidbit" ]
                ]

        nameView : Html Msg
        nameView =
            div
                []
                [ input
                    [ placeholder "name"
                    , onInput BasicTidbitUpdateName
                    , value model.creatingBasicTidbitData.name
                    ]
                    []
                ]

        descriptionView : Html Msg
        descriptionView =
            div
                []
                [ textarea
                    [ placeholder "description"
                    , onInput BasicTidbitUpdateDescription
                    , value model.creatingBasicTidbitData.description
                    , class "create-basic-tidbit-description-box"
                    ]
                    []
                ]

        languageView : Html Msg
        languageView =
            div
                []
                [ input
                    [ placeholder "language"
                    , onInput BasicTidbitUpdateLanguageQuery
                    , value model.creatingBasicTidbitData.languageQuery
                    , disabled <|
                        Util.isNotNothing
                            model.creatingBasicTidbitData.language
                    ]
                    []
                , viewMenu
                , button
                    [ onClick <| BasicTidbitSelectLanguage Nothing
                    , classList
                        [ ( "hidden"
                          , Util.isNothing
                                model.creatingBasicTidbitData.language
                          )
                        ]
                    ]
                    [ text "change language" ]
                ]

        tagsView : Html Msg
        tagsView =
            let
                currentTags =
                    div
                        []
                        (List.map
                            (\tagName ->
                                div
                                    []
                                    [ text tagName
                                    , button
                                        [ onClick <| BasicTidbitRemoveTag tagName ]
                                        [ text "X" ]
                                    ]
                            )
                            model.creatingBasicTidbitData.tags
                        )
            in
                div
                    []
                    [ input
                        [ placeholder "tags"
                        , onInput BasicTidbitUpdateTagInput
                        , value model.creatingBasicTidbitData.tagInput
                        , Util.onEnter <|
                            BasicTidbitAddTag
                                model.creatingBasicTidbitData.tagInput
                        ]
                        []
                    , currentTags
                    ]

        tidbitView : Html Msg
        tidbitView =
            let
                body =
                    case model.creatingBasicTidbitData.currentCommentTab of
                        BasicTidbit.Introduction ->
                            div
                                []
                                [ textarea
                                    [ placeholder "Introduction"
                                    , onInput <| BasicTidbitUpdateIntroduction
                                    , value model.creatingBasicTidbitData.introduction
                                    ]
                                    []
                                ]

                        BasicTidbit.Frame frameIndex ->
                            div
                                []
                                [ textarea
                                    [ placeholder <|
                                        "Frame "
                                            ++ (toString <| frameIndex + 1)
                                    , onInput <|
                                        BasicTidbitUpdateFrameComment frameIndex
                                    , value <|
                                        case
                                            (Array.get
                                                frameIndex
                                                model.creatingBasicTidbitData.highlightedComments
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

                        BasicTidbit.Conclusion ->
                            div
                                []
                                [ textarea
                                    [ placeholder "Conclusion"
                                    , onInput <| BasicTidbitUpdateConclusion
                                    , value model.creatingBasicTidbitData.conclusion
                                    ]
                                    []
                                ]

                tabBar =
                    let
                        dynamicFrameButtons =
                            (Array.toList <|
                                Array.indexedMap
                                    (\index maybeHighlightedComment ->
                                        button
                                            [ onClick <|
                                                BasicTidbitGoToCommentTab <|
                                                    BasicTidbit.Frame index
                                            ]
                                            [ text <| toString <| index + 1 ]
                                    )
                                    model.creatingBasicTidbitData.highlightedComments
                            )
                    in
                        div
                            []
                            (List.concat
                                [ [ button
                                        [ onClick <| BasicTidbitRemoveFrame
                                        , disabled <|
                                            Array.length
                                                model.creatingBasicTidbitData.highlightedComments
                                                <= 1
                                        ]
                                        [ text "-" ]
                                  , button
                                        [ onClick <|
                                            BasicTidbitGoToCommentTab
                                                BasicTidbit.Introduction
                                        ]
                                        [ text "Introduction" ]
                                  ]
                                , dynamicFrameButtons
                                , [ button
                                        [ onClick <|
                                            BasicTidbitGoToCommentTab
                                                BasicTidbit.Conclusion
                                        ]
                                        [ text "Conclusion" ]
                                  , button
                                        [ onClick <| BasicTidbitAddFrame ]
                                        [ text "+" ]
                                  ]
                                ]
                            )
            in
                div
                    []
                    [ div
                        [ class "code-editor-wrapper" ]
                        [ div
                            [ classList [ ( "code-editor", True ) ]
                            , id "basic-tidbit-code-editor"
                            ]
                            []
                        ]
                    , div
                        [ class "comment-creator" ]
                        [ body
                        , tabBar
                        ]
                    ]

        viewForTab : Html Msg
        viewForTab =
            case currentRoute of
                Route.HomeComponentCreateBasicName ->
                    nameView

                Route.HomeComponentCreateBasicDescription ->
                    descriptionView

                Route.HomeComponentCreateBasicLanguage ->
                    languageView

                Route.HomeComponentCreateBasicTags ->
                    tagsView

                Route.HomeComponentCreateBasicTidbit ->
                    tidbitView

                -- Default to name view.
                _ ->
                    nameView
    in
        div
            []
            [ div
                []
                [ h1 [] [ text "Creating Basic Tidbit" ]
                , button
                    [ class "create-basic-tidbit-back-button"
                    , onClick <| GoTo Route.HomeComponentCreate
                    ]
                    [ text "Back" ]
                , button
                    [ class "create-basic-tidbit-reset-button"
                    , onClick <| ResetCreateBasicTidbit
                    ]
                    [ text "Reset" ]
                ]
            , div
                []
                [ createBasicTidbitNavbar
                , viewForTab
                ]
            ]
