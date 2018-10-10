module Pages.Welcome.Update exposing (update)

import Api exposing (api)
import DefaultServices.CommonSubPageUtil exposing (CommonSubPageUtil(..))
import Models.ApiError as ApiError
import Models.RequestTracker as RT
import Models.Route as Route
import Navigation
import Pages.Messages as BaseMessage
import Pages.Model exposing (Shared)
import Pages.Welcome.Init exposing (..)
import Pages.Welcome.Messages exposing (..)
import Pages.Welcome.Model exposing (..)


{-| `Welcome` update.
-}
update : CommonSubPageUtil Model Shared Msg BaseMessage.Msg -> Msg -> Model -> Shared -> ( Model, Shared, Cmd BaseMessage.Msg )
update (Common common) msg model shared =
    case msg of
        -- On top of going to a route, wipes the errors on the welcome page. This is not the error in
        -- `shared.apiModalError`
        GoToAndClearWelcomeError route ->
            ( wipeError model, shared, Route.navigateTo route )

        OnRouteHit route ->
            common.justSetShared { shared | userNeedsAuthModal = Nothing }

        OnPasswordInput newPassword ->
            common.justSetModel <| wipeError { model | password = newPassword }

        OnConfirmPasswordInput newConfirmPassword ->
            common.justSetModel <| wipeError { model | confirmPassword = newConfirmPassword }

        OnEmailInput newEmail ->
            common.justSetModel <| wipeError { model | email = newEmail }

        OnNameInput newName ->
            common.justSetModel <| wipeError { model | name = newName }

        Register ->
            let
                registerAction =
                    common.justProduceCmd <|
                        api.post.register
                            { name = model.name
                            , email = model.email
                            , password = model.password
                            }
                            (common.subMsg << OnRegisterFailure)
                            (common.subMsg << OnRegisterSuccess)
            in
            if model.password == model.confirmPassword then
                common.makeSingletonRequest RT.LoginOrRegister registerAction
            else
                common.justSetModel
                    { model | apiError = Just ApiError.PasswordDoesNotMatchConfirmPassword }

        OnRegisterFailure newApiError ->
            common.justSetModel { model | apiError = Just newApiError }
                |> common.andFinishRequest RT.LoginOrRegister

        OnRegisterSuccess newUser ->
            let
                redirectCmd =
                    case Route.fromQPOnWelcomePage shared.route of
                        Just link ->
                            Navigation.newUrl link

                        Nothing ->
                            Route.navigateTo Route.BrowsePage
            in
            ( init, { shared | user = Just newUser }, redirectCmd )
                |> common.andFinishRequest RT.LoginOrRegister

        Login ->
            let
                loginAction =
                    common.justProduceCmd <|
                        api.post.login
                            { email = model.email, password = model.password }
                            (common.subMsg << OnLoginFailure)
                            (common.subMsg << OnLoginSuccess)
            in
            common.makeSingletonRequest RT.LoginOrRegister loginAction

        OnLoginSuccess newUser ->
            let
                redirectCmd =
                    case Route.fromQPOnWelcomePage shared.route of
                        Just link ->
                            Navigation.newUrl link

                        Nothing ->
                            Route.navigateTo Route.BrowsePage
            in
            ( init, { shared | user = Just newUser }, redirectCmd )
                |> common.andFinishRequest RT.LoginOrRegister

        OnLoginFailure newApiError ->
            common.justSetModel { model | apiError = Just newApiError }
                |> common.andFinishRequest RT.LoginOrRegister


{-| Sets the `apiError` on the `model` to `Nothing`.
-}
wipeError : Model -> Model
wipeError model =
    { model | apiError = Nothing }
