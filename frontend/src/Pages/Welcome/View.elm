module Pages.Welcome.View exposing (view)

import DefaultServices.Util as Util
import Html exposing (Html, a, button, div, h1, img, input, text)
import Html.Attributes exposing (class, classList, disabled, hidden, placeholder, src, type_, value)
import Html.Events exposing (onClick, onInput)
import Models.ApiError as ApiError
import Models.RequestTracker as RT
import Models.Route as Route
import Pages.Messages as BaseMessage
import Pages.Model exposing (Shared)
import Pages.Welcome.Messages exposing (..)
import Pages.Welcome.Model exposing (..)


{-| `Welcome` view.
-}
view : (Msg -> BaseMessage.Msg) -> Model -> Shared -> Html BaseMessage.Msg
view subMsg model shared =
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
            Route.RegisterPage from ->
                Route.navigationNode
                    (Route.LoginPage from
                        |> (\route -> Just ( Route.Route route, subMsg <| GoToAndClearWelcomeError route ))
                    )
                    []
                    [ button
                        [ class "welcome-page-change-tab-button" ]
                        [ text "Login" ]
                    ]

            Route.LoginPage from ->
                Route.navigationNode
                    (Route.RegisterPage from
                        |> (\route -> Just ( Route.Route route, subMsg <| GoToAndClearWelcomeError route ))
                    )
                    []
                    [ button
                        [ class "welcome-page-change-tab-button" ]
                        [ text "Register" ]
                    ]

            _ ->
                Util.hiddenDiv
        , Route.navigationNode
            (Just ( Route.Route Route.BrowsePage, subMsg <| GoToAndClearWelcomeError Route.BrowsePage ))
            []
            [ button
                [ class "welcome-page-change-tab-button welcome-page-browse-button" ]
                [ text "Browse Tutorials" ]
            ]
        , div
            [ classList
                [ ( "welcome-page", True )
                , ( "small-box-error"
                  , case ( model.apiError, shared.route ) of
                        ( Just _, Route.LoginPage _ ) ->
                            True

                        _ ->
                            False
                  )
                , ( "small-box"
                  , case ( model.apiError, shared.route ) of
                        ( Nothing, Route.LoginPage _ ) ->
                            True

                        _ ->
                            False
                  )
                , ( "big-box-error"
                  , case ( model.apiError, shared.route ) of
                        ( Just _, Route.RegisterPage _ ) ->
                            True

                        _ ->
                            False
                  )
                ]
            ]
            [ displayViewForRoute subMsg model shared
            ]
        ]


{-| Creates an error box with an appropriate message if there is an error, otherwise simply stays hidden.
-}
errorBox : Maybe ApiError.ApiError -> Html BaseMessage.Msg
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
loginView : (Msg -> BaseMessage.Msg) -> Model -> Shared -> Html BaseMessage.Msg
loginView subMsg model shared =
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
                , onInput <| subMsg << OnEmailInput
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
                , onInput <| subMsg << OnPasswordInput
                , value model.password
                ]
                []
            , errorBox currentError
            , button
                [ classList
                    [ ( "cursor-progress", RT.isMakingRequest shared.apiRequestTracker RT.LoginOrRegister ) ]
                , onClick <| subMsg Login
                , disabled invalidForm
                ]
                [ text "Login" ]
            ]
        ]


{-| The welcome register view
-}
registerView : (Msg -> BaseMessage.Msg) -> Model -> Shared -> Html BaseMessage.Msg
registerView subMsg model shared =
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
            , onInput <| subMsg << OnNameInput
            , value model.name
            ]
            []
        , div
            [ class "gap-15" ]
            []
        , input
            [ classList [ ( "input-error-highlight", highlightEmail ) ]
            , placeholder "Email"
            , onInput <| subMsg << OnEmailInput
            , value model.email
            ]
            []
        , input
            [ classList [ ( "input-error-highlight", hightlightPassword ) ]
            , placeholder "Password"
            , type_ "password"
            , onInput <| subMsg << OnPasswordInput
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
            , onInput <| subMsg << OnConfirmPasswordInput
            , value model.confirmPassword
            ]
            []
        , errorBox currentError
        , button
            [ classList
                [ ( "cursor-progress", RT.isMakingRequest shared.apiRequestTracker RT.LoginOrRegister ) ]
            , onClick <| subMsg Register
            , disabled invalidForm
            ]
            [ text "Start learning" ]
        ]


{-| Displays the welcome sub-view based on the sub-route (login or register)
-}
displayViewForRoute : (Msg -> BaseMessage.Msg) -> Model -> Shared -> Html BaseMessage.Msg
displayViewForRoute subMsg model shared =
    case shared.route of
        Route.LoginPage _ ->
            loginView subMsg model shared

        Route.RegisterPage _ ->
            registerView subMsg model shared

        _ ->
            Util.hiddenDiv
