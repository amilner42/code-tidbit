module Pages.CreateSnipbit.Messages exposing (..)

import Autocomplete as AC
import Models.ApiError exposing (ApiError)
import Models.IDResponse exposing (IDResponse)
import Models.Range exposing (Range)
import Models.Route exposing (Route)
import Pages.CreateSnipbit.Model exposing (..)


{-| `CreateSnipbit` msg.
-}
type Msg
    = OnRouteHit Route
    | OnRangeSelected Range
    | OnUpdateACState AC.Msg
    | OnUpdateACWrap Bool
    | OnUpdateCode { newCode : String, deltaRange : Range, action : String }
    | GoToCodeTab
    | Reset
    | AddFrame
    | RemoveFrame
    | TogglePreviewMarkdown
    | JumpToLineFromPreviousFrame
    | OnUpdateLanguageQuery String
    | SelectLanguage (Maybe String)
    | OnUpdateName String
    | OnUpdateDescription String
    | OnUpdateTagInput String
    | RemoveTag String
    | AddTag String
    | OnUpdateFrameComment Int String
    | Publish SnipbitForPublication
    | OnPublishSuccess IDResponse
    | OnPublishFailure ApiError
    | ToggleLockCode
