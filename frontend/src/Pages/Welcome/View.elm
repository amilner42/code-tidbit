module Pages.Welcome.View exposing (view)

import DefaultServices.Util as Util
import Html exposing (Html, a, button, div, h1, img, input, text)
import Html.Attributes exposing (class, classList, disabled, hidden, placeholder, src, type_, value)
import Html.Events exposing (onClick, onInput)
import Models.ApiError as ApiError
import Models.RequestTracker as RT
import Models.Route as Route
import Pages.Model exposing (Shared)
import Pages.Welcome.Messages exposing (..)
import Pages.Welcome.Model exposing (..)


{-| `Welcome` view.
-}
view : Model -> Shared -> Html Msg
view model shared =
    div
        [ class "welcome-page-wrapper" ]
        [ img
            [ class "logo"
            , src "assets/ct-logo.png"
            ]
            []
        , div
            [ class "logo-title-1" ]
            [ text "CODE" ]
        , div
            [ class "logo-title-2" ]
            [ text "TIDBIT" ]
        , case shared.route of
            Route.RegisterPage ->
                button
                    [ class "welcome-page-change-tab-button"
                    , onClick <| GoTo Route.LoginPage
                    ]
                    [ text "Login"
                    ]

            Route.LoginPage ->
                button
                    [ class "welcome-page-change-tab-button"
                    , onClick <| GoTo Route.RegisterPage
                    ]
                    [ text "Register"
                    ]

            _ ->
                Util.hiddenDiv
        , button
            [ class "welcome-page-change-tab-button welcome-page-browse-button"
            , onClick <| GoTo Route.BrowsePage
            ]
            [ text "Browse Tutorials" ]
        , div
            [ classList
                [ ( "welcome-page", True )
                , ( "small-box-error", (shared.route == Route.LoginPage) && Util.isNotNothing model.apiError )
                , ( "small-box", (shared.route == Route.LoginPage) && Util.isNothing model.apiError )
                , ( "big-box-error", (shared.route == Route.RegisterPage) && Util.isNotNothing model.apiError )
                ]
            ]
            [ displayViewForRoute model shared
            ]
        ]


{-| Creates an error box with an appropriate message if there is an error, otherwise simply stays hidden.
-}
errorBox : Maybe ApiError.ApiError -> Html Msg
errorBox maybeApiError =
    let
        humanReadable maybeApiError =
            case maybeApiError of
                -- Hidden when no error so this doesn't matter
                Nothing ->
                    ""

                Just apiError ->
                    ApiError.humanReadable apiError
    in
    div
        [ class "welcome-error-box"
        , hidden <| Util.isNothing <| maybeApiError
        ]
        [ text <| humanReadable <| maybeApiError ]


{-| The welcome login view
-}
loginView : Model -> Shared -> Html Msg
loginView model shared =
    let
        currentError =
            model.apiError

        highlightEmail =
            currentError == Just ApiError.NoAccountExistsForEmail

        hightlightPassword =
            currentError == Just ApiError.IncorrectPasswordForEmail

        incompleteForm =
            List.member
                ""
                [ model.email
                , model.password
                ]

        invalidForm =
            incompleteForm || Util.isNotNothing currentError
    in
    div
        []
        [ div
            [ class "welcome-box" ]
            [ div
                [ class "welcome-box-text" ]
                [ text "It's Good to Have You Back" ]
            , div
                [ class "welcome-box-sub-text" ]
                [ text "Now Go Learn Something Already" ]
            , input
                [ classList [ ( "input-error-highlight", highlightEmail ) ]
                , placeholder "Email"
                , onInput OnEmailInput
                , value model.email
                ]
                []
            , div
                [ class "gap-15" ]
                []
            , input
                [ classList [ ( "input-error-highlight", hightlightPassword ) ]
                , placeholder "Password"
                , type_ "password"
                , onInput OnPasswordInput
                , value model.password
                ]
                []
            , errorBox currentError
            , button
                [ classList
                    [ ( "cursor-progress", RT.isMakingRequest shared.apiRequestTracker RT.LoginOrRegister ) ]
                , onClick Login
                , disabled invalidForm
                ]
                [ text "Login" ]
            ]
        ]


{-| The welcome register view
-}
registerView : Model -> Shared -> Html Msg
registerView model shared =
    let
        currentError =
            model.apiError

        highlightEmail =
            List.member
                currentError
                [ Just ApiError.InvalidEmail
                , Just ApiError.EmailAddressAlreadyRegistered
                ]

        hightlightPassword =
            List.member
                currentError
                [ Just ApiError.InvalidPassword
                , Just ApiError.PasswordDoesNotMatchConfirmPassword
                ]

        incompleteForm =
            List.member
                ""
                [ model.email
                , model.password
                , model.confirmPassword
                , model.name
                ]

        invalidForm =
            incompleteForm || Util.isNotNothing currentError
    in
    div
        [ class "welcome-box" ]
        [ div
            [ class "welcome-box-text" ]
            [ text "Your Friendly Code Learning Platform" ]
        , div
            [ class "welcome-box-sub-text" ]
            [ text "Browse and Create Powerful Tutorials" ]
        , input
            [ classList [ ( "input-error-highlight", False ) ]
            , placeholder "Preferred Name"
            , onInput OnNameInput
            , value model.name
            ]
            []
        , div
            [ class "gap-15" ]
            []
        , input
            [ classList [ ( "input-error-highlight", highlightEmail ) ]
            , placeholder "Email"
            , onInput OnEmailInput
            , value model.email
            ]
            []
        , input
            [ classList [ ( "input-error-highlight", hightlightPassword ) ]
            , placeholder "Password"
            , type_ "password"
            , onInput OnPasswordInput
            , value model.password
            ]
            []
        , div
            [ class "gap-15" ]
            []
        , input
            [ classList [ ( "input-error-highlight", hightlightPassword ) ]
            , placeholder "Confirm Password"
            , type_ "password"
            , onInput OnConfirmPasswordInput
            , value model.confirmPassword
            ]
            []
        , errorBox currentError
        , button
            [ classList
                [ ( "cursor-progress", RT.isMakingRequest shared.apiRequestTracker RT.LoginOrRegister ) ]
            , onClick Register
            , disabled invalidForm
            ]
            [ text "Start learning" ]
        ]


{-| Displays the welcome sub-view based on the sub-route (login or register)
-}
displayViewForRoute : Model -> Shared -> Html Msg
displayViewForRoute model shared =
    case shared.route of
        Route.LoginPage ->
            loginView model shared

        Route.RegisterPage ->
            registerView model shared

        _ ->
            Util.hiddenDiv
