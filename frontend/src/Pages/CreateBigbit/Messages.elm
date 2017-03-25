module Pages.CreateBigbit.Messages exposing (..)

import Elements.Editor as Editor
import Elements.FileStructure as FS
import Models.ApiError as ApiError
import Models.Bigbit as Bigbit
import Models.IDResponse exposing (IDResponse)
import Models.Range as Range
import Models.Route as Route
import Pages.CreateBigbit.Model exposing (..)


{-| `CreateBigbit` msg.
-}
type Msg
    = NoOp
    | OnRouteHit Route.Route
    | GoTo Route.Route
    | BigbitGoToCodeTab
    | BigbitReset
    | BigbitUpdateName String
    | BigbitUpdateDescription String
    | BigbitUpdateTagInput String
    | BigbitAddTag String
    | BigbitRemoveTag String
    | BigbitUpdateIntroduction String
    | BigbitUpdateConclusion String
    | BigbitToggleFS
    | BigbitFSToggleFolder FS.Path
    | BigbitTogglePreviewMarkdown
    | BigbitUpdateActionButtonState (Maybe FSActionButtonState)
    | BigbitUpdateActionInput String
    | BigbitSubmitActionInput
    | BigbitAddFile FS.Path Editor.Language
    | BigbitUpdateCode { newCode : String, deltaRange : Range.Range, action : String }
    | BigbitFileSelected FS.Path
    | BigbitAddFrame
    | BigbitRemoveFrame
    | BigbitUpdateFrameComment Int String
    | BigbitNewRangeSelected Range.Range
    | BigbitPublish BigbitForPublication
    | BigbitJumpToLineFromPreviousFrame FS.Path
    | OnBigbitPublishFailure ApiError.ApiError
    | OnBigbitPublishSuccess IDResponse
