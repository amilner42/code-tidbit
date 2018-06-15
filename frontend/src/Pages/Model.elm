module Pages.Model exposing (..)

import DefaultServices.TextFields as TextFields
import Elements.Simple.Editor as Editor
import Flags exposing (Flags)
import Keyboard.Extra as KK
import Models.ApiError as ApiError
import Models.RequestTracker as RT
import Models.Route as Route
import Models.Story as Story
import Models.Tidbit as Tidbit
import Models.User as User
import Pages.Browse.Model as BrowseModel
import Pages.Create.Model as CreateModel
import Pages.CreateBigbit.Model as CreateBigbitModel
import Pages.CreateSnipbit.Model as CreateSnipbitModel
import Pages.DevelopStory.Model as DevelopStoryModel
import Pages.NewStory.Model as NewStoryModel
import Pages.Notifications.Model as NotificationsModel
import Pages.Profile.Model as ProfileModel
import Pages.ViewBigbit.Model as ViewBigbitModel
import Pages.ViewSnipbit.Model as ViewSnipbitModel
import Pages.ViewStory.Model as ViewStoryModel
import Pages.Welcome.Model as WelcomeModel


{-| `Base` model.

The base page will have nested inside it the state of every individual page as well as `shared`, which will be passed to
all pages so they can share data.

-}
type alias Model =
    { shared : Shared
    , welcomePage : WelcomeModel.Model
    , viewSnipbitPage : ViewSnipbitModel.Model
    , viewBigbitPage : ViewBigbitModel.Model
    , profilePage : ProfileModel.Model
    , newStoryPage : NewStoryModel.Model
    , createPage : CreateModel.Model
    , developStoryPage : DevelopStoryModel.Model
    , createSnipbitPage : CreateSnipbitModel.Model
    , createBigbitPage : CreateBigbitModel.Model
    , browsePage : BrowseModel.Model
    , viewStoryPage : ViewStoryModel.Model
    , notificationsPage : NotificationsModel.Model
    }


{-| `Shared` model.

All data shared between pages.

-}
type alias Shared =
    { user : Maybe User.User
    , route : Route.Route
    , languages : List ( Editor.Language, String )
    , keysDown : KK.Model
    , userStories : Maybe (List Story.Story)
    , userTidbits : Maybe (List Tidbit.Tidbit)
    , viewingStory : Maybe Story.ExpandedStory
    , flags : Flags
    , apiModalError : Maybe ApiError.ApiError
    , userNeedsAuthModal : Maybe String
    , apiRequestTracker : RT.RequestTracker
    , textFieldKeyTracker : TextFields.KeyTracker
    , logoutError : Maybe ApiError.ApiError
    }


{-| Update the `shared` field of `Model` given a `Shared` updater.
-}
updateShared : Model -> (Shared -> Shared) -> Model
updateShared model sharedUpdater =
    { model | shared = sharedUpdater model.shared }


{-| Updates `keysDown`.
-}
updateKeysDown : KK.Model -> Model -> Model
updateKeysDown newKeysDown model =
    updateShared model (\shared -> { shared | keysDown = newKeysDown })
