module Components.Home.Messages exposing (Msg(..))

import Autocomplete as AC
import Components.Home.Model exposing (TidbitType)
import Models.ApiError as ApiError
import Models.BasicResponse as BasicResponse
import Models.CreateSnipbitResponse exposing (CreateSnipbitResponse)
import Models.Range as Range
import Models.Route as Route
import Models.Snipbit as Snipbit


{-| Home Component Msg.
-}
type Msg
    = NoOp
    | OnRouteHit
    | GoTo Route.Route
    | LogOut
    | OnLogOutFailure ApiError.ApiError
    | OnLogOutSuccess BasicResponse.BasicResponse
    | ShowInfoFor (Maybe TidbitType)
    | SnipbitUpdateLanguageQuery String
    | SnipbitUpdateACState AC.Msg
    | SnipbitUpdateACWrap Bool
    | SnipbitSelectLanguage (Maybe String)
    | SnipbitReset
    | SnipbitUpdateName String
    | SnipbitUpdateDescription String
    | SnipbitUpdateTagInput String
    | SnipbitRemoveTag String
    | SnipbitAddTag String
    | SnipbitNewRangeSelected Range.Range
    | SnipbitAddFrame
    | SnipbitRemoveFrame
    | SnipbitUpdateFrameComment Int String
    | SnipbitUpdateIntroduction String
    | SnipbitUpdateConclusion String
    | SnipbitUpdateCode String
    | SnipbitPublish Snipbit.SnipbitForPublication
    | OnSnipbitPublishSuccess CreateSnipbitResponse
    | OnSnipbitPublishFailure ApiError.ApiError
    | OnGetSnipbitFailure ApiError.ApiError
    | OnGetSnipbitSuccess Snipbit.Snipbit
    | BigbitReset
    | BigbitUpdateName String
    | BigbitUpdateDescription String
    | BigbitUpdateTagInput String
    | BigbitAddTag String
    | BigbitRemoveTag String
