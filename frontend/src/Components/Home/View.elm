module Components.Home.View exposing (..)

import Autocomplete as AC
import Components.Home.Messages exposing (Msg(..))
import Components.Home.Model exposing (Model)
import Components.Home.Update exposing (filterLanguagesByQuery)
import Components.Model exposing (Shared)
import DefaultServices.Util as Util
import Elements.Editor as Editor
import Html exposing (Html, div, text, textarea, button, input, h1, h3)
import Html.Attributes exposing (class, classList, placeholder, value, hidden)
import Html.Events exposing (onClick, onInput)
import Models.Route as Route
import Models.TidbitType as TidbitType
import Models.BasicTidbit as BasicTidbit


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
            shared.route == Route.HomeComponentCreate
    in
        div [ class "nav" ]
            [ div
                [ classList
                    [ ( "nav-btn left", True )
                    , ( "selected", browseViewSelected )
                    ]
                , onClick GoToBrowseView
                ]
                [ text "Browse" ]
            , div
                [ classList
                    [ ( "nav-btn left", True )
                    , ( "selected", createViewSelected )
                    ]
                , onClick GoToCreateView
                ]
                [ text "Create" ]
            , div
                [ classList
                    [ ( "nav-btn right", True )
                    , ( "selected", profileViewSelected )
                    ]
                , onClick GoToProfileView
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
        createSubView =
            case model.creatingTidbitType of
                Nothing ->
                    div
                        []
                        [ h1
                            []
                            [ text "Select Tidbit Type" ]
                        , button
                            [ onClick <|
                                SelectTidbitTypeForCreate
                                    (Just TidbitType.Basic)
                            ]
                            [ text "Basic Tidbit" ]
                        ]

                Just tidbitType ->
                    case tidbitType of
                        TidbitType.Basic ->
                            createBasicTidbitView model shared
    in
        div
            []
            [ createSubView
            ]


{-| View for creating a basic tidbit.
-}
createBasicTidbitView : Model -> Shared -> Html Msg
createBasicTidbitView model shared =
    let
        currentStage : BasicTidbit.BasicTidbitCreateStage
        currentStage =
            model.creatingBasicTidbitData.createStage

        viewMenu : Html Msg
        viewMenu =
            div
                []
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
                          , currentStage == BasicTidbit.Name
                          )
                        ]
                    , onClick <| BasicTidbitSelectTab BasicTidbit.Name
                    ]
                    [ text "Name" ]
                , div
                    [ classList
                        [ ( "create-basic-tidbit-tab", True )
                        , ( "create-basic-tidbit-selected-tab"
                          , currentStage == BasicTidbit.Description
                          )
                        ]
                    , onClick <| BasicTidbitSelectTab BasicTidbit.Description
                    ]
                    [ text "Description" ]
                , div
                    [ classList
                        [ ( "create-basic-tidbit-tab", True )
                        , ( "create-basic-tidbit-selected-tab"
                          , currentStage == BasicTidbit.Language
                          )
                        ]
                    , onClick <| BasicTidbitSelectTab BasicTidbit.Language
                    ]
                    [ text "Language" ]
                , div
                    [ classList
                        [ ( "create-basic-tidbit-tab", True )
                        , ( "create-basic-tidbit-selected-tab"
                          , currentStage == BasicTidbit.Tags
                          )
                        ]
                    , onClick <| BasicTidbitSelectTab BasicTidbit.Tags
                    ]
                    [ text "Tags" ]
                , div
                    [ classList
                        [ ( "create-basic-tidbit-tab", True )
                        , ( "create-basic-tidbit-selected-tab"
                          , currentStage == BasicTidbit.Tidbit
                          )
                        ]
                    , onClick <| BasicTidbitSelectTab BasicTidbit.Tidbit
                    ]
                    [ text "Tidbit" ]
                ]

        nameView : Html Msg
        nameView =
            div
                [ classList [ ( "hidden", currentStage /= BasicTidbit.Name ) ] ]
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
                [ classList [ ( "hidden", currentStage /= BasicTidbit.Description ) ] ]
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
                [ classList [ ( "hidden", currentStage /= BasicTidbit.Language ) ] ]
                [ input
                    [ placeholder "language"
                    , onInput BasicTidbitUpdateLanguageQuery
                    , value model.creatingBasicTidbitData.languageQuery
                    ]
                    []
                , viewMenu
                ]

        tagView : Html Msg
        tagView =
            div
                [ classList [ ( "hidden", currentStage /= BasicTidbit.Tags ) ] ]
                []

        tidbitView : Html Msg
        tidbitView =
            div
                [ classList [ ( "hidden", currentStage /= BasicTidbit.Tidbit ) ] ]
                []
    in
        div
            []
            [ div
                []
                [ h1 [] [ text "Creating Basic Tidbit" ]
                , button
                    [ class "create-basic-tidbit-back-button"
                    , onClick <| SelectTidbitTypeForCreate Nothing
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
                , nameView
                , descriptionView
                , languageView
                , tagView
                , tidbitView
                ]
            ]
