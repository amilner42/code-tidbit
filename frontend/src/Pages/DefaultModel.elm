module Pages.DefaultModel exposing (..)

import Elements.Simple.Editor as Editor
import Flags exposing (Flags)
import Keyboard.Extra as KK
import Models.Route as Route
import Pages.Browse.Init as BrowseInit
import Pages.Create.Init as CreateInit
import Pages.CreateBigbit.Init as CreateBigbitInit
import Pages.CreateSnipbit.Init as CreateSnipbitInit
import Pages.DevelopStory.Init as DevelopStoryInit
import Pages.Model as Model
import Pages.NewStory.Init as NewStoryInit
import Pages.Profile.Init as ProfileInit
import Pages.ViewBigbit.Init as ViewBigbitInit
import Pages.ViewSnipbit.Init as ViewSnipbitInit
import Pages.ViewStory.Init as ViewStoryInit
import Pages.Welcome.Init as WelcomeInit


{-| The default model (`Pages/Model.elm`) for the application.

NOTE: This default model is outside of `Pages/Init.elm` to avoid circular dependencies, sometimes sub-pages want access
      to `defaultShared`.
-}
defaultModel : Route.Route -> Flags -> Model.Model
defaultModel route flags =
    { shared = defaultShared route flags
    , welcomePage = WelcomeInit.init
    , viewSnipbitPage = ViewSnipbitInit.init
    , viewBigbitPage = ViewBigbitInit.init
    , profilePage = ProfileInit.init
    , newStoryPage = NewStoryInit.init
    , createPage = CreateInit.init
    , developStoryPage = DevelopStoryInit.init
    , createSnipbitPage = CreateSnipbitInit.init
    , createBigbitPage = CreateBigbitInit.init
    , browsePage = BrowseInit.init
    , viewStoryPage = ViewStoryInit.init
    }


{-| The defult shared model.
-}
defaultShared : Route.Route -> Flags -> Model.Shared
defaultShared route flags =
    { user = Nothing
    , route = route
    , languages = Editor.humanReadableListOfLanguages
    , keysDown = KK.init
    , userStories = Nothing
    , userTidbits = Nothing
    , viewingStory = Nothing
    , flags = flags
    , apiModalError = Nothing
    }
