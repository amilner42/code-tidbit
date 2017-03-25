module Pages.Messages exposing (..)

import Pages.Model exposing (Model)
import Pages.Welcome.Messages as WelcomeMessages
import Pages.ViewSnipbit.Messages as ViewSnipbitMessages
import Pages.ViewBigbit.Messages as ViewBigbitMessages
import Pages.ViewStory.Messages as ViewStoryMessages
import Pages.Profile.Messages as ProfileMessages
import Pages.NewStory.Messages as NewStoryMessages
import Pages.Create.Messages as CreateMessages
import Pages.DevelopStory.Messages as DevelopStoryMessages
import Pages.CreateSnipbit.Messages as CreateSnipbitMessages
import Pages.CreateBigbit.Messages as CreateBigbitMessages
import Keyboard.Extra
import Models.ApiError as ApiError
import Models.Range as Range
import Models.Route as Route
import Models.User exposing (User)
import Navigation


{-| `Base` Msg.
-}
type Msg
    = NoOp
    | GoTo Route.Route
    | OnLocationChange Navigation.Location
    | LoadModelFromLocalStorage
    | OnLoadModelFromLocalStorageSuccess Model
    | OnLoadModelFromLocalStorageFailure String
    | GetUser
    | OnGetUserSuccess User
    | OnGetUserFailure ApiError.ApiError
    | WelcomeMessage WelcomeMessages.Msg
    | ViewSnipbitMessage ViewSnipbitMessages.Msg
    | ViewBigbitMessage ViewBigbitMessages.Msg
    | ViewStoryMessage ViewStoryMessages.Msg
    | ProfileMessage ProfileMessages.Msg
    | NewStoryMessage NewStoryMessages.Msg
    | CreateMessage CreateMessages.Msg
    | DevelopStoryMessage DevelopStoryMessages.Msg
    | CreateSnipbitMessage CreateSnipbitMessages.Msg
    | CreateBigbitMessage CreateBigbitMessages.Msg
    | CodeEditorUpdate { id : String, value : String, deltaRange : Range.Range, action : String }
    | CodeEditorSelectionUpdate { id : String, range : Range.Range }
    | KeyboardExtraMessage Keyboard.Extra.Msg
