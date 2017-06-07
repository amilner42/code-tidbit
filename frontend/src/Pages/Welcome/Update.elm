module Pages.Welcome.Update exposing (update)

import DefaultServices.CommonSubPageUtil exposing (CommonSubPageUtil(..))
import Models.ApiError as ApiError
import Models.RequestTracker as RT
import Models.Route as Route
import Pages.Model exposing (Shared)
import Pages.Welcome.Init exposing (..)
import Pages.Welcome.Messages exposing (..)
import Pages.Welcome.Model exposing (..)


{-| `Welcome` update.
-}
update : CommonSubPageUtil Model Shared Msg -> Msg -> Model -> Shared -> ( Model, Shared, Cmd Msg )
update (Common common) msg model shared =
    case msg of
        -- On top of going to a route, wipes the errors on the welcome page.
        GoTo route ->
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
                        common.api.post.register
                            { name = model.name
                            , email = model.email
                            , password = model.password
                            }
                            OnRegisterFailure
                            OnRegisterSuccess
            in
                if model.password == model.confirmPassword then
                    common.doIfRequestNotAlreadyLoading RT.LoginOrRegister registerAction
                else
                    common.justSetModel
                        { model | apiError = Just ApiError.PasswordDoesNotMatchConfirmPassword }

        OnRegisterFailure newApiError ->
            common.justSetModel { model | apiError = Just newApiError }
                |> common.andFinishRequest RT.LoginOrRegister

        OnRegisterSuccess newUser ->
            ( init, { shared | user = Just newUser }, Route.navigateTo Route.BrowsePage )
                |> common.andFinishRequest RT.LoginOrRegister

        Login ->
            let
                loginAction =
                    common.justProduceCmd <|
                        common.api.post.login
                            { email = model.email, password = model.password }
                            OnLoginFailure
                            OnLoginSuccess
            in
                common.doIfRequestNotAlreadyLoading RT.LoginOrRegister loginAction

        OnLoginSuccess newUser ->
            ( init, { shared | user = Just newUser }, Route.navigateTo Route.BrowsePage )
                |> common.andFinishRequest RT.LoginOrRegister

        OnLoginFailure newApiError ->
            common.justSetModel { model | apiError = Just newApiError }
                |> common.andFinishRequest RT.LoginOrRegister


{-| Sets the `apiError` on the `model` to `Nothing`.
-}
wipeError : Model -> Model
wipeError model =
    { model | apiError = Nothing }
