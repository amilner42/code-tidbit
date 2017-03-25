module Pages.Welcome.Init exposing (init)

import Pages.Welcome.Model exposing (Model)


{-| `Welcome` init.
-}
init : Model
init =
    { name = ""
    , email = ""
    , password = ""
    , confirmPassword = ""
    , apiError = Nothing
    }
