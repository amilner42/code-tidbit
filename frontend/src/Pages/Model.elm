module Pages.Model exposing (..)

import Pages.Welcome.Model as WelcomeModel
import Pages.ViewBigbit.Model as ViewBigbitModel
import Pages.ViewSnipbit.Model as ViewSnipbitModel
import Pages.Profile.Model as ProfileModel
import Pages.NewStory.Model as NewStoryModel
import Pages.Create.Model as CreateModel
import Pages.DevelopStory.Model as DevelopStoryModel
import Pages.CreateSnipbit.Model as CreateSnipbitModel
import Pages.CreateBigbit.Model as CreateBigbitModel
import Elements.Editor as Editor
import Models.Route as Route
import Models.Story as Story
import Models.User as User
import Models.Tidbit as Tidbit
import Keyboard.Extra as KK


{-| `Base` model.

The base page will have nested inside it the state of every individual page as
well as `shared`, which will be passed to all pages so they can share data.
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
    }


{-| `Shared` model.

All data shared between pages.
-}
type alias Shared =
    { user : Maybe (User.User)
    , route : Route.Route
    , languages : List ( Editor.Language, String )
    , keysDown : KK.Model
    , userStories : Maybe (List Story.Story)
    , userTidbits : Maybe (List Tidbit.Tidbit)
    , viewingStory : Maybe Story.ExpandedStory
    }


{-| A wrapper around KK.update to handle extra logic.

Extra Logic: When someone clicks shift-tab, they could let go of the tab but
keep their hand on the shift and click the tab again to "double-shift-tab" to
allow this behaviour, every shift tab we reset it as if it was the first
shift-tab clicked.
-}
kkUpdateWrapper : KK.Msg -> KK.Model -> KK.Model
kkUpdateWrapper keyMsg keysDown =
    let
        newKeysDown =
            KK.update keyMsg keysDown
    in
        case newKeysDown of
            [ Just key1, Nothing, Just key2 ] ->
                if
                    ((KK.fromCode key1) == KK.Tab)
                        && ((KK.fromCode key2) == KK.Shift)
                then
                    [ Just key1, Just key2 ]
                else
                    newKeysDown

            _ ->
                newKeysDown


{-| Updates `keysDown`.
-}
updateKeysDown : KK.Model -> Model -> Model
updateKeysDown newKeysDown model =
    let
        shared =
            model.shared
    in
        { model
            | shared =
                { shared
                    | keysDown = newKeysDown
                }
        }


{-| Updates 'keysDown' with the given list of `Key`s.
-}
updateKeysDownWithKeys : List KK.Key -> Model -> Model
updateKeysDownWithKeys newKeys =
    updateKeysDown (List.map (Just << KK.toCode) newKeys)
