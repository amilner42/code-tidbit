module Components.Home.View exposing (..)

import Autocomplete as AC
import Components.Home.Messages exposing (Msg(..))
import Components.Home.Model exposing (Model)
import Components.Home.Update exposing (filterLanguagesByQuery)
import Components.Model exposing (Shared)
import DefaultServices.Util as Util
import Elements.Editor as Editor
import Html exposing (Html, div, text, button, input, h1, h3)
import Html.Attributes exposing (class, classList, placeholder, value, hidden)
import Html.Events exposing (onClick, onInput)
import Models.Route as Route
import Models.TidbitType as TidbitType


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
    in
        div
            []
            [ h1
                []
                [ text "Creating Basic Tidbit" ]
            , div
                [ classList
                    [ ( "hidden", Util.isNotNothing model.creatingBasicTidbitData.language ) ]
                ]
                [ input
                    [ placeholder "language"
                    , onInput BasicTidbitUpdateLanguageQuery
                    , value model.creatingBasicTidbitData.languageQuery
                    ]
                    []
                , viewMenu
                ]
            ]
