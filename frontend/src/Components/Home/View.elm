module Components.Home.View exposing (..)

import Components.Home.Messages exposing (Msg(..))
import Components.Home.Model exposing (Model)
import Components.Model exposing (Shared)
import DefaultServices.Util as Util
import Html exposing (Html, div, text, button, input, h1, h3)
import Html.Attributes exposing (class, classList, placeholder, value, hidden)
import Html.Events exposing (onClick, onInput)
import Models.Route as Route


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
        Route.HomeComponentMain ->
            mainView model

        Route.HomeComponentProfile ->
            profileView model

        -- This should never happen.
        _ ->
            mainView model


{-| Horizontal navbar to go above the views.
-}
navbar : Shared -> Html Msg
navbar shared =
    let
        profileViewSelected =
            shared.route == Route.HomeComponentProfile

        mainViewSelected =
            shared.route == Route.HomeComponentMain
    in
        div [ class "nav" ]
            [ div
                [ classList
                    [ ( "nav-btn left", True )
                    , ( "selected", mainViewSelected )
                    ]
                , onClick GoToMainView
                ]
                [ text "Home" ]
            , div
                [ classList
                    [ ( "nav-btn right", True )
                    , ( "selected", profileViewSelected )
                    ]
                , onClick GoToProfileView
                ]
                [ text "Profile" ]
            ]


{-| The Profile view.
-}
profileView : Model -> Html Msg
profileView model =
    div []
        [ h1
            []
            [ text "Profile View" ]
        , button
            [ onClick LogOut ]
            [ text "Log out" ]
        , div
            [ hidden <| Util.isNothing model.logOutError ]
            [ text "Cannot log out right now, try again shortly." ]
        ]


{-| The Main view.
-}
mainView : Model -> Html Msg
mainView model =
    div []
        []
