module Pages.CreateBigbit.Messages exposing (..)

import Elements.Simple.Editor exposing (Language)
import Elements.Simple.FileStructure as FS
import Models.ApiError exposing (ApiError)
import Models.IDResponse exposing (IDResponse)
import Models.Range exposing (Range)
import Models.Route exposing (Route)
import Pages.CreateBigbit.Model exposing (..)


{-| `CreateBigbit` msg.
-}
type Msg
    = NoOp
    | GoTo Route
    | OnRouteHit Route
    | OnUpdateCode { newCode : String, deltaRange : Range, action : String }
    | OnRangeSelected Range
    | GoToCodeTab
    | Reset
    | AddFrame
    | RemoveFrame
    | ToggleFS
    | ToggleFolder FS.Path
    | SelectFile FS.Path
    | TogglePreviewMarkdown
    | AddFile FS.Path Language
    | JumpToLineFromPreviousFrame FS.Path
    | OnUpdateName String
    | OnUpdateDescription String
    | OnUpdateTagInput String
    | AddTag String
    | RemoveTag String
    | OnUpdateIntroduction String
    | OnUpdateFrameComment Int String
    | OnUpdateConclusion String
    | UpdateActionButtonState (Maybe FSActionButtonState)
    | OnUpdateActionInput String
    | SubmitActionInput
    | Publish BigbitForPublication
    | OnPublishSuccess IDResponse
    | OnPublishFailure ApiError
