module Components.Home.Messages exposing (Msg(..))

import Autocomplete as AC
import Components.Home.Model exposing (TidbitType)
import Models.ApiError as ApiError
import Models.BasicResponse as BasicResponse
import Models.CreateTidbitResponse exposing (CreateTidbitResponse)
import Models.Range as Range
import Models.Route as Route
import Models.Bigbit as Bigbit
import Models.Snipbit as Snipbit
import Elements.FileStructure as FS
import Elements.Editor as Editor


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
    | SnipbitUpdateCode FS.Content
    | SnipbitPublish Snipbit.SnipbitForPublication
    | OnSnipbitPublishSuccess CreateTidbitResponse
    | OnSnipbitPublishFailure ApiError.ApiError
    | OnGetSnipbitFailure ApiError.ApiError
    | OnGetSnipbitSuccess Snipbit.Snipbit
    | ViewSnipbitRangeSelected Range.Range
    | ViewSnipbitBrowseRelevantHC
    | ViewSnipbitCancelBrowseRelevantHC
    | ViewSnipbitNextRelevantHC
    | ViewSnipbitPreviousRelevantHC
    | ViewSnipbitJumpToFrame Route.Route
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
    | BigbitUpdateActionButtonState (Maybe Bigbit.FSActionButtonState)
    | BigbitUpdateActionInput String
    | BigbitSubmitActionInput
    | BigbitAddFile FS.Path Editor.Language
    | BigbitUpdateCode FS.Content
    | BigbitFileSelected FS.Path
    | BigbitAddFrame
    | BigbitRemoveFrame
    | BigbitUpdateFrameComment Int String
    | BigbitNewRangeSelected Range.Range
    | BigbitPublish Bigbit.BigbitForPublication
    | BigbitJumpToLineFromPreviousFrame FS.Path
    | OnBigbitPublishFailure ApiError.ApiError
    | OnBigbitPublishSuccess CreateTidbitResponse
    | OnGetBigbitFailure ApiError.ApiError
    | OnGetBigbitSuccess Bigbit.Bigbit
    | ViewBigbitToggleFS
    | ViewBigbitToggleFolder FS.Path
    | ViewBigbitSelectFile FS.Path
    | ViewBigbitRangeSelected Range.Range
    | ViewBigbitBrowseRelevantHC
    | ViewBigbitCancelBrowseRelevantHC
    | ViewBigbitNextRelevantHC
    | ViewBigbitPreviousRelevantHC
    | ViewBigbitJumpToFrame Route.Route
