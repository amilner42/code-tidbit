module Components.Home.Messages exposing (Msg(..))

import Autocomplete as AC
import Components.Home.Model exposing (TidbitType)
import Models.ApiError as ApiError
import Models.BasicResponse as BasicResponse
import Models.BasicTidbit as BasicTidbit
import Models.Range as Range
import Models.Route as Route


{-| Home Component Msg.
-}
type Msg
    = NoOp
    | GoTo Route.Route
    | LogOut
    | OnLogOutFailure ApiError.ApiError
    | OnLogOutSuccess BasicResponse.BasicResponse
    | ShowInfoFor (Maybe TidbitType)
    | BasicTidbitUpdateLanguageQuery String
    | BasicTidbitUpdateACState AC.Msg
    | BasicTidbitUpdateACWrap Bool
    | BasicTidbitSelectLanguage (Maybe String)
    | ResetCreateBasicTidbit
    | BasicTidbitUpdateName String
    | BasicTidbitUpdateDescription String
    | BasicTidbitUpdateTagInput String
    | BasicTidbitRemoveTag String
    | BasicTidbitAddTag String
    | BasicTidbitNewRangeSelected Range.Range
    | BasicTidbitAddFrame
    | BasicTidbitRemoveFrame
    | BasicTidbitUpdateFrameComment Int String
    | BasicTidbitUpdateIntroduction String
    | BasicTidbitUpdateConclusion String
    | BasicTidbitUpdateCode String
    | BasicTidbitPublish BasicTidbit.BasicTidbit
    | OnBasicTidbitPublishSuccess BasicResponse.BasicResponse
    | OnBasicTidbitPublishFailure ApiError.ApiError
