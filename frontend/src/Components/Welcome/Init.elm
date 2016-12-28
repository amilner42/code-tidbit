module Components.Welcome.Init exposing (init)

import Components.Welcome.Model exposing (Model)


{-| Welcome Component Init.
-}
init : Model
init =
    { email = ""
    , password = ""
    , confirmPassword = ""
    , apiError = Nothing
    }
