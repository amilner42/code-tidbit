module Components.Home.Messages exposing (Msg(..))

import Models.ApiError as ApiError
import Models.BasicResponse as BasicResponse


{-| Home Component Msg.
-}
type Msg
    = GoToMainView
    | GoToProfileView
    | LogOut
    | OnLogOutFailure ApiError.ApiError
    | OnLogOutSuccess BasicResponse.BasicResponse
    | CreateEditor String
