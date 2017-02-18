module Components.Messages exposing (..)

import Components.Home.Messages as HomeMessages
import Components.Model exposing (Model)
import Components.Welcome.Messages as WelcomeMessages
import Keyboard.Extra
import Models.ApiError as ApiError
import Models.Range as Range
import Models.User exposing (User)
import Navigation


{-| Base Component Msg.
-}
type Msg
    = NoOp
    | OnLocationChange Navigation.Location
    | LoadModelFromLocalStorage
    | OnLoadModelFromLocalStorageSuccess Model
    | OnLoadModelFromLocalStorageFailure String
    | GetUser
    | OnGetUserSuccess User
    | OnGetUserFailure ApiError.ApiError
    | HomeMessage HomeMessages.Msg
    | WelcomeMessage WelcomeMessages.Msg
    | CodeEditorUpdate { id : String, value : String }
    | CodeEditorSelectionUpdate { id : String, range : Range.Range }
    | KeyboardExtraMessage Keyboard.Extra.Msg
