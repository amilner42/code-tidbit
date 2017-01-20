module Components.Welcome.Init exposing (init)

import Components.Welcome.Model exposing (Model)


{-| Welcome Component Init.
-}
init : Model
init =
    { name = ""
    , email = ""
    , password = ""
    , confirmPassword = ""
    , apiError = Nothing
    }
