module Pages.CreateSnipbit.Messages exposing (..)

import Autocomplete as AC
import Pages.CreateSnipbit.Model exposing (..)
import Models.ApiError as ApiError
import Models.IDResponse exposing (IDResponse)
import Models.Range as Range
import Models.Route as Route


{-| `CreateSnipbit` msg.
-}
type Msg
    = NoOp
    | GoTo Route.Route
    | OnRouteHit Route.Route
    | SnipbitGoToCodeTab
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
    | SnipbitTogglePreviewMarkdown
    | SnipbitAddFrame
    | SnipbitRemoveFrame
    | SnipbitUpdateFrameComment Int String
    | SnipbitUpdateIntroduction String
    | SnipbitUpdateConclusion String
    | SnipbitUpdateCode { newCode : String, deltaRange : Range.Range, action : String }
    | SnipbitPublish SnipbitForPublication
    | SnipbitJumpToLineFromPreviousFrame
    | OnSnipbitPublishSuccess IDResponse
    | OnSnipbitPublishFailure ApiError.ApiError
