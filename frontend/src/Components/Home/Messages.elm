module Components.Home.Messages exposing (Msg(..))

import Autocomplete as AC
import Models.ApiError as ApiError
import Models.BasicResponse as BasicResponse
import Models.BasicTidbit as BasicTidbit
import Models.Route as Route


{-| Home Component Msg.
-}
type Msg
    = GoTo Route.Route
    | LogOut
    | OnLogOutFailure ApiError.ApiError
    | OnLogOutSuccess BasicResponse.BasicResponse
    | BasicTidbitUpdateLanguageQuery String
    | BasicTidbitUpdateACState AC.Msg
    | BasicTidbitSelectLanguage (Maybe String)
    | ResetCreateBasicTidbit
    | BasicTidbitUpdateName String
    | BasicTidbitUpdateDescription String
    | BasicTidbitUpdateTagInput String
    | BasicTidbitRemoveTag String
    | BasicTidbitAddTag String
