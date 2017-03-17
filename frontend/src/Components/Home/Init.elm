module Components.Home.Init exposing (init)

import Array
import Autocomplete as AC
import Components.Home.Model exposing (Model)
import Elements.Editor as Editor
import Elements.FileStructure as FS
import Models.CreateData as CreateData
import Models.Snipbit as Snipbit
import Models.Bigbit as Bigbit
import Models.NewStoryData as NewStoryData
import Models.StoryData as StoryData
import Models.ViewSnipbitData as ViewSnipbitData
import Models.ViewBigbitData as ViewBigbitData
import Models.ProfileData as ProfileData


{-| Home Component Init.
-}
init : Model
init =
    { createData = CreateData.defaultCreateData
    , viewSnipbitData = ViewSnipbitData.defaultViewSnipbitData
    , viewBigbitData = ViewBigbitData.defaultViewBigbitData
    , snipbitCreateData = Snipbit.defaultSnipbitCreateData
    , bigbitCreateData = Bigbit.defaultBigbitCreateData
    , profileData = ProfileData.defaultProfileData
    , newStoryData = NewStoryData.defaultNewStoryData
    , storyData = StoryData.defaultStoryData
    }
