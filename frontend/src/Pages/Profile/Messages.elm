module Pages.Profile.Messages exposing (..)

import Models.ApiError as ApiError
import Models.User as User
import Models.BasicResponse as BasicResponse


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
