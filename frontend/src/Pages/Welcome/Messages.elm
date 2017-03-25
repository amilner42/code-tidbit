module Pages.Welcome.Messages exposing (Msg(..))

import Models.ApiError as ApiError
import Models.User exposing (User)


{-| `Welcome` msg.
-}
type Msg
    = Register
    | OnRegisterSuccess User
    | OnRegisterFailure ApiError.ApiError
    | Login
    | OnLoginSuccess User
    | OnLoginFailure ApiError.ApiError
    | GoToRegisterView
    | GoToLoginView
    | OnPasswordInput String
    | OnConfirmPasswordInput String
    | OnEmailInput String
    | OnNameInput String
