module Components.Home.Init exposing (init)

import Array
import Autocomplete as AC
import Components.Home.Model exposing (Model)
import Elements.Editor as Editor
import Elements.FileStructure as FS
import Models.Snipbit as Snipbit
import Models.Bigbit as Bigbit
import Models.NewStoryData as NewStoryData
import Models.StoryData as StoryData
import Models.ViewStoryData as ViewStoryData


{-| Home Component Init.
-}
init : Model
init =
    { logOutError = Nothing
    , showInfoFor = Nothing
    , viewingSnipbit = Nothing
    , viewingSnipbitIsCompleted = Nothing
    , viewingSnipbitRelevantHC = Nothing
    , viewingBigbit = Nothing
    , viewingBigbitIsCompleted = Nothing
    , viewingBigbitRelevantHC = Nothing
    , snipbitCreateData =
        { language = Nothing
        , languageQueryACState = AC.empty
        , languageListHowManyToShow = (List.length Editor.humanReadableListOfLanguages)
        , languageQuery = ""
        , name = ""
        , description = ""
        , tags = []
        , tagInput = ""
        , code = ""
        , highlightedComments =
            Array.fromList
                [ { comment = Nothing, range = Nothing }
                ]
        , introduction = ""
        , conclusion = ""
        , previewMarkdown = False
        }
    , bigbitCreateData =
        { name = ""
        , description = ""
        , tags = []
        , tagInput = ""
        , introduction = ""
        , conclusion = ""
        , fs =
            (FS.emptyFS
                { activeFile = Nothing
                , openFS = False
                , actionButtonState = Nothing
                , actionButtonInput = ""
                , actionButtonSubmitConfirmed = False
                }
                { isExpanded = True }
            )
        , highlightedComments =
            Array.fromList
                [ Bigbit.emptyBigbitHighlightCommentForCreate ]
        , previewMarkdown =
            False
        }
    , profileData =
        { accountName = Nothing
        , accountBio = Nothing
        }
    , newStoryData = NewStoryData.defaultNewStoryData
    , storyData = StoryData.defaultStoryData
    , viewStoryData = ViewStoryData.defaultViewStoryData
    }
