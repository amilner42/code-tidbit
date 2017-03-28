module Pages.Welcome.Init exposing (..)

import Pages.Welcome.Model exposing (..)


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
