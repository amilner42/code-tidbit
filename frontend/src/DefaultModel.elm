module DefaultModel exposing (defaultModel, defaultShared)

import Pages.Model as Model
import Pages.Welcome.Init as WelcomeInit
import Pages.ViewSnipbit.Init as ViewSnipbitInit
import Pages.ViewBigbit.Init as ViewBigbitInit
import Pages.Profile.Init as ProfileInit
import Pages.NewStory.Init as NewStoryInit
import Pages.Create.Init as CreateInit
import Pages.DevelopStory.Init as DevelopStoryInit
import Pages.CreateSnipbit.Init as CreateSnipbitInit
import Pages.CreateBigbit.Init as CreateBigbitInit
import Elements.Editor as Editor
import Models.Route as Route
import Keyboard.Extra as KK


{-| The default model (`Pages/Model.elm`) for the application.
-}
defaultModel : Model.Model
defaultModel =
    { shared = defaultShared
    , welcomePage = WelcomeInit.init
    , viewSnipbitPage = ViewSnipbitInit.init
    , viewBigbitPage = ViewBigbitInit.init
    , profilePage = ProfileInit.init
    , newStoryPage = NewStoryInit.init
    , createPage = CreateInit.init
    , developStoryPage = DevelopStoryInit.init
    , createSnipbitPage = CreateSnipbitInit.init
    , createBigbitPage = CreateBigbitInit.init
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
