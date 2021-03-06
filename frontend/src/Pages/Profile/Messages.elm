module Pages.Profile.Messages exposing (..)

import Models.ApiError exposing (ApiError)
import Models.User exposing (User)


{-| `Profile` msg.
-}
type Msg
    = OnEditName String String
    | CancelEditedName
    | SaveEditedName
    | OnSaveEditedNameSuccess User
    | OnSaveEditedNameFailure ApiError
    | OnEditBio String String
    | CancelEditedBio
    | SaveEditedBio
    | OnSaveEditedBioSuccess User
    | OnSaveBioEditedFailure ApiError
