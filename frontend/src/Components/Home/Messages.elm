module Components.Home.Messages exposing (Msg(..))

import Autocomplete as AC
import Models.ApiError as ApiError
import Models.BasicResponse as BasicResponse
import Models.BasicTidbit as BasicTidbit
import Models.TidbitType as TidbitType


{-| Home Component Msg.
-}
type Msg
    = GoToBrowseView
    | GoToCreateView
    | GoToProfileView
    | LogOut
    | OnLogOutFailure ApiError.ApiError
    | OnLogOutSuccess BasicResponse.BasicResponse
    | CreateEditor String
    | SelectTidbitTypeForCreate (Maybe TidbitType.TidbitType)
    | BasicTidbitUpdateLanguageQuery String
    | BasicTidbitUpdateACState AC.Msg
    | BasicTidbitSelectLanguage String
    | BasicTidbitSelectTab BasicTidbit.BasicTidbitCreateStage
    | ResetCreateBasicTidbit
