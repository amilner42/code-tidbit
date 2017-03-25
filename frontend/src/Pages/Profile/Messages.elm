module Pages.Profile.Messages exposing (..)

import Models.ApiError as ApiError
import Models.BasicResponse as BasicResponse
import Models.User as User


{-| `Profile` msg.
-}
type Msg
    = ProfileCancelEditName
    | ProfileUpdateName String String
    | ProfileSaveEditName
    | ProfileSaveNameFailure ApiError.ApiError
    | ProfileSaveNameSuccess User.User
    | ProfileCancelEditBio
    | ProfileUpdateBio String String
    | ProfileSaveEditBio
    | ProfileSaveBioFailure ApiError.ApiError
    | ProfileSaveBioSuccess User.User
    | LogOut
    | OnLogOutFailure ApiError.ApiError
    | OnLogOutSuccess BasicResponse.BasicResponse
