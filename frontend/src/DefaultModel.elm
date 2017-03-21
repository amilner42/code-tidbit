module DefaultModel exposing (defaultModel, defaultShared)

import Pages.Home.Init as HomeInit
import Pages.Model as Model
import Pages.Welcome.Init as WelcomeInit
import Elements.Editor as Editor
import Models.Route as Route
import Keyboard.Extra as KK


{-| The default model (`Pages/Model.elm`) for the application.
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
    , route = Route.LoginPage
    , languages = Editor.humanReadableListOfLanguages
    , keysDown = KK.init
    , userStories = Nothing
    , userTidbits = Nothing
    , viewingStory = Nothing
    }
