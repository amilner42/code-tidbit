module DefaultModel exposing (defaultModel, defaultShared)

import Components.Home.Init as HomeInit
import Components.Model as Model
import Components.Welcome.Init as WelcomeInit
import Models.Route as Route


{-| The default model (`Components/Model.elm`) for the application.
-}
defaultModel : Model.Model
defaultModel =
    { shared = defaultShared
    , homeComponent = HomeInit.init
    , welcomeComponent = WelcomeInit.init
    }


{-| The defult shared model.
-}
defaultShared : Model.Shared
defaultShared =
    { user = Nothing
    , route = Route.WelcomeComponentLogin
    }
