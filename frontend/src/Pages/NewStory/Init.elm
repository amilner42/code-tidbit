module Pages.NewStory.Init exposing (..)

import Models.Story as Story
import Pages.NewStory.Model exposing (..)


{-| `NewStory` init.
-}
init : Model
init =
    { newStory = Story.defaultNewStory
    , editingStory = Story.blankStory
    , tagInput = ""
    , editingStoryTagInput = ""
    }
